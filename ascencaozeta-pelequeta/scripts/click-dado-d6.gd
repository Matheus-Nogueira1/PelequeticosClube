extends AnimatedSprite2D

var rolando = false

func animar_dado(lado: int) -> void:
	if rolando:
		return

	rolando = true

	play("rolar")

	await get_tree().create_timer(randf_range(1.0, 1.5)).timeout

	stop()
	animation = "default"
	frame = lado - 1

	rolando = false
