
extends Node2D

@onready var player = $Escolhido
@onready var walk = $Escolhido/Walk
@onready var levantar = $Escolhido/Levantar
@onready var black_screen = $CanvasLayer/BlackScreen


func _ready():
	print("Firekeeper: iniciando introdução")

	# 1. Tela preta no início.
	black_screen.visible = true
	black_screen.color = Color.BLACK
	black_screen.modulate.a = 1.0

	# 2. Bloqueia o movimento durante a introdução.
	player.pode_andar = false
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)

	# 3. Esconde o sprite normal.
	walk.visible = false

	# 4. Prepara a animação de levantar.
	levantar.stop()
	levantar.visible = false

	levantar.sprite_frames.set_animation_loop(
		"Levantar",
		false
	)

	levantar.speed_scale = 1.0

	# Pequena espera inicial.
	await get_tree().create_timer(0.3).timeout

	# 5. Alinha o sprite de levantar ao sprite normal.
	levantar.position = walk.position
	levantar.offset = walk.offset
	levantar.flip_h = walk.flip_h
	levantar.rotation = walk.rotation
	levantar.scale = walk.scale

	levantar.visible = true

	# 6. Inicia a animação.
	print("Firekeeper: personagem levantando")
	levantar.play("Levantar")

	# 7. Clareia a tela suavemente.
	var fade = create_tween()
	fade.set_trans(Tween.TRANS_SINE)
	fade.set_ease(Tween.EASE_IN_OUT)

	fade.tween_property(
		black_screen,
		"modulate:a",
		0.0,
		1.2
	)

	# 8. Espera a animação de levantar terminar.
	await levantar.animation_finished
	print("Firekeeper: animação concluída")

	# Mantém a espera que já funcionou no seu projeto.
	await get_tree().create_timer(1.3).timeout

	# 9. Retorna ao sprite de movimento.
	levantar.stop()
	levantar.visible = false

	walk.visible = true
	walk.play("walk_down")

	# 10. Libera o controle.
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	player.pode_andar = true

	# 11. Finaliza a introdução.
	black_screen.visible = false

	print("Firekeeper: jogador liberado!")
	print("Physics ativo: ", player.is_physics_processing())
	print("Pode andar: ", player.pode_andar)
