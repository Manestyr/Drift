class_name CrewSafety
extends RefCounted

const G: float = 9.80665
var members: Array[CrewMember] = []
var normal_limit_g: float = 3.0
var combat_limit_g: float = 8.0
var combat_requested: bool = false
var limited: bool = false
var denied: bool = false
var applied_fraction: float = 1.0

func all_secured() -> bool:
 if members.is_empty():
  return false
 for member in members:
  if not member.secured or member.station_id.is_empty():
   return false
 return true

func limit_force(request: Vector3, mass_kg: float) -> Vector3:
 denied = combat_requested and not all_secured()
 var maximum := (combat_limit_g if combat_requested and not denied else normal_limit_g) * G * mass_kg
 var result := request.limit_length(maximum)
 limited = result.length() + 0.01 < request.length()
 applied_fraction = result.length() / request.length() if request.length() > 0.001 else 1.0
 return result

func status() -> String:
 if denied:
  return "HIGH-G DENIED / CREW UNSECURED / 3 g"
 return ("COMBAT / <= 8 g" if combat_requested else "NORMAL / <= 3 g") + (" / THRUST LIMITED" if limited else "")
