extends SceneTree

var checks: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
 checks+=1
 if value: print("PASS: ",message)
 else:
  failures+=1
  push_error("FAIL: "+message)
func ticks(n: int) -> void:
 for i in n:
  await physics_frame
  await process_frame
func axis(index: int, value: float, device: int = 0) -> void:
 var e:=InputEventJoypadMotion.new()
 e.axis=index
 e.axis_value=value
 e.device=device
 Input.parse_input_event(e)
func button(index: int, pressed: bool = true) -> void:
 var e:=InputEventJoypadButton.new()
 e.button_index=index
 e.pressed=pressed
 Input.parse_input_event(e)
func press(index: int) -> void:
 button(index)
 await process_frame
 button(index,false)
 await process_frame
func action(game: Node, name: String) -> void:
 var event:=InputEventAction.new()
 event.action=name
 event.pressed=true
 game._unhandled_input(event)
 event.pressed=false
 game._unhandled_input(event)
func neutral() -> void:
 for index in range(6): axis(index,0)
 for index in range(JOY_BUTTON_MAX): button(index,false)
func mission(seed_value: int = 71) -> Node:
 var game=load("res://scenes/contact_alpha.tscn").instantiate()
 game.setup_seed=seed_value
 game.setup_difficulty=CombatProfile.Difficulty.HARD
 root.add_child(game)
 game.pause_menu.save_settings_on_close=false
 game.input_source.settings.symbol_scheme=1
 return game
func run() -> void:
 root.size=Vector2i(1280,720)
 Input.use_accumulated_input=false
 var game=mission()
 var source: PlayerInput=game.input_source
 source.settings.computer_layout=0
 source.settings.brake_mode=0
 source.settings.drift_button=JOY_BUTTON_X
 source.settings.drift_modifier=-1
 source.settings.retrograde_button=JOY_BUTTON_BACK
 source.settings.apply_advanced_bindings()
 await ticks(5)
 var friendly:=SensorContact.new()
 friendly.team=0
 friendly.quality=1
 friendly.tracking=true
 friendly.velocity_known=true
 var gate:=MissileLauncher.new()
 gate.owner_team=0
 gate.armed=true
 check(not gate.authorize(friendly,null) and gate.last_status.contains("FRIENDLY IFF"),"friendly target shows actual BLOCKED reason before firing")
 check(ControllerLabels.detect("Sony DualSense Wireless Controller")==1,"DualSense name selects PlayStation")
 check(ControllerLabels.detect("PS4 Controller")==1,"PS4 name selects PlayStation")
 check(ControllerLabels.detect("Xbox Wireless Controller")==2,"Xbox name selects Xbox")
 source.using_gamepad=true
 check(source.button_label(JOY_BUTTON_A)=="✕" and source.button_label(JOY_BUTTON_X)=="Quadrat","PS face labels match actual logical Input Map buttons")
 check(source.button_label(JOY_BUTTON_RIGHT_SHOULDER)=="R1" and source.button_label(JOY_BUTTON_START)=="Options","PS shoulder/menu labels match actions")
 game.pause_menu._refresh_binding_labels()
 var bindings: Dictionary=game.pause_menu.binding_choices[0]
 check(bindings.choice.get_item_text(bindings.indices.find(JOY_BUTTON_A))=="✕","advanced remapping choices refresh to PS after device detection")
 check(not source.hints(true).contains("Xbox") and not source.hints(true).contains("RT/"),"PS flight hints contain no Xbox aliases")
 source.settings.symbol_scheme=2
 check(source.button_label(JOY_BUTTON_A)=="A" and source.hints(true).contains("RT:"),"manual Xbox schema updates hints")
 game.pause_menu._refresh_binding_labels()
 check(bindings.choice.get_item_text(bindings.indices.find(JOY_BUTTON_RIGHT_SHOULDER))=="RB","advanced remapping choices update when scheme changes to Xbox")
 source.settings.symbol_scheme=0
 source.controller_name="Sony DualSense"
 check(source.symbol_scheme()==1,"automatic scheme uses active device name")
 source.settings.symbol_scheme=1
 game.crew.position=game.station.position+Vector3(0,0,0.8)
 await press(JOY_BUTTON_A)
 check(game.station.occupied,"PS Cross enters pilot seat")
 axis(JOY_AXIS_TRIGGER_RIGHT,1)
 await ticks(10)
 check(is_equal_approx(game.ship.command.main_engine,1) and is_equal_approx(game.ship.applied_main_thrust_n,2400000),"full R2 requests and applies rated healthy main thrust")
 check(game.ship.acceleration_local.is_equal_approx(Vector3(0,0,-20)),"healthy ship full R2 gives 20 m/s² with no hidden reverse force")
 button(JOY_BUTTON_DPAD_DOWN)
 await ticks(3)
 check(game.ship.computer.active_brake_axes.z==0,"manual main engine has priority over full brake on Z")
 axis(JOY_AXIS_TRIGGER_RIGHT,0)
 await ticks(3)
 check(game.ship.computer.automatic_force_local.length()>0,"held explicit brake produces actual RCS counterforce")
 button(JOY_BUTTON_DPAD_DOWN,false)
 await ticks(3)
 check(game.ship.computer.automatic_force_local==Vector3.ZERO and game.ship.acceleration_local==Vector3.ZERO,"released brake produces no further counterforce")
 var coast: Vector3=game.ship.linear_velocity
 await ticks(60)
 check(game.ship.linear_velocity.distance_to(coast)<0.001,"released inputs preserve Newtonian coast")
 # A held tactical brake/arm button is blocked until released after re-entering pilot.
 button(JOY_BUTTON_DPAD_DOWN)
 game._leave_pilot()
 game.crew.position=game.station.position+Vector3(0,0,0.8)
 action(game,"interact")
 await ticks(3)
 check(not game.ship.command.brake_all,"station handover cannot inherit a held D-pad brake")
 button(JOY_BUTTON_DPAD_DOWN,false)
 await ticks(3)
 button(JOY_BUTTON_DPAD_DOWN)
 await ticks(3)
 check(game.ship.command.brake_all,"released then newly pressed brake works after station handover")
 button(JOY_BUTTON_DPAD_DOWN,false)
 await ticks(3)
 # Damage fixture uses the same authoritative zone/hit path, no force or velocity edits.
 game.ship.damage_model.hit(Vector3(0,0,12))
 axis(JOY_AXIS_TRIGGER_RIGHT,1)
 await ticks(3)
 var telemetry:=ShipTelemetry.capture(game.ship)
 check(is_equal_approx(telemetry.engine_health,0.49) and is_equal_approx(game.ship.acceleration_local.z,-9.8),"single engine-zone hit explains half main acceleration without counterthrust")
 check(telemetry.brake_force_local==Vector3.ZERO and telemetry.main_force_n==1176000,"telemetry distinguishes damage from brake RCS")
 print("MEASURE engine-hit: health=",telemetry.engine_health," main N=",telemetry.main_force_n," auto N=",telemetry.brake_force_local," accel=",telemetry.acceleration_local)
 # Restore only damage configuration to isolate input regression; never body motion.
 game.ship.damage_model.health.main=100.0
 axis(JOY_AXIS_TRIGGER_LEFT,1)
 await ticks(3)
 telemetry=ShipTelemetry.capture(game.ship)
 check(telemetry.reverse_force_n==1440000 and is_equal_approx(telemetry.acceleration_local.z,-8),"deliberately held L2+R2 is explicit manual reverse, not automatic brake")
 axis(JOY_AXIS_TRIGGER_LEFT,0)
 await ticks(3)
 check(game.ship.computer.manual_force_local.z==0 and is_equal_approx(game.ship.acceleration_local.z,-20),"released L2 restores full main acceleration next fixed tick")
 # Pause with controls held: Resume must require neutral then a new press.
 button(JOY_BUTTON_DPAD_DOWN)
 await press(JOY_BUTTON_START)
 check(paused,"Options pauses mission")
 var tick_before: int=game.ship.tick
 for i in 5: await process_frame
 check(game.ship.tick==tick_before and not game.audio.can_process(),"pause stops physics and audio owner")
 await press(JOY_BUTTON_START)
 await ticks(3)
 check(game.ship.command.main_engine==0 and not game.ship.command.brake_all,"pause/resume quarantines held trigger and brake")
 neutral()
 await ticks(3)
 axis(JOY_AXIS_TRIGGER_RIGHT,1)
 await ticks(3)
 check(game.ship.command.main_engine==1,"neutral then fresh R2 rearms propulsion")
 # Device replacement clears the previous pad's held L2, keeps new input.
 axis(JOY_AXIS_TRIGGER_LEFT,1)
 axis(JOY_AXIS_TRIGGER_RIGHT,1,1)
 await ticks(3)
 check(game.ship.command.translation.z==0 and game.ship.command.main_engine==1,"switching controllers cannot inherit old reverse trigger")
 source._connection_changed(1,false)
 source.sample_flight(game.ship.command)
 check(game.ship.command.translation==Vector3.ZERO and game.ship.command.main_engine==0,"disconnect clears owned joypad commands")
 neutral()
 game.queue_free()
 await process_frame
 # Dedicated long encounter: same HARD seed/guard schedule as the existing
 # 113-second balance case, but every weapon command comes through controller input.
 game=mission(1741)
 # This is an input/ammunition soak rig, not a drone balance assertion. Keep
 # both propulsion systems at rated efficiency through real impacts so the
 # 0.3.3 defense limits cannot terminate the rig before all 16 launches.
 for body: ShipPhysics in [game.ship,game.encounter.enemy]:
  for system: String in body.damage_model.health: body.damage_model.health[system]=1000.0
 source=game.input_source
 await ticks(120)
 game.crew.position=game.stations[1].position+Vector3(0,0,0.8)
 await press(JOY_BUTTON_A)
 await press(JOY_BUTTON_DPAD_UP)
 await press(JOY_BUTTON_RIGHT_SHOULDER)
 game._leave_pilot()
 game.crew.position=game.stations[2].position+Vector3(0,0,0.8)
 await press(JOY_BUTTON_A)
 await press(JOY_BUTTON_DPAD_DOWN)
 check(game.encounter.player_launcher.armed and not game.ship.command.brake_all,"weapon D-pad Down arms only, never starts pilot brake")
 await press(JOY_BUTTON_X)
 await ticks(150)
 check(game.sensors.selected()!=null and game.sensors.selected().tracking,"Square starts tactical tracking")
 # Spend both racks with genuine separate launch orders and reload intervals.
 var attempts:=0
 var next_shot:=12.0
 while game.encounter.player_launcher.shots<8 and game.encounter.result=="ACTIVE" and attempts<300:
  var launcher: MissileLauncher=game.encounter.player_launcher
  if game.encounter.elapsed>=next_shot:
   if launcher.ammunition[launcher.selected_launcher]<=0: await press(JOY_BUTTON_DPAD_UP)
   var old_shots:=launcher.shots
   await press(JOY_BUTTON_RIGHT_SHOULDER)
   if launcher.shots>old_shots: next_shot=game.encounter.elapsed+14.0
  attempts+=1
  await ticks(30)
 check(game.encounter.player_launcher.shots==8,"long live mission consumes all eight friendly missiles through controller orders")
 check(game.ship.computer.automatic_force_local==Vector3.ZERO,"exhausted racks and weapon station do not latch braking")
 game._leave_pilot()
 game.crew.position=game.station.position+Vector3(0,0,0.8)
 await press(JOY_BUTTON_A)
 neutral()
 await ticks(3)
 axis(JOY_AXIS_TRIGGER_RIGHT,1)
 await ticks(3)
 check(game.ship.command.main_engine==1 and game.ship.computer.automatic_force_local==Vector3.ZERO,"return to pilot after missile expenditure has no unexplained counterforce")
 print("MEASURE live combat: seconds=",game.encounter.elapsed," stores=",game.encounter.player_launcher.ammunition," enemy=",game.encounter.enemy_launcher.ammunition," health=",game.ship.damage_model.health," auto=",game.ship.computer.automatic_force_local)
 neutral()
 # Fresh short fixture isolates console commands from lethal combat outcomes.
 neutral()
 game.queue_free()
 await process_frame
 game=mission()
 source=game.input_source
 await ticks(2)
 # Console controls remain independent of flight even with remapped pilot actions.
 game._leave_pilot()
 game.crew.position=game.stations[1].position+Vector3(0,0,0.8)
 await press(JOY_BUTTON_A)
 await press(JOY_BUTTON_DPAD_UP)
 check(is_instance_valid(game.encounter.drone),"PS D-pad Up deploys from drone context")
 await press(JOY_BUTTON_RIGHT_SHOULDER)
 check(game.encounter.drone.command_mode=="DEFEND","PS R1 commands DEFEND without pilot roll")
 await press(JOY_BUTTON_LEFT_SHOULDER)
 check(game.encounter.drone.command_mode=="HOLD","PS L1 commands inertial HOLD")
 await press(JOY_BUTTON_BACK)
 check(game.encounter.drone.command_mode=="RECALL","PS Share/Create commands RECALL, never retrograde")
 check(not game.ship.computer.retrograde_active and game.ship.command.rotation==Vector3.ZERO,"tactical buttons do not leak into pilot computer or rotation")
 var console: CombatDisplay=game.tactical_displays[1]
 check(console.key("R",JOY_BUTTON_RIGHT_SHOULDER)=="R1" and console.key("F",JOY_BUTTON_A)=="✕","console hints use actual PS action indices")
 # Audio assets/ownership and bus independence.
 check(game.audio.clips.size()==12 and game.audio.structural.size()==6 and game.audio.alerts.size()==4,"bounded scene-owned sound pool and all 12 clips exist")
 check(game.audio.engine.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"engine loop is explicitly enabled")
 game.audio.set_level("Ship",0)
 game.audio.set_level("Warnings",0.3)
 check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Ship")) and not AudioServer.is_bus_mute(AudioServer.get_bus_index("Warnings")),"Ship mute does not mute warnings")
 check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Warnings"))),0.3),"independent warning gain is applied")
 game.audio.exterior=true
 var before: int=int(game.audio.played.get("impact",0))
 game.audio.cue("impact","Ship")
 check(int(game.audio.played.get("impact",0))==before,"vacuum exterior does not emit structure impact sounds")
 game.audio.exterior=false
 game.audio.cue("impact","Ship",Vector3(2,0,10))
 check(int(game.audio.played.get("impact",0))==before+1,"interior impact uses local structural emitter")
 game.pause_menu.set_paused(true)
 before=int(game.audio.played.get("alarm",0))
 game.audio.cue("alarm","Warnings")
 check(int(game.audio.played.get("alarm",0))==before,"paused mission suppresses new warning cues")
 game.pause_menu.set_paused(false)
 var settings_path: String="user://test_audio_ps.cfg"
 source.settings.save_file(settings_path)
 var loaded:=InputSettings.new()
 loaded.load_file(settings_path)
 check(loaded.symbol_scheme==1 and loaded.audio_levels.Ship==0 and is_equal_approx(loaded.audio_levels.Warnings,0.3),"symbol scheme and independent gains persist")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))
 var bus_count:=AudioServer.bus_count
 game.queue_free()
 await process_frame
 for i in 3:
  game=mission()
  await ticks(2)
  check(game.interior.find_children("ShipAudio","",false,false).size()==1 and AudioServer.bus_count==bus_count,"restart owns one audio system and reuses buses: %d"%i)
  game.queue_free()
  await process_frame
 # Isolated mission-rule fixtures: stores and missile lifecycles, not simulated hits.
 game=mission()
 var encounter: CombatEncounter=game.encounter
 encounter.player_launcher.ammunition=[0,0]
 encounter.enemy_launcher.ammunition=[0,0]
 var missile:=MissileBody.new()
 missile.team=0
 missile.position=Vector3(500,500,500)
 encounter.add_child(missile)
 encounter._register_missile(missile)
 await ticks(360)
 check(encounter.result=="ACTIVE" and encounter.exhaustion_seconds==0,"empty racks never end mission while a physical missile is still live")
 await ticks(2760)
 check(encounter.result=="ACTIVE" and game.ship.computer.automatic_force_local==Vector3.ZERO,"52-second exhausted-store coast has no hidden braking or premature result")
 await ticks(190)
 await ticks(180)
 check(encounter.result=="ACTIVE","ceasefire grace period avoids instantaneous empty-rack result")
 await ticks(140)
 check(encounter.result=="DRAW" and encounter.end_reason.contains("all missiles resolved"),"exhausted offensive capability resolves to documented draw")
 check(game.end_panel.visible,"draw offers focused restart and free flight")
 game.queue_free()
 await process_frame
 game=mission()
 game.encounter.player_launcher.ammunition.assign([0,0])
 await ticks(360)
 check(game.encounter.result=="ACTIVE","one empty ship cannot end combat while opponent has launch capability")
 game.pause_menu.set_paused(true)
 game.pause_menu.disengage_button.emit_signal("pressed")
 check(not paused and game.encounter.result=="ABORTED" and game.end_panel.visible,"explicit controller-focusable pause Disengage ends without awarding kill")
 game.queue_free()
 await process_frame
 print("Flight/PS/sound checks=",checks," failures=",failures)
 quit(1 if failures else 0)
