#@tool
extends MeshInstance3D

@export var water : Node3D
var velocity := Vector3.ZERO

var gravity = 0.6
var bouyancy = 1.2
var speed = 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if global_position.y >= water.get_height(global_position):
		velocity.y -= bouyancy * delta
	velocity.y += gravity * delta
	
	
	#if Input.is_action_pressed("forward"):
		#velocity.z = speed * delta
	
	
	apply_movement(velocity)

func apply_movement(got_velocity) -> void:
	position += got_velocity
	
	
