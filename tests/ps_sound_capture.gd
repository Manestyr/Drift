extends SceneTree
func _initialize() -> void: call_deferred("run")
func action(game: Node,name: String) -> void:
 var e:=InputEventAction.new()
 e.action=name
 e.pressed=true
 game._unhandled_input(e)
 e.pressed=false
 game._unhandled_input(e)
func advance(game: Node, seconds: float) -> void:
 while game.encounter.elapsed<seconds and game.encounter.result=="ACTIVE":
  await physics_frame
  await process_frame
func capture(name: String) -> void:
 # Allow two 10-Hz presentation refreshes and font/layout work after context changes.
 for i in 18: await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://docs/screenshots/ps-"+name+".png")==OK)
func run() -> void:
 if DisplayServer.get_name()=="headless":
  push_error("Real graphical renderer required")
  quit(1)
  return
 root.size=Vector2i(1280,720)
 var game=load("res://scenes/contact_alpha.tscn").instantiate()
 game.setup_seed=71
 root.add_child(game)
 game.pause_menu.save_settings_on_close=false
 game.input_source.settings.symbol_scheme=1
 game.input_source.using_gamepad=true
 # Warm the real viewport/font pipelines before inspecting the first console.
 await advance(game,2.0)
 game.crew.position=game.stations[2].position+Vector3(0,0,0.8)
 action(game,"interact")
 await capture("weapons-blocked")
 action(game,"sensor_track")
 action(game,"combat_down")
 await advance(game,4.7)
 await capture("weapons-ready")
 action(game,"combat_primary")
 await advance(game,5.6)
 await capture("launch")
 game._leave_pilot()
 game.crew.position=game.stations[1].position+Vector3(0,0,0.8)
 action(game,"interact")
 action(game,"combat_up")
 action(game,"combat_primary")
 await advance(game,8.5)
 await capture("drone")
 game._leave_pilot()
 game.crew.position=game.station.position+Vector3(0,0,0.8)
 action(game,"interact")
 await capture("pilot")
 game.pause_menu.set_paused(true)
 await capture("pause")
 game.pause_menu.panel.hide()
 game.pause_menu.settings_panel.show()
 var schema: OptionButton=game.pause_menu.settings_panel.find_children("","OptionButton",true,false)[0]
 schema.select(game.input_source.settings.symbol_scheme)
 game.pause_menu.settings_panel.find_next_valid_focus().grab_focus()
 await capture("audio-symbols")
 game.pause_menu.set_paused(false)
 game.encounter.disengage()
 await capture("disengage")
 await create_timer(0.4).timeout
 game.queue_free()
 await process_frame
 quit()
