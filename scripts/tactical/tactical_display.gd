class_name TacticalDisplay
extends Control

var sensors: SensorSuite
var fire_control: FireControl
var safety: CrewSafety
var weapons: bool = false
var font: Font = ThemeDB.fallback_font

func _ready() -> void:
 size = Vector2(960, 640)
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func line(y: float, value: String, color: Color = Color(0.72, 0.84, 0.83), x: float = 32.0, pixels: int = 24) -> void:
 draw_string(font, Vector2(x,y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, color)

func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size), Color(0.015,0.027,0.033))
 draw_rect(Rect2(6,6,948,628),Color(0.25,0.4,0.43),false,3)
 line(42, "DRIFT / " + ("FIRE CONTROL — INERT TEST" if weapons else "PASSIVE SENSOR / TACTICAL"))
 line(76, "OBSERVED CONTACTS ONLY / 2 Hz / RANGE 2.5 km", Color(0.45,0.6,0.65),32,20)
 var center := Vector2(270,275)
 for radius: float in [53,106,160]:
  draw_arc(center,radius,0,TAU,64,Color(0.16,0.3,0.34),1)
 draw_line(center-Vector2(172,0),center+Vector2(172,0),Color(0.2,0.35,0.4))
 draw_line(center-Vector2(0,172),center+Vector2(0,172),Color(0.2,0.35,0.4))
 draw_colored_polygon(PackedVector2Array([center+Vector2(0,-12),center+Vector2(-6,7),center+Vector2(6,7)]),Color(0.3,0.6,0.95))
 line(102,"FORWARD -Z ↑ / TOP VIEW",Color(0.3,0.6,0.95),90,18)
 var y: float = 125
 for contact in sensors.contacts:
  var selected := contact.contact_id == sensors.selected_id
  var color := Color(0.35,0.8,0.55) if contact.acquired() else Color(0.95,0.55,0.2)
  var point := center + Vector2(contact.relative_position.x,contact.relative_position.z)/2500.0*160.0
  draw_circle(point,6,color)
  if selected:
   draw_arc(point,12,0,TAU,24,Color.WHITE,2)
  draw_string(font,point+Vector2(10,-10),contact.contact_id,HORIZONTAL_ALIGNMENT_LEFT,-1,18,color)
  line(y, ("> " if selected else "  ")+contact.contact_id+" / %.0f m"%contact.relative_position.length(),color,505,22)
  line(y+25,"%s / quality %.0f%%" % ["ACQUIRED" if contact.acquired() else "INSUFFICIENT",contact.quality*100],color,520,18)
  y += 62
 var current := sensors.selected()
 if weapons:
  for i in fire_control.slots.size():
   line(355+i*27, fire_control.slots[i],Color(0.6,0.7,0.72),505,19)
  line(451,fire_control.status,Color(0.4,0.8,0.55),32,21)
  line(480,"Intercept %.1f s / SIMULATION ONLY" % fire_control.solution_seconds if fire_control.solution_valid else "No usable firing solution",Color(0.7,0.8,0.8),32,21)
  line(509,fire_control.launch_safety,Color(0.96,0.62,0.25),32,21)
 else:
  if current != null:
   line(451,"Selected %s / track %s / age %.1f s" % [current.contact_id,sensors.tracking_enabled,current.age_seconds],Color(0.4,0.8,0.55),32,21)
   line(480,"Local XYZ m: %.0f / %.0f / %.0f" % [current.relative_position.x,current.relative_position.y,current.relative_position.z],Color(0.7,0.8,0.8),32,21)
   line(509,"Relative v m/s: %s" % (str(current.relative_velocity) if current.velocity_known else "ACQUIRING"),Color(0.7,0.8,0.8),32,21)
 line(550,safety.status(),Color(0.95,0.65,0.28),32,22)
 line(588,"←/→ / D-pad: target | T / X/Square: track | U / B/Circle: harness",Color(0.65,0.73,0.75),32,20)
 line(618,"F / A/Cross: leave | J / LS-click: request combat envelope",Color(0.65,0.73,0.75),32,20)
