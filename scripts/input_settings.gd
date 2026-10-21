class_name InputSettings
extends RefCounted

const PATH := "user://input_settings.cfg"
var deadzone: float = 0.15
var sensitivity: float = 1.0
var invert_y: bool = false

func load_file(path: String = PATH) -> void:
 var config := ConfigFile.new()
 if config.load(path) != OK:
  return
 deadzone = clampf(float(config.get_value("controller", "deadzone", 0.15)), 0.05, 0.4)
 sensitivity = clampf(float(config.get_value("controller", "sensitivity", 1.0)), 0.25, 2.0)
 invert_y = bool(config.get_value("controller", "invert_y", false))

func save_file(path: String = PATH) -> Error:
 var config := ConfigFile.new()
 config.set_value("controller", "deadzone", deadzone)
 config.set_value("controller", "sensitivity", sensitivity)
 config.set_value("controller", "invert_y", invert_y)
 return config.save(path)
