class_name PilotInput
extends RefCounted

static func sample(command: FlightCommand, source: PlayerInput = null, delta: float = 1.0 / 60.0) -> void:
 if source != null:
  source.sample_flight(command, delta)
 else:
  sample_keyboard(command)

static func sample_keyboard(command: FlightCommand) -> void:
 command.clear()
 command.drift_cancel = Input.is_action_pressed("drift_cancel")
 command.brake_all = Input.is_action_pressed("brake_all")
 if Input.is_action_pressed("flight_modifier"):
  command.brake_axes = Vector3(float(Input.is_action_pressed("left")),
   float(Input.is_action_pressed("up")), float(Input.is_action_pressed("forward")))
  command.brake_roll = Input.is_action_pressed("brake_roll")
  return
 command.translation = Vector3(
  Input.get_axis("left", "right"),
  Input.get_axis("down", "up"),
  Input.get_axis("forward", "back"))
 command.rotation = Vector3(
  Input.get_axis("pitch_down", "pitch_up"),
  Input.get_axis("yaw_right", "yaw_left"),
  Input.get_axis("roll_right", "roll_left"))
 command.main_engine = Input.get_action_strength("main_engine")
