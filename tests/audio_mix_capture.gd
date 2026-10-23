extends SceneTree

# Optional actual audio-mixer integration test (real wall-clock seconds).
# --audio-driver Dummy --script res://tests/audio_mix_capture.gd -- --audio-headless
func _initialize() -> void: call_deferred("run")
func capture(record: AudioEffectRecord, seconds: float, path: String) -> float:
 record.set_recording_active(true)
 await create_timer(seconds).timeout
 record.set_recording_active(false)
 var wav:=record.get_recording()
 var peak:=0.0
 for offset in range(0,wav.data.size(),2):
  peak=maxf(peak,absf(float(wav.data.decode_s16(offset)))/32768.0)
 assert(wav.save_to_wav(path)==OK)
 print("MIX ",path," bytes=",wav.data.size()," peak=",peak)
 return peak
func run() -> void:
 if DisplayServer.get_name()=="headless" and not "--audio-headless" in OS.get_cmdline_user_args():
  push_error("Pass -- --audio-headless to enable the real mixer for this fixture")
  quit(1)
  return
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.pause_menu.save_settings_on_close=false
 var record:=AudioEffectRecord.new()
 var index:=AudioServer.get_bus_index("Ship")
 AudioServer.add_bus_effect(index,record)
 game.station.enter("audio-fixture")
 Input.action_press("main_engine")
 var interior_peak:=await capture(record,2.0,"/tmp/drift032-ship.wav")
 game._toggle_exterior()
 await create_timer(0.4).timeout
 var vacuum_peak:=await capture(record,1.0,"/tmp/drift032-vacuum.wav")
 Input.action_release("main_engine")
 AudioServer.remove_bus_effect(index,AudioServer.get_bus_effect_count(index)-1)
 await create_timer(1.3).timeout
 game.queue_free()
 await process_frame
 var passed:=interior_peak>0.001 and interior_peak<0.8 and vacuum_peak<0.0001
 print("Audio mix integration: ","PASS" if passed else "FAIL")
 quit(0 if passed else 1)
