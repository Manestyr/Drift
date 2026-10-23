extends SceneTree
var checks: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if ok: print("PASS: ",message)
 else:
  failures+=1
  push_error("FAIL: "+message)
func contact(id: String,kind: String,p: Vector3,v: Vector3=Vector3.ZERO) -> SensorContact:
 var result:=SensorContact.new()
 result.contact_id=id
 result.kind=kind
 result.team=1
 result.quality=0.9
 result.observed_position_world=p
 result.observed_velocity_world=v
 result.velocity_known=true
 return result
func observe(state: ShipDesignations,values: Array[SensorContact],now: float) -> void:
 state.observe(values,now)
func action(game: Node,name: String) -> void:
 var event:=InputEventAction.new()
 event.action=name
 event.pressed=true
 game._unhandled_input(event)
 event.pressed=false
 game._unhandled_input(event)
func button(game: Node,index: int) -> void:
 var event:=InputEventJoypadButton.new()
 event.button_index=index
 event.pressed=true
 game._unhandled_input(event)
 event.pressed=false
 game._unhandled_input(event)
func ticks(n: int) -> void:
 for i in n:
  await physics_frame
  await process_frame
func run() -> void:
 root.size=Vector2i(1280,720)
 var state:=ShipDesignations.new()
 var ship:=contact("SHIP","ship",Vector3(100,0,-1000),Vector3(20,0,0))
 var replacement:=contact("OTHER","ship",Vector3(-50,0,-900))
 var missile:=contact("M1","missile",Vector3(0,0,-500),Vector3(0,0,100))
 observe(state,[ship,replacement,missile],10)
 check(state.primary==null and state.threat==null,"observation never assigns crew priorities automatically")
 check(state.designate("SHIP","primary","sensor-operator"),"operator can designate an observed hostile ship")
 check(state.primary.target_id=="SHIP" and state.primary.sender_role=="sensor-operator" and state.primary.issued_seconds==10,"designation carries target, sender role and simulation time")
 check(not state.designate("M1","primary","sensor-operator") and not state.designate("SHIP","threat","sensor-operator"),"designation categories reject wrong contact kinds")
 check(not state.designate("UNKNOWN","primary","sensor-operator") and not state.designate("SHIP","primary",""),"unknown contacts and missing sender are rejected")
 check(state.designate("M1","threat","sensor-operator") and state.primary.target_id=="SHIP","threat and primary designations coexist independently")
 state.designate("OTHER","primary","sensor-operator")
 check(state.primary.target_id=="OTHER" and state.threat.target_id=="M1","primary replacement does not change threat")
 state.clear_selected("OTHER","sensor-operator")
 check(state.primary==null and state.threat!=null,"selected designation clears without deleting the other category")
 state.clear("threat","sensor-operator")
 check(state.threat==null,"operator can remove priority missile")
 check(ShipDesignations.new().tracks.is_empty(),"each ship owns independent tactical state")
 var friendly:=contact("FRIEND","ship",Vector3(0,0,-20))
 friendly.team=0
 var invalid:=contact("INVALID","ship",Vector3(NAN,0,-20))
 var weak:=contact("WEAK","ship",Vector3(0,0,-20))
 weak.quality=0.1
 observe(state,[friendly,invalid,weak],10.1)
 check(state.get_track("FRIEND")==null and state.get_track("INVALID")==null and state.get_track("WEAK")==null,"friendly, nonfinite and unusably weak observations cannot create markers")
 check(state.get_track("SHIP").position_world==Vector3(100,0,-1000),"missing contacts retain copied evidence rather than enemy references")
 ship.observed_position_world=Vector3(999,999,999)
 check(state.get_track("SHIP").position_world==Vector3(100,0,-1000),"UI snapshot cannot mutate through the original SensorContact")
 var extrapolated:=state.get_track("SHIP").estimated_position(10.5)
 check(extrapolated.is_equal_approx(Vector3(110,0,-1000)),"brief lost-contact estimate follows measured velocity")
 check(state.get_track("SHIP").uncertain(10.1),"lost contact is explicitly uncertain immediately")
 check(not state.designate("SHIP","primary","sensor-operator"),"a lost retained track cannot receive a fresh designation")
 observe(state,[],11.5)
 check(state.tracks.is_empty(),"missing contacts expire at the bounded 1.5-second horizon")
 ship.observed_position_world=Vector3(100,0,-1000)
 ship.age_seconds=0.6
 observe(state,[ship],20)
 state.designate("SHIP","primary","sensor-operator")
 observe(state,[],20.8)
 check(state.primary!=null,"existing designation briefly survives sensor loss")
 observe(state,[],20.91)
 check(state.primary==null and state.tracks.is_empty(),"expiration clears shared designation and marker together")
 ship.age_seconds=1.6
 observe(state,[ship],30)
 check(state.get_track("SHIP")==null,"already expired sensor contacts cannot refresh history")
 ship.age_seconds=0
 ship.quality=0.4
 observe(state,[ship],31)
 check(state.get_track("SHIP").uncertain(31),"low quality observations use uncertain presentation")
 ship.quality=0.9
 observe(state,[ship],31.1)
 check(not state.get_track("SHIP").uncertain(31.1),"new high-quality observation replaces uncertainty")
 var observer:=Node3D.new()
 root.add_child(observer)
 var camera:=Camera3D.new()
 observer.add_child(camera)
 camera.current=true
 await process_frame
 var center:=TacticalHud.project(camera,Vector3(0,0,-100),Vector2(1280,720))
 check(not center.edge and center.point.is_equal_approx(Vector2(640,360)),"forward measured target projects into real camera center")
 var side:=TacticalHud.project(camera,Vector3(1000,0,-100),Vector2(1280,720))
 check(side.edge and side.point.x>1100 and side.direction.x>0,"right offscreen contact points to the right edge")
 var aft:=TacticalHud.project(camera,Vector3(100,0,100),Vector2(1280,720))
 check(aft.edge and aft.behind and aft.direction.x>0,"behind-camera direction is not mirrored to the wrong side")
 var exact_aft:=TacticalHud.project(camera,Vector3(0,0,100),Vector2(1280,720))
 check(exact_aft.edge and exact_aft.direction.is_finite(),"exact aft has deterministic finite edge direction")
 check(TacticalHud.project(camera,Vector3(INF,0,0),Vector2(1280,720)).is_empty(),"invalid positions never produce misleading arrows")
 observer.rotation.y=PI/2
 var rotated:=TacticalHud.project(camera,Vector3(-100,0,0),Vector2(1280,720))
 check(not rotated.edge and rotated.point.distance_to(Vector2(640,360))<0.1,"projection follows actual camera orientation")
 observer.rotation=Vector3.ZERO
 var warning_state:=ShipDesignations.new()
 var incoming: Array[SensorContact]=[]
 for index in 5:
  incoming.append(contact("IN%d"%index,"missile",Vector3(index*4,0,-500-index*100),Vector3(0,0,100)))
 incoming.append(contact("RECEDING","missile",Vector3(0,0,-100),Vector3(0,0,-100)))
 incoming.append(contact("MISS","missile",Vector3(500,0,-100),Vector3(0,0,100)))
 var unknown:=contact("UNKNOWN-V","missile",Vector3(0,0,-100))
 unknown.velocity_known=false
 incoming.append(unknown)
 observe(warning_state,incoming,40)
 check(warning_state.warning_tracks(Vector3.ZERO,Vector3.ZERO).size()==5,"several observed inbound missiles generate warnings, receding/near-miss/unknown tracks do not")
 check(warning_state.threat==null,"automatic immediate warnings never become operator priorities")
 warning_state.designate("IN4","threat","sensor-operator")
 check(warning_state.warning_tracks(Vector3.ZERO,Vector3.ZERO)[0].id=="IN4","crew priority ranks above nearest automatic danger")
 var hud:=TacticalHud.new()
 hud.state=warning_state
 hud.camera=camera
 root.add_child(hud)
 hud.size=Vector2(1280,720)
 hud.refresh()
 check(hud.markers.size()==3 and hud.markers[0].priority and hud.overflow.text.contains("THREATS 5"),"HUD caps clutter at three missile markers and reports hidden threats")
 check(hud.labels.filter(func(label: Label) -> bool: return label.visible).all(func(label: Label) -> bool: return label.position.y>=80 and label.position.y+70<=320),"tactical callouts remain above physical cockpit instrument area")
 check(hud.markers[0].text.contains("near ~") and hud.markers[0].text.contains("closing"),"approach text is explicitly estimated and uses measured closing velocity")
 check(unknown.velocity_known==false and warning_state.get_track("UNKNOWN-V").approach(Vector3.ZERO,Vector3.ZERO,40).x<0,"unknown velocity cannot invent an impact countdown")
 var before:=warning_state.get_track("IN0").approach(Vector3.ZERO,Vector3.ZERO,40)
 var moving:=warning_state.get_track("IN0").approach(Vector3.ZERO,Vector3(0,0,20),40)
 check(moving.y<before.y,"warning calculation uses current cooperative observer velocity")
 observe(warning_state,[],41.6)
 hud.refresh()
 check(hud.markers.is_empty() and hud.labels.all(func(label: Label) -> bool: return not label.visible),"expired tracks remove both marker geometry and labels")
 hud.queue_free()
 observer.queue_free()
 await process_frame
 # End-to-end actual station interaction and PS context checks, no body-state hacks.
 Input.use_accumulated_input=false
 var game=load("res://scenes/contact_alpha.tscn").instantiate()
 game.setup_seed=71
 root.add_child(game)
 game.pause_menu.save_settings_on_close=false
 game.input_source.settings.symbol_scheme=1
 game.input_source.using_gamepad=true
 await ticks(100)
 game.crew.position=game.stations[1].position+Vector3(0,0,0.8)
 action(game,"interact")
 check(game.current_station()==game.stations[1],"sensor station is physically enterable before designation")
 var trigger:=InputEventJoypadMotion.new()
 trigger.axis=JOY_AXIS_TRIGGER_LEFT
 trigger.axis_value=0.8
 Input.parse_input_event(trigger)
 await process_frame
 button(game,JOY_BUTTON_RIGHT_STICK)
 check(game.designation_context and not game.encounter.automatic_drone,"L2 + R3 enters DESIGNATE without role delegation")
 trigger.axis_value=0
 Input.parse_input_event(trigger)
 game.sensors.selected_id="ALPHA"
 button(game,JOY_BUTTON_X)
 var shared: ShipDesignations=game.encounter.player_designations
 check(shared.primary!=null and shared.primary.target_id=="ALPHA","PS Square designates sensor-observed hostile ship")
 check(not game.sensors.tracking_enabled,"DESIGNATE Square does not silently toggle tracking")
 button(game,JOY_BUTTON_RIGHT_SHOULDER)
 button(game,JOY_BUTTON_DPAD_UP)
 check(game.encounter.player_launcher.shots==0 and not is_instance_valid(game.encounter.drone),"designation controls neither fire weapons nor deploy drone")
 button(game,JOY_BUTTON_B)
 check(not game.designation_context and game.stations[1].secured,"Circle returns to drone controls without releasing harness")
 button(game,JOY_BUTTON_RIGHT_SHOULDER)
 button(game,JOY_BUTTON_DPAD_UP)
 check(is_instance_valid(game.encounter.drone),"original drone deployment remains functional outside DESIGNATE")
 action(game,"interact")
 game.crew.position=game.station.position+Vector3(0,0,0.8)
 action(game,"interact")
 await ticks(2)
 check(game.station.occupied and game.tactical_hud.visible and game.tactical_hud.markers.any(func(marker: Dictionary) -> bool: return marker.id=="ALPHA"),"sensor designation reaches pilot HUD after real seat change")
 check(game.tactical_hud.state==game.encounter.player_designations,"pilot reads the same ship-owned data as the sensor station")
 check(game.tactical_hud.markers[0].estimated.distance_to(game.encounter.enemy.global_position)>0.001,"marker uses quantized/extrapolated observation rather than exact enemy position")
 action(game,"exterior")
 await ticks(2)
 check(game.tactical_hud.visible and game.tactical_hud.camera==game.outside_camera,"exterior HUD projects through actual orbit camera")
 action(game,"exterior")
 action(game,"interact")
 game.crew.position=game.stations[1].position+Vector3(0,0,0.8)
 action(game,"interact")
 action(game,"designation_context")
 game.sensors.selected_id="ALPHA"
 button(game,JOY_BUTTON_RIGHT_STICK)
 check(shared.primary==null,"R3 clears selected ship marker only in DESIGNATE")
 button(game,JOY_BUTTON_A)
 check(game.current_station()==null and not game.designation_context,"Cross safely leaves DESIGNATE and its station")
 var event_count:=0
 for entry in game.encounter.events.entries:
  if entry.type=="designation": event_count+=1
 check(event_count>=2,"designation commands produce timestamped ship tactical events")
 check(game.encounter.player_launcher.shots==0,"shared HUD never adds MANUAL weapon automation")
 game.queue_free()
 await ticks(3)
 print("Shared tactical HUD checks=",checks," failures=",failures)
 quit(0 if failures==0 else 1)
