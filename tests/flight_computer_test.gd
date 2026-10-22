extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool, message: String) -> void:
 checks += 1
 if ok:
  print("PASS: ", message)
 else:
  failures += 1
  push_error("FAIL: " + message)

func ticks(count: int) -> void:
 for i in range(count):
  await physics_frame
 await process_frame

func release_actions() -> void:
 for name: StringName in InputMap.get_actions():
  Input.action_release(name)

func key(code: Key, pressed: bool = true) -> InputEventKey:
 var event := InputEventKey.new()
 event.physical_keycode = code
 event.pressed = pressed
 return event

func press_button(index: JoyButton) -> void:
 var event := InputEventJoypadButton.new()
 event.button_index = index
 event.pressed = true
 Input.parse_input_event(event)
 await process_frame
 event = event.duplicate()
 event.pressed = false
 Input.parse_input_event(event)
 await process_frame

func run() -> void:
 Input.use_accumulated_input = false
 var source := PlayerInput.new()
 root.add_child(source)
 var command := FlightCommand.new()
 check(InputMap.event_is_action(key(KEY_F), "interact") and not InputMap.event_is_action(key(KEY_E), "interact"), "F interacts; E no longer triggers station")
 check(InputMap.event_is_action(key(KEY_E), "roll_right") and InputMap.event_is_action(key(KEY_SHIFT), "down"), "E rolls and Shift translates down")
 source.add_flight_mouse(Vector2(80, -40))
 source.sample_flight(command)
 check(command.rotation.y < 0 and command.rotation.x > 0 and command.rotation.length() <= 1.0, "mouse requests bounded pitch/yaw torque")
 for i in range(60):
  source.sample_flight(command)
 check(command.rotation == Vector3.ZERO, "mouse virtual stick recenters without body damping")
 for combo: String in ["forward", "left", "up", "brake_roll"]:
  Input.action_press("flight_modifier")
  Input.action_press(combo)
  Input.action_press("main_engine")
  source.add_flight_mouse(Vector2(100, 50))
  source.sample_flight(command)
  check(command.translation == Vector3.ZERO and command.rotation == Vector3.ZERO and command.main_engine == 0.0 and source.mouse_steer == Vector2.ZERO and (command.brake_axes != Vector3.ZERO or command.brake_roll), "modifier consumes normal thrust/mouse: " + combo)
  release_actions()
 source.clear_mouse()
 Input.parse_input_event(key(KEY_CTRL))
 var modified_w := key(KEY_W)
 modified_w.ctrl_pressed = true
 Input.parse_input_event(modified_w)
 Input.flush_buffered_events()
 source.sample_flight(command)
 check(command.brake_axes.z == 1 and command.translation == Vector3.ZERO, "physical Ctrl+W events trigger braking instead of thrust")
 Input.parse_input_event(key(KEY_W, false))
 Input.parse_input_event(key(KEY_CTRL, false))
 release_actions()
 source.using_gamepad = true
 source.settings.computer_layout = 0
 source.settings.brake_mode = 0
 Input.action_press("pad_fc_down")
 source.sample_flight(command)
 check(command.brake_all, "default controller D-pad brake does not remap flight axes")
 source.settings.brake_mode = 2
 source.sample_flight(command)
 check(command.brake_axes == Vector3.RIGHT and not command.brake_all, "controller brake axis is configurable")
 release_actions()
 source.settings.computer_layout = 1
 Input.action_press("pad_fc_up")
 source.sample_flight(command)
 check(command.brake_axes == Vector3.RIGHT, "alternate controller computer layout works")
 source.orbiting = true
 Input.action_press("pad_main", 0.7)
 Input.action_press("pad_right_right", 0.7)
 source.sample_flight(command)
 check(command.main_engine == 0.0 and command.translation == Vector3.ZERO, "explicit controller orbit modifier consumes zoom/translation controls")
 source.set_orbit_mode(false)
 source.sample_flight(command)
 check(command.main_engine == 0.0 and command.translation == Vector3.ZERO, "leaving orbit requires neutral before held zoom controls can thrust")
 release_actions()
 source.sample_flight(command)
 Input.action_press("pad_main", 0.7)
 source.sample_flight(command)
 check(command.main_engine > 0.6, "flight throttle re-arms after neutral orbit controls")
 release_actions()
 var saved := InputSettings.new()
 saved.computer_layout = 1
 saved.brake_mode = 4
 var settings_path := "user://computer_test_settings.cfg"
 var saved_ok := saved.save_file(settings_path) == OK
 var restored := InputSettings.new()
 restored.load_file(settings_path)
 check(saved_ok and restored.computer_layout == 1 and restored.brake_mode == 4, "controller computer layout and brake selection persist")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))
 source.queue_free()
 var ship := ShipPhysics.new()
 root.add_child(ship)
 await ticks(4)
 check(ship.effective_inertia.distance_to(ship.inertia) < 5.0, "Godot effective principal inertia matches declared 36 m hull")
 print("MEASURE inertia kg m²: ", ship.effective_inertia, " | torque limits Nm: ", ship.torque_limits_nm)
 var mouse_source := PlayerInput.new()
 root.add_child(mouse_source)
 var untouched_pose := ship.transform
 var untouched_rate := ship.angular_velocity
 mouse_source.add_flight_mouse(Vector2(100, -30))
 mouse_source.sample_flight(ship.command)
 check(ship.transform == untouched_pose and ship.angular_velocity == untouched_rate, "mouse command never writes physical pose or angular velocity")
 await ticks(3)
 check(ship.angular_velocity.length() > 0 and ship.angular_velocity.length() < 0.05, "mouse command turns body through bounded physics torque")
 mouse_source.queue_free()
 ship.reset_requested = true
 await ticks(4)
 ship.linear_velocity = Vector3(4, 3, -6)
 await ticks(3)
 var initial := ship.linear_velocity
 var pose := ship.transform
 ship.command.brake_axes = Vector3(0, 0, 1)
 check(ship.linear_velocity == initial and ship.transform == pose, "enabling brake does not teleport velocity or pose")
 await ticks(300)
 check(absf(ship.linear_velocity.z) < 0.08 and absf(ship.linear_velocity.x - 4) < 0.001 and absf(ship.linear_velocity.y - 3) < 0.001, "local Z braking leaves orthogonal inertial components unchanged")
 for axis in range(2):
  ship.command.clear()
  ship.linear_velocity = Vector3(3, 3, 0)
  await ticks(3)
  initial = ship.linear_velocity
  ship.command.brake_axes[axis] = 1.0
  await ticks(1)
  check(ship.linear_velocity.distance_to(initial) < 0.07, "braking changes velocity by bounded force per tick, axis " + str(axis))
  await ticks(240)
  check(absf(ship.linear_velocity[axis]) < 0.04 and absf(ship.linear_velocity[1 - axis] - 3.0) < 0.001, "isolated local component braking, axis " + str(axis))
 ship.command.brake_all = true
 ship.computer.reference_velocity = Vector3(1, -1, 2)
 await ticks(360)
 check(ship.linear_velocity.distance_to(ship.computer.reference_velocity) < 0.08, "full brake converges to selected moving inertial frame")
 check(ship.computer.brake_progress > 0.98 and ship.computer.brake_eta < 0.5, "brake telemetry reports progress and settling ETA")
 ship.command.translation.x = 1
 ship.command.main_engine = 1
 await ticks(1)
 check(ship.computer.active_brake_axes.x == 0 and ship.computer.active_brake_axes.z == 0 and ship.computer.force_local.x > 0, "manual thrust overrides computer on each affected axis")
 check(ship.computer.force_local.length() <= ship.rcs_thrust_n + 1, "manual and automatic forces respect shared RCS budget")
 ship.command.clear()
 ship.computer.reference_velocity = Vector3.ZERO
 ship.reset_requested = true
 await ticks(4)
 ship.angular_velocity = Vector3(0, 0, 0.7)
 ship.command.brake_roll = true
 await ticks(180)
 check(ship.angular_velocity.length() < 0.01, "roll brake settles using physical torque")
 ship.command.clear()
 ship.computer.rotation_stabilization = true
 ship.angular_velocity = Vector3(0.3, -0.4, 0.2)
 await ticks(240)
 check(ship.angular_velocity.length() < 0.002, "rotation stabilization settles all axes without artificial damping")
 ship.computer.capture_attitude(ship.basis)
 ship.command.rotation.x = 0.4
 await ticks(3)
 check(not ship.computer.attitude_hold and ship.computer.torque_local.x > 0, "manual rotation releases attitude hold and wins actuation")
 for axis in range(3):
  ship.command.clear()
  ship.reset_requested = true
  await ticks(4)
  ship.linear_velocity = Vector3(9, 3, -8)
  await ticks(3)
  initial = ship.linear_velocity
  var direction := Vector3.ZERO
  direction[axis] = 1.0
  var target := Quaternion(direction, PI)
  var initial_pose := ship.transform
  var initial_omega := ship.angular_velocity
  ship.computer.target_attitude = target
  ship.computer.attitude_hold = true
  check(ship.transform == initial_pose and ship.angular_velocity == initial_omega, "attitude command does not teleport body, axis " + str(axis))
  var start := ship.tick
  var stable: int = 0
  var settle_time: float = -1.0
  var peak_rate: float = 0.0
  var peak_error_after_settle: float = 0.0
  var max_step: float = 0.0
  var previous_omega := ship.angular_velocity
  for i in range(720):
   await ticks(1)
   var error := ship.basis.get_rotation_quaternion().angle_to(target)
   peak_rate = maxf(peak_rate, ship.angular_velocity.length())
   max_step = maxf(max_step, ship.angular_velocity.distance_to(previous_omega))
   previous_omega = ship.angular_velocity
   if error < deg_to_rad(2.0) and ship.angular_velocity.length() < deg_to_rad(2.0):
    stable += 1
   else:
    stable = 0
   if stable == 60 and settle_time < 0:
    settle_time = float(ship.tick - start - 59) / 60.0
   if settle_time > 0:
    peak_error_after_settle = maxf(peak_error_after_settle, error)
  check(settle_time > 0 and settle_time <= 10.0, "180 degree maneuver settles within 10 s, axis " + str(axis))
  check(peak_error_after_settle < deg_to_rad(2.1), "attitude controller stays settled without oscillations, axis " + str(axis))
  check(max_step < 0.03 and ship.linear_velocity.distance_to(initial) < 0.001, "angular changes obey torque bound and preserve world velocity, axis " + str(axis))
  print("MEASURE axis=", axis, " settle_seconds=", settle_time, " peak_deg_s=", rad_to_deg(peak_rate), " max_delta_omega=", max_step)
 ship.queue_free()
 await process_frame
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.pause_menu.save_settings_on_close = false
 await ticks(4)
 check(not game.arena.grid.visible, "tactical grid starts disabled")
 var event := InputEventAction.new()
 event.action = "grid"
 event.pressed = true
 game._unhandled_input(event)
 check(game.arena.grid.visible, "grid is toggleable")
 var clear_spawn := true
 for at: Vector3 in game.arena.obstacle_positions:
  clear_spawn = clear_spawn and at.length() > 120
 check(clear_spawn, "asteroids do not obstruct spawn and launch corridor")
 var space: PhysicsDirectSpaceState3D = game.ship.get_world_3d().direct_space_state
 var corridor := PhysicsRayQueryParameters3D.create(Vector3(0, 0, -30), Vector3(0, 0, -1500), 1)
 check(space.intersect_ray(corridor).is_empty(), "global collision geometry leaves the launch corridor unobstructed")
 var station_ray := PhysicsRayQueryParameters3D.create(Vector3(320, 0, -500), Vector3(320, 0, -750), 1)
 check(not space.intersect_ray(station_ray).is_empty(), "station wreck has effective global collisions")
 var old_camera: Vector3 = game.outside_camera.position
 game.orbit.turn(Vector2(0.5, 0.2))
 game.orbit.zoom(-0.3)
 game.orbit.update(game.outside_camera, game.ship.position)
 check(game.outside_camera.position.distance_to(old_camera) > 1 and game.orbit.distance < 80, "exterior camera orbits and zooms independently of body pose")
 game.crew.position = Vector3(0, 1, -12)
 event.action = "interact"
 game._unhandled_input(event)
 var mouse_event := InputEventMouseMotion.new()
 mouse_event.relative = Vector2(50, 30)
 var untouched: Transform3D = game.ship.transform
 game._unhandled_input(mouse_event)
 check(game.input_source.mouse_steer != Vector2.ZERO and game.ship.transform == untouched, "pilot mouse event routes to intent without changing body transform")
 event.action = "exterior"
 game._unhandled_input(event)
 check(game.input_source.mouse_steer == Vector2.ZERO, "camera context switch clears buffered flight mouse")
 var previous_orbit: float = game.orbit.yaw
 game._unhandled_input(mouse_event)
 check(game.input_source.mouse_steer == Vector2.ZERO and game.orbit.yaw != previous_orbit, "exterior mouse orbits instead of issuing flight torque")
 game.pause_menu.cycle_reference()
 check(game.ship.computer.reference_velocity == Vector3(0, 0, -20), "UI switches inertial braking frame")
 await press_button(JOY_BUTTON_START)
 for i in range(6):
  await press_button(JOY_BUTTON_DPAD_DOWN)
 await press_button(JOY_BUTTON_A)
 check(game.pause_menu.computer_panel.visible, "controller opens flight-computer settings submenu")
 for i in range(2):
  await press_button(JOY_BUTTON_DPAD_DOWN)
 await press_button(JOY_BUTTON_A)
 await press_button(JOY_BUTTON_DPAD_DOWN)
 await press_button(JOY_BUTTON_A)
 check(game.input_source.settings.computer_layout == 1, "controller configures alternate computer layout through GUI")
 await press_button(JOY_BUTTON_B)
 check(game.pause_menu.panel.visible and not game.pause_menu.computer_panel.visible, "B returns from computer settings to pause menu")
 await press_button(JOY_BUTTON_START)
 check(not paused, "Start resumes from computer settings workflow")
 game.pause_menu.set_paused(false)
 game.queue_free()
 await process_frame
 print("Flight computer checks complete; checks=", checks, "; failures=", failures)
 quit(1 if failures else 0)
