extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool, message: String) -> void:
 checks += 1
 if ok: print("PASS: ", message)
 else:
  failures += 1
  push_error("FAIL: " + message)

func ticks(count: int) -> void:
 for i in range(count): await physics_frame
 await process_frame

func reset(ship: ShipPhysics) -> void:
 ship.command.clear()
 ship.computer.rotation_stabilization = false
 ship.computer.reference_velocity = Vector3.ZERO
 ship.reset_requested = true
 await ticks(4)

func button(index: int, pressed: bool = true) -> InputEventJoypadButton:
 var event := InputEventJoypadButton.new()
 event.button_index = index
 event.pressed = pressed
 return event

func press(index: int) -> void:
 Input.parse_input_event(button(index))
 await process_frame
 Input.parse_input_event(button(index, false))
 await process_frame

func run() -> void:
 Input.use_accumulated_input = false
 var source := PlayerInput.new()
 root.add_child(source)
 var command := FlightCommand.new()
 source.sample_flight(command)
 check(not command.drift_cancel, "drift command defaults OFF")
 var key := InputEventKey.new()
 key.physical_keycode = KEY_C
 key.pressed = true
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 source.sample_flight(command)
 check(command.drift_cancel, "physical C press activates held drift command")
 key = key.duplicate()
 key.pressed = false
 Input.parse_input_event(key)
 Input.flush_buffered_events()
 source.sample_flight(command)
 check(not command.drift_cancel, "C release clears command without a toggle")
 source.using_gamepad = true
 source.settings.drift_button = JOY_BUTTON_X
 source.settings.drift_modifier = JOY_BUTTON_LEFT_STICK
 source.settings.apply_advanced_bindings()
 Input.parse_input_event(button(JOY_BUTTON_X))
 source.sample_flight(command)
 check(not command.drift_cancel, "configured controller chord requires modifier")
 Input.parse_input_event(button(JOY_BUTTON_LEFT_STICK))
 source.sample_flight(command)
 check(command.drift_cancel, "held controller chord activates drift")
 source.settings.apply_advanced_bindings()
 source.sample_flight(command)
 check(not command.drift_cancel, "binding changes clear held action state rather than latching assistance")
 Input.parse_input_event(button(JOY_BUTTON_X))
 Input.parse_input_event(button(JOY_BUTTON_LEFT_STICK))
 Input.parse_input_event(button(JOY_BUTTON_X, false))
 source.sample_flight(command)
 check(not command.drift_cancel, "controller chord release clears drift immediately")
 Input.parse_input_event(button(JOY_BUTTON_LEFT_STICK, false))
 var settings_path := "user://advanced_test_settings.cfg"
 source.settings.retrograde_button = JOY_BUTTON_BACK
 var saved := source.settings.save_file(settings_path) == OK
 var restored := InputSettings.new()
 restored.load_file(settings_path)
 check(saved and restored.drift_button == JOY_BUTTON_X and restored.drift_modifier == JOY_BUTTON_LEFT_STICK and restored.retrograde_button == JOY_BUTTON_BACK, "advanced controller bindings persist")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))
 source.settings.retrograde_button = JOY_BUTTON_LEFT_SHOULDER
 source.settings.apply_advanced_bindings()
 Input.parse_input_event(button(JOY_BUTTON_LEFT_SHOULDER))
 source.sample_flight(command)
 check(command.rotation.z == 0 and source.advanced_consumes(button(JOY_BUTTON_LEFT_SHOULDER)), "retrograde rebound onto a roll button consumes its old manual function")
 Input.parse_input_event(button(JOY_BUTTON_LEFT_SHOULDER, false))
 source.queue_free()
 var ship := ShipPhysics.new()
 root.add_child(ship)
 await ticks(4)
 check(not ship.computer.drift_active and not ship.computer.retrograde_active, "flight computer advanced modes default OFF")
 for axis in range(3):
  for sign_value: float in [-1.0, 1.0]:
   await reset(ship)
   ship.command.translation[axis] = sign_value
   await ticks(3)
   var expected: float = ship.rcs_thrust_n
   if axis == 2: expected = ship.forward_rcs_thrust_n if sign_value < 0 else ship.reverse_thrust_n
   check(absf(ship.computer.force_local[axis] - sign_value * expected) < 1, "signed asymmetric force axis %d sign %.0f" % [axis, sign_value])
   check(absf(ship.acceleration_local[axis] - sign_value * expected / ship.mass) < 0.001, "actual acceleration follows rated force axis %d sign %.0f" % [axis, sign_value])
 await reset(ship)
 ship.command.main_engine = 1
 await ticks(3)
 check(absf(ship.acceleration_local.z + 20) < 0.001, "main engine remains 2.4 MN / 20 m/s²")
 ship.command.translation.z = -1
 await ticks(3)
 check(absf(ship.acceleration_local.z + 20) < 0.001 and ship.negative_force_limits.z == 0, "simultaneous main and forward RCS cannot exceed forward cap")
 await reset(ship)
 ship.linear_velocity = Vector3(15, -8, -12)
 await ticks(3)
 var initial := ship.linear_velocity
 await ticks(180)
 check(ship.linear_velocity.distance_to(initial) < 0.001 and ship.computer.force_local == Vector3.ZERO, "no automatic lateral drift correction without held command")
 ship.command.rotation.y = 0.6
 await ticks(120)
 check(ship.linear_velocity.distance_to(initial) < 0.001 and ship.computer.force_local == Vector3.ZERO, "turning alone never enables drift cancellation")
 await reset(ship)
 ship.linear_velocity = Vector3(15, -8, -12)
 await ticks(3)
 initial = ship.linear_velocity
 var pose := ship.transform
 ship.command.drift_cancel = true
 check(ship.linear_velocity == initial and ship.transform == pose, "drift command cannot teleport pose or velocity")
 await ticks(360)
 check(Vector2(ship.linear_velocity.x, ship.linear_velocity.y).length() < 0.05, "held command removes X/Y drift")
 check(absf(ship.linear_velocity.z + 12) < 0.001 and ship.computer.force_local.z == 0, "drift cancellation never corrects local Z")
 ship.command.drift_cancel = false
 await ticks(3)
 initial = ship.linear_velocity
 await ticks(60)
 check(ship.computer.automatic_force_local == Vector3.ZERO and not ship.computer.drift_active and ship.linear_velocity.distance_to(initial) < 0.001, "after release no lateral correcting force remains")
 await reset(ship)
 ship.linear_velocity = Vector3(15, 8, -10)
 ship.command.drift_cancel = true
 ship.command.translation.x = 0.5
 await ticks(3)
 check(ship.computer.force_local.x > 0 and ship.computer.automatic_force_local.x == 0 and ship.computer.active_brake_axes.x == 0, "manual lateral thrust wins over drift cancellation on same axis")
 check(ship.computer.automatic_force_local.y < 0 and ship.computer.drift_eta < 0, "orthogonal drift still brakes; ETA reports blocked manual axis")
 check(FlightComputer.normalized_force(ship.computer.force_local, ship.negative_force_limits, ship.positive_force_limits).length() <= 1.00001 and absf(ship.computer.manual_force_local.x - 600000) < 1, "directional ellipsoid allocation preserves manual force and caps shared budget")
 ship.command.translation = Vector3.FORWARD
 ship.command.main_engine = 1
 await ticks(2)
 check(ship.computer.automatic_force_local.x < 0 and ship.negative_force_limits.z == 0, "fully allocated main engine does not spend unavailable forward RCS budget")
 await reset(ship)
 ship.linear_velocity = Vector3(10, 0, 0)
 ship.command.drift_cancel = true
 ship.command.rotation.y = 0.5
 await ticks(80)
 var local_velocity := ship.global_basis.inverse() * ship.linear_velocity
 check(absf(ship.computer.drift_vector.x - local_velocity.x) < 0.1 and ship.computer.force_local.z == 0, "drift components recalculate continuously during rotation")
 # Reproducible 90-degree curve: coast while turning, then held C + forward burn.
 await reset(ship)
 ship.linear_velocity = Vector3.FORWARD * 40
 await ticks(3)
 initial = ship.linear_velocity
 ship.computer.target_attitude = Quaternion(Vector3.UP, PI / 2)
 ship.computer.attitude_hold = true
 var start := ship.tick
 var turn_seconds: float = -1
 for i in range(600):
  await ticks(1)
  if ship.basis.get_rotation_quaternion().angle_to(ship.computer.target_attitude) < deg_to_rad(0.5) and ship.angular_velocity.length() < deg_to_rad(0.5):
   turn_seconds = float(ship.tick - start) / 60
   break
 check(turn_seconds > 0 and ship.linear_velocity.distance_to(initial) < 0.001 and not ship.computer.drift_active, "90-degree coast turn preserves inertial velocity without drift command")
 var initial_cross := Vector2(ship.local_velocity().x, ship.local_velocity().y).length()
 ship.command.drift_cancel = true
 ship.command.main_engine = 1
 start = ship.tick
 var drift_seconds: float = -1
 var max_delta_v: float = 0
 var previous_v := ship.linear_velocity
 for i in range(900):
  await ticks(1)
  max_delta_v = maxf(max_delta_v, ship.linear_velocity.distance_to(previous_v))
  previous_v = ship.linear_velocity
  if Vector2(ship.local_velocity().x, ship.local_velocity().y).length() < 0.05:
   drift_seconds = float(ship.tick - start) / 60
   break
 check(drift_seconds > 0 and drift_seconds < 10 and absf(ship.local_velocity().z) > 50, "90-degree drift cancellation works while main engine accelerates new forward direction")
 check(max_delta_v < 0.6 and ship.computer.force_local.z == 0, "90-degree curve uses bounded forces without longitudinal auto-correction")
 print("MEASURE90 turn_seconds=", turn_seconds, " cross_initial_m_s=", initial_cross, " drift_seconds=", drift_seconds, " final_local_velocity=", ship.local_velocity(), " max_delta_v=", max_delta_v)
 # Autonomous retrograde: no direct target injection or automatic engine input.
 await reset(ship)
 ship.linear_velocity = Vector3.FORWARD * 30
 await ticks(3)
 initial = ship.linear_velocity
 pose = ship.transform
 var omega := ship.angular_velocity
 ship.computer.request_retrograde()
 check(ship.transform == pose and ship.angular_velocity == omega and ship.linear_velocity == initial, "retrograde request does not teleport physical state")
 start = ship.tick
 var retro_seconds: float = -1
 var peak_omega: float = 0
 var max_delta_omega: float = 0
 var previous_omega := ship.angular_velocity
 for i in range(720):
  await ticks(1)
  peak_omega = maxf(peak_omega, ship.angular_velocity.length())
  max_delta_omega = maxf(max_delta_omega, ship.angular_velocity.distance_to(previous_omega))
  previous_omega = ship.angular_velocity
  if ship.computer.retrograde_status.begins_with("ALIGNED"):
   retro_seconds = float(ship.tick - start) / 60
   break
 var alignment := (-ship.global_basis.z).dot(-initial.normalized())
 check(retro_seconds > 0 and retro_seconds < 10 and alignment > cos(deg_to_rad(2)), "automatic 180-degree retrograde aligns and brakes angular velocity")
 check(ship.command.main_engine == 0 and ship.applied_main_thrust_n == 0 and ship.linear_velocity.distance_to(initial) < 0.001 and ship.computer.force_local == Vector3.ZERO, "retrograde never starts a burn or changes linear velocity")
 check(max_delta_omega < 0.007 and ship.angular_velocity.length() < deg_to_rad(2), "retrograde angular changes respect physical torque bound")
 print("MEASURE180 complete_seconds=", retro_seconds, " error_deg=", rad_to_deg(acos(clampf(alignment,-1,1))), " final_rate_deg_s=", rad_to_deg(ship.angular_velocity.length()), " peak_deg_s=", rad_to_deg(peak_omega), " max_delta_omega=", max_delta_omega)
 await ticks(180)
 check(ship.applied_main_thrust_n == 0 and ship.linear_velocity.distance_to(initial) < 0.001 and ship.angular_velocity.length() < 0.001, "completed retrograde continues settling without ever auto-burning")
 ship.computer.reference_velocity = ship.linear_velocity - Vector3.BACK * 10
 await ticks(1)
 check(not ship.computer.retrograde_active and ship.computer.retrograde_status.contains("TARGET CHANGED"), "completed maneuver does not silently retarget when reference direction changes")
 await reset(ship)
 ship.computer.request_retrograde()
 await ticks(3)
 check(ship.computer.retrograde_status.contains("LOW SPEED") and not ship.computer.retrograde_active and not ship.computer.attitude_hold, "retrograde safely inhibits near zero speed")
 await reset(ship)
 ship.linear_velocity = Vector3.FORWARD * 30
 ship.computer.request_retrograde()
 await ticks(5)
 ship.command.rotation.x = 0.2
 await ticks(1)
 check(not ship.computer.retrograde_active and not ship.computer.attitude_hold and ship.computer.retrograde_status.contains("MANUAL"), "manual rotation aborts retrograde at the next fixed tick")
 await reset(ship)
 ship.linear_velocity = Vector3.FORWARD * 30
 ship.computer.request_retrograde()
 await ticks(5)
 ship.linear_velocity = Vector3.ZERO
 await ticks(1)
 check(not ship.computer.retrograde_active and ship.computer.retrograde_status.contains("LOW SPEED"), "loss of relative speed during maneuver safely cancels targeting")
 await reset(ship)
 ship.computer.reference_velocity = Vector3(7, 2, -9)
 ship.linear_velocity = ship.computer.reference_velocity + Vector3.DOWN * 10
 ship.computer.request_retrograde()
 await ticks(1)
 var target_forward := -(Basis(ship.computer.target_attitude)).z
 check(target_forward.is_equal_approx(Vector3.UP) and ship.computer.target_attitude.is_finite(), "retrograde uses selected relative velocity and stable vertical-axis convention")
 var previous_target := ship.computer.target_attitude
 await ticks(1)
 check(absf(previous_target.dot(ship.computer.target_attitude)) > 0.999, "roll convention remains continuous for repeated velocity samples")
 ship.computer.reference_velocity = ship.linear_velocity - Vector3.LEFT * 10
 await ticks(1)
 check((-(Basis(ship.computer.target_attitude)).z).is_equal_approx(Vector3.RIGHT), "reference-frame changes are included in active retrograde targeting")
 ship.queue_free()
 await process_frame
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.pause_menu.save_settings_on_close = false
 game.input_source.settings.drift_modifier = -1
 game.input_source.settings.apply_advanced_bindings()
 game.crew.position = Vector3(0,1,-12)
 var event := InputEventAction.new()
 event.pressed = true
 event.action = "interact"
 game._unhandled_input(event)
 Input.action_press("drift_cancel")
 game.ship.linear_velocity = Vector3(5, 2, -10)
 await ticks(4)
 check(game.instruments.snapshot.drift_active and game.instruments.snapshot.drift_vector.length() > 0 and game.instruments.snapshot.negative_limits.x == 1200000, "cockpit observes actual drift and asymmetric capability telemetry")
 Input.action_release("drift_cancel")
 await ticks(3)
 check(not game.instruments.snapshot.drift_active, "cockpit reports drift assist OFF after release")
 event.action = "retrograde"
 game._unhandled_input(event)
 await ticks(3)
 check(game.instruments.snapshot.retrograde_active, "retrograde keyboard command reaches simulation and cockpit telemetry")
 game.pause_menu.set_paused(true)
 game.pause_menu.advanced_panel.show()
 game.pause_menu.panel.hide()
 var focus: Control = game.pause_menu.advanced_panel.find_next_valid_focus()
 check(focus != null, "controller bindings panel provides focusable controls")
 focus.grab_focus()
 await press(JOY_BUTTON_A)
 await press(JOY_BUTTON_DPAD_UP)
 await press(JOY_BUTTON_DPAD_UP)
 await press(JOY_BUTTON_A)
 check(game.input_source.settings.drift_button == JOY_BUTTON_A and InputMap.event_is_action(button(JOY_BUTTON_A), "pad_drift_cancel"), "controller GUI freely rebinds held drift action")
 game.pause_menu.set_paused(false)
 Input.parse_input_event(button(JOY_BUTTON_A))
 await ticks(2)
 check(game.station.occupied and game.ship.command.drift_cancel, "rebound drift button takes precedence over conflicting seat interaction")
 Input.parse_input_event(button(JOY_BUTTON_A, false))
 game.pause_menu.leave_station_requested.emit()
 check(not game.station.occupied, "pause-menu exit preserves controller-only station access after rebinding")
 game.queue_free()
 await process_frame
 print("Advanced checks complete; checks=", checks, "; failures=", failures)
 quit(1 if failures else 0)
