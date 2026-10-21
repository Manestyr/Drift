extends SceneTree

var failures: int = 0

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool, message: String) -> void:
 if ok:
  print("PASS: ", message)
 else:
  failures += 1
  push_error("FAIL: " + message)

func action(game: Node, name: String) -> void:
 var event := InputEventAction.new()
 event.action = name
 event.pressed = true
 game._unhandled_input(event)

func ticks(count: int) -> void:
 for i in range(count):
  await physics_frame
 await process_frame

func run() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await ticks(60)
 var physical_w := InputEventKey.new()
 physical_w.physical_keycode = KEY_W
 physical_w.pressed = true
 check(InputMap.event_is_action(physical_w, "forward"), "physical W maps to forward")
 check(game.crew.is_on_floor(), "crew settles on local deck")
 var before: Vector3 = game.crew.position
 Input.action_press("back")
 await ticks(90)
 Input.action_release("back")
 check(game.crew.position.z > before.z + 4.0, "WASD walks through bridge doorway into corridor")
 Input.action_press("right")
 await ticks(120)
 Input.action_release("right")
 check(game.crew.position.x < 2.8, "local hull walls block crew")
 game.crew.position = Vector3(0, 1, -12)
 action(game, "interact")
 check(game.station.occupied and game.crew.seated and not game.interior_view.visible, "E enters seat and switches to pilot viewport")
 Input.action_press("main_engine")
 await ticks(60)
 Input.action_release("main_engine")
 check(game.ship.linear_velocity.length() > 15, "pilot input accelerates global rigid body")
 action(game, "exterior")
 check(game.outside_camera.current, "V activates exterior camera")
 action(game, "interact")
 check(not game.station.occupied and not game.crew.seated and game.interior_view.visible, "E exits seat and restores local first person")
 await ticks(3)
 var velocity: Vector3 = game.ship.linear_velocity
 await ticks(60)
 check(game.ship.linear_velocity.distance_to(velocity) < 0.001, "ship coasts after pilot leaves")
 check(game.crew.position.y > 0.8 and game.crew.position.y < 1.1, "crew stays on local deck during global flight")
 game.queue_free()
 await process_frame
 print("Workflow checks complete; failures=", failures)
 quit(1 if failures else 0)
