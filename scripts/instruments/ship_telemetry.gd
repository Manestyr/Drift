class_name ShipTelemetry
extends RefCounted

# One coherent, read-only-by-convention snapshot from the completed force callback.
var tick: int = 0
var orientation: Basis = Basis.IDENTITY
var velocity_world: Vector3 = Vector3.ZERO
var velocity_local: Vector3 = Vector3.ZERO
var relative_velocity_world: Vector3 = Vector3.ZERO
var acceleration_world: Vector3 = Vector3.ZERO
var acceleration_local: Vector3 = Vector3.ZERO
var angular_rate_local: Vector3 = Vector3.ZERO
var main_fraction: float = 0.0
var rcs_translation: Vector3 = Vector3.ZERO
var rcs_rotation: Vector3 = Vector3.ZERO
var auto_translation: Vector3 = Vector3.ZERO
var auto_rotation: Vector3 = Vector3.ZERO
var stabilization: bool = false
var hold: bool = false
var brake_axes: Vector3 = Vector3.ZERO
var roll_brake: bool = false
var reference_name: String = "Arena / inertial rest"
var progress: float = 0.0
var eta: float = 0.0
var brake_budget: float = 1.0
var drift_active: bool = false
var drift_vector: Vector3 = Vector3.ZERO
var drift_eta: float = -1.0
var retrograde_status: String = "IDLE"
var retrograde_active: bool = false
var negative_limits: Vector3 = Vector3.ZERO
var positive_limits: Vector3 = Vector3.ZERO
var main_limit: float = 0.0

static func capture(ship: ShipPhysics, state: PhysicsDirectBodyState3D = null) -> ShipTelemetry:
 var data := ShipTelemetry.new()
 data.tick = ship.tick
 data.orientation = ship.global_basis if state == null else state.transform.basis
 data.velocity_world = ship.linear_velocity if state == null else state.linear_velocity
 data.velocity_local = data.orientation.inverse() * data.velocity_world
 data.relative_velocity_world = data.velocity_world - ship.computer.reference_velocity
 data.acceleration_world = ship.acceleration_world
 data.acceleration_local = data.orientation.inverse() * data.acceleration_world
 var omega := ship.angular_velocity if state == null else state.angular_velocity
 data.angular_rate_local = data.orientation.inverse() * omega
 data.main_fraction = ship.applied_main_thrust_n / ship.main_thrust_n
 data.rcs_translation = FlightComputer.normalized_force(ship.computer.force_local, ship.negative_force_limits, ship.positive_force_limits)
 data.rcs_rotation = ship.computer.torque_local / ship.torque_limits_nm
 data.auto_translation = FlightComputer.normalized_force(ship.computer.automatic_force_local, ship.negative_force_limits, ship.positive_force_limits)
 data.auto_rotation = data.rcs_rotation - ship.command.rotation.limit_length()
 data.stabilization = ship.computer.rotation_stabilization
 data.hold = ship.computer.attitude_hold
 data.brake_axes = ship.computer.active_brake_axes
 data.roll_brake = ship.computer.roll_braking
 data.reference_name = ship.computer.reference_name
 data.progress = ship.computer.brake_progress
 data.eta = ship.computer.brake_eta
 data.brake_budget = ship.computer.brake_force_fraction
 data.drift_active = ship.computer.drift_active
 data.drift_vector = ship.computer.drift_vector
 data.drift_eta = ship.computer.drift_eta
 data.retrograde_status = ship.computer.retrograde_status
 data.retrograde_active = ship.computer.retrograde_active
 data.negative_limits = ship.negative_force_limits
 data.positive_limits = ship.positive_force_limits
 data.main_limit = ship.main_thrust_n
 return data

func navigation_velocity(inertial: bool) -> Vector3:
 return relative_velocity_world if inertial else orientation.inverse() * relative_velocity_world

func navigation_acceleration(inertial: bool) -> Vector3:
 return acceleration_world if inertial else acceleration_local

func navigation_forward(inertial: bool) -> Vector3:
 return -orientation.z if inertial else Vector3.FORWARD
