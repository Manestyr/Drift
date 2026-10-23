extends SceneTree
func _initialize() -> void: call_deferred("run")
func command(game: Node,name: String) -> void:
 var e:=InputEventAction.new()
 e.action=name
 e.pressed=true
 game._unhandled_input(e)
 e.pressed=false
 game._unhandled_input(e)
func axis(index: int,value: float) -> void:
 var event:=InputEventJoypadMotion.new()
 event.axis=index
 event.axis_value=value
 Input.parse_input_event(event)
func advance(game: Node,seconds: float) -> void:
 while game.encounter.elapsed<seconds and game.encounter.result=="ACTIVE":
  await physics_frame
  await process_frame
func capture(name: String) -> void:
 for frame in 18: await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://docs/screenshots/tactical-"+name+".png")==OK)
func run() -> void:
 if DisplayServer.get_name()=="headless":
  push_error("Actual graphical display required")
  quit(1)
  return
 Input.use_accumulated_input=false
 root.size=Vector2i(1280,720)
 var game=load("res://scenes/contact_alpha.tscn").instantiate()
 game.setup_seed=71
 root.add_child(game)
 game.pause_menu.save_settings_on_close=false
 game.input_source.settings.symbol_scheme=1
 game.input_source.using_gamepad=true
 await advance(game,2)
 game.crew.position=game.stations[2].position+Vector3(0,0,0.8)
 command(game,"interact")
 command(game,"sensor_track")
 command(game,"combat_down")
 await advance(game,4.5)
 await capture("fire-control")
 command(game,"combat_primary")
 command(game,"tactical_map")
 await capture("map")
 var map: TacticalMap=game.weapon_map()
 map.selected_id="ALPHA"
 command(game,"sensor_track")
 map.orbit(Vector2(0.6,0.4),0.5)
 map.zoom(-0.35)
 await capture("map-focus")
 command(game,"ui_cancel")
 command(game,"combat_hold")
 await capture("missile-auto")
 command(game,"missile_manual")
 axis(JOY_AXIS_LEFT_X,0.5)
 axis(JOY_AXIS_TRIGGER_RIGHT,0.65)
 for frame in 20:
  await physics_frame
  await process_frame
 await capture("missile-manual")
 axis(JOY_AXIS_LEFT_X,0)
 axis(JOY_AXIS_TRIGGER_RIGHT,0)
 command(game,"ui_cancel")
 game._leave_pilot()
 game.crew.position=game.stations[1].position+Vector3(0,0,0.8)
 command(game,"interact")
 command(game,"combat_up")
 command(game,"combat_primary")
 await advance(game,10)
 await capture("drone")
 game.queue_free()
 await create_timer(1).timeout
 quit()
