class_name CrewController
extends CharacterBody3D

@export var walk_speed: float = 4.0
@export var artificial_gravity: float = 9.81
var camera: Camera3D
var seated: bool = false
var pitch: float = 0.0

func _ready() -> void:
 collision_layer = 2
 collision_mask = 2
 var shape := CollisionShape3D.new()
 var capsule := CapsuleShape3D.new()
 capsule.radius = 0.3
 capsule.height = 1.8
 shape.shape = capsule
 add_child(shape)
 camera = Camera3D.new()
 camera.position.y = 0.7
 camera.near = 0.05
 add_child(camera)
 camera.current = true

func look(relative: Vector2) -> void:
 if seated:
  return
 rotate_y(-relative.x * 0.002)
 pitch = clampf(pitch - relative.y * 0.002, -1.4, 1.4)
 camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
 if seated:
  velocity = Vector3.ZERO
  return
 var input := Input.get_vector("left", "right", "forward", "back")
 var direction := basis * Vector3(input.x, 0, input.y)
 velocity.x = direction.x * walk_speed
 velocity.z = direction.z * walk_speed
 if not is_on_floor():
  velocity.y -= artificial_gravity * delta
 else:
  velocity.y = 0.0
 move_and_slide()
