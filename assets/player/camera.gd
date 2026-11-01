#Copyright © 2022 Marc Nahr: https://github.com/MarcPhi/godot-free-look-camera
extends Camera3D

@export_range(0, 10, 0.01) var sensitivity : float = 3
@export_range(0, 1000, 0.1) var default_velocity : float = 5
@export_range(0, 10, 0.01) var speed_scale : float = 1.17
@export_range(1, 100, 0.1) var boost_speed_multiplier : float = 3.0
@export var max_speed : float = 1000
@export var min_speed : float = 0.2
@export var water : Node3D
@export var the_environment : WorldEnvironment

@onready var _velocity = default_velocity
@onready var camera_pivot: Node3D = $".."
@onready var underwater_particles: CPUParticles3D = $UnderwaterParticles

const MAIN = preload("res://assets/environments/main.tres")
const UNDERWATER = preload("res://assets/environments/underwater.tres")

var is_underwater := false

var enable_camera_movement := true
var freeze_pivot := false
var pivot_pos := Vector3.ZERO
func _input(event):
	if not current or not enable_camera_movement:
		return

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			camera_pivot.rotation.y -= event.relative.x / 1000 * sensitivity
			camera_pivot.rotation.x += event.relative.y / 1000 * sensitivity
			camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, PI/-2, PI/2)

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
			MOUSE_BUTTON_WHEEL_UP: # increase fly velocity
				_velocity = clamp(_velocity * speed_scale, min_speed, max_speed)
			MOUSE_BUTTON_WHEEL_DOWN: # decrease fly velocity
				_velocity = clamp(_velocity / speed_scale, min_speed, max_speed)
			MOUSE_BUTTON_MIDDLE:
				freeze_pivot = !freeze_pivot
				pivot_pos = camera_pivot.global_position

func _process(delta):
	
	if global_position.y < water.get_height(global_position):
		if is_underwater == false:
			the_environment.environment = UNDERWATER
			underwater_particles.visible = true
			print("switch to underwater")
		is_underwater = true
	else:
		if is_underwater == true:
			the_environment.environment = MAIN
			underwater_particles.visible = false
			print("switch to main")
		is_underwater = false
	
	if freeze_pivot:
		camera_pivot.global_position = pivot_pos
	else:
		camera_pivot.position = Vector3.ZERO
	#if not current:
		#return

	#var direction = Vector3(
		#float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		#float(Input.is_physical_key_pressed(KEY_E)) - float(Input.is_physical_key_pressed(KEY_Q)),
		#float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	#).normalized()
#
	#if Input.is_physical_key_pressed(KEY_SHIFT): # boost
		#translate(direction * _velocity * delta * boost_speed_multiplier)
	#else:
		#translate(direction * _velocity * delta)
