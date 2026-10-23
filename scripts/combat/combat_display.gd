class_name CombatDisplay
extends TacticalDisplay

var text_nodes: Dictionary = {}
var text_generation: int = 0
var refresh_seconds: float = 0.0
var encounter: CombatEncounter
const BG:=Color(0.015,0.027,0.033)
const PANEL:=Color(0.035,0.065,0.075)
const GREEN:=Color(0.4,0.84,0.62)
const AMBER:=Color(0.98,0.65,0.3)
const BLUE:=Color(0.4,0.68,0.95)
const DIM:=Color(0.54,0.68,0.71)

# Reuse shaped text controls and a per-display font cache; the cockpit also
# renders text in other SubViewports and Label3D nodes. Geometry stays local.
func _ready() -> void:
 super._ready()
 font=ThemeDB.fallback_font.duplicate(true)
 if font is FontFile:
  (font as FontFile).multichannel_signed_distance_field=true

func _process(dt: float) -> void:
 # Sensors are 2 Hz; 10-Hz presentation keeps maps responsive without repeatedly
 # reshaping dozens of labels at the 60-Hz authoritative simulation rate.
 refresh_seconds+=dt
 if refresh_seconds>=0.1:
  refresh_seconds=0
  queue_redraw()

func line(y: float, value: String, color: Color = Color(0.72,0.84,0.83), x: float = 32.0, pixels: int = 24) -> void:
 var id: String="%s/%s"%[x,y]
 if not text_nodes.has(id):
  var label:=Label.new()
  label.mouse_filter=Control.MOUSE_FILTER_IGNORE
  label.clip_text=true
  label.add_theme_font_override("font",font)
  add_child(label)
  text_nodes[id]=label
 var label: Label=text_nodes[id]
 label.position=Vector2(x,y-pixels)
 label.size=Vector2(932-x,pixels*1.5)
 if label.get_theme_font_size("font_size")!=pixels:
  label.add_theme_font_size_override("font_size",pixels)
 if label.get_theme_color("font_color")!=color:
  label.add_theme_color_override("font_color",color)
 if label.text!=value: label.text=value
 label.set_meta("generation",text_generation)
 label.show()
 label.queue_redraw()

func key(keyboard: String, button: int) -> String:
 return source.button_label(button) if source!=null and source.using_gamepad else keyboard

func next_action() -> String:
 var target:=sensors.selected()
 if target==null: return key("← / →",JOY_BUTTON_DPAD_RIGHT)+": select ALPHA"
 if target.team==0 or target.kind!="ship": return key("← / →",JOY_BUTTON_DPAD_RIGHT)+": select hostile ship"
 if not target.tracking: return key("T",JOY_BUTTON_X)+": TRACK TARGET"
 var launcher:=encounter.player_launcher
 if launcher.ammunition[launcher.selected_launcher]<=0 and launcher.ammunition[1-launcher.selected_launcher]>0:
  return key("L",JOY_BUTTON_DPAD_UP)+": SELECT LOADED RACK"
 if not launcher.armed: return key("K",JOY_BUTTON_DPAD_DOWN)+": ARM WEAPON"
 if launcher.last_status=="READY": return key("R",JOY_BUTTON_RIGHT_SHOULDER)+": FIRE ONE MISSILE"
 return "WAIT / "+launcher.last_status.replace("DENIED / ","").replace("BLOCKED / ","")

func _draw() -> void:
 text_generation+=1
 if encounter==null:
  super._draw()
  _finish_labels()
  return
 draw_rect(Rect2(Vector2.ZERO,size),BG)
 draw_rect(Rect2(8,8,944,624),DIM.darkened(0.5),false,2)
 line(46,"WEAPONS / DRIFT" if weapons else "DRONE CONTROL",BLUE,28,34)
 line(78,encounter.control_label(weapons),DIM,28,24)
 draw_line(Vector2(28,92),Vector2(932,92),DIM.darkened(0.5),2)
 if weapons: _weapon_face()
 else: _drone_face()
 _controls()
 _finish_labels()

func _finish_labels() -> void:
 for label: Label in text_nodes.values():
  if label.get_meta("generation",-1)!=text_generation: label.hide()

func _weapon_face() -> void:
 var target:=sensors.selected()
 var launcher:=encounter.player_launcher
 line(135,"TARGET  "+(target.contact_id if target!=null else "NONE"),AMBER,28,38)
 if target!=null:
  line(174,"%.0f m   |   %s   |   LOCK %.0f%%"%[target.relative_position.length(),"TRACKING" if target.tracking else "NOT TRACKED",target.lock_quality*100],DIM,28,28)
  draw_rect(Rect2(28,190,904,12),PANEL)
  draw_rect(Rect2(28,190,904*target.lock_quality,12),GREEN)
 var ready:=launcher.last_status=="READY"
 draw_rect(Rect2(28,222,904,90),PANEL)
 line(257,"READY TO FIRE" if ready else "BLOCKED",GREEN if ready else AMBER,46,30)
 line(296,"Release + press for each launch" if ready else launcher.last_status.replace("DENIED / ","").replace("BLOCKED / ",""),GREEN if ready else AMBER,46,30)
 line(355,"%s  |  %s RACK  |  %d + %d MISSILES"%["ARMED" if launcher.armed else "SAFE","PORT" if launcher.selected_launcher==0 else "STBD",launcher.ammunition[0],launcher.ammunition[1]],GREEN if launcher.armed else AMBER,28,28)
 line(402,"NEXT  "+next_action(),GREEN,28,30)
 var flying:=0
 for missile in encounter.missiles:
  if is_instance_valid(missile) and not missile.spent and missile.team==0: flying+=1
 var previous: String="AWAITING OUTCOME" if launcher.shots>0 else "NO LAUNCH ORDERED"
 for outcome in encounter.missile_history:
  if outcome.team==0: previous=outcome.id+" / "+outcome.outcome
 line(446,"IN FLIGHT %d   |   %s"%[flying,previous],DIM,28,24)
 line(480,"Weapons %.0f%%   |   reload %.1f s"%[encounter.player.damage_model.health.weapons,launcher.cooldown],DIM,28,24)

func _drone_face() -> void:
 var center:=Vector2(262,294)
 var scale:=190.0/1200.0
 draw_rect(Rect2(28,110,466,374),PANEL)
 for radius: float in [400,800,1200]: draw_arc(center,radius*scale,0,TAU,64,DIM.darkened(0.55))
 draw_line(center-Vector2(200,0),center+Vector2(200,0),DIM.darkened(0.6))
 draw_line(center-Vector2(0,170),center+Vector2(0,170),DIM.darkened(0.6))
 line(140,"FORWARD ↑ / 1.2 km",BLUE,55,25)
 draw_colored_polygon(PackedVector2Array([center+Vector2(0,-12),center+Vector2(-8,9),center+Vector2(8,9)]),BLUE)
 line(464,"DRIFT / top view X-Z",DIM,55,24)
 for contact in sensors.contacts:
  if contact.team==1 and contact.kind=="missile":
   var offset:=Vector2(contact.relative_position.x,contact.relative_position.z)*scale
   var point:=center+offset.limit_length(174)
   draw_circle(point,7,AMBER)
 var active:=is_instance_valid(encounter.drone)
 if active:
  var drone:=encounter.drone
  var relative:=encounter.player.global_basis.inverse()*(drone.global_position-encounter.player.global_position)
  var offset:=Vector2(relative.x,relative.z)*scale
  var point:=center+offset.limit_length(174)
  if offset.length()<=174: draw_arc(point,drone.engagement_range*scale,0,TAU,64,GREEN,2)
  draw_line(center,point,GREEN.darkened(0.4),2)
  draw_rect(Rect2(point-Vector2(7,7),Vector2(14,14)),GREEN)
  line(187,"BLUE-D1",GREEN,520,30)
  line(232,drone.command_mode,GREEN,520,38)
  line(279,"AMMO  %d"%drone.ammunition,DIM,520,30)
  line(319,"FUEL  %.0f m/s"%drone.fuel_delta_v,DIM,520,28)
  line(359,"RADIUS  %.0f m"%drone.engagement_range,DIM,520,26)
  line(399,"WP %d | %.0f m from ship"%[encounter.selected_waypoint+1,relative.length()],DIM,520,24)
  line(440,"Gun ON" if drone.defense_enabled else "Gun OFF",GREEN if drone.defense_enabled else AMBER,520,28)
 else:
  line(204,"BLUE-D1",GREEN,520,32)
  line(252,"DOCKED" if encounter.drone_available else "LOST",AMBER,520,36)
  line(303,"AMMO %d"%encounter.drone_rounds,DIM,520,28)
  line(350,"FUEL %.0f m/s"%encounter.drone_fuel,DIM,520,28)
  line(408,key("L",JOY_BUTTON_DPAD_UP)+": DEPLOY",GREEN,520,28)

func _controls() -> void:
 draw_rect(Rect2(20,500,920,126),PANEL)
 if weapons:
  line(530,"%s: target   %s: track   %s: leave"%[key("←/→",JOY_BUTTON_DPAD_RIGHT),key("T",JOY_BUTTON_X),key("F",JOY_BUTTON_A)],DIM,32,26)
  line(568,"%s: rack   %s: arm/safe   %s: FIRE"%[key("L",JOY_BUTTON_DPAD_UP),key("K",JOY_BUTTON_DPAD_DOWN),key("R",JOY_BUTTON_RIGHT_SHOULDER)],AMBER,32,28)
  line(607,"%s: missile cam   %s: role consent"%[key("H",JOY_BUTTON_LEFT_SHOULDER),key("O",JOY_BUTTON_RIGHT_STICK)],DIM,32,26)
 else:
  line(530,"%s: deploy   %s: waypoint   %s: DEFEND"%[key("L",JOY_BUTTON_DPAD_UP),key("K",JOY_BUTTON_DPAD_DOWN),key("R",JOY_BUTTON_RIGHT_SHOULDER)],GREEN,32,26)
  line(568,"%s: HOLD   %s: RECALL   %s: leave"%[key("H",JOY_BUTTON_LEFT_SHOULDER),key("C",JOY_BUTTON_BACK),key("F",JOY_BUTTON_A)],DIM,32,26)
  line(607,"%s: track   %s: target   %s: role consent"%[key("T",JOY_BUTTON_X),key("←/→",JOY_BUTTON_DPAD_RIGHT),key("O",JOY_BUTTON_RIGHT_STICK)],DIM,32,26)
