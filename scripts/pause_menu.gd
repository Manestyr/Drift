class_name PauseMenu
extends CanvasLayer

signal pause_changed(paused: bool)
signal reset_requested
var save_settings_on_close: bool = true
var source: PlayerInput
var panel: PanelContainer
var resume: Button
var status: Label

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 layer = 10
 panel = PanelContainer.new()
 panel.position = Vector2(340, 150)
 panel.custom_minimum_size = Vector2(600, 410)
 add_child(panel)
 var rows := VBoxContainer.new()
 rows.add_theme_constant_override("separation", 14)
 panel.add_child(rows)
 var title := Label.new()
 title.text = "PAUSED — Controller settings"
 rows.add_child(title)
 resume = Button.new()
 resume.text = "Resume / Fortsetzen"
 resume.pressed.connect(func() -> void: set_paused(false))
 rows.add_child(resume)
 _slider(rows, "Stick deadzone", 0.05, 0.4, 0.01, source.settings.deadzone,
  func(value: float) -> void: source.settings.deadzone = value)
 _slider(rows, "Stick sensitivity", 0.25, 2.0, 0.05, source.settings.sensitivity,
  func(value: float) -> void: source.settings.sensitivity = value)
 var invert := CheckButton.new()
 invert.text = "Invert controller Y (look + pitch)"
 invert.button_pressed = source.settings.invert_y
 invert.toggled.connect(func(value: bool) -> void: source.settings.invert_y = value)
 rows.add_child(invert)
 var reset := Button.new()
 reset.text = "Reset ship position and velocities"
 reset.pressed.connect(func() -> void: reset_requested.emit(); set_paused(false))
 rows.add_child(reset)
 var quit_button := Button.new()
 quit_button.text = "Quit / Beenden"
 quit_button.pressed.connect(func() -> void: get_tree().quit())
 rows.add_child(quit_button)
 status = Label.new()
 status.text = "D-pad / arrows: navigate + adjust | A / Cross / Enter: select\nStart / Options / P / B / Circle: resume | settings saved on resume"
 rows.add_child(status)
 # Explicit cyclic vertical focus; horizontal input remains slider adjustment.
 var focusables: Array[Control] = []
 for child in rows.get_children():
  if child is Control and child.focus_mode == Control.FOCUS_ALL:
   focusables.append(child)
 for i in range(focusables.size()):
  focusables[i].focus_neighbor_top = focusables[i].get_path_to(focusables[(i - 1 + focusables.size()) % focusables.size()])
  focusables[i].focus_neighbor_bottom = focusables[i].get_path_to(focusables[(i + 1) % focusables.size()])
 panel.hide()

func _slider(rows: VBoxContainer, title: String, minimum: float, maximum: float,
 step: float, initial: float, changed: Callable) -> void:
 var label := Label.new()
 label.text = "%s: %.2f" % [title, initial]
 rows.add_child(label)
 var slider := HSlider.new()
 slider.min_value = minimum
 slider.max_value = maximum
 slider.step = step
 slider.value = initial
 slider.custom_minimum_size.y = 24
 slider.value_changed.connect(func(value: float) -> void:
  changed.call(value)
  label.text = "%s: %.2f" % [title, value])
 rows.add_child(slider)

func _input(event: InputEvent) -> void:
 if event.is_action_pressed("pause") or (get_tree().paused and event.is_action_pressed("ui_cancel")):
  source.observe(event)
  set_paused(not get_tree().paused)
  get_viewport().set_input_as_handled()

func set_paused(value: bool) -> void:
 get_tree().paused = value
 panel.visible = value
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
 if value:
  resume.grab_focus()
 else:
  resume.release_focus()
  if save_settings_on_close and source.settings.save_file() != OK:
   push_warning("Controller settings could not be saved to user://")
 pause_changed.emit(value)
