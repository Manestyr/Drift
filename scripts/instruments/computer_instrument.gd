class_name ComputerInstrument
extends InstrumentFace

func _init() -> void:
 title = "03 / FLIGHT COMPUTER"

func draw_content() -> void:
 text_at(Vector2(20, 88), "RATE STABILIZE", DIM)
 text_at(Vector2(370, 88), "ON" if telemetry.stabilization else "OFF", GREEN if telemetry.stabilization else DIM, 28)
 text_at(Vector2(20, 126), "ATTITUDE HOLD", DIM)
 text_at(Vector2(370, 126), "ON" if telemetry.hold else "OFF", GREEN if telemetry.hold else DIM, 28)
 var axes := ""
 for i in range(3):
  if telemetry.brake_axes[i] > 0:
   axes += ["X ", "Y ", "Z "][i]
 if telemetry.roll_brake:
  axes += "ROLL"
 text_at(Vector2(20, 166), "BRAKE  " + ("IDLE" if axes.is_empty() else axes), GREEN if not axes.is_empty() else DIM)
 var rate := telemetry.angular_rate_local * (180 / PI)
 for axis in range(3):
  text_at(Vector2(20 + axis * 170, 207), ["PITCH °/s", "YAW °/s", "ROLL °/s"][axis], DIM, 22)
  text_at(Vector2(20 + axis * 170, 242), "%+.1f" % rate[axis], TEXT, 30)
 text_at(Vector2(20, 281), "REFERENCE", DIM, 22)
 text_at(Vector2(20, 313), "ARENA / REST" if telemetry.reference_name.begins_with("Arena") else "CONVOY / WORLD Z -20 m/s", BLUE, 24)
 draw_rect(Rect2(20, 341, 472, 14), DIM.darkened(0.65))
 draw_rect(Rect2(20, 341, 472 * telemetry.progress, 14), GREEN)
 var braking := telemetry.brake_axes != Vector3.ZERO
 text_at(Vector2(20, 392), "%.0f%%   ETA ~%.1f s" % [telemetry.progress * 100, telemetry.eta] if braking else "COAST / NO LINEAR BRAKE", TEXT, 25)
 text_at(Vector2(20, 430), "RCS available %.0f%% | ETA to .05 m/s" % (telemetry.brake_budget * 100), DIM, 21)
