class_name TacticalTrack
extends RefCounted

var id: String = ""
var kind: String = "ship"
var team: int = -1
var position: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO
var acceleration: Vector3 = Vector3.ZERO
var cooperative: bool = false
var velocity_known: bool = false
var quality: float = 0.0
var age: float = 0.0
var uncertainty_m: float = 0.0
var horizon: float = 0.0

func predict(seconds: float) -> Vector3:
 var t:=clampf(seconds,0,horizon)
 return position+velocity*t+acceleration*0.5*t*t

func uncertainty(seconds: float) -> float:
 # Bounded constant-acceleration extrapolation, not a promised missile path.
 var t:=clampf(seconds,0,horizon)
 return uncertainty_m+(2.0 if cooperative else 12.0)*t*t
