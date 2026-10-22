extends SceneTree

var failures: int = 0
var checks: int = 0
func _initialize() -> void:
 call_deferred("run")
func check(ok: bool, message: String) -> void:
 checks += 1
 if ok: print("PASS: ",message)
 else:
  failures += 1
  push_error("FAIL: " + message)
func ticks(count: int) -> void:
 for i in count: await physics_frame
 await process_frame
func action(game: Node, name: String) -> void:
 var event := InputEventAction.new()
 event.action = name
 event.pressed = true
 game._unhandled_input(event)
func pad(game: Node, button: JoyButton) -> void:
 var event := InputEventJoypadButton.new()
 event.button_index = button
 event.pressed = true
 game._unhandled_input(event)
func run() -> void:
 root.size = Vector2i(1280,720)
 var seat := CrewStation.new()
 check(seat.enter("alice"),"station accepts identified operator")
 check(seat.secured and seat.occupant_id == "alice","entry secures harness with identity")
 check(not seat.enter("bob"),"station rejects second operator")
 seat.set_secured(false)
 check(not seat.secured and seat.occupied,"harness release preserves occupancy")
 seat.leave()
 check(not seat.occupied and not seat.secured and seat.occupant_id.is_empty(),"exit clears ownership and restraint")
 check(not seat.enter(""),"empty operator identity rejected")
 seat.restraint_suitable = false
 seat.enter("alice")
 check(not seat.secured,"unsuitable seat cannot secure crew")
 seat.free()
 var safety := CrewSafety.new()
 check(not safety.all_secured(),"empty roster cannot authorize combat")
 var alice := CrewMember.new()
 safety.members.append(alice)
 safety.combat_requested = true
 var force := safety.limit_force(Vector3(8e6,8e6,-8e6),120000)
 check(absf(force.length()/120000 - 3*CrewSafety.G) < 0.001,"aggregate diagonal force limited to 3g")
 check(safety.denied and safety.limited,"unsecured combat request explicitly denied")
 check(force.normalized().distance_to(Vector3(1,1,-1).normalized()) < 0.0001,"limiter preserves requested force direction")
 alice.station_id = "pilot"
 alice.secured = true
 check(safety.all_secured(),"secured station satisfies roster")
 force = safety.limit_force(Vector3(20e6,0,0),120000)
 check(absf(force.length()/120000 - 8*CrewSafety.G) < 0.001 and not safety.denied,"secured combat envelope bounded at 8g")
 var bob := CrewMember.new()
 bob.member_id = "bob"
 safety.members.append(bob)
 check(not safety.all_secured(),"one unsecured second member blocks all-secured")
 bob.secured = true
 bob.station_id = "sensors"
 check(safety.all_secured(),"all present secured members authorize combat")
 safety.combat_requested = false
 check(absf(safety.limit_force(Vector3(20e6,0,0),120000).length()/120000 - 3*CrewSafety.G)<0.001,"normal mode still limited with secured crew")
 check(safety.limit_force(Vector3.ZERO,120000) == Vector3.ZERO,"neutral request remains zero")
 alice.seat_position = Vector3(2,0,0)
 alice.seat_basis = Basis(Vector3.FORWARD,PI/2)
 alice.sample_load(Vector3(0,10,0),Vector3(0,0,2),Vector3(0,0,1),Basis.IDENTITY,42)
 var expected := alice.seat_basis.inverse()*Vector3(-8,12,0)
 check(alice.proper_acceleration.distance_to(expected)<0.001 and alice.sample_tick==42,"crew-point load includes oriented angular acceleration and centripetal term")
 var sensor := SensorSuite.new()
 var target := Node3D.new()
 target.name = "KNOWN"
 root.add_child(target)
 target.position = Vector3(100,0,-500)
 var targets: Array[Node3D] = [target]
 sensor.sample(targets,Transform3D.IDENTITY,Vector3(10,0,0),30,0.5)
 check(sensor.contacts.size()==1,"in-range physical target observed")
 check(not sensor.selected().velocity_known,"first observation does not invent velocity")
 target.position.x += 10
 sensor.sample(targets,Transform3D.IDENTITY,Vector3(10,0,0),60,0.5)
 check(sensor.selected().relative_velocity.distance_to(Vector3(10,0,0))<0.001,"relative velocity estimated from timed measurements minus observer velocity")
 check(sensor.selected().acquired(),"near contact acquired")
 var sampled_position := sensor.selected().relative_position
 target.position.x += 100
 sensor.sample(targets,Transform3D.IDENTITY,Vector3.ZERO,66,0.1)
 check(sensor.selected().relative_position==sampled_position and sensor.selected().age_seconds>0,"no perfect knowledge between sensor scans")
 target.position.x -= 100
 var fire := FireControl.new()
 fire.update(sensor.selected())
 check(not fire.solution_valid,"weapons reject untracked observation")
 sensor.toggle_tracking()
 sensor.sample(targets,Transform3D.IDENTITY,Vector3.ZERO,90,0.5)
 fire.update(sensor.selected())
 check(fire.solution_valid and fire.solution_seconds>0,"tracked acquired observation produces simulated intercept")
 sensor.toggle_tracking()
 fire.update(sensor.selected())
 check(not fire.solution_valid,"tracking release immediately invalidates simulated solution")
 sensor.toggle_tracking()
 check(fire.launch_safety.begins_with("INHIBITED"),"launch permanently inhibited without ordnance")
 sensor.selected().age_seconds = 2.0
 fire.update(sensor.selected())
 check(not fire.solution_valid,"stale observation invalidates fire solution")
 target.position = Vector3(0,0,-2200)
 sensor.sample(targets,Transform3D.IDENTITY,Vector3.ZERO,120,0.5)
 check(not sensor.selected().acquired(),"distant detection distinguished from acquired contact")
 fire.update(sensor.selected())
 check(not fire.solution_valid,"weak contact cannot produce solution")
 var orientation := Basis(Vector3.UP,PI/2)
 sensor.sample(targets,Transform3D(orientation,Vector3.ZERO),Vector3(0,0,20),150,0.5)
 check(sensor.selected().relative_position.distance_to(orientation.inverse()*target.position)<0.001,"sensor position expressed in actual observer basis")
 check(sensor.selected().relative_velocity.distance_to(orientation.inverse()*Vector3(0,0,-20))<0.001,"observed relative velocity rotates into observer basis")
 target.position.z = -3000
 sensor.sample(targets,Transform3D.IDENTITY,Vector3.ZERO,150,0.5)
 check(sensor.contacts.is_empty() and sensor.selected()==null,"out-of-range contacts removed and selection cleared")
 target.queue_free()
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.pause_menu.save_settings_on_close = false
 await ticks(35)
 check(game.stations.size()==3 and not game.hud.visible,"three stations and no debug wall at startup")
 check(game.sensors.contacts.size()==3,"test targets feed actual observation pipeline")
 for name in ["secure_crew","combat_envelope","target_previous","target_next","sensor_track"]:
  check(InputMap.has_action(name) and InputMap.action_get_events(name).size()==2,"keyboard and pad map: "+name)
 game.crew.position = Vector3(0,1,-12)
 action(game,"interact")
 check(game.station.occupied and game.current_station()==game.station,"pilot interaction selects nearest station")
 await ticks(2)
 check(game.crew_safety.all_secured(),"station restraint flows into central roster")
 action(game,"secure_crew")
 action(game,"combat_envelope")
 await ticks(2)
 check(game.crew_safety.denied and not game.crew_safety.all_secured(),"pilot harness release denies requested combat envelope")
 # Test fixture alone raises available hardware budgets: production defaults unchanged.
 game.ship.main_thrust_n = 12e6
 game.ship.rcs_thrust_n = 12e6
 game.ship.linear_velocity = Vector3(200,0,0)
 Input.action_press("main_engine")
 Input.action_press("right")
 await ticks(10)
 check(game.ship.acceleration_world.length() <= 3*CrewSafety.G+0.001,"integrator limits combined main and lateral request")
 check(absf(game.ship.acceleration_world.length()-3*CrewSafety.G)<0.001,"actual force reaches configured 3g ceiling without teleporting")
 check(game.ship.linear_velocity.length()>195,"limiter never clamps existing velocity")
 check(game.instruments.snapshot.acceleration_local.length()<=3*CrewSafety.G+0.001,"instruments report applied limited acceleration")
 Input.action_release("main_engine")
 Input.action_release("right")
 await ticks(2)
 var coasting: Vector3 = game.ship.linear_velocity
 await ticks(10)
 check(game.ship.linear_velocity.distance_to(coasting)<0.001,"zero command preserves high velocity under crew limit")
 game.ship.main_thrust_n = 2400000
 game.ship.rcs_thrust_n = 1200000
 action(game,"interact")
 for index in [1,2]:
  var console: CrewStation = game.stations[index]
  game.crew.position = console.position + Vector3(0,0,0.8)
  action(game,"interact")
  await ticks(2)
  check(console.occupied and console.secured and game.crew.seated,"tactical station entry/secures: "+console.station_id)
  check(console.camera.current and game.interior_view.visible,"own local camera context: "+console.station_id)
  var rotation_before: bool = game.ship.computer.rotation_stabilization
  action(game,"sensor_track")
  check(game.ship.computer.rotation_stabilization==rotation_before,"tactical T cannot toggle flight stabilization")
  Input.action_press("main_engine")
  Input.action_press("forward")
  await ticks(3)
  check(game.ship.command.main_engine==0 and game.ship.command.translation==Vector3.ZERO,"tactical input cannot command flight")
  Input.action_release("main_engine")
  Input.action_release("forward")
  var selected: String = game.sensors.selected_id
  pad(game,JOY_BUTTON_DPAD_RIGHT)
  check(game.sensors.selected_id!=selected,"tactical target cycling: "+console.station_id)
  var previous_secured: bool = console.secured
  pad(game,JOY_BUTTON_B)
  check(console.secured!=previous_secured,"controller B owns tactical harness context")
  game.input_source.using_gamepad = true
  Input.action_press("pad_main",1.0)
  Input.action_press("pad_left_up",1.0)
  await ticks(2)
  check(game.ship.command.main_engine==0 and game.ship.command.rotation==Vector3.ZERO,"controller axes isolated from flight at tactical station")
  Input.action_release("pad_main")
  Input.action_release("pad_left_up")
  game.input_source.using_gamepad = false
  pad(game,JOY_BUTTON_A)
  check(not console.occupied and not game.crew.seated,"tactical station exit: "+console.station_id)
 check(game.ship.linear_velocity.distance_to(coasting)<0.001,"all station changes preserve ship momentum")
 # Walk the continuous deck back from bridge through corridor to engineering.
 game.crew.position = Vector3(0,1,-9)
 game.crew.rotation = Vector3.ZERO
 Input.action_press("back")
 await ticks(340)
 Input.action_release("back")
 check(game.crew.position.z>12 and game.crew.is_on_floor(),"crew walks full bridge-corridor-engineering route with collisions")
 check(game.crew_member.sample_tick>0,"per-member acceleration observer sampled by fixed physics tick")
 game.queue_free()
 await process_frame
 print("Crew/stations checks=",checks," failures=",failures)
 quit(1 if failures else 0)
