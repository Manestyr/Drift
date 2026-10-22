class_name CrewMember
extends RefCounted

var member_id: String = "local-crew"
var station_id: String = ""
var secured: bool = false
var seat_position: Vector3 = Vector3.ZERO
var seat_basis: Basis = Basis.IDENTITY
var proper_acceleration: Vector3 = Vector3.ZERO
var sample_tick: int = 0

# Observer contract for future directional/time-dependent physiology. No health writes.
func sample_load(linear_acceleration: Vector3, angular_velocity: Vector3, angular_acceleration: Vector3, ship_basis: Basis, tick: int) -> void:
 var offset := ship_basis * seat_position
 var at_place := linear_acceleration + angular_acceleration.cross(offset) + angular_velocity.cross(angular_velocity.cross(offset))
 proper_acceleration = (ship_basis * seat_basis).inverse() * at_place
 sample_tick = tick
