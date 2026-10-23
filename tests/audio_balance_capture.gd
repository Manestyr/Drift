extends SceneTree

var rows: Array[Dictionary]=[]
var game: Node
var records: Dictionary={}
class Pulse:
 extends Node
 var active: bool=false
 var elapsed: float=0
 func _process(dt: float) -> void:
  if active:
   elapsed+=dt
   if fmod(elapsed,0.16)<0.08: Input.action_press("right")
   else: Input.action_release("right")
var pulse:=Pulse.new()
func _initialize() -> void: call_deferred("run")
func measure(name: String, duration: float) -> Dictionary:
 for record: AudioEffectRecord in records.values(): record.set_recording_active(true)
 await create_timer(duration).timeout
 var result: Dictionary={"phase":name}
 for bus: String in records:
  var record: AudioEffectRecord=records[bus]
  record.set_recording_active(false)
  var wav:=record.get_recording()
  wav.save_to_wav("/tmp/drift033-"+name+"-"+bus+".wav")
  var samples:=wav.data
  var peak:=0.0
  var energy:=0.0
  for offset in range(0,samples.size(),2):
   var value:=float(samples.decode_s16(offset))/32768.0
   peak=maxf(peak,absf(value))
   energy+=value*value
  result[bus]={"peak":peak,"rms":sqrt(energy/maxi(1,wav.data.size()/2)),"bytes":wav.data.size()}
 rows.append(result)
 print("AUDIO ",JSON.stringify(result))
 return result
func run() -> void:
 if not "--audio-headless" in OS.get_cmdline_user_args():
  push_error("Real mixer opt-in required: -- --audio-headless")
  quit(1)
  return
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 root.add_child(pulse)
 game.pause_menu.save_settings_on_close=false
 for bus: String in ["Master","Ship","Warnings"]:
  var record:=AudioEffectRecord.new()
  AudioServer.add_bus_effect(AudioServer.get_bus_index(bus),record)
  records[bus]=record
 game.station.enter("audio-rig")
 Input.action_press("main_engine")
 await create_timer(0.7).timeout
 var main:=await measure("main",2.5)
 Input.action_release("main_engine")
 await create_timer(1.1).timeout
 pulse.active=true
 var rcs:=await measure("frequent-rcs",2.5)
 pulse.active=false
 Input.action_release("right")
 await create_timer(0.8).timeout
 var encounter:=CombatEncounter.new() # isolated observed-warning fixture, no AI
 encounter.player_sensors=SensorSuite.new()
 var inbound:=SensorContact.new()
 inbound.team=1
 inbound.kind="missile"
 inbound.quality=1
 inbound.velocity_known=true
 inbound.relative_position=Vector3(0,0,-200)
 inbound.relative_velocity=Vector3(0,0,200)
 encounter.player_sensors.contacts=[inbound]
 game.audio.encounter=encounter
 Input.action_press("main_engine")
 await create_timer(0.7).timeout
 var warning:=await measure("urgent-warning",2.5)
 game.audio.encounter=null
 game._toggle_exterior()
 await create_timer(0.5).timeout
 var vacuum:=await measure("vacuum",1.0)
 Input.action_release("main_engine")
 for bus: String in records:
  var index:=AudioServer.get_bus_index(bus)
  AudioServer.remove_bus_effect(index,AudioServer.get_bus_effect_count(index)-1)
 await create_timer(1.2).timeout
 encounter.free()
 game.queue_free()
 pulse.queue_free()
 await process_frame
 var good: bool=main.Ship.rms>0.06 and main.Ship.rms>rcs.Ship.rms*4 and warning.Warnings.rms>0.01 and warning.Master.peak<0.89 and vacuum.Ship.peak<0.0001
 var file:=FileAccess.open("res://docs/audio-0.3.3.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(rows," ")+"\n")
 print("Audio balance integration: ","PASS" if good else "FAIL")
 quit(0 if good else 1)
