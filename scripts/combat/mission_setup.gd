class_name MissionSetup
extends Control

var mode: OptionButton
var difficulty: OptionButton
var seed_field: SpinBox
var weapons: CheckButton
var drone: CheckButton
var explanation: Label

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var background:=ColorRect.new()
 background.color=Color(0.015,0.025,0.035)
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(background)
 var panel:=PanelContainer.new()
 panel.position=Vector2(290,65)
 panel.custom_minimum_size=Vector2(700,580)
 add_child(panel)
 var rows:=VBoxContainer.new()
 rows.add_theme_constant_override("separation",16)
 panel.add_child(rows)
 var title:=Label.new()
 title.text="KONTAKT ALPHA / MISSION SETUP"
 title.add_theme_font_size_override("font_size",28)
 rows.add_child(title)
 mode=OptionButton.new()
 for item in CombatProfile.MODE_NAMES: mode.add_item(item)
 rows.add_child(mode)
 mode.item_selected.connect(_mode_changed)
 explanation=Label.new()
 rows.add_child(explanation)
 difficulty=OptionButton.new()
 for item in CombatProfile.DIFFICULTY_NAMES: difficulty.add_item(item)
 difficulty.select(CombatProfile.Difficulty.NORMAL)
 rows.add_child(difficulty)
 var info:=Label.new()
 info.text="Difficulty changes reactions, sensors, evasion and defense.\nHull, damage and missile physics are identical."
 rows.add_child(info)
 weapons=CheckButton.new()
 weapons.text="ASSISTED: grant missile launches to unoccupied weapon role"
 rows.add_child(weapons)
 drone=CheckButton.new()
 drone.text="ASSISTED: grant existing drone DEFEND (deploy manually)"
 rows.add_child(drone)
 var seed_label:=Label.new()
 seed_label.text="Scenario seed (0 = random; shown in mission)"
 rows.add_child(seed_label)
 seed_field=SpinBox.new()
 seed_field.max_value=2147483647
 rows.add_child(seed_field)
 var start:=Button.new()
 start.text="Start mission"
 start.pressed.connect(func() -> void:
  launch.call_deferred(get_tree(),mode.selected,difficulty.selected,int(seed_field.value),weapons.button_pressed,drone.button_pressed))
 rows.add_child(start)
 var free:=Button.new()
 free.text="Back to free flight"
 free.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main.tscn"))
 rows.add_child(free)
 _mode_changed(0)
 start.grab_focus()
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func _mode_changed(index: int) -> void:
 weapons.visible=index==CombatProfile.Mode.ASSISTED_SOLO
 drone.visible=weapons.visible
 weapons.button_pressed=false
 drone.button_pressed=false
 explanation.text=["MANUAL: no friendly missile or drone launch without your order.","ASSISTED SOLO: only checked roles receive explicit consent.\nDeploy the drone and select its area yourself.","FULL AUTO: autonomous launches and deployment / DEMO ONLY."][index]

static func launch(tree: SceneTree, selected_mode: int, selected_difficulty: int, seed: int, weapon_grant: bool = false, drone_grant: bool = false) -> void:
 var game=load("res://scenes/contact_alpha.tscn").instantiate()
 game.setup_mode=selected_mode
 game.setup_difficulty=selected_difficulty
 game.setup_seed=seed
 game.setup_weapon_grant=weapon_grant
 game.setup_drone_grant=drone_grant
 var old:=tree.current_scene
 tree.root.add_child(game)
 tree.current_scene=game
 if is_instance_valid(old): old.queue_free()
 tree.scene_changed.emit()

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):
  get_tree().change_scene_to_file("res://scenes/main.tscn")
