class_name DefenseTrial
extends RefCounted

# Actual finite ballistic missile/round collisions. All poses/velocities below
# are initial spawn conditions; no hits, winners or later body states injected.
static func run(tree: SceneTree, placement: String, count: int, unlimited: bool = false) -> Dictionary:
 var arena:=Node3D.new()
 tree.root.add_child(arena)
 var carrier:=ShipPhysics.new()
 carrier.name="PROTECTED"
 carrier.set_meta("team",0)
 carrier.damage_model=ComponentDamage.new()
 arena.add_child(carrier)
 var collision:=CollisionShape3D.new()
 var box:=BoxShape3D.new()
 box.size=Vector3(7,5,36)
 collision.shape=box
 carrier.add_child(collision)
 var drone: DefenseDrone=null
 var targets: Array[Node3D]=[]
 var tally: Dictionary={"placement":placement,"missiles":count,"unlimited":unlimited,"intercepts":0,"hits":0,"drone_hits":0,"shots":0,"fuel_used":0.0,"max_slew":0.0}
 if placement!="none":
  drone=DefenseDrone.new()
  drone.name="GUARD"
  drone.carrier=carrier
  drone.position=Vector3(-10,0,0)
  if unlimited:
   drone.reaction_seconds=0
   drone.switch_seconds=0
   drone.slew_rate=1000000
   drone.burst_size=1000
  arena.add_child(drone)
  drone.add_collision_exception_with(carrier)
  drone.assign_waypoint(Vector3(-60,20,-80) if placement=="guard" else Vector3(0,-30,900))
  drone.defense_enabled=true
  drone.round_fired.connect(func(round_body: DefenseRound) -> void:
   round_body.struck.connect(func(_round: DefenseRound, missile: MissileBody) -> void:
    if missile.spent: return
    tally.intercepts+=1
    missile.spent=true
    missile.queue_free()))
 # Give the same real deployment time to each placement; no docking teleport.
 for tick in 480:
  await tree.physics_frame
  await tree.process_frame
 for i in count:
  var missile:=MissileBody.new()
  missile.name="THREAT-%d"%i
  missile.team=1
  missile.fuel_delta_v=0
  var angle:=0.0 if count==1 else deg_to_rad(-65+130.0*i/maxi(1,count-1))
  missile.position=Vector3(sin(angle)*700,0,-cos(angle)*700)
  missile.linear_velocity=-missile.position.normalized()*450
  missile.impact.connect(func(_missile: MissileBody, body: Node3D, point: Vector3) -> void:
   if body==carrier:
    tally.hits+=1
    carrier.damage_model.hit(carrier.to_local(point))
   else: tally.drone_hits+=1)
  arena.add_child(missile)
  targets.append(missile)
 if drone!=null: drone.targets=targets
 var last_aim:=drone.aim_direction if drone!=null else Vector3.FORWARD
 for tick in 240:
  await tree.physics_frame
  await tree.process_frame
  if drone!=null:
   tally.max_slew=maxf(tally.max_slew,last_aim.angle_to(drone.aim_direction))
   last_aim=drone.aim_direction
 if drone!=null:
  tally.shots=drone.shots_fired
  tally.fuel_used=650-drone.fuel_delta_v
 tally.hull=carrier.damage_model.health.hull
 arena.queue_free()
 await tree.process_frame
 print("DEFENSE ",JSON.stringify(tally))
 return tally
