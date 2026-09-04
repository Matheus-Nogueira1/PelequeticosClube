extends CharacterBody2D


const SPEED = 300

var last_direction: Vector2 = Vector2.RIGHT

@onready var animated_sprite2d: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	process_movement(delta)
	process_animation()
	move_and_slide()



# ------------------------------------------------------------------------
# MOVEMENT & ANIMATION
# ------------------------------------------------------------------------
func process_movement(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector("left", "right", "up", "down")

	const ACCELERATION = 800
	const FRICTION = 600

	if direction != Vector2.ZERO:
		last_direction = direction
		velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * get_physics_process_delta_time())



func process_animation() -> void:
	if velocity != Vector2.ZERO:
		play_animation("walk", last_direction) 
	else:
		play_animation("idle", last_direction)



func play_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite2d.flip_h = dir.x < 0
		animated_sprite2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite2d.play(prefix +  "_up")
	elif dir.y > 0:
		animated_sprite2d.play(prefix +  "_down")
