extends CharacterBody2D

@onready var move_speed = 150
@onready var break_acc = 2000
@onready var acc = 1000

# Positivo y = Baixo | Negativo y = Cima
# Positivo x = Direita | Negativo x = Esquerda
func update_anim():
	if velocity.y > 0:
		$Walk.play("walk_down")
	elif velocity.y < 0:
		$Walk.play("walk_up")
	elif velocity.x < 0:
		$Walk.play("walk_left")
	elif velocity.x > 0:
		$Walk.play("walk_right")
	elif velocity.length() == 0:
		$Walk.stop()
	$Shadow.play("shadow")
	velocity.length()

func _physics_process(delta):
	update_move(delta)
	update_anim()
	
func update_move(delta):
	if Input.is_action_pressed("right"):
		if velocity.x < 0:
			velocity.x = 0
		velocity.x += delta*acc
		velocity.y = 0
		if velocity.x > move_speed:
			velocity.x = move_speed
	elif Input.is_action_pressed("left"):
		if velocity.x > 0:
			velocity.x = 0
		velocity.x -= delta*acc
		velocity.y = 0
		if velocity.x < -move_speed:
			velocity.x = -move_speed
	elif Input.is_action_pressed("down"):
		if velocity.y < 0:
			velocity.y = 0
		velocity.y+= delta*acc
		velocity.x = 0
		if velocity.y > move_speed:
			velocity.y = move_speed
	elif Input.is_action_pressed("up"):
		if velocity.y > 0:
			velocity.y = 0
		velocity.y -= delta*acc
		velocity.x = 0
		if velocity.y < -move_speed:
			velocity.y = -move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
