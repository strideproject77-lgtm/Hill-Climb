extends Node3D

const CityLayout = preload("res://scripts/sialkot_city.gd")
const PlayerScript = preload("res://scripts/player_character.gd")

var city_layout: Node3D
var vehicle: StrideVehicle
var player: IHPlayerCharacter
var follow_camera: Camera3D
var speed_label: Label
var mode_label: Label
var control_buttons: Dictionary = {}
var driving := false
var hud_root: Control
var camera_distance := 6.8
var held_controls: Dictionary = {}

func _ready() -> void:
	_setup_environment()
	city_layout = CityLayout.new()
	city_layout.name = "ClockTowerSaddarTestMap"
	add_child(city_layout)
	_spawn_vehicle()
	_spawn_player()
	_setup_camera()
	_setup_mobile_hud()
	_update_mode_ui()

func _process(delta: float) -> void:
	if driving and is_instance_valid(vehicle):
		_update_vehicle_camera(delta)
		speed_label.text = "%03d km/h" % int(vehicle.speed_kmh)
		follow_camera.fov = lerpf(66.0, 74.0, clampf(vehicle.speed_kmh / 105.0, 0.0, 1.0))
	elif is_instance_valid(player):
		_update_player_camera(delta)
		speed_label.text = "ON FOOT  •  %s" % ("RUN" if player.moving_amount > 0.1 and player.sprinting else "WALK")

func _setup_environment() -> void:
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#293c52")
	sky_mat.sky_horizon_color = Color("#d1ad83")
	sky_mat.ground_bottom_color = Color("#242b2b")
	sky_mat.ground_horizon_color = Color("#897968")
	sky_mat.use_debanding = true
	sky.sky_material = sky_mat
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.82
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.07
	environment.adjustment_saturation = 0.96
	world_env.environment = environment
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.name = "WarmLateAfternoonSun"
	sun.rotation_degrees = Vector3(-42,-32,0)
	sun.light_color = Color("#ffe0bd")
	sun.light_energy = 1.18
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 115.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)

func _spawn_vehicle() -> void:
	vehicle = StrideVehicle.new()
	vehicle.name = "ClockTowerTestSedan"
	vehicle.position = Vector3(-18.0,1.2,42.0)
	vehicle.rotation.y = PI
	add_child(vehicle)

func _spawn_player() -> void:
	player = PlayerScript.new()
	player.position = Vector3(5.0,0.15,1.5)
	add_child(player)

func _setup_camera() -> void:
	follow_camera = Camera3D.new()
	follow_camera.name = "ThirdPersonFollowCamera"
	follow_camera.fov = 66.0
	follow_camera.near = 0.08
	follow_camera.far = 650.0
	follow_camera.current = true
	add_child(follow_camera)
	_update_player_camera(1.0)

func _update_player_camera(delta: float) -> void:
	var target := player.global_position + Vector3.UP * 1.42
	var forward := -player.global_transform.basis.z
	var desired := target - forward * 6.4 + Vector3.UP * 2.65
	follow_camera.global_position = follow_camera.global_position.lerp(desired, 1.0 - exp(-delta * 6.5))
	follow_camera.look_at(target + forward * 1.8, Vector3.UP)

func _update_vehicle_camera(delta: float) -> void:
	var behind := -vehicle.global_transform.basis.z.normalized()
	var target := vehicle.global_position + behind * 8.6 + Vector3.UP * 4.0
	follow_camera.global_position = follow_camera.global_position.lerp(target, 1.0 - exp(-delta * 4.6))
	follow_camera.look_at(vehicle.global_position + Vector3.UP * 1.0 + vehicle.linear_velocity * 0.055, Vector3.UP)

func _setup_mobile_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ClockTowerTestingHUD"
	add_child(layer)
	hud_root = Control.new()
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud_root)
	var panel := PanelContainer.new()
	panel.position = Vector2(18,16)
	panel.custom_minimum_size = Vector2(290,88)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#101a20",0.78)
	style.border_color = Color("#b28b5c",0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(13)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel",style)
	hud_root.add_child(panel)
	var info := VBoxContainer.new()
	panel.add_child(info)
	var title := Label.new()
	title.text = "INFINITE HORIZONS  /  FIELD TEST"
	title.add_theme_font_size_override("font_size",12)
	title.add_theme_color_override("font_color",Color("#d9b98d"))
	info.add_child(title)
	speed_label = Label.new()
	speed_label.add_theme_font_size_override("font_size",22)
	speed_label.add_theme_color_override("font_color",Color("#f4ead7"))
	info.add_child(speed_label)
	mode_label = Label.new()
	mode_label.position = Vector2(20,112)
	mode_label.text = "CLOCK TOWER • SADDAR BAZAAR"
	mode_label.add_theme_font_size_override("font_size",12)
	mode_label.add_theme_color_override("font_color",Color("#e7d5b8"))
	hud_root.add_child(mode_label)
	_add_button("MOVE FORWARD","▲",Vector2(24,-198),Vector2(104,-130),false,"forward")
	_add_button("MOVE BACK","▼",Vector2(24,-112),Vector2(104,-44),false,"back")
	_add_button("MOVE LEFT","◀",Vector2(112,-112),Vector2(192,-44),false,"left")
	_add_button("MOVE RIGHT","▶",Vector2(112,-198),Vector2(192,-130),false,"right")
	_add_button("SPRINT","RUN",Vector2(208,-94),Vector2(292,-28),false,"sprint")
	_add_button("VEHICLE GAS","DRIVE",Vector2(-190,-142),Vector2(-104,-72),true,"throttle")
	_add_button("VEHICLE BRAKE","BRAKE",Vector2(-96,-104),Vector2(-18,-34),true,"brake")
	_add_button("VEHICLE LEFT","◀",Vector2(-190,-62),Vector2(-112,8),true,"car_left")
	_add_button("VEHICLE RIGHT","▶",Vector2(-102,-62),Vector2(-24,8),true,"car_right")
	_add_button("ENTER OR EXIT","ENTER CAR",Vector2(-170,-220),Vector2(-22,-158),true,"interact")

func _add_button(accessible_name: String, caption: String, top_left: Vector2, bottom_right: Vector2, right_side: bool, control_name: String) -> void:
	var button := Button.new()
	button.name = accessible_name.replace(" ","")
	button.text = caption
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size",14)
	button.add_theme_color_override("font_color",Color("#f5ead7"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#14212a",0.82)
	normal.border_color = Color("#b68c58",0.9)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(13)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#98683d",0.96)
	button.add_theme_stylebox_override("normal",normal)
	button.add_theme_stylebox_override("hover",normal)
	button.add_theme_stylebox_override("pressed",pressed)
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT if right_side else Control.PRESET_BOTTOM_LEFT)
	button.offset_left = top_left.x
	button.offset_top = top_left.y
	button.offset_right = bottom_right.x
	button.offset_bottom = bottom_right.y
	button.button_down.connect(_on_button_down.bind(control_name))
	button.button_up.connect(_on_button_up.bind(control_name))
	hud_root.add_child(button)
	control_buttons[control_name] = button

func _update_mode_ui() -> void:
	for key in ["forward","back","left","right","sprint"]:
		control_buttons[key].visible = not driving
	for key in ["throttle","brake","car_left","car_right"]:
		control_buttons[key].visible = driving
	control_buttons["interact"].text = "EXIT VEHICLE" if driving else "ENTER VEHICLE"
	mode_label.text = "CLOCK TOWER • " + ("DRIVING TEST" if driving else "ON-FOOT TEST")

func _on_button_down(name: String) -> void:
	held_controls[name] = true
	match name:
		"forward","back","left","right","sprint":
			_update_player_input()
		"throttle": vehicle.set_drive_controls(1.0,vehicle.brake_input,vehicle.steer_input)
		"brake": vehicle.set_drive_controls(vehicle.throttle_input,1.0,vehicle.steer_input)
		"car_left": vehicle.set_drive_controls(vehicle.throttle_input,vehicle.brake_input,-1.0)
		"car_right": vehicle.set_drive_controls(vehicle.throttle_input,vehicle.brake_input,1.0)
		"interact": _toggle_vehicle()

func _on_button_up(name: String) -> void:
	held_controls[name] = false
	match name:
		"forward","back","left","right","sprint":
			_update_player_input()
		"throttle": vehicle.set_drive_controls(0.0,vehicle.brake_input,vehicle.steer_input)
		"brake": vehicle.set_drive_controls(vehicle.throttle_input,0.0,vehicle.steer_input)
		"car_left","car_right": vehicle.set_drive_controls(vehicle.throttle_input,vehicle.brake_input,0.0)

func _update_player_input() -> void:
	var x := float(bool(held_controls.get("right",false))) - float(bool(held_controls.get("left",false)))
	var y := float(bool(held_controls.get("back",false))) - float(bool(held_controls.get("forward",false)))
	player.set_move_input(Vector2(x,y),bool(held_controls.get("sprint",false)))

func _toggle_vehicle() -> void:
	if not driving:
		if player.global_position.distance_to(vehicle.global_position) > 5.5:
			mode_label.text = "MOVE CLOSER TO THE SEDAN"
			return
		driving = true
		player.visible = false
		player.set_physics_process(false)
		vehicle.freeze = false
		vehicle.sleeping = false
	else:
		driving = false
		vehicle.set_drive_controls(0.0,1.0,0.0)
		vehicle.linear_velocity = Vector3.ZERO
		vehicle.angular_velocity = Vector3.ZERO
		player.global_position = vehicle.global_position + vehicle.global_transform.basis.x * 2.4 + Vector3.UP * 0.2
		player.velocity = Vector3.ZERO
		player.visible = true
		player.set_physics_process(true)
		vehicle.set_drive_controls(0.0,0.0,0.0)
	_update_mode_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_toggle_vehicle()
