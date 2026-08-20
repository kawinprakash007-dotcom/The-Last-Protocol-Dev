# Asset Pipeline Specifications — Premium Visual Production

Place incoming assets in these exact directories using the designated naming specifications so that they link with the cinematic scene nodes and AnimationPlayer paths automatically.

## Character Models
Path: `res://story/assets/characters/`

1. **Dr. Helen Vance (Hero)**:
   - File Path: `res://story/assets/characters/dr_helen_vance_hero.glb` (or `.gltf`/`.fbx`)
   - Naming inside GLB: The root bone must be named `Root` or `Skeleton3D`, with limbs conforming to:
     - `Spine`
     - `Neck` / `Head`
     - `Shoulder_L` -> `UpperArm_L` -> `Forearm_L` -> `Hand_L`
     - `Shoulder_R` -> `UpperArm_R` -> `Forearm_R` -> `Hand_R`
     - `Thigh_L` -> `Knee_L` -> `Foot_L`
     - `Thigh_R` -> `Knee_R` -> `Foot_R`

2. **Humanoid Robot**:
   - File Path: `res://story/assets/characters/humanoid_robot.glb` (or `.gltf`/`.fbx`)
   - Naming inside GLB: Same skeleton hierarchy convention.

## Environment & Props
Path: `res://story/assets/props/`

1. **Laboratory Equipment**: `res://story/assets/props/laboratory_props.glb`
2. **Flying Traffic Cars**: `res://story/assets/props/futuristic_vehicles.glb`

## Materials
Shared materials are located under `res://story/assets/materials/`.
