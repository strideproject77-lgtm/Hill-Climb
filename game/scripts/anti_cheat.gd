extends RefCounted
class_name FairPlayGuard

const MAX_BANK := 2000000
const MAX_GEMS := 100000
const MAX_RUN_SPEED := 1350.0
const MAX_DISTANCE_RATE := 125.0

func validate_profile(bank: int, gems: int, vehicle: int, map_index: int, vehicle_count: int, map_count: int) -> bool:
	return bank >= 0 and bank <= MAX_BANK and gems >= 0 and gems <= MAX_GEMS and vehicle >= 0 and vehicle < vehicle_count and map_index >= 0 and map_index < map_count

func validate_run(distance: float, coins: int, elapsed: float, speed: float, vehicle_speed: float) -> bool:
	if distance < 0.0 or coins < 0 or elapsed <= 0.0:
		return false
	if speed > minf(MAX_RUN_SPEED, 760.0 * vehicle_speed * 1.22):
		return false
	if distance > elapsed * MAX_DISTANCE_RATE + 45.0:
		return false
	if coins > int(distance / 20.5) + 3:
		return false
	return true

func sanitize_reward(reward: int, valid_run: bool) -> int:
	if not valid_run:
		return 0
	return clampi(reward, 0, 25000)
func validate_progression(stunts: int, checkpoints: int, bonus_coins: int, elapsed: float, distance: float) -> bool:
	if stunts < 0 or checkpoints < 0 or bonus_coins < 0 or elapsed < 0.0 or distance < 0.0:
		return false
	if checkpoints > int(distance / 1000.0):
		return false
	if stunts > int(elapsed / 0.55) + 1:
		return false
	var possible_flips := int(elapsed * 4.2 / TAU)
	var max_bonus := checkpoints * 25 + stunts * (15 + int(elapsed * 8.0) + possible_flips * 35) * 4
	return bonus_coins <= max_bonus
