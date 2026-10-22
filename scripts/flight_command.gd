class_name FlightCommand
extends RefCounted

# One command per fixed simulation tick; local axes, -Z is forward.
var translation: Vector3 = Vector3.ZERO
var rotation: Vector3 = Vector3.ZERO
var main_engine: float = 0.0
var brake_axes: Vector3 = Vector3.ZERO
var brake_all: bool = false
var brake_roll: bool = false

func clear() -> void:
 translation = Vector3.ZERO
 rotation = Vector3.ZERO
 main_engine = 0.0
 brake_axes = Vector3.ZERO
 brake_all = false
 brake_roll = false
