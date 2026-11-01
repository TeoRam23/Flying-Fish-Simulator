#@tool
extends CharacterBody3D

@export var water : Node3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var splash_particle: CPUParticles3D = $SplashParticle

@export var gravity = 50
@export var bouyancy = 80

@export var speed = 3000

var in_water := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	#linear_velocity.x = 5
	if global_position.y <= water.get_height(global_position):
		velocity.y += bouyancy * delta
		if in_water == false:
			splash_particle.emitting = true
		in_water = true
	else:
		if in_water == true:
			splash_particle.emitting = true
		in_water = false
	velocity.y -= gravity * delta
	
	var direction = Input.get_vector("right", "left", "back", "forward")
	var direction_ground = Vector3(direction.x, 0, direction.y).rotated(Vector3.UP, camera_pivot.rotation.y)
	velocity.x = direction_ground.x * speed * delta
	velocity.z = direction_ground.z * speed * delta
	
	move_and_slide()
	
	#
	#if Input.is_action_pressed("forward"):
		#velocity.z = speed * delta
	#
	#move_and_slide()
