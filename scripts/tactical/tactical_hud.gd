class_name TacticalHud
extends Control

var state: ShipDesignations
var camera: Camera3D
var own_transform: Transform3D = Transform3D.IDENTITY
var own_velocity: Vector3 = Vector3.ZERO
var markers: Array[Dictionary]=[]
var labels: Array[Label]=[]
var overflow: Label
var label_font: Font
var next_text_seconds: float = 0.0
const ORANGE:=Color(1,0.65,0.27)
const RED:=Color(1,0.32,0.30)

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 # Own raster font data avoids cross-viewport cache coupling; shadows are
 # omitted because dynamic shadowed glyphs fragmented in llvmpipe captures.
 label_font=ThemeDB.fallback_font.duplicate(true)
 if ThemeDB.fallback_font is FontFile:
  var isolated:=FontFile.new()
  isolated.data=(ThemeDB.fallback_font as FontFile).data.duplicate()
  label_font=isolated
 for index in 4:
  var label:=Label.new()
  label.mouse_filter=Control.MOUSE_FILTER_IGNORE
  label.add_theme_font_override("font",label_font)
  label.add_theme_font_size_override("font_size",17)
  add_child(label)
  labels.append(label)
 overflow=Label.new()
 overflow.position=Vector2(24,48)
 overflow.add_theme_font_override("font",label_font)
 overflow.add_theme_font_size_override("font_size",18)
 overflow.add_theme_color_override("font_color",RED)
 add_child(overflow)

# Projection is independent of enemy nodes and uses the actual active camera.
# Behind-camera bearings use absolute depth to avoid mirrored edge arrows.
static func project(camera_node: Camera3D, point: Vector3, screen: Vector2) -> Dictionary:
 if camera_node==null or not point.is_finite() or not screen.is_finite() or screen.x<400 or screen.y<300: return {}
 var local:=camera_node.global_transform.affine_inverse()*point
 if local.length()<0.01: return {}
 var bounds:=Rect2(Vector2(72,104),screen-Vector2(144,246))
 var front: bool=local.z<-camera_node.near
 var pixel: Vector2=camera_node.unproject_position(point) if front else Vector2(-1,-1)
 if front and bounds.has_point(pixel): return {"point":pixel,"edge":false,"direction":Vector2.ZERO,"behind":false}
 var direction:=Vector2(local.x,-local.y)
 # Exact aft is rotationally ambiguous: choose a deterministic right-hand arrow,
 # and label AFT explicitly rather than pretending the target is in front.
 if direction.length()<0.001: direction=Vector2.RIGHT
 direction=direction.normalized()
 if front:
  direction=(pixel-screen*0.5).normalized()
 var half:=bounds.size*0.5
 var extent:=minf(half.x/maxf(absf(direction.x),0.0001),half.y/maxf(absf(direction.y),0.0001))
 return {"point":bounds.get_center()+direction*extent,"edge":true,"direction":direction,"behind":not front}

func refresh() -> void:
 markers.clear()
 if state==null or camera==null: return
 var selected: Array[ObservedTrack]=[]
 if state.primary!=null:
  var target:=state.get_track(state.primary.target_id)
  if target!=null: selected.append(target)
 var warnings:=state.warning_tracks(own_transform.origin,own_velocity)
 for index in mini(3,warnings.size()): selected.append(warnings[index])
 for track in selected:
  var point:=track.estimated_position(state.now)
  var projection:=project(camera,point,size)
  if projection.is_empty(): continue
  var offset:=point-own_transform.origin
  var local:=own_transform.basis.inverse()*offset
  var bearing: String="FRONT" if -local.z>offset.length()*0.5 else ("AFT" if local.z>offset.length()*0.5 else "SIDE")
  var priority: bool=state.threat!=null and state.threat.target_id==track.id
  var relative:=track.velocity_world-own_velocity
  var text: String=("PRIORITY " if priority else ("TARGET " if track.kind=="ship" else "MISSILE "))+track.id
  text+=" / "+bearing+(" / BEHIND VIEW" if projection.behind else "")
  text+="\n~%.0f m"%offset.length()
  if track.velocity_known:
   if track.kind=="ship": text+=" | rel %.0f m/s"%relative.length()
   else:
    var approach:=track.approach(own_transform.origin,own_velocity,state.now)
    text+=" | closing %.0f m/s"%approach.y
    if approach.x>0 and approach.x<=30 and approach.z<=100: text+=" | near ~%.1f s"%approach.x
  else: text+=" | velocity UNKNOWN"
  if track.uncertain(state.now): text+="\nUNCERTAIN / age %.1f s"%track.age(state.now)
  # Four compact callouts stay above the physical instrument cluster. Stable
  # slots avoid text jumping/overlap when several bearings are nearly identical.
  var slot:=markers.size()
  var label_at:=Vector2(size.x-354 if slot%2==0 else 24,96 if slot<2 else 220)
  var color: Color=ORANGE if track.kind=="ship" else RED
  var velocity_end:=project(camera,point+relative*1.0,size) if track.velocity_known and track.kind=="ship" else {}
  markers.append({"id":track.id,"estimated":point,"point":projection.point,"edge":projection.edge,"direction":projection.direction,"uncertain":track.uncertain(state.now),"priority":priority,"color":color,"text":text,"label":label_at,"velocity":velocity_end})
 for index in labels.size():
  labels[index].visible=index<markers.size()
  if index<markers.size():
   var signature: String=markers[index].id+str(markers[index].uncertain)+str(markers[index].priority)
   if state.now>=next_text_seconds or labels[index].get_meta("signature","")!=signature:
    if labels[index].text!=markers[index].text: labels[index].text=markers[index].text
    labels[index].set_meta("signature",signature)
   labels[index].position=markers[index].label
   labels[index].add_theme_color_override("font_color",markers[index].color)
 if state.now>=next_text_seconds: next_text_seconds=state.now+0.1
 overflow.text="THREATS %d / showing %d (operator priority first)"%[warnings.size(),mini(3,warnings.size())] if not warnings.is_empty() else ""
 queue_redraw()

func _draw() -> void:
 for marker in markers:
  var p: Vector2=marker.point
  var color: Color=marker.color
  var radius: float=17 if marker.priority else 11
  if marker.edge:
   var direction: Vector2=marker.direction
   var side:=Vector2(-direction.y,direction.x)
   draw_polyline(PackedVector2Array([p-direction*15+side*9,p,p-direction*15-side*9]),color,3,true)
  else:
   var vertices:=PackedVector2Array([p+Vector2(0,-radius),p+Vector2(radius,0),p+Vector2(0,radius),p+Vector2(-radius,0),p+Vector2(0,-radius)])
   for index in 4:
    if marker.uncertain:
     draw_dashed_line(vertices[index],vertices[index+1],color,2,4)
    else: draw_line(vertices[index],vertices[index+1],color,2,true)
  if marker.priority: draw_arc(p,radius+7,0,TAU,24,color,2,true)
  if not marker.velocity.is_empty() and not marker.edge and not marker.velocity.edge:
   var end: Vector2=marker.velocity.point
   var vector: Vector2=(end-p).limit_length(70)
   if vector.length()>3:
    draw_line(p,p+vector,color,2,true)
    draw_circle(p+vector,3,color)
  draw_line(p,marker.label+Vector2(0,10),Color(color,0.35),1,true)
