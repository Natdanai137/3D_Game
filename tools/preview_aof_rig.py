"""Software render the rig's skinning poses without requiring a desktop window."""
import io
import sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
from rig_aof import read_glb, accessor, OUTPUT


def rotation(q):
    x,y,z,w=q
    return np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],
                     [2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],
                     [2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])


def pose(doc,raw,name,time):
    nodes=doc['nodes']
    local=[]
    for node in nodes:
        matrix=np.eye(4)
        matrix[:3,3]=node.get('translation',[0,0,0])
        local.append(matrix)
    animation=next(a for a in doc['animations'] if a['name']==name)
    for channel in animation['channels']:
        sample=animation['samplers'][channel['sampler']]
        times=accessor(doc,raw,sample['input']).ravel()
        values=accessor(doc,raw,sample['output'])
        i=max(0,min(len(times)-2,np.searchsorted(times,time)-1))
        ratio=np.clip((time-times[i])/(times[i+1]-times[i]),0,1)
        value=values[i]*(1-ratio)+values[i+1]*ratio
        matrix=local[channel['target']['node']]
        if channel['target']['path']=='rotation':
            matrix[:3,:3]=rotation(value/np.linalg.norm(value))
        else:
            matrix[:3,3]=value
    worlds={}
    def visit(i,parent):
        worlds[i]=parent@local[i]
        for child in nodes[i].get('children',[]):visit(child,worlds[i])
    for root in doc['scenes'][0]['nodes']:visit(root,np.eye(4))
    skin=doc['skins'][0]
    inverse=accessor(doc,raw,skin['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
    matrices=np.array([worlds[j]@inverse[k] for k,j in enumerate(skin['joints'])])
    primitive=doc['meshes'][0]['primitives'][0]
    a=primitive['attributes']
    positions=accessor(doc,raw,a['POSITION'])
    normal=accessor(doc,raw,a['NORMAL'])
    joints=accessor(doc,raw,a['JOINTS_0'])
    weights=accessor(doc,raw,a['WEIGHTS_0'])
    points=np.column_stack([positions,np.ones(len(positions))])
    vertices=np.zeros_like(positions,dtype=np.float64)
    normals=np.zeros_like(vertices)
    for k in range(4):
        transform=matrices[joints[:,k]]
        vertices+=np.einsum('nij,nj->ni',transform,points)[:,:3]*weights[:,k,None]
        normals+=np.einsum('nij,nj->ni',transform[:,:3,:3],normal)*weights[:,k,None]
    normals/=np.maximum(np.linalg.norm(normals,axis=1,keepdims=True),1e-8)
    return vertices,normals


def render(doc,raw,vertices,normals,yaw,width=420,height=720):
    primitive=doc['meshes'][0]['primitives'][0]
    uv=accessor(doc,raw,primitive['attributes']['TEXCOORD_0'])
    faces=accessor(doc,raw,primitive['indices']).reshape(-1,3)
    view=doc['bufferViews'][doc['images'][0]['bufferView']]
    texture=np.array(Image.open(io.BytesIO(raw[view['byteOffset']:view['byteOffset']+view['byteLength']])).convert('RGB'))
    angle=np.deg2rad(yaw)
    camera=np.array([[np.cos(angle),0,-np.sin(angle)],[0,1,0],[np.sin(angle),0,np.cos(angle)]])
    points=vertices@camera.T
    screen=np.column_stack([width/2+points[:,0]*310,height-40-points[:,1]*310])
    light=np.array([.4,.7,.8]);light/=np.linalg.norm(light)
    shade=.40+.60*np.maximum(0,normals@light)
    canvas=np.empty((height,width,3),np.uint8);canvas[:]=[23,32,42]
    zbuffer=np.full((height,width),-np.inf)
    for face in faces:
        pts=screen[face]
        xmin=max(0,int(np.floor(pts[:,0].min())));xmax=min(width-1,int(np.ceil(pts[:,0].max())))
        ymin=max(0,int(np.floor(pts[:,1].min())));ymax=min(height-1,int(np.ceil(pts[:,1].max())))
        if xmin>xmax or ymin>ymax:continue
        (x0,y0),(x1,y1),(x2,y2)=pts
        den=(y1-y2)*(x0-x2)+(x2-x1)*(y0-y2)
        if abs(den)<1e-8:continue
        xx,yy=np.meshgrid(np.arange(xmin,xmax+1)+.5,np.arange(ymin,ymax+1)+.5)
        w0=((y1-y2)*(xx-x2)+(x2-x1)*(yy-y2))/den
        w1=((y2-y0)*(xx-x2)+(x0-x2)*(yy-y2))/den
        w2=1-w0-w1
        depth=w0*points[face[0],2]+w1*points[face[1],2]+w2*points[face[2],2]
        region=zbuffer[ymin:ymax+1,xmin:xmax+1]
        mask=(w0>=-1e-6)&(w1>=-1e-6)&(w2>=-1e-6)&(depth>region)
        if not mask.any():continue
        coords=w0[...,None]*uv[face[0]]+w1[...,None]*uv[face[1]]+w2[...,None]*uv[face[2]]
        tx=np.clip((coords[:,:,0]*texture.shape[1]).astype(int),0,texture.shape[1]-1)
        ty=np.clip((coords[:,:,1]*texture.shape[0]).astype(int),0,texture.shape[0]-1)
        lighting=w0*shade[face[0]]+w1*shade[face[1]]+w2*shade[face[2]]
        color=np.clip(texture[ty,tx]*lighting[...,None],0,255).astype(np.uint8)
        region[mask]=depth[mask]
        canvas[ymin:ymax+1,xmin:xmax+1][mask]=color[mask]
    return Image.fromarray(canvas)


if __name__=='__main__':
    doc,raw=read_glb(OUTPUT)
    choices=[('Idle',0,0),('Walk',.225,-20),('Run',.16,-20),('Jump',.1,-20)]
    image=Image.new('RGB',(420*len(choices),760),(23,32,42))
    draw=ImageDraw.Draw(image)
    for i,(name,t,yaw) in enumerate(choices):
        vertices,normals=pose(doc,raw,name,t)
        assert np.all(np.isfinite(vertices))
        image.paste(render(doc,raw,vertices,normals,yaw),(i*420,40))
        draw.text((i*420+25,20),name.upper(),fill=(255,202,119))
        print('Rendered',name,flush=True)
    output=Path(sys.argv[1]) if len(sys.argv)>1 else OUTPUT.with_name('rig_preview.png')
    image.save(output)
    print(output)
