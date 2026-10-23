class_name MissileBody
extends RigidBody3D

signal expired(missile: MissileBody)
signal impact(missile: MissileBody, body: Node3D, point: Vector3)
var team: int = 0
var order_source: String = "PLAYER"
var carrier_id: String = ""
var target_id: String = ""
var seeker := SensorSuite.new()
var targets: Array[Node3D] = []
var thrust_n: float = 14400.0
var lateral_acceleration_limit: float = 55.0
var turn_acceleration_limit: float = 4.0
var fuel_delta_v: float = 960.0
var lifetime: float = 0.0
var status: String = "BOOST"
var spent: bool = false
var manual_mode: bool = false
var manual_rotation: Vector3 = Vector3.ZERO
var manual_translation: Vector2 = Vector2.ZERO
var manual_throttle: float = 0.0
var control_reserve: float = 12.0 # integrated angular acceleration, rad/s
var command_delay_ticks: int = 11 # 183 ms at the fixed 60-Hz tick
var max_manual_rate: float = 1.2 # rad/s; controlled by torque, never a state clamp
var delivered_rotation: Vector3 = Vector3.ZERO
var _manual_queue: Array[Dictionary] = []
var launch_impulse: Vector3 = Vector3.ZERO
var initial_solver_velocity: Vector3 = Vector3.ZERO
var applied_force: Vector3 = Vector3.ZERO
var applied_torque: Vector3 = Vector3.ZERO
var tick: int = 0
var position_history: Array[Vector3] = []
var previous_position: Vector3 = Vector3.ZERO
var collision_exclusions: Array[RID] = []
var guidance_position: Vector3 = Vector3.ZERO
var guidance_velocity: Vector3 = Vector3.ZERO
var observation_age: float = 100.0

func _init() -> void:
 linear_damp_mode=RigidBody3D.DAMP_MODE_REPLACE
 angular_damp_mode=RigidBody3D.DAMP_MODE_REPLACE
 mass = 120.0
 gravity_scale = 0.0
 linear_damp = 0.0
 angular_damp = 0.0
 can_sleep = false
 inertia = Vector3(80,80,12)
 collision_layer = 4
 collision_mask = 1|8
 continuous_cd = true
 contact_monitor = true
 max_contacts_reported = 4
 seeker.cadence_seconds = 0.1
 seeker.measurement_resolution_m = 0.05
 seeker.max_range_m = 2500.0

func _ready() -> void:
 set_meta("team",team)
 set_meta("kind","missile")
 var shape := CollisionShape3D.new()
 var sphere := SphereShape3D.new()
 sphere.radius = 0.75
 shape.shape = sphere
 add_child(shape)
 var mesh := MeshInstance3D.new()
 var body := CapsuleMesh.new()
 body.radius = 0.5
 body.height = 3.5
 mesh.mesh = body
 mesh.rotation.x = PI/2
 var material := StandardMaterial3D.new()
 material.albedo_color = Color(0.95,0.55,0.2) if team==0 else Color(0.9,0.15,0.1)
 material.emission_enabled = true
 material.emission = material.albedo_color*0.6
 mesh.material_override = material
 add_child(mesh)
 previous_position = global_position
 body_entered.connect(func(body_hit: Node) -> void:
  if body_hit is Node3D: report_impact(body_hit,global_position))

# Spawn pose/velocity are assigned once by launcher, before the first solver step.
# Thereafter no pose, linear velocity or angular velocity writes occur.
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
 tick += 1
 if tick==1:
  state.apply_central_impulse(launch_impulse)
  initial_solver_velocity=state.linear_velocity
 lifetime += state.step
 applied_force = Vector3.ZERO
 applied_torque = Vector3.ZERO
 observation_age += state.step
 if spent: return
 var valid_targets: Array[Node3D] = []
 for target in targets:
  if is_instance_valid(target): valid_targets.append(target)
 seeker.sample(valid_targets,state.transform,state.linear_velocity,tick,state.step)
 for contact in seeker.contacts:
  if contact.contact_id==target_id and contact.acquired() and contact.velocity_known:
   guidance_position = contact.observed_position_world
   guidance_velocity = contact.observed_velocity_world
   observation_age = contact.age_seconds
 if manual_mode:
  _manual_actuation(state)
 elif observation_age < 0.8 and fuel_delta_v > 0.0:
  var offset := guidance_position + guidance_velocity*observation_age - state.transform.origin
  var closing := maxf(60.0,state.linear_velocity.length())
  var lead_time := clampf(offset.length()/closing,0.0,2.0)
  var desired_direction := (offset+guidance_velocity*lead_time).normalized()
  var forward := -state.transform.basis.z
  var error := forward.cross(desired_direction)
  # atan2 preserves the full 180-degree turn request.
  var angle := atan2(error.length(),forward.dot(desired_direction))
  var rotation_error := error.normalized()*angle if error.length()>0.0001 else Vector3.UP*angle
  var omega := state.angular_velocity
  var angular_acceleration := (rotation_error*8.0-omega*5.7).limit_length(turn_acceleration_limit)
  angular_acceleration*=minf(1,control_reserve/maxf(angular_acceleration.length()*state.step,0.000001))
  control_reserve=maxf(0,control_reserve-angular_acceleration.length()*state.step)
  var local_alpha := state.transform.basis.inverse()*angular_acceleration
  applied_torque = state.transform.basis*(inertia*local_alpha)
  state.apply_torque(applied_torque)
  var relative := guidance_velocity-state.linear_velocity
  var side_velocity := relative-forward*relative.dot(forward)
  var side_offset := offset-forward*offset.dot(forward)
  var side_acceleration := (side_offset*1.8+side_velocity*2.7).limit_length(lateral_acceleration_limit)
  # No useful forward burn while facing away; RCS can still turn/translate.
  var forward_acceleration := thrust_n/mass if forward.dot(desired_direction)>0.35 else 0.0
  applied_force = (forward*forward_acceleration+side_acceleration).limit_length(thrust_n/mass)*mass
  status = "GUIDED"
 else:
  status = "COAST / LOST TRACK" if fuel_delta_v>0 else "BALLISTIC / DRY"
 if fuel_delta_v>0 and applied_force.length()>0:
  var requested_dv := applied_force.length()/mass*state.step
  applied_force *= minf(1.0,fuel_delta_v/maxf(requested_dv,0.000001))
  fuel_delta_v = maxf(0.0,fuel_delta_v-applied_force.length()/mass*state.step)
  state.apply_central_force(applied_force)
 if lifetime>55.0:
  spent=true
  status="EXPIRED / MISS"
  expired.emit(self)
  call_deferred("queue_free")

func set_manual(value: bool) -> void:
 manual_mode=value
 clear_operator_input()

func clear_operator_input() -> void:
 manual_rotation=Vector3.ZERO
 manual_translation=Vector2.ZERO
 manual_throttle=0
 delivered_rotation=Vector3.ZERO
 _manual_queue.clear()

func _manual_actuation(state: PhysicsDirectBodyState3D) -> void:
 status="MANUAL / LINK DELAY" if fuel_delta_v>0 else "MANUAL / BALLISTIC DRY"
 _manual_queue.append({"deliver":tick+command_delay_ticks,"rotation":manual_rotation.limit_length(),"side":manual_translation.limit_length(),"throttle":clampf(manual_throttle,0,1)})
 var received: Dictionary={}
 while not _manual_queue.is_empty() and int(_manual_queue[0].deliver)<=tick:
  received=_manual_queue.pop_front()
 if received.is_empty() or fuel_delta_v<=0: return
 delivered_rotation=received.rotation
 var local_rate:=state.transform.basis.inverse()*state.angular_velocity
 var alpha: Vector3=(delivered_rotation*max_manual_rate-local_rate)/0.22
 alpha=alpha.limit_length(turn_acceleration_limit)
 if control_reserve>0:
  alpha*=minf(1,control_reserve/maxf(alpha.length()*state.step,0.000001))
  control_reserve=maxf(0,control_reserve-alpha.length()*state.step)
  applied_torque=state.transform.basis*(inertia*alpha)
  state.apply_torque(applied_torque)
 var side: Vector2=received.side
 var force_local:=Vector3(side.x,side.y,0)*lateral_acceleration_limit*mass
 force_local+=Vector3.FORWARD*float(received.throttle)*thrust_n
 applied_force=(state.transform.basis*force_local).limit_length(thrust_n)

func _physics_process(_dt: float) -> void:
 if spent: return
 # Swept real collider query supplements CCD for thin targets/high closing speed.
 if previous_position.distance_to(global_position)>0.001:
  var query := PhysicsRayQueryParameters3D.create(previous_position,global_position,1|8,collision_exclusions)
  var hit := get_world_3d().direct_space_state.intersect_ray(query)
  if not hit.is_empty(): report_impact(hit.collider,hit.position)
 position_history.append(global_position)
 if position_history.size()>8: position_history.pop_front()
 previous_position = global_position

func report_impact(body: Node3D, point: Vector3) -> void:
 if spent: return
 if body is DefenseRound:
  body.strike(self)
  return
 if previous_position.distance_to(global_position)>0.001:
  var query := PhysicsRayQueryParameters3D.create(position_history[0] if not position_history.is_empty() else previous_position,global_position+linear_velocity.normalized()*4.0,1|8,collision_exclusions)
  var surface := get_world_3d().direct_space_state.intersect_ray(query)
  if not surface.is_empty() and surface.collider==body: point=surface.position
 spent=true
 status="IMPACT"
 impact.emit(self,body,point)
 call_deferred("queue_free")
