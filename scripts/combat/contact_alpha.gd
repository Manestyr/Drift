extends "res://scripts/main.gd"

var setup_mode: int = CombatProfile.Mode.MANUAL
var setup_difficulty: int = CombatProfile.Difficulty.NORMAL
var setup_seed: int = 0
var setup_weapon_grant: bool = false
var setup_drone_grant: bool = false
var primary_held: bool = false
var encounter: CombatEncounter
var mission_status: Label
var observe_missile: bool = false
# Operator context, not simulation state. Each station can later own an adapter.
enum WeaponView { FIRE_CONTROL, MAP, MISSILE }
var weapon_view: int = WeaponView.FIRE_CONTROL
var selected_missile_id: String = ""
var missile_command:=FlightCommand.new()
var missile_hint: Label
var end_panel: PanelContainer

func _new_tactical_display() -> TacticalDisplay:
 return CombatDisplay.new()

func _tactical_targets() -> void:
 # Free-flight passive scenery targets are not combat entities.
 pass

func _ready() -> void:
 super._ready()
 encounter=CombatEncounter.new()
 encounter.difficulty=setup_difficulty
 encounter.scenario_seed=setup_seed if setup_seed!=0 else randi_range(1,2147483647)
 setup_seed=encounter.scenario_seed
 encounter.weapons_station=stations[2]
 encounter.drone_station=stations[1]
 encounter.player=ship
 encounter.player_sensors=sensors
 ship.get_parent().add_child(encounter)
 encounter.set_mode(setup_mode)
 if setup_mode==CombatProfile.Mode.ASSISTED_SOLO:
  encounter.grant_role("weapons",setup_weapon_grant)
  encounter.grant_role("drone",setup_drone_grant)
 for display in tactical_displays:
  (display as CombatDisplay).encounter=encounter
 sensor_targets=encounter.observed_targets()
 audio.attach_combat(encounter)
 pause_menu.disengage_button.show()
 pause_menu.disengage_requested.connect(encounter.disengage)
 encounter.ended.connect(_mission_ended)
 var canvas := CanvasLayer.new()
 canvas.layer=3
 add_child(canvas)
 mission_status=Label.new()
 mission_status.position=Vector2(24,12)
 mission_status.add_theme_font_size_override("font_size",19)
 canvas.add_child(mission_status)
 missile_hint=Label.new()
 missile_hint.position=Vector2(24,525)
 missile_hint.add_theme_font_size_override("font_size",22)
 canvas.add_child(missile_hint)
 end_panel=PanelContainer.new()
 end_panel.position=Vector2(420,230)
 end_panel.custom_minimum_size=Vector2(440,240)
 canvas.add_child(end_panel)
 end_panel.hide()

func _physics_process(dt: float) -> void:
 if encounter==null: return
 sensor_targets=encounter.observed_targets()
 sensors.max_range_m=2500*ship.damage_model.efficiency("sensors")
 sensors.enabled=ship.damage_model.efficiency("sensors")>0
 super._physics_process(dt)
 encounter.weapons_occupied=stations[2].occupied
 encounter.drone_occupied=stations[1].occupied
 encounter.tick(dt)
 var missile:=selected_missile()
 if weapon_view==WeaponView.MISSILE and missile!=null and missile.manual_mode:
  input_source.set_orbit_mode(false)
  input_source.sample_missile(missile_command,dt)
  missile.manual_rotation=missile_command.rotation
  missile.manual_translation=Vector2(missile_command.translation.x,missile_command.translation.y)
  missile.manual_throttle=missile_command.main_engine
  if missile.global_position.distance_to(ship.global_position)>4000:
   _return_fire_control()
   encounter.last_message="MISSILE LINK LOST / AUTO"
 if encounter.result!="ACTIVE":
  ship.command.clear()
  crew.controls_enabled=false
  controls_captured=false

func _process(dt: float) -> void:
 super._process(dt)
 if encounter==null: return
 if weapon_view!=WeaponView.FIRE_CONTROL:
  status_hint.text="" # Context-specific hints replace the harness shortcuts.
 if observe_missile:
  var missile:=selected_missile()
  if missile==null:
   _return_fire_control()
  else:
   outside_camera.global_position=missile.to_global(Vector3(0,3,14))
   outside_camera.look_at(missile.global_position-missile.global_basis.z*80,missile.global_basis.y)
 if weapon_view==WeaponView.MAP:
  var map:=weapon_map()
  map.orbit(input_source.movement(),dt)
  var zoom: float=(input_source.flight_strength("pad_reverse")-input_source.flight_strength("pad_main"))*dt
  if input_source.using_gamepad: map.zoom(zoom)
 missile_hint.visible=weapon_view==WeaponView.MISSILE
 if missile_hint.visible:
  var missile:=selected_missile()
  if missile!=null:
   var pad:=input_source.using_gamepad
   missile_hint.text="%s / %s / dv %.0f m/s / control %.1f rad/s / LINK 183 ms"%[missile.name,"MANUAL" if missile.manual_mode else "AUTO VIEW",missile.fuel_delta_v,missile.control_reserve]
   missile_hint.text+="\n"+("%s: manual/auto | %s: console | %s: next missile"%[input_source.button_label(JOY_BUTTON_RIGHT_STICK),input_source.button_label(JOY_BUTTON_B),input_source.button_label(JOY_BUTTON_DPAD_RIGHT)] if pad else "M: manual/auto | Esc: console | arrows: select missile")
   if missile.manual_mode:
    missile_hint.text+="\n"+("Left stick: pitch/yaw | Right stick: side RCS | %s: burn | %s/%s: roll"%["R2" if input_source.symbol_scheme()==1 else "RT",input_source.button_label(JOY_BUTTON_LEFT_SHOULDER),input_source.button_label(JOY_BUTTON_RIGHT_SHOULDER)] if pad else "Mouse: pitch/yaw | A/D + Space/Shift: side RCS | LMB: burn | Q/E: roll")
   missile_hint.text+="\n"+("%s: leave station | %s: exterior | %s: pause"%[input_source.button_label(JOY_BUTTON_A),input_source.button_label(JOY_BUTTON_Y),input_source.button_label(JOY_BUTTON_START)] if pad else "F: leave station | V: exterior | P: pause")
 mission_status.text="ALPHA | %s | %s | %.0f s | seed %d | %s: pause"%[CombatProfile.MODE_NAMES[encounter.control_mode],CombatProfile.DIFFICULTY_NAMES[encounter.difficulty],encounter.elapsed,setup_seed,input_source.button_label(JOY_BUTTON_START) if input_source.using_gamepad else "P"]

func _unhandled_input(event: InputEvent) -> void:
 if encounter==null or encounter.result!="ACTIVE": return
 if event.is_action_released("combat_primary"):
  primary_held=false
  return
 var occupied := current_station()
 if occupied==stations[2]:
  if event.is_action_pressed("interact"):
   _leave_pilot()
   return
  if weapon_view!=WeaponView.FIRE_CONTROL:
   _weapon_context_input(event)
   return
  if event.is_action_pressed("tactical_map"):
   _set_weapon_view(WeaponView.MAP)
   return
 if occupied!=null and occupied!=station and not outside:
  var handled: bool = true
  if event.is_action_pressed("combat_primary"):
   if primary_held: return
   primary_held=true
   if occupied==stations[2]: encounter.fire_player()
   else: encounter.drone_command("defense")
  elif event.is_action_pressed("combat_up"):
   if occupied==stations[2]: encounter.player_launcher.selected_launcher=1-encounter.player_launcher.selected_launcher
   else: encounter.drone_command("deploy")
  elif event.is_action_pressed("combat_down"):
   if occupied==stations[2]: encounter.player_launcher.armed=not encounter.player_launcher.armed
   else: encounter.drone_command("waypoint")
  elif event.is_action_pressed("combat_hold"):
   if occupied==stations[1]: encounter.drone_command("hold")
   else:
    _set_weapon_view(WeaponView.MISSILE)
  elif event.is_action_pressed("combat_recall") and occupied==stations[1]: encounter.drone_command("recall")
  elif event.is_action_pressed("combat_automation") and not outside:
   if occupied==stations[2]: encounter.grant_role("weapons",not encounter.automatic_weapons)
   else: encounter.grant_role("drone",not encounter.automatic_drone)
  else: handled=false
  if handled:
   audio.cue("confirm")
   return
 var selected_before := sensors.selected_id
 super._unhandled_input(event)
 if selected_before!=sensors.selected_id:
  encounter.events.record(ship.tick,"target_change","DRIFT",{"contact_id":sensors.selected_id})

func _mission_ended(outcome: String) -> void:
 _return_fire_control()
 input_source.clear_mouse()
 controls_captured=false
 crew.controls_enabled=false
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 var rows := VBoxContainer.new()
 end_panel.add_child(rows)
 var title := Label.new()
 title.text={"VICTORY":"SIEG","DEFEAT":"NIEDERLAGE","DRAW":"UNENTSCHIEDEN","ABORTED":"ABGEBROCHEN"}.get(outcome,outcome)+" / %.1f s"%encounter.elapsed
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 title.add_theme_font_size_override("font_size",30)
 rows.add_child(title)
 var reason:=Label.new()
 reason.text=encounter.end_reason
 reason.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var restart := Button.new()
 restart.text="Kontakt Alpha neu starten"
 restart.pressed.connect(func() -> void: MissionSetup.launch.call_deferred(get_tree(),setup_mode,setup_difficulty,setup_seed,setup_weapon_grant,setup_drone_grant))
 rows.add_child(restart)
 var free := Button.new()
 free.text="Zum freien Flug"
 free.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main.tscn"))
 rows.add_child(free)
 rows.add_child(reason)
 end_panel.show()
 restart.grab_focus()

func _leave_pilot() -> void:
 _return_fire_control()
 observe_missile=false
 primary_held=Input.is_action_pressed("combat_primary")
 super._leave_pilot()

func _toggle_exterior() -> void:
 var was_outside:=outside and weapon_view==WeaponView.FIRE_CONTROL
 _return_fire_control()
 outside=was_outside
 observe_missile=false
 super._toggle_exterior()

func _pause_changed(paused: bool) -> void:
 var missile:=selected_missile()
 if missile!=null: missile.clear_operator_input()
 primary_held=Input.is_action_pressed("combat_primary")
 super._pause_changed(paused)

func selected_missile() -> MissileBody:
 if encounter==null: return null
 for missile in encounter.missiles:
  if is_instance_valid(missile) and not missile.spent and missile.team==0 and String(missile.name)==selected_missile_id: return missile
 return null

func cycle_missile(direction: int) -> void:
 var available: Array[MissileBody]=[]
 for missile in encounter.missiles:
  if is_instance_valid(missile) and not missile.spent and missile.team==0: available.append(missile)
 if available.is_empty():
  _return_fire_control()
  encounter.last_message="NO LIVE OWN MISSILE"
  return
 var old:=selected_missile()
 var index:=available.find(old)
 if old!=null: old.set_manual(false)
 selected_missile_id=String(available[posmod(index+direction,available.size())].name)
 input_source.reset_context()

func weapon_map() -> TacticalMap:
 for display in tactical_displays:
  if display.weapons: return (display as CombatDisplay).tactical_map
 return null

func _set_weapon_view(value: int) -> void:
 _return_fire_control()
 if value==WeaponView.MISSILE:
  cycle_missile(1)
  if selected_missile()==null: return
 weapon_view=value
 observe_missile=value==WeaponView.MISSILE
 outside=observe_missile
 for display in tactical_displays:
  if display.weapons: (display as CombatDisplay).presentation_mode=value
 input_source.reset_context()
 _update_view()

func _return_fire_control() -> void:
 var missile:=selected_missile()
 if missile!=null: missile.set_manual(false)
 weapon_view=WeaponView.FIRE_CONTROL
 observe_missile=false
 outside=false
 for display in tactical_displays:
  if display is CombatDisplay: display.presentation_mode=0
 input_source.reset_context()
 _update_view()

func _weapon_context_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel") or event.is_action_pressed("tactical_map"):
  _return_fire_control()
 elif event.is_action_pressed("exterior"):
  _toggle_exterior()
 elif weapon_view==WeaponView.MAP:
  var map:=weapon_map()
  if event.is_action_pressed("target_previous"): map.cycle(-1)
  elif event.is_action_pressed("target_next"): map.cycle(1)
  elif event.is_action_pressed("sensor_track"): map.focus_selected()
  elif event.is_action_pressed("combat_automation"):
   map.follow_selected=false
   map.focus=Vector3.ZERO
   map.yaw=0.6
   map.pitch=0.45
   map.distance=22
   map.update_camera()
  elif event.is_action_pressed("zoom_in"): map.zoom(-0.15)
  elif event.is_action_pressed("zoom_out"): map.zoom(0.15)
  elif event is InputEventMouseMotion: map.orbit(event.relative*0.002,1)
 elif weapon_view==WeaponView.MISSILE:
  var missile:=selected_missile()
  if missile==null:
   _return_fire_control()
  elif event.is_action_pressed("target_previous"): cycle_missile(-1)
  elif event.is_action_pressed("target_next"): cycle_missile(1)
  elif event.is_action_pressed("missile_manual"):
   missile.set_manual(not missile.manual_mode)
   input_source.reset_context()
  elif event.is_action_pressed("combat_hold") and not missile.manual_mode: _return_fire_control()
  elif event is InputEventMouseMotion and missile.manual_mode: input_source.add_flight_mouse(event.relative)

func _orbit_controls_active() -> bool:
 return false if weapon_view==WeaponView.MISSILE else super._orbit_controls_active()

func _active_device_changed(gamepad: bool) -> void:
 var missile:=selected_missile()
 if missile!=null: missile.clear_operator_input()
 super._active_device_changed(gamepad)
