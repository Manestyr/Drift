class_name ShipPhysics
extends RigidBody3D

signal state_sampled(tick: int)
@export var main_thrust_n: float = 2400000.0
@export var rcs_thrust_n: float = 240000.0
@export var rcs_torque_nm: float = 1800000.0
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
 inertia = Vector3(11000000.0, 11000000.0, 2200000.0)
 collision_layer = 1
 collision_mask = 1

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
 if reset_requested:
  state.transform = Transform3D.IDENTITY
  state.linear_velocity = Vector3.ZERO
  state.angular_velocity = Vector3.ZERO
  command.clear()
  reset_requested = false
 var force_local := command.translation.limit_length() * rcs_thrust_n
 applied_main_thrust_n = clampf(command.main_engine, 0.0, 1.0) * main_thrust_n
 force_local += Vector3.FORWARD * applied_main_thrust_n
 var force_world := state.transform.basis * force_local
 state.apply_central_force(force_world)
 state.apply_torque(state.transform.basis * command.rotation.limit_length() * rcs_torque_nm)
 # Proper acceleration from commanded force, excludes coordinate rotation.
 acceleration_world = force_world / mass
 acceleration_local = force_local / mass
 tick += 1
 state_sampled.emit(tick)

func local_velocity() -> Vector3:
 return global_basis.inverse() * linear_velocity
