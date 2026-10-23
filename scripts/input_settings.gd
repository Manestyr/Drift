class_name InputSettings
extends RefCounted

const PATH := "user://input_settings.cfg"
var mouse_flight_sensitivity: float = 1.0
var deadzone: float = 0.15
var sensitivity: float = 1.0
var invert_y: bool = false
# 0 auto, 1 PlayStation, 2 Xbox.
var symbol_scheme: int = 0
var audio_levels: Dictionary = {"Master":0.8,"Ship":0.75,"Warnings":0.65,"UI":0.5}
var computer_layout: int = 0
var brake_mode: int = 0
var drift_button: int = JOY_BUTTON_X
var drift_modifier: int = -1
var retrograde_button: int = JOY_BUTTON_BACK

func load_file(path: String = PATH) -> void:
 var config := ConfigFile.new()
 if config.load(path) != OK:
  return
 symbol_scheme=clampi(int(config.get_value("controller","symbol_scheme",0)),0,2)
 for bus: String in audio_levels:
  audio_levels[bus]=clampf(float(config.get_value("audio",bus,audio_levels[bus])),0,1)
 mouse_flight_sensitivity = clampf(float(config.get_value("mouse", "flight_sensitivity", 1.0)), 0.25, 2.0)
 deadzone = clampf(float(config.get_value("controller", "deadzone", 0.15)), 0.05, 0.4)
 sensitivity = clampf(float(config.get_value("controller", "sensitivity", 1.0)), 0.25, 2.0)
 invert_y = bool(config.get_value("controller", "invert_y", false))
 computer_layout = clampi(int(config.get_value("controller", "computer_layout", 0)), 0, 1)
 brake_mode = clampi(int(config.get_value("controller", "brake_mode", 0)), 0, 4)
 drift_button = clampi(int(config.get_value("advanced", "drift_button", JOY_BUTTON_X)), 0, JOY_BUTTON_MAX - 1)
 drift_modifier = clampi(int(config.get_value("advanced", "drift_modifier", -1)), -1, JOY_BUTTON_MAX - 1)
 retrograde_button = clampi(int(config.get_value("advanced", "retrograde_button", JOY_BUTTON_BACK)), 0, JOY_BUTTON_MAX - 1)
 # OS/menu controls stay reserved, even for hand-edited configurations.
 if drift_button in [JOY_BUTTON_START, JOY_BUTTON_GUIDE]: drift_button = JOY_BUTTON_X
 if drift_modifier in [JOY_BUTTON_START, JOY_BUTTON_GUIDE]: drift_modifier = -1
 if retrograde_button in [JOY_BUTTON_START, JOY_BUTTON_GUIDE] or retrograde_button == drift_button: retrograde_button = JOY_BUTTON_BACK if drift_button != JOY_BUTTON_BACK else JOY_BUTTON_LEFT_STICK

func apply_advanced_bindings() -> void:
 if drift_modifier == retrograde_button:
  drift_modifier = -1
 for action: String in ["pad_drift_cancel", "pad_drift_modifier", "pad_retrograde"]:
  if not InputMap.has_action(action):
   InputMap.add_action(action)
  Input.action_release(action)
  InputMap.action_erase_events(action)
 var indices := [drift_button, drift_modifier, retrograde_button]
 var names := ["pad_drift_cancel", "pad_drift_modifier", "pad_retrograde"]
 for i in range(3):
  if indices[i] >= 0:
   var event := InputEventJoypadButton.new()
   event.device = -1
   event.button_index = indices[i]
   InputMap.action_add_event(names[i], event)

func save_file(path: String = PATH) -> Error:
 var config := ConfigFile.new()
 config.set_value("controller","symbol_scheme",symbol_scheme)
 for bus: String in audio_levels: config.set_value("audio",bus,audio_levels[bus])
 config.set_value("mouse", "flight_sensitivity", mouse_flight_sensitivity)
 config.set_value("controller", "deadzone", deadzone)
 config.set_value("controller", "sensitivity", sensitivity)
 config.set_value("controller", "invert_y", invert_y)
 config.set_value("controller", "computer_layout", computer_layout)
 config.set_value("controller", "brake_mode", brake_mode)
 config.set_value("advanced", "drift_button", drift_button)
 config.set_value("advanced", "drift_modifier", drift_modifier)
 config.set_value("advanced", "retrograde_button", retrograde_button)
 return config.save(path)
