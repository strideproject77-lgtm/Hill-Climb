extends RefCounted
class_name VehiclePhysics

const GRAVITY := 1450.0
const WHEEL_RADIUS := 21.0
const HALF_WHEELBASE := 57.0
const WHEEL_OFFSET_Y := 25.0

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

func step(dt: float, gas: float, brake: float, lean: float, ground: Callable, spec: Dictionary) -> void:
	var mass: float = float(spec.get("mass", 1.0))
	var power: float = float(spec.get("power", 1.0))
	var suspension: float = float(spec.get("suspension", 1.0))
	var grip: float = float(spec.get("grip", 1.0))
	var wheelbase := HALF_WHEELBASE * 2.0
	var old_vy := vy
	var total_spring := 0.0
	var total_torque := 0.0
	var contacts := 0
	var compression_front := 0.0
	var compression_rear := 0.0
	for side in [-1.0, 1.0]:
		var local_offset := Vector2(side * HALF_WHEELBASE, WHEEL_OFFSET_Y)
		var rotated := local_offset.rotated(angle)
		var wheel_x := x + rotated.x
		var wheel_y := y + rotated.y
		var floor_y := float(ground.call(wheel_x))
		var penetration := wheel_y + WHEEL_RADIUS - floor_y
		if penetration > 0.0:
			contacts += 1
			var spring := clampf(penetration * 105.0 * suspension - vy * 13.0, 0.0, 26000.0)
			total_spring += spring
			total_torque += rotated.x * spring
			if side > 0.0:
				compression_front = clampf(penetration / 34.0, 0.0, 1.0)
			else:
				compression_rear = clampf(penetration / 34.0, 0.0, 1.0)
	front_compression = move_toward(front_compression, compression_front, dt * 12.0)
	rear_compression = move_toward(rear_compression, compression_rear, dt * 12.0)
	grounded = contacts > 0
	var forward := Vector2.RIGHT.rotated(angle)
	var traction := gas * 1050.0 * power * grip
	var braking := brake * 1450.0
	vx += forward.x * (traction - braking * signf(vx)) * dt / mass
	vy += GRAVITY * dt - total_spring * dt / mass
	var torque_accel := total_torque / (mass * wheelbase * wheelbase * 0.42)
	if grounded:
		angular_velocity += torque_accel * dt
		angular_velocity += lean * 0.18 * dt
		angular_velocity *= pow(0.18, dt)
		var forward_speed := Vector2(vx, vy).dot(forward)
		var side_axis := Vector2.UP.rotated(angle)
		var lateral := Vector2(vx, vy).dot(side_axis)
		var corrected := forward * forward_speed + side_axis * lateral * maxf(0.0, 1.0 - grip * 2.8 * dt)
		vx = corrected.x
		vy = corrected.y
	else:
		angular_velocity += lean * 2.7 * dt
		angular_velocity *= pow(0.92, dt)
	angular_velocity = clampf(angular_velocity, -3.8, 3.8)
	angle = wrapf(angle + angular_velocity * dt, -PI, PI)
	x += vx * dt
	y += vy * dt
	var worst_penetration := 0.0
	for side in [-1.0, 1.0]:
		var offset := Vector2(side * HALF_WHEELBASE, WHEEL_OFFSET_Y).rotated(angle)
		var floor_y := float(ground.call(x + offset.x))
		worst_penetration = maxf(worst_penetration, y + offset.y + WHEEL_RADIUS - floor_y)
	if worst_penetration > 0.0:
		y -= worst_penetration
		if vy > 0.0:
			impact = maxf(impact, vy - old_vy)
			vy = minf(vy, 0.0)
	if not grounded:
		vx = move_toward(vx, 0.0, 7.0 * dt)
	vx = clampf(vx, -180.0, 760.0)
