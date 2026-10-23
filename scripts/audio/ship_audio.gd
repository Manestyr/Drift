class_name ShipAudio
extends Node3D

# Scene-owned observer, in the interior acoustic World3D. Never attaches sound
# to enemy ships/missiles in vacuum. Structural sounds are muted outside.
var playback_enabled: bool = DisplayServer.get_name()!="headless" or "--audio-headless" in OS.get_cmdline_user_args()
var ship: ShipPhysics
var source: PlayerInput
var exterior: bool = false
var listener_position: Vector3 = Vector3.ZERO
var listener: AudioListener3D
var engine: AudioStreamPlayer3D
var structural: Array[AudioStreamPlayer3D] = []
var alerts: Array[AudioStreamPlayer] = []
var clips: Dictionary = {}
var played: Dictionary = {}
var encounter: CombatEncounter
var _rcs_level: float = 0.0
var _rcs_running: bool = false
var _warning_duck: float = 0.0
var _alarm_timer: float = 0.0
var _sensor_timer: float = 0.0
var _last_contacts: int = 0
var _engine_level: float = 0.0
var _structural_gain: float = 0.0
var _voice: int = 0
var _alert_voice: int = 0

func _ready() -> void:
 name="ShipAudio"
 ensure_buses()
 for clip: String in ["engine","rcs","launch","impact","damage","sensor","alarm","ui","confirm","drone","victory","defeat"]:
  clips[clip]=load("res://assets/audio/"+clip+".wav")
 listener=AudioListener3D.new()
 add_child(listener)
 listener.make_current()
 engine=_structural_player()
 engine.position=Vector3(0,1,12)
 var loop: AudioStreamWAV=clips.engine
 loop.loop_mode=AudioStreamWAV.LOOP_FORWARD
 loop.loop_begin=0
 loop.loop_end=loop.data.size()/2
 engine.stream=loop
 engine.volume_db=-80
 for i in 6: structural.append(_structural_player())
 var rcs_loop: AudioStreamWAV=clips.rcs
 rcs_loop.loop_mode=AudioStreamWAV.LOOP_FORWARD
 rcs_loop.loop_end=rcs_loop.data.size()/2
 structural[0].stream=rcs_loop
 structural[0].attenuation_model=AudioStreamPlayer3D.ATTENUATION_DISABLED
 for i in 4:
  var player:=AudioStreamPlayer.new()
  add_child(player)
  alerts.append(player)
 for bus: String in source.settings.audio_levels: set_level(bus,source.settings.audio_levels[bus])

static func ensure_buses() -> void:
 for bus: String in ["Ship","Warnings","UI"]:
  if AudioServer.get_bus_index(bus)<0:
   AudioServer.add_bus()
   var index:=AudioServer.bus_count-1
   AudioServer.set_bus_name(index,bus)
   AudioServer.set_bus_send(index,"Master")
 # Shared limiter protects the sum of simultaneous voices; stable bus count.
 var master:=AudioServer.get_bus_index("Master")
 var has_limiter:=false
 for i in AudioServer.get_bus_effect_count(master):
  if AudioServer.get_bus_effect(master,i) is AudioEffectLimiter: has_limiter=true
 if not has_limiter:
  var limiter:=AudioEffectLimiter.new()
  limiter.ceiling_db=-1.0
  AudioServer.add_bus_effect(master,limiter)

func _structural_player() -> AudioStreamPlayer3D:
 var player:=AudioStreamPlayer3D.new()
 player.bus="Ship"
 player.unit_size=35
 player.max_distance=90
 player.max_db=0
 add_child(player)
 return player

func set_level(bus: String, linear: float) -> void:
 ensure_buses()
 source.settings.audio_levels[bus]=clampf(linear,0,1)
 var index:=AudioServer.get_bus_index(bus)
 AudioServer.set_bus_mute(index,linear<=0)
 AudioServer.set_bus_volume_db(index,linear_to_db(maxf(linear,0.0001)))

func cue(clip: String, bus: String = "UI", local_point: Vector3 = Vector3.ZERO) -> void:
 if get_tree().paused or not clips.has(clip): return
 if bus=="Ship" and exterior: return
 played[clip]=int(played.get(clip,0))+1
 if bus=="Ship":
  var player:=structural[1+_voice%(structural.size()-1)]
  _voice+=1
  player.position=local_point
  player.stream=clips[clip]
  player.volume_db=-12
  if playback_enabled: player.play()
 else:
  var player:=alerts[0] if bus=="Warnings" else alerts[1+_alert_voice%(alerts.size()-1)]
  _alert_voice+=1
  player.bus=bus
  player.stream=clips[clip]
  player.volume_db=2 if clip=="alarm" else (-8 if bus=="Warnings" else -16)
  if playback_enabled: player.play()

func attach_combat(value: CombatEncounter) -> void:
 encounter=value
 encounter.events.recorded.connect(_combat_event)
 encounter.ended.connect(func(result: String) -> void:
  cue("victory" if result=="VICTORY" else ("defeat" if result=="DEFEAT" else "confirm"),"Warnings"))

func _combat_event(event: Dictionary) -> void:
 var own:=String(event.entity_id)==String(ship.name)
 match event.type:
  "launch":
   if event.payload.get("carrier_id","")==String(ship.name): cue("launch","Ship",Vector3(0,0,-14))
  "missile_hit":
   if event.payload.get("body_id","")==String(ship.name): cue("impact","Ship",ship.to_local(event.payload.point))
  "system_damage":
   if own: cue("damage","Ship")
  "drone_launch":
   if event.entity_id=="BLUE-D1": cue("drone","Ship",Vector3(-3,0,0))
  "drone_recovered": cue("drone","Ship",Vector3(-3,0,0))

func _process(dt: float) -> void:
 listener.position=listener_position
 _engine_level=lerpf(_engine_level,ship.applied_main_thrust_n/ship.main_thrust_n,1-exp(-dt*6))
 _structural_gain=move_toward(_structural_gain,0.0 if exterior else 1.0,dt*8)
 if _engine_level*_structural_gain>0.005:
  if playback_enabled and not engine.playing: engine.play()
 elif engine.playing: engine.stop()
 engine.volume_db=linear_to_db(maxf(0.0001,_engine_level*_structural_gain*1.4*(0.2 if _warning_duck>0 else 1.0)))
 engine.pitch_scale=0.8+_engine_level*0.35
 for i in range(1,structural.size()):
  structural[i].volume_db=-12 if not exterior else -80
 # Audio-only duty smoothing: no recurring transients and no physics changes.
 var duty:=maxf(ship.computer.force_local.length()/maxf(ship.rcs_thrust_n,1),ship.computer.torque_local.length()/maxf(ship.torque_limits_nm.length(),1))
 _rcs_level=lerpf(_rcs_level,clampf(duty,0,1),1-exp(-dt/0.15))
 var rcs_gain:=sqrt(_rcs_level)*_structural_gain*0.25
 structural[0].position=listener_position+Vector3(2,0,1)
 structural[0].volume_db=linear_to_db(maxf(0.0001,rcs_gain))
 if rcs_gain>0.002:
  if not _rcs_running:
   played["rcs"]=int(played.get("rcs",0))+1
   _rcs_running=true
   if playback_enabled: structural[0].play()
 elif _rcs_running:
  structural[0].stop()
  _rcs_running=false
 _warning_duck=maxf(0,_warning_duck-dt)
 _alarm_timer-=dt
 _sensor_timer-=dt
 if encounter!=null:
  var nearest:=INF
  for contact in encounter.player_sensors.contacts:
   if contact.team==1 and contact.kind=="missile" and contact.acquired() and contact.velocity_known:
    var distance:=contact.relative_position.length()
    var closing: float=-contact.relative_position.normalized().dot(contact.relative_velocity)
    if closing>5: nearest=minf(nearest,distance/closing)
  if nearest<12 and _alarm_timer<=0:
   cue("alarm","Warnings")
   _warning_duck=0.4
   _alarm_timer=clampf(nearest/6,0.65,2.0)
  var count:=encounter.player_sensors.contacts.size()
  if count>_last_contacts and _sensor_timer<=0 and _warning_duck<=0:
   cue("sensor","Warnings")
   _sensor_timer=3.0
  _last_contacts=count

func _exit_tree() -> void:
 # Explicitly retire looping playbacks before the World3D/listener disappears.
 if is_instance_valid(engine):
  engine.stop()
  engine.stream=null
 for voice in structural:
  voice.stop()
  voice.stream=null
 for voice in alerts:
  voice.stop()
  voice.stream=null
 clips.clear()
