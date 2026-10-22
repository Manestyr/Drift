extends SceneTree

# Optional rendered fixtures; never used by production flight code.
func _initialize() -> void:
 call_deferred("run")

func frames(count: int) -> void:
 for i in range(count): await process_frame
 await RenderingServer.frame_post_draw

func save_image(name: String) -> void:
 var image := root.get_texture().get_image()
 assert(image != null and not image.is_empty())
 assert(image.save_png("res://docs/screenshots/" + name + ".png") == OK)

func run() -> void:
 if DisplayServer.get_name() == "headless":
  push_error("Capture requires an actual rendering driver/display")
  quit(1)
  return
 root.size = Vector2i(1280, 720)
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.pause_menu.save_settings_on_close = false
 game.crew.position = Vector3(0, 1, -12)
 var event := InputEventAction.new()
 event.action = "interact"
 event.pressed = true
 game._unhandled_input(event)
 game.ship.linear_velocity = Vector3(12, 3, -20)
 Input.action_press("drift_cancel")
 Input.action_press("main_engine")
 await frames(30)
 save_image("advanced-drift")
 Input.action_release("drift_cancel")
 Input.action_release("main_engine")
 await frames(4)
 game.ship.linear_velocity = Vector3.FORWARD * 30
 game.ship.computer.request_retrograde()
 await frames(150)
 save_image("advanced-retrograde")
 game.pause_menu.set_paused(true)
 game.pause_menu.panel.hide()
 game.pause_menu.advanced_panel.show()
 await frames(3)
 save_image("advanced-bindings")
 game.pause_menu.set_paused(false)
 game.queue_free()
 await process_frame
 quit()
