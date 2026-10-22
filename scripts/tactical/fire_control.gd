class_name FireControl
extends RefCounted

var slots: PackedStringArray = ["PORT / EMPTY", "STARBOARD / EMPTY", "DORSAL / TEST INERT"]
var solution_valid: bool = false
var solution_seconds: float = -1.0
var aim_local: Vector3 = Vector3.ZERO
var status: String = "NO SENSOR TRACK"
var launch_safety: String = "INHIBITED / NO LIVE ORDNANCE"
var assumed_speed_mps: float = 300.0

func update(contact: SensorContact) -> void:
 solution_valid = false
 solution_seconds = -1.0
 aim_local = Vector3.ZERO
 if contact == null or not contact.acquired() or not contact.velocity_known or not contact.tracking:
  status = "INSUFFICIENT / TRACK REQUIRED"
  return
 # Constant-relative-velocity interception, not actual missile guidance.
 var r := contact.relative_position
 var v := contact.relative_velocity
 var a := v.length_squared() - assumed_speed_mps * assumed_speed_mps
 var b := 2.0 * r.dot(v)
 var c := r.length_squared()
 var discriminant := b*b - 4.0*a*c
 if discriminant < 0.0:
  status = "NO INTERCEPT"
  return
 var time: float = -1.0
 if absf(a) < 0.0001:
  if absf(b) > 0.0001:
   time = -c/b
 else:
  for candidate: float in [(-b-sqrt(discriminant))/(2.0*a), (-b+sqrt(discriminant))/(2.0*a)]:
   if candidate > 0.0 and (time < 0.0 or candidate < time):
    time = candidate
 if time <= 0.0:
  status = "NO POSITIVE INTERCEPT"
  return
 solution_seconds = time
 aim_local = r + v*time
 solution_valid = true
 status = "SIMULATED SOLUTION / 300 m/s"
