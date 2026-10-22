class_name ComputerInstrument
extends InstrumentFace

func _init() -> void:
 title = "03 / FLIGHT COMPUTER"

func draw_content() -> void:
 text_at(Vector2(20, 79), "ROT RATE %s | HOLD %s" % ["ON" if telemetry.stabilization else "OFF", "ON" if telemetry.hold else "OFF"], TEXT, 24)
 text_at(Vector2(20, 111), "LATERAL ASSIST " + ("ON" if telemetry.drift_active else "OFF"), GREEN if telemetry.drift_active else DIM, 24)
 text_at(Vector2(20, 141), "DRIFT CANCEL ACTIVE" if telemetry.drift_active else "DRIFT CANCEL / RELEASED", GREEN if telemetry.drift_active else DIM, 23)
 text_at(Vector2(20, 173), "D [%+.2f, %+.2f] m/s" % [telemetry.drift_vector.x, telemetry.drift_vector.y], ORANGE, 24)
 var eta := "~%.1f s" % telemetry.drift_eta if telemetry.drift_eta >= 0 else "-- / MANUAL OR IDLE"
 text_at(Vector2(20, 201), "DRIFT ETA " + eta, DIM, 21)
 text_at(Vector2(20, 233), "RETRO " + telemetry.retrograde_status, GREEN if telemetry.retrograde_active else BLUE, 21)
 var rate := telemetry.angular_rate_local * (180 / PI)
 for axis in range(3):
  text_at(Vector2(20 + axis * 170, 265), ["PITCH °/s", "YAW °/s", "ROLL °/s"][axis], DIM, 21)
  text_at(Vector2(20 + axis * 170, 294), "%+.1f" % rate[axis], TEXT, 28)
 var axes := ""
 for i in range(3):
  if telemetry.brake_axes[i] > 0: axes += ["X ", "Y ", "Z "][i]
 if telemetry.roll_brake: axes += "ROLL"
 text_at(Vector2(20, 325), "TRANS BRAKE " + ("IDLE" if axes.is_empty() else axes), TEXT, 22)
 text_at(Vector2(20, 354), "FRAME " + ("ARENA REST" if telemetry.reference_name.begins_with("Arena") else "CONVOY -20 m/s Z"), BLUE, 21)
 draw_rect(Rect2(20, 368, 472, 12), DIM.darkened(0.65))
 draw_rect(Rect2(20, 368, 472 * telemetry.progress, 12), GREEN)
 var braking := telemetry.brake_axes != Vector3.ZERO
 var braking_eta := "~%.1f s" % telemetry.eta if telemetry.eta >= 0 else "WAIT / MANUAL"
 text_at(Vector2(20, 410), "%.0f%% ETA %s" % [telemetry.progress * 100, braking_eta] if braking else "COAST / NO LINEAR BRAKE", TEXT, 24)
 text_at(Vector2(20, 438), telemetry.crew_safety_status, DIM, 18)
