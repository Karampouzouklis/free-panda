extends Skeleton3D

@export var muscle_strength: float = 3000.0
@export var muscle_damping: float = 80.0
@export var max_angular_speed: float = 50.0
@export var target_skeleton_path := NodePath("../../../PandaAnimation/Armature/Skeleton3D")

var physics_bones: Array[PhysicalBone3D] = []
var target_bone_ids: Array[int] = []
var target_initial_rotations: Array[Quaternion] = []
var physical_initial_rotations: Array[Quaternion] = []
var target_skeleton: Skeleton3D

func _ready() -> void:
	var simulator := get_node_or_null("PhysicalBoneSimulator3D") as PhysicalBoneSimulator3D
	if simulator == null:
		push_error("PhysicalBoneSimulator3D container not found.")
		return

	target_skeleton = get_node_or_null(target_skeleton_path) as Skeleton3D
	if target_skeleton == null:
		push_error("Animation target skeleton not found at '%s'." % target_skeleton_path)
		return

	for child in simulator.get_children():
		if child is PhysicalBone3D:
			var physical_bone := child as PhysicalBone3D
			var bone_id := physical_bone.get_bone_id()
			if bone_id < 0:
				push_error("Physical bone '%s' is not bound to a skeleton bone." % physical_bone.name)
				continue

			var target_bone_id := target_skeleton.find_bone(get_bone_name(bone_id))
			if target_bone_id < 0:
				push_error("Animation target is missing bone '%s'." % get_bone_name(bone_id))
				continue

			physics_bones.append(physical_bone)
			target_bone_ids.append(target_bone_id)
			target_initial_rotations.append(
				(
					target_skeleton.global_transform
					* target_skeleton.get_bone_global_pose_no_override(target_bone_id)
				).basis.get_rotation_quaternion().normalized()
			)
			physical_initial_rotations.append(
				physical_bone.global_transform.basis.get_rotation_quaternion().normalized()
			)

	if physics_bones.is_empty():
		push_error("No valid physical bones were found.")
		return

	simulator.physical_bones_start_simulation()

func _physics_process(delta: float) -> void:
	if target_skeleton == null:
		return

	for index in range(physics_bones.size()):
		var physical_bone := physics_bones[index]
		var source_rotation := (
			target_skeleton.global_transform
			* target_skeleton.get_bone_global_pose_no_override(target_bone_ids[index])
		).basis.get_rotation_quaternion().normalized()
		var animation_delta := source_rotation * target_initial_rotations[index].inverse()
		var target_rotation := (animation_delta * physical_initial_rotations[index]).normalized()
		var current_rotation := physical_bone.global_transform.basis.get_rotation_quaternion().normalized()
		var rotation_error := (target_rotation * current_rotation.inverse()).normalized()
		var angle := rotation_error.get_angle()
		if angle > PI:
			angle -= TAU

		var angular_acceleration := (
			rotation_error.get_axis() * angle * muscle_strength
			- physical_bone.angular_velocity * muscle_damping
		)
		physical_bone.angular_velocity = (
			physical_bone.angular_velocity + angular_acceleration * delta
		).limit_length(max_angular_speed)
