class_name InstrumentFace
extends Control

const BLUE := Color(0.26, 0.57, 0.9)
const ORANGE := Color(0.94, 0.55, 0.23)
const GREEN := Color(0.35, 0.79, 0.54)
const TEXT := Color(0.8, 0.86, 0.85)
const DIM := Color(0.46, 0.55, 0.57)
const BACKGROUND := Color(0.016, 0.027, 0.032)
var telemetry := ShipTelemetry.new()
var last_tick: int = -1
var title: String = "INSTRUMENT"
var transparent_center: bool = false
var font: Font = ThemeDB.fallback_font
var content_drawer: Callable

func _ready() -> void:
 size = Vector2(512, 448)
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func refresh(data: ShipTelemetry) -> void:
 telemetry = data
 last_tick = data.tick
 queue_redraw()

func text_at(at: Vector2, value: String, color: Color = TEXT, pixels: int = 24) -> void:
 draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, color)

func _draw() -> void:
 if not transparent_center:
  draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
 else:
  draw_rect(Rect2(0, 0, 512, 52), BACKGROUND)
  draw_rect(Rect2(0, 302, 512, 146), BACKGROUND)
 draw_rect(Rect2(2, 2, 508, 444), DIM.darkened(0.5), false, 2)
 text_at(Vector2(20, 35), title, TEXT, 26)
 draw_line(Vector2(18, 48), Vector2(494, 48), DIM, 1)
 draw_content()
 if content_drawer.is_valid():
  content_drawer.call()

func draw_content() -> void:
 pass

func signed_bar(y: float, label: String, value: float, automatic: float) -> void:
 text_at(Vector2(20, y + 6), label)
 var center := Vector2(344, y)
 draw_line(center - Vector2(126, 0), center + Vector2(126, 0), DIM.darkened(0.65), 14)
 draw_line(center, center + Vector2(clampf(value, -1, 1) * 126, 0), ORANGE, 12)
 draw_line(center - Vector2(0, 10), center + Vector2(0, 10), TEXT, 2)
 var marker := center + Vector2(clampf(automatic, -1, 1) * 126, 0)
 draw_line(marker - Vector2(0, 13), marker + Vector2(0, 13), GREEN, 3)
 text_at(Vector2(204, y + 7), "-", DIM, 20)
 text_at(Vector2(477, y + 7), "+", DIM, 20)
