#@tool
extends CharacterBody3D

@export var water : Node3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var splash_particle: CPUParticles3D = $SplashParticle
@onready var water_height_3d: MeshInstance3D = $WaterHeight3D
@onready var model_body: Node3D = $ModelBody
@onready var fish_model: Node3D = $ModelBody/FishModel
@onready var fish_animation: AnimationPlayer = $ModelBody/FishModel/FishAnimation
@onready var fish_animation_tree: AnimationTree = $ModelBody/FishModel/FishAnimationTree
@onready var liftoff_timer: Timer = $ModelBody/FishModel/LiftoffTimer

@export var gravity := 50.0
@export var bouyancy := 80.0

@export var speed := 1500.0
@export var max_boost := 2000.0
@export var boost_amount := 500
var current_boost := 0
@export var acceleration := 200.0
@export var water_drag := 50.0
@export var movement_drag := 20.0

var in_water := false
var last_in_water := false
var in_limbo := false
var last_direction := Vector2.ZERO
var last_pivot_rotation := Vector3.ZERO
var direction := Vector2.ZERO

var water_height = 0

var wave_update_counter = 2
var position_mover = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	water_height = water.get_height(global_position)
	direction = Input.get_vector("right", "left", "back", "forward")
	
	wave_update_counter += 1
	if wave_update_counter >= 3:
		wave_update_counter = 0
		if global_position.y > water_height:
			position_mover = (global_position.y - water_height) * 0.15
		else:
			position_mover = (global_position.y - water_height) * 0.15
	water_height_3d.global_position.y = water_height
	#linear_velocity.x = 5
	#print(velocity.y * delta)
	
	# LIMBO type 1
	if global_position.y <= water_height+3 and global_position.y >= water_height-3 \
	and abs(velocity.y) * delta <= 0.03 and 1==2:
		in_limbo = true
		#velocity.y -= (global_position.y - water_height) * 5
		global_position.y -= position_mover
		#global_position.y = water_height
		
		#print("i am Limbo")
	else:
		in_limbo = false
	
	
	# Dette brukes i air movement, når vi ikke gjør noe skal den glide i siste retning vi så i. Må gjøre det utenform air_movement()
	if direction:
		last_direction = direction
		last_pivot_rotation = camera_pivot.rotation
	
	
	if global_position.y <= water_height or in_limbo:
		if in_water == false:
			splash_particle.emitting = true
		in_water = true
		new_water_movement(delta)
		#print("uuuuuuuhhhh")
	elif global_position.y > water_height:# and in_limbo == false:
		if in_water == true:
			splash_particle.emitting = true
		in_water = false
		air_movement(delta)
		
	velocity *= scale.x
	move_and_slide()
	velocity /= scale.x
	
	update_model()
	

	water_height_3d.global_position.y = water_height
	
	last_in_water = in_water
	#
	#if Input.is_action_pressed("forward"):
		#velocity.z = speed * delta
	#
	#move_and_slide()
	
	

func air_movement(delta):
	velocity.y -= gravity * delta 
	

	var pivot_rotation : Vector3
	
	if not direction:
		# jeg vet ikke om jeg heller vil falle eller glide videre når man slipper knappen
		return
		direction = last_direction
		pivot_rotation = last_pivot_rotation
	else:
		pivot_rotation = camera_pivot.rotation
		last_direction = direction
		last_pivot_rotation = pivot_rotation
	
	var direction_vertical = Vector3(0, 0, 1).rotated(Vector3.RIGHT, pivot_rotation.x)
	#var direction_horizontal = Vector3(direction_vertical.x, 0, direction_vertical.z).rotated(Vector3.UP, camera_pivot.rotation.y)
	var direction_horizontal = Vector3(direction.x, 0, direction.y).rotated(Vector3.UP, pivot_rotation.y)
	var up_direction = sin(pivot_rotation.x)
	

	
	#print(direction_vertical.y)
	
	var total_speed = Vector3.ZERO.distance_to(velocity)
	var forward_speed = Vector2.ZERO.distance_to(Vector2(velocity.x, velocity.z))
	#total_speed = 0.5
	
	#print(total_speed)
	
	#total_speed -= direction_vertical.y*total_speed*0.01
	
	# rett ned
	#lift = total_speed * direction_vertical.y
	# DETTE VIRKER IKKE! NÅR SPEED ER 0 KOMMER MAN SEG IKKE NED IGJEN Å NEI
	# så denne metoden er det noe fundametalt feil med :(
	
	#lift = direction_vertical.y * total_speed
	#lift = (direction_vertical.y+1) * gravity*delta *(total_speed)*0.02
	
	#lift = (direction_vertical.y+1) * gravity*delta *(total_speed)*0.02
	#forward_speed += 0
	
	#lift = (direction_vertical.y+1) * forward_speed*delta
	#forward_speed += 0 # hvordan kalkulerer man forward speed? det er så rare tidspunkter om når den skal stige eller senke.... idk
	#forward_speed = abs(abs(direction_vertical.y)-1) * total_speed
	
	# når vi går nedover og glider
	if velocity.y < 0:
		var glide = 0.1 * (-velocity.y) * ((abs(abs(direction_vertical.y)-1))**2)
		velocity.x += 0.6 * glide * direction_horizontal.x * 60*delta
		velocity.y += glide * 60*delta
		velocity.z += 0.6 * glide * direction_horizontal.z * 60*delta
		
	# når vi peker oppover
	if direction_vertical.y > 0:
		var lift = 0.128*0.3 * forward_speed * direction_vertical.y
		velocity.x -= 0.3125 * lift * direction_horizontal.x * 60*delta
		velocity.y += lift * 1.0 * 60*delta
		velocity.z -= 0.3125 * lift * direction_horizontal.z * 60*delta
	
	# jeg tror denne gjør man man kan styre
	velocity.x -= 0.1 * (velocity.x - forward_speed * direction_horizontal.x) * 60*delta
	velocity.z -= 0.1 * (velocity.z - forward_speed * direction_horizontal.z) * 60*delta
	
	
	# drag
	velocity.x *= 0.999 * 60*delta;
	if velocity.y > 0:
		velocity.y *= 0.98 * 60*delta;
	velocity.z *= 0.999 * 60*delta;
	
	

	
	#print(direction_vertical.y)
	#print(gravity*delta)
	#print()
	#print("lift ", lift)
	#print("total speed ", total_speed)
	#print("forward speed ", forward_speed)
	#print("forward speed ", forward_speed)
	#print("math 1 ", )
	#print("rest speed ", rest_speed)
	#print("x dpeed ", direction_horizontal.x * rest_speed)
	#print("velocity ", velocity)
	#print("directions, ", Vector3(direction_horizontal.x, direction_vertical.y, direction_horizontal.z))
	#print("up direction, ", up_direction)
	#print("pivot dir, ", camera_pivot.rotation.x)
	#print()
	
	#velocity.y += lift
	#velocity.x = direction_horizontal.x * forward_speed
	#velocity.z = direction_horizontal.z * forward_speed
	#print("new_velocity ", velocity)
	
	
	# ok hva er det vi gjør?
	# jo mer opp vi ser, jo mindre fart, men høyere altitude,
	# jo lavere vi ser, jo mindre altitude, men høyere fart...
	# når vi ser rett fram mister vi verken fart eller altitude

	
	#lift = -camera_pivot.rotation.x * 0.3 + total_speed * 0.5 #camera_pivot må erstattes med noe...
	#velocity.y += lift
	#print(gravity*delta)





func new_water_movement(delta):
	var direction_vertical = Vector3(direction.x, 0, direction.y).rotated(Vector3.RIGHT, camera_pivot.rotation.x)
	var direction_horizontal = Vector3(direction_vertical.x, 0, direction_vertical.z).rotated(Vector3.UP, camera_pivot.rotation.y)
	
	var total_speed = Vector3.ZERO.distance_to(velocity)
	
	if direction:
		
		if total_speed < (speed + current_boost)*delta:
			total_speed += acceleration * delta
			if total_speed > (speed + current_boost)*delta:
				total_speed = (speed + current_boost)*delta
			
		
		
		#velocity.x = total_speed * direction_horizontal.x
		#velocity.y = total_speed * direction_vertical.y
		#velocity.z = total_speed * direction_horizontal.z
		
		# turning og akselerering
		velocity.x -= 0.3 * (velocity.x - total_speed * direction_horizontal.x) * 60*delta
		velocity.y -= 0.3 * (velocity.y - total_speed * direction_vertical.y) * 60*delta
		velocity.z -= 0.3 * (velocity.z - total_speed * direction_horizontal.z) * 60*delta
		
		# drag mens vi styrer
		velocity.x *= 0.999 * 60*delta;
		velocity.y *= 0.999 * 60*delta;
		velocity.z *= 0.999 * 60*delta;
	else:
		# drag når vi ikke styrer
		velocity.x *= 0.98 * 60*delta;
		velocity.y *= 0.98 * 60*delta;
		velocity.z *= 0.98 * 60*delta;
		

func water_movement(delta):
	var direction_vertical = Vector3(direction.x, 0, direction.y).rotated(Vector3.RIGHT, camera_pivot.rotation.x)
	var direction_horizontal = Vector3(direction_vertical.x, 0, direction_vertical.z).rotated(Vector3.UP, camera_pivot.rotation.y)
	
	var our_speed = Vector3.ZERO.distance_to(velocity)*60
	var using_speed = speed+current_boost
	if our_speed > using_speed:
		using_speed = our_speed
	#print("our speed ", our_speed * 60)
	#print("speed, ", speed + current_boost)
	
	
	if direction == Vector2.ZERO and in_limbo:
		direction_vertical.y = 0
		#velocity.y = 0
		
		
	if direction_horizontal.x == 0:
		velocity.x = move_toward(velocity.x, direction_horizontal.x * (using_speed) * delta, water_drag * delta)
	else:
		velocity.x = move_toward(velocity.x, direction_horizontal.x * (using_speed) * delta, lerp(movement_drag, acceleration, abs(direction_horizontal.x)) * delta)
	if direction_vertical.y == 0:
		velocity.y = move_toward(velocity.y, direction_vertical.y * (using_speed) * delta, water_drag * delta)
	else:
		velocity.y = move_toward(velocity.y, direction_vertical.y * (using_speed) * delta, lerp(movement_drag, acceleration, abs(direction_vertical.y)) * delta)
	if direction_horizontal.z == 0:
		velocity.z = move_toward(velocity.z, direction_horizontal.z * (using_speed) * delta, water_drag * delta)
	else:
		velocity.z = move_toward(velocity.z, direction_horizontal.z * (using_speed) * delta, lerp(movement_drag, acceleration, abs(direction_horizontal.z)) * delta)
	
	
	#velocity.x = move_toward(velocity.x, direction_horizontal.x * speed * delta, lerp(movement_drag, acceleration, abs(direction_horizontal.x)) * delta)
	#velocity.y = move_toward(velocity.y, direction_vertical.y * speed * delta, lerp(movement_drag, acceleration, abs(direction_vertical.y)) * delta)
	#velocity.z = move_toward(velocity.z, direction_horizontal.z * speed * delta, lerp(movement_drag, acceleration, abs(direction_horizontal.z)) * delta)
	#velocity.x = move_toward(velocity.x, direction_horizontal.x * speed * delta, acceleration * delta)
	#velocity.y = move_toward(velocity.y, direction_vertical.y * speed * delta, acceleration * delta)
	#velocity.z = move_toward(velocity.z, direction_horizontal.z * speed * delta, acceleration * delta)
	
	
	#velocity.y = direction_water.y * speed * delta
	#velocity.z = direction_ground.z * speed * delta

func update_model():
	var state_machine = fish_animation_tree["parameters/playback"]
	
	if direction:
		#model_body.rotation.y = camera_pivot.rotation.y
		#model_body.rotation = model_body.rotation.move_toward(camera_pivot.rotation, 0.1)
		#print("veler ",Vector2(velocity.x, velocity.y).normalized())
		#print("rot deg ", model_body.rotation_degrees)
		#print("rot ", model_body.rotation)
		#model_body.rotation.x = velocity.normalized().y*PI*-0.5
		#model_body.rotation.y
		
		#if abs(camera_pivot.rotation_degrees.x - model_body.rotation_degrees.x) < 0.5:
			#model_body.rotation.x = camera_pivot.rotation.x
		model_body.rotation_degrees.x += (camera_pivot.rotation_degrees.x - model_body.rotation_degrees.x) * 0.1
		model_body.rotation_degrees.y += (camera_pivot.rotation_degrees.y - model_body.rotation_degrees.y) * 0.1
		if not in_water:
			model_body.rotation_degrees.z = (model_body.rotation_degrees.y - camera_pivot.rotation_degrees.y) * 1.5
		else:
			model_body.rotation_degrees.z -= model_body.rotation_degrees.z * 0.1
	
	else: # når man ikke styrer noe
		model_body.rotation.x += (velocity.normalized().y*PI*-0.5 - model_body.rotation.x) * 0.1
		#model_body.rotation.x = velocity.normalized().y*PI*-0.5
	
	var speed = velocity.length()
	var animation_speed = speed * 0.0344
	if animation_speed > 3:
		animation_speed = 3
	#print(velocity.length())
	
	fish_animation_tree.set("parameters/Swim/SwimSpeed/scale",animation_speed)
	fish_animation_tree.set("parameters/Glide/SwimSpeed/scale",animation_speed)
	
	
	## Styrer liftoff animasjonen
	if last_in_water and not in_water:
		print("LIFTOFF!")
		liftoff_timer.start()
	var tween = get_tree().create_tween()
	fish_animation_tree.set("parameters/Glide/BlendLift/blend_amount", \
	tween.interpolate_value(1.0, -1.0, liftoff_timer.wait_time - liftoff_timer.time_left, liftoff_timer.wait_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT))
	tween.kill()
	
	
	## Styrer hvor langt ut vingene er ute, bassert på tilt
	fish_animation_tree.set("parameters/Glide/BlendGlide/blend_amount", abs(sin(model_body.rotation.x))**4.0)
	
	
	#if in_water:
		#if (speed > 10 or direction):
			#fish_animation_tree.set("parameters/SwimSpeed/scale", speed /29)
			#if fish_animation.current_animation != "Animations/Swim" or 1==1:
				##print("duh")
				##print(fish_animation.current_animation)
				##fish_animation.play("Animations/Swim", 1.0, 1.0)
				##fish_animation_tree.set("parameters/Transition/transition_request", "swim")
				#state_machine.travel("Animations_Swim")
			##fish_animation.speed_scale = 1
			##fish_animation_tree.tree_root.blend_animation("Animation/Swim")
		#else:
			#fish_animation.speed_scale = 1
			##fish_animation.play("Animations/IdleWater", 2, 1.0)
			##fish_animation_tree.set("parameters/Transition/transition_request", "idle")
			#state_machine.travel("Animations_IdleWater")
		##print("look here")
		###fish_animation.current_animation = "Animation/fish_test"
	#elif not in_water:
		#fish_animation.speed_scale = 1
		##fish_animation.play("Animations/Glide", 0.3, 1.0)
		##fish_animation_tree.set("parameters/Transition/transition_request", "glide")
		#state_machine.travel("Animations_Glide")





func _input(event: InputEvent) -> void:
	if event.is_action_pressed("boost"):
		if in_water:
			current_boost += boost_amount *4
		else:
			current_boost += boost_amount*0.5
		if not in_water:
			velocity.y += 20
		
		if current_boost > max_boost: current_boost = max_boost
		#print(current_boost)
		


# current vec starter som vec xyz
# gjør vec xyz om til straight speed og direction


# hvordan lager man drag i andre retninger? 
# hva om man har direction og speed om hvor man er på vei, og så har man en om... idk direction man prøver å dra?
