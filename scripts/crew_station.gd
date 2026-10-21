class_name CrewStation
extends Node3D

signal occupancy_changed(occupied: bool)
var occupied: bool = false

# Human input adapter today; a future AI adapter can submit the same command.
func enter() -> bool:
 if occupied:
  return false
 occupied = true
 occupancy_changed.emit(true)
 return true

func leave() -> void:
 occupied = false
 occupancy_changed.emit(false)
