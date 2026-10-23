class_name ObservedTrack
extends RefCounted

# A copy of sensor evidence, never a reference to an enemy body.
var id: String = ""
var kind: String = "ship"
var quality: float = 0.0
var position_world: Vector3 = Vector3.ZERO
var velocity_world: Vector3 = Vector3.ZERO
var velocity_known: bool = false
var sampled_seconds: float = 0.0
var tracking: bool = false
var present: bool = false

func age(now: float) -> float:
 return maxf(0,now-sampled_seconds)

func estimated_position(now: float) -> Vector3:
 return position_world+(velocity_world*minf(age(now),1.5) if velocity_known else Vector3.ZERO)

func uncertain(now: float) -> bool:
 return quality<0.65 or age(now)>0.65 or not present

# Relative closest approach, NOT a guaranteed impact time. Near misses are
# excluded from automatic alerts. Carrier navigation is cooperative own data.
func approach(origin: Vector3, own_velocity: Vector3, now: float) -> Vector3:
 if not velocity_known or quality<0.45: return Vector3(-1,0,INF)
 var offset:=estimated_position(now)-origin
 var relative:=velocity_world-own_velocity
 var closing: float=-offset.normalized().dot(relative) if offset.length()>0.01 else 0.0
 if closing<=1 or relative.length_squared()<1: return Vector3(-1,closing,INF)
 var time: float=-offset.dot(relative)/relative.length_squared()
 var miss: float=(offset+relative*maxf(time,0)).length()
 return Vector3(time,closing,miss)
