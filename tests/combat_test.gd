extends SceneTree

var failures: int = 0
var checks: int = 0
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
func event(game: Node, name: String) -> void:
 var input := InputEventAction.new()
 input.action=name
 input.pressed=true
 game._unhandled_input(input)
func pad(game: Node, button: JoyButton) -> void:
 var input := InputEventJoypadButton.new()
 input.button_index=button
 input.pressed=true
 game._unhandled_input(input)
func fixture_contact(id: String, position: Vector3) -> SensorContact:
 var contact := SensorContact.new()
 contact.contact_id=id
 contact.relative_position=position
 contact.observed_position_world=position
 contact.quality=1
 contact.tracking=true
 contact.velocity_known=true
 contact.kind="ship"
 return contact
func run() -> void:
 root.size=Vector2i(1280,720)
 var log := CombatEvents.new()
 log.record(4,"launch","A",{"v":Vector3.ONE})
 log.record(4,"target_change","A")
 check(log.entries[1].sequence==2 and log.entries[0].tick==4,"combat events retain tick, monotonic sequence and structured payload")
 var damage := ComponentDamage.new()
 check(damage.zone(Vector3(0,0,12))=="main" and damage.zone(Vector3(0,0,-12))=="weapons","fore/aft hit zones map weapons and main")
 check(damage.zone(Vector3(3,0,0))=="rcs" and damage.zone(Vector3(0,2,0))=="sensors","side/dorsal zones map maneuver and sensors")
 damage.hit(Vector3(0,0,12))
 check(damage.efficiency("main")<0.5 and damage.health.hull==66,"one hit damages actual component and hull")
 damage.damage("weapons",100)
 check(damage.incapable() and damage.health.hull>0,"weapon disable can incapacitate intact hull")
 var body := ShipPhysics.new()
 body.name="CARRIER"
 root.add_child(body)
 var hull := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size=Vector3(7,5,36)
 hull.shape=shape
 body.add_child(hull)
 body.linear_velocity=Vector3(25,3,-4) # explicit launch-fixture state only
 body.angular_velocity=Vector3(0,0.1,0)
 var world := Node3D.new()
 root.add_child(world)
 var target := ShipPhysics.new()
 target.name="TARGET"
 target.position=Vector3(0,0,-800)
 root.add_child(target)
 var target_shape := CollisionShape3D.new()
 var target_box := BoxShape3D.new()
 target_box.size=Vector3(7,5,36)
 target_shape.shape=target_box
 target.add_child(target_shape)
 await ticks(2)
 var contact := fixture_contact("TARGET",target.position)
 var launcher := MissileLauncher.new()
 check(not launcher.authorize(contact,null),"safe launcher rejects launch")
 launcher.armed=true
 contact.quality=0.3
 check(not launcher.authorize(contact,null),"weak observation blocks weapons")
 contact.quality=1
 contact.age_seconds=2
 check(not launcher.authorize(contact,null),"stale observation blocks weapons")
 contact.age_seconds=0
 contact.velocity_known=false
 check(not launcher.authorize(contact,null),"unknown velocity blocks weapons")
 contact.velocity_known=true
 contact.tracking=false
 check(not launcher.authorize(contact,null),"untracked target blocks weapons")
 contact.tracking=true
 contact.kind="missile"
 check(not launcher.authorize(contact,null),"launcher cannot accidentally engage missile track")
 contact.kind="ship"
 var targets: Array[Node3D] = [target]
 var offset := body.global_basis*Vector3(-5.5,0,-14)
 var inherited := body.linear_velocity+body.angular_velocity.cross(offset)+body.global_basis*Vector3(-12,0,-25)
 contact.team=0
 check(launcher.launch(body,contact,0,world,targets)==null,"friendly IFF prevents unintended launch")
 contact.team=-1
 var missile := launcher.launch(body,contact,0,world,targets)
 await ticks(2)
 var impact_seen: Array[bool]=[false]
 missile.impact.connect(func(_m: MissileBody, _b: Node3D, _point: Vector3) -> void: impact_seen[0]=true)
 check(missile!=null and missile.initial_solver_velocity.distance_to(inherited)<0.001,"launch inherits carrier linear and omega-cross-offset velocity plus rack impulse")
 check(launcher.ammunition[0]==3 and launcher.cooldown==6,"launch consumes finite ammo and starts cooldown")
 check(not launcher.authorize(contact,null),"cooldown prevents repeat launch")
 var previous_v := missile.linear_velocity
 var previous_fuel := missile.fuel_delta_v
 await ticks(12)
 check(missile.linear_velocity.distance_to(previous_v)>5,"missile actually accelerates under thrust")
 check(missile.fuel_delta_v<previous_fuel and missile.fuel_delta_v>=0,"missile acceleration consumes finite delta-v")
 check(missile.applied_force.length()<=missile.thrust_n+0.1,"missile total thrust bounded")
 var forward := -missile.global_basis.z
 var side := missile.applied_force/missile.mass-forward*(missile.applied_force/missile.mass).dot(forward)
 check(side.length()<=missile.lateral_acceleration_limit+0.01,"missile lateral acceleration bounded")
 check(missile.applied_torque.length()<=missile.inertia.length()*missile.turn_acceleration_limit+0.1,"missile angular actuation bounded by finite moments")
 missile.targets=[]
 await ticks(100)
 check(missile.status.begins_with("COAST") and missile.applied_force==Vector3.ZERO,"missing observations cause ballistic coast instead of perfect tracking")
 missile.fuel_delta_v=0
 await ticks(2)
 previous_v=missile.linear_velocity
 await ticks(20)
 check(missile.linear_velocity.distance_to(previous_v)<0.001,"dry missile preserves Newtonian velocity")
 check(missile.global_position.distance_to(target.global_position)>30,"unguided missile can miss target")
 for script in ["missile_body","defense_drone"]:
  var source := FileAccess.get_file_as_string("res://scripts/combat/"+script+".gd")
  var force_section := source.substr(source.find("func _integrate_forces"))
  force_section=force_section.split("\nfunc ")[0]
  check(not force_section.contains("state.linear_velocity =") and not force_section.contains("state.angular_velocity =") and not force_section.contains("state.transform =") and not force_section.contains("global_position="),"no physical state teleport in fixed-tick module: "+script)
 await ticks(3350)
 check(not impact_seen[0] and not is_instance_valid(missile),"unguided dry missile actually misses and expires without scripted hit")
 if is_instance_valid(missile): missile.queue_free()
 body.damage_model=ComponentDamage.new()
 body.angular_velocity=Vector3.ZERO # fixture isolation before thrust comparison
 body.command.main_engine=1
 await ticks(3)
 check(absf(body.acceleration_world.length()-20)<0.01,"healthy ship retains previous main acceleration")
 body.damage_model.damage("main",100)
 await ticks(3)
 check(body.applied_main_thrust_n==0 and body.acceleration_world==Vector3.ZERO,"main system failure disables real main thrust")
 body.command.main_engine=0
 body.command.translation=Vector3.RIGHT
 body.command.rotation=Vector3.UP
 body.damage_model.damage("rcs",100)
 await ticks(3)
 check(body.acceleration_world==Vector3.ZERO and body.computer.torque_local==Vector3.ZERO,"RCS failure disables both translation and rotation without NaN")
 body.damage_model.damage("weapons",100)
 launcher.advance(10)
 check(not launcher.authorize(contact,body.damage_model),"weapon damage disables launcher rather than just UI")
 body.queue_free()
 target.queue_free()
 world.queue_free()
 await process_frame
 var ai := EnemyPilot.new()
 var command := FlightCommand.new()
 ai.command_for(null,Basis.IDENTITY,Vector3.ZERO,command,1.0/60)
 check(command.translation==Vector3.ZERO and ai.phase.begins_with("SEARCH"),"enemy AI without contact coasts")
 contact=fixture_contact("DRIFT",Vector3(0,0,-1100))
 ai.command_for(contact,Basis.IDENTITY,Vector3.ZERO,command,1)
 check(absf(command.translation.x)>0.01 and command.translation.length()<=0.4,"enemy AI uses bounded lateral evasion and standoff intent")
 var game = load("res://scenes/contact_alpha.tscn").instantiate()
 game.setup_mode=CombatProfile.Mode.ASSISTED_SOLO
 game.setup_difficulty=CombatProfile.Difficulty.EASY
 game.setup_seed=1741
 root.add_child(game)
 game.pause_menu.save_settings_on_close=false
 game.encounter.automatic_weapons=false
 game.encounter.automatic_drone=false
 await ticks(100) # EASY enemy reacts after its explicit 1.3-second decision interval
 check(game.sensors.selected()!=null and game.sensors.selected().contact_id=="ALPHA","mission observes real enemy through existing sensor suite")
 check(game.encounter.enemy.linear_velocity.length()>0 and game.encounter.enemy.command.translation.length()>0,"enemy has independent physical motion and bounded AI command")
 game.crew.position=game.stations[2].position+Vector3(0,0,0.8)
 event(game,"interact")
 check(game.stations[2].occupied,"weapons station remains enterable")
 var selected_rack: int=game.encounter.player_launcher.selected_launcher
 event(game,"combat_up")
 check(game.encounter.player_launcher.selected_launcher!=selected_rack,"weapons context selects launcher")
 event(game,"combat_down")
 check(game.encounter.player_launcher.armed,"weapons context toggles fire authorization")
 event(game,"sensor_track")
 await ticks(150) # explicit tracking/solution acquisition, no instant lock
 var auto_before: bool=game.encounter.automatic_weapons
 event(game,"combat_automation")
 check(game.encounter.automatic_weapons!=auto_before,"manual console exposes optional automation")
 pad(game,JOY_BUTTON_RIGHT_SHOULDER)
 check(game.encounter.missiles.size()==1 and game.encounter.player_launcher.ammunition[selected_rack^1]==3,"manual weapon command spawns real missile and spends ammo")
 check(game.ship.command.main_engine==0 and game.ship.command.rotation==Vector3.ZERO,"combat console actions cannot leak into flight")
 await ticks(35) # wait for the newly launched missile to enter the next sensor scan
 event(game,"target_next")
 check(game.encounter.events.entries.any(func(e: Dictionary) -> bool: return e.type=="target_change"),"actual station target selection emits replay-ready event")
 event(game,"combat_hold")
 check(game.outside and game.observe_missile,"weapons context offers real missile observation camera")
 event(game,"combat_hold")
 event(game,"interact")
 game.crew.position=game.stations[1].position+Vector3(0,0,0.8)
 event(game,"interact")
 event(game,"combat_up")
 check(is_instance_valid(game.encounter.drone) and not game.encounter.drone_available,"drone context deploys physical craft")
 var drone: DefenseDrone=game.encounter.drone
 var initial_drone_position := drone.global_position
 event(game,"combat_down")
 check(drone.waypoint==game.encounter.waypoints[1],"drone waypoint command differs from weapon arming")
 event(game,"combat_primary")
 check(drone.defense_enabled,"drone context enables point defense")
 await ticks(180)
 check(drone.global_position.distance_to(initial_drone_position)>10 and drone.fuel_delta_v<650,"drone reaches toward waypoint using fuel-limited physical acceleration")
 event(game,"combat_hold")
 check(drone.hold_world,"drone context holds reachable inertial point")
 event(game,"combat_recall")
 check(drone.recalling and not drone.defense_enabled,"recall cancels defense and commands physical return")
 for i in range(1200):
  await physics_frame
  if not is_instance_valid(drone): break
 await process_frame
 check(game.encounter.drone_available and not is_instance_valid(drone),"drone physically returns and docks")
 check(game.encounter.drone_fuel<650,"recovery preserves spent fuel rather than refilling")
 check(not game.encounter.automatic_drone,"manual recall suppresses automatic redeployment")
 check(game.encounter.deploy_drone(),"recovered drone can redeploy with remaining stores")
 drone=game.encounter.drone
 drone.fuel_delta_v=0
 await ticks(2)
 var dry_drone_velocity := drone.linear_velocity
 await ticks(30)
 check(drone.linear_velocity.distance_to(dry_drone_velocity)<0.001 and drone.applied_force==Vector3.ZERO,"fuel-empty drone coasts without position snap or invisible drag")
 game.ship.damage_model.damage("sensors",100)
 await ticks(120)
 check(not game.sensors.enabled and (game.sensors.selected()==null or not game.sensors.selected().acquired()),"sensor system failure ages observations into unusable tracks")
 game.queue_free()
 await process_frame
 # Fully integrated unoccupied-station battle, no scripted hits or pose edits.
 for scenario in ["supported","unsupported"]:
  game=load("res://scenes/contact_alpha.tscn").instantiate()
  game.setup_mode=CombatProfile.Mode.FULL_AUTO
  game.setup_difficulty=CombatProfile.Difficulty.EASY
  game.setup_seed=1741
  root.add_child(game)
  game.pause_menu.save_settings_on_close=false
  if scenario=="unsupported":
   game.encounter.automatic_weapons=false
   game.encounter.automatic_drone=false
  for i in range(7200):
   await physics_frame
   await process_frame
   if game.encounter.result!="ACTIVE": break
  var encounter: CombatEncounter=game.encounter
  var counts: Dictionary={}
  for entry in encounter.events.entries: counts[entry.type]=int(counts.get(entry.type,0))+1
  print("BATTLE ",scenario," result=",encounter.result," seconds=",encounter.elapsed," events=",counts," player=",game.ship.damage_model.health," enemy=",encounter.enemy.damage_model.health)
  check(encounter.result==("VICTORY" if scenario=="supported" else "DEFEAT"),"actual missile battle outcome: "+scenario)
  check(encounter.elapsed>=30 and encounter.elapsed<=120,"battle duration within first-contact target: "+scenario)
  check(counts.get("missile_hit",0)>=2 and counts.get("system_damage",0)>=2,"physical hits produce structured system damage: "+scenario)
  check(counts.get("incapacitated",0)==1 and game.end_panel.visible,"exactly one result event and restart panel: "+scenario)
  if scenario=="supported":
   check(counts.get("intercept",0)>0,"physical defense projectiles intercept observed enemy missiles")
   check(encounter.player_launcher.ammunition[0]<4 and encounter.enemy_launcher.ammunition[0]<4,"both combatants spend finite launcher ammunition")
   check(is_instance_valid(encounter.drone) and encounter.drone.ammunition<60,"point defense consumes finite drone ammunition")
  else:
   check(game.ship.damage_model.incapable(),"unsupported player receives actual incapacitating damage")
  game.queue_free()
  await process_frame
 # New instance is the restart path's clean mission state.
 game=load("res://scenes/contact_alpha.tscn").instantiate()
 root.add_child(game)
 check(game.encounter.result=="ACTIVE" and game.encounter.player_launcher.ammunition==[4,4] and game.ship.damage_model.health.hull==100,"mission restart creates fresh ammo, state and undamaged components")
 game.queue_free()
 await process_frame
 # Exercise the actual restart button against SceneTree.current_scene.
 change_scene_to_file("res://scenes/contact_alpha.tscn")
 await scene_changed
 game=current_scene
 game.encounter.finish("VICTORY") # isolated menu fixture; battle outcomes above use actual hits
 check(game.end_panel.get_child(0).get_child(1).has_focus(),"result panel focuses restart for controller navigation")
 game.end_panel.get_child(0).get_child(1).pressed.emit()
 await scene_changed
 game=current_scene
 check(game.encounter.result=="ACTIVE" and game.ship.damage_model.health.hull==100,"restart button actually reloads playable mission")
 game.queue_free()
 await process_frame
 print("Combat checks=",checks," failures=",failures)
 quit(1 if failures else 0)
