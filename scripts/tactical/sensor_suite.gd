class_name SensorSuite
extends RefCounted

# Only this observation boundary receives ground truth. UI/fire control never do.
var contacts: Array[SensorContact] = []
var selected_id: String = ""
var tracking_enabled: bool = false
var max_range_m: float = 2500.0
var cadence_seconds: float = 0.5
var measurement_resolution_m: float = 5.0
var enabled: bool = true
var elapsed: float = 0.0
var previous_positions: Dictionary = {}
var previous_ticks: Dictionary = {}

func sample(targets: Array[Node3D], observer: Transform3D, velocity: Vector3, tick: int, dt: float) -> void:
 for contact in contacts:
  contact.age_seconds += dt
 if not enabled:
  return
 elapsed += dt
 if elapsed < cadence_seconds:
  return
 var interval := elapsed
 elapsed = 0.0
 var next: Array[SensorContact] = []
 for target in targets:
  if not is_instance_valid(target): continue
  var offset := target.global_position - observer.origin
  var distance := offset.length()
  if distance > max_range_m or distance < 1.0:
   continue
  var id := String(target.name)
  var contact := SensorContact.new()
  contact.contact_id = id
  # Configurable quantization; default 5 m for the original free-flight sensor.
  var measured := target.global_position.snapped(Vector3.ONE * measurement_resolution_m)
  contact.relative_position = observer.basis.inverse() * (measured - observer.origin)
  contact.quality = clampf(1.0 - distance / max_range_m * 0.6, 0.1, 1.0)
  contact.observed_tick = tick
  contact.observed_position_world = measured
  contact.kind = String(target.get_meta("kind","ship"))
  contact.team = int(target.get_meta("team",-1))
  contact.tracking = tracking_enabled and selected_id == id
  if previous_positions.has(id):
   var measurement_dt := float(tick - int(previous_ticks[id])) / float(Engine.physics_ticks_per_second)
   contact.relative_velocity = observer.basis.inverse() * ((measured - previous_positions[id]) / maxf(measurement_dt, interval) - velocity)
   contact.velocity_known = true
   contact.observed_velocity_world = (measured-previous_positions[id])/maxf(measurement_dt,interval)
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
 for contact in contacts:
  contact.tracking = tracking_enabled and contact.contact_id == selected_id
