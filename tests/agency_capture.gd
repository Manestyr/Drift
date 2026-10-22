extends SceneTree
func _initialize() -> void: call_deferred("run")
func action(game: Node,name: String) -> void:
 var event:=InputEventAction.new()
 event.action=name
 event.pressed=true
 game._unhandled_input(event)
 event.pressed=false
 game._unhandled_input(event)
func to_time(game: Node, time: float) -> void:
 RenderingServer.render_loop_enabled=false
 while game.encounter.elapsed<time and game.encounter.result=="ACTIVE":
  await physics_frame
  await process_frame
 RenderingServer.render_loop_enabled=true
func capture(name: String) -> void:
 for i in range(5): await process_frame
 await RenderingServer.frame_post_draw
 var picture:=root.get_texture().get_image()
 assert(picture.save_png("res://docs/screenshots/agency-"+name+".png")==OK)
func run() -> void:
 if DisplayServer.get_name()=="headless":
  push_error("Graphical display required")
  quit(1)
  return
 root.size=Vector2i(1280,720)
 var menu=load("res://scenes/mission_setup.tscn").instantiate()
 root.add_child(menu)
 await capture("mission-menu")
 menu.mode.select(CombatProfile.Mode.ASSISTED_SOLO)
 menu._mode_changed(CombatProfile.Mode.ASSISTED_SOLO)
 await capture("assisted-consent")
 menu.queue_free()
 await process_frame
 var game=load("res://scenes/contact_alpha.tscn").instantiate()
 game.setup_seed=71
 root.add_child(game)
 await to_time(game,0.6)
 game.crew.position=game.stations[2].position+Vector3(0,0,0.8)
 action(game,"interact")
 action(game,"sensor_track")
 action(game,"combat_down")
 await to_time(game,3.6)
 await capture("weapon-ready")
 action(game,"combat_primary")
 await to_time(game,4.2)
 await capture("missile-ordered")
 game._leave_pilot()
 game.crew.position=game.stations[1].position+Vector3(0,0,0.8)
 action(game,"interact")
 action(game,"combat_up")
 await to_time(game,6)
 await capture("drone-escort")
 action(game,"combat_primary")
 await to_time(game,14)
 await capture("drone-defend")
 game.queue_free()
 await process_frame
 quit()
