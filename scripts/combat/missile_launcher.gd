class_name MissileLauncher
extends RefCounted

var ammunition: Array[int] = [4,4]
var selected_launcher: int = 0
var armed: bool = false
var cooldown: float = 0.0
var last_status: String = "SAFE"
var shots: int = 0

func advance(dt: float) -> void:
 cooldown = maxf(0,cooldown-dt)

func authorize(contact: SensorContact, damage: ComponentDamage) -> bool:
 if damage != null and damage.efficiency("weapons") <= 0:
  last_status="WEAPONS OFFLINE"
 elif not armed: last_status="SAFE / ARM FIRST"
 elif ammunition[selected_launcher]<=0: last_status="LAUNCHER EMPTY"
 elif cooldown>0: last_status="RELOADING %.1f s"%cooldown
 elif contact==null or not contact.acquired() or not contact.tracking or not contact.velocity_known:
  last_status="DENIED / SENSOR TRACK"
 elif contact.kind!="ship": last_status="DENIED / SHIP TARGET REQUIRED"
 else:
  last_status="READY"
  return true
 return false

func launch(carrier: ShipPhysics, contact: SensorContact, team: int, parent: Node3D, targets: Array[Node3D]) -> MissileBody:
 if not authorize(contact,carrier.damage_model): return null
 if contact.team==team:
  last_status="DENIED / FRIENDLY IFF"
  return null
 var missile := MissileBody.new()
 shots += 1
 missile.name = ("BLUE" if team==0 else "RED")+"-M%02d"%shots
 missile.team=team
 missile.carrier_id=String(carrier.name)
 missile.target_id=contact.contact_id
 missile.targets=targets.duplicate()
 # Rack ejects sideways and forward outside the 7 x 5 x 36 m hull.
 var local_offset := Vector3(-5.5 if selected_launcher==0 else 5.5,0,-14)
 missile.transform=Transform3D(carrier.global_basis,carrier.to_global(local_offset))
 var offset_world := carrier.global_basis*local_offset
 missile.linear_velocity=carrier.linear_velocity+carrier.angular_velocity.cross(offset_world)
 missile.guidance_position=contact.observed_position_world
 missile.guidance_velocity=contact.observed_velocity_world
 missile.observation_age=contact.age_seconds
 missile.launch_impulse=carrier.global_basis*Vector3(-12 if selected_launcher==0 else 12,0,-25)*missile.mass
 parent.add_child(missile)
 missile.add_collision_exception_with(carrier)
 missile.collision_exclusions=[carrier.get_rid(),missile.get_rid()]
 ammunition[selected_launcher]-=1
 cooldown=6.0 / maxf(0.25,carrier.damage_model.efficiency("weapons") if carrier.damage_model!=null else 1.0)
 last_status="LAUNCHED "+missile.name
 return missile
