extends VehicleBody3D
class_name StrideVehicle

const ENGINE_POWER := 980.0
const BRAKE_POWER := 128.0
const MAX_STEER := 0.50
const STEER_RESPONSE := 5.0

var throttle_input := 0.0
var brake_input := 0.0
var steer_input := 0.0
var speed_kmh := 0.0
var traction_limiter := 1.0
var model_root: Node3D
var left_front_door: Node3D
var right_front_door: Node3D
var door_open_amount := 0.0
var door_tween: Tween
var driver_seat: Marker3D
var steering_wheel: Node3D
var brake_lights: Array[MeshInstance3D] = []

func _ready() -> void:
	mass = 1420.0
	linear_damp = 0.035
	angular_damp = 0.8
	continuous_cd = true
	can_sleep = false
	_add_chassis_collision()
	model_root = Node3D.new()
	model_root.name = "VehicleVisuals"
	model_root.rotation.y = PI
	add_child(model_root)
	_build_vehicle_model()
	_add_wheel(Vector3(-0.91, -0.43, 1.34), true, false, "FrontLeft")
	_add_wheel(Vector3(0.91, -0.43, 1.34), true, false, "FrontRight")
	_add_wheel(Vector3(-0.91, -0.43, -1.34), false, true, "RearLeft")
	_add_wheel(Vector3(0.91, -0.43, -1.34), false, true, "RearRight")

func _physics_process(delta: float) -> void:
	var gas_key := Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var brake_key := Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	var steer_key := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var throttle := maxf(throttle_input, 1.0 if gas_key else 0.0)
	var braking := maxf(brake_input, 1.0 if brake_key else 0.0)
	var steer_axis := steer_input if absf(steer_input) > 0.01 else steer_key
	var speed_ratio := clampf(speed_kmh / 220.0,0.0,1.0)
	# Progressive torque delivery and speed-sensitive steering keep the
	# high-powered rear-drive coupe controllable on narrow city streets.
	var torque_curve := lerpf(1.0,0.62,speed_ratio)
	var traction_target := 0.78 if absf(steer_axis) > 0.35 and speed_kmh > 65.0 else 1.0
	traction_limiter = move_toward(traction_limiter,traction_target if throttle > 0.0 else 1.0,delta * 2.8)
	engine_force = throttle * ENGINE_POWER * torque_curve * traction_limiter
	brake = braking * BRAKE_POWER
	var steer_limit := lerpf(MAX_STEER,0.20,speed_ratio)
	steering = move_toward(steering, -steer_axis * steer_limit, delta * STEER_RESPONSE)
	linear_damp = lerpf(0.035,0.11,speed_ratio)
	angular_damp = lerpf(0.8,1.35,speed_ratio)
	if is_instance_valid(steering_wheel):
		steering_wheel.rotation.z = -steering * 0.72
	speed_kmh = linear_velocity.length() * 3.6

func set_drive_controls(gas: float, brake_value: float, steering_value: float) -> void:
	throttle_input = clampf(gas, 0.0, 1.0)
	brake_input = clampf(brake_value, 0.0, 1.0)
	steer_input = clampf(steering_value, -1.0, 1.0)

func _add_chassis_collision() -> void:
	var collision := CollisionShape3D.new()
	collision.name = "ChassisCollision"
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.82, 0.62, 4.15)
	collision.shape = shape
	collision.position = Vector3(0.0, 0.43, 0.0)
	add_child(collision)

func _paint(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material

func _build_vehicle_model() -> void:
	var paint := _paint(Color("#344f67"), 0.68, 0.27)
	var trim := _paint(Color("#111820"), 0.25, 0.48)
	var glass := _paint(Color("#172c39"), 0.42, 0.16)
	var chrome := _paint(Color("#aab6bd"), 0.86, 0.22)
	var lamps := _paint(Color("#fff0c9"), 0.18, 0.16)
	lamps.emission_enabled = true
	lamps.emission = Color("#ffe8b4")
	lamps.emission_energy_multiplier = 0.7
	var tail := _paint(Color("#9c2630"), 0.22, 0.25)
	tail.emission_enabled = true
	tail.emission = Color("#d51f2c")
	tail.emission_energy_multiplier = 0.45

	_add_hull([
		{"z":-2.08,"half":0.72,"bottom":0.08,"top":0.43},
		{"z":-1.38,"half":0.88,"bottom":0.02,"top":0.60},
		{"z":0.92,"half":0.86,"bottom":0.02,"top":0.55},
		{"z":1.92,"half":0.76,"bottom":0.08,"top":0.46}
	], paint, "SculptedBody")
	_add_hull([
		{"z":-1.12,"half":0.66,"bottom":0.56,"top":1.12},
		{"z":-0.55,"half":0.61,"bottom":0.58,"top":1.42},
		{"z":0.62,"half":0.61,"bottom":0.56,"top":1.40},
		{"z":1.12,"half":0.66,"bottom":0.50,"top":1.04}
	], glass, "PanoramicCabin")
	_add_box("RoofPanel", Vector3(1.02,0.075,1.34), Vector3(0,1.39,0.02), paint)
	_add_box("FrontBumper", Vector3(1.68,0.17,0.13), Vector3(0,0.18,-2.10), trim)
	_add_box("RearBumper", Vector3(1.65,0.16,0.13), Vector3(0,0.20,1.98), trim)
	_add_box("FrontGrille", Vector3(0.72,0.20,0.035), Vector3(0,0.36,-2.16), trim)
	_add_box("FrontGrilleChrome", Vector3(0.62,0.025,0.045), Vector3(0,0.36,-2.185), chrome)
	_add_box("HeadlightLeft", Vector3(0.34,0.13,0.045), Vector3(-0.55,0.47,-2.12), lamps)
	_add_box("HeadlightRight", Vector3(0.34,0.13,0.045), Vector3(0.55,0.47,-2.12), lamps)
	_add_box("TailLightLeft", Vector3(0.34,0.14,0.045), Vector3(-0.53,0.43,1.96), tail)
	_add_box("TailLightRight", Vector3(0.34,0.14,0.045), Vector3(0.53,0.43,1.96), tail)
	_add_box("LeftMirror", Vector3(0.18,0.12,0.22), Vector3(-0.92,0.72,-0.78), paint)
	_add_box("RightMirror", Vector3(0.18,0.12,0.22), Vector3(0.92,0.72,-0.78), paint)
	_add_box("FrontPlate", Vector3(0.42,0.10,0.025), Vector3(0,0.20,-2.19), chrome)
	_add_box("RearPlate", Vector3(0.42,0.10,0.025), Vector3(0,0.23,2.04), chrome)
	for side in [-1.0, 1.0]:
		_add_box("CoupeSideGlass", Vector3(0.018,0.43,1.45), Vector3(side * 0.635,1.02,0.03), glass)
		_add_box("RearQuarterGlass", Vector3(0.018,0.30,0.42), Vector3(side * 0.625,1.00,0.92), glass)
		_add_box("SideSkirt", Vector3(0.12,0.16,2.05), Vector3(side * 0.87,0.16,0.05), trim)
		_add_box("FrontFenderVent", Vector3(0.025,0.18,0.30), Vector3(side * 0.885,0.47,-1.30), trim)
		_add_box("FrontIndicator", Vector3(0.035,0.075,0.18), Vector3(side * 0.89,0.40,-1.72), lamps)
		_add_box("WideRearHaunch", Vector3(0.12,0.22,0.82), Vector3(side * 0.875,0.37,1.12), paint)
	_add_box("HoodCreaseLeft", Vector3(0.025,0.018,0.92), Vector3(-0.48,0.615,-1.58), chrome)
	_add_box("HoodCreaseRight", Vector3(0.025,0.018,0.92), Vector3(0.48,0.615,-1.58), chrome)
	_add_box("Dashboard", Vector3(1.02,0.13,0.32), Vector3(0,0.94,-0.62), trim)
	# Original high-performance coupe detailing: wide M-style stance, deep
	# front intakes, splitter, rear diffuser, quad exhausts and cabin trim.
	_add_box("FrontSplitter", Vector3(1.72,0.075,0.30), Vector3(0,0.095,-2.12), trim)
	_add_box("LowerIntake", Vector3(1.12,0.16,0.045), Vector3(0,0.255,-2.19), glass)
	_add_box("IntakeLeft", Vector3(0.28,0.20,0.05), Vector3(-0.62,0.27,-2.17), trim)
	_add_box("IntakeRight", Vector3(0.28,0.20,0.05), Vector3(0.62,0.27,-2.17), trim)
	_add_box("RearDiffuser", Vector3(1.42,0.10,0.26), Vector3(0,0.10,2.02), trim)
	for exhaust_x in [-0.55,-0.38,0.38,0.55]:
		var exhaust := CylinderMesh.new()
		exhaust.top_radius = 0.055
		exhaust.bottom_radius = 0.055
		exhaust.height = 0.12
		var pipe := MeshInstance3D.new()
		pipe.mesh = exhaust
		pipe.rotation.x = PI * 0.5
		pipe.position = Vector3(exhaust_x,0.19,2.12)
		pipe.material_override = chrome
		model_root.add_child(pipe)
	_add_box("RearSpoiler", Vector3(1.32,0.055,0.18), Vector3(0,0.69,1.72), trim)
	_add_box("RearSpoilerLeftMount", Vector3(0.06,0.18,0.08), Vector3(-0.48,0.61,1.68), chrome)
	_add_box("RearSpoilerRightMount", Vector3(0.06,0.18,0.08), Vector3(0.48,0.61,1.68), chrome)
	_add_box("HoodPowerBulge", Vector3(0.54,0.035,0.74), Vector3(0,0.625,-1.54), paint)
	_add_box("CenterConsole", Vector3(0.20,0.16,0.62), Vector3(0,0.82,-0.05), trim)
	_add_box("DriverSeatBase", Vector3(0.48,0.20,0.48), Vector3(-0.34,0.68,0.30), trim)
	_add_box("DriverSeatBack", Vector3(0.48,0.62,0.18), Vector3(-0.34,1.00,0.48), trim)
	_add_box("PassengerSeatBase", Vector3(0.48,0.20,0.48), Vector3(0.34,0.68,0.30), trim)
	_add_box("PassengerSeatBack", Vector3(0.48,0.62,0.18), Vector3(0.34,1.00,0.48), trim)
	steering_wheel = Node3D.new()
	steering_wheel.name = "SteeringWheelPivot"
	steering_wheel.position = Vector3(-0.34,0.98,-0.60)
	model_root.add_child(steering_wheel)
	var wheel_ring := TorusMesh.new()
	wheel_ring.inner_radius = 0.13
	wheel_ring.outer_radius = 0.17
	var wheel_visual := MeshInstance3D.new()
	wheel_visual.mesh = wheel_ring
	wheel_visual.rotation.x = PI * 0.5
	wheel_visual.material_override = trim
	steering_wheel.add_child(wheel_visual)
	driver_seat = Marker3D.new()
	driver_seat.name = "DriverSeatAnchor"
	driver_seat.position = Vector3(-0.34,0.82,0.22)
	model_root.add_child(driver_seat)
	_create_front_door(-1.0)
	_create_front_door(1.0)

func _create_front_door(side: float) -> void:
	var hinge := Node3D.new()
	hinge.name = "DriverDoorHinge" if side < 0.0 else "PassengerDoorHinge"
	hinge.position = Vector3(side * 0.84,0.55,-0.92)
	model_root.add_child(hinge)
	var door_material := _paint(Color("#344f67"),0.68,0.27)
	var glass_material := _paint(Color("#172c39"),0.42,0.16)
	var door_panel := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(0.075,0.42,0.98)
	door_panel.mesh = panel_mesh
	door_panel.position = Vector3(side * 0.015,-0.12,0.43)
	door_panel.material_override = door_material
	hinge.add_child(door_panel)
	var window := MeshInstance3D.new()
	var window_mesh := BoxMesh.new()
	window_mesh.size = Vector3(0.035,0.34,0.90)
	window.mesh = window_mesh
	window.position = Vector3(side * 0.005,0.29,0.40)
	window.material_override = glass_material
	hinge.add_child(window)
	var handle := MeshInstance3D.new()
	var handle_mesh := BoxMesh.new()
	handle_mesh.size = Vector3(0.025,0.035,0.18)
	handle.mesh = handle_mesh
	handle.position = Vector3(side * 0.058,0.02,0.42)
	handle.material_override = _paint(Color("#bdc6cc"),0.85,0.2)
	hinge.add_child(handle)
	var trim_line := MeshInstance3D.new()
	var line_mesh := BoxMesh.new()
	line_mesh.size = Vector3(0.018,0.018,0.82)
	trim_line.mesh = line_mesh
	trim_line.position = Vector3(side * 0.058,-0.28,0.42)
	trim_line.material_override = _paint(Color("#18212a"),0.35,0.42)
	hinge.add_child(trim_line)
	if side < 0.0:
		left_front_door = hinge
	else:
		right_front_door = hinge

func set_doors_open(open: bool, duration: float = 0.42) -> void:
	if door_tween and door_tween.is_running():
		door_tween.kill()
	door_tween = create_tween().set_parallel(true)
	var target := 1.0 if open else 0.0
	door_tween.tween_method(_set_door_amount,door_open_amount,target,duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func _set_door_amount(amount: float) -> void:
	door_open_amount = clampf(amount,0.0,1.0)
	if is_instance_valid(left_front_door):
		left_front_door.rotation.y = -door_open_amount * 1.08
	if is_instance_valid(right_front_door):
		right_front_door.rotation.y = door_open_amount * 1.08

func get_driver_seat_transform() -> Transform3D:
	return driver_seat.global_transform if is_instance_valid(driver_seat) else global_transform

func _add_hull(stations: Array, material: Material, node_name: String) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(stations.size() - 1):
		var a: Dictionary = stations[i]
		var b: Dictionary = stations[i + 1]
		var al := Vector3(-float(a.half),float(a.bottom),float(a.z))
		var ar := Vector3(float(a.half),float(a.bottom),float(a.z))
		var atl := Vector3(-float(a.half)*0.88,float(a.top),float(a.z))
		var atr := Vector3(float(a.half)*0.88,float(a.top),float(a.z))
		var bl := Vector3(-float(b.half),float(b.bottom),float(b.z))
		var br := Vector3(float(b.half),float(b.bottom),float(b.z))
		var btl := Vector3(-float(b.half)*0.88,float(b.top),float(b.z))
		var btr := Vector3(float(b.half)*0.88,float(b.top),float(b.z))
		_quad(surface,al,bl,btl,atl)
		_quad(surface,ar,atr,btr,br)
		_quad(surface,atl,btl,btr,atr)
		_quad(surface,al,ar,br,bl)
	surface.generate_normals()
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = surface.commit()
	instance.material_override = material
	model_root.add_child(instance)

func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)
	surface.add_vertex(a)
	surface.add_vertex(c)
	surface.add_vertex(d)

func _add_box(node_name: String, dimensions: Vector3, at: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material
	model_root.add_child(instance)

func _add_wheel(at: Vector3, steering_wheel: bool, traction_wheel: bool, wheel_name: String) -> void:
	var wheel := VehicleWheel3D.new()
	wheel.name = wheel_name
	wheel.position = at
	wheel.use_as_steering = steering_wheel
	wheel.use_as_traction = traction_wheel
	wheel.wheel_radius = 0.37
	wheel.wheel_rest_length = 0.19
	wheel.suspension_travel = 0.22
	wheel.suspension_stiffness = 38.0
	wheel.damping_compression = 0.58
	wheel.damping_relaxation = 0.72
	wheel.wheel_friction_slip = 3.1
	wheel.wheel_roll_influence = 0.12
	wheel.suspension_max_force = 6000.0
	add_child(wheel)
	var tire := MeshInstance3D.new()
	var tire_mesh := CylinderMesh.new()
	tire_mesh.top_radius = 0.37
	tire_mesh.bottom_radius = 0.37
	tire_mesh.height = 0.25
	tire.mesh = tire_mesh
	tire.rotation.z = PI*0.5
	tire.material_override = _paint(Color("#171b20"),0.02,0.92)
	wheel.add_child(tire)
	var rim := MeshInstance3D.new()
	var rim_mesh := CylinderMesh.new()
	rim_mesh.top_radius = 0.235
	rim_mesh.bottom_radius = 0.235
	rim_mesh.height = 0.265
	rim.mesh = rim_mesh
	rim.rotation.z = PI*0.5
	rim.material_override = _paint(Color("#aeb9c0"),0.88,0.2)
	wheel.add_child(rim)
	var brake_disc := MeshInstance3D.new()
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = 0.185
	disc_mesh.bottom_radius = 0.185
	disc_mesh.height = 0.045
	brake_disc.mesh = disc_mesh
	brake_disc.rotation.z = PI * 0.5
	brake_disc.material_override = _paint(Color("#737d84"),0.78,0.36)
	wheel.add_child(brake_disc)
	var hub := MeshInstance3D.new()
	var hub_mesh := CylinderMesh.new()
	hub_mesh.top_radius = 0.075
	hub_mesh.bottom_radius = 0.075
	hub_mesh.height = 0.28
	hub.mesh = hub_mesh
	hub.rotation.z = PI * 0.5
	hub.material_override = _paint(Color("#d4dbe0"),0.92,0.18)
	wheel.add_child(hub)
	var caliper := MeshInstance3D.new()
	var caliper_mesh := BoxMesh.new()
	caliper_mesh.size = Vector3(0.09,0.17,0.10)
	caliper.mesh = caliper_mesh
	caliper.position = Vector3(0.0,0.0,-0.16)
	caliper.material_override = _paint(Color("#a82e28"),0.35,0.3)
	wheel.add_child(caliper)
	for spoke_index in range(10):
		var spoke := MeshInstance3D.new()
		var spoke_mesh := BoxMesh.new()
		spoke_mesh.size = Vector3(0.035,0.22,0.035)
		spoke.mesh = spoke_mesh
		spoke.position = Vector3(0.0,0.0,0.0)
		spoke.rotation.z = TAU * float(spoke_index) / 10.0
		spoke.material_override = _paint(Color("#c3cbd0"),0.9,0.19)
		wheel.add_child(spoke)
