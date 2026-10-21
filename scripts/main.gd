extends Node

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
 _space()
 _interior()
 _ui()
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
 var rng := RandomNumberGenerator.new()
 rng.seed = 1741
 for i in range(180):
  var location := Vector3(rng.randf_range(-2500, 2500), rng.randf_range(-1400, 1400), rng.randf_range(-3500, 1500))
  _box(space, location, Vector3.ONE * rng.randf_range(1.0, 5.0), Color(0.7, 0.8, 0.9))
 for i in range(1, 11):
  var marker := Node3D.new()
  space.add_child(marker)
  marker.position = Vector3(40, 0, -i * 100)
  _box(marker, Vector3.ZERO, Vector3(2, 20, 2), Color(0.8, 0.5, 0.1))
  var label := Label3D.new()
  label.text = "%d m / fixed reference" % (i * 100)
  label.position.y = 13
  label.font_size = 64
  label.pixel_size = 0.04
  marker.add_child(label)
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
 hud.add_theme_font_size_override("font_size", 20)
 canvas.add_child(hud)
 debug_panel = PanelContainer.new()
 debug_panel.position = Vector2(760, 20)
 var button := Button.new()
 button.text = "F5: Reset ship position + velocities"
 button.pressed.connect(_reset_ship)
 debug_panel.add_child(button)
 debug_panel.visible = false
 canvas.add_child(debug_panel)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not outside:
  crew.look(event.relative)
 if event.is_action_pressed("ui_cancel"):
  controls_captured = not controls_captured
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if controls_captured else Input.MOUSE_MODE_VISIBLE
 if event.is_action_pressed("interact"):
  if station.occupied:
   station.leave()
   crew.seated = false
   crew.position = Vector3(0, 1, -12)
   ship.command.clear()
   outside = false
  elif crew.position.distance_to(station.position) < 3.0 and not outside:
   crew.seated = station.enter()
  _update_view()
 if event.is_action_pressed("exterior"):
  outside = not outside
  _update_view()
 if event.is_action_pressed("debug"):
  debug_panel.visible = not debug_panel.visible
 if event.is_action_pressed("reset"):
  _reset_ship()

func _update_view() -> void:
 interior_view.visible = not station.occupied and not outside
 if outside:
  outside_camera.current = true
 else:
  pilot_camera.current = true

func _reset_ship() -> void:
 ship.reset_requested = true

func _physics_process(_delta: float) -> void:
 if station.occupied and controls_captured:
  PilotInput.sample(ship.command)
 else:
  ship.command.clear()

func _process(delta: float) -> void:
 outside_camera.position = ship.position + ship.basis * Vector3(45, 25, 55)
 outside_camera.look_at(ship.position)
 var g_load := ship.acceleration_world.length() / 9.80665
 exposure = lerpf(exposure, g_load, 1.0 - exp(-delta / maxf(g_effect_response_seconds, 0.01)))
 (stress_overlay.material as ShaderMaterial).set_shader_parameter("strength", clampf(exposure * g_effect_gain, 0.0, 0.65))
 var local_v := ship.local_velocity()
 var mode := "PILOT / NEWTONIAN — ASSIST OFF" if station.occupied else "CREW / LOCAL ARTIFICIAL GRAVITY"
 hud.text = "DRIFT 0.1 | %s\nSpeed %.2f m/s | local v [%.2f, %.2f, %.2f] m/s\nMain %.0f N | acceleration %.2f m/s² | %.2f g\nSustained load %.2f g | physics tick %d\nE: seat / exit  V: exterior  Esc: mouse  F3: debug  F5: reset\nWalk WASD + mouse | Pilot WASD/Space/Ctrl: RCS, Shift: main\nArrows: pitch/yaw  Q/R: roll | thrust release = coast" % [mode, ship.linear_velocity.length(), local_v.x, local_v.y, local_v.z, ship.applied_main_thrust_n, ship.acceleration_world.length(), g_load, exposure, ship.tick]
 if not station.occupied and crew.position.distance_to(station.position) < 3.0:
  hud.text += "\n[E] Take pilot station"
