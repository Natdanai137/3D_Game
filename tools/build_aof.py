from pathlib import Path
root = Path(__file__).resolve().parents[1]
resources=[]
nodes=[]
def vec(v): return 'Vector3('+', '.join(str(x) for x in v)+')'
def material(name,color):
    resources.append(f'[sub_resource type="StandardMaterial3D" id="{name}"]\nalbedo_color = Color({color}, 1)\nroughness = 0.86\n')
for name,c in [('orange','0.95, 0.29, 0.055'),('cuff','0.65, 0.14, 0.025'),('skin','0.72, 0.43, 0.26'),('hair','0.075, 0.044, 0.03'),('pants','0.075, 0.12, 0.19'),('sole','0.82, 0.86, 0.83'),('shoe','0.10, 0.17, 0.19'),('bag','0.12, 0.25, 0.25'),('trim','0.31, 0.47, 0.42'),('cream','0.97, 0.84, 0.59'),('eye','0.025, 0.022, 0.02')]: material(name,c)
def pivot(name,parent,pos):
    nodes.append(f'[node name="{name}" type="Node3D" parent="{parent}"]\nposition = {vec(pos)}\n')
def part(name,parent,pos,size,mat,kind='box',rot=None):
    mid='mesh_'+str(len(resources))
    if kind=='sphere':
        resources.append(f'[sub_resource type="SphereMesh" id="{mid}"]\nradius = 0.5\nheight = 1.0\nradial_segments = 10\nrings = 5\n')
    else: resources.append(f'[sub_resource type="BoxMesh" id="{mid}"]\nsize = Vector3(1, 1, 1)\n')
    node=f'[node name="{name}" type="MeshInstance3D" parent="{parent}"]\nposition = {vec(pos)}\nscale = {vec(size)}\nmesh = SubResource("{mid}")\nmaterial_override = SubResource("{mat}")\n'
    if rot: node+='rotation = '+vec(rot)+'\n'
    nodes.append(node)
pivot('Body','.',(0,0,0))
part('Hoodie','Body',(0,1.06,0),(.64,.64,.43),'orange','sphere')
part('Hem','Body',(0,.82,0),(.47,.12,.32),'cuff')
part('Pocket','Body',(0,.98,.198),(.29,.16,.025),'cuff')
part('PocketFace','Body',(0,1,.217),(.27,.12,.025),'orange')
part('Hood','Body',(0,1.35,-.085),(.53,.3,.40),'orange','sphere')
part('HoodOpening','Body',(0,1.40,.01),(.34,.1,.28),'cuff','sphere')
part('Neck','Body',(0,1.4,.025),(.19,.22,.18),'skin','sphere')
part('Head','Body',(0,1.63,.018),(.44,.46,.39),'skin','sphere')
part('HairCap','Body',(0,1.78,-.025),(.46,.23,.40),'hair','sphere')
for x,a in [(-.145,-.2),(0,.08),(.14,.3)]:
    part('Fringe'+str(len(nodes)),'Body',(x,1.77,.171),(.17,.13,.075),'hair',rot=(0,0,a))
for x in [-.228,.228]: part('Ear'+str(len(nodes)),'Body',(x,1.62,.015),(.09,.14,.11),'skin','sphere')
for x in [-.089,.089]:
    part('Eye'+str(len(nodes)),'Body',(x,1.655,.197),(.038,.055,.015),'eye')
    part('Brow'+str(len(nodes)),'Body',(x,1.71,.186),(.072,.02,.02),'hair')
part('Nose','Body',(0,1.605,.207),(.055,.064,.06),'skin','sphere')
part('Smile','Body',(0,1.55,.184),(.078,.012,.012),'hair')
part('Backpack','Body',(0,1.105,-.285),(.46,.53,.24),'bag','sphere')
part('BagPocket','Body',(0,1.0,-.405),(.32,.21,.075),'trim')
part('BagPatch','Body',(0,1.2,-.409),(.12,.1,.025),'cream')
for x in [-.205,.205]:
    part('Strap'+str(len(nodes)),'Body',(x,1.16,.17),(.055,.38,.045),'bag',rot=(0,0,-x*.4))
for x in [-.065,.065]: part('Drawstring'+str(len(nodes)),'Body',(x,1.22,.215),(.018,.18,.018),'cream')
for side,x in [('Left',-.35),('Right',.35)]:
    pivot(side+'Arm','Body',(x,1.28,0))
    path='Body/'+side+'Arm'
    part('Sleeve',path,(0,-.2,0),(.21,.43,.24),'orange','sphere')
    part('Cuff',path,(0,-.40,0),(.16,.10,.18),'cuff')
    part('Hand',path,(0,-.49,.02),(.17,.18,.18),'skin','sphere')
for side,x in [('Left',-.145),('Right',.145)]:
    pivot(side+'Leg','Body',(x,.80,0))
    path='Body/'+side+'Leg'
    part('Trouser',path,(0,-.30,0),(.22,.60,.25),'pants')
    part('Shoe',path,(0,-.68,.065),(.25,.18,.38),'shoe')
    part('Sole',path,(0,-.765,.065),(.26,.06,.39),'sole')
    part('Laces',path,(0,-.597,.105),(.14,.012,.12),'cream')
header='[gd_scene format=3]\n\n[ext_resource type="Script" path="res://Scripts/AofVisual.gd" id="1"]\n\n'
scene=header+'\n'.join(resources)+'\n[node name="Aof" type="Node3D"]\nscript = ExtResource("1")\n\n'+'\n'.join(nodes)
(root/'Assets/Models/Aof/Aof.tscn').write_text(scene,encoding='utf-8')

