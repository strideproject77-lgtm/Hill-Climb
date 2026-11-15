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
var left_knee: Node3D
var right_knee: Node3D
var left_elbow: Node3D
var right_elbow: Node3D
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
		var knee := Node3D.new()
		knee.name = "KneeJoint"
		knee.position = Vector3(0, -0.42, -0.015)
		leg.add_child(knee)
		var lower := CapsuleMesh.new()
		lower.radius = 0.115
		lower.height = 0.48
		_mesh(knee, lower, Vector3(0, -0.13, 0), trousers)
		var foot := BoxMesh.new()
		foot.size = Vector3(0.23, 0.13, 0.38)
		_mesh(knee, foot, Vector3(0, -0.36, -0.06), shoes)
		if side < 0:
			left_leg = leg
			left_knee = knee
		else:
			right_leg = leg
			right_knee = knee
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.39, 1.52, 0)
		visual_root.add_child(arm)
		var sleeve := CapsuleMesh.new()
		sleeve.radius = 0.125
		sleeve.height = 0.52
		_mesh(arm, sleeve, Vector3(0, -0.22, 0), shirt)
		var elbow := Node3D.new()
		elbow.name = "ElbowJoint"
		elbow.position = Vector3(0, -0.43, -0.01)
		arm.add_child(elbow)
		var forearm := CapsuleMesh.new()
		forearm.radius = 0.095
		forearm.height = 0.42
		_mesh(elbow, forearm, Vector3(0, -0.14, -0.015), skin)
		var hand := SphereMesh.new()
		hand.radius = 0.095
		hand.height = 0.16
		_mesh(elbow, hand, Vector3(0, -0.38, -0.02), skin)
		if side < 0:
			left_arm = arm
			left_elbow = elbow
		else:
			right_arm = arm
			right_elbow = elbow
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


	# Face shaping: brows, nose, lips and inner ear details.
	var lip_mat := _material(Color("#754b3e"), 0.72)
	var nose_bridge := CapsuleMesh.new()
	nose_bridge.radius = 0.035
	nose_bridge.height = 0.13
	_mesh(visual_root, nose_bridge, Vector3(0, 1.965, -0.225), skin)
	var nose_tip := SphereMesh.new()
	nose_tip.radius = 0.043
	nose_tip.height = 0.055
	_mesh(visual_root, nose_tip, Vector3(0, 1.925, -0.25), skin)
	var mouth := BoxMesh.new()
	mouth.size = Vector3(0.105, 0.018, 0.018)
	_mesh(visual_root, mouth, Vector3(0, 1.875, -0.226), lip_mat)
	for side in [-1.0, 1.0]:
		var brow := BoxMesh.new()
		brow.size = Vector3(0.09, 0.025, 0.035)
		var brow_part := _mesh(visual_root, brow, Vector3(side * 0.079, 2.065, -0.215), hair)
		brow_part.rotation.z = side * -0.10
		var ear_inner := SphereMesh.new()
		ear_inner.radius = 0.027
		ear_inner.height = 0.06
		_mesh(visual_root, ear_inner, Vector3(side * 0.258, 1.99, -0.012), lip_mat)
	# Hairline, sideburns and rear hair form a complete head silhouette.
	var hairline := BoxMesh.new()
	hairline.size = Vector3(0.30, 0.055, 0.055)
	_mesh(visual_root, hairline, Vector3(0, 2.105, -0.198), hair)
	for side in [-1.0, 1.0]:
		var sideburn := CapsuleMesh.new()
		sideburn.radius = 0.045
		sideburn.height = 0.19
		_mesh(visual_root, sideburn, Vector3(side * 0.218, 2.015, -0.015), hair)
	var rear_hair := SphereMesh.new()
	rear_hair.radius = 0.225
	rear_hair.height = 0.36
	_mesh(visual_root, rear_hair, Vector3(0, 2.025, 0.105), hair)
	# Jacket lapels, shoulder shaping, pocket flaps and buttons.
	var lapel := BoxMesh.new()
	lapel.size = Vector3(0.105, 0.29, 0.045)
	var lapel_left := _mesh(visual_root, lapel, Vector3(-0.105, 1.54, -0.304), shirt_light)
	lapel_left.rotation.z = -0.20
	var lapel_right := _mesh(visual_root, lapel, Vector3(0.105, 1.54, -0.304), shirt_light)
	lapel_right.rotation.z = 0.20
	for side in [-1.0, 1.0]:
		var shoulder := SphereMesh.new()
		shoulder.radius = 0.19
		shoulder.height = 0.28
		_mesh(visual_root, shoulder, Vector3(side * 0.31, 1.49, 0), shirt)
		var pocket_flap := BoxMesh.new()
		pocket_flap.size = Vector3(0.15, 0.045, 0.035)
		_mesh(visual_root, pocket_flap, Vector3(side * 0.19, 1.39, -0.359), shirt_light)
		var pocket_button := SphereMesh.new()
		pocket_button.radius = 0.018
		pocket_button.height = 0.018
		_mesh(visual_root, pocket_button, Vector3(side * 0.19, 1.365, -0.382), trim)
	# Belt, buckle, trouser fly, knee panels and shoe construction.
	var belt := BoxMesh.new()
	belt.size = Vector3(0.55, 0.075, 0.36)
	_mesh(visual_root, belt, Vector3(0, 0.91, 0), hair)
	var buckle := BoxMesh.new()
	buckle.size = Vector3(0.105, 0.065, 0.025)
	_mesh(visual_root, buckle, Vector3(0, 0.91, -0.19), trim)
	var fly := BoxMesh.new()
	fly.size = Vector3(0.018, 0.24, 0.018)
	_mesh(visual_root, fly, Vector3(0, 0.72, -0.17), shirt_light)
	for side in [-1.0, 1.0]:
		var knee_panel := BoxMesh.new()
		knee_panel.size = Vector3(0.19, 0.19, 0.035)
		_mesh(visual_root, knee_panel, Vector3(side * 0.17, 0.43, -0.108), trousers)
		var shoe_toe := SphereMesh.new()
		shoe_toe.radius = 0.12
		shoe_toe.height = 0.11
		var toe_part := _mesh(visual_root, shoe_toe, Vector3(side * 0.17, 0.105, -0.245), shoes)
		toe_part.scale = Vector3(1.0, 0.72, 1.5)
		for lace in range(3):
			var lace_mesh := BoxMesh.new()
			lace_mesh.size = Vector3(0.13, 0.012, 0.018)
			_mesh(visual_root, lace_mesh, Vector3(side * 0.17, 0.145 + float(lace) * 0.018, -0.19 + float(lace) * 0.045), trim)
	# Individual fingers and thumbs make the hands less mitten-like.
	for side in [-1.0, 1.0]:
		for finger in range(4):
			var digit := CapsuleMesh.new()
			digit.radius = 0.018
			digit.height = 0.105
			_mesh(visual_root, digit, Vector3(side * (0.435 + float(finger) * 0.025), 0.66, -0.045), skin)
		var thumb := CapsuleMesh.new()
		thumb.radius = 0.022
		thumb.height = 0.09
		var thumb_part := _mesh(visual_root, thumb, Vector3(side * 0.34, 0.70, -0.095), skin)
		thumb_part.rotation.z = side * 0.65

func _animate_character(delta: float) -> void:
	anim_clock += delta * (7.8 if moving_amount > 0.1 else 2.0)
	var gait := sin(anim_clock)
	var opposite_gait := sin(anim_clock + PI)
	var swing := gait * 0.52 * moving_amount
	var knee_bend := maxf(0.0, cos(anim_clock)) * 0.62 * moving_amount
	var opposite_knee_bend := maxf(0.0, cos(anim_clock + PI)) * 0.62 * moving_amount
	if left_leg:
		left_leg.rotation.x = swing
	if right_leg:
		right_leg.rotation.x = -swing
	if left_knee:
		left_knee.rotation.x = knee_bend
	if right_knee:
		right_knee.rotation.x = opposite_knee_bend
	if left_arm:
		left_arm.rotation.x = -swing * 0.82
		left_arm.rotation.z = -0.035 * moving_amount
	if right_arm:
		right_arm.rotation.x = swing * 0.82
		right_arm.rotation.z = 0.035 * moving_amount
	if left_elbow:
		left_elbow.rotation.x = -0.12 - knee_bend * 0.30
	if right_elbow:
		right_elbow.rotation.x = -0.12 - opposite_knee_bend * 0.30
	if visual_root:
		visual_root.position.y = absf(gait) * 0.025 * moving_amount
		visual_root.rotation.z = sin(anim_clock * 0.5) * 0.018 * moving_amount
		visual_root.rotation.y = sin(anim_clock * 0.5) * 0.025 * moving_amount
		var breath := 1.0 + sin(anim_clock * 1.7) * 0.003
		visual_root.scale = Vector3(1.0, breath, 1.0)
