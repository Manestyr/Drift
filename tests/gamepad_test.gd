extends SceneTree

var failures: int = 0
var checks: int = 0

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool, message: String) -> void:
 checks += 1
 if ok:
  print("PASS: ", message)
 else:
  failures += 1
  push_error("FAIL: " + message)

func axis(index: JoyAxis, value: float) -> InputEventJoypadMotion:
 var event := InputEventJoypadMotion.new()
 event.axis = index
 event.axis_value = value
 event.device = 0
 return event

func button(index: JoyButton, pressed: bool = true) -> InputEventJoypadButton:
 var event := InputEventJoypadButton.new()
 event.button_index = index
 event.pressed = pressed
 event.device = 0
 return event

func ticks(count: int) -> void:
 for i in range(count):
  await physics_frame
 await process_frame

func press(index: JoyButton) -> void:
 Input.parse_input_event(button(index))
 await process_frame
 Input.parse_input_event(button(index, false))
 await process_frame

func clear_axes() -> void:
 for index: JoyAxis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y, JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
  Input.parse_input_event(axis(index, 0.0))

func run() -> void:
 Input.use_accumulated_input = false
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.pause_menu.save_settings_on_close = false
 var source: PlayerInput = game.input_source
 source.settings.deadzone = 0.15
 source.settings.sensitivity = 1.0
 source.settings.invert_y = false
 await ticks(10)
 check(PlayerInput.filter_stick(Vector2(0.08, -0.08), 0.15) == Vector2.ZERO, "radial stick drift below 0.15 yields zero")
 check(PlayerInput.filter_stick(Vector2(0.15, 0), 0.15) == Vector2.ZERO, "deadzone boundary yields zero")
 check(PlayerInput.filter_stick(Vector2(0.575, 0), 0.15).is_equal_approx(Vector2(0.5, 0)), "half usable stick travel yields half output")
 check(PlayerInput.filter_stick(Vector2.ONE, 0.15).length() <= 1.00001, "diagonal stick output is bounded")
 check(PlayerInput.filter_stick(Vector2(0.2, 0), 0.25) == Vector2.ZERO, "configured deadzone is respected")
 var buttons := {"interact": JOY_BUTTON_A, "exterior": JOY_BUTTON_Y, "pause": JOY_BUTTON_START,
  "pad_roll_left": JOY_BUTTON_LEFT_SHOULDER, "pad_roll_right": JOY_BUTTON_RIGHT_SHOULDER,
  "ui_accept": JOY_BUTTON_A, "ui_cancel": JOY_BUTTON_B, "ui_up": JOY_BUTTON_DPAD_UP,
  "ui_down": JOY_BUTTON_DPAD_DOWN, "ui_left": JOY_BUTTON_DPAD_LEFT, "ui_right": JOY_BUTTON_DPAD_RIGHT}
 for action: String in buttons:
  check(InputMap.event_is_action(button(buttons[action]), action), "Input Map button: " + action)
 var axes := {"pad_left_left": [JOY_AXIS_LEFT_X, -1.0], "pad_left_right": [JOY_AXIS_LEFT_X, 1.0],
  "pad_left_up": [JOY_AXIS_LEFT_Y, -1.0], "pad_left_down": [JOY_AXIS_LEFT_Y, 1.0],
  "pad_right_left": [JOY_AXIS_RIGHT_X, -1.0], "pad_right_right": [JOY_AXIS_RIGHT_X, 1.0],
  "pad_right_up": [JOY_AXIS_RIGHT_Y, -1.0], "pad_right_down": [JOY_AXIS_RIGHT_Y, 1.0],
  "pad_main": [JOY_AXIS_TRIGGER_RIGHT, 1.0], "pad_reverse": [JOY_AXIS_TRIGGER_LEFT, 1.0]}
 for action: String in axes:
  check(InputMap.event_is_action(axis(axes[action][0], axes[action][1]), action), "Input Map axis: " + action)
 source.observe(axis(JOY_AXIS_LEFT_X, 0.08))
 check(not source.using_gamepad, "stick drift does not switch active device")
 Input.parse_input_event(axis(JOY_AXIS_LEFT_X, 0.575))
 await process_frame
 check(source.using_gamepad and source.hints(true).contains("RT/R2"), "real mapped event switches adapter and HUD hints")
 var command := FlightCommand.new()
 source.sample_flight(command)
 check(is_equal_approx(command.rotation.y, -0.5), "partial left stick gives proportional yaw")
 source.settings.sensitivity = 0.5
 source.sample_flight(command)
 check(is_equal_approx(command.rotation.y, -0.25), "rotation sensitivity scales analog input")
 source.settings.sensitivity = 1.0
 clear_axes()
 Input.parse_input_event(axis(JOY_AXIS_LEFT_Y, -0.575))
 source.sample_flight(command)
 check(is_equal_approx(command.rotation.x, 0.5), "left stick up pitches up")
 source.settings.invert_y = true
 source.sample_flight(command)
 check(is_equal_approx(command.rotation.x, -0.5), "optional inversion reverses pilot pitch")
 clear_axes()
 Input.parse_input_event(axis(JOY_AXIS_RIGHT_Y, -0.575))
 check(source.camera_rate().y > 0.0, "optional inversion reverses crew look")
 source.settings.invert_y = false
 source.sample_flight(command)
 check(is_equal_approx(command.translation.y, 0.5), "right stick vertical gives proportional translation")
 clear_axes()
 Input.parse_input_event(axis(JOY_AXIS_TRIGGER_RIGHT, 0.5))
 source.sample_flight(command)
 check(command.main_engine > 0.4 and command.main_engine < 0.6, "RT is proportional, not digital")
 clear_axes()
 Input.parse_input_event(axis(JOY_AXIS_TRIGGER_LEFT, 0.5))
 source.sample_flight(command)
 check(command.translation.z > 0.4 and command.translation.z < 0.6 and command.main_engine == 0.0, "LT gives proportional reverse RCS only")
 clear_axes()
 Input.parse_input_event(button(JOY_BUTTON_LEFT_SHOULDER))
 source.sample_flight(command)
 check(command.rotation.z == 1.0, "LB rolls left")
 Input.parse_input_event(button(JOY_BUTTON_LEFT_SHOULDER, false))
 Input.parse_input_event(button(JOY_BUTTON_RIGHT_SHOULDER))
 source.sample_flight(command)
 check(command.rotation.z == -1.0, "RB rolls right")
 Input.parse_input_event(button(JOY_BUTTON_RIGHT_SHOULDER, false))
 Input.parse_input_event(axis(JOY_AXIS_LEFT_X, 0.08))
 Input.parse_input_event(axis(JOY_AXIS_RIGHT_Y, -0.08))
 Input.parse_input_event(axis(JOY_AXIS_TRIGGER_RIGHT, 0.03))
 source.sample_flight(command)
 check(command.translation == Vector3.ZERO and command.rotation == Vector3.ZERO and command.main_engine == 0.0, "neutral plus drift produces no force or torque")
 clear_axes()
 var before: Vector3 = game.crew.position
 Input.parse_input_event(axis(JOY_AXIS_LEFT_Y, 0.7))
 await ticks(30)
 check(game.crew.position.z > before.z + 0.8, "controller walks crew using mapped left stick")
 clear_axes()
 var yaw: float = game.crew.rotation.y
 Input.parse_input_event(axis(JOY_AXIS_RIGHT_X, 0.7))
 await ticks(15)
 check(game.crew.rotation.y < yaw - 0.1, "controller right stick looks with physics-delta scaling")
 clear_axes()
 game.crew.position = Vector3(0, 1, -12)
 await press(JOY_BUTTON_A)
 check(game.station.occupied and game.crew.seated, "A enters pilot seat through event routing")
 Input.parse_input_event(axis(JOY_AXIS_TRIGGER_RIGHT, 0.5))
 await ticks(60)
 check(game.ship.linear_velocity.length() > 8.0 and game.ship.linear_velocity.length() < 12.0, "half trigger produces approximately half main acceleration")
 clear_axes()
 await ticks(3)
 var velocity: Vector3 = game.ship.linear_velocity
 Input.parse_input_event(axis(JOY_AXIS_LEFT_X, 0.575))
 await ticks(60)
 check(game.ship.linear_velocity.distance_to(velocity) < 0.001, "controller rotation preserves existing world velocity")
 clear_axes()
 await ticks(3)
 velocity = game.ship.linear_velocity
 await ticks(30)
 check(game.ship.linear_velocity.distance_to(velocity) < 0.001, "neutral controller preserves inertial flight")
 await press(JOY_BUTTON_Y)
 check(game.outside_camera.current, "Y switches exterior camera")
 await press(JOY_BUTTON_START)
 check(paused and game.pause_menu.panel.visible and game.pause_menu.resume.has_focus(), "Start pauses and focuses Resume")
 var tick_before: int = game.ship.tick
 for i in range(6):
  await process_frame
 check(game.ship.tick == tick_before, "pause freezes the flight simulation")
 await press(JOY_BUTTON_DPAD_DOWN)
 var focused := root.gui_get_focus_owner()
 check(focused is HSlider, "D-pad navigates to deadzone slider")
 var previous: float = source.settings.deadzone
 await press(JOY_BUTTON_DPAD_RIGHT)
 check(source.settings.deadzone > previous, "D-pad adjusts settings")
 await press(JOY_BUTTON_B)
 check(not paused and not game.pause_menu.panel.visible, "B resumes gameplay")
 await press(JOY_BUTTON_START)
 await press(JOY_BUTTON_A)
 check(not paused, "A activates focused Resume without entering/exiting seat")
 check(game.station.occupied, "menu confirm does not leak to station interaction")
 await press(JOY_BUTTON_START)
 for i in range(3):
  await press(JOY_BUTTON_DPAD_DOWN)
 await press(JOY_BUTTON_A)
 check(source.settings.invert_y, "controller confirms Y inversion checkbox")
 await press(JOY_BUTTON_DPAD_DOWN)
 await press(JOY_BUTTON_A)
 await ticks(3)
 check(not paused and game.ship.linear_velocity.length() < 0.001 and game.ship.angular_velocity.length() < 0.001, "controller menu resets ship and resumes simulation")
 await press(JOY_BUTTON_A)
 check(not game.station.occupied, "A exits pilot seat")
 var key := InputEventKey.new()
 key.physical_keycode = KEY_W
 key.pressed = true
 source.observe(key)
 check(not source.using_gamepad and source.hints(false).contains("WASD"), "keyboard switches back with keyboard hints")
 source.observe(axis(JOY_AXIS_LEFT_X, 0.3))
 source._connection_changed(0, false)
 check(not source.using_gamepad, "disconnect returns to keyboard adapter")
 Input.parse_input_event(axis(JOY_AXIS_LEFT_X, 0.7))
 source.observe(key)
 source.sample_flight(command)
 check(command.rotation == Vector3.ZERO, "keyboard takeover ignores a still-deflected controller stick")
 source.observe(axis(JOY_AXIS_LEFT_X, 0.7))
 var motion := InputEventMouseMotion.new()
 motion.relative = Vector2(0.5, 0)
 source.observe(motion)
 check(source.using_gamepad, "tiny mouse motion does not flicker device hints")
 motion.relative = Vector2(8, 0)
 source.observe(motion)
 check(not source.using_gamepad, "intentional mouse motion switches input source")
 var settings := InputSettings.new()
 settings.deadzone = 0.22
 settings.sensitivity = 0.7
 settings.invert_y = true
 var path := "user://test_input_settings.cfg"
 check(settings.save_file(path) == OK, "settings can be persisted")
 var restored := InputSettings.new()
 restored.load_file(path)
 check(is_equal_approx(restored.deadzone, 0.22) and is_equal_approx(restored.sensitivity, 0.7) and restored.invert_y, "settings round-trip all controls")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 clear_axes()
 game.queue_free()
 await process_frame
 print("Gamepad checks complete; checks=", checks, "; failures=", failures)
 quit(1 if failures else 0)
