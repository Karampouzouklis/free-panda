extends Node3D

@export var move_speed := 4.0
@export var velocity_response := 5.0
@export var max_acceleration := 20.0

@onready var root_physical_bone: PhysicalBone3D = get_node(
	"Panda2/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Bone"
)


func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	var desired_velocity := Vector3(input_vector.x, 0.0, input_vector.y) * move_speed
	var current_velocity := Vector3(
		root_physical_bone.linear_velocity.x,
		0.0,
		root_physical_bone.linear_velocity.z
	)
	var acceleration := (desired_velocity - current_velocity) * velocity_response
	root_physical_bone.apply_central_impulse(
		acceleration.limit_length(max_acceleration) * root_physical_bone.mass
	)
