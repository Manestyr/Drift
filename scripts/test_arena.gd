class_name TestArena
extends Node3D

var grid: MeshInstance3D
var obstacle_positions: Array[Vector3] = []

func _ready() -> void:
 var rng := RandomNumberGenerator.new()
 rng.seed = 1741
 # Shared low-poly mesh/material, modest count, no objects in the launch corridor.
 var rock := SphereMesh.new()
 rock.radial_segments = 12
 rock.rings = 6
 var material := StandardMaterial3D.new()
 material.albedo_color = Color(0.42, 0.34, 0.27)
 rock.material = material
 for i in range(72):
  var size := rng.randf_range(5, 35)
  var at := Vector3(rng.randf_range(160, 1600) * (-1 if i % 2 else 1), rng.randf_range(-400, 400), rng.randf_range(-2600, 800))
  var mesh := MeshInstance3D.new()
  mesh.mesh = rock
  mesh.position = at
  mesh.scale = Vector3.ONE * size
  add_child(mesh)
  var shape := SphereShape3D.new()
  shape.radius = size * 0.5
  _collider(at, shape)
  obstacle_positions.append(at)
 # A solid station wreck, offset 320 m from the straight launch path.
 for i in range(7):
  var at := Vector3(320, float(i - 3) * 14.0, -650)
  _box(at, Vector3(12, 10, 90), Color(0.24, 0.4, 0.48))
  _box(at + Vector3(30, 0, 0), Vector3(50, 3, 55), Color(0.55, 0.34, 0.1))
 _label(Vector3(320, 65, -650), "STATION WRECK / INERTIAL REST", 0.08)
 for i in range(1, 16):
  _box(Vector3(45, -8, -i * 100), Vector3(2, 16, 2), Color(0.9, 0.6, 0.15), false)
  _label(Vector3(45, 4, -i * 100), "%d m" % (i * 100), 0.025)
 _label(Vector3(0, 25, -220), "-Z / LAUNCH DIRECTION", 0.04)
 _label(Vector3(220, 15, 0), "+X / STARBOARD", 0.04)
 _label(Vector3(0, 220, 0), "+Y / UP", 0.04)
 var lines := ImmediateMesh.new()
 var line_material := StandardMaterial3D.new()
 line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 line_material.albedo_color = Color(0.12, 0.4, 0.5)
 lines.surface_begin(Mesh.PRIMITIVE_LINES, line_material)
 for i in range(-20, 21):
  lines.surface_add_vertex(Vector3(i * 100, -60, -2000))
  lines.surface_add_vertex(Vector3(i * 100, -60, 2000))
  lines.surface_add_vertex(Vector3(-2000, -60, i * 100))
  lines.surface_add_vertex(Vector3(2000, -60, i * 100))
 lines.surface_end()
 grid = MeshInstance3D.new()
 grid.mesh = lines
 grid.visible = false
 add_child(grid)

func _collider(at: Vector3, shape: Shape3D) -> void:
 var body := StaticBody3D.new()
 body.position = at
 body.collision_layer = 1
 body.collision_mask = 1
 var collision := CollisionShape3D.new()
 collision.shape = shape
 body.add_child(collision)
 add_child(body)

func _box(at: Vector3, size: Vector3, color: Color, solid: bool = true) -> void:
 var instance := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = size
 var material := StandardMaterial3D.new()
 material.albedo_color = color
 mesh.material = material
 instance.mesh = mesh
 instance.position = at
 add_child(instance)
 if solid:
  var shape := BoxShape3D.new()
  shape.size = size
  _collider(at, shape)

func _label(at: Vector3, text: String, scale_per_pixel: float) -> void:
 var label := Label3D.new()
 label.text = text
 label.position = at
 label.font_size = 48
 label.pixel_size = scale_per_pixel
 label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 add_child(label)
