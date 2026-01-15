extends CharacterBody2D

@export var speed := 120
var can_move: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_direction := Vector2.DOWN

func _ready():
	add_to_group("player")

func _physics_process(_delta):
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var direction := Vector2.ZERO

	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		last_direction = direction
		play_walk_animation(direction)
	else:
		play_idle_animation()

	velocity = direction * speed
	move_and_slide()
func play_walk_animation(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			sprite.play("walk_right")
		else:
			sprite.play("walk_left")
	else:
		if dir.y > 0:
			sprite.play("walk_down")
		else:
			sprite.play("walk_up")
			
func play_idle_animation():
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			sprite.play("idle_right")
		else:
			sprite.play("idle_left")
	else:
		if last_direction.y > 0:
			sprite.play("idle_down")
		else:
			sprite.play("idle_up")
			
func set_can_move(value: bool):
	can_move = value
