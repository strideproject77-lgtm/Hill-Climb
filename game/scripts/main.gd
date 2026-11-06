extends Node2D

const W := 960.0
const H := 540.0
const GRAVITY := 1150.0
const MAX_SPEED := 620.0
const WHEEL_BASE := 112.0
const COIN_SPACING := 245.0

var car_x := 180.0
var car_y := 260.0
var car_vx := 0.0
var car_vy := 0.0
var car_angle := 0.0
var angular_velocity := 0.0
var camera_x := 0.0
var distance := 0.0
var coins := 0
var fuel := 100.0
var game_state := "menu"
var throttle := false
var brake := false
var rotate_left := false
var rotate_right := false
var touch_points: Dictionary = {}
var collected: Dictionary = {}
var best_distance := 0.0
var last_grounded := true
var crash_timer := 0.0

var font: Font

func _ready() -> void:
	font = ThemeDB.fallback_font
	_reset_run()
	set_process(true)

func _reset_run() -> void:
	car_x = 180.0
	car_y = ground_height(car_x) - 74.0
	car_vx = 0.0
	car_vy = 0.0
	car_angle = 0.0
	angular_velocity = 0.0
	camera_x = 0.0
	distance = 0.0
	coins = 0
	fuel = 100.0
	collected.clear()
	last_grounded = true
	crash_timer = 0.0

func _process(delta: float) -> void:
	var dt := minf(delta, 0.033)
	if game_state == "playing":
		_update_physics(dt)
	queue_redraw()

func _update_physics(dt: float) -> void:
	var grounded := _is_grounded()
	var drive := (1.0 if throttle else 0.0) - (0.72 if brake else 0.0)
	if fuel > 0.0:
		car_vx += drive * (820.0 if drive >= 0.0 else 680.0) * dt
		if throttle:
			fuel = maxf(0.0, fuel - 1.05 * dt)
	car_vx = move_toward(car_vx, 0.0, (95.0 if not throttle and not brake else 20.0) * dt)
	car_vx = clampf(car_vx, -110.0, MAX_SPEED)
	car_x += car_vx * dt
	car_vy += GRAVITY * dt
	car_y += car_vy * dt

	var left_ground := ground_height(car_x - WHEEL_BASE * 0.5)
	var right_ground := ground_height(car_x + WHEEL_BASE * 0.5)
	var target_y := minf(left_ground, right_ground) - 72.0
	var target_angle := atan2(right_ground - left_ground, WHEEL_BASE)
	if car_y >= target_y and car_vy > 0.0:
		car_y = target_y
		car_vy = 0.0
		angular_velocity = lerpf(angular_velocity, 0.0, 0.35)
		car_angle = lerp_angle(car_angle, target_angle, minf(1.0, dt * 11.0))
		grounded = true
	else:
		grounded = false
		if rotate_left:
			angular_velocity -= 2.4 * dt
		if rotate_right:
			angular_velocity += 2.4 * dt
		angular_velocity = clampf(angular_velocity, -2.8, 2.8)
		car_angle += angular_velocity * dt
		car_angle = wrapf(car_angle, -PI, PI)

	if grounded and not last_grounded and absf(car_angle) > 1.0 and car_vx > 200.0:
		crash_timer = 0.65
	last_grounded = grounded
	if crash_timer > 0.0:
		crash_timer -= dt
		if crash_timer <= 0.0:
			_end_run()
	if car_y > H + 500.0 or fuel <= 0.0:
		_end_run()

	distance = maxf(distance, (car_x - 180.0) / 10.0)
	best_distance = maxf(best_distance, distance)
	camera_x = maxf(0.0, car_x - 330.0)
	_check_pickups()

func _end_run() -> void:
	game_state = "over"
	throttle = false
	brake = false
	rotate_left = false
	rotate_right = false

func _is_grounded() -> bool:
	var g := minf(ground_height(car_x - WHEEL_BASE * 0.5), ground_height(car_x + WHEEL_BASE * 0.5))
	return car_y >= g - 73.0 and car_vy >= 0.0

func ground_height(world_x: float) -> float:
	var hills := sin(world_x * 0.0042) * 78.0 + sin(world_x * 0.0091 + 1.4) * 29.0 + sin(world_x * 0.0017) * 65.0
	var ramps := sin(world_x * 0.0011 + 0.6) * 24.0
	return 390.0 - hills - ramps

func _check_pickups() -> void:
	var index := int(floor((car_x - 160.0) / COIN_SPACING))
	for i in range(index - 1, index + 3):
		if i < 0 or collected.has(i):
			continue
		var px := 260.0 + float(i) * COIN_SPACING
		var py := ground_height(px) - 118.0
		if Vector2(car_x, car_y).distance_to(Vector2(px, py)) < 78.0:
			collected[i] = true
			coins += 1
			if coins % 6 == 0:
				fuel = minf(100.0, fuel + 14.0)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed:
			_handle_press(e.index, e.position)
		else:
			_release_touch(e.index)
	elif event is InputEventScreenDrag:
		var e := event as InputEventScreenDrag
		_update_touch(e.index, e.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_press(-1, event.position)
		else:
			_release_touch(-1)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_touch(-1, event.position)
	elif event is InputEventKey:
		_update_controls()

func _handle_press(id: int, pos: Vector2) -> void:
	if game_state != "playing":
		if Rect2(340, 330, 280, 92).has_point(pos):
			_reset_run()
			game_state = "playing"
			return
		return
	touch_points[id] = pos
	_update_controls()

func _update_touch(id: int, pos: Vector2) -> void:
	if touch_points.has(id):
		touch_points[id] = pos
		_update_controls()

func _release_touch(id: int) -> void:
	touch_points.erase(id)
	_update_controls()

func _update_controls() -> void:
	throttle = false
	brake = false
	rotate_left = false
	rotate_right = false
	for p in touch_points.values():
		if p.x > 710.0 and p.y > 360.0:
			throttle = true
		elif p.x < 250.0 and p.y > 360.0:
			brake = true
		elif p.x > 430.0 and p.x < 690.0 and p.y > 360.0:
			rotate_right = true
		elif p.x > 250.0 and p.x < 430.0 and p.y > 360.0:
			rotate_left = true
	throttle = throttle or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
	brake = brake or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
	rotate_left = rotate_left or Input.is_key_pressed(KEY_UP)
	rotate_right = rotate_right or Input.is_key_pressed(KEY_DOWN)

func _draw() -> void:
	_draw_background()
	_draw_terrain()
	_draw_pickups()
	_draw_car()
	_draw_hud()
	if game_state == "menu":
		_draw_menu()
	elif game_state == "over":
		_draw_game_over()

func _draw_background() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("#8ed6e8"))
	for i in range(5):
		var x := fposmod(float(i) * 270.0 - camera_x * 0.18, W + 260.0) - 130.0
		var y := 110.0 + float(i % 2) * 48.0
		draw_circle(Vector2(x, y), 31.0, Color(1, 1, 1, 0.72))
		draw_circle(Vector2(x + 28, y + 8), 24.0, Color(1, 1, 1, 0.72))
		draw_circle(Vector2(x - 25, y + 12), 20.0, Color(1, 1, 1, 0.72))
	for i in range(4):
		var mx := fposmod(float(i) * 360.0 - camera_x * 0.34, W + 360.0) - 180.0
		var peak := 300.0 + float(i % 2) * 40.0
		var points := PackedVector2Array([Vector2(mx - 190, H), Vector2(mx, peak), Vector2(mx + 190, H)])
		draw_colored_polygon(points, Color("#74b7a0"))

func _draw_terrain() -> void:
	var points := PackedVector2Array()
	points.append(Vector2(0, H))
	for sx in range(0, 981, 8):
		points.append(Vector2(float(sx), ground_height(camera_x + float(sx))))
	points.append(Vector2(W, H))
	draw_colored_polygon(points, Color("#79553b"))
	var ridge := PackedVector2Array()
	for sx in range(0, 981, 8):
		ridge.append(Vector2(float(sx), ground_height(camera_x + float(sx))))
	for i in range(ridge.size() - 1):
		draw_line(ridge[i], ridge[i + 1], Color("#5bb85c"), 13.0, true)
		draw_line(ridge[i] + Vector2(0, 8), ridge[i + 1] + Vector2(0, 8), Color("#a1d66c"), 3.0, true)

func _draw_pickups() -> void:
	var first := int(floor((camera_x - 260.0) / COIN_SPACING))
	for i in range(maxi(0, first), first + 7):
		if collected.has(i):
			continue
		var wx := 260.0 + float(i) * COIN_SPACING
		var sx := wx - camera_x
		if sx < -30.0 or sx > W + 30.0:
			continue
		var sy := ground_height(wx) - 118.0
		draw_circle(Vector2(sx, sy), 15.0, Color("#f6b93b"))
		draw_circle(Vector2(sx, sy), 10.0, Color("#ffe58a"))
		draw_line(Vector2(sx, sy - 6), Vector2(sx, sy + 6), Color("#c47b20"), 3.0)

func _draw_car() -> void:
	var screen_pos := Vector2(car_x - camera_x, car_y)
	draw_set_transform(screen_pos, car_angle, Vector2.ONE)
	for wx in [-WHEEL_BASE * 0.5, WHEEL_BASE * 0.5]:
		draw_line(Vector2(wx, 20), Vector2(wx, 42), Color("#3d4650"), 7.0)
		draw_circle(Vector2(wx, 45), 22.0, Color("#26313a"))
		draw_circle(Vector2(wx, 45), 11.0, Color("#c4d0d4"))
		draw_circle(Vector2(wx, 45), 4.0, Color("#687982"))
	draw_colored_polygon(PackedVector2Array([Vector2(-70, -20), Vector2(-53, -48), Vector2(24, -48), Vector2(57, -18), Vector2(69, 14), Vector2(-70, 14)]), Color("#ef7d35"))
	draw_colored_polygon(PackedVector2Array([Vector2(-28, -43), Vector2(18, -43), Vector2(43, -20), Vector2(-38, -20)]), Color("#bfe8f2"))
	draw_line(Vector2(-68, 14), Vector2(68, 14), Color("#9b4829"), 5.0)
	draw_circle(Vector2(52, -4), 6.0, Color("#fff1a8"))
	draw_set_transform(Vector2.ZERO)

func _draw_hud() -> void:
	_draw_panel(Rect2(22, 18, 230, 82), Color(0.08, 0.15, 0.19, 0.82))
	_draw_text("DISTANCE", Vector2(42, 46), 15, Color("#b7dce1"))
	_draw_text("%dm" % int(distance), Vector2(42, 82), 29, Color.WHITE)
	_draw_panel(Rect2(270, 18, 160, 82), Color(0.08, 0.15, 0.19, 0.82))
	_draw_text("COINS", Vector2(290, 46), 15, Color("#f8d56b"))
	_draw_text(str(coins), Vector2(290, 82), 29, Color.WHITE)
	_draw_panel(Rect2(740, 24, 194, 54), Color(0.08, 0.15, 0.19, 0.82))
	_draw_text("FUEL", Vector2(756, 46), 13, Color.WHITE)
	draw_rect(Rect2(810, 37, 108, 17), Color("#35434a"))
	draw_rect(Rect2(810, 37, 108.0 * fuel / 100.0, 17), Color("#72d36c") if fuel > 25 else Color("#ed754c"))
	if game_state == "playing":
		_draw_control(Rect2(24, 420, 190, 92), "BRAKE", Color("#477f9c"))
		_draw_control(Rect2(250, 420, 180, 92), "LEAN", Color("#687e91"))
		_draw_control(Rect2(455, 420, 180, 92), "LEAN", Color("#687e91"))
		_draw_control(Rect2(746, 420, 190, 92), "GAS", Color("#d76d38"))

func _draw_menu() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.025, 0.07, 0.09, 0.58))
	_draw_panel(Rect2(235, 76, 490, 380), Color("#172a32"))
	_draw_text("HILL CLIMB", Vector2(480, 157), 48, Color("#f5b84b"), HORIZONTAL_ALIGNMENT_CENTER)
	_draw_text("ADVENTURE", Vector2(480, 207), 29, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_draw_text("Drive • Climb • Collect", Vector2(480, 255), 20, Color("#b9d5d9"), HORIZONTAL_ALIGNMENT_CENTER)
	_draw_panel(Rect2(340, 330, 280, 92), Color("#df813d"))
	_draw_text("TAP TO START", Vector2(480, 387), 27, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_draw_text("A tiny off-road journey", Vector2(480, 445), 15, Color("#b9d5d9"), HORIZONTAL_ALIGNMENT_CENTER)

func _draw_game_over() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.025, 0.07, 0.09, 0.62))
	_draw_panel(Rect2(285, 95, 390, 350), Color("#172a32"))
	_draw_text("RUN COMPLETE", Vector2(480, 165), 34, Color("#f5b84b"), HORIZONTAL_ALIGNMENT_CENTER)
	_draw_text("Distance   %dm" % int(distance), Vector2(480, 230), 23, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_draw_text("Coins   %d" % coins, Vector2(480, 270), 21, Color("#f8d56b"), HORIZONTAL_ALIGNMENT_CENTER)
	_draw_text("Best   %dm" % int(best_distance), Vector2(480, 307), 17, Color("#b9d5d9"), HORIZONTAL_ALIGNMENT_CENTER)
	_draw_panel(Rect2(340, 345, 280, 72), Color("#df813d"))
	_draw_text("TAP TO RETRY", Vector2(480, 390), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_panel(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4)), Color(1, 1, 1, 0.16))

func _draw_control(rect: Rect2, label: String, color: Color) -> void:
	draw_rect(rect, Color(0.04, 0.08, 0.11, 0.58))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5)), color)
	_draw_text(label, rect.position + Vector2(rect.size.x * 0.5, 56), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_text(value: String, pos: Vector2, size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(font, pos, value, align, -1, size, color)
