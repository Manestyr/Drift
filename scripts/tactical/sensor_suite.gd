class_name SensorSuite
extends RefCounted

# Only this observation boundary receives ground truth. UI/fire control never do.
var contacts: Array[SensorContact] = []
var selected_id: String = ""
var tracking_enabled: bool = false
var max_range_m: float = 2500.0
var cadence_seconds: float = 0.5
var measurement_resolution_m: float = 5.0
var estimate_acceleration: bool = false
var sample_direct_physics: bool = false
var previous_velocities: Dictionary = {}
var previous_accelerations: Dictionary = {}
var tracking_refinement: bool = false
var track_seconds: float = 0.0
var tracking_id: String = ""
var enabled: bool = true
var elapsed: float = 0.0
var previous_positions: Dictionary = {}
var previous_ticks: Dictionary = {}

func sample(targets: Array[Node3D], observer: Transform3D, velocity: Vector3, tick: int, dt: float) -> void:
 for contact in contacts:
  contact.age_seconds += dt
 if not enabled:
  return
 if tracking_refinement:
  if not tracking_enabled or selected_id!=tracking_id:
   track_seconds=0.0
   tracking_id=selected_id
  elif selected()!=null and selected().age_seconds<1.5:
   track_seconds+=dt
 elapsed += dt
 if elapsed < cadence_seconds:
  return
 var interval := elapsed
 elapsed = 0.0
 var next: Array[SensorContact] = []
 for target in targets:
  if not is_instance_valid(target): continue
  var truth_position:=target.global_position
  if sample_direct_physics and target is RigidBody3D:
   var direct:=PhysicsServer3D.body_get_direct_state(target.get_rid())
   if direct!=null: truth_position=direct.transform.origin
  var offset := truth_position - observer.origin
  var distance := offset.length()
  if distance > max_range_m or distance < 1.0:
   continue
  var id := String(target.name)
  var contact := SensorContact.new()
  contact.contact_id = id
  # Configurable quantization; default 5 m for the original free-flight sensor.
  var measured := truth_position.snapped(Vector3.ONE * measurement_resolution_m)
  contact.relative_position = observer.basis.inverse() * (measured - observer.origin)
  contact.quality = clampf(1.0 - distance / max_range_m * 0.6, 0.1, 1.0)
  contact.observed_tick = tick
  contact.observed_position_world = measured
  contact.kind = String(target.get_meta("kind","ship"))
  contact.team = int(target.get_meta("team",-1))
  contact.tracking = tracking_enabled and selected_id == id
  if tracking_refinement and contact.tracking:
   contact.track_seconds=track_seconds
   contact.quality=clampf(contact.quality+0.15*(1.0-exp(-track_seconds/1.2)),0,1)
   contact.solution_progress=clampf(track_seconds/2.0,0,1)
   contact.lock_quality=contact.quality*contact.solution_progress
  if previous_positions.has(id):
   var measurement_dt := float(tick - int(previous_ticks[id])) / float(Engine.physics_ticks_per_second)
   contact.relative_velocity = observer.basis.inverse() * ((measured - previous_positions[id]) / maxf(measurement_dt, interval) - velocity)
   contact.velocity_known = true
   contact.observed_velocity_world = (measured-previous_positions[id])/maxf(measurement_dt,interval)
   contact.velocity_sample_seconds=maxf(measurement_dt,interval)
   if estimate_acceleration:
    if previous_velocities.has(id):
     var derived: Vector3=((contact.observed_velocity_world-previous_velocities[id])/contact.velocity_sample_seconds).limit_length(300)
     contact.observed_acceleration_world=derived.lerp(previous_accelerations.get(id,derived),0.5)
     previous_accelerations[id]=contact.observed_acceleration_world
    previous_velocities[id]=contact.observed_velocity_world
  previous_positions[id] = measured
  previous_ticks[id] = tick
  next.append(contact)
 contacts = next
 if selected() == null:
  selected_id = contacts[0].contact_id if not contacts.is_empty() else ""

func selected() -> SensorContact:
 for contact in contacts:
  if contact.contact_id == selected_id:
   return contact
 return null

func cycle(direction: int) -> void:
 if contacts.is_empty():
  selected_id = ""
  return
 var index: int = 0
 for i in contacts.size():
  if contacts[i].contact_id == selected_id:
   index = i
 selected_id = contacts[posmod(index + direction, contacts.size())].contact_id
 _sync_tracking()

func toggle_tracking() -> void:
 tracking_enabled = not tracking_enabled
 _sync_tracking()

func _sync_tracking() -> void:
 if not tracking_enabled or selected_id!=tracking_id:
  track_seconds=0
  tracking_id=selected_id
 for contact in contacts:
  contact.tracking = tracking_enabled and contact.contact_id == selected_id
  if tracking_refinement and (not contact.tracking or track_seconds==0):
   contact.track_seconds=0
   contact.solution_progress=0
   contact.lock_quality=0
