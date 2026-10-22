class_name CrewStation
extends Node3D

signal occupancy_changed(occupied: bool)
signal securing_changed(secured: bool)
@export var station_id: String = "pilot"
@export var role: String = "PILOT"
var controlled_subsystems: PackedStringArray = ["flight"]
var occupant_id: String = ""
var occupied: bool = false
var secured: bool = false
var restraint_suitable: bool = true
var camera: Camera3D

# Identity and exclusive ownership are independent of the input source.
func enter(member_id: String = "local-crew") -> bool:
 if occupied or member_id.is_empty():
  return false
 occupant_id = member_id
 occupied = true
 set_secured(true)
 occupancy_changed.emit(true)
 return true

func set_secured(value: bool) -> void:
 secured = value and occupied and restraint_suitable
 securing_changed.emit(secured)

func leave() -> void:
 set_secured(false)
 occupied = false
 occupant_id = ""
 occupancy_changed.emit(false)
