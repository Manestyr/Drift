class_name BalanceScenario
extends RefCounted

class PilotManeuver:
 extends Node
 var ship: ShipPhysics
 var lateral: bool = false
 var elapsed: float = 0.0
 func _physics_process(dt: float) -> void:
  elapsed+=dt
  if lateral: ship.command.translation=Vector3.RIGHT
  elif elapsed<4.0: ship.command.translation=Vector3.FORWARD
  elif elapsed>=10 and elapsed<13.333333: ship.command.translation=Vector3.BACK
  else: ship.command.translation=Vector3.ZERO


static func battle(tree: SceneTree, mode: int, difficulty: int, seed_value: int, plan: String = "idle") -> Dictionary:
 var game=load("res://scenes/contact_alpha.tscn").instantiate()
 game.setup_mode=mode
 game.setup_difficulty=difficulty
 game.setup_seed=seed_value
 game.setup_weapon_grant=mode==CombatProfile.Mode.ASSISTED_SOLO
 game.setup_drone_grant=mode==CombatProfile.Mode.ASSISTED_SOLO
 tree.root.add_child(game)
 game.pause_menu.save_settings_on_close=false
 var e: CombatEncounter=game.encounter
 if mode==CombatProfile.Mode.MANUAL and plan!="idle":
  var pilot:=PilotManeuver.new()
  pilot.ship=game.ship
  pilot.lateral=plan=="lateral"
  game.add_child(pilot)
 var last_fire: float=-4
 var pair_pending: float=-1
 var tracking_order: bool=false
 var deployed: bool=false
 var defense_order: bool=false
 for i in range(7200):
  # Explicit operator commands, never scripted hits or body-state corrections.
  if plan!="idle" or mode==CombatProfile.Mode.ASSISTED_SOLO:
   if mode==CombatProfile.Mode.MANUAL and not tracking_order and e.player_sensors.selected()!=null:
    e.player_sensors.toggle_tracking()
    e.player_launcher.armed=true
    tracking_order=true
   if mode==CombatProfile.Mode.MANUAL and pair_pending>=0 and e.elapsed>=pair_pending:
    e.player_launcher.selected_launcher=1-e.player_launcher.selected_launcher
    e.fire_player()
    pair_pending=-1
   if mode==CombatProfile.Mode.MANUAL and e.elapsed-last_fire>8:
    if e.player_launcher.ammunition[e.player_launcher.selected_launcher]<=0: e.player_launcher.selected_launcher=1-e.player_launcher.selected_launcher
    if e.fire_player()!=null:
     last_fire=e.elapsed
     pair_pending=e.elapsed+0.2
   if plan not in ["no-drone","lateral"] and not deployed and e.elapsed>3:
    deployed=e.deploy_drone()
    if deployed and plan=="bad-position": e.drone.assign_waypoint(Vector3(0,-30,900))
   if deployed and not defense_order and e.elapsed>3.2:
    e.drone.defense_enabled=true
    defense_order=true
  await tree.physics_frame
  await tree.process_frame
  if e.result!="ACTIVE": break
 var counts: Dictionary={}
 var friendly_hits: int=0
 var hostile_hits: int=0
 var blue_intercepts: int=0
 var red_intercepts: int=0
 for entry in e.events.entries:
  counts[entry.type]=int(counts.get(entry.type,0))+1
  if entry.type=="missile_hit":
   if String(entry.entity_id).begins_with("BLUE") and entry.payload.body_id=="ALPHA": friendly_hits+=1
   elif entry.payload.body_id=="DRIFT": hostile_hits+=1
  if entry.type=="intercept":
   if entry.payload.defender=="BLUE-D1": blue_intercepts+=1
   else: red_intercepts+=1
 var row: Dictionary={"mode":CombatProfile.MODE_NAMES[mode],"difficulty":CombatProfile.DIFFICULTY_NAMES[difficulty],"seed":seed_value,"plan":"granted-guard" if mode==CombatProfile.Mode.ASSISTED_SOLO and plan=="idle" else plan,"result":e.result,"seconds":snappedf(e.elapsed,0.01),"blue_launches":e.player_launcher.shots,"red_launches":e.enemy_launcher.shots,"blue_hits":friendly_hits,"red_hits":hostile_hits,"blue_pd":blue_intercepts,"red_pd":red_intercepts,"player_hull":game.ship.damage_model.health.hull,"enemy_hull":e.enemy.damage_model.health.hull,"blue_rounds":60-e.drone.ammunition if is_instance_valid(e.drone) else 0,"red_rounds":int(e.profile.rounds)-e.enemy_drone.ammunition if is_instance_valid(e.enemy_drone) else 0}
 game.queue_free()
 await tree.process_frame
 print("BALANCE ",JSON.stringify(row))
 return row
