class_name DefenseDrone
extends RigidBody3D

signal recovered
signal round_fired(round_body: DefenseRound)
var carrier: ShipPhysics
var team: int = 0
var fuel_delta_v: float = 650.0
var thrust_n: float = 18000.0
var ammunition: int = 60
var command_mode: String = "ESCORT"
var gun_interval: float = 0.25
var engagement_range: float = 420.0
var defense_enabled: bool = false:
 set(value):
  defense_enabled=value
  if value: command_mode="DEFEND"
  elif command_mode=="DEFEND": command_mode="ESCORT"
var recalling: bool = false
var waypoint: Vector3 = Vector3(-60,20,-80)
var hold_world: bool = false
var world_waypoint: Vector3 = Vector3.ZERO
var status: String = "DEPLOYING"
var applied_force: Vector3 = Vector3.ZERO
var sensors := SensorSuite.new()
var targets: Array[Node3D] = []
var cooldown: float = 0.0
var ticks: int = 0
var docked: bool = false
@export var reaction_seconds: float = 0.16
@export var switch_seconds: float = 0.22
@export var slew_rate: float = 3.0 # rad/s; turret, independent of hull orientation
@export var burst_size: int = 2
@export var burst_recovery: float = 0.65
var aim_direction: Vector3 = Vector3.FORWARD
var locked_id: String = ""
var lock_seconds: float = 0.0
var switch_remaining: float = 0.0
var burst_count: int = 0
var cooling: float = 0.0
var shots_fired: int = 0

func _init() -> void:
 linear_damp_mode=RigidBody3D.DAMP_MODE_REPLACE
 angular_damp_mode=RigidBody3D.DAMP_MODE_REPLACE
 mass=450.0
 gravity_scale=0
 linear_damp=0
 angular_damp=0
 can_sleep=false
 inertia=Vector3.ONE*250.0
 collision_layer=8
 collision_mask=1|4
 sensors.sample_direct_physics=true
 sensors.estimate_acceleration=true
 sensors.cadence_seconds=0.05
 sensors.measurement_resolution_m=0.05
 sensors.max_range_m=650.0

func _ready() -> void:
 aim_direction=-carrier.global_basis.z if is_instance_valid(carrier) else Vector3.FORWARD
 set_meta("team",team)
 set_meta("kind","drone")
 var shape := CollisionShape3D.new()
 var box := BoxShape3D.new()
 box.size=Vector3(3,1,3)
 shape.shape=box
 add_child(shape)
 var mesh := MeshInstance3D.new()
 var geometry := BoxMesh.new()
 geometry.size=box.size
 mesh.mesh=geometry
 var material := StandardMaterial3D.new()
 material.albedo_color=Color(0.15,0.6,0.4)
 mesh.material_override=material
 add_child(mesh)

func assign_waypoint(offset: Vector3) -> void:
 waypoint=offset.limit_length(1200.0)
 defense_enabled=false
 command_mode="ESCORT"
 recalling=false
 hold_world=false

func hold_position() -> void:
 defense_enabled=false
 command_mode="HOLD"
 world_waypoint=global_position
 hold_world=true
 recalling=false

func recall() -> void:
 command_mode="RECALL"
 recalling=true
 hold_world=false
 defense_enabled=false

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
 if docked or not is_instance_valid(carrier): return
 ticks+=1
 cooldown=maxf(0,cooldown-state.step)
 var desired_position := carrier.to_global(Vector3(-10,0,0) if recalling else waypoint)
 var desired_velocity := carrier.linear_velocity+carrier.angular_velocity.cross(desired_position-carrier.global_position)
 if hold_world:
  desired_position=world_waypoint
  desired_velocity=Vector3.ZERO
 var offset := desired_position-state.transform.origin
 var acceleration := (offset*0.6+(desired_velocity-state.linear_velocity)*1.55).limit_length(thrust_n/mass)
 applied_force=acceleration*mass
 var dv := acceleration.length()*state.step
 if dv>0:
  applied_force*=minf(1.0,fuel_delta_v/dv)
  fuel_delta_v=maxf(0,fuel_delta_v-applied_force.length()/mass*state.step)
  state.apply_central_force(applied_force)
 status="RECALL" if recalling else command_mode
 if fuel_delta_v<=0: status="FUEL EMPTY / COAST"
 if recalling and offset.length()<3.0 and (state.linear_velocity-desired_velocity).length()<2.0:
  docked=true
  call_deferred("_finish_recovery")
 var valid: Array[Node3D] = []
 for candidate in targets:
  if is_instance_valid(candidate): valid.append(candidate)
 sensors.sample(valid,state.transform,state.linear_velocity,ticks,state.step)
 _defense_tick(state.step)

func _defense_tick(dt: float) -> void:
 switch_remaining=maxf(0,switch_remaining-dt)
 cooling=maxf(0,cooling-dt)
 if not defense_enabled or ammunition<=0:
  locked_id=""
  lock_seconds=0
  return
 var selected: SensorContact=null
 for contact in sensors.contacts:
  if contact.contact_id==locked_id and can_engage(contact): selected=contact
 if selected==null:
  var nearest:=INF
  for contact in sensors.contacts:
   if can_engage(contact):
    var eta: float=(contact.observed_position_world-carrier.global_position).length()/maxf(1,(contact.observed_velocity_world-carrier.linear_velocity).length())
    if eta<nearest:
     nearest=eta
     selected=contact
  if selected!=null and selected.contact_id!=locked_id:
   switch_remaining=switch_seconds if not locked_id.is_empty() else 0
   locked_id=selected.contact_id
   lock_seconds=0
 if selected==null:
  # Keep the previous ID so a different threat incurs a real retarget delay.
  lock_seconds=0
  return
 lock_seconds+=dt
 var desired:=fire_direction(selected)
 var angle:=aim_direction.angle_to(desired)
 if angle>0.00001:
  var axis:=aim_direction.cross(desired)
  if axis.length()<0.0001: axis=aim_direction.cross(Vector3.UP if absf(aim_direction.y)<0.9 else Vector3.RIGHT)
  aim_direction=aim_direction.rotated(axis.normalized(),minf(angle,slew_rate*dt)).normalized()
 if cooldown<=0 and cooling<=0 and switch_remaining<=0 and lock_seconds>=reaction_seconds and aim_direction.dot(desired)>cos(0.025):
  call_deferred("_fire",selected)
  cooldown=gun_interval

func _finish_recovery() -> void:
 recovered.emit()
 queue_free()

func fire_direction(contact: SensorContact) -> Vector3:
 # Direct-state observations share the launch solver epoch. The legacy Node
 # cache boundary needed one extra tick; adding it again overleads fast tracks.
 var age:=contact.age_seconds+(0.0 if sensors.sample_direct_physics else 1.0/float(Engine.physics_ticks_per_second))
 var acceleration:=contact.observed_acceleration_world
 var estimated_position:=contact.observed_position_world+contact.observed_velocity_world*age+acceleration*0.5*age*(age+contact.velocity_sample_seconds)
 var relative_position:=estimated_position-global_position
 var relative_velocity:=contact.observed_velocity_world+acceleration*(age+contact.velocity_sample_seconds*0.5)-linear_velocity
 var flight_time:=relative_position.length()/2000.0
 for i in range(4): flight_time=maxf(0,(relative_position+relative_velocity*flight_time+acceleration*0.5*flight_time*flight_time).length()-2.5)/2000.0
 return (relative_position+relative_velocity*flight_time+acceleration*0.5*flight_time*flight_time).normalized()

func _fire(contact: SensorContact) -> void:
 if docked or not defense_enabled or ammunition<=0 or not can_engage(contact): return
 var direction:=fire_direction(contact)
 if aim_direction.dot(direction)<cos(0.025): return
 var round_body := DefenseRound.new()
 round_body.team=team
 round_body.position=global_position+direction*2.5
 round_body.linear_velocity=linear_velocity+direction*2000.0
 get_parent().add_child(round_body)
 round_body.exclusions=[round_body.get_rid()]
 ammunition-=1
 shots_fired+=1
 burst_count+=1
 if burst_count>=burst_size:
  cooling=burst_recovery
  burst_count=0
 round_fired.emit(round_body)

func can_engage(contact: SensorContact) -> bool:
 if contact.team==team or contact.kind!="missile" or not contact.acquired() or contact.age_seconds>0.2 or not contact.velocity_known: return false
 var position_estimate := contact.observed_position_world+contact.observed_velocity_world*contact.age_seconds
 if global_position.distance_to(position_estimate)>engagement_range: return false
 # Protect the carrier from inbound tracks; no shots wasted on harmless outbound tracks.
 var relative := position_estimate-carrier.global_position
 var velocity := contact.observed_velocity_world-carrier.linear_velocity
 if relative.dot(velocity)>=0: return false
 var time := clampf(-relative.dot(velocity)/maxf(velocity.length_squared(),0.01),0,6)
 return (relative+velocity*time).length()<200.0
