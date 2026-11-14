extends Node3D

## Compact, fictionalized Sialkot-inspired city layout.
## Real locations guide the districts; roads are deliberately compressed and
## rearranged for readable navigation and mobile gameplay, not 1:1 GIS accuracy.

const WORLD_WIDTH := 2600.0
const WORLD_DEPTH := 1900.0
var rng := RandomNumberGenerator.new()
var asphalt: StandardMaterial3D
var lane_paint: StandardMaterial3D
var sidewalk: StandardMaterial3D
var plaza_mat: StandardMaterial3D
var building_mats: Array[StandardMaterial3D] = []

func _ready() -> void:
	generate_city()

func generate_city() -> void:
	rng.seed = 731904
	_setup_materials()
	_build_ground()
	_build_primary_roads()
	_build_bazaar_grid()
	_build_cantonment_grid()
	_build_mehrajke_corridor()
	_build_ring_connectors()
	_build_city_blocks()
	_build_landmarks()
	_build_street_furniture()

func _setup_materials() -> void:
	asphalt = _mat(Color("#292d31"), 0.94)
	lane_paint = _mat(Color("#d9cba8"), 0.72)
	sidewalk = _mat(Color("#77766f"), 0.88)
	plaza_mat = _mat(Color("#8b8273"), 0.9)
	for color in ["#b7a38a", "#9c8875", "#c2b8a3", "#887d70", "#a99c89", "#d0c1a7", "#777a78"]:
		building_mats.append(_mat(Color(color), 0.92))

func _mat(color: Color, rough: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rough
	return material

func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "UrbanGround"
	var plane := PlaneMesh.new()
	plane.size = Vector2(WORLD_WIDTH, WORLD_DEPTH)
	ground.mesh = plane
	ground.position.y = -0.42
	ground.material_override = _mat(Color("#55584d"), 1.0)
	add_child(ground)
	var body := StaticBody3D.new()
	body.name = "CityGroundCollision"
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(WORLD_WIDTH, 0.8, WORLD_DEPTH)
	collision.shape = shape
	collision.position.y = -0.4
	body.add_child(collision)
	add_child(body)

func _add_road(a: Vector3, b: Vector3, width: float, name: String, markings: bool = true) -> void:
	var delta := b - a
	var length := Vector2(delta.x, delta.z).length()
	if length < 1.0:
		return
	var road := MeshInstance3D.new()
	road.name = name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, 0.12, length)
	road.mesh = mesh
	road.position = (a + b) * 0.5
	road.position.y = 0.015
	road.rotation.y = atan2(delta.x, delta.z)
	road.material_override = asphalt
	add_child(road)
	if markings and width >= 15.0:
		var stripe := MeshInstance3D.new()
		var stripe_mesh := BoxMesh.new()
		stripe_mesh.size = Vector3(0.22, 0.035, maxf(2.0, length - 5.0))
		stripe.mesh = stripe_mesh
		stripe.position = road.position + Vector3(0, 0.085, 0)
		stripe.rotation.y = road.rotation.y
		stripe.material_override = lane_paint
		add_child(stripe)

func _build_primary_roads() -> void:
	# The central crossroads represents the Clock Tower / Saddar anchor.
	_add_road(Vector3(-WORLD_WIDTH * 0.46, 0, 0), Vector3(WORLD_WIDTH * 0.46, 0, 0), 25.0, "KashmirStyleMainBoulevard")
	_add_road(Vector3(0, 0, -WORLD_DEPTH * 0.43), Vector3(0, 0, WORLD_DEPTH * 0.43), 22.0, "JammuStyleNorthSouthBoulevard")
	_add_road(Vector3(-850, 0, -390), Vector3(820, 0, 390), 17.0, "DiagonalCityConnector")
	_add_road(Vector3(-780, 0, 390), Vector3(780, 0, -390), 17.0, "CrossCityConnector")

func _build_bazaar_grid() -> void:
	# Dense, narrow streets around the old-city / Saddar-inspired core.
	for x in [-560.0, -455.0, -350.0, -245.0, -140.0, -35.0]:
		_add_road(Vector3(x, 0, -430), Vector3(x + 18.0, 0, 430), 8.5, "SaddarLane")
	for z in [-360.0, -270.0, -180.0, -90.0, 90.0, 180.0, 270.0, 360.0]:
		_add_road(Vector3(-650, 0, z), Vector3(45, 0, z + 12.0), 8.0, "BazaarMarketStreet", false)

func _build_cantonment_grid() -> void:
	# More open, orderly streets and larger blocks on the Cantonment side.
	for x in [190.0, 340.0, 490.0, 640.0, 790.0]:
		_add_road(Vector3(x, 0, -610), Vector3(x, 0, 610), 13.0, "CantonmentAvenue")
	for z in [-470.0, -310.0, -150.0, 150.0, 310.0, 470.0]:
		_add_road(Vector3(100, 0, z), Vector3(930, 0, z), 12.0, "CantonmentCrossStreet", false)

func _build_mehrajke_corridor() -> void:
	# A long, legible arterial toward the future Mehrajke-side expansion.
	_add_road(Vector3(300, 0, 185), Vector3(1190, 0, 250), 24.0, "MehrajkeDirectionArterial")
	_add_road(Vector3(350, 0, 225), Vector3(1170, 0, 290), 5.0, "MehrajkeServiceLane", false)
	for x in [540.0, 730.0, 920.0, 1080.0]:
		_add_road(Vector3(x, 0, 120), Vector3(x + 12.0, 0, 420), 10.0, "CorridorConnector", false)

func _build_ring_connectors() -> void:
	# A compact loop makes district-to-district driving more interesting.
	var points: Array[Vector3] = []
	for i in range(17):
		var angle := TAU * float(i) / 16.0
		points.append(Vector3(cos(angle) * 520.0, 0, sin(angle) * 390.0))
	for i in range(points.size() - 1):
		_add_road(points[i], points[i + 1], 14.0, "CentralRingConnector")

func _build_city_blocks() -> void:
	# Bazaar: tight low-rise blocks.
	for x in [-610.0, -505.0, -400.0, -295.0, -190.0, -85.0]:
		for z in [-315.0, -225.0, -135.0, -45.0, 45.0, 135.0, 225.0, 315.0]:
			_add_building(Vector3(x, 0, z), Vector2(58, 48), rng.randi_range(9, 19), "Bazaar")
	# Cantonment: spaced plots and larger properties.
	for x in [265.0, 415.0, 565.0, 715.0, 865.0]:
		for z in [-390.0, -230.0, -70.0, 230.0, 390.0]:
			_add_building(Vector3(x, 0, z), Vector2(78, 70), rng.randi_range(12, 27), "Cantonment")
	# Corridor: mixed roadside commercial/residential clusters.
	for x in [520.0, 680.0, 840.0, 1000.0, 1140.0]:
		_add_building(Vector3(x, 0, 390), Vector2(82, 62), rng.randi_range(8, 21), "OuterCity")

func _add_building(center: Vector3, footprint: Vector2, height: float, district: String) -> void:
	var root := Node3D.new()
	root.name = district + "Building"
	root.position = center
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(footprint.x, height, footprint.y)
	body.mesh = box
	body.position.y = height * 0.5
	body.material_override = building_mats[rng.randi_range(0, building_mats.size() - 1)]
	root.add_child(body)
	# Simple contrasting facade bands give the skyline depth without heavy assets.
	for level in range(maxi(1, int(height / 4.0))):
		var band := MeshInstance3D.new()
		var band_mesh := BoxMesh.new()
		band_mesh.size = Vector3(footprint.x * 0.82, 0.55, 0.08)
		band.mesh = band_mesh
		band.position = Vector3(0, 2.2 + float(level) * 3.2, -footprint.y * 0.5 - 0.045)
		band.material_override = lane_paint
		root.add_child(band)
	add_child(root)

func _build_landmarks() -> void:
	_add_plaza(Vector3.ZERO, Vector2(100, 100), "ClockTowerSaddarPlaza")
	_build_clock_tower()
	_build_gate(Vector3(430, 0, -20), "CantonmentGate")
	_add_wayfinding_marker(Vector3(1040, 0, 245), "MEHRAJKE ROAD")
	_add_wayfinding_marker(Vector3(-430, 0, 475), "SADDAR BAZAAR")

func _add_plaza(center: Vector3, size: Vector2, name: String) -> void:
	var plaza := MeshInstance3D.new()
	plaza.name = name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, 0.16, size.y)
	plaza.mesh = mesh
	plaza.position = center + Vector3(0, 0.09, 0)
	plaza.material_override = plaza_mat
	add_child(plaza)

func _build_clock_tower() -> void:
	var tower := Node3D.new()
	tower.name = "ClockTowerLandmark"
	tower.position = Vector3(0, 0, 0)
	var stone := _mat(Color("#c6b49a"), 0.82)
	var dark := _mat(Color("#29343b"), 0.5)
	_add_tower_part(tower, Vector3(15, 20, 15), Vector3(0, 10, 0), stone)
	_add_tower_part(tower, Vector3(10, 12, 10), Vector3(0, 26, 0), stone)
	_add_tower_part(tower, Vector3(7, 5, 7), Vector3(0, 34.5, 0), dark)
	_add_tower_part(tower, Vector3(4, 8, 4), Vector3(0, 41, 0), stone)
	for side in [Vector3(0, 26, -5.1), Vector3(0, 26, 5.1), Vector3(-5.1, 26, 0), Vector3(5.1, 26, 0)]:
		_add_tower_part(tower, Vector3(3.4, 3.4, 0.18) if absf(side.z) > 0 else Vector3(0.18, 3.4, 3.4), side, dark)
	add_child(tower)

func _add_tower_part(parent: Node3D, size: Vector3, at: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = at
	part.material_override = material
	parent.add_child(part)

func _build_gate(at: Vector3, name: String) -> void:
	var gate := Node3D.new()
	gate.name = name
	gate.position = at
	var stone := _mat(Color("#b9ad98"), 0.86)
	_add_tower_part(gate, Vector3(4, 13, 4), Vector3(-12, 6.5, 0), stone)
	_add_tower_part(gate, Vector3(4, 13, 4), Vector3(12, 6.5, 0), stone)
	_add_tower_part(gate, Vector3(28, 3, 4), Vector3(0, 13, 0), stone)
	add_child(gate)

func _add_wayfinding_marker(at: Vector3, caption: String) -> void:
	var marker := Label3D.new()
	marker.text = caption
	marker.position = at + Vector3(0, 22, 0)
	marker.font_size = 36
	marker.outline_size = 8
	marker.modulate = Color("#f2dfb8")
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(marker)

func _build_street_furniture() -> void:
	for x in [-480.0, -240.0, 240.0, 480.0, 720.0, 960.0]:
		for z in [-520.0, 520.0]:
			_add_street_light(Vector3(x, 0, z))
	for x in [-690.0, -620.0, -550.0, 970.0, 1040.0, 1110.0]:
		_add_tree(Vector3(x, 0, -560.0 if x < 0 else 520.0))

func _add_street_light(at: Vector3) -> void:
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.12
	pole_mesh.bottom_radius = 0.18
	pole_mesh.height = 8.0
	pole.mesh = pole_mesh
	pole.position = at + Vector3(0, 4, 0)
	pole.material_override = _mat(Color("#343b3b"), 0.65)
	add_child(pole)
	var lamp := MeshInstance3D.new()
	var lamp_mesh := BoxMesh.new()
	lamp_mesh.size = Vector3(1.4, 0.24, 0.55)
	lamp.mesh = lamp_mesh
	lamp.position = at + Vector3(0.65, 7.8, 0)
	lamp.material_override = _mat(Color("#e6d5aa"), 0.32)
	add_child(lamp)

func _add_tree(at: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.28
	trunk_mesh.bottom_radius = 0.42
	trunk_mesh.height = 3.8
	trunk.mesh = trunk_mesh
	trunk.position = at + Vector3(0, 1.9, 0)
	trunk.material_override = _mat(Color("#55422f"), 0.95)
	add_child(trunk)
	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 2.4
	crown_mesh.height = 4.8
	crown.mesh = crown_mesh
	crown.position = at + Vector3(0, 5.0, 0)
	crown.material_override = _mat(Color("#3e5a3b"), 0.95)
	add_child(crown)
