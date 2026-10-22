class_name EnemyPilot
extends RefCounted

var weave: float = 0.12
var phase_offset: float = 0.0
var threat: SensorContact
var phase: String = "SEARCH"
var time: float = 0.0

func command_for(contact: SensorContact, basis: Basis, velocity: Vector3, command: FlightCommand, dt: float) -> void:
 command.clear()
 time += dt
 if contact==null or not contact.acquired():
  phase="SEARCH / COAST"
  return
 # Range control plus deliberate transverse weaving; never airplane steering.
 var direction := contact.relative_position.normalized()
 var approach := clampf((contact.relative_position.length()-950.0)/600.0,-0.25,0.25)
 var relative_velocity := contact.relative_velocity if contact.velocity_known else Vector3.ZERO
 var demand := direction*approach+relative_velocity*0.008
 demand.x += sin(time*0.4+phase_offset)*weave
 demand.y += cos(time*0.31+phase_offset)*weave*0.667
 if threat!=null and threat.acquired() and threat.age_seconds<1.0:
  var evade := Vector3(-threat.relative_position.z,0,threat.relative_position.x).normalized()
  demand+=evade*weave
 command.translation=demand.limit_length(maxf(0.4,weave*2.2))
 command.rotation=Vector3(0.025*sin(time*0.25),0.025*cos(time*0.23),0)
 phase="WEAVE / STANDOFF" if approach<0.1 else "APPROACH / EVADE"
