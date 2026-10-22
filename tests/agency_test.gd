extends SceneTree

var failures: int=0
var checks: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
 checks+=1
 if ok: print("PASS: ",message)
 else:
  failures+=1
  push_error("FAIL: "+message)
func ticks(count: int) -> void:
 for i in count: await physics_frame
 await process_frame
func action(game: Node, name: String, pressed: bool = true) -> void:
 var event:=InputEventAction.new()
 event.action=name
 event.pressed=pressed
 game._unhandled_input(event)
func pad(game: Node, button: JoyButton, pressed: bool = true) -> void:
 var event:=InputEventJoypadButton.new()
 event.button_index=button
 event.pressed=pressed
 game._unhandled_input(event)
func mission(mode: int = CombatProfile.Mode.MANUAL) -> Node:
 var game=load("res://scenes/contact_alpha.tscn").instantiate()
 game.setup_mode=mode
 game.setup_difficulty=CombatProfile.Difficulty.EASY
 game.setup_seed=1741
 root.add_child(game)
 game.pause_menu.save_settings_on_close=false
 return game
func run() -> void:
 root.size=Vector2i(1280,720)
 var sensor:=SensorSuite.new()
 sensor.estimate_acceleration=true
 sensor.cadence_seconds=0.05
 sensor.measurement_resolution_m=0.001
 var target:=Node3D.new()
 target.name="ACCEL-FIXTURE"
 root.add_child(target)
 var targets: Array[Node3D]=[target]
 for i in range(6):
  var time:=float(i)*0.05
  target.position=Vector3(0,0,-500+60*time*time) # analytic observation fixture only
  sensor.sample(targets,Transform3D.IDENTITY,Vector3.ZERO,i*3,0.05)
 check(absf(sensor.selected().observed_acceleration_world.z-120)<0.2,"defense acceleration estimate comes from timed observed positions")
 target.queue_free()
 await process_frame
 var game=mission()
 check(game.encounter.control_mode==CombatProfile.Mode.MANUAL,"direct mission default is MANUAL")
 check(not game.encounter.automatic_weapons and not game.encounter.automatic_drone,"no role consent in manual default")
 game.encounter.automatic_weapons=true
 game.encounter.automatic_drone=true
 await ticks(1800)
 check(game.encounter.player_launcher.shots==0,"MANUAL prevents automatic friendly fire even with stale role flags")
 check(not is_instance_valid(game.encounter.drone) and game.encounter.drone_available,"MANUAL never deploys drone without an order")
 check(game.encounter.enemy.damage_model.health.hull==100,"idle MANUAL cannot silently kill ALPHA")
 check(game.encounter.enemy_launcher.shots>0,"enemy remains a genuine threat to idle player")
 game.queue_free()
 await process_frame
 game=mission(CombatProfile.Mode.FULL_AUTO)
 await ticks(650)
 game.crew.position=game.stations[2].position+Vector3(0,0,0.8)
 action(game,"interact")
 var before: int=game.encounter.player_launcher.shots
 await ticks(1000)
 check(game.stations[2].occupied and game.encounter.player_launcher.shots==before,"taking weapon station immediately cancels autonomous launch authority")
 check(game.encounter.fire_player(true)==null,"authority boundary rejects even explicit stale automatic launch")
 check(game.encounter.control_label(true).ends_with("PLAYER"),"console reports actual player authority")
 game.queue_free()
 await process_frame
 game=mission()
 await ticks(65)
 game.crew.position=game.stations[2].position+Vector3(0,0,0.8)
 action(game,"interact")
 action(game,"sensor_track")
 action(game,"combat_down")
 action(game,"combat_primary")
 action(game,"combat_primary",false)
 check(game.encounter.player_launcher.shots==0 and game.encounter.player_launcher.last_status.contains("LOCK"),"arm and track do not bypass solution-building gate")
 await ticks(150)
 var contact: SensorContact=game.sensors.selected()
 check(contact.tracking and contact.solution_progress>=1 and contact.lock_quality>=0.7,"continuous tracking builds usable lock quality from observations")
 var refined_quality:=contact.quality
 check(refined_quality>0.75,"tracking measurably improves estimated contact quality")
 pad(game,JOY_BUTTON_RIGHT_SHOULDER)
 check(game.encounter.player_launcher.shots==1,"one controller press launches exactly one missile")
 check(game.encounter.events.entries.any(func(e: Dictionary) -> bool: return e.type=="launch" and e.payload.authority=="PLAYER"),"launch events identify actual player versus role-AI authority")
 await ticks(380)
 pad(game,JOY_BUTTON_RIGHT_SHOULDER) # duplicate held press, cooldown already elapsed
 check(game.encounter.player_launcher.shots==1,"held/repeated press cannot fire after reload")
 pad(game,JOY_BUTTON_RIGHT_SHOULDER,false)
 pad(game,JOY_BUTTON_RIGHT_SHOULDER)
 check(game.encounter.player_launcher.shots==2,"release and deliberate next press authorize one further missile")
 pad(game,JOY_BUTTON_RIGHT_SHOULDER,false)
 var rack: int=game.encounter.player_launcher.selected_launcher
 pad(game,JOY_BUTTON_DPAD_UP)
 check(game.encounter.player_launcher.selected_launcher!=rack and game.encounter.player_launcher.cooldown==0,"other rack has independent reload state")
 pad(game,JOY_BUTTON_RIGHT_SHOULDER)
 check(game.encounter.player_launcher.shots==3,"rack choice enables a deliberate separately commanded second launch")
 pad(game,JOY_BUTTON_RIGHT_SHOULDER,false)
 action(game,"sensor_track")
 check(game.sensors.selected().solution_progress==0,"releasing track immediately invalidates lock solution")
 game.encounter.grant_role("weapons",true)
 check(not game.encounter.can_automate("weapons"),"MANUAL role-toggle request cannot grant tactical automation")
 check(game.encounter.last_message.contains("MANUAL"),"refused role consent has clear reason")
 game.queue_free()
 await process_frame
 game=mission(CombatProfile.Mode.ASSISTED_SOLO)
 await ticks(180)
 check(not game.encounter.can_automate("weapons") and game.encounter.drone_available,"ASSISTED starts without implicit role grants or deployment")
 game.encounter.grant_role("weapons",true)
 check(game.encounter.can_automate("weapons"),"ASSISTED weapon role requires explicit grant")
 game.encounter.grant_role("drone",true)
 await ticks(180)
 check(not is_instance_valid(game.encounter.drone),"ASSISTED drone role never launches craft on its own")
 game.encounter.enemy_launcher.armed=false # isolate motion/commands from weapon impacts
 check(game.encounter.deploy_drone(),"operator can deliberately deploy drone")
 var drone: DefenseDrone=game.encounter.drone
 check(drone.command_mode=="ESCORT" and not drone.defense_enabled,"manual launch starts ESCORT, not an undeclared defense order")
 var position_before:=drone.global_position
 await ticks(360)
 check(drone.global_position.distance_to(position_before)>50 and drone.fuel_delta_v<650,"ESCORT moves with bounded physical thrust and spends fuel")
 drone.defense_enabled=true
 check(drone.command_mode=="DEFEND","explicit defense order changes drone command mode")
 var threat:=SensorContact.new()
 threat.kind="missile"
 threat.team=1
 threat.quality=1
 threat.velocity_known=true
 threat.observed_position_world=Vector3(0,0,-200)
 threat.observed_velocity_world=Vector3(0,0,300)
 check(drone.can_engage(threat),"guard-position drone can defend carrier from observed inbound missile")
 threat.observed_velocity_world=Vector3(0,0,-300)
 check(not drone.can_engage(threat),"DEFEND avoids spending ammunition on outbound harmless tracks")
 drone.assign_waypoint(Vector3(0,-30,900))
 check(not drone.defense_enabled and drone.command_mode=="ESCORT","new escort waypoint cannot silently re-enable defense")
 await ticks(1200)
 drone.defense_enabled=true
 threat.observed_velocity_world=Vector3(0,0,300)
 check(not drone.can_engage(threat),"bad rear waypoint physically places same threat outside real gun range")
 check(drone.global_position.z>700,"rear waypoint is reached by actual movement, not just UI state")
 drone.hold_position()
 check(drone.command_mode=="HOLD" and not drone.defense_enabled,"HOLD captures inertial position and stops defensive engagement")
 drone.recall()
 check(drone.command_mode=="RECALL" and drone.recalling,"RECALL explicitly commands physical return")
 game.queue_free()
 await process_frame
 for difficulty in range(3):
  var profile:=CombatProfile.settings(difficulty)
  check(profile.reaction>0 and profile.rounds>0,"finite reaction and defense stores: "+CombatProfile.DIFFICULTY_NAMES[difficulty])
 check(CombatProfile.settings(0).reaction>CombatProfile.settings(2).reaction,"difficulty changes reactions without health multipliers")
 var passive:=await BalanceScenario.battle(self,CombatProfile.Mode.MANUAL,CombatProfile.Difficulty.NORMAL,71)
 var guard:=await BalanceScenario.battle(self,CombatProfile.Mode.MANUAL,CombatProfile.Difficulty.NORMAL,71,"guard")
 var bad:=await BalanceScenario.battle(self,CombatProfile.Mode.MANUAL,CombatProfile.Difficulty.NORMAL,71,"bad-position")
 var lateral:=await BalanceScenario.battle(self,CombatProfile.Mode.MANUAL,CombatProfile.Difficulty.NORMAL,71,"lateral")
 check(passive.blue_launches==0 and passive.result=="DEFEAT" and passive.enemy_hull==100,"no orders loses while ALPHA remains intact")
 check(guard.blue_launches>0 and guard.blue_hits>0,"deliberate weapon orders make actual successful hits")
 check(guard.result=="VICTORY","timely explicit player decisions can win")
 check(guard.blue_pd>bad.blue_pd,"well-placed DEFEND drone provides measurably more physical protection")
 check(guard.player_hull>bad.player_hull or guard.result!=bad.result,"poor positioning changes damage or result")
 check(lateral.red_hits<passive.red_hits and lateral.blue_pd==0,"physical pilot maneuver changes actual missile hit count")
 var repeat:=await BalanceScenario.battle(self,CombatProfile.Mode.MANUAL,CombatProfile.Difficulty.NORMAL,71,"guard")
 check(guard==repeat,"fixed seed and command schedule reproduce complete scenario result")
 var setup=load("res://scenes/mission_setup.tscn").instantiate()
 root.add_child(setup)
 check(setup.mode.selected==CombatProfile.Mode.MANUAL and setup.difficulty.selected==CombatProfile.Difficulty.NORMAL,"mission menu defaults MANUAL / NORMAL")
 setup.mode.select(CombatProfile.Mode.ASSISTED_SOLO)
 setup._mode_changed(CombatProfile.Mode.ASSISTED_SOLO)
 check(setup.weapons.visible and setup.drone.visible and not setup.weapons.button_pressed,"ASSISTED consent controls are explicit and default off")
 current_scene=setup
 MissionSetup.launch.call_deferred(self,CombatProfile.Mode.ASSISTED_SOLO,CombatProfile.Difficulty.HARD,71,true,false)
 await scene_changed
 game=current_scene
 check(game.encounter.control_mode==CombatProfile.Mode.ASSISTED_SOLO and game.encounter.difficulty==CombatProfile.Difficulty.HARD and game.setup_seed==71,"mission-menu launch passes explicit mode, difficulty and seed")
 check(game.encounter.automatic_weapons and not game.encounter.automatic_drone,"mission menu passes only explicitly granted roles")
 game.encounter.player_launcher.armed=true
 game.encounter.set_mode(CombatProfile.Mode.MANUAL)
 check(not game.encounter.player_launcher.armed and not game.encounter.automatic_weapons and game.encounter.fire_player(true)==null,"mode change revokes old authority and disarms weapons")
 game.queue_free()
 await process_frame
 print("Agency checks=",checks," failures=",failures)
 quit(1 if failures else 0)
