extends CharacterBody2D

var speed = 300
var is_moving = false
var last_direction = "down"
func check_boundaries():
	var viewport_size = get_viewport_rect().size
	if global_position.x < 60:
		global_position.x = 60
	if global_position.x > viewport_size.x - 55:
		global_position.x = viewport_size.x - 55
	if global_position.y < 45:
		global_position.y = 45
	if global_position.y > viewport_size.y - 70:
		global_position.y = viewport_size.y - 70
func _physics_process(delta):
	# Reset velocity
	velocity = Vector2.ZERO
	is_moving = false
	
	if Input.is_action_pressed("move_right"):
		velocity.x = 1
		$AnimatedSprite2D.play("move_right")
		last_direction = "right"
		is_moving = true
	elif Input.is_action_pressed("move_left"):
		velocity.x = -1
		$AnimatedSprite2D.play("move_left")
		last_direction = "left"
		is_moving = true
	elif Input.is_action_pressed("move_down"):
		velocity.y = 1
		$AnimatedSprite2D.play("move_down")
		last_direction = "down"
		is_moving = true
	elif Input.is_action_pressed("move_up"):     
		velocity.y = -1
		$AnimatedSprite2D.play("move_up")
		last_direction = "up"
		is_moving = true
	
	if !is_moving:
		$AnimatedSprite2D.play("idle_" + last_direction)
	else:
		velocity = velocity * speed
	
	move_and_slide()
	
	check_boundaries()
	
	
