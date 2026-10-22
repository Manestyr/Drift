class_name FlightComputer
extends RefCounted

# Pure fixed-tick controller: outputs actuation, never writes a body pose/velocity.
var rotation_stabilization: bool = false
var attitude_hold: bool = false
var target_attitude: Quaternion = Quaternion.IDENTITY
var reference_velocity: Vector3 = Vector3.ZERO
var reference_name: String = "Arena / inertial rest"
var force_local: Vector3 = Vector3.ZERO
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

func capture_attitude(basis: Basis) -> void:
 target_attitude = basis.get_rotation_quaternion().normalized()
 attitude_hold = true

func solve(command: FlightCommand, basis: Basis, world_velocity: Vector3,
 world_omega: Vector3, moment: Vector3, mass_kg: float,
 force_limit: float, torque_limit: Vector3) -> void:
 var manual := command.translation.limit_length()
 var velocity := basis.inverse() * (world_velocity - reference_velocity)
 active_brake_axes = Vector3.ONE if command.brake_all else command.brake_axes
 for axis in range(3):
  if absf(manual[axis]) > 0.0001 or (axis == 2 and command.main_engine > 0.0001):
   active_brake_axes[axis] = 0.0
 var selected := velocity * active_brake_axes
 var auto_force := -selected * mass_kg / VELOCITY_TAU
 var manual_force := manual * force_limit
 var remaining_force := sqrt(maxf(0.0, force_limit * force_limit - manual_force.length_squared()))
 brake_force_fraction = remaining_force / force_limit
 force_local = manual_force + auto_force.limit_length(remaining_force)
 if active_brake_axes != _previous_axes:
  _start_speed = selected.length()
 _previous_axes = active_brake_axes
 var speed := selected.length()
 if active_brake_axes == Vector3.ZERO:
  _start_speed = 0.0
  brake_progress = 0.0
  brake_eta = 0.0
 else:
  brake_progress = clampf(1.0 - speed / maxf(_start_speed, 0.0001), 0.0, 1.0)
  var acceleration := force_limit / mass_kg
  var transition := acceleration * VELOCITY_TAU
  brake_eta = maxf(0.0, (speed - transition) / acceleration)
  brake_eta += VELOCITY_TAU * log(maxf(minf(speed, transition), 0.05) / 0.05)
 var omega := basis.inverse() * world_omega
 var manual_rotation := command.rotation.limit_length()
 # A deliberate manual rotation disengages attitude hold, never fights its target.
 if manual_rotation.length_squared() > 0.000001:
  attitude_hold = false
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
 var automatic := alpha * moment / torque_limit
 for axis in range(3):
  if absf(manual_rotation[axis]) > 0.0001:
   automatic[axis] = 0.0
 var remaining_torque := sqrt(maxf(0.0, 1.0 - manual_rotation.length_squared()))
 torque_local = (manual_rotation + automatic.limit_length(remaining_torque)) * torque_limit
