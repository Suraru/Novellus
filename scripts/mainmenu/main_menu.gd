extends Control

# Scene paths for navigation
const GAME_START_SCENE = "res://scenes/mainmenu/GameStart.tscn"
const HISTORY_SCENE = "res://scenes/mainmenu/History.tscn"
const SETTINGS_SCENE = "res://scenes/mainmenu/Settings.tscn"

# Node references
@onready var start_button = $VBoxContainer/StartButton
@onready var history_button = $VBoxContainer/HistoryButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var exit_button = $VBoxContainer/ExitButton
@onready var nebula_animation_timer = $Nebula/AnimationTimer

# Called when the node enters the scene tree for the first time
func _ready():
	# Connect button signals to their respective functions
	start_button.pressed.connect(_on_start_button_pressed)
	history_button.pressed.connect(_on_history_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	
	# Connect animation timer for nebula effect
	nebula_animation_timer.timeout.connect(_on_animation_timer_timeout)

# Button click handlers
func _on_start_button_pressed():
	get_tree().change_scene_to_file(GAME_START_SCENE)

func _on_history_button_pressed():
	# This button is disabled in the UI but preparing the functionality
	get_tree().change_scene_to_file(HISTORY_SCENE)

func _on_settings_button_pressed():
	get_tree().change_scene_to_file(SETTINGS_SCENE)

func _on_exit_button_pressed():
	# Quit the game
	get_tree().quit()

# Animation for the nebula background
func _on_animation_timer_timeout():
	# Get nebula sprite node
	var nebula_sprite = $Nebula/NebulaSpriteLayer
	
	# Create a subtle animation effect
	# This could be a gentle rotation, color shift, or scale pulse
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Example: subtle scale pulsing effect
	tween.tween_property(nebula_sprite, "scale", Vector2(1.02, 1.02), 1.0)
	tween.tween_property(nebula_sprite, "scale", Vector2(1.0, 1.0), 1.0)
