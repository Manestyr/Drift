class_name PilotInput
extends RefCounted

static func sample(command: FlightCommand, source: PlayerInput = null) -> void:
 if source != null:
  source.sample_flight(command)
 else:
  sample_keyboard(command)

static func sample_keyboard(command: FlightCommand) -> void:
 command.translation = Vector3(
  Input.get_axis("left", "right"),
  Input.get_axis("down", "up"),
  Input.get_axis("forward", "back"))
 command.rotation = Vector3(
  Input.get_axis("pitch_down", "pitch_up"),
  Input.get_axis("yaw_right", "yaw_left"),
  Input.get_axis("roll_right", "roll_left"))
 command.main_engine = Input.get_action_strength("main_engine")
