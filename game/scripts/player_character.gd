extends CharacterBody3D
class_name IHPlayerCharacter

var move_axis := Vector2.ZERO
var sprinting := false
var walk_speed := 4.4
var run_speed := 6.8
var gravity := 19.0
var visual_root: Node3D
var head_pivot: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_knee: Node3D
var right_knee: Node3D
var left_ankle: Node3D
var right_ankle: Node3D
var left_elbow: Node3D
var right_elbow: Node3D
var left_wrist: Node3D
var right_wrist: Node3D
var left_eye: MeshInstance3D
var right_eye: MeshInstance3D
var left_pupil: MeshInstance3D
var right_pupil: MeshInstance3D
var mouth_detail: MeshInstance3D
var left_eyebrow: MeshInstance3D
var right_eyebrow: MeshInstance3D
var left_fingers: Array[MeshInstance3D] = []
var right_fingers: Array[MeshInstance3D] = []
var facial_clock := 0.0
var blink_amount := 0.0
var next_blink_at := 2.8
var left_foot_ik_offset := 0.0
var right_foot_ik_offset := 0.0
var left_foot_ground_pitch := 0.0
var right_foot_ground_pitch := 0.0
var left_foot_ground_roll := 0.0
var right_foot_ground_roll := 0.0
var anim_clock := 0.0
var moving_amount := 0.0
var grounded_amount := 1.0
var movement_intent_world := Vector3.ZERO
var turn_intensity := 0.0
var locomotion_accel := 0.0
var previous_horizontal_velocity := Vector3.ZERO
var idle_clock := 0.0

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
	movement_intent_world = world_direction
	var target_horizontal := Vector3(world_direction.x * speed, 0.0, world_direction.z * speed)
	var before_horizontal := Vector3(velocity.x, 0.0, velocity.z)
	velocity.x = move_toward(velocity.x, target_horizontal.x, delta * 18.0)
	velocity.z = move_toward(velocity.z, target_horizontal.z, delta * 18.0)
	var after_horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var acceleration_delta := (after_horizontal - previous_horizontal_velocity).length() / maxf(delta, 0.001)
	locomotion_accel = move_toward(locomotion_accel, clampf(acceleration_delta / 18.0, 0.0, 1.0), delta * 7.0)
	previous_horizontal_velocity = after_horizontal
	if before_horizontal.length() > 0.25 and world_direction.length() > 0.08:
		var cross_y := before_horizontal.normalized().cross(world_direction).y
		turn_intensity = move_toward(turn_intensity, clampf(cross_y * 2.2, -1.0, 1.0), delta * 5.0)
	else:
		turn_intensity = move_toward(turn_intensity, 0.0, delta * 3.5)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.25
	if world_direction.length() > 0.08:
		rotation.y = lerp_angle(rotation.y, atan2(-world_direction.x, -world_direction.z), 1.0 - exp(-delta * 11.0))
	moving_amount = move_toward(moving_amount, 1.0 if after_horizontal.length() > 0.35 else 0.0, delta * (7.0 if world_direction.length() > 0.08 else 4.0))
	if moving_amount < 0.02:
		idle_clock += delta
	move_and_slide()
	grounded_amount = move_toward(grounded_amount, 1.0 if is_on_floor() else 0.0, delta * 8.0)
	_update_foot_grounding(delta)
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
		var ankle := Node3D.new()
		ankle.name = "AnkleJoint"
		ankle.position = Vector3(0, -0.31, -0.015)
		knee.add_child(ankle)
		var foot := BoxMesh.new()
		foot.size = Vector3(0.23, 0.13, 0.38)
		_mesh(ankle, foot, Vector3(0, -0.045, -0.06), shoes)
		if side < 0:
			left_leg = leg
			left_knee = knee
			left_ankle = ankle
		else:
			right_leg = leg
			right_knee = knee
			right_ankle = ankle
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
		var wrist := Node3D.new()
		wrist.name = "WristJoint"
		wrist.position = Vector3(0, -0.36, -0.02)
		elbow.add_child(wrist)
		var hand := SphereMesh.new()
		hand.radius = 0.095
		hand.height = 0.16
		_mesh(wrist, hand, Vector3(0, -0.015, -0.015), skin)
		if side < 0:
			left_arm = arm
			left_elbow = elbow
			left_wrist = wrist
		else:
			right_arm = arm
			right_elbow = elbow
			right_wrist = wrist
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
		var eye_part := _mesh(visual_root, eye, Vector3(side * 0.078, 2.015, -0.211), eye_white)
		if side < 0.0:
			left_eye = eye_part
		else:
			right_eye = eye_part
		var pupil := SphereMesh.new()
		pupil.radius = 0.013
		pupil.height = 0.018
		var pupil_part := _mesh(visual_root, pupil, Vector3(side * 0.078, 2.014, -0.235), eye_dark)
		if side < 0.0:
			left_pupil = pupil_part
		else:
			right_pupil = pupil_part
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
	mouth_detail = _mesh(visual_root, mouth, Vector3(0, 1.875, -0.226), lip_mat)
	for side in [-1.0, 1.0]:
		var brow := BoxMesh.new()
		brow.size = Vector3(0.09, 0.025, 0.035)
		var brow_part := _mesh(visual_root, brow, Vector3(side * 0.079, 2.065, -0.215), hair)
		brow_part.rotation.z = side * -0.10
		if side < 0.0:
			left_eyebrow = brow_part
		else:
			right_eyebrow = brow_part
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
	# Fingers and thumbs are attached to each wrist so they follow arm motion.
	for side in [-1.0, 1.0]:
		var wrist := left_wrist if side < 0.0 else right_wrist
		if wrist == null:
			continue
		for finger in range(4):
			var digit := CapsuleMesh.new()
			digit.radius = 0.018
			digit.height = 0.105
			var finger_x := (float(finger) - 1.5) * 0.043
			var finger_part := _mesh(wrist, digit, Vector3(finger_x, -0.055, -0.035), skin)
			finger_part.rotation.x = -0.12
			if side < 0.0:
				left_fingers.append(finger_part)
			else:
				right_fingers.append(finger_part)
		var thumb := CapsuleMesh.new()
		thumb.radius = 0.022
		thumb.height = 0.09
		var thumb_part := _mesh(wrist, thumb, Vector3(side * 0.085, -0.015, -0.015), skin)
		thumb_part.rotation.z = -side * 0.65

	# Give the complete head/face assembly its own pivot while preserving its world pose.
	head_pivot = Node3D.new()
	head_pivot.name = "HeadNeckPivot"
	head_pivot.position = Vector3(0.0, 1.76, 0.0)
	visual_root.add_child(head_pivot)
	for part in visual_root.get_children():
		if part == head_pivot or not (part is Node3D):
			continue
		if part.position.y >= 1.84:
			part.reparent(head_pivot, true)


func _update_foot_grounding(delta: float) -> void:
	# Four short probes approximate the shoe contact plane across heel, toe and edges.
	# This is still procedural contact adaptation, not planted-foot two-bone IK.
	var space := get_world_3d().direct_space_state
	var foot_specs := [
		{"ankle": left_ankle, "side": -1.0},
		{"ankle": right_ankle, "side": 1.0}
	]
	for spec in foot_specs:
		var ankle: Node3D = spec["ankle"]
		if ankle == null:
			continue

		var side: float = spec["side"]
		var foot_center: Vector3 = ankle.global_position + Vector3(0.0, 0.42, -0.06)
		var probe_offsets: Array[Vector3] = [
			Vector3(-0.075, 0.0, 0.13),
			Vector3(0.075, 0.0, 0.13),
			Vector3(-0.075, 0.0, -0.19),
			Vector3(0.075, 0.0, -0.19)
		]
		var hit_position_sum := Vector3.ZERO
		var hit_normal_sum := Vector3.ZERO
		var hit_count := 0
		for local_offset in probe_offsets:
			var probe_start: Vector3 = foot_center + global_transform.basis * local_offset
			var query := PhysicsRayQueryParameters3D.create(probe_start, probe_start + Vector3.DOWN * 0.82)
			query.exclude = [get_rid()]
			var hit := space.intersect_ray(query)
			if hit.is_empty():
				continue
			hit_position_sum += hit.position
			var hit_normal: Vector3 = hit.normal
			if hit_normal.y < 0.0:
				hit_normal = -hit_normal
			hit_normal_sum += hit_normal
			hit_count += 1

		var target_offset := 0.0
		var target_pitch := 0.0
		var target_roll := 0.0
		if hit_count >= 2 and is_on_floor():
			var average_hit_position: Vector3 = hit_position_sum / float(hit_count)
			var average_normal: Vector3 = (hit_normal_sum / float(hit_count)).normalized()
			var desired_foot_y: float = average_hit_position.y + 0.075
			target_offset = clampf(desired_foot_y - (ankle.global_position.y - 0.31 + 0.045), -0.12, 0.12)
			# Average contact normals reduce sudden ankle flips on seams and small props.
			var local_normal: Vector3 = (global_transform.basis.inverse() * average_normal).normalized()
			target_pitch = clampf(atan2(local_normal.z, maxf(local_normal.y, 0.01)), -0.18, 0.18)
			target_roll = clampf(atan2(-local_normal.x, maxf(local_normal.y, 0.01)), -0.16, 0.16)
		if side < 0.0:
			left_foot_ik_offset = move_toward(left_foot_ik_offset, target_offset, delta * 3.8)
			left_foot_ground_pitch = move_toward(left_foot_ground_pitch, target_pitch, delta * 2.8)
			left_foot_ground_roll = move_toward(left_foot_ground_roll, target_roll, delta * 2.8)
			ankle.position.y = -0.31 + left_foot_ik_offset
		else:
			right_foot_ik_offset = move_toward(right_foot_ik_offset, target_offset, delta * 3.8)
			right_foot_ground_pitch = move_toward(right_foot_ground_pitch, target_pitch, delta * 2.8)
			right_foot_ground_roll = move_toward(right_foot_ground_roll, target_roll, delta * 2.8)
			ankle.position.y = -0.31 + right_foot_ik_offset

func _animate_face(delta: float, active_gait: float) -> void:
	facial_clock += delta
	if facial_clock >= next_blink_at:
		blink_amount = 1.0
		next_blink_at = facial_clock + 2.4 + fmod(facial_clock * 1.73, 2.1)
	blink_amount = move_toward(blink_amount, 0.0, delta * 11.0)
	var exertion := clampf((Vector2(velocity.x, velocity.z).length() - walk_speed * 0.72) / maxf(run_speed - walk_speed * 0.72, 0.01), 0.0, 1.0)
	var eye_height := maxf(0.12, 1.0 - blink_amount * 0.92 - exertion * 0.08)
	if left_eye:
		left_eye.scale.y = eye_height
	if right_eye:
		right_eye.scale.y = eye_height
	var gaze_x := clampf(movement_intent_world.dot(global_transform.basis.x), -1.0, 1.0) * 0.012
	var gaze_y := clampf(movement_intent_world.dot(global_transform.basis.z), -1.0, 1.0) * 0.006
	if left_pupil:
		left_pupil.position.x = -0.078 + gaze_x
		left_pupil.position.y = 0.254 + gaze_y
	if right_pupil:
		right_pupil.position.x = 0.078 + gaze_x
		right_pupil.position.y = 0.254 + gaze_y
	# Brows and mouth respond subtly to exertion, avoiding a permanently static face.
	var brow_tension := exertion * 0.055 + locomotion_accel * 0.025
	if left_eyebrow:
		left_eyebrow.rotation.z = -0.10 + brow_tension
	if right_eyebrow:
		right_eyebrow.rotation.z = 0.10 - brow_tension
	if mouth_detail:
		mouth_detail.scale.x = 1.0 + exertion * 0.10 + sin(facial_clock * 0.8) * 0.018 * (1.0 - active_gait)
		mouth_detail.scale.y = 1.0 + exertion * 0.16
	# Small finger curl adds a restrained hand response during faster movement.
	var finger_curl := exertion * 0.10 + active_gait * 0.025
	for finger in left_fingers:
		finger.rotation.x = -0.12 - finger_curl
	for finger in right_fingers:
		finger.rotation.x = -0.12 - finger_curl


func _animate_character(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var run_blend := 1.0 if (sprinting or Input.is_key_pressed(KEY_SHIFT)) and horizontal_speed > walk_speed * 0.72 else 0.0
	var speed_ratio := clampf(horizontal_speed / maxf(run_speed, 0.01), 0.0, 1.0)
	var active_gait := moving_amount * grounded_amount
	var start_stop_weight := clampf(locomotion_accel, 0.0, 1.0) * active_gait
	var turn_weight := turn_intensity * active_gait
	var cadence := lerpf(6.2, 9.4, run_blend) * lerpf(0.55, 1.0, speed_ratio)
	anim_clock += delta * cadence
	var gait := sin(anim_clock)
	var left_phase := cos(anim_clock)
	var right_phase := cos(anim_clock + PI)
	var stride_strength := lerpf(0.40, 0.58, run_blend) * active_gait
	var swing := gait * stride_strength
	var knee_bend := maxf(0.0, left_phase) * lerpf(0.48, 0.78, run_blend) * active_gait
	var opposite_knee_bend := maxf(0.0, right_phase) * lerpf(0.48, 0.78, run_blend) * active_gait
	# Lift only the swing-phase foot; keep the stance-phase foot close to the ground.
	var left_lift := pow(maxf(0.0, left_phase), 1.35) * lerpf(0.055, 0.095, run_blend) * active_gait
	var right_lift := pow(maxf(0.0, right_phase), 1.35) * lerpf(0.055, 0.095, run_blend) * active_gait
	var left_toe_roll := maxf(0.0, -left_phase) * 0.16 * active_gait
	var right_toe_roll := maxf(0.0, -right_phase) * 0.16 * active_gait
	if left_leg:
		left_leg.rotation.x = swing
	if right_leg:
		right_leg.rotation.x = -swing
	if left_knee:
		left_knee.rotation.x = knee_bend
	if right_knee:
		right_knee.rotation.x = opposite_knee_bend
	if left_ankle:
		left_ankle.position.y = -0.31 + left_lift + left_foot_ik_offset * (1.0 - clampf(left_lift / 0.095, 0.0, 1.0))
		left_ankle.rotation.x = -swing * 0.48 - knee_bend * 0.12 + left_toe_roll + left_foot_ground_pitch * (1.0 - clampf(left_lift / 0.095, 0.0, 1.0))
		left_ankle.rotation.z = left_foot_ground_roll * (1.0 - clampf(left_lift / 0.095, 0.0, 1.0))
	if right_ankle:
		right_ankle.position.y = -0.31 + right_lift + right_foot_ik_offset * (1.0 - clampf(right_lift / 0.095, 0.0, 1.0))
		right_ankle.rotation.x = swing * 0.48 - opposite_knee_bend * 0.12 + right_toe_roll + right_foot_ground_pitch * (1.0 - clampf(right_lift / 0.095, 0.0, 1.0))
		right_ankle.rotation.z = right_foot_ground_roll * (1.0 - clampf(right_lift / 0.095, 0.0, 1.0))
	if left_arm:
		left_arm.rotation.x = -swing * 0.82
		left_arm.rotation.z = -0.035 * active_gait
	if right_arm:
		right_arm.rotation.x = swing * 0.82
		right_arm.rotation.z = 0.035 * active_gait
	if left_elbow:
		left_elbow.rotation.x = -0.12 - knee_bend * 0.30
	if right_elbow:
		right_elbow.rotation.x = -0.12 - opposite_knee_bend * 0.30
	# Subtle wrist counter-motion keeps hands aligned with the forearm swing.
	if left_wrist:
		left_wrist.rotation.x = 0.10 + swing * 0.12
		left_wrist.rotation.z = -0.035 * active_gait
	if right_wrist:
		right_wrist.rotation.x = 0.10 - swing * 0.12
		right_wrist.rotation.z = 0.035 * active_gait
	_animate_face(delta, active_gait)
	if head_pivot:
		var head_look_yaw := clampf(movement_intent_world.dot(global_transform.basis.x), -1.0, 1.0) * 0.12
		var head_look_pitch := clampf(locomotion_accel, 0.0, 1.0) * -0.025
		head_pivot.rotation.y = lerp_angle(head_pivot.rotation.y, head_look_yaw, 1.0 - exp(-delta * 5.0))
		head_pivot.rotation.x = lerpf(head_pivot.rotation.x, head_look_pitch + sin(idle_clock * 0.7) * 0.012 * (1.0 - active_gait), 1.0 - exp(-delta * 4.0))
	if visual_root:
		var idle_sway := sin(idle_clock * 1.15) * 0.006 * (1.0 - active_gait)
		var turn_lean := -turn_weight * lerpf(0.025, 0.055, run_blend)
		var start_pitch := -start_stop_weight * 0.035
		visual_root.position.y = absf(gait) * lerpf(0.012, 0.035, run_blend) * active_gait + idle_sway
		visual_root.rotation.z = turn_lean + idle_sway * 0.35
		visual_root.rotation.x = start_pitch
		visual_root.rotation.y = sin(anim_clock * 0.5) * 0.025 * active_gait
		visual_root.rotation.x += clampf(movement_intent_world.x, -1.0, 1.0) * 0.012
		var breath := 1.0 + sin(idle_clock * 1.7) * 0.003 * (1.0 - active_gait)
		visual_root.scale = Vector3(1.0, breath, 1.0)
