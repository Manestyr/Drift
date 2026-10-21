class_name FlightCommand
extends RefCounted

# One command per fixed simulation tick; local axes, -Z is forward.
var translation: Vector3 = Vector3.ZERO
var rotation: Vector3 = Vector3.ZERO
var main_engine: float = 0.0

func clear() -> void:
 translation = Vector3.ZERO
 rotation = Vector3.ZERO
 main_engine = 0.0
