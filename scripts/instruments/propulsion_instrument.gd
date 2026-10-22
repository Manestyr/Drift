class_name PropulsionInstrument
extends InstrumentFace

func _init() -> void:
 title = "02 / PROPULSION & RCS"

func draw_content() -> void:
 text_at(Vector2(20, 81), "MAIN", ORANGE)
 draw_rect(Rect2(138, 61, 252, 22), DIM.darkened(0.65))
 draw_rect(Rect2(138, 61, 252 * telemetry.main_fraction, 22), ORANGE)
 text_at(Vector2(402, 81), "%3.0f%%" % (telemetry.main_fraction * 100), ORANGE)
 text_at(Vector2(20, 119), "%.2f m/s²    /    %.2f g" % [telemetry.acceleration_world.length(), telemetry.acceleration_world.length() / 9.80665], GREEN, 28)
 text_at(Vector2(20, 155), "TRANSLATION   - AXIS +", DIM, 22)
 signed_bar(182, "X  PORT / STBD", telemetry.rcs_translation.x, telemetry.auto_translation.x)
 signed_bar(217, "Y  DOWN / UP", telemetry.rcs_translation.y, telemetry.auto_translation.y)
 signed_bar(252, "Z  FWD / AFT", telemetry.rcs_translation.z, telemetry.auto_translation.z)
 text_at(Vector2(20, 291), "ROTATION      - AXIS +", DIM, 22)
 signed_bar(317, "X  PITCH", telemetry.rcs_rotation.x, telemetry.auto_rotation.x)
 signed_bar(352, "Y  YAW", telemetry.rcs_rotation.y, telemetry.auto_rotation.y)
 signed_bar(387, "Z  ROLL", telemetry.rcs_rotation.z, telemetry.auto_rotation.z)
 text_at(Vector2(20, 430), "ORANGE actual  |  GREEN computer", DIM, 22)
