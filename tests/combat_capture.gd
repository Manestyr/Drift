extends SceneTree

func _initialize() -> void: call_deferred("run")
func simulation_to(game: Node, seconds: float) -> void:
 RenderingServer.render_loop_enabled=false
 while game.encounter.elapsed<seconds and game.encounter.result=="ACTIVE":
  await physics_frame
  await process_frame
 RenderingServer.render_loop_enabled=true
func capture(name: String) -> void:
 for i in range(5): await process_frame
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 assert(picture.save_png("res://docs/screenshots/contact-"+name+".png")==OK)
func occupy(game: Node, index: int) -> void:
 game._leave_pilot()
 game.crew.position=game.stations[index].position+Vector3(0,0,0.8)
 var event := InputEventAction.new()
 event.action="interact"
 event.pressed=true
 game._unhandled_input(event)
func run() -> void:
 if DisplayServer.get_name()=="headless":
  push_error("Actual graphical renderer required")
  quit(1)
  return
 root.size=Vector2i(1280,720)
 var game = load("res://scenes/contact_alpha.tscn").instantiate()
 root.add_child(game)
 game.pause_menu.save_settings_on_close=false
 await simulation_to(game,12.5)
 occupy(game,2)
 await capture("weapons")
 game._leave_pilot()
 await simulation_to(game,15)
 occupy(game,1)
 await capture("drone")
 game._leave_pilot()
 occupy(game,2)
 game.observe_missile=true
 game.outside=true
 game._update_view()
 await capture("missile-flight")
 game.observe_missile=false
 game._leave_pilot()
 await simulation_to(game,60)
 await capture("victory")
 game.queue_free()
 await process_frame
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.pause_menu.set_paused(true)
 await capture("mode-menu")
 game.pause_menu.set_paused(false)
 game.queue_free()
 await process_frame
 quit()
