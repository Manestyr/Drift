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
 encounter.ended.connect(_mission_ended)
 var canvas := CanvasLayer.new()
 canvas.layer=3
 add_child(canvas)
 mission_status=Label.new()
 mission_status.position=Vector2(24,12)
 mission_status.add_theme_font_size_override("font_size",19)
 canvas.add_child(mission_status)
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
 if encounter.result!="ACTIVE":
  ship.command.clear()
  crew.controls_enabled=false
  controls_captured=false

func _process(dt: float) -> void:
 super._process(dt)
 if encounter==null: return
 if observe_missile:
  for missile in encounter.missiles:
   if is_instance_valid(missile) and missile.team==0:
    outside_camera.global_position=missile.global_position+Vector3(12,7,18)
    outside_camera.look_at(missile.global_position+missile.linear_velocity.normalized()*12,Vector3.UP)
    break
 mission_status.text="ALPHA | %s | %s | %.0f s | seed %d | P/Options: mission setup"%[CombatProfile.MODE_NAMES[encounter.control_mode],CombatProfile.DIFFICULTY_NAMES[encounter.difficulty],encounter.elapsed,setup_seed]

func _unhandled_input(event: InputEvent) -> void:
 if encounter==null or encounter.result!="ACTIVE": return
 if event.is_action_released("combat_primary"):
  primary_held=false
  return
 var occupied := current_station()
 if occupied!=null and occupied!=station:
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
    observe_missile=not observe_missile
    outside=observe_missile
    _update_view()
  elif event.is_action_pressed("combat_recall") and occupied==stations[1]: encounter.drone_command("recall")
  elif event.is_action_pressed("combat_automation") and not outside:
   if occupied==stations[2]: encounter.grant_role("weapons",not encounter.automatic_weapons)
   else: encounter.grant_role("drone",not encounter.automatic_drone)
  else: handled=false
  if handled: return
 var selected_before := sensors.selected_id
 super._unhandled_input(event)
 if selected_before!=sensors.selected_id:
  encounter.events.record(ship.tick,"target_change","DRIFT",{"contact_id":sensors.selected_id})

func _mission_ended(outcome: String) -> void:
 input_source.clear_mouse()
 controls_captured=false
 crew.controls_enabled=false
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 var rows := VBoxContainer.new()
 end_panel.add_child(rows)
 var title := Label.new()
 title.text=("SIEG" if outcome=="VICTORY" else "NIEDERLAGE")+" / %.1f s"%encounter.elapsed
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 title.add_theme_font_size_override("font_size",30)
 rows.add_child(title)
 var restart := Button.new()
 restart.text="Kontakt Alpha neu starten"
 restart.pressed.connect(func() -> void: MissionSetup.launch.call_deferred(get_tree(),setup_mode,setup_difficulty,setup_seed,setup_weapon_grant,setup_drone_grant))
 rows.add_child(restart)
 var free := Button.new()
 free.text="Zum freien Flug"
 free.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main.tscn"))
 rows.add_child(free)
 end_panel.show()
 restart.grab_focus()

func _leave_pilot() -> void:
 observe_missile=false
 primary_held=Input.is_action_pressed("combat_primary")
 super._leave_pilot()

func _toggle_exterior() -> void:
 observe_missile=false
 super._toggle_exterior()

func _pause_changed(paused: bool) -> void:
 primary_held=Input.is_action_pressed("combat_primary")
 super._pause_changed(paused)
