class_name PauseMenu
extends CanvasLayer

signal pause_changed(paused: bool)
signal reset_requested
var save_settings_on_close: bool = true
signal camera_requested
signal leave_station_requested
var advanced_panel: PanelContainer
var instruments: CockpitInstruments
var computer: FlightComputer
var computer_panel: PanelContainer
var rate_toggle: CheckButton
var hold_toggle: CheckButton
var nav_toggle: CheckButton
var reference: OptionButton
var source: PlayerInput
var panel: PanelContainer
var resume: Button
var status: Label

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 layer = 10
 panel = PanelContainer.new()
 panel.position = Vector2(340, 45)
 panel.custom_minimum_size = Vector2(600, 410)
 add_child(panel)
 var rows := VBoxContainer.new()
 rows.add_theme_constant_override("separation", 8)
 panel.add_child(rows)
 var title := Label.new()
 title.text = "PAUSED — Input settings"
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
 var flight_button := Button.new()
 flight_button.text = "Flight computer / Controller bindings"
 flight_button.pressed.connect(_open_computer)
 rows.add_child(flight_button)
 _slider(rows, "Mouse flight sensitivity", 0.25, 2.0, 0.05, source.settings.mouse_flight_sensitivity,
  func(value: float) -> void: source.settings.mouse_flight_sensitivity = value)
 var advanced_button := Button.new()
 advanced_button.text = "Advanced flight / Controller bindings"
 advanced_button.pressed.connect(func() -> void:
  panel.hide()
  advanced_panel.show()
  advanced_panel.find_next_valid_focus().grab_focus())
 rows.add_child(advanced_button)
 var contact_button := Button.new()
 contact_button.text = "Kontakt Alpha / First Contact"
 contact_button.pressed.connect(func() -> void:
  set_paused(false)
  get_tree().change_scene_to_file("res://scenes/contact_alpha.tscn"))
 rows.add_child(contact_button)
 var free_button := Button.new()
 free_button.text = "Freier Flug / Free flight"
 free_button.pressed.connect(func() -> void:
  set_paused(false)
  get_tree().change_scene_to_file("res://scenes/main.tscn"))
 rows.add_child(free_button)
 _build_advanced_panel()
 _build_computer_panel()
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
  if (computer_panel.visible or advanced_panel.visible) and event.is_action_pressed("ui_cancel"):
   advanced_panel.hide()
   computer_panel.hide()
   panel.show()
   resume.grab_focus()
  else:
   set_paused(not get_tree().paused)
  get_viewport().set_input_as_handled()

func set_paused(value: bool) -> void:
 get_tree().paused = value
 panel.visible = value
 computer_panel.hide()
 advanced_panel.hide()
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
 if value:
  resume.grab_focus()
 else:
  resume.release_focus()
  if save_settings_on_close and source.settings.save_file() != OK:
   push_warning("Controller settings could not be saved to user://")
 pause_changed.emit(value)

func _build_computer_panel() -> void:
 computer_panel = PanelContainer.new()
 computer_panel.position = Vector2(310, 100)
 computer_panel.custom_minimum_size = Vector2(660, 480)
 add_child(computer_panel)
 var rows := VBoxContainer.new()
 rows.add_theme_constant_override("separation", 12)
 computer_panel.add_child(rows)
 var title := Label.new()
 title.text = "FLIGHT COMPUTER — physical RCS only"
 rows.add_child(title)
 rate_toggle = CheckButton.new()
 rate_toggle.text = "Automatic rotation stabilization"
 rate_toggle.toggled.connect(func(value: bool) -> void: computer.rotation_stabilization = value)
 rows.add_child(rate_toggle)
 hold_toggle = CheckButton.new()
 hold_toggle.text = "Hold current attitude (manual rotation releases hold)"
 hold_toggle.toggled.connect(func(value: bool) -> void:
  if value:
   # Composition provides the actual attitude via signal, not a UI body lookup.
   attitude_capture_requested.emit()
  else:
   computer.attitude_hold = false)
 rows.add_child(hold_toggle)
 _choice(rows, "Controller D-pad layout", ["Down brake / Up stabilize / Left hold / Right grid", "Up brake / Down stabilize / Right hold / Left grid"], source.settings.computer_layout,
  func(value: int) -> void: source.settings.computer_layout = value)
 _choice(rows, "Controller brake button operates", ["All velocity components", "Local forward/back (Z)", "Local lateral (X)", "Local vertical (Y)", "Local roll rate"], source.settings.brake_mode,
  func(value: int) -> void: source.settings.brake_mode = value)
 reference = _choice(rows, "Inertial braking frame", ["Arena rest (0 m/s)", "Virtual convoy (-20 m/s world Z)"], 0, _select_reference)
 nav_toggle = CheckButton.new()
 nav_toggle.text = "Navigation display: inertial world axes (N)"
 nav_toggle.toggled.connect(func(value: bool) -> void: instruments.navigation.inertial_frame = value)
 rows.add_child(nav_toggle)
 var info := Label.new()
 info.text = "Hold brake button to brake. Manual thrust wins on its axis.\nMouse wheel: exterior zoom. Hold RS click: orbit/trigger zoom."
 rows.add_child(info)
 var back := Button.new()
 back.text = "Back"
 back.pressed.connect(func() -> void:
  computer_panel.hide()
  panel.show()
  resume.grab_focus())
 rows.add_child(back)
 computer_panel.hide()

signal attitude_capture_requested

func _choice(rows: VBoxContainer, title: String, items: Array, selected: int, changed: Callable) -> OptionButton:
 var label := Label.new()
 label.text = title
 rows.add_child(label)
 var choice := OptionButton.new()
 for item: String in items:
  choice.add_item(item)
 choice.select(selected)
 choice.item_selected.connect(changed)
 rows.add_child(choice)
 return choice

func _open_computer() -> void:
 panel.hide()
 computer_panel.show()
 nav_toggle.set_pressed_no_signal(instruments.navigation.inertial_frame)
 rate_toggle.set_pressed_no_signal(computer.rotation_stabilization)
 hold_toggle.set_pressed_no_signal(computer.attitude_hold)
 rate_toggle.grab_focus()

func _select_reference(index: int) -> void:
 computer.reference_velocity = Vector3.ZERO if index == 0 else Vector3(0, 0, -20)
 computer.reference_name = "Arena / inertial rest" if index == 0 else "Virtual convoy / -20 m/s world Z"
 computer.reset_braking_progress()

func cycle_reference() -> void:
 var next := 1 - reference.selected
 reference.select(next)
 _select_reference(next)

func _build_advanced_panel() -> void:
 advanced_panel = PanelContainer.new()
 advanced_panel.position = Vector2(310, 100)
 advanced_panel.custom_minimum_size = Vector2(660, 480)
 add_child(advanced_panel)
 var rows := VBoxContainer.new()
 rows.add_theme_constant_override("separation", 12)
 advanced_panel.add_child(rows)
 var title := Label.new()
 title.text = "ADVANCED FLIGHT — held drift / retrograde"
 rows.add_child(title)
 var info := Label.new()
 info.text = "C: hold Drift Cancel | B: retrograde (no auto burn)\nBindings override overlapping gameplay buttons while active."
 rows.add_child(info)
 var indices: Array[int] = []
 var names: Array[String] = []
 var labels := ["A / Cross", "B / Circle", "X / Square", "Y / Triangle", "Back / Share", "Guide", "Start", "LS click", "RS click", "LB / L1", "RB / R1", "D-pad Up", "D-pad Down", "D-pad Left", "D-pad Right", "Misc", "Paddle 1", "Paddle 2", "Paddle 3", "Paddle 4", "Touchpad"]
 for i in range(JOY_BUTTON_MAX):
  if i in [JOY_BUTTON_GUIDE, JOY_BUTTON_START]:
   continue
  indices.append(i)
  names.append(labels[i] if i < labels.size() else "Button " + str(i))
 var drift := _choice(rows, "Hold Drift Cancel button", names, indices.find(source.settings.drift_button), func(_value: int) -> void: pass)
 var modifier_names: Array = ["None"] + names
 var modifier_indices: Array = [-1] + indices
 var modifier := _choice(rows, "Optional chord modifier (must also be held)", modifier_names, modifier_indices.find(source.settings.drift_modifier), func(_value: int) -> void: pass)
 var retro := _choice(rows, "Retrograde command button", names, indices.find(source.settings.retrograde_button), func(_value: int) -> void: pass)
 drift.item_selected.connect(func(value: int) -> void:
  if indices[value] == source.settings.retrograde_button:
   info.text = "Choose different Drift and Retrograde buttons."
   drift.select(indices.find(source.settings.drift_button))
  else:
   source.settings.drift_button = indices[value]
   source.settings.apply_advanced_bindings())
 modifier.item_selected.connect(func(value: int) -> void:
  if modifier_indices[value] == source.settings.retrograde_button:
   info.text = "Modifier cannot also trigger Retrograde."
   modifier.select(modifier_indices.find(source.settings.drift_modifier))
  else:
   source.settings.drift_modifier = modifier_indices[value]
   source.settings.apply_advanced_bindings())
 retro.item_selected.connect(func(value: int) -> void:
  if indices[value] in [source.settings.drift_button, source.settings.drift_modifier]:
   info.text = "Choose a separate Retrograde button."
   retro.select(indices.find(source.settings.retrograde_button))
  else:
   source.settings.retrograde_button = indices[value]
   source.settings.apply_advanced_bindings())
 var camera_button := Button.new()
 camera_button.text = "Toggle exterior camera (fallback after rebinding Y)"
 camera_button.pressed.connect(func() -> void: camera_requested.emit(); set_paused(false))
 rows.add_child(camera_button)
 var leave := Button.new()
 leave.text = "Leave pilot seat (also available with rebound A)"
 leave.pressed.connect(func() -> void: leave_station_requested.emit(); set_paused(false))
 rows.add_child(leave)
 var back := Button.new()
 back.text = "Back"
 back.pressed.connect(func() -> void:
  advanced_panel.hide()
  panel.show()
  resume.grab_focus())
 rows.add_child(back)
 advanced_panel.hide()
