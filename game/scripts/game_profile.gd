extends RefCounted
class_name GameProfile
const SAVE_PATH := "user://stride_hill_profile.cfg"
const VEHICLES := [
	{"id":"trail_buggy","name":"TRAIL BUGGY","price":0,"mass":1.0,"power":1.0,"suspension":1.0,"grip":1.0,"speed":1.0,"inertia":1.0,"color":"#e87535","description":"Balanced starter off-roader"},
	{"id":"rally_4x4","name":"RALLY 4x4","price":650,"mass":1.2,"power":1.15,"suspension":1.18,"grip":1.12,"speed":0.92,"inertia":1.15,"color":"#4c9cda","description":"Stable climb specialist"},
	{"id":"sand_buggy","name":"SAND BUGGY","price":1200,"mass":0.78,"power":1.3,"suspension":0.92,"grip":0.9,"speed":1.28,"inertia":0.82,"color":"#e8b83e","description":"Lightweight speed machine"},
	{"id":"monster_truck","name":"MONSTER TRUCK","price":2400,"mass":1.55,"power":1.42,"suspension":1.5,"grip":1.2,"speed":0.82,"inertia":1.4,"color":"#8e78c8","description":"Heavy wheels, huge suspension"},
	{"id":"motocross","name":"MOTOCROSS","price":3200,"mass":0.62,"power":1.18,"suspension":1.08,"grip":0.94,"speed":1.36,"inertia":0.72,"color":"#dc594f","description":"Agile two-wheel hill runner"},
	{"id":"rock_crawler","name":"ROCK CRAWLER","price":4600,"mass":1.42,"power":1.62,"suspension":1.72,"grip":1.48,"speed":0.7,"inertia":1.55,"color":"#72a17c","description":"Maximum grip for brutal climbs"},
	{"id":"trophy_truck","name":"TROPHY TRUCK","price":6200,"mass":1.28,"power":1.78,"suspension":1.56,"grip":1.18,"speed":1.12,"inertia":1.22,"color":"#d77b46","description":"Long-travel desert race truck"}
]
const MAPS := [
	{"name":"GREEN HIGHLANDS","subtitle":"Rolling grassland and forest trails","sky":"#9bcbd3","earth":"#74513a","surface":"#4d9a55"},
	{"name":"DESERT DUNES","subtitle":"Long sandy slopes and dry heat","sky":"#e8b98b","earth":"#9a6844","surface":"#d4a85f"},
	{"name":"FROST RIDGE","subtitle":"Icy peaks and slippery descents","sky":"#a9c7df","earth":"#647b8b","surface":"#dce8ee"},
	{"name":"VOLCANIC RUN","subtitle":"Hot rock, steep ridges and ash","sky":"#9d7976","earth":"#4b4143","surface":"#c66a45"},
	{"name":"MOON BASIN","subtitle":"Low gravity and giant air time","sky":"#4f597d","earth":"#55566d","surface":"#a4a7b9"}
]
var bank := 0
var selected_vehicle := 0
var selected_map := 0
var best_distance := 0
var upgrades := {"engine":0,"suspension":0,"tires":0,"fuel":0}
var unlocked := [0]
func load_profile() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	bank = int(cfg.get_value("career", "coins", 0))
	selected_vehicle = int(cfg.get_value("garage", "selected", 0))
	selected_map = int(cfg.get_value("career", "map", 0))
	best_distance = int(cfg.get_value("career", "best", 0))
	upgrades = cfg.get_value("upgrades", "levels", upgrades)
	unlocked = cfg.get_value("garage", "unlocked", [0])
	if unlocked.is_empty():
		unlocked = [0]
	for key in upgrades:
		upgrades[key] = clampi(int(upgrades[key]), 0, 5)
	selected_vehicle = clampi(selected_vehicle, 0, VEHICLES.size() - 1)
	selected_map = clampi(selected_map, 0, MAPS.size() - 1)
	if not unlocked.has(0):
		unlocked.append(0)
func save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("career", "coins", bank)
	cfg.set_value("career", "best", best_distance)
	cfg.set_value("garage", "selected", selected_vehicle)
	cfg.set_value("career", "map", selected_map)
	cfg.set_value("garage", "unlocked", unlocked)
	cfg.set_value("upgrades", "levels", upgrades)
	cfg.save(SAVE_PATH)
func vehicle_spec() -> Dictionary:
	var spec: Dictionary = VEHICLES[selected_vehicle].duplicate(true)
	spec["power"] = float(spec.power) * (1.0 + int(upgrades.engine) * 0.12)
	spec["suspension"] = float(spec.suspension) * (1.0 + int(upgrades.suspension) * 0.14)
	spec["grip"] = float(spec.grip) * (1.0 + int(upgrades.tires) * 0.1)
	spec["fuel_capacity"] = 100.0 + int(upgrades.fuel) * 18.0
	return spec
