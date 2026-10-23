class_name TacticalMapModel
extends RefCounted

var tracks: Array[TacticalTrack] = []
var revision: int = 0
# Only cooperative own bodies enter this boundary. No enemy Node references.
func sample(observer: ShipPhysics, suite: SensorSuite, own: Array[Node3D]) -> void:
 tracks.clear()
 var frame:=observer.global_transform
 var inverse:=frame.basis.inverse()
 var ids: Dictionary={}
 for body in own:
  if not is_instance_valid(body) or int(body.get_meta("team",-1))!=int(observer.get_meta("team",0)): continue
  if not body is RigidBody3D: continue
  var track:=TacticalTrack.new()
  track.id=String(body.name)
  track.team=int(body.get_meta("team",0))
  track.kind=String(body.get_meta("kind","ship"))
  track.cooperative=true
  track.velocity_known=true
  track.quality=1
  track.position=inverse*(body.global_position-frame.origin)
  track.velocity=inverse*(body.linear_velocity-observer.linear_velocity)
  if body is ShipPhysics: track.acceleration=inverse*body.acceleration_world
  elif body is MissileBody: track.acceleration=inverse*(body.applied_force/body.mass)
  elif body is DefenseDrone: track.acceleration=inverse*(body.applied_force/body.mass)
  track.horizon=4
  tracks.append(track)
  ids[track.id]=true
 for contact in suite.contacts:
  if ids.has(contact.contact_id) or contact.age_seconds>=1.5: continue
  var track:=TacticalTrack.new()
  track.id=contact.contact_id
  track.kind=contact.kind
  track.team=contact.team
  track.quality=contact.quality
  track.age=contact.age_seconds
  # Reproject the last measured world position into the current ship frame.
  track.position=inverse*(contact.observed_position_world-frame.origin)
  track.velocity_known=contact.velocity_known and contact.acquired()
  if track.velocity_known:
   track.velocity=inverse*(contact.observed_velocity_world-observer.linear_velocity)
   track.acceleration=inverse*contact.observed_acceleration_world
   # Current frame origin already includes observer motion since the sample.
   track.position+=inverse*contact.observed_velocity_world*track.age
   track.horizon=minf(4,2+contact.quality*2)
  track.uncertainty_m=suite.measurement_resolution_m+(1-contact.quality)*80+track.age*40
  tracks.append(track)
 revision+=1

func find(id: String) -> TacticalTrack:
 for track in tracks:
  if track.id==id: return track
 return null
