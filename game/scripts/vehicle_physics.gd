extends RefCounted
class_name VehiclePhysics
const GRAVITY := 1450.0
const HALF_WHEELBASE := 57.0
const WHEEL_OFFSET_Y := 25.0
const WHEEL_RADIUS := 21.0
const MAX_DAMAGE := 100.0
var x := 180.0
var y := 250.0
var vx := 0.0
var vy := 0.0
var angle := 0.0
var angular_velocity := 0.0
var grounded := false
var front_compression := 0.0
var rear_compression := 0.0
var impact := 0.0
var damage := 0.0
var engine_heat := 0.0
var tire_wear := 0.0
var wheel_rotation := 0.0
var airborne_time := 0.0
var engine_rpm := 900.0
var landing_g := 0.0
func reset(start_x: float, ground: Callable) -> void:
	x = start_x
	y = float(ground.call(start_x)) - 72.0
	vx = 0.0
	vy = 0.0
	angle = 0.0
	angular_velocity = 0.0
	grounded = true
	front_compression = 0.0
	rear_compression = 0.0
	impact = 0.0
	damage = 0.0
	engine_heat = 0.0
	tire_wear = 0.0
	wheel_rotation = 0.0
	airborne_time = 0.0
	engine_rpm = 900.0
	landing_g = 0.0
func step(dt: float, gas: float, brake: float, lean: float, ground: Callable, spec: Dictionary) -> void:
	var mass: float = maxf(0.55, float(spec.get("mass", 1.0)))
	var gravity_scale: float = float(spec.get("gravity_scale", 1.0))
	var heat_multiplier: float = float(spec.get("heat_multiplier", 1.0))
	var power: float = float(spec.get("power", 1.0))
	var suspension: float = float(spec.get("suspension", 1.0))
	var grip: float = float(spec.get("grip", 1.0)) * (1.0 - tire_wear * 0.42)
	var max_speed: float = 760.0 * float(spec.get("speed", 1.0))
	var inertia: float = mass * float(spec.get("inertia", 1.0))
	var old_vy := vy
	var was_grounded := grounded
	impact = 0.0
	landing_g = 0.0
	var spring_force := 0.0
	var angular_force := 0.0
	var contacts := 0
	var compression_front := 0.0
	var compression_rear := 0.0
	var contact_slope := 0.0
	for side in [-1.0, 1.0]:
		var offset := Vector2(side * HALF_WHEELBASE, WHEEL_OFFSET_Y).rotated(angle)
		var wheel_x := x + offset.x
		var penetration := y + offset.y + WHEEL_RADIUS - float(ground.call(wheel_x))
		if penetration > 0.0:
			contacts += 1
			var point_velocity := vy + angular_velocity * offset.x
			var spring := clampf(penetration * 118.0 * suspension - point_velocity * 15.5, 0.0, 30000.0)
			spring_force += spring
			angular_force += offset.x * spring
			contact_slope += (float(ground.call(wheel_x + 5.0)) - float(ground.call(wheel_x - 5.0))) / 10.0
			if side > 0.0:
				compression_front = clampf(penetration / 36.0, 0.0, 1.0)
			else:
				compression_rear = clampf(penetration / 36.0, 0.0, 1.0)
	front_compression = move_toward(front_compression, compression_front, dt * 15.0)
	rear_compression = move_toward(rear_compression, compression_rear, dt * 15.0)
	grounded = contacts > 0
	if grounded:
		airborne_time = 0.0
		var terrain_angle := atan(contact_slope / float(contacts))
		angular_force += wrapf(terrain_angle - angle, -PI, PI) * mass * 820.0
		angular_velocity += angular_force / maxf(1.0, inertia * 2.0) * dt + lean * 0.2 * dt
	else:
		airborne_time += dt
		angular_velocity += lean * 3.1 * dt
	var heat_penalty := 1.0 - clampf((engine_heat - 72.0) / 65.0, 0.0, 0.48)
	var forward := Vector2.RIGHT.rotated(angle)
	var lateral_axis := Vector2.UP.rotated(angle)
	var forward_speed := Vector2(vx, vy).dot(forward)
	var lateral_speed := Vector2(vx, vy).dot(lateral_axis)
	var engine_force := gas * 1260.0 * power * heat_penalty
	var brake_force := brake * (850.0 + absf(vx) * 2.1)
	var drag := 0.0018 * forward_speed * absf(forward_speed)
	var acceleration := (engine_force - drag - signf(forward_speed) * brake_force) / mass
	vx += forward.x * acceleration * dt
	vy += GRAVITY * gravity_scale * dt + forward.y * acceleration * dt - spring_force * dt / mass
	if grounded:
		lateral_speed *= 1.0 - clampf(grip * (2.4 + contacts * 0.55) * dt, 0.0, 1.0)
		var corrected := forward * Vector2(vx, vy).dot(forward) + lateral_axis * lateral_speed
		vx = corrected.x
		vy = corrected.y
		angular_velocity *= pow(0.16, dt)
		tire_wear = minf(1.0, tire_wear + (absf(vx) * 0.0000015 + absf(angular_velocity) * 0.00003) * dt)
	else:
		angular_velocity *= pow(0.985, dt)
	angular_velocity = clampf(angular_velocity, -4.2, 4.2)
	angle = wrapf(angle + angular_velocity * dt, -PI, PI)
	x += vx * dt
	y += vy * dt
	var deepest := 0.0
	for side in [-1.0, 1.0]:
		var offset := Vector2(side * HALF_WHEELBASE, WHEEL_OFFSET_Y).rotated(angle)
		deepest = maxf(deepest, y + offset.y + WHEEL_RADIUS - float(ground.call(x + offset.x)))
	if deepest > 0.0:
		y -= deepest
		if vy > 0.0:
			impact = old_vy
			landing_g = impact / 9.8
			vy = minf(vy, 0.0)
			if not was_grounded:
				damage = minf(MAX_DAMAGE, damage + maxf(0.0, impact - 390.0) * 0.026)
	if gas > 0.05:
		engine_heat = minf(120.0, engine_heat + (8.0 + power * 2.5) * gas * heat_multiplier * dt)
	else:
		engine_heat = maxf(0.0, engine_heat - 5.8 / maxf(0.5, heat_multiplier) * dt)
	engine_rpm = lerpf(engine_rpm, 900.0 + absf(forward_speed) * 8.5 + gas * 2600.0, minf(1.0, dt * 4.5))
	wheel_rotation = wrapf(wheel_rotation + vx * dt / WHEEL_RADIUS, -TAU, TAU)
	vx = clampf(vx, -max_speed * 0.3, max_speed)
	if not grounded:
		vx = move_toward(vx, 0.0, 4.5 * dt)
