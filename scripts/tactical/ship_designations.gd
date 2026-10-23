class_name ShipDesignations
extends RefCounted

signal designation_changed(category: String, target_id: String, sender_role: String, seconds: float)
const MAX_AGE: float = 1.5
var primary: CrewDesignation
var threat: CrewDesignation
var tracks: Dictionary = {}
var now: float = 0.0
var own_team: int = 0

func observe(contacts: Array[SensorContact], seconds: float) -> void:
 now=seconds
 for track: ObservedTrack in tracks.values(): track.present=false
 for contact in contacts:
  if contact.team<0 or contact.team==own_team or contact.contact_id.is_empty(): continue
  if contact.kind not in ["ship","missile"]: continue
  if not contact.observed_position_world.is_finite() or not contact.observed_velocity_world.is_finite(): continue
  if not is_finite(contact.quality) or not is_finite(contact.age_seconds) or contact.age_seconds<0 or contact.age_seconds>=MAX_AGE or contact.quality<0.25: continue
  var track:=ObservedTrack.new()
  track.id=contact.contact_id
  track.kind=contact.kind
  track.quality=contact.quality
  track.position_world=contact.observed_position_world
  track.velocity_world=contact.observed_velocity_world
  track.velocity_known=contact.velocity_known
  track.sampled_seconds=now-contact.age_seconds
  track.tracking=contact.tracking
  track.present=true
  tracks[track.id]=track
 for id: String in tracks.keys():
  if tracks[id].age(now)>=MAX_AGE: tracks.erase(id)
 if primary!=null and get_track(primary.target_id)==null: clear("primary","sensors / expired")
 if threat!=null and get_track(threat.target_id)==null: clear("threat","sensors / expired")

func get_track(id: String) -> ObservedTrack:
 return tracks.get(id) as ObservedTrack

func designate(id: String, category: String, sender: String) -> bool:
 if category not in ["primary","threat"] or sender.is_empty(): return false
 var track:=get_track(id)
 if track==null or not track.present or track.age(now)>=MAX_AGE: return false
 if track.kind!=("ship" if category=="primary" else "missile"): return false
 var record:=CrewDesignation.new()
 record.target_id=id
 record.sender_role=sender
 record.issued_seconds=now
 record.category=category
 if category=="primary": primary=record
 else: threat=record
 designation_changed.emit(category,id,sender,now)
 return true

func clear(category: String, sender: String) -> void:
 if category=="primary": primary=null
 elif category=="threat": threat=null
 else: return
 designation_changed.emit(category,"",sender,now)

func clear_selected(id: String, sender: String) -> void:
 if primary!=null and primary.target_id==id: clear("primary",sender)
 if threat!=null and threat.target_id==id: clear("threat",sender)

func summary() -> String:
 return "PILOT %s | THREAT %s"%[primary.target_id if primary!=null else "—",threat.target_id if threat!=null else "—"]

func warning_tracks(origin: Vector3, velocity: Vector3) -> Array[ObservedTrack]:
 var ranked: Array[Dictionary]=[]
 for track: ObservedTrack in tracks.values():
  if track.kind!="missile": continue
  var priority: bool=threat!=null and threat.target_id==track.id
  var approach:=track.approach(origin,velocity,now)
  if priority or (approach.x>0 and approach.x<=20 and approach.z<=100):
   ranked.append({"track":track,"score":-1.0 if priority else approach.x})
 ranked.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
  return a.score<b.score if a.score!=b.score else a.track.id<b.track.id)
 var result: Array[ObservedTrack]=[]
 for row in ranked: result.append(row.track)
 return result
