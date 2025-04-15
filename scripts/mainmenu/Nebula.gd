extends Node2D

@onready var shader_sprite = $NebulaSpriteLayer
@onready var timer = $AnimationTimer

var time_seed = 0.0
var scroll_speed = 0.02
var color_transition_speed = 0.05

func _ready():
	# Create the shader material
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://assets/background/NebulaClouds.gdshader")
	
	# Create sprite to apply shader
	shader_sprite.material = shader_material
	
	# Start the animation timer
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	timer.start()

func _process(delta):
	# Animate the time seed for continuous movement
	time_seed += scroll_speed * delta
	
	# Update shader parameters
	if shader_sprite.material:
		shader_sprite.material.set_shader_parameter("time_seed", time_seed)
		
		# Smooth color transitions
		var base_color = Color(
			0.2 + sin(time_seed * color_transition_speed) * 0.03, 
			0.1 + cos(time_seed * color_transition_speed) * 0.02, 
			0.3 + sin(time_seed * color_transition_speed * 0.5) * 0.04
		)
		var accent_color = Color(
			0.4 + cos(time_seed * color_transition_speed) * 0.05, 
			0.2 + sin(time_seed * color_transition_speed) * 0.03, 
			0.6 + cos(time_seed * color_transition_speed * 0.4) * 0.06
		)
		
		shader_sprite.material.set_shader_parameter("base_color", base_color)
		shader_sprite.material.set_shader_parameter("accent_color", accent_color)
		
		# Subtle dynamic adjustments
		shader_sprite.material.set_shader_parameter("cloud_scale", 
			3.0 + sin(time_seed * 0.1) * 0.5)
		shader_sprite.material.set_shader_parameter("cloud_density", 
			0.5 + cos(time_seed * 0.15) * 0.1)

func _on_timer_timeout():
	# Randomize animation parameters slightly
	scroll_speed = randf_range(0.01, 0.04)
	color_transition_speed = randf_range(0.03, 0.08)
