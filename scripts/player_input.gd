class_name PlayerInput
extends Node

signal device_changed(gamepad: bool)
var settings := InputSettings.new()
var using_gamepad: bool = false
# Device ownership belongs to this adapter, never the body/station. Only one
# local operator exists today. Future local players need scoped action sources.
var active_device: int = -1
var mouse_steer: Vector2 = Vector2.ZERO
var orbiting: bool = false
var _wait_pad_neutral: bool = false
var blocked_actions: Array[String] = []
var controller_name: String = ""

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 settings.load_file()
 settings.apply_advanced_bindings()
 Input.joy_connection_changed.connect(_connection_changed)

func _input(event: InputEvent) -> void:
 observe(event)

func observe(event: InputEvent) -> void:
 if event is InputEventJoypadMotion:
  var threshold := settings.deadzone
  if event.axis == JOY_AXIS_TRIGGER_LEFT or event.axis == JOY_AXIS_TRIGGER_RIGHT:
   threshold = 0.05
  if event.axis_value > threshold + 0.000001 or (event.axis <= JOY_AXIS_RIGHT_Y and event.axis_value < -threshold - 0.000001):
   _adopt_controller(event)
   _set_device(true)
 elif event is InputEventJoypadButton and event.pressed:
  _adopt_controller(event)
  _set_device(true)
 elif event is InputEventKey and event.pressed and not event.echo:
  _set_device(false)
 elif event is InputEventMouseButton and event.pressed:
  _set_device(false)
 elif event is InputEventMouseMotion and event.relative.length() > 2.0:
  _set_device(false)

func _adopt_controller(event: InputEvent) -> void:
 if active_device>=0 and active_device!=event.device:
  _release_pad_actions()
  # Reapply only this fresh event, via the existing Input Map. No event replay
  # (which would double-fire station/weapon button handlers).
  for action: StringName in InputMap.get_actions():
   if event.is_action(action):
    var strength:=event.get_action_strength(action)
    if strength>0: Input.action_press(action,strength)
 controller_name=Input.get_joy_name(event.device)
 active_device=event.device

func _release_pad_actions() -> void:
 for action: StringName in InputMap.get_actions():
  for event in InputMap.action_get_events(action):
   if event is InputEventJoypadMotion or event is InputEventJoypadButton:
    Input.action_release(action)
    break
 clear_mouse()

func _set_device(gamepad: bool) -> void:
 if using_gamepad != gamepad:
  clear_mouse()
  using_gamepad = gamepad
  device_changed.emit(gamepad)

func _connection_changed(device: int, connected: bool) -> void:
 if not connected and device == active_device:
  _release_pad_actions()
  active_device = -1
  _set_device(false)

# Explicit radial deadzone: remap [deadzone, 1] to [0, 1], never normalize
# partial deflections to full power. Map actions have zero deadzone to avoid
# a second, independent filter. Trigger actions have a separate 0.05 filter.
static func filter_stick(value: Vector2, deadzone: float) -> Vector2:
 var length := value.length()
 var threshold := clampf(deadzone, 0.05, 0.4)
 if length <= threshold + 0.000001:
  return Vector2.ZERO
 return value / length * clampf((length - threshold) / (1.0 - threshold), 0.0, 1.0)

func stick(prefix: String) -> Vector2:
 var raw := Vector2(
  Input.get_action_raw_strength(prefix + "_right") - Input.get_action_raw_strength(prefix + "_left"),
  Input.get_action_raw_strength(prefix + "_down") - Input.get_action_raw_strength(prefix + "_up"))
 return filter_stick(raw, settings.deadzone)

func movement() -> Vector2:
 _clear_released()
 if using_gamepad:
  return Vector2.ZERO if blocked_actions.any(func(a: String) -> bool: return a.begins_with("pad_left_")) else stick("pad_left")
 return Vector2(flight_strength("right")-flight_strength("left"),flight_strength("back")-flight_strength("forward")).limit_length()

func camera_rate() -> Vector2:
 _clear_released()
 if blocked_actions.any(func(a: String) -> bool: return a.begins_with("pad_right_")): return Vector2.ZERO
 if not using_gamepad:
  return Vector2.ZERO
 var value := stick("pad_right") * settings.sensitivity * 2.5
 if settings.invert_y:
  value.y = -value.y
 return value

func set_orbit_mode(value: bool) -> void:
 if orbiting and not value:
  _wait_pad_neutral = stick("pad_right") != Vector2.ZERO or Input.get_action_strength("pad_main") > 0 or Input.get_action_strength("pad_reverse") > 0
 orbiting = value

func clear_mouse() -> void:
 mouse_steer = Vector2.ZERO

func add_flight_mouse(relative: Vector2) -> void:
 mouse_steer = (mouse_steer + relative * 0.008 * settings.mouse_flight_sensitivity).limit_length()

func computer_event(event: InputEvent, action: String) -> bool:
 if event is InputEventJoypadButton:
  var bindings := {"brake_all": "pad_fc_down", "stabilize": "pad_fc_up", "hold_attitude": "pad_fc_left", "grid": "pad_fc_right"}
  if settings.computer_layout == 1:
   bindings = {"brake_all": "pad_fc_up", "stabilize": "pad_fc_down", "hold_attitude": "pad_fc_right", "grid": "pad_fc_left"}
  return event.is_action_pressed(bindings[action])
 return event.is_action_pressed(action)

func drift_held() -> bool:
 return Input.is_action_pressed("pad_drift_cancel") and (settings.drift_modifier < 0 or Input.is_action_pressed("pad_drift_modifier"))

func pad_button_consumed(index: int) -> bool:
 if index == settings.drift_modifier and Input.is_action_pressed("pad_drift_modifier"):
  return true
 if index == settings.retrograde_button and Input.is_action_pressed("pad_retrograde"):
  return true
 return drift_held() and index in [settings.drift_button, settings.drift_modifier]

func orbit_held() -> bool:
 return not "pad_orbit" in blocked_actions and Input.is_action_pressed("pad_orbit") and not pad_button_consumed(JOY_BUTTON_RIGHT_STICK)

func advanced_consumes(event: InputEvent) -> bool:
 if not event is InputEventJoypadButton:
  return false
 return event.is_action("pad_retrograde") or event.button_index == settings.drift_modifier or pad_button_consumed(event.button_index)

func controller_brake_held() -> bool:
 var index := JOY_BUTTON_DPAD_DOWN if settings.computer_layout == 0 else JOY_BUTTON_DPAD_UP
 return Input.is_action_pressed("pad_fc_down" if settings.computer_layout == 0 else "pad_fc_up") and not pad_button_consumed(index)

func symbol_scheme() -> int:
 return settings.symbol_scheme if settings.symbol_scheme!=0 else ControllerLabels.detect(controller_name)

func button_label(index: int) -> String:
 return ControllerLabels.button(index,symbol_scheme())

func reset_context() -> void:
 clear_mouse()
 # Quarantine controls already held at a context boundary, until real neutral.
 # Never release Godot's global actions: that would lose physical release state.
 for action: StringName in InputMap.get_actions():
  if String(action).begins_with("pad_") or action in ["brake_all","drift_cancel","flight_modifier","main_engine","forward","back","left","right","up","down","roll_left","roll_right","pitch_up","pitch_down","yaw_left","yaw_right"]:
   if Input.is_action_pressed(action) and not String(action) in blocked_actions:
    blocked_actions.append(String(action))

func _clear_released() -> void:
 for action in blocked_actions.duplicate():
  if not Input.is_action_pressed(action): blocked_actions.erase(action)

func flight_strength(action: String) -> float:
 return 0.0 if action in blocked_actions else Input.get_action_strength(action)

func sample_flight(command: FlightCommand, delta: float = 1.0 / 60.0) -> void:
 _clear_released()
 if not using_gamepad:
  PilotInput.sample_keyboard(command)
  if "forward" in blocked_actions or "back" in blocked_actions: command.translation.z=0
  if "left" in blocked_actions or "right" in blocked_actions: command.translation.x=0
  if "up" in blocked_actions or "down" in blocked_actions: command.translation.y=0
  if "pitch_up" in blocked_actions or "pitch_down" in blocked_actions: command.rotation.x=0
  if "yaw_left" in blocked_actions or "yaw_right" in blocked_actions: command.rotation.y=0
  if "roll_left" in blocked_actions or "roll_right" in blocked_actions: command.rotation.z=0
  if "brake_all" in blocked_actions: command.brake_all=false
  if "drift_cancel" in blocked_actions: command.drift_cancel=false
  if "flight_modifier" in blocked_actions:
   command.brake_axes=Vector3.ZERO
   command.brake_roll=false
  if "main_engine" in blocked_actions: command.main_engine=0
  if not Input.is_action_pressed("flight_modifier"):
   command.rotation += Vector3(-mouse_steer.y, -mouse_steer.x, 0)
   command.rotation = command.rotation.limit_length()
  else:
   clear_mouse()
  mouse_steer = mouse_steer.move_toward(Vector2.ZERO, delta * 3.0)
  return
 command.clear()
 var left := Vector2.ZERO if blocked_actions.any(func(a: String) -> bool: return a.begins_with("pad_left_")) else stick("pad_left") * settings.sensitivity
 if _wait_pad_neutral and stick("pad_right") == Vector2.ZERO and flight_strength("pad_main") == 0 and flight_strength("pad_reverse") == 0:
  _wait_pad_neutral = false
 var camera_controls := orbiting or _wait_pad_neutral
 var right := Vector2.ZERO if camera_controls or blocked_actions.any(func(a: String) -> bool: return a.begins_with("pad_right_")) else stick("pad_right")
 var pitch := -left.y
 if settings.invert_y:
  pitch = -pitch
 var roll_left := 0.0 if pad_button_consumed(JOY_BUTTON_LEFT_SHOULDER) else flight_strength("pad_roll_left")
 var roll_right := 0.0 if pad_button_consumed(JOY_BUTTON_RIGHT_SHOULDER) else flight_strength("pad_roll_right")
 command.rotation = Vector3(pitch, -left.x, roll_left - roll_right).limit_length()
 command.translation = Vector3(right.x, -right.y, 0.0 if camera_controls else flight_strength("pad_reverse")).limit_length()
 command.main_engine = 0.0 if camera_controls else flight_strength("pad_main")
 command.drift_cancel = drift_held() and not "pad_drift_cancel" in blocked_actions and not "pad_drift_modifier" in blocked_actions
 if controller_brake_held() and not ("pad_fc_down" in blocked_actions or "pad_fc_up" in blocked_actions):
  match settings.brake_mode:
   0: command.brake_all = true
   1: command.brake_axes.z = 1.0
   2: command.brake_axes.x = 1.0
   3: command.brake_axes.y = 1.0
   4: command.brake_roll = true

func hints(piloting: bool) -> String:
 return ControllerLabels.adapt(_hints(piloting),symbol_scheme()) if using_gamepad else _hints(piloting)

func _hints(piloting: bool) -> String:
 if using_gamepad:
  if piloting:
   var layout_hint := "D-pad Down: brake / Up: stabilize / Left: hold / Right: grid"
   if settings.computer_layout == 1:
    layout_hint = "D-pad Up: brake / Down: stabilize / Right: hold / Left: grid"
   var mode_name: String = ["ALL", "local Z", "local X", "local Y", "roll"][settings.brake_mode]
   return "A / Cross: exit | Y / Triangle: camera | Start / Options: pause\nLS: pitch/yaw | RS: lateral/vertical RCS | RT/R2: main | LT/L2: reverse RCS\nLB/L1 + RB/R1: roll\n%s | brake mode: %s\nExterior: hold RS click + RS to orbit, triggers to zoom" % [layout_hint, mode_name]
  return "LS: walk | RS: look | A / Cross: interact | Y / Triangle: camera\nStart / Options: pause and settings"
 if not piloting:
  return "WASD: walk | Mouse: look | F: seat | V: exterior | G: grid | P: pause | Esc: mouse"
 return "F: seat | V: exterior | P: pause/settings | Esc: mouse | F5: reset\nMouse: pitch/yaw | WASD + Space/Shift: RCS | Q/E: roll | LMB: main\nX: brake | Ctrl+W/A/Space/R: axis/roll brake | T: rate assist | H: hold | G: grid | C: drift | B: retrograde"
