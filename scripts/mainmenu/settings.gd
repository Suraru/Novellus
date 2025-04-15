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
		"delta_content": true,
		"epsilon_content": true
	},
	"multiplayer": {
		"player_name": "",
		"server_address": "127.0.0.1",
		"server_port": 9876,
		"auto_connect": false
	}
}

# Path to save settings file
const SETTINGS_PATH = "user://settings.cfg"

# References to UI elements - using more reliable node paths
@onready var resolution_option = $SettingsContainer/TabContainer/UI/VBoxContainer/ResolutionSetting/OptionButton
@onready var fullscreen_checkbox = $SettingsContainer/TabContainer/UI/VBoxContainer/FullscreenSetting/CheckBox
@onready var vsync_checkbox = $SettingsContainer/TabContainer/UI/VBoxContainer/VSyncSetting/CheckBox
@onready var ui_scale_slider = $SettingsContainer/TabContainer/UI/VBoxContainer/UIScaleSetting/HSlider
@onready var ui_scale_value = $SettingsContainer/TabContainer/UI/VBoxContainer/UIScaleSetting/Value

@onready var master_volume_slider = $SettingsContainer/TabContainer/Audio/VBoxContainer/MasterVolumeSetting/HBoxContainer/HSlider
@onready var master_volume_value = $SettingsContainer/TabContainer/Audio/VBoxContainer/MasterVolumeSetting/HBoxContainer/Value
@onready var music_volume_slider = $SettingsContainer/TabContainer/Audio/VBoxContainer/MusicVolumeSetting/HBoxContainer/HSlider
@onready var music_volume_value = $SettingsContainer/TabContainer/Audio/VBoxContainer/MusicVolumeSetting/HBoxContainer/Value
@onready var sfx_volume_slider = $SettingsContainer/TabContainer/Audio/VBoxContainer/SFXVolumeSetting/HBoxContainer/HSlider
@onready var sfx_volume_value = $SettingsContainer/TabContainer/Audio/VBoxContainer/SFXVolumeSetting/HBoxContainer/Value
@onready var voice_volume_slider = $SettingsContainer/TabContainer/Audio/VBoxContainer/VoiceVolumeSetting/HBoxContainer/HSlider
@onready var voice_volume_value = $SettingsContainer/TabContainer/Audio/VBoxContainer/VoiceVolumeSetting/HBoxContainer/Value
@onready var mute_checkbox = $SettingsContainer/TabContainer/Audio/VBoxContainer/MuteSetting/CheckBox

@onready var alpha_content_checkbox = $SettingsContainer/TabContainer/Content/VBoxContainer/AlphaContentSetting/CheckBox
@onready var beta_content_checkbox = $SettingsContainer/TabContainer/Content/VBoxContainer/BetaContentSetting/CheckBox
@onready var charlie_content_checkbox = $SettingsContainer/TabContainer/Content/VBoxContainer/CharlieContentSetting/CheckBox
@onready var delta_content_checkbox = $SettingsContainer/TabContainer/Content/VBoxContainer/DeltaContentSetting/CheckBox
@onready var epsilon_content_checkbox = $SettingsContainer/TabContainer/Content/VBoxContainer/DeltaContentSetting2/CheckBox

@onready var player_name_field = $SettingsContainer/TabContainer/Multiplayer/VBoxContainer/PlayerNameSetting/LineEdit
@onready var server_address_field = $SettingsContainer/TabContainer/Multiplayer/VBoxContainer/ServerAddressSetting/LineEdit
@onready var server_port_spinbox = $SettingsContainer/TabContainer/Multiplayer/VBoxContainer/ServerPortSetting/SpinBox
@onready var auto_connect_checkbox = $SettingsContainer/TabContainer/Multiplayer/VBoxContainer/AutoConnectSetting/CheckBox

func _ready():
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	# Ensure AudioServer has required buses
	ensure_audio_buses()
	
	# Load settings
	load_settings()
	
	# Update UI
	update_ui_from_settings()
	
	# Connect button signals
	$ButtonPanel/BackButton.pressed.connect(_on_back_button_pressed)
	$ButtonPanel/StartButton.pressed.connect(_on_start_button_pressed)
	
	# Connect slider signals
	ui_scale_slider.value_changed.connect(_on_ui_scale_slider_value_changed)
	master_volume_slider.value_changed.connect(_on_master_volume_slider_value_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_slider_value_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_slider_value_changed)
	voice_volume_slider.value_changed.connect(_on_voice_volume_slider_value_changed)
	
	# Connect checkbox and dropdown signals
	resolution_option.item_selected.connect(_on_resolution_option_item_selected)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_checkbox_toggled)
	vsync_checkbox.toggled.connect(_on_vsync_checkbox_toggled)
	mute_checkbox.toggled.connect(_on_mute_checkbox_toggled)
	
	# Connect content settings
	alpha_content_checkbox.toggled.connect(_on_alpha_content_checkbox_toggled)
	beta_content_checkbox.toggled.connect(_on_beta_content_checkbox_toggled)
	charlie_content_checkbox.toggled.connect(_on_charlie_content_checkbox_toggled)
	delta_content_checkbox.toggled.connect(_on_delta_content_checkbox_toggled) if delta_content_checkbox else null
	epsilon_content_checkbox.toggled.connect(_on_epsilon_content_checkbox_toggled) if epsilon_content_checkbox else null
	
	# Connect multiplayer settings
	player_name_field.text_changed.connect(_on_player_name_field_text_changed)
	server_address_field.text_changed.connect(_on_server_address_field_text_changed)
	server_port_spinbox.value_changed.connect(_on_server_port_spinbox_value_changed)
	auto_connect_checkbox.toggled.connect(_on_auto_connect_checkbox_toggled)
	
func _on_viewport_size_changed():
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Handle background scaling
	var bg_texture_size = background.texture.get_size()
	var bg_scale_x = viewport_size.x / bg_texture_size.x
	var bg_scale_y = viewport_size.y / bg_texture_size.y
	var scaling_factor = max(bg_scale_x, bg_scale_y)
	
	background.scale = Vector2(scaling_factor, scaling_factor)
	background.centered = false

# Ensure audio buses exist
func ensure_audio_buses():
	# Create audio buses if they don't exist
	if AudioServer.get_bus_index("Master") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(1, "Master")
	
	# Only try to add these if you're actually using them
	var last_idx = AudioServer.bus_count - 1
	
	if AudioServer.get_bus_index("Music") < 0:
		AudioServer.add_bus()
		last_idx += 1
		AudioServer.set_bus_name(last_idx, "Music")
	
	if AudioServer.get_bus_index("SFX") < 0:
		AudioServer.add_bus()
		last_idx += 1
		AudioServer.set_bus_name(last_idx, "SFX")
	
	if AudioServer.get_bus_index("Voice") < 0:
		AudioServer.add_bus()
		last_idx += 1
		AudioServer.set_bus_name(last_idx, "Voice")

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
	settings.content.delta_content = config.get_value("content", "delta_content", settings.content.delta_content)
	settings.content.epsilon_content = config.get_value("content", "epsilon_content", settings.content.epsilon_content)
	
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
	config.set_value("content", "delta_content", settings.content.delta_content)
	config.set_value("content", "epsilon_content", settings.content.epsilon_content)
	
	# Multiplayer settings
	config.set_value("multiplayer", "player_name", settings.multiplayer.player_name)
	config.set_value("multiplayer", "server_address", settings.multiplayer.server_address)
	config.set_value("multiplayer", "server_port", settings.multiplayer.server_port)
	config.set_value("multiplayer", "auto_connect", settings.multiplayer.auto_connect)
	
	# Save to file
	var error = config.save(SETTINGS_PATH)
	if error == OK:
		print("Settings saved to: ", SETTINGS_PATH)
	else:
		print("Error saving settings: ", error)

# Update UI controls from settings
func update_ui_from_settings():
	# UI tab
	var resolution_index = 1  # Default to 1080p
	match settings.ui.resolution:
		"1280 x 720": resolution_index = 0
		"1920 x 1080": resolution_index = 1
		"2560 x 1440": resolution_index = 2
		"3840 x 2160": resolution_index = 3
	
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
	
	if delta_content_checkbox:
		delta_content_checkbox.button_pressed = settings.content.delta_content
	
	if epsilon_content_checkbox:
		epsilon_content_checkbox.button_pressed = settings.content.epsilon_content
	
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
		"1280 x 720": resolution = Vector2i(1280, 720)
		"1920 x 1080": resolution = Vector2i(1920, 1080)
		"2560 x 1440": resolution = Vector2i(2560, 1440)
		"3840 x 2160": resolution = Vector2i(3840, 2160)
	
	DisplayServer.window_set_size(resolution)
	
	# Apply audio settings - safely check if buses exist first
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

# UI tab signal handlers
func _on_resolution_option_item_selected(index):
	var resolution_text = resolution_option.get_item_text(index)
	settings.ui.resolution = resolution_text

func _on_fullscreen_checkbox_toggled(button_pressed):
	settings.ui.fullscreen = button_pressed

func _on_vsync_checkbox_toggled(button_pressed):
	settings.ui.vsync = button_pressed

func _on_ui_scale_slider_value_changed(value):
	settings.ui.ui_scale = value
	ui_scale_value.text = str(value)

# Audio tab signal handlers
func _on_master_volume_slider_value_changed(value):
	settings.audio.master_volume = value
	master_volume_value.text = str(int(value * 100)) + "%"
	
	# Apply immediately for feedback
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_music_volume_slider_value_changed(value):
	settings.audio.music_volume = value
	music_volume_value.text = str(int(value * 100)) + "%"
	
	# Apply immediately for feedback
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_sfx_volume_slider_value_changed(value):
	settings.audio.sfx_volume = value
	sfx_volume_value.text = str(int(value * 100)) + "%"
	
	# Apply immediately for feedback
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_voice_volume_slider_value_changed(value):
	settings.audio.voice_volume = value
	voice_volume_value.text = str(int(value * 100)) + "%"
	
	# Apply immediately for feedback
	var bus_idx = AudioServer.get_bus_index("Voice")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_mute_checkbox_toggled(button_pressed):
	settings.audio.mute = button_pressed
	
	# Apply immediately for feedback
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_mute(bus_idx, button_pressed)

# Content tab signal handlers
func _on_alpha_content_checkbox_toggled(button_pressed):
	settings.content.alpha_content = button_pressed

func _on_beta_content_checkbox_toggled(button_pressed):
	settings.content.beta_content = button_pressed

func _on_charlie_content_checkbox_toggled(button_pressed):
	settings.content.charlie_content = button_pressed

func _on_delta_content_checkbox_toggled(button_pressed):
	settings.content.delta_content = button_pressed

func _on_epsilon_content_checkbox_toggled(button_pressed):
	settings.content.epsilon_content = button_pressed

# Multiplayer tab signal handlers
func _on_player_name_field_text_changed(new_text):
	settings.multiplayer.player_name = new_text

func _on_server_address_field_text_changed(new_text):
	settings.multiplayer.server_address = new_text

func _on_server_port_spinbox_value_changed(value):
	settings.multiplayer.server_port = int(value)

func _on_auto_connect_checkbox_toggled(button_pressed):
	settings.multiplayer.auto_connect = button_pressed

# Button panel signal handlers
func _on_back_button_pressed():
	# Go back without saving
	get_tree().change_scene_to_file("res://scenes/mainmenu/MainMenu.tscn")

func _on_start_button_pressed():
	# Save settings and apply them
	save_settings()
	apply_settings()
	get_tree().change_scene_to_file("res://scenes/mainmenu/MainMenu.tscn")
