class_name FlightComputer
extends RefCounted

# Pure fixed-tick controller: outputs actuation, never writes a body pose/velocity.
var rotation_stabilization: bool = false
var attitude_hold: bool = false
var target_attitude: Quaternion = Quaternion.IDENTITY
var reference_velocity: Vector3 = Vector3.ZERO
var reference_name: String = "Arena / inertial rest"
var force_local: Vector3 = Vector3.ZERO
var manual_force_local: Vector3 = Vector3.ZERO
var automatic_force_local: Vector3 = Vector3.ZERO
var drift_active: bool = false
var drift_vector: Vector3 = Vector3.ZERO
var drift_eta: float = -1.0
var retrograde_status: String = "IDLE"
var retrograde_active: bool = false
var _retrograde_requested: bool = false
var _retrograde_up: Vector3 = Vector3.UP
var _aligned_seconds: float = 0.0
const RETROGRADE_MIN_SPEED := 0.5
var torque_local: Vector3 = Vector3.ZERO
var active_brake_axes: Vector3 = Vector3.ZERO
var brake_force_fraction: float = 1.0
var roll_braking: bool = false
var brake_progress: float = 0.0
var brake_eta: float = 0.0
var _start_speed: float = 0.0
var _previous_axes: Vector3 = Vector3.ZERO
const VELOCITY_TAU := 0.8
const RATE_TAU := 0.5
const ATTITUDE_KP := 1.6
const ATTITUDE_KD := 2.529822

func reset_braking_progress() -> void:
 _previous_axes = Vector3(-1, -1, -1)

func reset_advanced() -> void:
 retrograde_active = false
 _retrograde_requested = false
 retrograde_status = "IDLE"
 drift_active = false
 drift_eta = -1.0

func request_retrograde() -> void:
 if retrograde_active:
  cancel_retrograde("CANCELLED / PILOT")
 else:
  _retrograde_requested = true

func cancel_retrograde(reason: String) -> void:
 if retrograde_active or _retrograde_requested:
  attitude_hold = false
  retrograde_status = reason
 retrograde_active = false
 _retrograde_requested = false

static func directional_limits(vector: Vector3, negative: Vector3, positive: Vector3) -> Vector3:
 return Vector3(negative.x if vector.x < 0 else positive.x,
  negative.y if vector.y < 0 else positive.y, negative.z if vector.z < 0 else positive.z)

static func normalized_force(force: Vector3, negative: Vector3, positive: Vector3) -> Vector3:
 var limits := directional_limits(force, negative, positive)
 var result := Vector3.ZERO
 for i in range(3):
  if limits[i] > 0:
   result[i] = force[i] / limits[i]
 return result

static func settling_eta(velocity: Vector3, mass_kg: float, negative: Vector3, positive: Vector3, budget: float = 1.0) -> float:
 var speed := velocity.length()
 if speed < 0.05:
  return 0.0
 if budget < 0.00001:
  return -1.0
 var stopping_limits := directional_limits(-velocity, negative, positive)
 for axis in range(3):
  if absf(velocity[axis]) > 0.05 and stopping_limits[axis] <= 0:
   return -1.0
 var unit_force := normalized_force(-velocity.normalized(), negative, positive)
 if unit_force.length() < 0.000000001:
  return -1.0
 var acceleration := budget / (unit_force.length() * mass_kg)
 var transition := acceleration * VELOCITY_TAU
 return maxf(0, (speed - transition) / acceleration) + VELOCITY_TAU * log(maxf(minf(speed, transition), 0.05) / 0.05)

func _update_retrograde(basis: Basis, velocity: Vector3, omega: Vector3, manual: Vector3) -> void:
 if _retrograde_requested:
  _retrograde_requested = false
  retrograde_active = true
  retrograde_status = "ORIENTING"
  _retrograde_up = basis.y
  _aligned_seconds = 0.0
 if not retrograde_active:
  if retrograde_status.begins_with("ALIGNED"):
   if velocity.length() < RETROGRADE_MIN_SPEED:
    retrograde_status = "COMPLETE / LOW SPEED"
   elif (-basis.z).dot(-velocity.normalized()) < cos(deg_to_rad(2.0)):
    retrograde_status = "COMPLETE / TARGET CHANGED"
  return
 if manual.length_squared() > 0.000001:
  cancel_retrograde("CANCELLED / MANUAL")
  return
 if velocity.length() < RETROGRADE_MIN_SPEED:
  cancel_retrograde("LOW SPEED / INHIBITED")
  return
 var back := velocity.normalized() # -Z/main points opposite relative velocity.
 var up := _retrograde_up - back * _retrograde_up.dot(back)
 if up.length() < 0.001:
  var seed := Vector3.UP if absf(back.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
  up = seed - back * seed.dot(back)
 up = up.normalized()
 var right := up.cross(back).normalized()
 up = back.cross(right).normalized()
 _retrograde_up = up
 target_attitude = Basis(right, up, back).get_rotation_quaternion().normalized()
 attitude_hold = true
 var error := basis.get_rotation_quaternion().angle_to(target_attitude)
 if error < deg_to_rad(2.0):
  retrograde_status = "SETTLING"
 else:
  retrograde_status = "ORIENTING"
 if error < deg_to_rad(0.5) and omega.length() < deg_to_rad(0.5):
  _aligned_seconds += 1.0 / float(Engine.physics_ticks_per_second)
 else:
  _aligned_seconds = 0.0
 if _aligned_seconds >= 0.5:
  retrograde_active = false
  retrograde_status = "ALIGNED / NO AUTO BURN"

func capture_attitude(basis: Basis) -> void:
 cancel_retrograde("CANCELLED / HOLD")
 target_attitude = basis.get_rotation_quaternion().normalized()
 attitude_hold = true

func solve(command: FlightCommand, basis: Basis, world_velocity: Vector3,
 world_omega: Vector3, moment: Vector3, mass_kg: float,
 force_limit: float, torque_limit: Vector3, negative_limits: Vector3 = Vector3.ZERO, positive_limits: Vector3 = Vector3.ZERO) -> void:
 var manual := command.translation.limit_length()
 var velocity := basis.inverse() * (world_velocity - reference_velocity)
 var negative := Vector3.ONE * force_limit if negative_limits == Vector3.ZERO else negative_limits
 var positive := Vector3.ONE * force_limit if positive_limits == Vector3.ZERO else positive_limits
 drift_active = command.drift_cancel
 drift_vector = Vector3(velocity.x, velocity.y, 0)
 active_brake_axes = Vector3.ONE if command.brake_all else command.brake_axes
 if drift_active:
  active_brake_axes = active_brake_axes.max(Vector3(1, 1, 0))
 for axis in range(3):
  if absf(manual[axis]) > 0.0001 or (axis == 2 and command.main_engine > 0.0001):
   active_brake_axes[axis] = 0.0
 var selected := velocity * active_brake_axes
 var auto_force := -selected * mass_kg / VELOCITY_TAU
 manual_force_local = manual * directional_limits(manual, negative, positive)
 var effective_manual := normalized_force(manual_force_local, negative, positive)
 brake_force_fraction = sqrt(maxf(0.0, 1.0 - effective_manual.length_squared()))
 var automatic_request := normalized_force(auto_force, negative, positive).limit_length(brake_force_fraction)
 automatic_force_local = automatic_request * directional_limits(automatic_request, negative, positive)
 force_local = manual_force_local + automatic_force_local
 if active_brake_axes != _previous_axes:
  _start_speed = selected.length()
 _previous_axes = active_brake_axes
 if active_brake_axes == Vector3.ZERO:
  _start_speed = 0.0
  brake_progress = 0.0
  brake_eta = 0.0
 else:
  brake_progress = clampf(1.0 - selected.length() / maxf(_start_speed, 0.0001), 0.0, 1.0)
  brake_eta = settling_eta(selected, mass_kg, negative, positive, brake_force_fraction)
 drift_eta = -1.0
 if drift_active:
  drift_eta = settling_eta(drift_vector, mass_kg, negative, positive, brake_force_fraction)
  for axis in range(2):
   if active_brake_axes[axis] == 0 and absf(velocity[axis]) > 0.05:
    drift_eta = -1.0
 _update_retrograde(basis, world_velocity - reference_velocity, world_omega, command.rotation)
 var omega := basis.inverse() * world_omega
 var manual_rotation := command.rotation.limit_length()
 # A deliberate manual rotation disengages attitude hold, never fights its target.
 if manual_rotation.length_squared() > 0.000001:
  attitude_hold = false
  if retrograde_status.begins_with("ALIGNED"):
   retrograde_status = "COMPLETE / RELEASED"
 var alpha := Vector3.ZERO
 if attitude_hold:
  var error := (target_attitude * basis.get_rotation_quaternion().inverse()).normalized()
  if error.w < 0.0:
   error = Quaternion(-error.x, -error.y, -error.z, -error.w)
  var angle := error.get_angle()
  var error_local := Vector3.ZERO
  if angle > 0.000001:
   error_local = basis.inverse() * error.get_axis() * angle
  alpha = error_local * ATTITUDE_KP - omega * ATTITUDE_KD
 elif rotation_stabilization:
  alpha = -omega / RATE_TAU
 roll_braking = command.brake_roll and absf(manual_rotation.z) < 0.0001
 if roll_braking:
  alpha.z = -omega.z / RATE_TAU
 var automatic := Vector3.ZERO
 for axis in range(3):
  if torque_limit[axis] > 0.0:
   automatic[axis] = alpha[axis] * moment[axis] / torque_limit[axis]
 for axis in range(3):
  if absf(manual_rotation[axis]) > 0.0001:
   automatic[axis] = 0.0
 var remaining_torque := sqrt(maxf(0.0, 1.0 - manual_rotation.length_squared()))
 torque_local = (manual_rotation + automatic.limit_length(remaining_torque)) * torque_limit
