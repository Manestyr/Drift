class_name ExteriorOrbit
extends RefCounted

var yaw: float = 0.7
var pitch: float = 0.35
var distance: float = 80.0

func turn(delta: Vector2) -> void:
 yaw -= delta.x
 pitch = clampf(pitch + delta.y, -1.4, 1.4)

func zoom(amount: float) -> void:
 distance = clampf(distance * exp(amount), 24.0, 6000.0)

func update(camera: Camera3D, target: Vector3) -> void:
 camera.position = target + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
 camera.look_at(target)
