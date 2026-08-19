import re

with open("room_02.tscn", "r") as f:
    content = f.read()

# Add the robot scene to ext_resource
if 'uid://secrobotblockout' not in content:
    content = content.replace('[ext_resource type="Script"', '[ext_resource type="PackedScene" uid="uid://secrobotblockout" path="res://security_robot.tscn" id="8_robot"]\n[ext_resource type="Script"', 1)

# Remove the sofa and tv and appliances and vents, replace with ServerRacks
content = re.sub(r'\[node name="Sofa".*?(?=\[node|$)', '', content, flags=re.DOTALL)
content = re.sub(r'\[node name="SmartTV".*?(?=\[node|$)', '', content, flags=re.DOTALL)
content = re.sub(r'\[node name="ApplianceLeft".*?(?=\[node|$)', '', content, flags=re.DOTALL)
content = re.sub(r'\[node name="ApplianceRight".*?(?=\[node|$)', '', content, flags=re.DOTALL)
content = re.sub(r'\[node name="OverheadVent1".*?(?=\[node|$)', '', content, flags=re.DOTALL)
content = re.sub(r'\[node name="OverheadVent2".*?(?=\[node|$)', '', content, flags=re.DOTALL)

servers_and_robot = """
[sub_resource type="StandardMaterial3D" id="Material_Server"]
albedo_color = Color(0.1, 0.1, 0.1, 1)
roughness = 0.4
metallic = 0.8

[sub_resource type="BoxMesh" id="BoxMesh_Server"]
material = SubResource("Material_Server")
size = Vector3(3, 4, 6)

[sub_resource type="BoxShape3D" id="BoxShape3D_Server"]
size = Vector3(3, 4, 6)

[node name="ServerRack1" type="StaticBody3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -5, 2, 8)
[node name="Mesh" type="MeshInstance3D" parent="ServerRack1"]
mesh = SubResource("BoxMesh_Server")
[node name="Collision" type="CollisionShape3D" parent="ServerRack1"]
shape = SubResource("BoxShape3D_Server")

[node name="ServerRack2" type="StaticBody3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 5, 2, 8)
[node name="Mesh" type="MeshInstance3D" parent="ServerRack2"]
mesh = SubResource("BoxMesh_Server")
[node name="Collision" type="CollisionShape3D" parent="ServerRack2"]
shape = SubResource("BoxShape3D_Server")

[node name="ServerRack3" type="StaticBody3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -5, 2, 16)
[node name="Mesh" type="MeshInstance3D" parent="ServerRack3"]
mesh = SubResource("BoxMesh_Server")
[node name="Collision" type="CollisionShape3D" parent="ServerRack3"]
shape = SubResource("BoxShape3D_Server")

[node name="ServerRack4" type="StaticBody3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 5, 2, 16)
[node name="Mesh" type="MeshInstance3D" parent="ServerRack4"]
mesh = SubResource("BoxMesh_Server")
[node name="Collision" type="CollisionShape3D" parent="ServerRack4"]
shape = SubResource("BoxShape3D_Server")

[node name="Entities" type="Node3D" parent="."]

[node name="PatrolPoints" type="Node3D" parent="Entities"]

[node name="P1" type="Marker3D" parent="Entities/PatrolPoints"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -8, 0, 12)

[node name="P2" type="Marker3D" parent="Entities/PatrolPoints"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 8, 0, 12)

[node name="P3" type="Marker3D" parent="Entities/PatrolPoints"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 8, 0, 18)

[node name="P4" type="Marker3D" parent="Entities/PatrolPoints"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -8, 0, 18)

[node name="SecurityRobot" parent="Entities" instance=ExtResource("8_robot")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -8, 0, 12)
patrol_points = Array[NodePath]([NodePath("../PatrolPoints/P1"), NodePath("../PatrolPoints/P2"), NodePath("../PatrolPoints/P3"), NodePath("../PatrolPoints/P4")])
"""

content = content + servers_and_robot

with open("room_02.tscn", "w") as f:
    f.write(content)
