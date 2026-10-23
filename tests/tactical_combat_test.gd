extends SceneTree
var checks: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
 checks+=1
 if ok: print("PASS: ",message)
 else:
  failures+=1
  push_error("FAIL: "+message)
func ticks(n: int) -> void:
 for i in n:
  await physics_frame
  await process_frame
func action(game: Node,name: String) -> void:
 var event:=InputEventAction.new()
 event.action=name
 event.pressed=true
 game._unhandled_input(event)
 event.pressed=false
 game._unhandled_input(event)
func pad(index: int,value: float) -> void:
 var event:=InputEventJoypadMotion.new()
 event.axis=index
 event.axis_value=value
 Input.parse_input_event(event)
func press(game: Node,index: int) -> void:
 var event:=InputEventJoypadButton.new()
 event.button_index=index
 event.pressed=true
 game._unhandled_input(event)
 event.pressed=false
 game._unhandled_input(event)
func run() -> void:
 Input.use_accumulated_input=false
 root.size=Vector2i(1280,720)
 var game=load("res://scenes/contact_alpha.tscn").instantiate()
 game.setup_seed=71
 root.add_child(game)
 game.pause_menu.save_settings_on_close=false
 await ticks(65)
 check(game.encounter.control_mode==CombatProfile.Mode.MANUAL and game.encounter.player_launcher.shots==0,"new systems keep MANUAL free of unsolicited launches")
 var model:=TacticalMapModel.new()
 var observation:=SensorContact.new()
 observation.contact_id="UNCERTAIN"
 observation.team=1
 observation.quality=0.4
 observation.velocity_known=true
 observation.observed_position_world=Vector3(10,120,-300)
 observation.observed_velocity_world=Vector3(5,0,0)
 var suite:=SensorSuite.new()
 suite.contacts=[observation]
 var own: Array[Node3D]=[game.ship,game.encounter.enemy] # wrong-team input must be rejected
 model.sample(game.ship,suite,own)
 var track:=model.find("UNCERTAIN")
 check(model.find("ALPHA")==null,"map rejects foreign ground truth even when mistakenly passed as own link")
 check(track!=null and track.position.is_equal_approx(Vector3(10,120,-300)),"map position derives from measured sensor coordinates including height")
 check(not track.velocity_known and track.horizon==0,"insufficient quality cannot reveal velocity or detailed predictions")
 observation.quality=1
 observation.age_seconds=0.2
 model.sample(game.ship,suite,own)
 track=model.find("UNCERTAIN")
 check(track.velocity_known and track.horizon<=4,"acquired observed track has limited forecast horizon")
 # Observer translation is already included by the current frame origin.
 game.ship.linear_velocity=Vector3(100,0,0) # isolated snapshot setup, not a gameplay command
 model.sample(game.ship,suite,own)
 check(model.find("UNCERTAIN").position.is_equal_approx(Vector3(11,120,-300)),"aged observations do not subtract observer travel twice")
 game.ship.linear_velocity=Vector3.ZERO
 model.sample(game.ship,suite,own)
 track=model.find("UNCERTAIN")

 check(track.predict(2).is_equal_approx(track.position+track.velocity*2),"constant-velocity forecast uses available observations")
 check(track.predict(100).is_equal_approx(track.predict(track.horizon)),"forecast never extends past published horizon")
 check(track.uncertainty(3)>track.uncertainty(1),"prediction uncertainty grows with horizon")
 var previous:=track.position
 var previous_revision:=model.revision
 observation.observed_position_world+=Vector3(20,30,0)
 model.sample(game.ship,suite,own)
 check(model.find("UNCERTAIN").position!=previous and model.revision==previous_revision+1,"new measured samples update tactical snapshots")
 observation.age_seconds=2
 model.sample(game.ship,suite,own)
 check(model.find("UNCERTAIN")==null,"aged-out observations disappear instead of following perfect enemy truth")
 game.crew.position=game.stations[2].position+Vector3(0,0,0.8)
 action(game,"interact")
 press(game,JOY_BUTTON_BACK)
 await ticks(10)
 check(game.weapon_view==game.WeaponView.MAP and game.weapon_map().visible,"PS Share enters physical-console 3D map")
 var map: TacticalMap=game.weapon_map()
 var top:=map.project(Vector3(0,100,0))
 var bottom:=map.project(Vector3(0,-100,0))
 check(top.distance_to(bottom)>5,"3D projection distinguishes altitude, unlike old X-Z overlay")
 var initial_yaw:=map.yaw
 map.orbit(Vector2(1,0.5),0.2)
 check(map.yaw!=initial_yaw,"map camera orbits independently of ship physics")
 map.zoom(-0.2)
 check(map.distance<22,"tactical zoom changes relative rendering scale")
 map.selected_id="DRIFT"
 map.focus_selected()
 check(map.focus==Vector3.ZERO and map.follow_selected,"focus follows selected own contact")
 check(map.find_children("","RigidBody3D",true,false).is_empty(),"map contains display geometry and no second physical universe")
 var shots: int=game.encounter.player_launcher.shots
 press(game,JOY_BUTTON_RIGHT_SHOULDER)
 press(game,JOY_BUTTON_DPAD_DOWN)
 check(game.encounter.player_launcher.shots==shots and not game.encounter.player_launcher.armed,"map input cannot fire or arm weapons")
 press(game,JOY_BUTTON_B)
 check(game.weapon_view==game.WeaponView.FIRE_CONTROL and not game.outside,"Circle returns safely to fire control")
 action(game,"sensor_track")
 action(game,"combat_down")
 await ticks(150)
 action(game,"combat_primary")
 check(game.encounter.player_launcher.shots==1,"explicit console order still launches one physical missile")
 action(game,"combat_hold")
 check(game.observe_missile and game.selected_missile()!=null,"L1/H selects live own missile and enters its camera")
 var missile: MissileBody=game.selected_missile()
 action(game,"missile_manual")
 check(missile.manual_mode,"manual guidance requires an explicit separate command")
 await ticks(1)
 var before: Vector3=missile.linear_velocity
 pad(JOY_AXIS_LEFT_X,-1)
 missile.manual_throttle=0
 await ticks(5)
 check(missile.delivered_rotation==Vector3.ZERO,"remote command cannot bypass physical link delay")
 await ticks(10)
 check(missile.delivered_rotation.y>0 and missile.applied_torque.length()>0,"delayed manual rotation requests actual bounded torque")
 check(missile.applied_force==Vector3.ZERO,"rotation-only manual demand emits no central force")
 check(missile.applied_torque.length()<=missile.inertia.length()*missile.turn_acceleration_limit+0.1,"manual torque obeys finite inertia and actuator bounds")
 # Detached isolated missile keeps context sampler from replacing a known demand.
 pad(JOY_AXIS_LEFT_X,0)
 missile.set_manual(false)
 press(game,JOY_BUTTON_B)
 var isolated:=MissileBody.new()
 isolated.position=Vector3(1000,500,1000)
 isolated.linear_velocity=Vector3(2,3,4)
 game.ship.get_parent().add_child(isolated)
 isolated.set_manual(true)
 isolated.manual_rotation=Vector3(0.4,-0.3,0)
 isolated.manual_throttle=0
 await ticks(40)
 check(isolated.linear_velocity.is_equal_approx(Vector3(2,3,4)),"isolated manual rotation preserves the complete inertial velocity vector")
 isolated.manual_throttle=0.6
 var reserve:=isolated.control_reserve
 var fuel:=isolated.fuel_delta_v
 await ticks(80)
 check(isolated.linear_velocity.distance_to(Vector3(2,3,4))>1,"manual main burn changes velocity through integrated force")
 check(isolated.applied_force.length()<=isolated.thrust_n+0.1,"manual resultant force is bounded")
 check(isolated.fuel_delta_v<fuel and isolated.control_reserve<reserve,"manual translation and rotation consume finite reserves")
 check(isolated.angular_velocity.length()<isolated.max_manual_rate+0.08,"rate controller settles below configured manual rate envelope")
 isolated.fuel_delta_v=0
 await ticks(2)
 before=isolated.linear_velocity
 var omega:=isolated.angular_velocity
 await ticks(30)
 check(isolated.linear_velocity.distance_to(before)<0.001 and isolated.angular_velocity.distance_to(omega)<0.001,"dry manual missile coasts linearly and angularly without artificial damping")
 isolated.queue_free()
 # A separate own-link camera fixture cannot disappear into the target while
 # this test advances an unrelated isolated missile.
 var camera_fixture:=MissileBody.new()
 camera_fixture.name="CAMERA-FIXTURE"
 camera_fixture.position=Vector3(-1000,600,800)
 game.encounter.add_child(camera_fixture)
 game.encounter.missiles.append(camera_fixture)
 action(game,"combat_hold")
 game.selected_missile_id=String(camera_fixture.name)
 action(game,"missile_manual")
 var controlled: MissileBody=game.selected_missile()
 check(controlled!=null,"operator can reselect surviving missile")
 game.pause_menu.set_paused(true)
 check(controlled.manual_throttle==0 and controlled._manual_queue.is_empty(),"pause clears queued manual missile input")
 game.pause_menu.set_paused(false)
 press(game,JOY_BUTTON_B)
 check(not controlled.manual_mode and game.weapon_view==game.WeaponView.FIRE_CONTROL,"returning to console relinquishes manual control to AUTO")
 check(game.ship.command.main_engine==0 and game.ship.command.rotation==Vector3.ZERO,"missile/map commands never actuate ship flight channels")
 check(InputMap.has_action("tactical_map") and InputMap.has_action("missile_manual"),"new context commands use Input Map actions")
 var map_event:=InputEventJoypadButton.new()
 map_event.button_index=JOY_BUTTON_BACK
 var manual_event:=InputEventJoypadButton.new()
 manual_event.button_index=JOY_BUTTON_RIGHT_STICK
 check(InputMap.action_has_event("tactical_map",map_event) and InputMap.action_has_event("missile_manual",manual_event),"Share/Create and R3 bindings resolve through actual Input Map")
 var keyboard_adapter:=PlayerInput.new()
 var keyboard_command:=FlightCommand.new()
 Input.action_press("yaw_left")
 Input.action_press("pitch_up")
 keyboard_adapter.sample_missile(keyboard_command,1.0/60)
 check(keyboard_command.rotation==Vector3.ZERO,"missile selection arrows cannot also apply keyboard steering")
 Input.action_release("yaw_left")
 Input.action_release("pitch_up")
 keyboard_adapter.free()

 check(game.audio.structural[0].stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"RCS audio uses continuous smoothed loop, not repetitive gunshot cues")
 game.queue_free()
 await process_frame
 var no_drone:=await DefenseTrial.run(self,"none",3)
 var guard:=await DefenseTrial.run(self,"guard",3)
 var bad:=await DefenseTrial.run(self,"rear",3)
 var single:=await DefenseTrial.run(self,"guard",1)
 var legacy:=await DefenseTrial.run(self,"guard",3,true)
 check(single.intercepts>=1,"well-positioned defense remains reliable against a single inbound threat")
 check(guard.intercepts>no_drone.intercepts and guard.hits<no_drone.hits,"physical guard reduces real salvo hits relative to no defense")
 check(guard.intercepts<3 and guard.hits>0,"simultaneous multi-angle salvo penetrates finite defense")
 check(guard.intercepts>bad.intercepts and guard.hits<bad.hits,"poor rear placement provides less real protection")
 check(guard.max_slew<=3.0/60.0+0.001,"turret aim changes obey radian-per-tick slew limit")
 check(guard.fuel_used>0 and guard.shots>0,"physical deployment spends actual fuel and defense rounds")
 check(legacy.intercepts>=guard.intercepts,"unlimited turret counterfactual isolates previous ideal-aim advantage")
 var report: Array[Dictionary]=[no_drone,guard,bad,single,legacy]
 var file:=FileAccess.open("res://docs/defense-0.3.3.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report," ")+"\n")
 print("Tactical combat checks=",checks," failures=",failures)
 quit(1 if failures else 0)
