extends Node2D

const W := 960.0
const H := 540.0
const COIN_SPACING := 205.0
const FUEL_SPACING := 1320.0
const PhysicsScript = preload("res://scripts/vehicle_physics.gd")
const ProfileScript = preload("res://scripts/game_profile.gd")

var car
var profile
var font: Font
var game_state := "home"
var camera_x := 0.0
var run_distance := 0.0
var run_coins := 0
var fuel := 100.0
var fuel_capacity := 100.0
var fuel_pickups: Dictionary = {}
var coin_pickups: Dictionary = {}
var touch_points: Dictionary = {}
var gas_pressed := false
var brake_pressed := false
var lean_left := false
var lean_right := false
var crash_flash := 0.0
var last_crash_speed := 0.0
var best_distance := 0

func _ready() -> void:
	font = ThemeDB.fallback_font
	car = PhysicsScript.new()
	profile = ProfileScript.new()
	profile.load_profile()
	best_distance = profile.best_distance
	_reset_run()
	set_process(true)

func ground_height(world_x: float) -> float:
	match profile.selected_map:
		1:
			var dune_a := sin(world_x * 0.00155 + 0.4) * 78.0
			var dune_b := sin(world_x * 0.0032 + 1.1) * 31.0
			var dune_ripple := sin(world_x * 0.009) * 5.0
			return 410.0 - dune_a - dune_b - dune_ripple
		2:
			var ice_hill := sin(world_x * 0.0018) * 83.0
			var ice_roll := sin(world_x * 0.0048 + 1.5) * 54.0
			var ice_cliff := pow(maxf(0.0, sin(world_x * 0.0008 + 0.8)), 4.0) * 52.0
			return 402.0 - ice_hill - ice_roll - ice_cliff
		_:
			var long_hill := sin(world_x * 0.0019 + 0.5) * 66.0
			var rolling := sin(world_x * 0.0041) * 58.0
			var sharp := sin(world_x * 0.0105 + 1.3) * 19.0
			var ridge := pow(maxf(0.0, sin(world_x * 0.00072 + 0.4)), 3.0) * 48.0
			return 405.0 - long_hill - rolling - sharp - ridge

func _reset_run() -> void:
	car.reset(180.0, Callable(self, "ground_height"))
	camera_x = 0.0
	run_distance = 0.0
	run_coins = 0
	fuel_capacity = float(profile.vehicle_spec().fuel_capacity)
	fuel = fuel_capacity
	coin_pickups.clear()
	fuel_pickups.clear()
	crash_flash = 0.0
	_clear_controls()

func _process(delta: float) -> void:
	var dt := minf(delta, 0.033)
	if game_state == "playing":
		_update_run(dt)
	queue_redraw()

func _update_run(dt: float) -> void:
	var lean := (1.0 if lean_right else 0.0) - (1.0 if lean_left else 0.0)
	var spec: Dictionary = profile.vehicle_spec()
	if profile.selected_map == 2:
		spec["grip"] = float(spec.grip) * 0.68
	elif profile.selected_map == 1:
		spec["grip"] = float(spec.grip) * 0.92
	car.step(dt, 1.0 if gas_pressed and fuel > 0.0 else 0.0, 1.0 if brake_pressed else 0.0, lean, Callable(self, "ground_height"), spec)
	if gas_pressed and fuel > 0.0:
		fuel = maxf(0.0, fuel - (0.72 + float(spec.power) * 0.22) * dt)
	run_distance = maxf(run_distance, (car.x - 180.0) / 10.0)
	camera_x = maxf(0.0, car.x - 330.0)
	_collect_items()
	crash_flash = maxf(0.0, crash_flash - dt)
	var upside_down := absf(wrapf(car.angle, -PI, PI)) > 2.15 and car.grounded
	if upside_down:
		crash_flash += dt
	else:
		crash_flash = 0.0
	if crash_flash > 0.65 or car.y > H + 360.0 or fuel <= 0.0:
		_finish_run()

func _collect_items() -> void:
	var coin_index := int(floor(car.x / COIN_SPACING))
	for i in range(maxi(0, coin_index - 2), coin_index + 4):
		if coin_pickups.has(i):
			continue
		var px := 300.0 + float(i) * COIN_SPACING
		var py := ground_height(px) - 112.0 - sin(float(i) * 1.7) * 18.0
		if Vector2(car.x, car.y).distance_to(Vector2(px, py)) < 67.0:
			coin_pickups[i] = true
			run_coins += 1
	var fuel_index := int(floor(car.x / FUEL_SPACING))
	for j in range(maxi(0, fuel_index - 1), fuel_index + 2):
		if fuel_pickups.has(j):
			continue
		var fx := 760.0 + float(j) * FUEL_SPACING
		var fy := ground_height(fx) - 82.0
		if Vector2(car.x, car.y).distance_to(Vector2(fx, fy)) < 75.0:
			fuel_pickups[j] = true
			fuel = minf(fuel_capacity, fuel + fuel_capacity * 0.34)

func _finish_run() -> void:
	game_state = "results"
	_clear_controls()
	var reward := run_coins + int(run_distance / 80.0)
	profile.bank += reward
	profile.best_distance = maxi(profile.best_distance, int(run_distance))
	best_distance = profile.best_distance
	profile.save_profile()

func _clear_controls() -> void:
	touch_points.clear()
	gas_pressed = false
	brake_pressed = false
	lean_left = false
	lean_right = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_press(touch.index, touch.position)
		else:
			_release(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if touch_points.has(drag.index):
			touch_points[drag.index] = drag.position
			_update_controls()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(-1, event.position)
		else:
			_release(-1)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if touch_points.has(-1):
			touch_points[-1] = event.position
			_update_controls()
	elif event is InputEventKey:
		_update_controls()

func _press(id: int, pos: Vector2) -> void:
	if game_state != "playing":
		_handle_menu_press(pos)
		return
	touch_points[id] = pos
	_update_controls()

func _release(id: int) -> void:
	touch_points.erase(id)
	_update_controls()

func _update_controls() -> void:
	gas_pressed = Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
	brake_pressed = Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
	lean_left = Input.is_key_pressed(KEY_UP)
	lean_right = Input.is_key_pressed(KEY_DOWN)
	for point in touch_points.values():
		if point.y >= 365.0:
			if point.x < 235.0:
				brake_pressed = true
			elif point.x < 465.0:
				lean_left = true
			elif point.x < 700.0:
				lean_right = true
			else:
				gas_pressed = true

func _handle_menu_press(pos: Vector2) -> void:
	match game_state:
		"home":
			if Rect2(445, 340, 230, 78).has_point(pos):
				_reset_run()
				game_state = "playing"
			elif Rect2(45, 340, 180, 78).has_point(pos):
				game_state = "garage"
			elif Rect2(245, 340, 180, 78).has_point(pos):
				game_state = "maps"
			elif Rect2(695, 340, 220, 78).has_point(pos):
				game_state = "upgrades"
		"maps":
			if Rect2(35, 445, 170, 62).has_point(pos):
				game_state = "home"
			else:
				for i in range(profile.MAPS.size()):
					if Rect2(170.0 + float(i) * 215.0, 215, 190, 190).has_point(pos):
						profile.selected_map = i
						profile.save_profile()
						break
		"garage":
			if Rect2(35, 445, 170, 62).has_point(pos):
				game_state = "home"
			elif Rect2(235, 280, 100, 80).has_point(pos):
				profile.selected_vehicle = posmod(profile.selected_vehicle - 1, profile.VEHICLES.size())
				profile.save_profile()
			elif Rect2(625, 280, 100, 80).has_point(pos):
				profile.selected_vehicle = posmod(profile.selected_vehicle + 1, profile.VEHICLES.size())
				profile.save_profile()
			elif Rect2(350, 390, 260, 72).has_point(pos):
				_select_or_buy_vehicle()
		"upgrades":
			if Rect2(35, 445, 170, 62).has_point(pos):
				game_state = "home"
			else:
				for i in range(4):
					if Rect2(250, 205.0 + float(i) * 58.0, 470, 48).has_point(pos):
						_buy_upgrade(["engine", "suspension", "tires", "fuel"][i])
						break
		"results":
			if Rect2(350, 370, 260, 72).has_point(pos):
				_reset_run()
				game_state = "playing"
			elif Rect2(35, 445, 170, 62).has_point(pos):
				game_state = "home"

func _select_or_buy_vehicle() -> void:
	var vehicle: Dictionary = profile.VEHICLES[profile.selected_vehicle]
	if profile.unlocked.has(profile.selected_vehicle):
		_reset_run()
		game_state = "playing"
	elif profile.bank >= int(vehicle.price):
		profile.bank -= int(vehicle.price)
		profile.unlocked.append(profile.selected_vehicle)
		profile.save_profile()

func _buy_upgrade(key: String) -> void:
	var level := int(profile.upgrades[key])
	if level >= 5:
		return
	var cost := 120 + level * 145
	if profile.bank >= cost:
		profile.bank -= cost
		profile.upgrades[key] = level + 1
		profile.save_profile()

func _draw() -> void:
	_draw_backdrop()
	_draw_landscape()
	if game_state == "playing" or game_state == "results":
		_draw_collectibles()
		_draw_vehicle()
		_draw_hud()
	match game_state:
		"home": _draw_home()
		"garage": _draw_garage()
		"maps": _draw_maps()
		"upgrades": _draw_upgrades()
		"results": _draw_results()

func _draw_backdrop() -> void:
	var palette: Dictionary = profile.MAPS[profile.selected_map]
	draw_rect(Rect2(0, 0, W, H), Color(str(palette.sky)))
	for i in range(7):
		var sx := fposmod(float(i) * 205.0 - camera_x * 0.12, W + 220.0) - 100.0
		draw_circle(Vector2(sx, 92.0 + float(i % 3) * 25.0), 28.0, Color(1, 1, 1, 0.45))
		draw_circle(Vector2(sx + 24.0, 99.0 + float(i % 3) * 25.0), 21.0, Color(1, 1, 1, 0.45))
	for i in range(5):
		var mx := fposmod(float(i) * 330.0 - camera_x * 0.23, W + 350.0) - 170.0
		var peak := 285.0 + float(i % 2) * 40.0
		var mountain_color := Color("#719a91") if profile.selected_map == 0 else (Color("#b9875c") if profile.selected_map == 1 else Color("#718ba8"))
		draw_colored_polygon(PackedVector2Array([Vector2(mx - 190, H), Vector2(mx, peak), Vector2(mx + 190, H)]), mountain_color)
		draw_colored_polygon(PackedVector2Array([Vector2(mx - 75, peak + 82), Vector2(mx, peak), Vector2(mx + 75, peak + 82)]), Color("#e4eceb", 0.65) if profile.selected_map == 2 else Color("#c6d7c7", 0.7))

func _draw_landscape() -> void:
	var terrain := PackedVector2Array([Vector2(0, H)])
	for sx in range(0, 981, 6):
		terrain.append(Vector2(float(sx), ground_height(camera_x + float(sx))))
	terrain.append(Vector2(W, H))
	var palette: Dictionary = profile.MAPS[profile.selected_map]
	draw_colored_polygon(terrain, Color(str(palette.earth)))
	for sx in range(0, 981, 6):
		var x1 := float(sx)
		var x2 := x1 + 6.0
		var y1 := ground_height(camera_x + x1)
		var y2 := ground_height(camera_x + x2)
		var surface := Color(str(palette.surface))
		draw_line(Vector2(x1, y1), Vector2(x2, y2), surface, 12.0, true)
		draw_line(Vector2(x1, y1 + 7), Vector2(x2, y2 + 7), surface.lightened(0.28), 2.0, true)
	for i in range(14):
		var wx := float(i) * 390.0 + 180.0
		var sx := wx - camera_x
		if sx > -40.0 and sx < W + 40.0:
			var gy := ground_height(wx)
			if profile.selected_map == 0:
				draw_line(Vector2(sx, gy - 4), Vector2(sx - 4, gy - 38), Color("#554b35"), 5.0)
				draw_circle(Vector2(sx - 4, gy - 45), 18.0, Color("#497e55"))
			elif profile.selected_map == 1:
				draw_line(Vector2(sx, gy - 3), Vector2(sx, gy - 28), Color("#55734c"), 5.0)
				draw_line(Vector2(sx, gy - 18), Vector2(sx - 13, gy - 24), Color("#55734c"), 4.0)
				draw_line(Vector2(sx, gy - 18), Vector2(sx + 13, gy - 24), Color("#55734c"), 4.0)
			else:
				var snow_peak := PackedVector2Array([Vector2(sx - 24, gy - 12), Vector2(sx, gy - 60), Vector2(sx + 24, gy - 12)])
				draw_colored_polygon(snow_peak, Color("#526e85"))
				draw_colored_polygon(PackedVector2Array([Vector2(sx - 10, gy - 40), Vector2(sx, gy - 60), Vector2(sx + 10, gy - 40)]), Color("#edf4f5"))

func _draw_collectibles() -> void:
	var start := int(floor(camera_x / COIN_SPACING)) - 1
	for i in range(maxi(0, start), start + 8):
		if coin_pickups.has(i):
			continue
		var wx := 300.0 + float(i) * COIN_SPACING
		var sx := wx - camera_x
		if sx < -30.0 or sx > W + 30.0:
			continue
		var sy := ground_height(wx) - 112.0 - sin(float(i) * 1.7) * 18.0
		draw_circle(Vector2(sx, sy), 15.0, Color("#f4b83f"))
		draw_circle(Vector2(sx, sy), 9.0, Color("#ffe99a"))
	var fuel_start := int(floor(camera_x / FUEL_SPACING)) - 1
	for j in range(maxi(0, fuel_start), fuel_start + 4):
		if fuel_pickups.has(j):
			continue
		var fx := 760.0 + float(j) * FUEL_SPACING
		var sx2 := fx - camera_x
		if sx2 > -35.0 and sx2 < W + 35.0:
			var fy := ground_height(fx) - 82.0
			draw_rect(Rect2(sx2 - 12, fy - 16, 24, 32), Color("#e5e9e4"))
			draw_rect(Rect2(sx2 - 7, fy - 10, 14, 18), Color("#dc5147"))
			draw_rect(Rect2(sx2 - 5, fy - 22, 10, 6), Color("#4a5555"))

func _draw_vehicle() -> void:
	var spec: Dictionary = profile.vehicle_spec()
	var pos := Vector2(car.x - camera_x, car.y)
	draw_set_transform(pos, car.angle, Vector2.ONE)
	var wheelbase := 57.0
	var wheel_radius := 29.0 if profile.selected_vehicle == 3 else 23.0
	for side in [-1.0, 1.0]:
		var wx := side * wheelbase
		var compression := car.front_compression if side > 0.0 else car.rear_compression
		var wy := 45.0 + compression * 8.0
		draw_line(Vector2(wx, 24), Vector2(wx, wy - wheel_radius + 3.0), Color("#333b42"), 7.0)
		draw_circle(Vector2(wx, wy), wheel_radius, Color("#202a30"))
		draw_circle(Vector2(wx, wy), wheel_radius * 0.55, Color("#aab8ba"))
		draw_circle(Vector2(wx, wy), 5.0, Color("#4e5b60"))
		for spoke in range(6):
			var a := float(spoke) * PI / 3.0
			draw_line(Vector2(wx, wy), Vector2(wx + cos(a) * wheel_radius * 0.46, wy + sin(a) * wheel_radius * 0.46), Color("#526168"), 2.0)
	var body_color := Color(str(spec.color))
	match profile.selected_vehicle:
		1:
			draw_colored_polygon(PackedVector2Array([Vector2(-75, -17), Vector2(-62, -55), Vector2(35, -55), Vector2(68, -24), Vector2(76, 18), Vector2(-75, 18)]), body_color)
		2:
			draw_colored_polygon(PackedVector2Array([Vector2(-76, -12), Vector2(-50, -37), Vector2(34, -37), Vector2(69, -12), Vector2(76, 12), Vector2(-76, 12)]), body_color)
			draw_line(Vector2(-38, -35), Vector2(-15, -65), Color("#303c42"), 5.0)
			draw_line(Vector2(-15, -65), Vector2(34, -35), Color("#303c42"), 5.0)
		3:
			draw_colored_polygon(PackedVector2Array([Vector2(-72, -25), Vector2(-57, -65), Vector2(35, -65), Vector2(68, -28), Vector2(75, 18), Vector2(-75, 18)]), body_color)
		_:
			draw_colored_polygon(PackedVector2Array([Vector2(-70, -18), Vector2(-52, -48), Vector2(25, -48), Vector2(60, -17), Vector2(70, 16), Vector2(-69, 16)]), body_color)
	var glass_y := -58.0 if profile.selected_vehicle == 3 else (-48.0 if profile.selected_vehicle != 2 else -37.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-27, glass_y + 5), Vector2(18, glass_y + 5), Vector2(42, -20), Vector2(-39, -20)]), Color("#b9dce2"))
	draw_line(Vector2(-68, 12), Vector2(67, 12), Color("#343c42"), 5.0)
	draw_rect(Rect2(-12, -14, 27, 20), Color("#28353a"))
	draw_circle(Vector2(54, -3), 6.0, Color("#fff0a5"))
	draw_set_transform(Vector2.ZERO)

func _draw_hud() -> void:
	_panel(Rect2(20, 18, 205, 78), Color("#172b32"))
	_text("DISTANCE", Vector2(38, 45), 13, Color("#b9d5d9"))
	_text("%dm" % int(run_distance), Vector2(38, 81), 29, Color.WHITE)
	_panel(Rect2(240, 18, 140, 78), Color("#172b32"))
	_text("COINS", Vector2(258, 45), 13, Color("#f3ca66"))
	_text(str(run_coins), Vector2(258, 81), 29, Color.WHITE)
	_panel(Rect2(705, 18, 235, 78), Color("#172b32"))
	_text("FUEL", Vector2(723, 44), 13, Color.WHITE)
	draw_rect(Rect2(723, 56, 195, 17), Color("#3b4b4f"))
	draw_rect(Rect2(723, 56, 195.0 * fuel / fuel_capacity, 17), Color("#77cb68") if fuel > fuel_capacity * 0.25 else Color("#e36b4d"))
	_control(Rect2(20, 420, 190, 96), "BRAKE", Color("#477e9a"))
	_control(Rect2(235, 420, 190, 96), "LEAN BACK", Color("#536d7a"))
	_control(Rect2(450, 420, 190, 96), "LEAN FWD", Color("#536d7a"))
	_control(Rect2(750, 420, 190, 96), "THROTTLE", Color("#d87537"))

func _draw_home() -> void:
	_overlay()
	_panel(Rect2(40, 42, 880, 440), Color("#17262e"))
	_text("RIDGELINE", Vector2(480, 128), 56, Color("#f0b44b"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("OFFROAD CHAMPIONSHIP", Vector2(480, 169), 20, Color("#d8e3df"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("A new climb begins here", Vector2(480, 213), 18, Color("#a9c2c5"), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(45, 340, 180, 78), Color("#386d79"))
	_text("GARAGE", Vector2(135, 387), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(245, 340, 180, 78), Color("#4d7e77"))
	_text("MAPS", Vector2(335, 387), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(445, 340, 230, 78), Color("#d47a36"))
	_text("START DRIVE", Vector2(560, 387), 23, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(695, 340, 220, 78), Color("#536a7b"))
	_text("UPGRADES", Vector2(805, 387), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_text("%s     BANK %d     BEST %dm" % [profile.MAPS[profile.selected_map].name, profile.bank, best_distance], Vector2(480, 455), 16, Color("#f1d58a"), HORIZONTAL_ALIGNMENT_CENTER)

func _draw_maps() -> void:
	_overlay()
	_panel(Rect2(105, 35, 750, 465), Color("#17262e"))
	_text("CHOOSE YOUR TERRAIN", Vector2(480, 100), 38, Color("#f0b44b"), HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(profile.MAPS.size()):
		var map_data: Dictionary = profile.MAPS[i]
		var x := 170.0 + float(i) * 215.0
		var sky := Color(str(map_data.sky))
		_panel(Rect2(x, 215, 190, 190), Color("#2b414a"))
		draw_rect(Rect2(x + 12, 227, 166, 86), sky)
		var earth := Color(str(map_data.earth))
		draw_colored_polygon(PackedVector2Array([Vector2(x + 12, 300), Vector2(x + 48, 270), Vector2(x + 84, 291), Vector2(x + 125, 260), Vector2(x + 178, 295), Vector2(x + 178, 313), Vector2(x + 12, 313)]), earth)
		_text(str(map_data.name), Vector2(x + 95, 345), 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		_text("SELECTED" if profile.selected_map == i else "TAP TO SELECT", Vector2(x + 95, 380), 13, Color("#f1d58a"), HORIZONTAL_ALIGNMENT_CENTER)
	_text(str(map_data.subtitle), Vector2(480, 435), 16, Color("#b9d5d9"), HORIZONTAL_ALIGNMENT_CENTER)
	_back_button()

func _draw_garage() -> void:
	_overlay()
	_panel(Rect2(100, 30, 760, 470), Color("#17262e"))
	_text("VEHICLE GARAGE", Vector2(480, 90), 37, Color("#f0b44b"), HORIZONTAL_ALIGNMENT_CENTER)
	var spec: Dictionary = profile.VEHICLES[profile.selected_vehicle]
	_text("%02d / %02d" % [profile.selected_vehicle + 1, profile.VEHICLES.size()], Vector2(480, 132), 16, Color("#a9c2c5"), HORIZONTAL_ALIGNMENT_CENTER)
	_draw_showcase_vehicle(Vector2(480, 235), Color(str(spec.color)), profile.selected_vehicle)
	_text(str(spec.name), Vector2(480, 320), 29, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_text(str(spec.description), Vector2(480, 350), 16, Color("#b9d5d9"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("POWER %.1f     SUSPENSION %.1f     GRIP %.1f" % [float(spec.power), float(spec.suspension), float(spec.grip)], Vector2(480, 382), 15, Color("#e1d7b6"), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(235, 280, 100, 70), Color("#3c6874"))
	_text("<", Vector2(285, 326), 38, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(625, 280, 100, 70), Color("#3c6874"))
	_text(">", Vector2(675, 326), 38, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	var owned := profile.unlocked.has(profile.selected_vehicle)
	_panel(Rect2(350, 390, 260, 70), Color("#d47a36") if owned else Color("#4d8b65"))
	_text("SELECT VEHICLE" if owned else "UNLOCK  %d" % int(spec.price), Vector2(480, 433), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_text("BANK  %d" % profile.bank, Vector2(790, 465), 17, Color("#f1d58a"), HORIZONTAL_ALIGNMENT_CENTER)
	_back_button()

func _draw_showcase_vehicle(center: Vector2, color: Color, index: int) -> void:
	draw_set_transform(center, 0.0, Vector2(1.55, 1.55))
	var wheel_y := 20.0
	for wx in [-55.0, 55.0]:
		draw_circle(Vector2(wx, wheel_y), 22.0 if index == 3 else 17.0, Color("#202a30"))
		draw_circle(Vector2(wx, wheel_y), 9.0, Color("#aab8ba"))
	draw_colored_polygon(PackedVector2Array([Vector2(-78, -12), Vector2(-54, -45), Vector2(28, -45), Vector2(70, -10), Vector2(76, 14), Vector2(-78, 14)]), color)
	draw_colored_polygon(PackedVector2Array([Vector2(-30, -40), Vector2(20, -40), Vector2(44, -15), Vector2(-43, -15)]), Color("#b9dce2"))
	draw_set_transform(Vector2.ZERO)

func _draw_upgrades() -> void:
	_overlay()
	_panel(Rect2(125, 35, 710, 465), Color("#17262e"))
	_text("WORKSHOP UPGRADES", Vector2(480, 92), 37, Color("#f0b44b"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("Improve your machine. Each level changes real handling.", Vector2(480, 128), 16, Color("#b9d5d9"), HORIZONTAL_ALIGNMENT_CENTER)
	var names := ["ENGINE", "SUSPENSION", "TIRES & GRIP", "FUEL TANK"]
	var keys := ["engine", "suspension", "tires", "fuel"]
	for i in range(4):
		var y := 205.0 + float(i) * 58.0
		var level := int(profile.upgrades[keys[i]])
		var cost := 120 + level * 145
		_panel(Rect2(250, y, 470, 48), Color("#29404a"))
		_text(names[i], Vector2(270, y + 30), 17, Color.WHITE)
		for k in range(5):
			draw_rect(Rect2(430 + float(k) * 27.0, y + 15, 19, 18), Color("#e7b24a") if k < level else Color("#52656a"))
		_text("MAX" if level >= 5 else "%d" % cost, Vector2(690, y + 30), 15, Color("#f0d28b"), HORIZONTAL_ALIGNMENT_RIGHT)
	_text("BANK  %d" % profile.bank, Vector2(790, 465), 17, Color("#f1d58a"), HORIZONTAL_ALIGNMENT_CENTER)
	_back_button()

func _draw_results() -> void:
	_overlay()
	_panel(Rect2(260, 60, 440, 420), Color("#17262e"))
	_text("RUN FINISHED", Vector2(480, 130), 38, Color("#f0b44b"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("%dm" % int(run_distance), Vector2(480, 205), 48, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_text("DISTANCE", Vector2(480, 235), 15, Color("#a9c2c5"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("Coins collected  %d" % run_coins, Vector2(480, 285), 20, Color("#f1d58a"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("Career bank  %d" % profile.bank, Vector2(480, 320), 18, Color("#b9d5d9"), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(350, 370, 260, 72), Color("#d47a36"))
	_text("DRIVE AGAIN", Vector2(480, 415), 23, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_back_button()

func _overlay() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.025, 0.055, 0.07, 0.55))

func _back_button() -> void:
	_panel(Rect2(35, 445, 170, 62), Color("#3c6874"))
	_text("BACK", Vector2(120, 485), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)

func _panel(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4)), Color(1, 1, 1, 0.13))

func _control(rect: Rect2, label: String, color: Color) -> void:
	draw_rect(rect, Color(0.035, 0.07, 0.09, 0.68))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5)), color)
	_text(label, rect.position + Vector2(rect.size.x * 0.5, 59), 19, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)

func _text(value: String, pos: Vector2, size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(font, pos, value, align, -1, size, color)
