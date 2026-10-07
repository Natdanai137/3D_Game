extends Control

const TOWN_SCENE := 'res://Scenes/floating_town.tscn'
@onready var play_button: Button = $Margin/Layout/Content/Actions/Play
@onready var controls_button: Button = $Margin/Layout/Content/Actions/Controls
@onready var quit_button: Button = $Margin/Layout/Content/Actions/Quit
@onready var controls_dialog: AcceptDialog = $ControlsDialog
var starting: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().root.gui_embed_subwindows = true
	play_button.pressed.connect(start_game)
	controls_button.pressed.connect(show_controls)
	quit_button.pressed.connect(func(): get_tree().quit())
	controls_dialog.confirmed.connect(func(): controls_button.grab_focus())
	controls_dialog.canceled.connect(func(): controls_button.grab_focus())
	controls_dialog.get_ok_button().text = 'เข้าใจแล้ว'
	quit_button.visible = not OS.has_feature("web")
	play_button.grab_focus()

func start_game() -> void:
	if starting:
		return
	starting = true
	play_button.disabled = true
	var result := get_tree().change_scene_to_file(TOWN_SCENE)
	if result != OK:
		starting = false
		play_button.disabled = false
		push_error('Cannot open Floating Town: %s' % error_string(result))

func show_controls() -> void:
	controls_dialog.popup_centered(Vector2i(540,350))
