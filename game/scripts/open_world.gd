extends Node3D

## Phase 1: 3D open-world rendering and world-generation foundation.
## Gameplay, player driving, NPCs and streamed districts are separate follow-up phases.

const WORLD_EXTENT := 1500.0
const TERRAIN_CELLS := 112
const TREE_COUNT := 190
const ROAD_SEGMENTS := 220
const ROAD_WIDTH := 12.0

var terrain_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()
var terrain_material: ShaderMaterial
var road_material: StandardMaterial3D
var foliage_rng := RandomNumberGenerator.new()

func _ready() -> void:
	_setup_noise()
	_setup_environment()
	_build_terrain()
	_build_road()
	_build_road_markings()
	_build_vegetation()
	_build_distant_ridge()
	_setup_camera()

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
	var broad := terrain_noise.get_noise_2d(x, z) * 74.0
	var detail := detail_noise.get_noise_2d(x, z) * 8.0
	var ridge := 1.0 - absf(terrain_noise.get_noise_2d(x * 0.42 + 600.0, z * 0.42 - 900.0))
	return broad + detail + pow(maxf(0.0, ridge), 3.0) * 28.0

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
	sun.rotation_degrees = Vector3(-38.0, -28.0, 0.0)
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
	var step := (WORLD_EXTENT * 2.0) / float(TERRAIN_CELLS)
	for z_index in range(TERRAIN_CELLS + 1):
		for x_index in range(TERRAIN_CELLS + 1):
			var x := -WORLD_EXTENT + float(x_index) * step
			var z := -WORLD_EXTENT + float(z_index) * step
			vertices.append(Vector3(x, _height_at(x, z), z))
			uvs.append(Vector2(float(x_index) / 8.0, float(z_index) / 8.0))
	for z_index in range(TERRAIN_CELLS):
		for x_index in range(TERRAIN_CELLS):
			var a := z_index * (TERRAIN_CELLS + 1) + x_index
			var b := a + 1
			var c := a + TERRAIN_CELLS + 1
			var d := c + 1
			indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var surface_tool := SurfaceTool.new()
	surface_tool.create_from(mesh, 0)
	surface_tool.generate_normals()
	var smooth_mesh := surface_tool.commit()
	var terrain := MeshInstance3D.new()
	terrain.name = "ProceduralLandscape"
	terrain.mesh = smooth_mesh
	terrain.material_override = _make_terrain_material()
	add_child(terrain)

func _make_terrain_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
varying vec3 world_pos;
varying vec3 world_normal;
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() {
	vec4 wp = MODEL_MATRIX * vec4(VERTEX, 1.0);
	world_pos = wp.xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	float slope = 1.0 - clamp(world_normal.y, 0.0, 1.0);
	float n = noise2(world_pos.xz * 0.075) * 0.5 + noise2(world_pos.xz * 0.31) * 0.18;
	vec3 grass = mix(vec3(0.105, 0.155, 0.105), vec3(0.22, 0.255, 0.15), n);
	vec3 soil = mix(vec3(0.22, 0.19, 0.14), vec3(0.34, 0.28, 0.20), n);
	vec3 rock = mix(vec3(0.25, 0.245, 0.22), vec3(0.43, 0.40, 0.34), n);
	float soil_band = smoothstep(0.34, 0.58, n) * (1.0 - smoothstep(0.62, 0.82, n));
	vec3 base = mix(grass, soil, soil_band * 0.48);
	base = mix(base, rock, smoothstep(0.24, 0.68, slope));
	ALBEDO = base;
	ROUGHNESS = 0.94;
	SPECULAR = 0.12;
}
"""
	terrain_material = ShaderMaterial.new()
	terrain_material.shader = shader
	return terrain_material

func _road_center(x: float) -> float:
	return sin(x * 0.00115) * 155.0 + sin(x * 0.0031 + 0.7) * 34.0

func _build_road() -> void:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in range(ROAD_SEGMENTS + 1):
		var x := -WORLD_EXTENT + float(i) * (WORLD_EXTENT * 2.0 / float(ROAD_SEGMENTS))
		var z := _road_center(x)
		var ahead_z := _road_center(x + 3.0)
		var side := Vector3(0.0, 0.0, 1.0)
		var tangent := Vector3(3.0, 0.0, ahead_z - z).normalized()
		side = tangent.cross(Vector3.UP).normalized()
		var center := Vector3(x, _height_at(x, z) + 1.25, z)
		vertices.append(center - side * ROAD_WIDTH * 0.5)
		vertices.append(center + side * ROAD_WIDTH * 0.5)
		uvs.append(Vector2(0.0, float(i) * 0.8))
		uvs.append(Vector2(1.0, float(i) * 0.8))
	for i in range(ROAD_SEGMENTS):
		var a := i * 2
		indices.append_array(PackedInt32Array([a, a + 2, a + 1, a + 1, a + 2, a + 3]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var st := SurfaceTool.new()
	st.create_from(mesh, 0)
	st.generate_normals()
	var road := MeshInstance3D.new()
	road.name = "WindingAsphaltRoad"
	road.mesh = st.commit()
	road.material_override = _make_road_material()
	add_child(road)

func _make_road_material() -> StandardMaterial3D:
	road_material = StandardMaterial3D.new()
	road_material.albedo_color = Color("#292d30")
	road_material.roughness = 0.91
	road_material.metallic = 0.03
	return road_material

func _build_road_markings() -> void:
	var marking_material := StandardMaterial3D.new()
	marking_material.albedo_color = Color("#d6c59b")
	marking_material.roughness = 0.8
	for i in range(74):
		var x := -WORLD_EXTENT + float(i) * 40.0
		var z := _road_center(x)
		var ahead_z := _road_center(x + 2.0)
		var direction := Vector3(2.0, 0.0, ahead_z - z).normalized()
		var stripe := MeshInstance3D.new()
		var stripe_mesh := BoxMesh.new()
		stripe_mesh.size = Vector3(8.0, 0.08, 0.22)
		stripe.mesh = stripe_mesh
		stripe.position = Vector3(x, _height_at(x, z) + 2.0, z)
		stripe.rotation.y = -atan2(direction.z, direction.x)
		stripe.material_override = marking_material
		add_child(stripe)

func _build_vegetation() -> void:
	var trunk_material := StandardMaterial3D.new()
	trunk_material.albedo_color = Color("#51402c")
	trunk_material.roughness = 1.0
	var leaf_material := StandardMaterial3D.new()
	leaf_material.albedo_color = Color("#304a32")
	leaf_material.roughness = 0.96
	for i in range(TREE_COUNT):
		var x := foliage_rng.randf_range(-WORLD_EXTENT + 35.0, WORLD_EXTENT - 35.0)
		var z := foliage_rng.randf_range(-WORLD_EXTENT + 35.0, WORLD_EXTENT - 35.0)
		var road_distance := absf(z - _road_center(x))
		if road_distance < 28.0:
			continue
		var height := _height_at(x, z)
		var scale := foliage_rng.randf_range(0.75, 1.55)
		var tree := Node3D.new()
		tree.position = Vector3(x, height, z)
		tree.scale = Vector3.ONE * scale
		var trunk := MeshInstance3D.new()
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.34
		trunk_mesh.bottom_radius = 0.55
		trunk_mesh.height = 5.2
		trunk.mesh = trunk_mesh
		trunk.position.y = 2.6
		trunk.material_override = trunk_material
		tree.add_child(trunk)
		var crown := MeshInstance3D.new()
		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = 2.5
		crown_mesh.height = 5.4
		crown.mesh = crown_mesh
		crown.position.y = 6.0
		crown.material_override = leaf_material
		tree.add_child(crown)
		add_child(tree)

func _build_distant_ridge() -> void:
	var ridge_material := StandardMaterial3D.new()
	ridge_material.albedo_color = Color("#59605b")
	ridge_material.roughness = 1.0
	for i in range(13):
		var ridge := MeshInstance3D.new()
		var mountain := PrismMesh.new()
		mountain.size = Vector3(170.0 + float(i % 4) * 38.0, 115.0 + float(i % 5) * 22.0, 95.0)
		ridge.mesh = mountain
		ridge.position = Vector3(-1100.0 + float(i) * 185.0, 22.0, -1080.0 - float(i % 3) * 80.0)
		ridge.rotation.y = float(i) * 0.37
		ridge.material_override = ridge_material
		add_child(ridge)

func _setup_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "WorldOverviewCamera"
	camera.position = Vector3(0.0, 118.0, 205.0)
	camera.rotation_degrees = Vector3(-25.0, 0.0, 0.0)
	camera.fov = 62.0
	camera.near = 0.1
	camera.far = 2600.0
	camera.current = true
	add_child(camera)
