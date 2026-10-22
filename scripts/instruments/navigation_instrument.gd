class_name NavigationInstrument
extends Node3D

var face: InstrumentFace
var camera: Camera3D
var arrows: Array[Node3D] = []
var inertial_frame: bool = false
var last_tick: int = -1
var displayed_vectors: Array[Vector3] = []

func _ready() -> void:
 var environment := WorldEnvironment.new()
 environment.environment = Environment.new()
 environment.environment.background_mode = Environment.BG_COLOR
 environment.environment.background_color = InstrumentFace.BACKGROUND
 add_child(environment)
 camera = Camera3D.new()
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.size = 4.3
 camera.position = Vector3(3, 2.2, 4)
 add_child(camera)
 camera.look_at(Vector3(0, -0.25, 0))
 camera.current = true
 var wire := StandardMaterial3D.new()
 wire.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 wire.albedo_color = Color(0.12, 0.22, 0.25)
 for axis in range(3):
  var ring := MeshInstance3D.new()
  var torus := TorusMesh.new()
  torus.inner_radius = 0.99
  torus.outer_radius = 1.0
  torus.rings = 32
  torus.ring_segments = 8
  ring.mesh = torus
  ring.material_override = wire
  if axis == 1:
   ring.rotation.x = PI / 2
  elif axis == 2:
   ring.rotation.z = PI / 2
  add_child(ring)
 for axis in range(3):
  var label := Label3D.new()
  label.text = ["+X", "+Y", "-Z"][axis]
  label.position = [Vector3(1.15, 0, 0), Vector3(0, 1.15, 0), Vector3(0, 0, -1.15)][axis]
  label.font_size = 40
  label.pixel_size = 0.005
  label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  label.modulate = InstrumentFace.DIM
  add_child(label)
 for color: Color in [InstrumentFace.BLUE, InstrumentFace.ORANGE, InstrumentFace.GREEN]:
  arrows.append(_arrow(color))
 var canvas := CanvasLayer.new()
 add_child(canvas)
 face = InstrumentFace.new()
 face.transparent_center = true
 face.title = "01 / NAVIGATION"
 canvas.add_child(face)
 face.content_drawer = _readout

func _arrow(color: Color) -> Node3D:
 var root := Node3D.new()
 var material := StandardMaterial3D.new()
 material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 material.albedo_color = color
 var shaft := MeshInstance3D.new()
 var cylinder := CylinderMesh.new()
 cylinder.top_radius = 0.018
 cylinder.bottom_radius = 0.018
 cylinder.height = 0.8
 shaft.mesh = cylinder
 shaft.material_override = material
 shaft.position.y = 0.4
 root.add_child(shaft)
 var head := MeshInstance3D.new()
 var cone := CylinderMesh.new()
 cone.top_radius = 0
 cone.bottom_radius = 0.09
 cone.height = 0.2
 head.mesh = cone
 head.material_override = material
 head.position.y = 0.9
 root.add_child(head)
 add_child(root)
 return root

func refresh(data: ShipTelemetry) -> void:
 last_tick = data.tick
 displayed_vectors = [data.navigation_forward(inertial_frame), data.navigation_velocity(inertial_frame), data.navigation_acceleration(inertial_frame)]
 for i in range(3):
  var vector := displayed_vectors[i]
  arrows[i].visible = vector.length() > 0.00001
  if not arrows[i].visible:
   continue
  # Align actual geometry's +Y with the vector; no ship transforms are touched.
  arrows[i].quaternion = Quaternion(Vector3.UP, vector.normalized())
  var magnitude := 1.0 if i == 0 else clampf(vector.length() / (20.0 if i == 1 else 2.0), 0.15, 1.0)
  arrows[i].scale = Vector3.ONE * magnitude
 face.refresh(data)
 face.title = "01 / NAV  " + ("WORLD" if inertial_frame else "LOCAL")
func _readout() -> void:
 var data := face.telemetry
 face.text_at(Vector2(20, 82), "FWD", InstrumentFace.BLUE, 22)
 face.text_at(Vector2(160, 82), "VEL", InstrumentFace.ORANGE, 22)
 face.text_at(Vector2(300, 82), "ACCEL", InstrumentFace.GREEN, 22)
 face.text_at(Vector2(20, 340), "%.2f m/s" % data.relative_velocity_world.length(), InstrumentFace.ORANGE, 32)
 var v := data.navigation_velocity(inertial_frame)
 face.text_at(Vector2(20, 376), "V [%+.1f, %+.1f, %+.1f]" % [v.x, v.y, v.z], InstrumentFace.ORANGE, 24)
 var a := data.navigation_acceleration(inertial_frame)
 face.text_at(Vector2(20, 410), "A [%+.1f, %+.1f, %+.1f]" % [a.x, a.y, a.z], InstrumentFace.GREEN, 24)
 face.text_at(Vector2(20, 437), "N / pause menu: LOCAL <> WORLD", InstrumentFace.DIM, 20)
