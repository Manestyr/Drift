class_name CombatEncounter
extends Node3D

signal ended(result: String)
var player: ShipPhysics
var player_sensors: SensorSuite
var enemy: ShipPhysics
var enemy_sensors := SensorSuite.new()
var enemy_pilot := EnemyPilot.new()
var player_launcher := MissileLauncher.new()
var enemy_launcher := MissileLauncher.new()
var events := CombatEvents.new()
var missiles: Array[MissileBody] = []
var drone: DefenseDrone
var drone_available: bool = true
var drone_rounds: int = 60
var drone_fuel: float = 650.0
var automatic_weapons: bool = true
var automatic_drone: bool = true
var weapons_occupied: bool = false
var drone_occupied: bool = false
var elapsed: float = 0.0
var result: String = "ACTIVE"
var last_player_shot: float = -2.0
var last_enemy_shot: float = -4.0
var selected_waypoint: int = 0
var waypoints: Array[Vector3] = [Vector3(-60,20,-80),Vector3(60,20,-80),Vector3(0,45,-140)]
var last_message: String = "Kontakt Alpha / automation fills unoccupied stations"

func _ready() -> void:
 player.name="DRIFT"
 player.set_meta("team",0)
 player.set_meta("kind","ship")
 player.damage_model=ComponentDamage.new()
 _connect_damage(player)
 enemy=ShipPhysics.new()
 enemy.name="ALPHA"
 enemy.position=Vector3(120,35,-1100)
 enemy.rotation.y=PI
 enemy.linear_velocity=Vector3(-2,0,8)
 enemy.damage_model=ComponentDamage.new()
 enemy.computer.rotation_stabilization=true
 add_child(enemy)
 _connect_damage(enemy)
 enemy.set_meta("team",1)
 enemy.set_meta("kind","ship")
 var shape := CollisionShape3D.new()
 var box := BoxShape3D.new()
 box.size=Vector3(7,5,36)
 shape.shape=box
 enemy.add_child(shape)
 var mesh := MeshInstance3D.new()
 var geometry := BoxMesh.new()
 geometry.size=box.size
 mesh.mesh=geometry
 var material := StandardMaterial3D.new()
 material.albedo_color=Color(0.48,0.15,0.10)
 material.roughness=0.7
 mesh.material_override=material
 enemy.add_child(mesh)
 var marker := Label3D.new()
 marker.text="ALPHA"
 marker.position.y=8
 marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 marker.font_size=64
 enemy.add_child(marker)
 enemy_launcher.armed=true
 enemy_sensors.tracking_enabled=true
 enemy_sensors.selected_id=String(player.name)
 # Combat uses the same sensor boundary, at finer precision for missile tracking.
 player_sensors.measurement_resolution_m=0.25
 enemy_sensors.measurement_resolution_m=0.25

func _connect_damage(body: ShipPhysics) -> void:
 body.damage_model.system_damaged.connect(func(system: String, remaining: float) -> void:
  events.record(player.tick,"system_damage",String(body.name),{"system":system,"remaining":remaining})
  last_message="%s / %s %.0f%%"%[body.name,system,remaining]
  for child in body.get_children():
   if child is MeshInstance3D and child.material_override is StandardMaterial3D:
    child.material_override.albedo_color=Color(0.36,0.12,0.08))

func observed_targets() -> Array[Node3D]:
 var targets: Array[Node3D] = [enemy,player]
 for missile in missiles:
  if is_instance_valid(missile) and not missile.spent: targets.append(missile)
 if is_instance_valid(drone): targets.append(drone)
 return targets

func tick(dt: float) -> void:
 if result!="ACTIVE": return
 elapsed+=dt
 missiles=missiles.filter(func(m: MissileBody) -> bool: return is_instance_valid(m) and not m.spent)
 var all_targets := observed_targets()
 enemy_sensors.max_range_m=2500*enemy.damage_model.efficiency("sensors")
 enemy_sensors.enabled=enemy.damage_model.efficiency("sensors")>0
 enemy_sensors.sample(all_targets,enemy.global_transform,enemy.linear_velocity,player.tick,dt)
 var enemy_contact := enemy_sensors.selected()
 enemy_pilot.command_for(enemy_contact,enemy.global_basis,enemy.linear_velocity,enemy.command,dt)
 if player_launcher.ammunition[player_launcher.selected_launcher]<=0 and player_launcher.ammunition[1-player_launcher.selected_launcher]>0 and automatic_weapons and not weapons_occupied:
  player_launcher.selected_launcher=1-player_launcher.selected_launcher
 if enemy_launcher.ammunition[enemy_launcher.selected_launcher]<=0 and enemy_launcher.ammunition[1-enemy_launcher.selected_launcher]>0:
  enemy_launcher.selected_launcher=1-enemy_launcher.selected_launcher
 player_launcher.advance(dt)
 enemy_launcher.advance(dt)
 player_launcher.authorize(player_sensors.selected(),player.damage_model)
 if automatic_weapons and not weapons_occupied:
  var contact := hostile_ship(player_sensors,0)
  if contact != null:
   if player_sensors.selected_id!=contact.contact_id:
    select_contact(player_sensors,contact.contact_id)
   player_sensors.tracking_enabled=true
   player_sensors._sync_tracking()
   player_launcher.armed=true
   if elapsed-last_player_shot>=14.0:
    fire_player()
 if elapsed-last_enemy_shot>=18.0:
  var launched := enemy_launcher.launch(enemy,enemy_contact,1,self,all_targets)
  if launched!=null:
   _register_missile(launched)
   last_enemy_shot=elapsed
 if automatic_drone and not drone_occupied:
  if drone_available and elapsed>2.0: deploy_drone()
  if is_instance_valid(drone) and not drone.recalling: drone.defense_enabled=true
 for missile in missiles:
  missile.targets=all_targets
 if is_instance_valid(drone): drone.targets=all_targets
 if player.damage_model.incapable(): finish("DEFEAT")
 elif enemy.damage_model.incapable(): finish("VICTORY")

func hostile_ship(suite: SensorSuite, team: int) -> SensorContact:
 for contact in suite.contacts:
  if contact.team!=team and contact.kind=="ship": return contact
 return null

func select_contact(suite: SensorSuite, id: String) -> void:
 suite.selected_id=id
 suite._sync_tracking()
 events.record(player.tick,"target_change",String(player.name),{"contact_id":id})

func fire_player() -> MissileBody:
 if result!="ACTIVE": return null
 var launched := player_launcher.launch(player,player_sensors.selected(),0,self,observed_targets())
 last_message=player_launcher.last_status
 if launched!=null:
  _register_missile(launched)
  last_player_shot=elapsed
 return launched

func _register_missile(missile: MissileBody) -> void:
 missiles.append(missile)
 missile.impact.connect(_impact)
 events.record(player.tick,"launch",String(missile.name),{"carrier_id":missile.carrier_id,"target_id":missile.target_id,"position":missile.global_position,"velocity":missile.linear_velocity+missile.launch_impulse/missile.mass,"team":missile.team})

func _impact(missile: MissileBody, body: Node3D, point: Vector3) -> void:
 events.record(player.tick,"missile_hit",String(missile.name),{"body_id":String(body.name),"point":point})
 if body is ShipPhysics and body.damage_model!=null:
  body.damage_model.hit(body.to_local(point))
  if body.damage_model.incapable(): finish("DEFEAT" if body==player else "VICTORY")
 elif body is DefenseDrone:
  last_message="DEFENSE DRONE LOST"
  body.call_deferred("queue_free")

func finish(outcome: String) -> void:
 if result!="ACTIVE": return
 result=outcome
 player.command.clear()
 enemy.command.clear()
 events.record(player.tick,"incapacitated",String(player.name if outcome=="DEFEAT" else enemy.name),{"result":outcome,"elapsed":elapsed})
 ended.emit(outcome)

func deploy_drone() -> bool:
 if not drone_available or result!="ACTIVE" or player.damage_model.efficiency("weapons")<=0: return false
 drone=DefenseDrone.new()
 drone.name="BLUE-D1"
 drone.carrier=player
 drone.position=player.to_global(Vector3(-10,0,0))
 drone.linear_velocity=player.linear_velocity+player.global_basis*Vector3(-3,0,0)
 drone.ammunition=drone_rounds
 drone.fuel_delta_v=drone_fuel
 add_child(drone)
 drone.add_collision_exception_with(player)
 drone.assign_waypoint(waypoints[selected_waypoint])
 drone.recovered.connect(func() -> void:
  drone_rounds=drone.ammunition
  drone_fuel=drone.fuel_delta_v
  drone_available=true
  last_message="DRONE DOCKED / NO FREE REFUEL OR AMMO")
 drone.round_fired.connect(func(round_body: DefenseRound) -> void:
  round_body.struck.connect(_intercept))
 drone_available=false
 last_message="DRONE DEPLOYED"
 events.record(player.tick,"drone_launch",String(drone.name),{"position":drone.global_position,"velocity":drone.linear_velocity})
 return true

func _intercept(round_body: DefenseRound, missile: MissileBody) -> void:
 if missile.spent: return
 missile.spent=true
 missile.status="INTERCEPTED"
 missile.call_deferred("queue_free")
 events.record(player.tick,"intercept",String(missile.name),{"defender":"BLUE-D1","position":missile.global_position,"round_position":round_body.global_position})
 last_message="POINT DEFENSE / INTERCEPT "+String(missile.name)

func drone_command(action: String) -> void:
 if action=="deploy": deploy_drone()
 elif is_instance_valid(drone):
  if action=="recall": automatic_drone=false
  match action:
   "waypoint":
    selected_waypoint=(selected_waypoint+1)%waypoints.size()
    drone.assign_waypoint(waypoints[selected_waypoint])
   "hold": drone.hold_position()
   "defense": drone.defense_enabled=not drone.defense_enabled
   "recall": drone.recall()
