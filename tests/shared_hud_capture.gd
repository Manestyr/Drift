extends SceneTree
var game: Node
func _initialize() -> void: call_deferred("run")
func command(name: String) -> void:
 var event:=InputEventAction.new()
 event.action=name
 event.pressed=true
 game._unhandled_input(event)
 event.pressed=false
 game._unhandled_input(event)
func ticks(count: int) -> void:
 for frame in count:
  await physics_frame
  await process_frame
func enter(seat: CrewStation) -> void:
 if game.current_station()!=null: command("interact")
 game.crew.position=seat.position+Vector3(0,0,0.8)
 command("interact")
func capture(name: String) -> void:
 for frame in 12: await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png("res://docs/screenshots/shared-"+name+".png")==OK)
func run() -> void:
 if DisplayServer.get_name()=="headless":
  push_error("Actual graphical display required")
  quit(1)
  return
 root.size=Vector2i(1280,720)
 game=load("res://scenes/contact_alpha.tscn").instantiate()
 game.setup_seed=71
 root.add_child(game)
 game.pause_menu.save_settings_on_close=false
 game.input_source.settings.symbol_scheme=1
 game.input_source.using_gamepad=true
 await ticks(100)
 enter(game.stations[1])
 await capture("drone-controls")
 command("designation_context")
 game.sensors.selected_id="ALPHA"
 command("sensor_track")
 await capture("designation")
 enter(game.station)
 await capture("pilot-target")
 # Reproducible physical inbound fixture: poses/velocities are initialized once.
 # All HUD observations still come through the real mission sensor suite.
 var missiles: Array[MissileBody]=[]
 var starts: Array[Vector3]=[Vector3(120,40,-1100),Vector3(-130,30,-1200),Vector3(100,-40,-1000),Vector3(-80,20,1200)]
 for index in starts.size():
  var missile:=MissileBody.new()
  missile.name="HUD-IN%d"%(index+1)
  missile.team=1
  missile.target_id=String(game.ship.name)
  missile.targets=[game.ship]
  missile.position=starts[index]
  missile.linear_velocity=-starts[index].normalized()*170
  missile.thrust_n=0 # unpowered genuine incoming bodies, no synthetic HUD state
  game.ship.get_parent().add_child(missile)
  game.encounter.missiles.append(missile)
  missiles.append(missile)
 await ticks(65)
 enter(game.stations[1])
 command("designation_context")
 game.sensors.selected_id="HUD-IN4"
 command("combat_primary")
 await capture("priority-console")
 enter(game.station)
 await capture("multiple-threats")
 # Orbit only the camera, not the ship or hostile bodies.
 command("exterior")
 game.orbit.yaw=PI/2
 await capture("exterior-edge")
 # Sensor blackout: no new observations; real retained evidence ages out.
 game.ship.damage_model.health.sensors=0
 await ticks(45)
 await capture("uncertain")
 await ticks(65)
 await capture("expired")
 game.queue_free()
 await create_timer(0.3).timeout
 quit()
