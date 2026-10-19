
extends CharacterBody2D

@onready var move_speed = 50
@onready var break_acc = 2000
@onready var acc = 1000
var travado: bool = false

var pode_andar: bool = true


# Positivo Y = baixo | Negativo Y = cima
# Positivo X = direita | Negativo X = esquerda

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


func travar(valor: bool) -> void:
	travado = valor
	if valor:
		velocity = Vector2.ZERO
		$Walk.stop()

func _physics_process(delta):
	if travado:
		velocity = Vector2.ZERO
		return

	if not pode_andar:
		velocity = Vector2.ZERO
		update_anim()
		move_and_slide()
		return

	update_move(delta)
	update_anim()

func update_move(delta):
	if Input.is_action_pressed("right"):
		if velocity.x < 0:
			velocity.x = 0

		velocity.x += delta * acc
		velocity.y = 0

		if velocity.x > move_speed:
			velocity.x = move_speed

	elif Input.is_action_pressed("left"):
		if velocity.x > 0:
			velocity.x = 0

		velocity.x -= delta * acc
		velocity.y = 0

		if velocity.x < -move_speed:
			velocity.x = -move_speed

	elif Input.is_action_pressed("down"):
		if velocity.y < 0:
			velocity.y = 0

		velocity.y += delta * acc
		velocity.x = 0

		if velocity.y > move_speed:
			velocity.y = move_speed

	elif Input.is_action_pressed("up"):
		if velocity.y > 0:
			velocity.y = 0

		velocity.y -= delta * acc
		velocity.x = 0

		if velocity.y < -move_speed:
			velocity.y = -move_speed

	else:
		velocity = Vector2.ZERO

	move_and_slide()
