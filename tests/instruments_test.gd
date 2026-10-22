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

func action(game: Node, name: String) -> void:
 var event := InputEventAction.new()
 event.action = name
 event.pressed = true
 game._unhandled_input(event)

func run() -> void:
 Input.use_accumulated_input = false
 root.size = Vector2i(1280, 720)
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.pause_menu.save_settings_on_close = false
 await ticks(4)
 var cockpit: CockpitInstruments = game.instruments
 var ship: ShipPhysics = game.ship
 check(not game.hud.visible and not game.debug_panel.visible and not game.nose_hint.visible, "debug text and old HUD hidden on startup")
 check(cockpit.viewports.size() == 3 and cockpit.screens.size() == 3, "three independent viewports mounted on actual cockpit meshes")
 for i in range(3):
  check(cockpit.viewports[i].size == Vector2i(512, 448) and cockpit.screens[i].material_override.albedo_texture == cockpit.viewports[i].get_texture(), "screen texture and resolution: " + str(i))
 game.crew.position = Vector3(0, 1, -12)
 action(game, "interact")
 check(game.station.occupied and game.pilot_camera.current, "pilot camera remains functional with cockpit")
 for i in range(3):
  var screen := cockpit.screens[i]
  var minimum := Vector2.INF
  var maximum := -Vector2.INF
  for x: float in [-0.525, 0.525]:
   for y: float in [-0.46, 0.46]:
    var point: Vector2 = game.pilot_camera.unproject_position(screen.global_transform * Vector3(x, y, 0))
    minimum = minimum.min(point)
    maximum = maximum.max(point)
  check(minimum.x > 0 and minimum.y > 0 and maximum.x < 1280 and maximum.y < 720, "all four display corners in 1280x720 pilot frustum: " + str(i))
  check((maximum - minimum).x > 270 and (maximum - minimum).y > 240, "display large enough for at least ~14 pixel body text: " + str(i))
  print("SCREEN ", i, " pixels ", minimum, " -> ", maximum)
 check(cockpit.navigation.last_tick == cockpit.propulsion.last_tick and cockpit.propulsion.last_tick == cockpit.computer.last_tick and cockpit.sample_count > 0, "all instruments share the same fixed-tick snapshot")
 var data := ShipTelemetry.new()
 data.tick = 1234
 data.orientation = Basis(Vector3.UP, PI / 2)
 data.velocity_world = Vector3.RIGHT * 5
 data.velocity_local = data.orientation.inverse() * data.velocity_world
 data.relative_velocity_world = data.velocity_world
 data.acceleration_world = Vector3.FORWARD * 2
 data.acceleration_local = data.orientation.inverse() * data.acceleration_world
 check(data.navigation_velocity(false).is_equal_approx(Vector3(0, 0, 5)), "world velocity is correctly rotated into ship coordinates")
 check(data.navigation_forward(true).is_equal_approx(Vector3.LEFT) and data.navigation_forward(false) == Vector3.FORWARD, "forward arrow follows orientation only in inertial display")
 check(data.navigation_acceleration(false).is_equal_approx(Vector3.RIGHT * 2), "acceleration arrow is transformed independently of velocity")
 var pose := ship.transform
 var velocity := ship.linear_velocity
 cockpit.refresh(data)
 check(ship.transform == pose and ship.linear_velocity == velocity, "instrument updates do not mutate physical state")
 check(cockpit.navigation.displayed_vectors[1].is_equal_approx(Vector3(0, 0, 5)) and cockpit.propulsion.last_tick == 1234, "navigation geometry and reusable displays consume snapshot")
 cockpit.navigation.inertial_frame = true
 cockpit.refresh(data)
 check(cockpit.navigation.displayed_vectors[1] == Vector3.RIGHT * 5, "inertial display mode updates actual arrow direction")
 cockpit.navigation.inertial_frame = false
 ship.computer.rotation_stabilization = false
 ship.linear_velocity = Vector3(5, 0, 0)
 await ticks(8)
 var sampled: ShipTelemetry = cockpit.snapshot
 check(sampled.velocity_local.x > 4.9 and sampled.acceleration_world.length() < 0.0001, "neutral thrust preserves velocity with zero acceleration telemetry")
 check(not cockpit.navigation.arrows[2].visible and cockpit.navigation.arrows[1].visible, "neutral acceleration hides green arrow while orange drift arrow remains")
 Input.action_press("left")
 await ticks(8)
 sampled = cockpit.snapshot
 check(sampled.acceleration_local.x < -1.9 and sampled.rcs_translation.x < -0.99, "counter-thrust updates actual acceleration and RCS direction")
 check(sampled.auto_translation.length() < 0.0001, "manual thrust is not mislabeled as computer countersteering")
 Input.action_release("left")
 Input.action_press("brake_all")
 await ticks(8)
 sampled = cockpit.snapshot
 check(sampled.auto_translation.x < 0 and sampled.brake_axes != Vector3.ZERO, "flight-computer countersteer visible in telemetry and instrument")
 check(cockpit.computer.telemetry.tick == sampled.tick and cockpit.propulsion.telemetry.tick == sampled.tick, "propulsion and flight computer update together while braking")
 Input.action_release("brake_all")
 ship.computer.reference_velocity = Vector3(0, 0, -20)
 await ticks(3)
 sampled = cockpit.snapshot
 check(sampled.relative_velocity_world.is_equal_approx(sampled.velocity_world - Vector3(0, 0, -20)), "selected inertial braking frame uses relative velocity without changing actual state")
 var n_key := InputEventKey.new()
 n_key.physical_keycode = KEY_N
 check(InputMap.event_is_action(n_key, "instrument_frame"), "physical N key maps to instrument frame action")
 var inertial_before := cockpit.navigation.inertial_frame
 action(game, "instrument_frame")
 await ticks(3)
 check(cockpit.navigation.inertial_frame != inertial_before, "N presentation-frame switch is independent of physics reference")
 action(game, "debug")
 check(game.hud.visible and game.debug_panel.visible and game.hud.text.contains("P/Y/R"), "F3 preserves full technical telemetry")
 action(game, "debug")
 check(not game.hud.visible and not game.debug_panel.visible, "F3 hides all debug panels again")
 game.pause_menu.set_paused(true)
 game.pause_menu._open_computer()
 game.pause_menu.nav_toggle.grab_focus()
 var was_inertial := cockpit.navigation.inertial_frame
 var confirm := InputEventJoypadButton.new()
 confirm.button_index = JOY_BUTTON_A
 confirm.pressed = true
 Input.parse_input_event(confirm)
 await process_frame
 confirm = confirm.duplicate()
 confirm.pressed = false
 Input.parse_input_event(confirm)
 await process_frame
 check(cockpit.navigation.inertial_frame != was_inertial, "controller GUI confirm toggles navigation axes without requiring keyboard")
 game.pause_menu.set_paused(false)
 var source: PlayerInput = game.input_source
 source.settings.mouse_flight_sensitivity = 0.5
 source.clear_mouse()
 source.add_flight_mouse(Vector2(40, 0))
 var low := source.mouse_steer.length()
 source.settings.mouse_flight_sensitivity = 1.0
 source.clear_mouse()
 source.add_flight_mouse(Vector2(40, 0))
 check(is_equal_approx(source.mouse_steer.length(), low * 2), "mouse flight sensitivity is proportional and configurable")
 var settings := InputSettings.new()
 settings.mouse_flight_sensitivity = 0.7
 var path := "user://instrument_test_settings.cfg"
 var saved := settings.save_file(path) == OK
 var restored := InputSettings.new()
 restored.load_file(path)
 check(saved and is_equal_approx(restored.mouse_flight_sensitivity, 0.7), "mouse sensitivity persists without changing existing settings contract")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 game.queue_free()
 await process_frame
 print("Instrument checks complete; checks=", checks, "; failures=", failures)
 quit(1 if failures else 0)
