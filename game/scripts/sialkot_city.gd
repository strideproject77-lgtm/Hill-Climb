extends Node3D

## Small, detailed Clock Tower / Saddar Bazaar gameplay test district.
## Layout is intentionally compressed; it is not a survey-grade 1:1 reconstruction.
const MAP_HALF := 430.0
var rng := RandomNumberGenerator.new()
var asphalt: StandardMaterial3D
var lane: StandardMaterial3D
var pavement: StandardMaterial3D
var stone: StandardMaterial3D
var facade_mats: Array[StandardMaterial3D] = []

func _ready() -> void:
	rng.seed = 20261115
	_make_materials()
	_make_ground()
	_make_roads_and_squares()
	_make_bazaar_blocks()
	_make_clock_tower()
	_make_street_details()

func _mat(color: Color, rough: float = 0.85, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metallic
	return m

func _make_materials() -> void:
	asphalt = _mat(Color("#24282b"), 0.94)
	lane = _mat(Color("#d9c9a7"), 0.72)
	pavement = _mat(Color("#77746d"), 0.92)
	stone = _mat(Color("#c6b18e"), 0.82)
	for c in ["#bda98d", "#a98f75", "#c8bca6", "#927e6a", "#d0c1a6", "#8f9690", "#b7a38c", "#756e64"]:
		facade_mats.append(_mat(Color(c), 0.9))

func _make_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "ClockTowerDistrictGround"
	var plane := PlaneMesh.new()
	plane.size = Vector2(MAP_HALF * 2.0, MAP_HALF * 2.0)
	ground.mesh = plane
	ground.position.y = -0.28
	ground.material_override = _mat(Color("#77766a"), 1.0)
	add_child(ground)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(MAP_HALF * 2.0, 0.55, MAP_HALF * 2.0)
	shape.shape = box
	shape.position.y = -0.28
	body.add_child(shape)
	add_child(body)

func _road(a: Vector3, b: Vector3, width: float, road_name: String, markings: bool = true) -> void:
	var d := b - a
	var length := Vector2(d.x, d.z).length()
	var road := MeshInstance3D.new()
	road.name = road_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, 0.1, length)
	road.mesh = mesh
	road.position = (a + b) * 0.5
	road.position.y = -0.015
	road.rotation.y = atan2(d.x, d.z)
	road.material_override = asphalt
	add_child(road)
	if markings and width > 12.0:
		for side in [-1.0, 1.0]:
			var edge := MeshInstance3D.new()
			var stripe := BoxMesh.new()
			stripe.size = Vector3(0.13, 0.025, maxf(2.0, length - 3.0))
			edge.mesh = stripe
			edge.position = road.position + Vector3(side * width * 0.43, 0.065, 0)
			edge.rotation.y = road.rotation.y
			edge.material_override = lane
			add_child(edge)

func _make_roads_and_squares() -> void:
	_road(Vector3(-MAP_HALF,0,0), Vector3(MAP_HALF,0,0), 18.0, "SaddarMainRoad")
	_road(Vector3(0,0,-MAP_HALF), Vector3(0,0,MAP_HALF), 17.0, "ClockTowerApproach")
	_road(Vector3(-MAP_HALF,0,-205), Vector3(MAP_HALF,0,-205), 10.0, "NorthBazaarStreet", false)
	_road(Vector3(-MAP_HALF,0,205), Vector3(MAP_HALF,0,205), 10.0, "SouthBazaarStreet", false)
	_road(Vector3(-205,0,-MAP_HALF), Vector3(-205,0,MAP_HALF), 10.0, "WestBazaarStreet", false)
	_road(Vector3(205,0,-MAP_HALF), Vector3(205,0,MAP_HALF), 10.0, "EastBazaarStreet", false)
	var square := MeshInstance3D.new()
	square.name = "ClockTowerTrafficIsland"
	var disc := CylinderMesh.new()
	disc.top_radius = 22.0
	disc.bottom_radius = 23.0
	disc.height = 0.22
	square.mesh = disc
	square.position.y = 0.12
	square.material_override = _mat(Color("#a99b85"), 0.9)
	add_child(square)
	# Four pedestrian refuge corners and a tiled public apron.
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var curb := MeshInstance3D.new()
		var curb_mesh := BoxMesh.new()
		curb_mesh.size = Vector3(7.0, 0.18, 2.0)
		curb.mesh = curb_mesh
		curb.position = Vector3(cos(angle) * 29.0, 0.11, sin(angle) * 29.0)
		curb.rotation.y = angle
		curb.material_override = pavement
		add_child(curb)

func _make_bazaar_blocks() -> void:
	for x in [-310.0, -205.0, -105.0, 105.0, 205.0, 310.0]:
		for z in [-310.0, -205.0, -105.0, 105.0, 205.0, 310.0]:
			if absf(x) < 75.0 or absf(z) < 75.0:
				continue
			var width := rng.randf_range(42.0, 66.0)
			var depth := rng.randf_range(38.0, 58.0)
			var height := rng.randf_range(10.0, 21.0)
			_build_shop(Vector3(x + rng.randf_range(-8,8),0,z + rng.randf_range(-8,8)), Vector2(width,depth), height)

func _build_shop(at: Vector3, footprint: Vector2, height: float) -> void:
	var root := Node3D.new()
	root.name = "SaddarShopfront"
	root.position = at
	var base := MeshInstance3D.new()
	var body := BoxMesh.new()
	body.size = Vector3(footprint.x,height,footprint.y)
	base.mesh = body
	base.position.y = height * 0.5
	var wall_mat: Material = facade_mats[rng.randi_range(0,facade_mats.size()-1)]
	base.material_override = wall_mat
	root.add_child(base)
	var front_z := -footprint.y * 0.5 - 0.045
	# Recessed-looking shop bay, shaded signboard, and upper-floor windows.
	var shop_opening := MeshInstance3D.new()
	var opening := BoxMesh.new()
	opening.size = Vector3(footprint.x * 0.66, height * 0.36, 0.12)
	shop_opening.mesh = opening
	shop_opening.position = Vector3(0, height * 0.2, front_z)
	shop_opening.material_override = _mat(Color("#343b3a"), 0.55)
	root.add_child(shop_opening)
	var sign := MeshInstance3D.new()
	var sign_mesh := BoxMesh.new()
	sign_mesh.size = Vector3(footprint.x * 0.72, 1.05, 0.34)
	sign.mesh = sign_mesh
	sign.position = Vector3(0, height * 0.43, front_z - 0.08)
	sign.material_override = _mat(Color("#5c4532"), 0.7)
	root.add_child(sign)
	for side in [-1.0,1.0]:
		var window := MeshInstance3D.new()
		var glass := BoxMesh.new()
		glass.size = Vector3(footprint.x * 0.25, 2.4, 0.09)
		window.mesh = glass
		window.position = Vector3(side * footprint.x * 0.28, height * 0.72, front_z)
		window.material_override = _mat(Color("#344b53"), 0.2, 0.25)
		root.add_child(window)
	var awning := MeshInstance3D.new()
	var awning_mesh := BoxMesh.new()
	awning_mesh.size = Vector3(footprint.x * 0.78, 0.16, 2.2)
	awning.mesh = awning_mesh
	awning.position = Vector3(0, height * 0.38, front_z - 1.0)
	awning.material_override = _mat(Color("#80613f"), 0.72)
	root.add_child(awning)
	var collision := StaticBody3D.new()
	var collision_shape := CollisionShape3D.new()
	var collision_box := BoxShape3D.new()
	collision_box.size = Vector3(footprint.x,height,footprint.y)
	collision_shape.shape = collision_box
	collision_shape.position.y = height * 0.5
	collision.add_child(collision_shape)
	root.add_child(collision)
	add_child(root)

func _part(parent: Node3D, size: Vector3, at: Vector3, material: Material, part_name: String = "") -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material
	if not part_name.is_empty():
		instance.name = part_name
	parent.add_child(instance)
	return instance

func _make_clock_tower() -> void:
	var tower := Node3D.new()
	tower.name = "SialkotClockTowerHeroLandmark"
	var limestone := _mat(Color("#c9b796"), 0.83)
	var trim := _mat(Color("#9b8467"), 0.82)
	var dark := _mat(Color("#26343a"), 0.35)
	_part(tower, Vector3(15,18,15), Vector3(0,9,0), limestone, "ClockTowerBase")
	_part(tower, Vector3(12.5,2,12.5), Vector3(0,18.5,0), trim)
	_part(tower, Vector3(10.5,11,10.5), Vector3(0,25,0), limestone, "ClockChamber")
	_part(tower, Vector3(11.5,0.8,11.5), Vector3(0,31,0), trim)
	_part(tower, Vector3(7.5,5,7.5), Vector3(0,34,0), limestone)
	_part(tower, Vector3(4.0,8,4.0), Vector3(0,40.5,0), trim)
	var roof := PrismMesh.new()
	roof.size = Vector3(6.5,3.5,6.5)
	var cap := MeshInstance3D.new()
	cap.mesh = roof
	cap.position.y = 46.0
	cap.material_override = dark
	tower.add_child(cap)
	for face in range(4):
		var angle := float(face) * PI * 0.5
		var clock := MeshInstance3D.new()
		var dial := CylinderMesh.new()
		dial.top_radius = 2.05
		dial.bottom_radius = 2.05
		dial.height = 0.16
		clock.mesh = dial
		clock.position = Vector3(sin(angle) * 5.34,25.5,cos(angle) * 5.34)
		clock.rotation.x = PI * 0.5
		clock.rotation.y = angle
		clock.material_override = dark
		tower.add_child(clock)
		var inner := MeshInstance3D.new()
		var dial_face := CylinderMesh.new()
		dial_face.top_radius = 1.72
		dial_face.bottom_radius = 1.72
		dial_face.height = 0.18
		inner.mesh = dial_face
		inner.position = clock.position + Vector3(sin(angle) * 0.1,0,cos(angle) * 0.1)
		inner.rotation = clock.rotation
		inner.material_override = _mat(Color("#e5d9bd"), 0.42)
		tower.add_child(inner)
		# Clock hands and cardinal ticks on the front dial.
		for tick in range(12):
			var t := float(tick) * TAU / 12.0
			var mark := MeshInstance3D.new()
			var mark_mesh := BoxMesh.new()
			mark_mesh.size = Vector3(0.08,0.42,0.07)
			mark.mesh = mark_mesh
			mark.position = inner.position + Vector3(sin(t)*1.42,cos(t)*1.42,0.12)
			mark.rotation.z = -t
			mark.material_override = trim
			tower.add_child(mark)
		var hand := MeshInstance3D.new()
		var hand_mesh := BoxMesh.new()
		hand_mesh.size = Vector3(0.09,1.0,0.06)
		hand.mesh = hand_mesh
		hand.position = inner.position + Vector3(0,0.05,0.16)
		hand.rotation.z = -0.55
		hand.material_override = dark
		tower.add_child(hand)
	add_child(tower)

func _make_street_details() -> void:
	var pole_mat := _mat(Color("#333b3c"), 0.55, 0.35)
	var warm := _mat(Color("#e8d6ad"), 0.25)
	for x in [-365.0,-250.0,-125.0,125.0,250.0,365.0]:
		for z in [-365.0,365.0]:
			var pole := MeshInstance3D.new()
			var shaft := CylinderMesh.new()
			shaft.top_radius = 0.09
			shaft.bottom_radius = 0.14
			shaft.height = 7.2
			pole.mesh = shaft
			pole.position = Vector3(x,3.6,z)
			pole.material_override = pole_mat
			add_child(pole)
			var lamp := MeshInstance3D.new()
			var housing := BoxMesh.new()
			housing.size = Vector3(0.9,0.22,0.5)
			lamp.mesh = housing
			lamp.position = Vector3(x+0.42,7.1,z)
			lamp.material_override = warm
			add_child(lamp)
	for i in range(8):
		var bollard := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.12
		cylinder.bottom_radius = 0.16
		cylinder.height = 0.9
		bollard.mesh = cylinder
		var angle := float(i) * TAU / 8.0
		bollard.position = Vector3(cos(angle)*25.0,0.45,sin(angle)*25.0)
		bollard.material_override = trim
		add_child(bollard)
	var district := Label3D.new()
	district.text = "SADDAR BAZAAR"
	district.position = Vector3(-95,8,-35)
	district.font_size = 42
	district.outline_size = 8
	district.modulate = Color("#f1dfbf")
	district.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(district)
