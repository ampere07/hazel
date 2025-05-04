extends CharacterBody2D
var speed = 180
var is_moving = false
var is_mining = false
var facing_right = true
var cursor_offset = Vector2(32, 0)
var cursor_direction = Vector2.RIGHT
# Onready variables
@onready var cursor = $Cursor
@onready var mine_fx = $mineFx

func _ready():
	update_cursor_position()

func _physics_process(_delta):
	velocity = Vector2.ZERO
	is_moving = false
	
	if Input.is_action_pressed("ui_select") or Input.is_action_pressed("ui_accept"):
		$AnimatedSprite2D.play("mine")
		is_mining = true
		
		if not mine_fx.playing:
			mine_fx.play()
		
		if cursor.has_method("check_mining_hit"):
			cursor.check_mining_hit()
	else:
		is_mining = false
		
		if Input.is_action_pressed("move_right"):
			velocity.x = 1
			$AnimatedSprite2D.play("run")
			facing_right = true
			cursor_direction = Vector2.RIGHT
			is_moving = true
		elif Input.is_action_pressed("move_left"):
			velocity.x = -1
			$AnimatedSprite2D.play("run")
			facing_right = false
			cursor_direction = Vector2.LEFT
			is_moving = true
		elif Input.is_action_pressed("move_down"):
			velocity.y = 1
			$AnimatedSprite2D.play("run")
			cursor_direction = Vector2.DOWN
			is_moving = true
		elif Input.is_action_pressed("move_up"):     
			velocity.y = -1
			$AnimatedSprite2D.play("run")
			cursor_direction = Vector2.UP
			is_moving = true
		
		if !is_moving:
			$AnimatedSprite2D.play("idle")
		else:
			velocity = velocity * speed
	
	$AnimatedSprite2D.flip_h = !facing_right
	
	if !is_mining:
		move_and_slide()
	
	update_cursor_position()

func update_cursor_position():
	var offset = cursor_offset
	
	if cursor_direction == Vector2.LEFT:
		offset = Vector2(-cursor_offset.x, cursor_offset.y)
	elif cursor_direction == Vector2.UP:
		offset = Vector2(0, -cursor_offset.y - 32)
	elif cursor_direction == Vector2.DOWN:
		offset = Vector2(0, cursor_offset.y + 32)
	
	cursor.position = offset
