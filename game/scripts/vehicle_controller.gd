extends VehicleBody3D
class_name StrideVehicle

const ENGINE_POWER := 68.0
const BRAKE_POWER := 42.0
const MAX_STEER := 0.48
const STEER_RESPONSE := 2.8

var throttle_input := 0.0
var brake_input := 0.0
var steer_input := 0.0
var speed_kmh := 0.0
var model_root: Node3D

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
	engine_force = throttle * ENGINE_POWER
	brake = braking * BRAKE_POWER
	steering = move_toward(steering, -steer_axis * MAX_STEER, delta * STEER_RESPONSE)
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
	wheel.suspension_stiffness = 31.0
	wheel.damping_compression = 0.42
	wheel.damping_relaxation = 0.52
	wheel.wheel_friction_slip = 2.0
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
