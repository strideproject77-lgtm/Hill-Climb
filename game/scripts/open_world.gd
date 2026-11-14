extends Node3D

## Drivable 3D vehicle test slice. Sialkot GIS map is a separate data-driven phase.
const WORLD_EXTENT := 1500.0
const TERRAIN_CELLS := 112
const TREE_COUNT := 190
const ROAD_SEGMENTS := 220
const ROAD_WIDTH := 12.0

var terrain_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()
var foliage_rng := RandomNumberGenerator.new()
var vehicle: StrideVehicle
var follow_camera: Camera3D
var speed_label: Label
var control_buttons: Dictionary = {}
var using_sialkot_map := false

func _ready() -> void:
	_setup_noise()
	_setup_environment()
	var city_map = preload("res://scripts/sialkot_map.gd").new()
	if city_map.load_city_map():
		using_sialkot_map = true
		add_child(city_map)
		vehicle = StrideVehicle.new()
		vehicle.name = "PlayerSedan"
		vehicle.position = Vector3(0.0, 2.4, 0.0)
		vehicle.rotation.y = PI * 0.5
		add_child(vehicle)
		_setup_camera()
		_setup_mobile_hud()
		return
	_build_terrain()
	_build_road()
	_build_road_markings()
	_build_vegetation()
	_build_distant_ridge()
	_spawn_vehicle()
	_setup_camera()
	_setup_mobile_hud()

func _process(delta: float) -> void:
	if is_instance_valid(vehicle):
		_update_camera(delta)
		speed_label.text = "%03d km/h" % int(vehicle.speed_kmh)
		follow_camera.fov = lerpf(68.0, 76.0, clampf(vehicle.speed_kmh / 150.0, 0.0, 1.0))

func _setup_noise() -> void:
	terrain_noise.seed = 48127
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	terrain_noise.frequency = 0.0018
	terrain_noise.fractal_octaves = 5
	terrain_noise.fractal_lacunarity = 2.1
	terrain_noise.fractal_gain = 0.48
	detail_noise.seed = 9271
	detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	detail_noise.frequency = 0.012
	detail_noise.fractal_octaves = 3
	foliage_rng.seed = 741903

func _height_at(x: float, z: float) -> float:
	var broad := terrain_noise.get_noise_2d(x,z)*74.0
	var detail := detail_noise.get_noise_2d(x,z)*8.0
	var ridge := 1.0-absf(terrain_noise.get_noise_2d(x*0.42+600.0,z*0.42-900.0))
	return broad+detail+pow(maxf(0.0,ridge),3.0)*28.0

func _setup_environment() -> void:
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#263e5b")
	sky_material.sky_horizon_color = Color("#c4a98b")
	sky_material.ground_bottom_color = Color("#202a2a")
	sky_material.ground_horizon_color = Color("#8b806d")
	sky_material.sun_angle_max = 18.0
	sky_material.use_debanding = true
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.05
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.08
	environment.adjustment_saturation = 0.92
	world_env.environment = environment
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.name = "LateAfternoonSun"
	sun.rotation_degrees = Vector3(-38,-28,0)
	sun.light_color = Color("#ffe0b5")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 180.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)

func _build_terrain() -> void:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var step := WORLD_EXTENT*2.0/float(TERRAIN_CELLS)
	for zi in range(TERRAIN_CELLS+1):
		for xi in range(TERRAIN_CELLS+1):
			var x := -WORLD_EXTENT+float(xi)*step
			var z := -WORLD_EXTENT+float(zi)*step
			vertices.append(Vector3(x,_height_at(x,z),z))
			uvs.append(Vector2(float(xi)/8.0,float(zi)/8.0))
	for zi in range(TERRAIN_CELLS):
		for xi in range(TERRAIN_CELLS):
			var a := zi*(TERRAIN_CELLS+1)+xi
			var b := a+1
			var c := a+TERRAIN_CELLS+1
			var d := c+1
			indices.append_array(PackedInt32Array([a,c,b,b,c,d]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var st := SurfaceTool.new()
	st.create_from(mesh,0)
	st.generate_normals()
	var smooth_mesh := st.commit()
	var terrain := MeshInstance3D.new()
	terrain.name = "ProceduralLandscape"
	terrain.mesh = smooth_mesh
	terrain.material_override = _make_terrain_material()
	add_child(terrain)
	var terrain_body := StaticBody3D.new()
	terrain_body.name = "TerrainCollision"
	var terrain_shape := CollisionShape3D.new()
	var concave := ConcavePolygonShape3D.new()
	concave.set_faces(smooth_mesh.get_faces())
	terrain_shape.shape = concave
	terrain_body.add_child(terrain_shape)
	add_child(terrain_body)

func _make_terrain_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
varying vec3 world_pos;
varying vec3 world_normal;
float hash21(vec2 p) {
 p=fract(p*vec2(123.34,456.21)); p+=dot(p,p+45.32); return fract(p.x*p.y);
}
float noise2(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash21(i),hash21(i+vec2(1.0,0.0)),f.x),mix(hash21(i+vec2(0.0,1.0)),hash21(i+vec2(1.0,1.0)),f.x),f.y);
}
void vertex() {
 vec4 wp=MODEL_MATRIX*vec4(VERTEX,1.0); world_pos=wp.xyz; world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
 float slope=1.0-clamp(world_normal.y,0.0,1.0);
 float n=noise2(world_pos.xz*0.075)*0.5+noise2(world_pos.xz*0.31)*0.18;
 vec3 grass=mix(vec3(0.105,0.155,0.105),vec3(0.22,0.255,0.15),n);
 vec3 soil=mix(vec3(0.22,0.19,0.14),vec3(0.34,0.28,0.20),n);
 vec3 rock=mix(vec3(0.25,0.245,0.22),vec3(0.43,0.40,0.34),n);
 float band=smoothstep(0.34,0.58,n)*(1.0-smoothstep(0.62,0.82,n));
 ALBEDO=mix(mix(grass,soil,band*0.48),rock,smoothstep(0.24,0.68,slope));
 ROUGHNESS=0.94; SPECULAR=0.12;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

func _road_center(x: float) -> float:
	return sin(x*0.00115)*155.0+sin(x*0.0031+0.7)*34.0

func _build_road() -> void:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in range(ROAD_SEGMENTS+1):
		var x := -WORLD_EXTENT+float(i)*(WORLD_EXTENT*2.0/float(ROAD_SEGMENTS))
		var z := _road_center(x)
		var tangent := Vector3(3.0,0.0,_road_center(x+3.0)-z).normalized()
		var side := tangent.cross(Vector3.UP).normalized()
		var center := Vector3(x,_height_at(x,z)+1.25,z)
		vertices.append(center-side*ROAD_WIDTH*0.5)
		vertices.append(center+side*ROAD_WIDTH*0.5)
		uvs.append(Vector2(0,float(i)*0.8))
		uvs.append(Vector2(1,float(i)*0.8))
	for i in range(ROAD_SEGMENTS):
		var a := i*2
		indices.append_array(PackedInt32Array([a,a+1,a+2,a+1,a+3,a+2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var st := SurfaceTool.new()
	st.create_from(mesh,0)
	st.generate_normals()
	var road_mesh := st.commit()
	var road := MeshInstance3D.new()
	road.name = "WindingAsphaltRoad"
	road.mesh = road_mesh
	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_color = Color("#292d30")
	asphalt.roughness = 0.91
	asphalt.metallic = 0.03
	road.material_override = asphalt
	add_child(road)
	var road_body := StaticBody3D.new()
	road_body.name = "RoadCollision"
	var road_shape := CollisionShape3D.new()
	var road_collision := ConcavePolygonShape3D.new()
	road_collision.set_faces(road_mesh.get_faces())
	road_shape.shape = road_collision
	road_body.add_child(road_shape)
	add_child(road_body)

func _build_road_markings() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#d6c59b")
	material.roughness = 0.8
	for i in range(74):
		var x := -WORLD_EXTENT+float(i)*40.0
		var z := _road_center(x)
		var stripe := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(8.0,0.08,0.22)
		stripe.mesh = box
		stripe.position = Vector3(x,_height_at(x,z)+2.0,z)
		stripe.rotation.y = -atan2(_road_center(x+2.0)-z,2.0)
		stripe.material_override = material
		add_child(stripe)

func _build_vegetation() -> void:
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color("#51402c")
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color("#304a32")
	for i in range(TREE_COUNT):
		var x := foliage_rng.randf_range(-WORLD_EXTENT+35.0,WORLD_EXTENT-35.0)
		var z := foliage_rng.randf_range(-WORLD_EXTENT+35.0,WORLD_EXTENT-35.0)
		if absf(z-_road_center(x))<28.0:
			continue
		var tree := Node3D.new()
		tree.position = Vector3(x,_height_at(x,z),z)
		tree.scale = Vector3.ONE*foliage_rng.randf_range(0.75,1.55)
		var trunk := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius=0.34
		cylinder.bottom_radius=0.55
		cylinder.height=5.2
		trunk.mesh=cylinder
		trunk.position.y=2.6
		trunk.material_override=trunk_mat
		tree.add_child(trunk)
		var crown := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius=2.5
		sphere.height=5.4
		crown.mesh=sphere
		crown.position.y=6.0
		crown.material_override=leaf_mat
		tree.add_child(crown)
		add_child(tree)

func _build_distant_ridge() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color=Color("#59605b")
	for i in range(13):
		var ridge := MeshInstance3D.new()
		var mountain := PrismMesh.new()
		mountain.size=Vector3(170.0+float(i%4)*38.0,115.0+float(i%5)*22.0,95.0)
		ridge.mesh=mountain
		ridge.position=Vector3(-1100.0+float(i)*185.0,22.0,-1080.0-float(i%3)*80.0)
		ridge.rotation.y=float(i)*0.37
		ridge.material_override=material
		add_child(ridge)

func _spawn_vehicle() -> void:
	vehicle = StrideVehicle.new()
	vehicle.name = "PlayerSedan"
	vehicle.position = Vector3(0.0,_height_at(0.0,_road_center(0.0))+2.2,_road_center(0.0))
	vehicle.rotation.y = PI * 0.5
	add_child(vehicle)

func _setup_camera() -> void:
	follow_camera = Camera3D.new()
	follow_camera.name = "VehicleChaseCamera"
	follow_camera.fov = 68.0
	follow_camera.far = 1800.0
	follow_camera.current = true
	add_child(follow_camera)
	follow_camera.global_position = vehicle.global_position+Vector3(0,5,9)
	follow_camera.look_at(vehicle.global_position+Vector3.UP,Vector3.UP)

func _update_camera(delta: float) -> void:
	var behind := -vehicle.global_transform.basis.z.normalized()
	var target := vehicle.global_position+behind*8.8+Vector3.UP*4.2
	follow_camera.global_position=follow_camera.global_position.lerp(target,1.0-exp(-delta*4.2))
	follow_camera.look_at(vehicle.global_position+Vector3.UP*1.05+vehicle.linear_velocity*0.08,Vector3.UP)

func _setup_mobile_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name="DrivingHUD"
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	speed_label=Label.new()
	speed_label.position=Vector2(24,22)
	speed_label.add_theme_font_size_override("font_size",25)
	speed_label.add_theme_color_override("font_color",Color("#f4e7cb"))
	root.add_child(speed_label)
	var location := Label.new()
	location.position=Vector2(26,57)
	location.text = "SIALKOT  •  OPENSTREETMAP PILOT" if using_sialkot_map else "FREE DRIVE  •  PHYSICS TEST AREA"
	location.add_theme_font_size_override("font_size",12)
	location.add_theme_color_override("font_color",Color("#d3c4a4"))
	root.add_child(location)
	_add_touch_button(root,"STEER LEFT","◀",Vector2(22,-118),Vector2(94,-34),false,"left")
	_add_touch_button(root,"STEER RIGHT","▶",Vector2(104,-118),Vector2(176,-34),false,"right")
	_add_touch_button(root,"BRAKE","BRAKE",Vector2(-188,-104),Vector2(-102,-28),true,"brake")
	_add_touch_button(root,"ACCELERATE","DRIVE",Vector2(-94,-142),Vector2(-22,-28),true,"throttle")

func _add_touch_button(root: Control, accessible_name: String, caption: String, top_left: Vector2, bottom_right: Vector2, right_side: bool, control_name: String) -> void:
	var button := Button.new()
	button.name=accessible_name.replace(" ","")
	button.text=caption
	button.focus_mode=Control.FOCUS_NONE
	button.mouse_filter=Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size",17 if caption.length()<5 else 13)
	button.add_theme_color_override("font_color",Color("#f4ead6"))
	var normal := StyleBoxFlat.new()
	normal.bg_color=Color("#17232c",0.78)
	normal.border_color=Color("#b88c50",0.85)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(14)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color=Color("#9a612f",0.92)
	button.add_theme_stylebox_override("normal",normal)
	button.add_theme_stylebox_override("hover",normal)
	button.add_theme_stylebox_override("pressed",pressed)
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT if right_side else Control.PRESET_BOTTOM_LEFT)
	button.offset_left=top_left.x
	button.offset_top=top_left.y
	button.offset_right=bottom_right.x
	button.offset_bottom=bottom_right.y
	button.button_down.connect(_on_button_down.bind(control_name))
	button.button_up.connect(_on_button_up.bind(control_name))
	root.add_child(button)
	control_buttons[control_name]=button

func _on_button_down(name: String) -> void:
	match name:
		"left": vehicle.set_drive_controls(vehicle.throttle_input,vehicle.brake_input,-1.0)
		"right": vehicle.set_drive_controls(vehicle.throttle_input,vehicle.brake_input,1.0)
		"throttle": vehicle.set_drive_controls(1.0,vehicle.brake_input,vehicle.steer_input)
		"brake": vehicle.set_drive_controls(vehicle.throttle_input,1.0,vehicle.steer_input)

func _on_button_up(name: String) -> void:
	match name:
		"left","right": vehicle.set_drive_controls(vehicle.throttle_input,vehicle.brake_input,0.0)
		"throttle": vehicle.set_drive_controls(0.0,vehicle.brake_input,vehicle.steer_input)
		"brake": vehicle.set_drive_controls(vehicle.throttle_input,0.0,vehicle.steer_input)
