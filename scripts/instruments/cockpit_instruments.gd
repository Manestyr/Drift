class_name CockpitInstruments
extends Node3D

var navigation: NavigationInstrument
var propulsion: PropulsionInstrument
var computer: ComputerInstrument
var viewports: Array[SubViewport] = []
var screens: Array[MeshInstance3D] = []
var sample_count: int = 0
var snapshot := ShipTelemetry.new()

func _ready() -> void:
 for i in range(3):
  var viewport := SubViewport.new()
  viewport.size = Vector2i(512, 448)
  viewport.own_world_3d = true
  viewport.gui_disable_input = true
  viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
  add_child(viewport)
  viewports.append(viewport)
 navigation = NavigationInstrument.new()
 viewports[0].add_child(navigation)
 propulsion = PropulsionInstrument.new()
 viewports[1].add_child(propulsion)
 computer = ComputerInstrument.new()
 viewports[2].add_child(computer)
 mount(self, Vector3.ZERO)

func refresh(data: ShipTelemetry) -> void:
 snapshot = data
 sample_count += 1
 navigation.refresh(data)
 propulsion.refresh(data)
 computer.refresh(data)

func mount(parent: Node3D, offset: Vector3) -> void:
 # Shared textures also mount into the existing isolated local interior world.
 for i in range(3):
  var mounting := Node3D.new()
  mounting.position = offset + Vector3((i - 1) * 1.13, 0.98, -20.05)
  mounting.rotation = Vector3(deg_to_rad(-12), deg_to_rad((1 - i) * 10), 0)
  parent.add_child(mounting)
  _solid(mounting, Vector3(0, 0, -0.065), Vector3(1.13, 1.0, 0.12), Color(0.075, 0.092, 0.095))
  var screen := MeshInstance3D.new()
  var quad := QuadMesh.new()
  quad.size = Vector2(1.05, 0.92)
  screen.mesh = quad
  screen.position.z = 0.002
  var material := StandardMaterial3D.new()
  material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  material.albedo_texture = viewports[i].get_texture()
  material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
  screen.material_override = material
  mounting.add_child(screen)
  if parent == self:
   screens.append(screen)
  _solid(parent, offset + Vector3((i - 1) * 1.13, 0.38, -20.1), Vector3(0.12, 0.65, 0.16), Color(0.09, 0.11, 0.12))
 _solid(parent, offset + Vector3(0, 0.30, -20.1), Vector3(3.65, 0.16, 1.0), Color(0.10, 0.12, 0.13))
 for side: float in [-1, 1]:
  _solid(parent, offset + Vector3(side * 1.92, 1.6, -20.0), Vector3(0.13, 2.4, 0.18), Color(0.11, 0.13, 0.14))
 _solid(parent, offset + Vector3(0, 2.74, -20.0), Vector3(3.95, 0.14, 0.18), Color(0.11, 0.13, 0.14))

func _solid(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
 var mesh := MeshInstance3D.new()
 var box := BoxMesh.new()
 box.size = size
 mesh.mesh = box
 mesh.position = at
 var material := StandardMaterial3D.new()
 material.albedo_color = color
 material.roughness = 0.9
 mesh.material_override = material
 parent.add_child(mesh)
