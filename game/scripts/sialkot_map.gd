extends Node3D
## Batched renderer for the bounded OpenStreetMap Sialkot pilot extract.
const MAP_PATH := "res://data/sialkot_city.json"
var map_counts: Dictionary = {}

func load_city_map() -> bool:
	if not FileAccess.file_exists(MAP_PATH):
		return false
	var file := FileAccess.open(MAP_PATH, FileAccess.READ)
	if file == null:
		return false
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or int(data.get("schema", 0)) != 1:
		push_error("Invalid Sialkot map data schema.")
		return false
	map_counts = data.get("counts", {})
	_build_roads(data.get("roads", []))
	_build_buildings(data.get("buildings", []))
	_build_lines(data.get("railways", []), Color("#6b6257"), 1.4, "OSM_Railways")
	_build_lines(data.get("waterways", []), Color("#477d91"), 2.0, "OSM_Waterways")
	print("Sialkot OSM pilot loaded: ", map_counts)
	return true

func _road_width(tags: Dictionary) -> float:
	match str(tags.get("highway", "")):
		"motorway": return 15.0
		"trunk": return 13.0
		"primary": return 11.0
		"secondary": return 8.0
		"tertiary": return 6.2
		"residential", "living_street": return 4.8
		"service": return 3.2
		"track": return 2.8
		_: return 4.0

func _add_ribbon(surface: SurfaceTool, points: Array, width: float, y: float) -> void:
	for i in range(points.size() - 1):
		var a := Vector2(float(points[i][0]), float(points[i][1]))
		var b := Vector2(float(points[i + 1][0]), float(points[i + 1][1]))
		var d := b - a
		if d.length_squared() < 0.04:
			continue
		var side := Vector2(-d.y, d.x).normalized() * width * 0.5
		var al := Vector3(a.x + side.x, y, a.y + side.y)
		var ar := Vector3(a.x - side.x, y, a.y - side.y)
		var bl := Vector3(b.x + side.x, y, b.y + side.y)
		var br := Vector3(b.x - side.x, y, b.y - side.y)
		for p in [al, ar, bl, ar, br, bl]:
			surface.add_vertex(p)

func _build_roads(records: Array) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for record in records:
		_add_ribbon(surface, record.get("points", []), _road_width(record.get("tags", {})), 0.12)
	if surface.get_vertex_array().is_empty():
		return
	surface.generate_normals()
	var mesh := surface.commit()
	var node := MeshInstance3D.new()
	node.name = "OSM_RoadNetwork"
	node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#343638")
	mat.roughness = 0.92
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = mat
	add_child(node)
	var body := StaticBody3D.new()
	body.name = "OSM_RoadCollision"
	var collision := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(mesh.get_faces())
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _building_color(osm_id: int) -> Color:
	var palette := [Color("#a99a82"), Color("#b6a58d"), Color("#8d887c"),
		Color("#c0ad91"), Color("#9f927e"), Color("#b4b0a2")]
	return palette[abs(osm_id) % palette.size()]

func _build_buildings(records: Array) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for record in records:
		var points: Array = record.get("points", [])
		if points.size() < 4:
			continue
		var polygon := PackedVector2Array()
		for point in points:
			polygon.append(Vector2(float(point[0]), float(point[1])))
		if polygon.size() > 1 and polygon[0].distance_squared_to(polygon[-1]) < 0.01:
			polygon.remove_at(polygon.size() - 1)
		if polygon.size() < 3:
			continue
		var indices := Geometry2D.triangulate_polygon(polygon)
		if indices.is_empty():
			continue
		var height := clampf(float(record.get("height", 6.2)), 3.0, 45.0)
		var color := _building_color(int(record.get("id", 0)))
		for i in range(0, indices.size(), 3):
			for j in range(3):
				var p: Vector2 = polygon[indices[i + j]]
				surface.set_color(color)
				surface.add_vertex(Vector3(p.x, height, p.y))
		for i in range(polygon.size()):
			var a: Vector2 = polygon[i]
			var b: Vector2 = polygon[(i + 1) % polygon.size()]
			var a0 := Vector3(a.x, 0.15, a.y)
			var b0 := Vector3(b.x, 0.15, b.y)
			var a1 := Vector3(a.x, height, a.y)
			var b1 := Vector3(b.x, height, b.y)
			for p in [a0, b0, a1, b0, b1, a1]:
				surface.set_color(color.darkened(0.13))
				surface.add_vertex(p)
	if surface.get_vertex_array().is_empty():
		return
	surface.generate_normals()
	var node := MeshInstance3D.new()
	node.name = "OSM_Building_Footprints"
	node.mesh = surface.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.88
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = mat
	add_child(node)

func _build_lines(records: Array, color: Color, width: float, node_name: String) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for record in records:
		_add_ribbon(surface, record.get("points", []), width, 0.16)
	if surface.get_vertex_array().is_empty():
		return
	surface.generate_normals()
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = surface.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = mat
	add_child(node)
