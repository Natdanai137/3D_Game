"""Build Aof's body rig, skin weights and locomotion clips from the original GLB.
Requires NumPy and Pillow from the bundled Python runtime. Never overwrites the source.
"""
import json
import io
import struct
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Assets/model/Aof/Aof_3D.glb'
OUTPUT = SOURCE.with_name('Aof_Rigged.glb')


def read_glb(path):
    blob = path.read_bytes()
    assert blob[:4] == b'glTF'
    size = struct.unpack_from('<I', blob, 12)[0]
    doc = json.loads(blob[20:20+size])
    offset = 20+size
    size = struct.unpack_from('<I', blob, offset)[0]
    return doc, bytearray(blob[offset+8:offset+8+size])


def accessor(doc, raw, index):
    item = doc['accessors'][index]
    view = doc['bufferViews'][item['bufferView']]
    dtype = {5126:'<f4',5125:'<u4',5123:'<u2',5121:'u1'}[item['componentType']]
    count = {'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[item['type']]
    return np.ndarray((item['count'],count), dtype=dtype, buffer=raw,
                      offset=view.get('byteOffset',0)+item.get('byteOffset',0),
                      strides=(view.get('byteStride',np.dtype(dtype).itemsize*count),np.dtype(dtype).itemsize)).copy()


def append(doc, raw, array, kind, component=5126, target=None, bounds=False):
    raw.extend(b'\0' * (-len(raw)%4))
    array = np.asarray(array,dtype={5126:'<f4',5123:'<u2',5125:'<u4'}[component])
    view = {'buffer':0,'byteOffset':len(raw),'byteLength':array.nbytes}
    if target:
        view['target'] = target
    view_index = len(doc['bufferViews'])
    doc['bufferViews'].append(view)
    raw.extend(array.tobytes())
    item = {'bufferView':view_index,'componentType':component,'count':len(array),'type':kind}
    if bounds:
        item['min'] = array.min(axis=0).reshape(-1).tolist()
        item['max'] = array.max(axis=0).reshape(-1).tolist()
    index = len(doc['accessors'])
    doc['accessors'].append(item)
    return index


def smooth(a,b,x):
    t=np.clip((x-a)/(b-a),0,1)
    return t*t*(3-2*t)


def quat(axis, angles):
    out=np.zeros((len(angles),4),np.float32)
    out[:,axis]=np.sin(angles/2)
    out[:,3]=np.cos(angles/2)
    return out


def build():
    doc, raw = read_glb(SOURCE)
    primitive = doc['meshes'][0]['primitives'][0]
    points = accessor(doc,raw,primitive['attributes']['POSITION'])
    bottom=float(points[:,1].min())
    scale=1.8/float(points[:,1].max()-bottom)
    def position(x,y,z):
        return np.array([x,y-bottom,z],np.float32)*scale
    vertices=points.copy()*scale
    vertices[:,1]=(points[:,1]-bottom)*scale
    primitive['attributes']['POSITION']=append(doc,raw,vertices,'VEC3',target=34962,bounds=True)
    # Anatomical landmarks measured in the source mesh's coordinate system.
    bones=[('Root',None,np.zeros(3)),
           ('Hips','Root',position(0,-.34,.025)),
           ('Spine','Hips',position(0,-.12,0)),
           ('Chest','Spine',position(0,.12,0)),
           ('Neck','Chest',position(0,.29,.01)),
           ('Head','Neck',position(0,.43,.025))]
    for side,sign in [('Left',1),('Right',-1)]:
        bones.extend([(side+'Shoulder','Chest',position(sign*.17,.135,.005)),
                      (side+'UpperArm',side+'Shoulder',position(sign*.217,.075,.005)),
                      (side+'Forearm',side+'UpperArm',position(sign*.258,-.125,.015)),
                      (side+'Hand',side+'Forearm',position(sign*.266,-.30,.025)),
                      (side+'UpperLeg','Hips',position(sign*.137,-.365,.018)),
                      (side+'LowerLeg',side+'UpperLeg',position(sign*.162,-.595,.025)),
                      (side+'Foot',side+'LowerLeg',position(sign*.17,-.815,.05)),
                      (side+'Toes',side+'Foot',position(sign*.17,-.90,.22))])
    bone_ids={name:i for i,(name,_,_) in enumerate(bones)}
    node_base=len(doc['nodes'])
    for name,parent,world in bones:
        parent_world=bones[bone_ids[parent]][2] if parent else np.zeros(3)
        doc['nodes'].append({'name':name,'translation':(world-parent_world).tolist(),'children':[]})
    for name,parent,world in bones:
        if parent:
            doc['nodes'][node_base+bone_ids[parent]]['children'].append(node_base+bone_ids[name])
    count=len(points)
    weights=np.zeros((count,len(bones)),np.float32)
    x,y,z=points.T
    ax=np.abs(x)
    head=smooth(.24,.36,y)
    chest=smooth(-.13,.17,y)
    hips=1-smooth(-.38,-.10,y)
    torso=1-head
    weights[:,bone_ids['Hips']]=torso*hips
    weights[:,bone_ids['Chest']]=torso*(1-hips)*chest
    weights[:,bone_ids['Spine']]=torso*(1-hips)*(1-chest)
    neck=(1-head)*smooth(.17,.26,y)
    weights[:,:]*=(1-neck[:,None])
    weights[:,bone_ids['Neck']]+=neck
    weights[:,bone_ids['Head']]+=head
    # Restrict arm weighting to sleeves/hands, excluding backpack and hip fabric.
    seam=np.interp(y,[-.48,-.35,-.12,.08,.18],[.245,.218,.19,.18,.23])
    arm=smooth(seam-.012,seam+.025,ax)*(1-smooth(.13,.24,y))*smooth(-.51,-.40,y)*(1-smooth(.10,.22,-z))
    legs=1-smooth(-.48,-.35,y)
    legs*=1-arm
    weights*=((1-arm)*(1-legs))[:,None]
    for side,sign in [('Left',1),('Right',-1)]:
        side_mask=(x*sign>=0).astype(np.float32)
        contribution=arm*side_mask
        hand=1-smooth(-.33,-.25,y)
        forearm=(1-hand)*(1-smooth(-.16,-.06,y))
        upper=1-hand-forearm
        weights[:,bone_ids[side+'Hand']]+=contribution*hand
        weights[:,bone_ids[side+'Forearm']]+=contribution*forearm
        weights[:,bone_ids[side+'UpperArm']]+=contribution*upper
        contribution=legs*side_mask
        foot=1-smooth(-.84,-.75,y)
        toe=foot*smooth(.12,.25,z)
        lower=(1-foot)*(1-smooth(-.66,-.53,y))
        upper=1-foot-lower
        weights[:,bone_ids[side+'UpperLeg']]+=contribution*upper
        weights[:,bone_ids[side+'LowerLeg']]+=contribution*lower
        weights[:,bone_ids[side+'Foot']]+=contribution*(foot-toe)
        weights[:,bone_ids[side+'Toes']]+=contribution*toe
    # Texture-assisted hand region: curled fingertips overlap the trousers in X/Y.
    # Keep skin-colored hand vertices with the hand bone, including dark creases.
    uv=accessor(doc,raw,primitive['attributes']['TEXCOORD_0'])
    image_view=doc['bufferViews'][doc['images'][0]['bufferView']]
    image=np.asarray(Image.open(io.BytesIO(raw[image_view['byteOffset']:image_view['byteOffset']+image_view['byteLength']])).convert('RGB'))
    rgb=image[np.clip((uv[:,1]*image.shape[0]).astype(int),0,image.shape[0]-1),np.clip((uv[:,0]*image.shape[1]).astype(int),0,image.shape[1]-1)].astype(float)
    hand_volume=(y<-.26)&(y>-.56)&(ax>.19)&(z>-.09)
    skin_color=(rgb[:,0]>70)&(rgb[:,1]>40)&(rgb[:,2]>28)&(rgb[:,0]<rgb[:,1]*1.85)&(rgb[:,1]<rgb[:,2]*2.1)
    hand_region=hand_volume&skin_color
    faces=accessor(doc,raw,primitive['indices']).reshape(-1,3)
    for _ in range(4):
        touched=hand_region[faces].any(axis=1)
        expanded=np.zeros(count,dtype=bool)
        expanded[faces[touched].ravel()]=True
        hand_region|=expanded&hand_volume
    for side,sign in [('Left',1),('Right',-1)]:
        selected=hand_region&(x*sign>=0)
        weights[selected]=0
        weights[selected,bone_ids[side+'Hand']]=1
    indices=np.argsort(weights,axis=1)[:,-4:][:,::-1].astype(np.uint16)
    skin_weights=np.take_along_axis(weights,indices,axis=1)
    skin_weights/=skin_weights.sum(axis=1,keepdims=True)
    assert np.all(np.isfinite(skin_weights)) and np.allclose(skin_weights.sum(1),1,atol=1e-6)
    # The generated source fuses small contact bridges between hands and trousers.
    # Disconnect only those bridges so swinging hands cannot stretch hip triangles.
    dominant=indices[np.arange(count),skin_weights.argmax(axis=1)]
    arm_ids=[bone_ids[side+part] for side in ['Left','Right'] for part in ['UpperArm','Forearm','Hand']]
    body_ids=[bone_ids[name] for name in ['Hips','Spine','Chest']]+[bone_ids[side+part] for side in ['Left','Right'] for part in ['UpperLeg','LowerLeg','Foot','Toes']]
    contact=np.isin(dominant[faces],arm_ids).any(axis=1)&np.isin(dominant[faces],body_ids).any(axis=1)&(points[faces,1].max(axis=1)<-.22)
    primitive['indices']=append(doc,raw,faces[~contact].reshape(-1,1),'SCALAR',5125,34963)
    primitive['attributes']['JOINTS_0']=append(doc,raw,indices,'VEC4',5123,34962)
    primitive['attributes']['WEIGHTS_0']=append(doc,raw,skin_weights,'VEC4',target=34962)
    inverse=[]
    for _,_,world in bones:
        matrix=np.eye(4,dtype=np.float32); matrix[:3,3]=-world
        inverse.append(matrix.T.reshape(16))
    bind=append(doc,raw,np.array(inverse),'MAT4')
    doc['skins']=[{'name':'AofBodyRig','skeleton':node_base,'joints':list(range(node_base,node_base+len(bones))),'inverseBindMatrices':bind}]
    doc['nodes'][0]['skin']=0
    doc['nodes'][0]['name']='AofMesh'
    doc['scenes']=[{'name':'AofRigged','nodes':[0,node_base]}]
    doc['scene']=0
    doc['animations']=[]
    def clip(name,duration,rotations,translations=None):
        times=np.linspace(0,duration,25,dtype=np.float32)
        input_index=append(doc,raw,times.reshape(-1,1),'SCALAR',bounds=True)
        animation={'name':name,'samplers':[],'channels':[]}
        for bone,(axis,values) in rotations.items():
            output_index=append(doc,raw,quat(axis,np.asarray(values)),'VEC4')
            animation['samplers'].append({'input':input_index,'output':output_index,'interpolation':'LINEAR'})
            animation['channels'].append({'sampler':len(animation['samplers'])-1,'target':{'node':node_base+bone_ids[bone],'path':'rotation'}})
        for bone,values in (translations or {}).items():
            output_index=append(doc,raw,values,'VEC3')
            animation['samplers'].append({'input':input_index,'output':output_index,'interpolation':'LINEAR'})
            animation['channels'].append({'sampler':len(animation['samplers'])-1,'target':{'node':node_base+bone_ids[bone],'path':'translation'}})
        doc['animations'].append(animation)
    phase=np.linspace(0,2*np.pi,25); wave=np.sin(phase)
    zeros=np.zeros(25)
    all_motion=['Hips','Spine','Chest','Neck','Head']+[side+part for side in ['Left','Right'] for part in ['Shoulder','UpperArm','Forearm','Hand','UpperLeg','LowerLeg','Foot','Toes']]
    def neutral(): return {name:(0,zeros.copy()) for name in all_motion}
    hips_rest=bones[bone_ids['Hips']][2].copy()
    for name,duration,amount in [('Idle',2.4,0),('Walk',.9,.48),('Run',.64,.78)]:
        rotations=neutral()
        pelvis=np.tile(hips_rest,(25,1))
        if amount:
            for side,sign in [('Left',1),('Right',-1)]:
                swing=wave*sign
                rotations[side+'UpperLeg']=(0,amount*swing)
                rotations[side+'LowerLeg']=(0,np.maximum(swing,0)*(.75 if name=='Run' else .42))
                rotations[side+'Foot']=(0,-np.maximum(swing,0)*.16)
                rotations[side+'UpperArm']=(0,-swing*(.55 if name=='Run' else .30))
                rotations[side+'Forearm']=(0,zeros-(.40 if name=='Run' else .16))
            rotations['Hips']=(0,zeros+(.08 if name=='Run' else .025))
            rotations['Chest']=(2,wave*.022)
            rotations['Head']=(2,-wave*.015)
            pelvis[:,1]+=(1-np.cos(phase*2))*(.018 if name=='Run' else .012)
        else:
            pelvis[:,1]+=wave*.004
            rotations['Chest']=(0,wave*.012)
            rotations['Head']=(1,wave*.015)
        clip(name,duration,rotations,{'Hips':pelvis})
    for name in ['Jump','Fall']:
        rotations=neutral()
        for side,offset in [('Left',0),('Right',.12)]:
            rotations[side+'UpperArm']=(0,zeros+(-.52 if name=='Jump' else -.30))
            rotations[side+'Forearm']=(0,zeros-.45)
            rotations[side+'UpperLeg']=(0,zeros+(-.52-offset if name=='Jump' else -.12-offset))
            rotations[side+'LowerLeg']=(0,zeros+(.70 if name=='Jump' else .28))
            rotations[side+'Foot']=(0,zeros-.15)
        rotations['Hips']=(0,zeros-.05)
        clip(name,.5,rotations,{'Hips':np.tile(hips_rest,(25,1))})
    doc['asset']['generator']='Aof body rig builder / tools/rig_aof.py'
    raw.extend(b'\0'*(-len(raw)%4)); doc['buffers']=[{'byteLength':len(raw)}]
    encoded=json.dumps(doc,separators=(',',':')).encode(); encoded+=b' '*(-len(encoded)%4)
    blob=struct.pack('<4sII',b'glTF',2,12+8+len(encoded)+8+len(raw))+struct.pack('<I4s',len(encoded),b'JSON')+encoded+struct.pack('<I4s',len(raw),b'BIN\0')+raw
    OUTPUT.write_bytes(blob)
    report={'source':str(SOURCE.relative_to(ROOT)),'output':str(OUTPUT.relative_to(ROOT)),'vertices':count,'disconnected_contact_faces':int(contact.sum()),'bones':[b[0] for b in bones],'clips':[a['name'] for a in doc['animations']],'height_m':1.8,'weight_sum_error':float(np.abs(skin_weights.sum(1)-1).max())}
    OUTPUT.with_suffix('.rig.json').write_text(json.dumps(report,indent=2))
    print(json.dumps(report,indent=2))

if __name__=='__main__':
    build()

