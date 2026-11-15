extends CharacterBody3D
class_name IHPlayerCharacter

var move_axis := Vector2.ZERO
var sprinting := false
var walk_speed := 4.4
var run_speed := 6.8
var gravity := 19.0
var visual_root: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var anim_clock := 0.0
var moving_amount := 0.0

func _ready() -> void:
	name = "PlayerCharacter"
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	floor_snap_length = 0.28
	floor_max_angle = deg_to_rad(48.0)
	_add_collision()
	_build_character()

func set_move_input(axis: Vector2, run: bool = false) -> void:
	move_axis = axis.limit_length(1.0)
	sprinting = run

func _physics_process(delta: float) -> void:
	var keyboard := Vector2(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	)
	var axis := move_axis if move_axis.length() > 0.01 else keyboard
	var speed := run_speed if sprinting or Input.is_key_pressed(KEY_SHIFT) else walk_speed
	var direction := Vector3(axis.x, 0.0, axis.y)
	if direction.length() > 1.0:
		direction = direction.normalized()
	var camera_basis := get_viewport().get_camera_3d().global_transform.basis if get_viewport().get_camera_3d() else Basis.IDENTITY
	var forward := -camera_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := camera_basis.x
	right.y = 0.0
	right = right.normalized()
	var world_direction := (right * direction.x + forward * -direction.z).normalized()
	velocity.x = move_toward(velocity.x, world_direction.x * speed, delta * 18.0)
	velocity.z = move_toward(velocity.z, world_direction.z * speed, delta * 18.0)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.25
	if world_direction.length() > 0.08:
		rotation.y = lerp_angle(rotation.y, atan2(-world_direction.x, -world_direction.z), 1.0 - exp(-delta * 11.0))
	moving_amount = move_toward(moving_amount, 1.0 if world_direction.length() > 0.08 else 0.0, delta * 5.0)
	move_and_slide()
	_animate_character(delta)

func _add_collision() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.78
	shape.shape = capsule
	shape.position.y = 0.91
	add_child(shape)

func _material(color: Color, rough: float = 0.78) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rough
	return material

func _mesh(parent: Node3D, mesh: PrimitiveMesh, at: Vector3, material: Material, node_name: String = "") -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	part.material_override = material
	if not node_name.is_empty():
		part.name = node_name
	parent.add_child(part)
	return part

func _build_character() -> void:
	visual_root = Node3D.new()
	visual_root.name = "CharacterVisual"
	add_child(visual_root)
	var skin := _material(Color("#a96f4d"))
	var shirt := _material(Color("#293d43"))
	var shirt_light := _material(Color("#3d5960"))
	var trousers := _material(Color("#242a31"))
	var shoes := _material(Color("#17191b"))
	var hair := _material(Color("#211b18"))
	var trim := _material(Color("#c4a477"), 0.55)
	var torso := CapsuleMesh.new()
	torso.radius = 0.34
	torso.height = 0.86
	_mesh(visual_root, torso, Vector3(0, 1.23, 0), shirt, "Jacket")
	var chest := BoxMesh.new()
	chest.size = Vector3(0.54, 0.36, 0.09)
	_mesh(visual_root, chest, Vector3(0, 1.31, -0.285), shirt_light)
	var neck := CylinderMesh.new()
	neck.top_radius = 0.105
	neck.bottom_radius = 0.12
	neck.height = 0.16
	_mesh(visual_root, neck, Vector3(0, 1.76, 0), skin)
	var head := SphereMesh.new()
	head.radius = 0.235
	head.height = 0.49
	_mesh(visual_root, head, Vector3(0, 1.99, 0), skin, "Head")
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.242
	hair_mesh.height = 0.22
	_mesh(visual_root, hair_mesh, Vector3(0, 2.13, 0.012), hair, "Hair")
	var face := BoxMesh.new()
	face.size = Vector3(0.28, 0.075, 0.035)
	_mesh(visual_root, face, Vector3(0, 1.99, -0.211), skin)
	for side in [-1.0, 1.0]:
		var ear := SphereMesh.new()
		ear.radius = 0.055
		ear.height = 0.11
		_mesh(visual_root, ear, Vector3(side * 0.235, 1.99, 0), skin)
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.17, 0.83, 0)
		visual_root.add_child(leg)
		var upper := CapsuleMesh.new()
		upper.radius = 0.145
		upper.height = 0.58
		_mesh(leg, upper, Vector3(0, -0.17, 0), trousers)
		var lower := CapsuleMesh.new()
		lower.radius = 0.115
		lower.height = 0.48
		_mesh(leg, lower, Vector3(0, -0.55, -0.015), trousers)
		var foot := BoxMesh.new()
		foot.size = Vector3(0.23, 0.13, 0.38)
		_mesh(leg, foot, Vector3(0, -0.79, -0.075), shoes)
		if side < 0:
			left_leg = leg
		else:
			right_leg = leg
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.39, 1.52, 0)
		visual_root.add_child(arm)
		var sleeve := CapsuleMesh.new()
		sleeve.radius = 0.125
		sleeve.height = 0.52
		_mesh(arm, sleeve, Vector3(0, -0.22, 0), shirt)
		var forearm := CapsuleMesh.new()
		forearm.radius = 0.095
		forearm.height = 0.42
		_mesh(arm, forearm, Vector3(0, -0.59, -0.015), skin)
		var hand := SphereMesh.new()
		hand.radius = 0.095
		hand.height = 0.16
		_mesh(arm, hand, Vector3(0, -0.84, -0.02), skin)
		if side < 0:
			left_arm = arm
		else:
			right_arm = arm
	# Small collar and jacket zipper details improve silhouette readability.
	var collar := BoxMesh.new()
	collar.size = Vector3(0.22, 0.07, 0.12)
	_mesh(visual_root, collar, Vector3(0, 1.66, -0.12), trim)
	var zipper := BoxMesh.new()
	zipper.size = Vector3(0.018, 0.47, 0.018)
	_mesh(visual_root, zipper, Vector3(0, 1.24, -0.337), trim)
	var eye_white := _material(Color("#eee7d8"), 0.42)
	var eye_dark := _material(Color("#211b18"), 0.35)
	for side in [-1.0, 1.0]:
		var eye := SphereMesh.new()
		eye.radius = 0.027
		eye.height = 0.035
		_mesh(visual_root, eye, Vector3(side * 0.078, 2.015, -0.211), eye_white)
		var pupil := SphereMesh.new()
		pupil.radius = 0.013
		pupil.height = 0.018
		_mesh(visual_root, pupil, Vector3(side * 0.078, 2.014, -0.235), eye_dark)
		var pocket := BoxMesh.new()
		pocket.size = Vector3(0.13, 0.15, 0.025)
		_mesh(visual_root, pocket, Vector3(side * 0.19, 1.30, -0.337), shirt)
		var cuff := CylinderMesh.new()
		cuff.top_radius = 0.102
		cuff.bottom_radius = 0.102
		cuff.height = 0.09
		_mesh(visual_root, cuff, Vector3(side * 0.39, 0.93, 0), trim)
	for side in [-1.0, 1.0]:
		var sole := BoxMesh.new()
		sole.size = Vector3(0.24, 0.045, 0.40)
		_mesh(visual_root, sole, Vector3(side * 0.17, 0.035, -0.075), trim)

func _animate_character(delta: float) -> void:
	anim_clock += delta * (7.8 if moving_amount > 0.1 else 2.0)
	var swing := sin(anim_clock) * 0.48 * moving_amount
	if left_leg:
		left_leg.rotation.x = swing
	if right_leg:
		right_leg.rotation.x = -swing
	if left_arm:
		left_arm.rotation.x = -swing * 0.72
	if right_arm:
		right_arm.rotation.x = swing * 0.72
	if visual_root:
		visual_root.position.y = absf(sin(anim_clock * 2.0)) * 0.035 * moving_amount
