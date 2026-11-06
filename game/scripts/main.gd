extends Node2D

const W := 960.0
const H := 540.0
const COIN_SPACING := 205.0
const FUEL_SPACING := 1320.0
const PhysicsScript = preload("res://scripts/vehicle_physics.gd")
const ProfileScript = preload("res://scripts/game_profile.gd")
const AntiCheatScript = preload("res://scripts/anti_cheat.gd")

var car
var profile
var anti_cheat
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
var run_elapsed := 0.0
var run_reward := 0
var run_gems := 0
var fair_play_valid := true
var achievement_notice := ""
var run_bonus_coins := 0
var run_airtime := 0.0
var airborne_rotation := 0.0
var airborne_duration := 0.0
var stunt_chain := 0
var stunt_chain_timer := 0.0
var stunt_count := 0
var checkpoint_count := 0
var next_checkpoint_distance := 1000.0
var progression_notice := ""
var startup_error := ""

func _ready() -> void:
	set_process(true)
	font = ThemeDB.fallback_font
	if font == null:
		startup_error = "Font service is unavailable."
		push_error("Stride startup: ThemeDB fallback font is unavailable.")
		queue_redraw()
		return
	car = PhysicsScript.new()
	profile = ProfileScript.new()
	anti_cheat = AntiCheatScript.new()
	if profile == null or anti_cheat == null or car == null:
		startup_error = "A required game component could not be initialized."
		push_error("Stride startup: a required runtime component is null.")
		queue_redraw()
		return
	profile.load_profile()
	if profile.MAPS.is_empty() or profile.VEHICLES.is_empty():
		startup_error = "Game data could not be loaded."
		push_error("Stride startup: vehicle or map data is empty.")
		queue_redraw()
		return
	if not anti_cheat.validate_profile(profile.bank, profile.gems, profile.selected_vehicle, profile.selected_map, profile.VEHICLES.size(), profile.MAPS.size()):
		profile.bank = 0
		profile.gems = 0
		profile.selected_vehicle = 0
		profile.selected_map = 0
	best_distance = profile.best_distance
	_reset_run()
	startup_error = ""
	queue_redraw()

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
		3:
			return 405.0 - sin(world_x * 0.0017) * 92.0 - sin(world_x * 0.0052) * 58.0 - pow(maxf(0.0, sin(world_x * 0.0009)), 3.0) * 66.0
		4:
			return 420.0 - sin(world_x * 0.0013) * 112.0 - sin(world_x * 0.0038 + 0.5) * 70.0
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
	run_elapsed = 0.0
	run_reward = 0
	run_gems = 0
	run_bonus_coins = 0
	run_airtime = 0.0
	airborne_rotation = 0.0
	airborne_duration = 0.0
	stunt_chain = 0
	stunt_chain_timer = 0.0
	stunt_count = 0
	checkpoint_count = 0
	next_checkpoint_distance = 1000.0
	progression_notice = ""
	fair_play_valid = true
	achievement_notice = ""
	fuel_capacity = float(profile.vehicle_spec().fuel_capacity)
	fuel = fuel_capacity
	coin_pickups.clear()
	fuel_pickups.clear()
	crash_flash = 0.0
	_clear_controls()

func _process(delta: float) -> void:
	if profile == null or car == null or not startup_error.is_empty():
		queue_redraw()
		return
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
		spec["fuel_multiplier"] = 1.12
	elif profile.selected_map == 3:
		spec["heat_multiplier"] = float(spec.heat_multiplier) * 1.65
	elif profile.selected_map == 4:
		spec["gravity_scale"] = 0.32
	var was_grounded := car.grounded
	var old_angle := car.angle
	car.step(dt, 1.0 if gas_pressed and fuel > 0.0 else 0.0, 1.0 if brake_pressed else 0.0, lean, Callable(self, "ground_height"), spec)
	_update_stunts(dt, was_grounded, old_angle)
	if gas_pressed and fuel > 0.0:
		fuel = maxf(0.0, fuel - (0.58 + float(spec.power) * 0.17 + car.engine_heat * 0.0018) * float(spec.get("fuel_multiplier", 1.0)) * dt)
	run_elapsed += dt
	run_distance = maxf(run_distance, (car.x - 180.0) / 10.0)
	while run_distance >= next_checkpoint_distance:
		checkpoint_count += 1
		run_bonus_coins += 25
		fuel = minf(fuel_capacity, fuel + fuel_capacity * 0.12)
		progression_notice = "CHECKPOINT %d  +25 COINS" % checkpoint_count
		next_checkpoint_distance += 1000.0
	stunt_chain_timer = maxf(0.0, stunt_chain_timer - dt)
	if stunt_chain_timer <= 0.0:
		stunt_chain = 0
	camera_x = maxf(0.0, car.x - 330.0)
	_collect_items()
	crash_flash = maxf(0.0, crash_flash - dt)
	var upside_down := absf(wrapf(car.angle, -PI, PI)) > 2.15 and car.grounded
	if upside_down:
		crash_flash += dt
	else:
		crash_flash = 0.0
	if crash_flash > 0.65 or car.y > H + 360.0 or fuel <= 0.0 or car.damage >= VehiclePhysics.MAX_DAMAGE:
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

func _update_stunts(dt: float, was_grounded: bool, old_angle: float) -> void:
	if not car.grounded:
		airborne_duration += dt
		run_airtime += dt
		airborne_rotation += wrapf(car.angle - old_angle, -PI, PI)
	elif not was_grounded:
		if airborne_duration >= 0.55:
			var flips := int(floor(absf(airborne_rotation) / TAU))
			stunt_chain = mini(4, stunt_chain + 1) if stunt_chain_timer > 0.0 else 1
			var bonus := (15 + flips * 35 + int(airborne_duration * 8.0)) * stunt_chain
			run_bonus_coins += bonus
			stunt_count += 1
			progression_notice = ("BACKFLIP" if airborne_rotation < 0.0 else "FRONTFLIP") if flips > 0 else "CLEAN AIR"
			progression_notice += "  x%d  +%d" % [stunt_chain, bonus]
			stunt_chain_timer = 7.0
		airborne_duration = 0.0
		airborne_rotation = 0.0

func _finish_run() -> void:
	if game_state != "playing":
		return
	game_state = "results"
	_clear_controls()
	var spec: Dictionary = profile.vehicle_spec()
	fair_play_valid = anti_cheat.validate_run(run_distance, run_coins, run_elapsed, absf(car.vx), float(spec.speed)) and anti_cheat.validate_progression(stunt_count, checkpoint_count, run_bonus_coins, run_elapsed, run_distance)
	if fair_play_valid:
		profile.add_daily_progress(run_distance, run_coins, run_airtime)
	run_reward = anti_cheat.sanitize_reward(run_coins + int(run_distance / 80.0) + run_bonus_coins, fair_play_valid)
	if fair_play_valid:
		profile.bank = clampi(profile.bank + run_reward, 0, 2000000)
		profile.stats["runs"] = int(profile.stats.runs) + 1
		profile.stats["total_distance"] = int(profile.stats.total_distance) + int(run_distance)
		profile.stats["total_coins"] = int(profile.stats.total_coins) + run_coins
		profile.condition = maxf(0.0, profile.condition - car.damage * 0.32)
		profile.best_distance = maxi(profile.best_distance, int(run_distance))
		_update_achievements()
	best_distance = profile.best_distance
	profile.save_profile()

func _update_achievements() -> void:
	for item in profile.ACHIEVEMENTS:
		var id := str(item.id)
		if profile.achievements.has(id):
			continue
		var unlocked_now := false
		match id:
			"first_run": unlocked_now = int(profile.stats.runs) >= 1
			"distance_1000": unlocked_now = int(profile.stats.total_distance) >= 1000
			"distance_5000": unlocked_now = int(profile.stats.total_distance) >= 5000
			"coin_100": unlocked_now = int(profile.stats.total_coins) >= 100
			"runs_10": unlocked_now = int(profile.stats.runs) >= 10
			"clean_run": unlocked_now = car.damage < 10.0
		if unlocked_now:
			profile.achievements.append(id)
			var reward := int(item.reward)
			profile.gems = clampi(profile.gems + reward, 0, 100000)
			run_gems += reward
			achievement_notice = str(item.name)

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
			if Rect2(320, 335, 140, 76).has_point(pos):
				_reset_run()
				game_state = "playing"
			elif Rect2(20, 335, 140, 76).has_point(pos):
				game_state = "garage"
			elif Rect2(170, 335, 140, 76).has_point(pos):
				game_state = "maps"
			elif Rect2(470, 335, 140, 76).has_point(pos):
				game_state = "upgrades"
			elif Rect2(620, 335, 140, 76).has_point(pos):
				game_state = "achievements"
			elif Rect2(770, 335, 140, 76).has_point(pos):
				game_state = "missions"
		"maps":
			if Rect2(35, 445, 170, 62).has_point(pos):
				game_state = "home"
			else:
				for i in range(profile.MAPS.size()):
					if _map_card_rect(i).has_point(pos):
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
			elif Rect2(635, 390, 190, 72).has_point(pos):
				_repair_vehicle()
		"upgrades":
			if Rect2(35, 445, 170, 62).has_point(pos):
				game_state = "home"
			else:
				var upgrade_keys := ["engine", "suspension", "tires", "fuel", "transmission", "cooling"]
				for i in range(upgrade_keys.size()):
					if Rect2(220, 174.0 + float(i) * 49.0, 520, 43).has_point(pos):
						_buy_upgrade(upgrade_keys[i])
						break
		"achievements":
			if Rect2(35, 445, 170, 62).has_point(pos):
				game_state = "home"
		"missions":
			if Rect2(35, 445, 170, 62).has_point(pos):
				game_state = "home"
			elif Rect2(350, 125, 260, 55).has_point(pos):
				if profile.claim_daily_reward():
					progression_notice = "DAILY REWARD  +40 COINS  +2 GEMS"
			else:
				for i in range(profile.DAILY_MISSIONS.size()):
					var mission: Dictionary = profile.DAILY_MISSIONS[i]
					if Rect2(210, 205.0 + float(i) * 72.0, 540, 60).has_point(pos):
						if profile.claim_mission(str(mission.id)):
							progression_notice = "MISSION CLAIMED  +%d COINS" % int(mission.coins)
						break
		"results":
			if Rect2(350, 390, 260, 62).has_point(pos):
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
	var level := int(profile.upgrades.get(key, 0))
	if level >= 5:
		return
	var cost := profile.upgrade_cost(key)
	if profile.bank >= cost:
		profile.bank -= cost
		profile.upgrades[key] = level + 1
		profile.save_profile()

func _repair_vehicle() -> void:
	var cost := profile.repair_cost()
	if cost <= 0:
		return
	if profile.bank >= cost:
		profile.bank -= cost
		profile.condition = 100.0
		profile.save_profile()

func _draw() -> void:
	if font == null:
		font = ThemeDB.fallback_font
	if profile == null or car == null or font == null or profile.MAPS.is_empty() or profile.VEHICLES.is_empty():
		draw_rect(Rect2(0, 0, W, H), Color("#182631"))
		var fallback_font: Font = ThemeDB.fallback_font
		if fallback_font != null:
			draw_string(fallback_font, Vector2(0, 245), "HILL CLIMB", HORIZONTAL_ALIGNMENT_CENTER, W, 34, Color("#f0b44b"))
			draw_string(fallback_font, Vector2(0, 282), startup_error if not startup_error.is_empty() else "INITIALIZING GAME...", HORIZONTAL_ALIGNMENT_CENTER, W, 17, Color("#d6e0df"))
		return
	if profile.selected_map < 0 or profile.selected_map >= profile.MAPS.size():
		profile.selected_map = 0
	if profile.selected_vehicle < 0 or profile.selected_vehicle >= profile.VEHICLES.size():
		profile.selected_vehicle = 0
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
		"achievements": _draw_achievements()
		"missions": _draw_missions()

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
			elif profile.selected_map == 2:
				var snow_peak := PackedVector2Array([Vector2(sx - 24, gy - 12), Vector2(sx, gy - 60), Vector2(sx + 24, gy - 12)])
				draw_colored_polygon(snow_peak, Color("#526e85"))
				draw_colored_polygon(PackedVector2Array([Vector2(sx - 10, gy - 40), Vector2(sx, gy - 60), Vector2(sx + 10, gy - 40)]), Color("#edf4f5"))
			elif profile.selected_map == 3:
				draw_circle(Vector2(sx, gy - 18), 13.0, Color("#b75d43"))
				draw_circle(Vector2(sx - 5, gy - 23), 5.0, Color("#e8a05a"))
			else:
				draw_circle(Vector2(sx, gy - 15), 16.0, Color("#88899e"))
				draw_circle(Vector2(sx + 10, gy - 28), 6.0, Color("#c8cad5"))

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
	var wheel_radius := 29.0 if profile.selected_vehicle in [3, 5, 6] else (18.0 if profile.selected_vehicle == 4 else 23.0)
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
		4:
			draw_line(Vector2(-12, -30), Vector2(15, -64), Color("#303c42"), 5.0)
			draw_line(Vector2(15, -64), Vector2(44, -26), Color("#303c42"), 5.0)
			draw_colored_polygon(PackedVector2Array([Vector2(-36, -26), Vector2(-14, -43), Vector2(22, -39), Vector2(48, -18), Vector2(-30, -12)]), body_color)
		5:
			draw_colored_polygon(PackedVector2Array([Vector2(-78, -20), Vector2(-65, -52), Vector2(45, -52), Vector2(78, -18), Vector2(78, 18), Vector2(-78, 18)]), body_color)
		6:
			draw_colored_polygon(PackedVector2Array([Vector2(-82, -22), Vector2(-62, -58), Vector2(42, -58), Vector2(78, -25), Vector2(82, 18), Vector2(-82, 18)]), body_color)
		_:
			draw_colored_polygon(PackedVector2Array([Vector2(-70, -18), Vector2(-52, -48), Vector2(25, -48), Vector2(60, -17), Vector2(70, 16), Vector2(-69, 16)]), body_color)
	var glass_y := -58.0 if profile.selected_vehicle == 3 else (-43.0 if profile.selected_vehicle in [5, 6] else (-48.0 if profile.selected_vehicle != 2 else -37.0))
	draw_colored_polygon(PackedVector2Array([Vector2(-27, glass_y + 5), Vector2(18, glass_y + 5), Vector2(42, -20), Vector2(-39, -20)]), Color("#b9dce2"))
	draw_line(Vector2(-68, 12), Vector2(67, 12), Color("#343c42"), 5.0)
	draw_rect(Rect2(-12, -14, 27, 20), Color("#28353a"))
	draw_circle(Vector2(54, -3), 6.0, Color("#fff0a5"))
	draw_set_transform(Vector2.ZERO)

func _draw_hud() -> void:
	_panel(Rect2(18, 16, 170, 78), Color("#14232d"))
	_draw_icon("distance", Vector2(42, 39), 13, Color("#f2c46a"))
	_text("DISTANCE", Vector2(62, 43), 11, Color("#a9c2c5"))
	_text("%dm" % int(run_distance), Vector2(34, 79), 26, Color.WHITE)
	_panel(Rect2(200, 16, 126, 78), Color("#14232d"))
	_draw_icon("coin", Vector2(224, 39), 12, Color("#f2c46a"))
	_text("COINS", Vector2(244, 43), 11, Color("#a9c2c5"))
	_text(str(run_coins), Vector2(218, 79), 26, Color.WHITE)
	_panel(Rect2(338, 16, 284, 78), Color("#14232d"))
	_text("CHECKPOINT  %d" % checkpoint_count, Vector2(480, 42), 12, Color("#f2c46a"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("NEXT  %dm" % int(maxf(0.0, next_checkpoint_distance - run_distance)), Vector2(480, 72), 19, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(634, 16, 308, 78), Color("#14232d"))
	_text("FUEL", Vector2(652, 40), 11, Color("#a9c2c5"))
	draw_rect(Rect2(704, 29, 216, 13), Color("#3b4b4f"))
	draw_rect(Rect2(704, 29, 216.0 * clampf(fuel / maxf(1.0, fuel_capacity), 0.0, 1.0), 13), Color("#72c779") if fuel > fuel_capacity * 0.25 else Color("#e36b4d"))
	_text("ENGINE TEMP", Vector2(652, 76), 10, Color("#a9c2c5"))
	draw_rect(Rect2(738, 65, 182, 10), Color("#3b4b4f"))
	draw_rect(Rect2(738, 65, 182.0 * clampf(car.engine_heat / 120.0, 0.0, 1.0), 10), Color("#e36b4d") if car.engine_heat > 75.0 else Color("#e7b24a"))
	_control(Rect2(20, 420, 190, 96), "BRAKE", Color("#477e9a"))
	_control(Rect2(235, 420, 190, 96), "LEAN BACK", Color("#536d7a"))
	_control(Rect2(450, 420, 190, 96), "LEAN FWD", Color("#536d7a"))
	_control(Rect2(750, 420, 190, 96), "THROTTLE", Color("#d87537"))
	_panel(Rect2(20, 112, 140, 48), Color("#14232d"))
	_text("SPEED  %d" % int(absf(car.vx) * 0.36), Vector2(90, 143), 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(800, 112, 140, 48), Color("#14232d"))
	_text("DAMAGE  %d%%" % int(clampf(car.damage, 0.0, 100.0)), Vector2(870, 143), 14, Color("#f0a18b"), HORIZONTAL_ALIGNMENT_CENTER)
	if progression_notice != "":
		_text(progression_notice, Vector2(480, 190), 18, Color("#ffe39a"), HORIZONTAL_ALIGNMENT_CENTER)
	if stunt_chain > 1 and stunt_chain_timer > 0.0:
		_text("STUNT COMBO  x%d" % stunt_chain, Vector2(480, 220), 18, Color("#83d7e0"), HORIZONTAL_ALIGNMENT_CENTER)

func _draw_home() -> void:
	_overlay()
	_panel(Rect2(24, 18, 300, 78), Color("#14232d"))
	_draw_icon("profile", Vector2(66, 57), 25, Color("#d7e7e9"))
	_text("DRIVER", Vector2(104, 45), 13, Color("#92abb3"))
	_text("RIDGELINE ROOKIE", Vector2(104, 70), 20, Color.WHITE)
	_panel(Rect2(665, 20, 128, 54), Color("#263b43"))
	_draw_icon("coin", Vector2(689, 47), 13, Color("#f3c65d"))
	_text(str(profile.bank), Vector2(711, 55), 18, Color.WHITE)
	_panel(Rect2(802, 20, 130, 54), Color("#263b43"))
	_draw_icon("gem", Vector2(825, 47), 13, Color("#77d8e7"))
	_text(str(profile.gems), Vector2(847, 55), 18, Color.WHITE)
	_panel(Rect2(40, 115, 880, 196), Color("#172a34"))
	draw_rect(Rect2(40, 115, 880, 3), Color("#e6a64d"))
	_text("STRIDE", Vector2(480, 164), 43, Color("#f2bd62"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("HILL CLIMB", Vector2(480, 202), 29, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_text("BUILD YOUR MACHINE  •  CONQUER EVERY RIDGE", Vector2(480, 230), 13, Color("#a9c2c5"), HORIZONTAL_ALIGNMENT_CENTER)
	_draw_showcase_vehicle(Vector2(480, 276), Color(str(profile.VEHICLES[profile.selected_vehicle].color)), profile.selected_vehicle)
	var buttons := [
		{"rect":Rect2(20,335,140,76),"label":"GARAGE","icon":"garage","color":"#315766"},
		{"rect":Rect2(170,335,140,76),"label":"MAPS","icon":"map","color":"#355e58"},
		{"rect":Rect2(320,335,140,76),"label":"DRIVE","icon":"play","color":"#bd7138"},
		{"rect":Rect2(470,335,140,76),"label":"UPGRADES","icon":"tools","color":"#40576a"},
		{"rect":Rect2(620,335,140,76),"label":"TROPHIES","icon":"trophy","color":"#65577c"},
		{"rect":Rect2(770,335,140,76),"label":"MISSIONS","icon":"mission","color":"#3d6c59"}
	]
	for item in buttons:
		_panel(item.rect, Color(str(item.color)))
		_draw_icon(str(item.icon), item.rect.position + Vector2(70, 25), 17, Color("#f4d89a"))
		_text(str(item.label), item.rect.position + Vector2(70, 64), 13, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(24, 433, 912, 76), Color("#14232d"))
	_text("CURRENT REGION", Vector2(46, 458), 11, Color("#91aab1"))
	_text(str(profile.MAPS[profile.selected_map].name), Vector2(46, 485), 18, Color.WHITE)
	_text("BEST  %dm" % best_distance, Vector2(475, 481), 16, Color("#f2c46a"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("RUNS  %d" % int(profile.stats.runs), Vector2(875, 481), 16, Color("#c5d6d8"), HORIZONTAL_ALIGNMENT_RIGHT)

func _map_card_rect(index: int) -> Rect2:
	return Rect2(150.0 + float(index % 3) * 220.0, 145.0 + float(index / 3) * 150.0, 200.0, 132.0)

func _draw_maps() -> void:
	_overlay()
	_panel(Rect2(105, 35, 750, 465), Color("#17262e"))
	_text("CHOOSE YOUR TERRAIN", Vector2(480, 94), 34, Color("#f0b44b"), HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(profile.MAPS.size()):
		var map_data: Dictionary = profile.MAPS[i]
		var rect := _map_card_rect(i)
		var x := rect.position.x
		var y := rect.position.y
		_panel(rect, Color("#d47a36") if profile.selected_map == i else Color("#2b414a"))
		draw_rect(Rect2(x + 9, y + 9, 182, 65), Color(str(map_data.sky)))
		var earth := Color(str(map_data.earth))
		draw_colored_polygon(PackedVector2Array([Vector2(x + 9, y + 65), Vector2(x + 48, y + 40), Vector2(x + 84, y + 58), Vector2(x + 125, y + 35), Vector2(x + 191, y + 65), Vector2(x + 191, y + 74), Vector2(x + 9, y + 74)]), earth)
		_text(str(map_data.name), Vector2(x + 100, y + 99), 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		_text("SELECTED" if profile.selected_map == i else "TAP TO SELECT", Vector2(x + 100, y + 120), 11, Color("#f1d58a"), HORIZONTAL_ALIGNMENT_CENTER)
	_text(str(profile.MAPS[profile.selected_map].subtitle), Vector2(590, 462), 13, Color("#b9d5d9"), HORIZONTAL_ALIGNMENT_CENTER)
	_back_button()

func _draw_garage() -> void:
	_overlay()
	_panel(Rect2(100, 30, 760, 470), Color("#17262e"))
	_text("VEHICLE GARAGE", Vector2(480, 78), 35, Color("#f0b44b"), HORIZONTAL_ALIGNMENT_CENTER)
	var spec: Dictionary = profile.VEHICLES[profile.selected_vehicle]
	_text("%02d / %02d" % [profile.selected_vehicle + 1, profile.VEHICLES.size()], Vector2(480, 116), 15, Color("#a9c2c5"), HORIZONTAL_ALIGNMENT_CENTER)
	_draw_showcase_vehicle(Vector2(480, 215), Color(str(spec.color)), profile.selected_vehicle)
	_text(str(spec.name), Vector2(480, 302), 27, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_text(str(spec.description), Vector2(480, 330), 15, Color("#b9d5d9"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("POWER %.1f   SUSPENSION %.1f   GRIP %.1f" % [float(spec.power), float(spec.suspension), float(spec.grip)], Vector2(480, 356), 14, Color("#e1d7b6"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("CONDITION  %d%%" % int(profile.condition), Vector2(480, 382), 14, Color("#e6a58a"), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(235, 255, 100, 70), Color("#3c6874"))
	_text("<", Vector2(285, 301), 38, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(625, 255, 100, 70), Color("#3c6874"))
	_text(">", Vector2(675, 301), 38, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	var owned := profile.unlocked.has(profile.selected_vehicle)
	_panel(Rect2(350, 390, 260, 70), Color("#d47a36") if owned else Color("#4d8b65"))
	_text("SELECT VEHICLE" if owned else "UNLOCK  %d" % int(spec.price), Vector2(480, 433), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	var repair := profile.repair_cost()
	_panel(Rect2(635, 390, 190, 70), Color("#4d8b65") if repair > 0 and profile.bank >= repair else Color("#344b50"))
	_text("REPAIR  %d" % repair if repair > 0 else "FULL HEALTH", Vector2(730, 433), 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_text("BANK %d  |  GEMS %d" % [profile.bank, profile.gems], Vector2(790, 478), 14, Color("#f1d58a"), HORIZONTAL_ALIGNMENT_CENTER)
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
	_text("WORKSHOP UPGRADES", Vector2(480, 82), 34, Color("#f0b44b"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("Six systems. Five levels each. Every upgrade changes handling.", Vector2(480, 112), 14, Color("#b9d5d9"), HORIZONTAL_ALIGNMENT_CENTER)
	var names := ["ENGINE POWER", "SUSPENSION", "TIRE GRIP", "FUEL CAPACITY", "TRANSMISSION", "ENGINE COOLING"]
	var keys := ["engine", "suspension", "tires", "fuel", "transmission", "cooling"]
	for i in range(keys.size()):
		var y := 150.0 + float(i) * 48.0
		var level := int(profile.upgrades[keys[i]])
		var cost := profile.upgrade_cost(keys[i])
		_panel(Rect2(220, y, 520, 42), Color("#29404a"))
		_text(names[i], Vector2(235, y + 27), 14, Color.WHITE)
		for k in range(5):
			draw_rect(Rect2(445 + float(k) * 24.0, y + 12, 17, 17), Color("#e7b24a") if k < level else Color("#52656a"))
		_text("MAX" if level >= 5 else "%d" % cost, Vector2(720, y + 27), 13, Color("#f0d28b"), HORIZONTAL_ALIGNMENT_RIGHT)
	_text("BANK %d  |  GEMS %d" % [profile.bank, profile.gems], Vector2(780, 470), 14, Color("#f1d58a"), HORIZONTAL_ALIGNMENT_CENTER)
	_back_button()

func _draw_achievements() -> void:
	_overlay()
	_panel(Rect2(130, 35, 700, 465), Color("#17262e"))
	_text("CAREER TROPHIES", Vector2(480, 85), 35, Color("#f0b44b"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("GEMS %d   |   DRIVES %d   |   TOTAL DISTANCE %dm" % [profile.gems, int(profile.stats.runs), int(profile.stats.total_distance)], Vector2(480, 118), 14, Color("#b9d5d9"), HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(profile.ACHIEVEMENTS.size()):
		var item: Dictionary = profile.ACHIEVEMENTS[i]
		var y := 145.0 + float(i) * 48.0
		var unlocked := profile.achievements.has(str(item.id))
		_panel(Rect2(205, y, 550, 42), Color("#355b50") if unlocked else Color("#293c46"))
		_text(str(item.name), Vector2(220, y + 18), 14, Color.WHITE)
		_text(str(item.description), Vector2(220, y + 34), 11, Color("#c0d0d0"))
		_text("CLAIMED" if unlocked else "+%d GEMS" % int(item.reward), Vector2(735, y + 26), 12, Color("#83d7e0"), HORIZONTAL_ALIGNMENT_RIGHT)
	_back_button()

func _draw_missions() -> void:
	_overlay()
	_panel(Rect2(130, 35, 700, 465), Color("#17262e"))
	_text("DAILY CHALLENGES", Vector2(480, 82), 35, Color("#f0b44b"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("Complete objectives on your drives to earn extra coins and gems", Vector2(480, 108), 13, Color("#b9d5d9"), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(350, 125, 260, 55), Color("#4d8b65") if not profile.daily_claimed else Color("#344b50"))
	_text("CLAIM DAILY  +40 COINS  +2 GEMS" if not profile.daily_claimed else "DAILY REWARD CLAIMED", Vector2(480, 159), 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(profile.DAILY_MISSIONS.size()):
		var mission: Dictionary = profile.DAILY_MISSIONS[i]
		var y := 205.0 + float(i) * 72.0
		var progress := float(profile.mission_progress.get(str(mission.id), 0.0))
		var complete := profile.mission_complete(mission)
		var claimed := profile.mission_claimed.has(str(mission.id))
		_panel(Rect2(210, y, 540, 60), Color("#3c6655") if complete else Color("#293e48"))
		_text(str(mission.name), Vector2(228, y + 22), 15, Color.WHITE)
		_text(str(mission.description), Vector2(228, y + 43), 12, Color("#c2d2d2"))
		_text("%d / %d" % [int(progress), int(mission.target)], Vector2(620, y + 24), 13, Color("#f1d58a"), HORIZONTAL_ALIGNMENT_RIGHT)
		_text("CLAIMED" if claimed else ("CLAIM" if complete else "+%d COINS / %d GEMS" % [int(mission.coins), int(mission.gems)]), Vector2(730, y + 44), 11, Color("#83d7e0"), HORIZONTAL_ALIGNMENT_RIGHT)
	_back_button()

func _draw_results() -> void:
	_overlay()
	_panel(Rect2(245, 48, 470, 445), Color("#17262e"))
	_text("RUN FINISHED", Vector2(480, 105), 36, Color("#f0b44b"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("%dm" % int(run_distance), Vector2(480, 168), 46, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_text("DISTANCE", Vector2(480, 195), 14, Color("#a9c2c5"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("Coins %d  |  Stunt & checkpoint bonus +%d" % [run_coins, run_bonus_coins], Vector2(480, 238), 15, Color("#f1d58a"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("Run reward  +%d coins" % run_reward if fair_play_valid else "REWARD HELD - RUN VALIDATION", Vector2(480, 270), 16, Color("#b9d5d9"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("Achievement gems  +%d" % run_gems, Vector2(480, 298), 15, Color("#83d7e0"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("Bank %d   Gems %d" % [profile.bank, profile.gems], Vector2(480, 326), 16, Color("#f1d58a"), HORIZONTAL_ALIGNMENT_CENTER)
	_text("Vehicle condition  %d%%" % int(profile.condition), Vector2(480, 350), 14, Color("#e6a58a"), HORIZONTAL_ALIGNMENT_CENTER)
	_text(achievement_notice, Vector2(480, 370), 12, Color("#83d7e0"), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(Rect2(350, 390, 260, 62), Color("#d47a36"))
	_text("DRIVE AGAIN", Vector2(480, 430), 21, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_back_button()

func _overlay() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.025, 0.055, 0.07, 0.55))

func _back_button() -> void:
	_panel(Rect2(35, 445, 170, 62), Color("#3c6874"))
	_text("BACK", Vector2(120, 485), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_icon(kind: String, center: Vector2, scale: float, color: Color) -> void:
	var r := scale
	match kind:
		"profile":
			draw_circle(center, r, color.darkened(0.55))
			draw_circle(center + Vector2(0, -r * 0.32), r * 0.34, color)
			draw_arc(center + Vector2(0, r * 0.55), r * 0.57, PI, TAU, 24, color, maxf(2.0, r * 0.24), true)
		"coin":
			draw_circle(center, r, color.darkened(0.35))
			draw_circle(center, r * 0.72, color)
			draw_arc(center, r * 0.48, 0, TAU, 24, Color("#8c642e"), 2.0, true)
		"gem":
			draw_colored_polygon(PackedVector2Array([center + Vector2(0,-r),center + Vector2(r*0.82,-r*0.25),center + Vector2(r*0.55,r*0.72),center + Vector2(0,r),center + Vector2(-r*0.55,r*0.72),center + Vector2(-r*0.82,-r*0.25)]),color)
		"play":
			draw_colored_polygon(PackedVector2Array([center + Vector2(-r*0.55,-r),center + Vector2(r,r*0.0),center + Vector2(-r*0.55,r)]),color)
		"garage":
			draw_line(center + Vector2(-r,-r*0.1),center + Vector2(0,-r),color,3.0,true)
			draw_line(center + Vector2(0,-r),center + Vector2(r,-r*0.1),color,3.0,true)
			draw_rect(Rect2(center + Vector2(-r*0.72,-r*0.1),Vector2(r*1.44,r*0.95)),color,false,3.0)
			draw_rect(Rect2(center + Vector2(-r*0.28,r*0.25),Vector2(r*0.56,r*0.6)),color,false,2.0)
		"map":
			draw_rect(Rect2(center + Vector2(-r,-r*0.8),Vector2(r*2,r*1.6)),color,false,2.0)
			draw_line(center + Vector2(-r*0.55,-r*0.5),center + Vector2(-r*0.15,r*0.45),color,2.0)
			draw_line(center + Vector2(-r*0.15,r*0.45),center + Vector2(r*0.45,-r*0.4),color,2.0)
			draw_circle(center + Vector2(r*0.45,-r*0.4),r*0.2,color)
		"tools":
			draw_line(center + Vector2(-r*0.75,r*0.75),center + Vector2(r*0.55,-r*0.55),color,4.0,true)
			draw_arc(center + Vector2(r*0.58,-r*0.58),r*0.42,-1.2,1.8,18,color,3.0,true)
			draw_circle(center + Vector2(-r*0.65,r*0.65),r*0.22,color)
		"trophy":
			draw_rect(Rect2(center + Vector2(-r*0.5,-r*0.7),Vector2(r,r*0.9)),color)
			draw_arc(center + Vector2(-r*0.55,-r*0.25),r*0.4,-PI/2,PI/2,16,color,3.0,true)
			draw_arc(center + Vector2(r*0.55,-r*0.25),r*0.4,PI/2,3*PI/2,16,color,3.0,true)
			draw_line(center + Vector2(0,r*0.2),center + Vector2(0,r*0.75),color,3.0)
			draw_line(center + Vector2(-r*0.55,r*0.8),center + Vector2(r*0.55,r*0.8),color,3.0)
		"mission":
			draw_rect(Rect2(center + Vector2(-r*0.65,-r*0.8),Vector2(r*1.3,r*1.6)),color,false,2.0)
			draw_line(center + Vector2(-r*0.35,-r*0.2),center + Vector2(-r*0.05,r*0.1),color,3.0)
			draw_line(center + Vector2(-r*0.05,r*0.1),center + Vector2(r*0.45,-r*0.4),color,3.0)

func _panel(rect: Rect2, color: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(0, 4), rect.size), Color(0, 0, 0, 0.28))
	draw_rect(rect, color)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2)), Color(1, 1, 1, 0.17))

func _control(rect: Rect2, label: String, color: Color) -> void:
	draw_rect(rect, Color(0.035, 0.07, 0.09, 0.68))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5)), color)
	_text(label, rect.position + Vector2(rect.size.x * 0.5, 59), 19, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)

func _text(value: String, pos: Vector2, size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(font, pos, value, align, -1, size, color)
