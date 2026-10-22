class_name InputSettings
extends RefCounted

const PATH := "user://input_settings.cfg"
var mouse_flight_sensitivity: float = 1.0
var deadzone: float = 0.15
var sensitivity: float = 1.0
var invert_y: bool = false
var computer_layout: int = 0
var brake_mode: int = 0

func load_file(path: String = PATH) -> void:
 var config := ConfigFile.new()
 if config.load(path) != OK:
  return
 mouse_flight_sensitivity = clampf(float(config.get_value("mouse", "flight_sensitivity", 1.0)), 0.25, 2.0)
 deadzone = clampf(float(config.get_value("controller", "deadzone", 0.15)), 0.05, 0.4)
 sensitivity = clampf(float(config.get_value("controller", "sensitivity", 1.0)), 0.25, 2.0)
 invert_y = bool(config.get_value("controller", "invert_y", false))
 computer_layout = clampi(int(config.get_value("controller", "computer_layout", 0)), 0, 1)
 brake_mode = clampi(int(config.get_value("controller", "brake_mode", 0)), 0, 4)

func save_file(path: String = PATH) -> Error:
 var config := ConfigFile.new()
 config.set_value("mouse", "flight_sensitivity", mouse_flight_sensitivity)
 config.set_value("controller", "deadzone", deadzone)
 config.set_value("controller", "sensitivity", sensitivity)
 config.set_value("controller", "invert_y", invert_y)
 config.set_value("controller", "computer_layout", computer_layout)
 config.set_value("controller", "brake_mode", brake_mode)
 return config.save(path)
