extends SceneTree

# Optional rendered acceptance aid: requires a real rendering driver/display.
# Run with --resolution 1280x720, not --headless.
func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 if DisplayServer.get_name() == "headless":
  push_error("Capture requires a graphical display, not --headless")
  quit(1)
  return
 root.size = Vector2i(1280, 720)
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.pause_menu.save_settings_on_close = false
 for i in range(20):
  await process_frame
 await RenderingServer.frame_post_draw
 var image := root.get_texture().get_image()
 if image == null or image.is_empty():
  push_error("A rendering driver is required for screenshots")
  quit(1)
  return
 image.save_png("res://docs/screenshots/bridge.png")
 game.crew.position = Vector3(0, 1, -12)
 var event := InputEventAction.new()
 event.action = "interact"
 event.pressed = true
 game._unhandled_input(event)
 game.ship.linear_velocity = Vector3(7, 0, -12)
 Input.action_press("left", 0.6)
 for i in range(30):
  await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/screenshots/cockpit.png")
 Input.action_release("left")
 Input.action_press("brake_all")
 for i in range(12):
  await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/screenshots/braking.png")
 Input.action_release("brake_all")
 game.queue_free()
 await process_frame
 quit()
