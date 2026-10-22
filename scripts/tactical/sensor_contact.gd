class_name SensorContact
extends RefCounted

var contact_id: String = ""
var relative_position: Vector3 = Vector3.ZERO
var relative_velocity: Vector3 = Vector3.ZERO
var velocity_known: bool = false
var quality: float = 0.0
var observed_tick: int = 0
var age_seconds: float = 0.0
var observed_position_world: Vector3 = Vector3.ZERO
var observed_velocity_world: Vector3 = Vector3.ZERO
var kind: String = "ship"
var team: int = -1
var tracking: bool = false

func acquired() -> bool:
 return quality >= 0.65 and age_seconds < 1.5
