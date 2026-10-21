class_name PlayerInput
extends Node

signal device_changed(gamepad: bool)
var settings := InputSettings.new()
var using_gamepad: bool = false
# Device ownership belongs to this adapter, never the body/station. Only one
# local operator exists today. Future local players need scoped action sources.
var active_device: int = -1

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 settings.load_file()
 Input.joy_connection_changed.connect(_connection_changed)

func _input(event: InputEvent) -> void:
 observe(event)

func observe(event: InputEvent) -> void:
 if event is InputEventJoypadMotion:
  var threshold := settings.deadzone
  if event.axis == JOY_AXIS_TRIGGER_LEFT or event.axis == JOY_AXIS_TRIGGER_RIGHT:
   threshold = 0.05
  if event.axis_value > threshold + 0.000001 or (event.axis <= JOY_AXIS_RIGHT_Y and event.axis_value < -threshold - 0.000001):
   active_device = event.device
   _set_device(true)
 elif event is InputEventJoypadButton and event.pressed:
  active_device = event.device
  _set_device(true)
 elif event is InputEventKey and event.pressed and not event.echo:
  _set_device(false)
 elif event is InputEventMouseButton and event.pressed:
  _set_device(false)
 elif event is InputEventMouseMotion and event.relative.length() > 2.0:
  _set_device(false)

func _set_device(gamepad: bool) -> void:
 if using_gamepad != gamepad:
  using_gamepad = gamepad
  device_changed.emit(gamepad)

func _connection_changed(device: int, connected: bool) -> void:
 if not connected and device == active_device:
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
 if using_gamepad:
  return stick("pad_left")
 return Input.get_vector("left", "right", "forward", "back")

func camera_rate() -> Vector2:
 if not using_gamepad:
  return Vector2.ZERO
 var value := stick("pad_right") * settings.sensitivity * 2.5
 if settings.invert_y:
  value.y = -value.y
 return value

func sample_flight(command: FlightCommand) -> void:
 if not using_gamepad:
  PilotInput.sample_keyboard(command)
  return
 var left := stick("pad_left") * settings.sensitivity
 var right := stick("pad_right")
 var pitch := -left.y
 if settings.invert_y:
  pitch = -pitch
 command.rotation = Vector3(pitch, -left.x,
  Input.get_axis("pad_roll_right", "pad_roll_left")).limit_length()
 command.translation = Vector3(right.x, -right.y, Input.get_action_strength("pad_reverse")).limit_length()
 command.main_engine = Input.get_action_strength("pad_main")

func hints(piloting: bool) -> String:
 if using_gamepad:
  if piloting:
   return "A / Cross: exit | Y / Triangle: camera | Start / Options: pause\nLS: pitch/yaw | RS: lateral/vertical RCS | RT/R2: main | LT/L2: reverse RCS\nLB/L1 + RB/R1: roll | release thrust = coast"
  return "LS: walk | RS: look | A / Cross: interact | Y / Triangle: camera\nStart / Options: pause and settings"
 return "E: seat / exit | V: exterior | Esc: mouse | P: pause/settings | F3: debug | F5: reset\nWASD + mouse: walk | Pilot WASD/Space/Ctrl: RCS, Shift: main\nArrows: pitch/yaw | Q/R: roll | thrust release = coast"
