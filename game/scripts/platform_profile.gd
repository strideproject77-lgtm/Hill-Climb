extends RefCounted
class_name IHPlatformProfile

## Shared platform capability profile. Gameplay code should query this helper
## rather than scattering platform-name checks across scenes and controllers.

static func platform_name() -> String:
	return OS.get_name().to_lower()

static func is_ios() -> bool:
	return OS.get_name() == "iOS"

static func is_android() -> bool:
	return OS.get_name() == "Android"

static func is_mobile() -> bool:
	return is_ios() or is_android()

static func supports_touch_controls() -> bool:
	return is_mobile() or DisplayServer.is_touchscreen_available()

static func preferred_frame_rate() -> int:
	# Keep a conservative default for mobile thermals; allow desktop to run uncapped.
	return 60 if is_mobile() else 0

static func quality_profile() -> String:
	return "mobile" if is_mobile() else "desktop"
