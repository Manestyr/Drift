extends Node

var stations: Array[CrewStation] = []
var tactical_displays: Array[TacticalDisplay] = []
var crew_member := CrewMember.new()
var crew_safety := CrewSafety.new()
var sensors := SensorSuite.new()
var fire_control := FireControl.new()
var sensor_targets: Array[Node3D] = []
var last_angular_velocity := Vector3.ZERO
var input_source: PlayerInput
var pause_menu: PauseMenu
var instruments: CockpitInstruments
var status_hint: Label
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
var audio: ShipAudio
var _input_station: CrewStation
var exposure: float = 0.0
@export var g_effect_gain: float = 0.12
@export var g_effect_response_seconds: float = 3.0

func _ready() -> void:
 input_source = PlayerInput.new()
 add_child(input_source)
 input_source.device_changed.connect(_active_device_changed)
 _space()
 _interior()
 crew_safety.members.append(crew_member)
 ship.crew_safety = crew_safety
 _tactical_targets()
 _ui()
 pause_menu = PauseMenu.new()
 pause_menu.source = input_source
 pause_menu.computer = ship.computer
 pause_menu.instruments = instruments
 pause_menu.pause_changed.connect(_pause_changed)
 pause_menu.reset_requested.connect(_reset_ship)
 pause_menu.leave_station_requested.connect(_leave_pilot)
 pause_menu.camera_requested.connect(_toggle_exterior)
 pause_menu.attitude_capture_requested.connect(func() -> void: ship.computer.capture_attitude(ship.global_basis))
 add_child(pause_menu)
 audio=ShipAudio.new()
 audio.ship=ship
 audio.source=input_source
 interior.audio_listener_enable_3d=true
 interior.add_child(audio)
 pause_menu.audio_level_changed.connect(audio.set_level)
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
 instruments = CockpitInstruments.new()
 ship.add_child(instruments)
 ship.state_sampled.connect(_sample_instruments)
 # The instrument console supplies the physical sill and screen housings.
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
 instruments.mount(room, Vector3(0, 0.8, 4.5))
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
  label.double_sided = false
  room.add_child(label)
  var reverse := label.duplicate() as Label3D
  reverse.rotation.y = PI
  reverse.position.z -= 0.01
  room.add_child(reverse)
 _box(room, Vector3(0, 0.45, -14), Vector3(1, 0.9, 1), Color(0.12, 0.4, 0.5), true)
 _box(room, Vector3(0, 1, -16), Vector3(3, 1, 0.8), Color(0.1, 0.5, 0.6), true)
 for x: float in [-1.8, 1.8]:
  _box(room, Vector3(x, 0.35, 13), Vector3(1.4, 0.7, 6), Color(0.55, 0.27, 0.09), true)
 station = CrewStation.new()
 station.position = Vector3(0, 1, -12.5)
 room.add_child(station)
 stations.append(station)
 _build_station(room, "sensors", "SENSOR / DRONE", Vector3(-1.7, 1, -9.6))
 _build_station(room, "weapons", "WEAPONS / FIRE CONTROL", Vector3(1.7, 1, -9.6))
 _industrial_details(room)
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
 hud.visible = false
 canvas.add_child(hud)
 status_hint = Label.new()
 status_hint.position = Vector2(24, 674)
 status_hint.add_theme_font_size_override("font_size", 18)
 status_hint.modulate = Color(0.7, 0.8, 0.8)
 canvas.add_child(status_hint)
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
 var occupied := current_station()
 if audio!=null:
  if event.is_action_pressed("interact"): audio.cue("confirm")
  elif occupied!=null and occupied!=station and (event.is_action_pressed("sensor_track") or event.is_action_pressed("target_previous") or event.is_action_pressed("target_next")):
   audio.cue("ui")
 var advanced_reserved := occupied == station and input_source.advanced_consumes(event)
 if event.is_action_pressed("secure_crew") and occupied != null and not advanced_reserved:
  occupied.set_secured(not occupied.secured)
 if event.is_action_pressed("combat_envelope") and not advanced_reserved:
  crew_safety.combat_requested = not crew_safety.combat_requested
 if occupied != null and occupied != station:
  if outside and event is InputEventMouseMotion and controls_captured and not input_source.using_gamepad:
   orbit.turn(event.relative * 0.004)
  if outside and event.is_action_pressed("zoom_in"):
   orbit.zoom(-0.15)
  if outside and event.is_action_pressed("zoom_out"):
   orbit.zoom(0.15)
  if event.is_action_pressed("interact"):
   _leave_pilot()
  elif event.is_action_pressed("target_previous"):
   sensors.cycle(-1)
  elif event.is_action_pressed("target_next"):
   sensors.cycle(1)
  elif event.is_action_pressed("sensor_track"):
   sensors.toggle_tracking()
  elif event.is_action_pressed("exterior"):
   _toggle_exterior()
  elif event.is_action_pressed("debug"):
   debug_panel.visible = not debug_panel.visible
   hud.visible = debug_panel.visible
  return
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
 if station.occupied and (event.is_action_pressed("retrograde") or (event is InputEventJoypadButton and event.is_action_pressed("pad_retrograde"))):
  ship.computer.request_retrograde()
 if station.occupied and input_source.advanced_consumes(event):
  return
 if event.is_action_pressed("interact"):
  input_source.clear_mouse()
  if station.occupied:
   _leave_pilot()
  elif not outside:
   var nearest := nearest_station()
   if nearest != null:
    crew.seated = nearest.enter(crew_member.member_id)
  _update_view()
 if input_source.computer_event(event, "grid"):
  arena.grid.visible = not arena.grid.visible
 if station.occupied:
  if input_source.computer_event(event, "stabilize"):
   ship.computer.rotation_stabilization = not ship.computer.rotation_stabilization
  if input_source.computer_event(event, "hold_attitude"):
   ship.computer.cancel_retrograde("CANCELLED / HOLD")
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
  _toggle_exterior()
 if event.is_action_pressed("instrument_frame"):
  instruments.navigation.inertial_frame = not instruments.navigation.inertial_frame
 if event.is_action_pressed("debug"):
  debug_panel.visible = not debug_panel.visible
  hud.visible = debug_panel.visible
 if event.is_action_pressed("reset"):
  _reset_ship()

func _toggle_exterior() -> void:
 input_source.clear_mouse()
 outside = not outside
 _update_view()

func _leave_pilot() -> void:
 var occupied := current_station()
 if occupied == null:
  return
 var exit_position := occupied.position + Vector3(0,0,1.0)
 occupied.leave()
 crew.seated = false
 crew.position = exit_position
 ship.command.clear()
 ship.computer.cancel_retrograde("CANCELLED / STATION")
 outside = false
 _update_view()

func _update_view() -> void:
 var next_station:=current_station()
 if next_station!=_input_station:
  input_source.reset_context()
  _input_station=next_station
 crew.controls_enabled = controls_captured and not outside
 var occupied := current_station()
 interior_view.visible = (occupied == null or occupied != station) and not outside
 if occupied != null and occupied != station and not outside:
  occupied.camera.current = true
 elif occupied == null:
  crew.camera.current = true
 if outside:
  outside_camera.current = true
 else:
  pilot_camera.current = true

func _active_device_changed(gamepad: bool) -> void:
 if input_source!=null:
  var keyboard: Array[String]=["brake_all","drift_cancel","flight_modifier","main_engine","forward","back","left","right","up","down","roll_left","roll_right","pitch_up","pitch_down","yaw_left","yaw_right"]
  for action: StringName in InputMap.get_actions():
   var old_source: bool=(String(action) in keyboard) if gamepad else String(action).begins_with("pad_")
   if old_source and Input.is_action_pressed(action) and not String(action) in input_source.blocked_actions:
    input_source.blocked_actions.append(String(action))
 if gamepad and not get_tree().paused:
  controls_captured = true
  crew.controls_enabled = not outside
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _pause_changed(_paused: bool) -> void:
 input_source.reset_context()
 ship.command.clear()
 input_source.clear_mouse()
 controls_captured = true
 crew.controls_enabled = not outside

func _reset_ship() -> void:
 last_angular_velocity = Vector3.ZERO
 input_source.clear_mouse()
 ship.reset_requested = true

func _physics_process(delta: float) -> void:
 var occupied := current_station()
 crew_member.station_id = occupied.station_id if occupied != null else ""
 crew_member.secured = occupied.secured if occupied != null else false
 crew_member.seat_position = occupied.position if occupied != null else crew.position
 crew_member.seat_basis = occupied.basis if occupied != null else crew.basis
 sensors.sample(sensor_targets, ship.global_transform, ship.linear_velocity, ship.tick, delta)
 fire_control.update(sensors.selected())
 for display in tactical_displays:
  display.source=input_source
  if not display is CombatDisplay: display.queue_redraw()
 input_source.set_orbit_mode(_orbit_controls_active())
 if station.occupied and controls_captured:
  PilotInput.sample(ship.command, input_source, delta)
 else:
  ship.command.clear()

func _sample_instruments(_tick: int) -> void:
 var state := PhysicsServer3D.body_get_direct_state(ship.get_rid())
 instruments.refresh(ShipTelemetry.capture(ship, state))
 var angular_acceleration := (state.angular_velocity-last_angular_velocity) / state.step
 crew_member.sample_load(ship.acceleration_world,state.angular_velocity,angular_acceleration,state.transform.basis,ship.tick)
 last_angular_velocity = state.angular_velocity

func _process(delta: float) -> void:
 if audio!=null:
  audio.exterior=outside
  var seat:=current_station()
  audio.listener_position=seat.position+Vector3(0,0.7,0) if seat!=null else crew.camera.global_position
 if _orbit_controls_active() and input_source.using_gamepad:
  orbit.turn(input_source.camera_rate() * delta)
  orbit.zoom((Input.get_action_strength("pad_reverse") - Input.get_action_strength("pad_main")) * delta)
 orbit.update(outside_camera, ship.position)
 nose_hint.visible = false
 status_hint.text = ""
 var occupied := current_station()
 var nearest := nearest_station()
 if occupied == null and nearest != null:
  status_hint.text = (input_source.button_label(JOY_BUTTON_A)+": " if input_source.using_gamepad else "F: ") + nearest.role
 elif occupied != null:
  status_hint.text = "%s / %s | %s | %s" % [occupied.role, "SECURED" if occupied.secured else "UNSECURED",crew_safety.status(), (input_source.button_label(JOY_BUTTON_B)+": harness | "+input_source.button_label(JOY_BUTTON_LEFT_STICK)+": combat") if input_source.using_gamepad else "U: harness | J: combat"]
 if station.occupied and not debug_panel.visible:
  var data:=ShipTelemetry.capture(ship)
  status_hint.text="MAIN THRUST %.2f MN (%d%% health) | BRAKE RCS %.2f MN | NET ACCELERATION %.2f m/s²"%[data.main_force_n/1e6,roundi(data.engine_health*100),data.brake_force_local.length()/1e6,data.acceleration_world.length()]
  if data.reverse_force_n>100: status_hint.text+=" | REVERSE INPUT %.2f MN"%(data.reverse_force_n/1e6)
 var g_load := crew_member.proper_acceleration.length() / 9.80665
 exposure = lerpf(exposure, g_load, 1.0 - exp(-delta / maxf(g_effect_response_seconds, 0.01)))
 (stress_overlay.material as ShaderMaterial).set_shader_parameter("strength", clampf(exposure * g_effect_gain, 0.0, 0.65))
 var local_v := ship.local_velocity()
 var mode := "PILOT / NEWTONIAN" if station.occupied else "CREW / LOCAL ARTIFICIAL GRAVITY"
 hud.text = "DRIFT 0.2 | %s\nSpeed %.2f m/s | local v [%.2f, %.2f, %.2f] m/s\nMain %.0f N | acceleration %.2f m/s² | %.2f g\nSustained load %.2f g | physics tick %d" % [mode, ship.linear_velocity.length(), local_v.x, local_v.y, local_v.z, ship.applied_main_thrust_n, ship.acceleration_world.length(), g_load, exposure, ship.tick]
 var rate := ship.global_basis.inverse() * ship.angular_velocity * (180.0 / PI)
 var fc := ship.computer
 var relative_v := ship.global_basis.inverse() * (ship.linear_velocity - fc.reference_velocity)
 hud.text += "\nP/Y/R [%.1f, %.1f, %.1f] deg/s | relative v [%.1f, %.1f, %.1f] m/s" % [rate.x, rate.y, rate.z, relative_v.x, relative_v.y, relative_v.z]
 hud.text += "\nRate assist %s | Hold %s | Brake axes %s | frame: %s" % [fc.rotation_stabilization, fc.attitude_hold, fc.active_brake_axes, fc.reference_name]
 hud.text += "\nRoll brake %s | brake RCS budget %.0f%% (manual priority)" % [fc.roll_braking, fc.brake_force_fraction * 100.0]
 hud.text += "\nDRIFT CANCEL %s | local XY %s | drift ETA %.2f s | RETRO %s" % [fc.drift_active, fc.drift_vector, fc.drift_eta, fc.retrograde_status]
 hud.text += "\nTranslation limits -/+ N: %s / %s" % [ship.negative_force_limits, ship.positive_force_limits]
 if fc.active_brake_axes != Vector3.ZERO:
  hud.text += "\nBrake %.0f%% | ETA ~%.1f s to 0.05 m/s (free RCS)" % [fc.brake_progress * 100.0, fc.brake_eta]
 hud.text += "\n" + input_source.hints(station.occupied)
 if not station.occupied and crew.position.distance_to(station.position) < 3.0:
  hud.text += "\n["+input_source.button_label(JOY_BUTTON_A)+"] Take pilot station" if input_source.using_gamepad else "\n[F] Take pilot station"

func current_station() -> CrewStation:
 for candidate in stations:
  if candidate.occupied:
   return candidate
 return null

func nearest_station() -> CrewStation:
 var nearest: CrewStation = null
 var distance: float = 3.0
 for candidate in stations:
  var candidate_distance := crew.position.distance_to(candidate.position)
  if candidate_distance < distance and not candidate.occupied:
   nearest = candidate
   distance = candidate_distance
 return nearest

func _build_station(room: Node3D, id: String, role: String, at: Vector3) -> void:
 var console := CrewStation.new()
 console.station_id = id
 console.role = role
 console.controlled_subsystems = PackedStringArray(["sensors", "drone-reserved"] if id == "sensors" else ["fire-control"])
 console.position = at
 room.add_child(console)
 stations.append(console)
 console.camera = Camera3D.new()
 console.camera.position = Vector3(0, 0.7, 0)
 console.camera.fov = 65
 console.add_child(console.camera)
 var viewport := SubViewport.new()
 viewport.size = Vector2i(960,640)
 viewport.world_2d=World2D.new()
 viewport.gui_disable_input = true
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 add_child(viewport)
 var display := _new_tactical_display()
 display.sensors = sensors
 display.fire_control = fire_control
 display.safety = crew_safety
 display.weapons = id == "weapons"
 viewport.add_child(display)
 tactical_displays.append(display)
 var screen := MeshInstance3D.new()
 var quad := QuadMesh.new()
 quad.size = Vector2(1.85,1.23)
 screen.mesh = quad
 screen.position = Vector3(0,0.7,-1.12)
 var material := StandardMaterial3D.new()
 material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 material.albedo_texture = viewport.get_texture()
 material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
 screen.material_override = material
 console.add_child(screen)
 _box(console,Vector3(0,0.7,-1.22),Vector3(2.0,1.38,0.12),Color(0.1,0.13,0.14),true)
 _box(console,Vector3(0,-0.5,-1.15),Vector3(1.9,0.9,0.7),Color(0.14,0.2,0.22),true)
 _box(console,Vector3(0,-0.5,0.1),Vector3(0.65,0.8,0.65),Color(0.17,0.25,0.26),true)
 _box(console,Vector3(0,0.1,0.45),Vector3(0.65,1.1,0.14),Color(0.2,0.28,0.28))
 var label := Label3D.new()
 label.text = role
 label.position = Vector3(0,1.55,-1.2)
 label.font_size = 32
 label.pixel_size = 0.002
 console.add_child(label)

func _industrial_details(room: Node3D) -> void:
 # Ribs, service runs and engineering panels leave a central 1.8m circulation lane.
 for z: float in [-16,-12,-8,-4,0,4,8,12,16]:
  for x: float in [-2.7,2.7]:
   _box(room,Vector3(x,1.8,z),Vector3(0.18,3.5,0.18),Color(0.28,0.31,0.31))
  _box(room,Vector3(0,3.5,z),Vector3(5.5,0.16,0.18),Color(0.28,0.31,0.31))
 for x: float in [-2.6,2.6]:
  _box(room,Vector3(x,3.1,0),Vector3(0.16,0.16,34),Color(0.6,0.36,0.13))
  _box(room,Vector3(x*0.9,0.015,0),Vector3(0.08,0.02,34),Color(0.7,0.48,0.18))
  for z: float in [-5,-1,3]:
   _box(room,Vector3(x,1.1,z),Vector3(0.35,1.6,2),Color(0.12,0.17,0.19),true)
 for side: float in [-1.0,1.0]:
  for z: float in [10.5,12.0,13.5,15.0]:
   var drum := MeshInstance3D.new()
   var cylinder := CylinderMesh.new()
   cylinder.top_radius = 0.55
   cylinder.bottom_radius = 0.55
   cylinder.height = 1.25
   cylinder.radial_segments = 16
   drum.mesh = cylinder
   drum.rotation.x = PI/2
   drum.position = Vector3(side*1.8,1.35,z)
   var metal := StandardMaterial3D.new()
   metal.albedo_color = Color(0.27,0.3,0.29)
   metal.metallic = 0.65
   metal.roughness = 0.6
   drum.material_override = metal
   room.add_child(drum)
   _box(room,Vector3(side*1.8,1.35,z+0.64),Vector3(1.16,1.16,0.12),Color(0.35,0.22,0.1))
   _box(room,Vector3(side*1.18,1.3,z),Vector3(0.12,0.5,0.7),Color(0.1,0.15,0.17))
   for y: float in [1.15,1.3,1.45]:
    _box(room,Vector3(side*1.1,y,z),Vector3(0.05,0.04,0.5),Color(0.25,0.65,0.45))
 for z: float in [11,13,15]:
  for x: float in [-1.8,1.8]:
   _box(room,Vector3(x,2.45,z),Vector3(1.25,0.12,0.7),Color(0.3,0.34,0.34))
   _box(room,Vector3(x-signf(x)*0.73,1.6,z),Vector3(0.04,0.22,0.65),Color(0.2,0.65,0.45))
 for z: float in [-15,-10,-3,4,12]:
  _box(room,Vector3(0,3.57,z),Vector3(1.4,0.06,0.25),Color(0.65,0.72,0.7))

func _tactical_targets() -> void:
 var positions: Array[Vector3] = [Vector3(-220,80,-550),Vector3(320,0,-650),Vector3(1000,-250,-1800)]
 for i in positions.size():
  var target := Node3D.new()
  target.name = "TEST-%02d" % (i+1)
  target.position = positions[i]
  add_child(target)
  _box(target,Vector3.ZERO,Vector3(18,12,25),Color(0.38,0.3,0.2))
  sensor_targets.append(target)

func _new_tactical_display() -> TacticalDisplay:
 return TacticalDisplay.new()

func _orbit_controls_active() -> bool:
 return outside and input_source.orbit_held()
