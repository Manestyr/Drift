class_name DefenseDrone
extends RigidBody3D

signal recovered
signal round_fired(round_body: DefenseRound)
var carrier: ShipPhysics
var team: int = 0
var fuel_delta_v: float = 650.0
var thrust_n: float = 18000.0
var ammunition: int = 60
var defense_enabled: bool = false
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
 sensors.cadence_seconds=0.05
 sensors.measurement_resolution_m=0.05
 sensors.max_range_m=650.0

func _ready() -> void:
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
 waypoint=offset.limit_length(220.0)
 recalling=false
 hold_world=false

func hold_position() -> void:
 world_waypoint=global_position
 hold_world=true
 recalling=false

func recall() -> void:
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
 status="RECALL" if recalling else ("WORLD HOLD" if hold_world else "CARRIER WAYPOINT")
 if fuel_delta_v<=0: status="FUEL EMPTY / COAST"
 if recalling and offset.length()<3.0 and (state.linear_velocity-desired_velocity).length()<2.0:
  docked=true
  call_deferred("_finish_recovery")
 var valid: Array[Node3D] = []
 for candidate in targets:
  if is_instance_valid(candidate): valid.append(candidate)
 sensors.sample(valid,state.transform,state.linear_velocity,ticks,state.step)
 if defense_enabled and ammunition>0 and cooldown<=0:
  for contact in sensors.contacts:
   if contact.team!=team and contact.kind=="missile" and contact.acquired() and contact.velocity_known and contact.relative_position.length()<420:
    call_deferred("_fire",contact)
    cooldown=0.25
    break

func _finish_recovery() -> void:
 recovered.emit()
 queue_free()

func _fire(contact: SensorContact) -> void:
 if docked or not defense_enabled or ammunition<=0: return
 var estimated_position := contact.observed_position_world+contact.observed_velocity_world*contact.age_seconds
 var flight_time := global_position.distance_to(estimated_position)/2000.0
 var aim := estimated_position+contact.observed_velocity_world*flight_time
 var direction := (aim-global_position).normalized()
 var round_body := DefenseRound.new()
 round_body.team=team
 round_body.position=global_position+direction*2.5
 round_body.linear_velocity=linear_velocity+direction*2000.0
 get_parent().add_child(round_body)
 round_body.exclusions=[round_body.get_rid()]
 ammunition-=1
 round_fired.emit(round_body)
