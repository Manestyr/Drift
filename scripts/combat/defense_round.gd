class_name DefenseRound
extends RigidBody3D

signal struck(round_body: DefenseRound, missile: MissileBody)
var team: int = 0
var age: float = 0.0
var spent: bool = false
var previous: Vector3 = Vector3.ZERO
var exclusions: Array[RID] = []

func _init() -> void:
 linear_damp_mode=RigidBody3D.DAMP_MODE_REPLACE
 angular_damp_mode=RigidBody3D.DAMP_MODE_REPLACE
 mass=0.1
 gravity_scale=0
 linear_damp=0
 angular_damp=0
 collision_layer=16
 collision_mask=4
 continuous_cd=true
 contact_monitor=true
 max_contacts_reported=2

func _ready() -> void:
 var shape := CollisionShape3D.new()
 var sphere := SphereShape3D.new()
 sphere.radius=0.35
 shape.shape=sphere
 add_child(shape)
 var mesh := MeshInstance3D.new()
 var ball := SphereMesh.new()
 ball.radius=0.35
 ball.height=0.7
 mesh.mesh=ball
 var material := StandardMaterial3D.new()
 material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 material.albedo_color=Color(0.3,1,0.6)
 mesh.material_override=material
 add_child(mesh)
 previous=global_position
 body_entered.connect(func(body: Node) -> void:
  if body is MissileBody: strike(body))

func strike(missile: MissileBody) -> void:
 if spent or missile.spent or missile.team==team: return
 spent=true
 struck.emit(self,missile)
 call_deferred("queue_free")

func _physics_process(dt: float) -> void:
 age+=dt
 if age>0.5:
  queue_free()
  return
 if previous.distance_to(global_position)>0.001:
  var query := PhysicsRayQueryParameters3D.create(previous,global_position,4,exclusions)
  var result := get_world_3d().direct_space_state.intersect_ray(query)
  if not result.is_empty() and result.collider is MissileBody: strike(result.collider)
 previous=global_position
