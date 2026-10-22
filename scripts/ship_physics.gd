class_name ShipPhysics
extends RigidBody3D

signal state_sampled(tick: int)
@export var main_thrust_n: float = 2400000.0
@export var rcs_thrust_n: float = 240000.0
@export var torque_limits_nm := Vector3(5284000.0, 5380000.0, 296000.0)
var computer := FlightComputer.new()
var effective_inertia: Vector3 = Vector3.ZERO
var command := FlightCommand.new()
var acceleration_world: Vector3 = Vector3.ZERO
var applied_main_thrust_n: float = 0.0
var acceleration_local: Vector3 = Vector3.ZERO
var tick: int = 0
var reset_requested: bool = false

func _init() -> void:
 mass = 120000.0
 gravity_scale = 0.0
 linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
 angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
 linear_damp = 0.0
 angular_damp = 0.0
 can_sleep = false
 # Uniform 7 x 5 x 36 m hull; kg m². Explicit principal axes.
 inertia = mass / 12.0 * Vector3(5.0*5.0 + 36.0*36.0, 7.0*7.0 + 36.0*36.0, 7.0*7.0 + 5.0*5.0)
 collision_layer = 1
 collision_mask = 1

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
 if reset_requested:
  state.transform = Transform3D.IDENTITY
  state.linear_velocity = Vector3.ZERO
  state.angular_velocity = Vector3.ZERO
  command.clear()
  computer.attitude_hold = false
  reset_requested = false
 effective_inertia = Vector3.ONE / state.inverse_inertia
 computer.solve(command, state.transform.basis, state.linear_velocity,
  state.angular_velocity, effective_inertia, mass, rcs_thrust_n, torque_limits_nm)
 var force_local := computer.force_local
 applied_main_thrust_n = clampf(command.main_engine, 0.0, 1.0) * main_thrust_n
 force_local += Vector3.FORWARD * applied_main_thrust_n
 var force_world := state.transform.basis * force_local
 state.apply_central_force(force_world)
 state.apply_torque(state.transform.basis * computer.torque_local)
 # Proper acceleration from commanded force, excludes coordinate rotation.
 acceleration_world = force_world / mass
 acceleration_local = force_local / mass
 tick += 1
 state_sampled.emit(tick)

func local_velocity() -> Vector3:
 return global_basis.inverse() * linear_velocity
