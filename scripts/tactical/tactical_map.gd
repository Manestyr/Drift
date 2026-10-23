class_name TacticalMap
extends Control

const METERS_PER_UNIT:=100.0
var model:=TacticalMapModel.new()
var viewport: SubViewport
var world: Node3D
var geometry: Node3D
var camera: Camera3D
var yaw: float = 0.6
var pitch: float = 0.45
var distance: float = 22
var selected_id: String = "DRIFT"
var follow_selected: bool = false
var focus: Vector3 = Vector3.ZERO
var last_revision: int = -1
var tags: Dictionary = {}

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 position=Vector2(28,100)
 size=Vector2(904,380)
 viewport=SubViewport.new()
 viewport.size=Vector2i(904,380)
 viewport.own_world_3d=true
 viewport.world_2d=World2D.new()
 viewport.transparent_bg=false
 viewport.gui_disable_input=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 add_child(viewport)
 var texture:=TextureRect.new()
 texture.texture=viewport.get_texture()
 texture.size=size
 texture.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(texture)
 world=Node3D.new()
 viewport.add_child(world)
 var environment:=WorldEnvironment.new()
 environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR
 environment.environment.background_color=Color(0.015,0.027,0.033)
 world.add_child(environment)
 geometry=Node3D.new()
 world.add_child(geometry)
 camera=Camera3D.new()
 camera.near=0.02
 camera.far=1000
 world.add_child(camera)
 camera.current=true
 update_camera()

func update_camera() -> void:
 if camera==null: return
 var direction:=Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))
 camera.position=focus+direction*distance
 camera.look_at(focus,Vector3.UP)

func orbit(value: Vector2, dt: float) -> void:
 yaw-=value.x*dt*1.8
 pitch=clampf(pitch+value.y*dt*1.4,-1.35,1.35)
 update_camera()

func zoom(value: float) -> void:
 distance=clampf(distance*exp(value),1,120)
 update_camera()

func cycle(direction: int) -> void:
 if model.tracks.is_empty(): return
 var index:=0
 for i in model.tracks.size():
  if model.tracks[i].id==selected_id: index=i
 selected_id=model.tracks[posmod(index+direction,model.tracks.size())].id
 follow_selected=false

func focus_selected() -> void:
 var track:=model.find(selected_id)
 if track!=null:
  follow_selected=true
  focus=track.position/METERS_PER_UNIT
 update_camera()

func project(local_meters: Vector3) -> Vector2:
 return camera.unproject_position(local_meters/METERS_PER_UNIT)

func refresh() -> void:
 if not is_inside_tree(): return
 for child in geometry.get_children():
  geometry.remove_child(child)
  child.queue_free()
 if follow_selected:
  var selected:=model.find(selected_id)
  if selected!=null:
   focus=selected.position/METERS_PER_UNIT
   update_camera()
 # Sparse reference grid provides depth without duplicating simulation objects.
 for index in range(-12,13,3):
  segment(Vector3(index,0,-12),Vector3(index,0,12),Color(0.10,0.18,0.22))
  segment(Vector3(-12,0,index),Vector3(12,0,index),Color(0.10,0.18,0.22))
 segment(Vector3.ZERO,Vector3.RIGHT*3,Color(0.7,0.3,0.25))
 segment(Vector3.ZERO,Vector3.UP*3,Color(0.3,0.65,0.4))
 segment(Vector3.ZERO,Vector3.FORWARD*3,Color(0.3,0.55,0.9))
 for track in model.tracks:
  var color:=Color(0.3,0.75,1) if track.id=="DRIFT" else (Color(0.4,0.85,0.6) if track.cooperative else Color(0.95,0.55,0.25))
  var mesh:=MeshInstance3D.new()
  var sphere:=SphereMesh.new()
  sphere.radius=0.11 if track.kind=="missile" else 0.2
  sphere.height=sphere.radius*2
  mesh.mesh=sphere
  mesh.position=track.position/METERS_PER_UNIT
  mesh.material_override=material(color)
  geometry.add_child(mesh)
  # Ground/height stem makes the third dimension unambiguous while orbiting.
  segment(mesh.position,Vector3(mesh.position.x,0,mesh.position.z),color.darkened(0.65))
  if track.velocity_known:
   segment(mesh.position,mesh.position+track.velocity/METERS_PER_UNIT,color)
   var previous:=mesh.position
   for step in range(1,9):
    var t:=track.horizon*step/8.0
    var next:=track.predict(t)/METERS_PER_UNIT
    if step%2==1: segment(previous,next,color.darkened(0.25))
    previous=next
   var uncertainty:=MeshInstance3D.new()
   var bounds:=SphereMesh.new()
   bounds.radius=maxf(0.06,track.uncertainty(track.horizon)/METERS_PER_UNIT)
   bounds.height=bounds.radius*2
   bounds.radial_segments=12
   bounds.rings=6
   uncertainty.mesh=bounds
   uncertainty.position=track.predict(track.horizon)/METERS_PER_UNIT
   var translucent:=material(color)
   translucent.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
   translucent.albedo_color.a=0.12
   uncertainty.material_override=translucent
   geometry.add_child(uncertainty)
  if not tags.has(track.id):
   var created:=Label.new()
   created.mouse_filter=Control.MOUSE_FILTER_IGNORE
   created.add_theme_font_size_override("font_size",20)
   add_child(created)
   tags[track.id]=created
  var label: Label=tags[track.id]
  label.text=track.id+(" *" if track.id==selected_id else "")+" / %.0f m"%track.position.length()
  label.add_theme_color_override("font_color",color)
  label.add_theme_font_size_override("font_size",20)
  label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 for id: String in tags.keys():
  if model.find(id)==null:
   tags[id].queue_free()
   tags.erase(id)
 last_revision=model.revision
 _position_tags()

func _process(_dt: float) -> void:
 _position_tags()

func _position_tags() -> void:
 if camera==null: return
 var occupied: Array[Rect2]=[]
 for track in model.tracks:
  if not tags.has(track.id): continue
  var label: Label=tags[track.id]
  var world_point:=track.position/METERS_PER_UNIT
  var point:=camera.unproject_position(world_point)
  label.visible=not camera.is_position_behind(world_point) and Rect2(Vector2.ZERO,size).has_point(point)
  var position_hint:=(point+Vector2(8,-24)).clamp(Vector2.ZERO,size-Vector2(170,28))
  for attempt in model.tracks.size():
   var overlaps:=false
   for previous in occupied:
    if previous.intersects(Rect2(position_hint,Vector2(180,26))): overlaps=true
   if not overlaps: break
   position_hint.y=clampf(position_hint.y+27,0,size.y-28)
  label.position=position_hint
  if label.visible: occupied.append(Rect2(position_hint,Vector2(180,26)))

func segment(a: Vector3,b: Vector3,color: Color) -> void:
 if a.distance_to(b)<0.001: return
 var line:=MeshInstance3D.new()
 var mesh:=ImmediateMesh.new()
 mesh.surface_begin(Mesh.PRIMITIVE_LINES,material(color))
 mesh.surface_add_vertex(a)
 mesh.surface_add_vertex(b)
 mesh.surface_end()
 line.mesh=mesh
 geometry.add_child(line)

func material(color: Color) -> StandardMaterial3D:
 var result:=StandardMaterial3D.new()
 result.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 result.albedo_color=color
 return result
