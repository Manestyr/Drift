extends Node

var input_source: PlayerInput
var pause_menu: PauseMenu
var arena: TestArena
var orbit := ExteriorOrbit.new()
var nose_hint: Label
var ship: ShipPhysics
var crew: CrewController
var station: CrewStation
var pilot_camera: Camera3D
var outside_camera: Camera3D
var interior: SubViewport
var interior_view: SubViewportContainer
var hud: Label
var debug_panel: PanelContainer
var stress_overlay: ColorRect
var controls_captured: bool = true
var outside: bool = false
var exposure: float = 0.0
@export var g_effect_gain: float = 0.12
@export var g_effect_response_seconds: float = 3.0

func _ready() -> void:
 input_source = PlayerInput.new()
 add_child(input_source)
 input_source.device_changed.connect(_active_device_changed)
 _space()
 _interior()
 _ui()
 pause_menu = PauseMenu.new()
 pause_menu.source = input_source
 pause_menu.computer = ship.computer
 pause_menu.pause_changed.connect(_pause_changed)
 pause_menu.reset_requested.connect(_reset_ship)
 pause_menu.attitude_capture_requested.connect(func() -> void: ship.computer.capture_attitude(ship.global_basis))
 add_child(pause_menu)
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _box(parent: Node3D, at: Vector3, size: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
 var mesh := MeshInstance3D.new()
 var box := BoxMesh.new()
 box.size = size
 mesh.mesh = box
 mesh.position = at
 var material := StandardMaterial3D.new()
 material.albedo_color = color
 material.roughness = 0.75
 mesh.material_override = material
 parent.add_child(mesh)
 if solid:
  var body := StaticBody3D.new()
  body.collision_layer = 2
  body.collision_mask = 2
  var shape := CollisionShape3D.new()
  var box_shape := BoxShape3D.new()
  box_shape.size = size
  shape.shape = box_shape
  mesh.add_child(body)
  body.add_child(shape)
 return mesh

func _environment(parent: Node) -> void:
 var env_node := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color(0.002, 0.004, 0.012)
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color(0.3, 0.4, 0.55)
 env.ambient_light_energy = 0.6
 env_node.environment = env
 parent.add_child(env_node)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-35, -40, 0)
 sun.light_energy = 1.8
 parent.add_child(sun)

func _space() -> void:
 var space := Node3D.new()
 add_child(space)
 _environment(space)
 ship = ShipPhysics.new()
 space.add_child(ship)
 ship.computer.rotation_stabilization = true
 _box(ship, Vector3.ZERO, Vector3(7, 5, 36), Color(0.22, 0.29, 0.35))
 _box(ship, Vector3(0, 1, -13), Vector3(6, 3, 7), Color(0.1, 0.32, 0.45))
 for x: float in [-2.0, 2.0]:
  _box(ship, Vector3(x, 0, 18), Vector3(1.5, 2, 3), Color(0.8, 0.3, 0.08))
 var hull := CollisionShape3D.new()
 var hull_shape := BoxShape3D.new()
 hull_shape.size = Vector3(7, 5, 36)
 hull.shape = hull_shape
 ship.add_child(hull)
 pilot_camera = Camera3D.new()
 pilot_camera.position = Vector3(0, 1.5, -18.5)
 pilot_camera.far = 100000
 ship.add_child(pilot_camera)
 # Small cockpit sill in the pilot's view.
 _box(ship, Vector3(0, 0.7, -19.5), Vector3(2.2, 0.15, 0.3), Color(0.08, 0.17, 0.2))
 outside_camera = Camera3D.new()
 outside_camera.far = 100000
 space.add_child(outside_camera)
 arena = TestArena.new()
 space.add_child(arena)
 pilot_camera.current = true

func _interior() -> void:
 interior_view = SubViewportContainer.new()
 interior_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 interior_view.stretch = true
 interior_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(interior_view)
 interior = SubViewport.new()
 interior.size = Vector2i(1280, 720)
 interior.own_world_3d = true
 interior.gui_disable_input = true
 interior.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 interior_view.add_child(interior)
 var room := Node3D.new()
 interior.add_child(room)
 _environment(room)
 # All deck coordinates are ship-local. No global flight displacement enters this world.
 _box(room, Vector3(0, -0.25, 0), Vector3(6, 0.5, 36), Color(0.16, 0.2, 0.25), true)
 _box(room, Vector3(0, 3.8, 0), Vector3(6, 0.3, 36), Color(0.12, 0.15, 0.2), true)
 for x: float in [-3.0, 3.0]:
  _box(room, Vector3(x, 1.8, 0), Vector3(0.3, 4, 36), Color(0.2, 0.25, 0.3), true)
 for z: float in [-18.0, 18.0]:
  _box(room, Vector3(0, 1.8, z), Vector3(6, 4, 0.3), Color(0.1, 0.22, 0.28), true)
 for z: float in [-7.0, 7.0]:
  for x: float in [-2.0, 2.0]:
   _box(room, Vector3(x, 1.8, z), Vector3(2, 4, 0.4), Color(0.3, 0.35, 0.4), true)
 for z: float in [-13.0, 0.0, 13.0]:
  var light := OmniLight3D.new()
  light.position = Vector3(0, 3.2, z)
  light.omni_range = 15
  light.light_energy = 2.0
  light.light_color = Color(0.4, 0.8, 1.0) if z < 0 else Color(1.0, 0.6, 0.3)
  room.add_child(light)
  var label := Label3D.new()
  label.text = "BRIDGE / PILOT" if z < 0 else ("TRANSFER CORRIDOR" if z == 0 else "ENGINEERING")
  label.position = Vector3(0, 2.6, z - 3)
  label.font_size = 48
  room.add_child(label)
 _box(room, Vector3(0, 0.45, -14), Vector3(1, 0.9, 1), Color(0.12, 0.4, 0.5), true)
 _box(room, Vector3(0, 1, -16), Vector3(3, 1, 0.8), Color(0.1, 0.5, 0.6), true)
 for x: float in [-1.8, 1.8]:
  _box(room, Vector3(x, 1.2, 13), Vector3(1.4, 2.4, 6), Color(0.55, 0.27, 0.09), true)
 station = CrewStation.new()
 station.position = Vector3(0, 1, -12.5)
 room.add_child(station)
 crew = CrewController.new()
 crew.input_source = input_source
 crew.position = Vector3(0, 1, -9)
 room.add_child(crew)

func _ui() -> void:
 var canvas := CanvasLayer.new()
 add_child(canvas)
 stress_overlay = ColorRect.new()
 stress_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 stress_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var shader := Shader.new()
 shader.code = "shader_type canvas_item; uniform float strength = 0.0; void fragment() { float edge = smoothstep(0.2, 0.72, length(UV-vec2(0.5))); COLOR = vec4(0.01, 0.015, 0.025, edge * strength); }"
 var material := ShaderMaterial.new()
 material.shader = shader
 stress_overlay.material = material
 canvas.add_child(stress_overlay)
 hud = Label.new()
 hud.position = Vector2(24, 20)
 hud.add_theme_font_size_override("font_size", 18)
 canvas.add_child(hud)
 nose_hint = Label.new()
 nose_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 nose_hint.text = "^\n+\nFORWARD -Z"
 nose_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 nose_hint.offset_left = -60
 nose_hint.offset_right = 60
 nose_hint.offset_top = -34
 nose_hint.offset_bottom = 34
 nose_hint.modulate = Color(0.3, 1.0, 0.8)
 canvas.add_child(nose_hint)
 debug_panel = PanelContainer.new()
 debug_panel.position = Vector2(760, 20)
 var button := Button.new()
 button.text = "F5: Reset ship position + velocities"
 button.pressed.connect(_reset_ship)
 debug_panel.add_child(button)
 debug_panel.visible = false
 canvas.add_child(debug_panel)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion and controls_captured and not input_source.using_gamepad:
  if outside:
   orbit.turn(event.relative * 0.004)
  elif station.occupied:
   input_source.add_flight_mouse(event.relative)
  else:
   crew.look(event.relative)
 if event.is_action_pressed("ui_cancel") and not event is InputEventJoypadButton:
  input_source.clear_mouse()
  controls_captured = not controls_captured
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if controls_captured else Input.MOUSE_MODE_VISIBLE
  crew.controls_enabled = controls_captured and not outside
 if event.is_action_pressed("interact"):
  input_source.clear_mouse()
  if station.occupied:
   station.leave()
   crew.seated = false
   crew.position = Vector3(0, 1, -12)
   ship.command.clear()
   outside = false
  elif crew.position.distance_to(station.position) < 3.0 and not outside:
   crew.seated = station.enter()
  _update_view()
 if input_source.computer_event(event, "grid"):
  arena.grid.visible = not arena.grid.visible
 if station.occupied:
  if input_source.computer_event(event, "stabilize"):
   ship.computer.rotation_stabilization = not ship.computer.rotation_stabilization
  if input_source.computer_event(event, "hold_attitude"):
   if ship.computer.attitude_hold:
    ship.computer.attitude_hold = false
   else:
    ship.computer.capture_attitude(ship.global_basis)
 if event.is_action_pressed("reference_frame"):
  pause_menu.cycle_reference()
 if outside and event.is_action_pressed("zoom_in"):
  orbit.zoom(-0.15)
 if outside and event.is_action_pressed("zoom_out"):
  orbit.zoom(0.15)
 if event.is_action_pressed("exterior"):
  input_source.clear_mouse()
  outside = not outside
  _update_view()
 if event.is_action_pressed("debug"):
  debug_panel.visible = not debug_panel.visible
 if event.is_action_pressed("reset"):
  _reset_ship()

func _update_view() -> void:
 crew.controls_enabled = controls_captured and not outside
 interior_view.visible = not station.occupied and not outside
 if outside:
  outside_camera.current = true
 else:
  pilot_camera.current = true

func _active_device_changed(gamepad: bool) -> void:
 if gamepad and not get_tree().paused:
  controls_captured = true
  crew.controls_enabled = not outside
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _pause_changed(_paused: bool) -> void:
 ship.command.clear()
 input_source.clear_mouse()
 controls_captured = true
 crew.controls_enabled = not outside

func _reset_ship() -> void:
 input_source.clear_mouse()
 ship.reset_requested = true

func _physics_process(delta: float) -> void:
 input_source.set_orbit_mode(outside and Input.is_action_pressed("pad_orbit"))
 if station.occupied and controls_captured:
  PilotInput.sample(ship.command, input_source, delta)
 else:
  ship.command.clear()

func _process(delta: float) -> void:
 if outside and input_source.using_gamepad and Input.is_action_pressed("pad_orbit"):
  orbit.turn(input_source.camera_rate() * delta)
  orbit.zoom((Input.get_action_strength("pad_reverse") - Input.get_action_strength("pad_main")) * delta)
 orbit.update(outside_camera, ship.position)
 nose_hint.visible = station.occupied and not outside
 var g_load := ship.acceleration_world.length() / 9.80665
 exposure = lerpf(exposure, g_load, 1.0 - exp(-delta / maxf(g_effect_response_seconds, 0.01)))
 (stress_overlay.material as ShaderMaterial).set_shader_parameter("strength", clampf(exposure * g_effect_gain, 0.0, 0.65))
 var local_v := ship.local_velocity()
 var mode := "PILOT / NEWTONIAN" if station.occupied else "CREW / LOCAL ARTIFICIAL GRAVITY"
 hud.text = "DRIFT 0.1.2 | %s\nSpeed %.2f m/s | local v [%.2f, %.2f, %.2f] m/s\nMain %.0f N | acceleration %.2f m/s² | %.2f g\nSustained load %.2f g | physics tick %d" % [mode, ship.linear_velocity.length(), local_v.x, local_v.y, local_v.z, ship.applied_main_thrust_n, ship.acceleration_world.length(), g_load, exposure, ship.tick]
 var rate := ship.global_basis.inverse() * ship.angular_velocity * (180.0 / PI)
 var fc := ship.computer
 var relative_v := ship.global_basis.inverse() * (ship.linear_velocity - fc.reference_velocity)
 hud.text += "\nP/Y/R [%.1f, %.1f, %.1f] deg/s | relative v [%.1f, %.1f, %.1f] m/s" % [rate.x, rate.y, rate.z, relative_v.x, relative_v.y, relative_v.z]
 hud.text += "\nRate assist %s | Hold %s | Brake axes %s | frame: %s" % [fc.rotation_stabilization, fc.attitude_hold, fc.active_brake_axes, fc.reference_name]
 hud.text += "\nRoll brake %s | brake RCS budget %.0f%% (manual priority)" % [fc.roll_braking, fc.brake_force_fraction * 100.0]
 if fc.active_brake_axes != Vector3.ZERO:
  hud.text += "\nBrake %.0f%% | ETA ~%.1f s to 0.05 m/s (free RCS)" % [fc.brake_progress * 100.0, fc.brake_eta]
 hud.text += "\n" + input_source.hints(station.occupied)
 if not station.occupied and crew.position.distance_to(station.position) < 3.0:
  hud.text += "\n[A / Cross] Take pilot station" if input_source.using_gamepad else "\n[F] Take pilot station"
