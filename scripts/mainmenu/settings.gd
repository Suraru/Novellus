extends Control

@onready var background = $Characterbg

# Settings dictionary to store all configuration
var settings = {
	"ui": {
		"resolution": "1920 x 1080",
		"fullscreen": false,
		"vsync": true,
		"ui_scale": 1.0
	},
	"audio": {
		"master_volume": 1.0,
		"music_volume": 1.0,
		"sfx_volume": 1.0,
		"voice_volume": 1.0,
		"mute": false
	},
	"content": {
		"alpha_content": true,
		"beta_content": true,
		"charlie_content": true,
		"difficulty": 1 # 0: Easy, 1: Normal, 2: Hard
	},
	"multiplayer": {
		"player_name": "",
		"server_address": "127.0.0.1",
		"server_port": 9876,
		"auto_connect": false
	}
}

# Path to save the settings file
const SETTINGS_PATH = "user://settings.cfg"

# References to UI elements
@onready var resolution_option = %OptionButton
@onready var fullscreen_checkbox = %CheckBox
@onready var vsync_checkbox = %CheckBox
@onready var ui_scale_slider = %HSlider
@onready var ui_scale_value = %Value

@onready var master_volume_slider = %HSlider
@onready var master_volume_value = %Value
@onready var music_volume_slider = %HSlider
@onready var music_volume_value = %Value
@onready var sfx_volume_slider = %HSlider
@onready var sfx_volume_value = %Value
@onready var voice_volume_slider = %HSlider
@onready var voice_volume_value = %Value
@onready var mute_checkbox = %CheckBox

@onready var alpha_content_checkbox = %CheckBox
@onready var beta_content_checkbox = %CheckBox
@onready var charlie_content_checkbox = %CheckBox
@onready var difficulty_option = %OptionButton

@onready var player_name_field = %LineEdit
@onready var server_address_field = %LineEdit
@onready var server_port_spinbox = %SpinBox
@onready var auto_connect_checkbox = %CheckBox

func _ready():
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	# Load settings
	load_settings()
	
	# Initialize UI with loaded settings
	update_ui_from_settings()
	
	# Connect signals for UI elements
	_connect_signals()
	
func _on_viewport_size_changed():
	var viewport_size = get_viewport().get_visible_rect().size
	var texture_size = background.texture.get_size()
	
	# Calculate scale to cover the entire viewport
	var scale_x = viewport_size.x / texture_size.x
	var scale_y = viewport_size.y / texture_size.y
	var scale = max(scale_x, scale_y)
	
	background.scale = Vector2(scale, scale)
	
	# Center the background
	background.position = viewport_size / 2
	background.centered = true

# Connect all UI element signals
func _connect_signals():
	# UI tab signals
	resolution_option.item_selected.connect(_on_resolution_option_item_selected)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_checkbox_toggled)
	vsync_checkbox.toggled.connect(_on_vsync_checkbox_toggled)
	ui_scale_slider.value_changed.connect(_on_ui_scale_slider_value_changed)
	
	# Audio tab signals
	master_volume_slider.value_changed.connect(_on_master_volume_slider_value_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_slider_value_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_slider_value_changed)
	voice_volume_slider.value_changed.connect(_on_voice_volume_slider_value_changed)
	mute_checkbox.toggled.connect(_on_mute_checkbox_toggled)
	
	# Content tab signals
	alpha_content_checkbox.toggled.connect(_on_alpha_content_checkbox_toggled)
	beta_content_checkbox.toggled.connect(_on_beta_content_checkbox_toggled)
	charlie_content_checkbox.toggled.connect(_on_charlie_content_checkbox_toggled)
	difficulty_option.item_selected.connect(_on_difficulty_option_item_selected)
	
	# Multiplayer tab signals
	player_name_field.text_changed.connect(_on_player_name_field_text_changed)
	server_address_field.text_changed.connect(_on_server_address_field_text_changed)
	server_port_spinbox.value_changed.connect(_on_server_port_spinbox_value_changed)
	auto_connect_checkbox.toggled.connect(_on_auto_connect_checkbox_toggled)

# Load settings from file
func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	
	if err != OK:
		print("No settings file found, using defaults")
		return
	
	# UI settings
	settings.ui.resolution = config.get_value("ui", "resolution", settings.ui.resolution)
	settings.ui.fullscreen = config.get_value("ui", "fullscreen", settings.ui.fullscreen)
	settings.ui.vsync = config.get_value("ui", "vsync", settings.ui.vsync)
	settings.ui.ui_scale = config.get_value("ui", "ui_scale", settings.ui.ui_scale)
	
	# Audio settings
	settings.audio.master_volume = config.get_value("audio", "master_volume", settings.audio.master_volume)
	settings.audio.music_volume = config.get_value("audio", "music_volume", settings.audio.music_volume)
	settings.audio.sfx_volume = config.get_value("audio", "sfx_volume", settings.audio.sfx_volume)
	settings.audio.voice_volume = config.get_value("audio", "voice_volume", settings.audio.voice_volume)
	settings.audio.mute = config.get_value("audio", "mute", settings.audio.mute)
	
	# Content settings
	settings.content.alpha_content = config.get_value("content", "alpha_content", settings.content.alpha_content)
	settings.content.beta_content = config.get_value("content", "beta_content", settings.content.beta_content)
	settings.content.charlie_content = config.get_value("content", "charlie_content", settings.content.charlie_content)
	settings.content.difficulty = config.get_value("content", "difficulty", settings.content.difficulty)
	
	# Multiplayer settings
	settings.multiplayer.player_name = config.get_value("multiplayer", "player_name", settings.multiplayer.player_name)
	settings.multiplayer.server_address = config.get_value("multiplayer", "server_address", settings.multiplayer.server_address)
	settings.multiplayer.server_port = config.get_value("multiplayer", "server_port", settings.multiplayer.server_port)
	settings.multiplayer.auto_connect = config.get_value("multiplayer", "auto_connect", settings.multiplayer.auto_connect)

# Save settings to file
func save_settings():
	var config = ConfigFile.new()
	
	# UI settings
	config.set_value("ui", "resolution", settings.ui.resolution)
	config.set_value("ui", "fullscreen", settings.ui.fullscreen)
	config.set_value("ui", "vsync", settings.ui.vsync)
	config.set_value("ui", "ui_scale", settings.ui.ui_scale)
	
	# Audio settings
	config.set_value("audio", "master_volume", settings.audio.master_volume)
	config.set_value("audio", "music_volume", settings.audio.music_volume)
	config.set_value("audio", "sfx_volume", settings.audio.sfx_volume)
	config.set_value("audio", "voice_volume", settings.audio.voice_volume)
	config.set_value("audio", "mute", settings.audio.mute)
	
	# Content settings
	config.set_value("content", "alpha_content", settings.content.alpha_content)
	config.set_value("content", "beta_content", settings.content.beta_content)
	config.set_value("content", "charlie_content", settings.content.charlie_content)
	config.set_value("content", "difficulty", settings.content.difficulty)
	
	# Multiplayer settings
	config.set_value("multiplayer", "player_name", settings.multiplayer.player_name)
	config.set_value("multiplayer", "server_address", settings.multiplayer.server_address)
	config.set_value("multiplayer", "server_port", settings.multiplayer.server_port)
	config.set_value("multiplayer", "auto_connect", settings.multiplayer.auto_connect)
	
	# Save to file
	config.save(SETTINGS_PATH)
	print("Settings saved to: ", SETTINGS_PATH)

# Update UI controls from settings
func update_ui_from_settings():
	# UI tab
	var resolution_index = 1  # Default to 1080p
	match settings.ui.resolution:
		"1280 x 720":
			resolution_index = 0
		"1920 x 1080":
			resolution_index = 1
		"2560 x 1440":
			resolution_index = 2
		"3840 x 2160":
			resolution_index = 3
	
	resolution_option.selected = resolution_index
	fullscreen_checkbox.button_pressed = settings.ui.fullscreen
	vsync_checkbox.button_pressed = settings.ui.vsync
	ui_scale_slider.value = settings.ui.ui_scale
	ui_scale_value.text = str(settings.ui.ui_scale)
	
	# Audio tab
	master_volume_slider.value = settings.audio.master_volume
	master_volume_value.text = str(int(settings.audio.master_volume * 100)) + "%"
	music_volume_slider.value = settings.audio.music_volume
	music_volume_value.text = str(int(settings.audio.music_volume * 100)) + "%"
	sfx_volume_slider.value = settings.audio.sfx_volume
	sfx_volume_value.text = str(int(settings.audio.sfx_volume * 100)) + "%"
	voice_volume_slider.value = settings.audio.voice_volume
	voice_volume_value.text = str(int(settings.audio.voice_volume * 100)) + "%"
	mute_checkbox.button_pressed = settings.audio.mute
	
	# Content tab
	alpha_content_checkbox.button_pressed = settings.content.alpha_content
	beta_content_checkbox.button_pressed = settings.content.beta_content
	charlie_content_checkbox.button_pressed = settings.content.charlie_content
	difficulty_option.selected = settings.content.difficulty
	
	# Multiplayer tab
	player_name_field.text = settings.multiplayer.player_name
	server_address_field.text = settings.multiplayer.server_address
	server_port_spinbox.value = settings.multiplayer.server_port
	auto_connect_checkbox.button_pressed = settings.multiplayer.auto_connect

# Apply settings to the game
func apply_settings():
	# UI settings
	var window_mode = DisplayServer.WINDOW_MODE_FULLSCREEN if settings.ui.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(window_mode)
	
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.ui.vsync else DisplayServer.VSYNC_DISABLED)
	
	# Resolution setting
	var resolution = Vector2i()
	match settings.ui.resolution:
		"1280 x 720":
			resolution = Vector2i(1280, 720)
		"1920 x 1080":
			resolution = Vector2i(1920, 1080)
		"2560 x 1440":
			resolution = Vector2i(2560, 1440)
		"3840 x 2160":
			resolution = Vector2i(3840, 2160)
	
	DisplayServer.window_set_size(resolution)
	
	# Apply UI scale (this would depend on your UI implementation)
	# Example:
	# get_tree().root.content_scale_factor = settings.ui.ui_scale
	
	# Audio settings
	# These would connect to your AudioServer setup
	# Example:
	var bus_idx_master = AudioServer.get_bus_index("Master")
	var bus_idx_music = AudioServer.get_bus_index("Music")
	var bus_idx_sfx = AudioServer.get_bus_index("SFX")
	var bus_idx_voice = AudioServer.get_bus_index("Voice")
	
	if bus_idx_master >= 0:
		AudioServer.set_bus_mute(bus_idx_master, settings.audio.mute)
		AudioServer.set_bus_volume_db(bus_idx_master, linear_to_db(settings.audio.master_volume))
	
	if bus_idx_music >= 0:
		AudioServer.set_bus_volume_db(bus_idx_music, linear_to_db(settings.audio.music_volume))
	
	if bus_idx_sfx >= 0:
		AudioServer.set_bus_volume_db(bus_idx_sfx, linear_to_db(settings.audio.sfx_volume))
	
	if bus_idx_voice >= 0:
		AudioServer.set_bus_volume_db(bus_idx_voice, linear_to_db(settings.audio.voice_volume))
	
	# Content settings and multiplayer settings would be used by other systems in your game

# UI tab signal handlers
func _on_resolution_option_item_selected(index):
	var resolution_text = resolution_option.get_item_text(index)
	settings.ui.resolution = resolution_text
	print("Resolution changed to: ", resolution_text)

func _on_fullscreen_checkbox_toggled(button_pressed):
	settings.ui.fullscreen = button_pressed
	print("Fullscreen toggled: ", button_pressed)

func _on_vsync_checkbox_toggled(button_pressed):
	settings.ui.vsync = button_pressed
	print("VSync toggled: ", button_pressed)

func _on_ui_scale_slider_value_changed(value):
	settings.ui.ui_scale = value
	ui_scale_value.text = str(value)
	print("UI Scale changed to: ", value)

# Audio tab signal handlers
func _on_master_volume_slider_value_changed(value):
	settings.audio.master_volume = value
	master_volume_value.text = str(int(value * 100)) + "%"
	print("Master volume changed to: ", value)

func _on_music_volume_slider_value_changed(value):
	settings.audio.music_volume = value
	music_volume_value.text = str(int(value * 100)) + "%"
	print("Music volume changed to: ", value)

func _on_sfx_volume_slider_value_changed(value):
	settings.audio.sfx_volume = value
	sfx_volume_value.text = str(int(value * 100)) + "%"
	print("SFX volume changed to: ", value)

func _on_voice_volume_slider_value_changed(value):
	settings.audio.voice_volume = value
	voice_volume_value.text = str(int(value * 100)) + "%"
	print("Voice volume changed to: ", value)

func _on_mute_checkbox_toggled(button_pressed):
	settings.audio.mute = button_pressed
	print("Mute toggled: ", button_pressed)

# Content tab signal handlers
func _on_alpha_content_checkbox_toggled(button_pressed):
	settings.content.alpha_content = button_pressed
	print("Alpha content toggled: ", button_pressed)

func _on_beta_content_checkbox_toggled(button_pressed):
	settings.content.beta_content = button_pressed
	print("Beta content toggled: ", button_pressed)

func _on_charlie_content_checkbox_toggled(button_pressed):
	settings.content.charlie_content = button_pressed
	print("Charlie content toggled: ", button_pressed)

func _on_difficulty_option_item_selected(index):
	settings.content.difficulty = index
	print("Difficulty changed to: ", index)

# Multiplayer tab signal handlers
func _on_player_name_field_text_changed(new_text):
	settings.multiplayer.player_name = new_text
	print("Player name changed to: ", new_text)

func _on_server_address_field_text_changed(new_text):
	settings.multiplayer.server_address = new_text
	print("Server address changed to: ", new_text)

func _on_server_port_spinbox_value_changed(value):
	settings.multiplayer.server_port = int(value)
	print("Server port changed to: ", value)

func _on_auto_connect_checkbox_toggled(button_pressed):
	settings.multiplayer.auto_connect = button_pressed
	print("Auto connect toggled: ", button_pressed)

# Button panel signal handlers
func _on_back_button_pressed():
	# Go back without saving
	print("Back button pressed, returning without saving")
	get_tree().change_scene_to_file("res://scenes/mainmenu/mainmenu.tscn")

func _on_start_button_pressed():
	# Save settings and apply them
	save_settings()
	apply_settings()
	print("Settings saved and applied")
	get_tree().change_scene_to_file("res://scenes/mainmenu/mainmenu.tscn")
