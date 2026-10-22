extends SceneTree

func _initialize() -> void:
 call_deferred("run")
func frames(count: int) -> void:
 for i in count: await process_frame
 await RenderingServer.frame_post_draw
func save_image(name: String) -> void:
 var picture := root.get_texture().get_image()
 assert(picture.save_png("res://docs/screenshots/crew-"+name+".png")==OK)
func run() -> void:
 if DisplayServer.get_name()=="headless":
  push_error("Real rendering display required")
  quit(1)
  return
 root.size = Vector2i(1280,720)
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await frames(50)
 save_image("bridge")
 for index in [1,2]:
  var console: CrewStation = game.stations[index]
  game.crew.position = console.position+Vector3(0,0,0.8)
  var event := InputEventAction.new()
  event.action="interact"
  event.pressed=true
  game._unhandled_input(event)
  game.sensors.tracking_enabled=true
  await frames(40)
  save_image(console.station_id)
  game._leave_pilot()
 game.crew.position=Vector3(0,1,-12)
 var pilot_event := InputEventAction.new()
 pilot_event.action="interact"
 pilot_event.pressed=true
 game._unhandled_input(pilot_event)
 game.station.set_secured(false)
 game.crew_safety.combat_requested=true
 await frames(6)
 save_image("pilot-safety")
 game._leave_pilot()
 game.crew.position=Vector3(0,1,8)
 game.crew.rotation=Vector3(0,PI,0)
 game.crew.camera.rotation.x=0
 await frames(5)
 save_image("engineering")
 game.queue_free()
 await process_frame
 quit()
