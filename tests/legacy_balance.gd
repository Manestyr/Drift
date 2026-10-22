extends SceneTree

# Run this fixture with project path checked out at bf98faf, not current MANUAL code.
func _initialize() -> void: call_deferred("run")
func run() -> void:
 if ProjectSettings.get_setting("application/config/version")!="0.3":
  push_error("Legacy fixture requires a bf98faf / 0.3 project checkout")
  quit(1)
  return
 for support in ["full","no-drone","idle"]:
  for variant in range(2):
   var game=load("res://scenes/contact_alpha.tscn").instantiate()
   root.add_child(game)
   game.encounter.automatic_weapons=support!="idle"
   game.encounter.automatic_drone=support=="full"
   game.encounter.enemy.position+=Vector3(variant*40,variant*10,-variant*120)
   for i in range(7200):
    await physics_frame
    await process_frame
    if game.encounter.result!="ACTIVE": break
   var e=game.encounter
   var counts: Dictionary={}
   for entry in e.events.entries: counts[entry.type]=int(counts.get(entry.type,0))+1
   print("BASELINE ",JSON.stringify({"support":support,"variant":variant,"result":e.result,"seconds":snappedf(e.elapsed,0.01),"events":counts,"player_hull":game.ship.damage_model.health.hull,"enemy_hull":e.enemy.damage_model.health.hull}))
   game.queue_free()
   await process_frame
 quit()
