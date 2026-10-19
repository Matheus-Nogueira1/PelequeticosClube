
extends CharacterBody2D

var player_near := false
var player: CharacterBody2D = null
var interacting := false
var cutscene_started := false


func _ready():
	player_near = false
	player = null
	interacting = false
	cutscene_started = false

	$InteractionArea.body_entered.connect(_on_body_entered)
	$InteractionArea.body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body is CharacterBody2D:
		player_near = true
		player = body


func _on_body_exited(body):
	if body == player and not cutscene_started:
		player_near = false
		player = null
		interacting = false
		$"../UI/DialogueBox".visible = false


func _process(_delta):
	if player_near and not interacting and not cutscene_started:
		if Input.is_action_just_pressed("interact"):
			interact()


func interact():
	interacting = true
	$"../UI/DialogueBox".visible = true
	print("Abriu o diálogo!")


func _on_light_button_pressed():
	if not interacting or not player_near or player == null:
		return

	iniciar_empurrao()


func _on_darkness_button_pressed():
	if not interacting or not player_near or player == null:
		return

	iniciar_empurrao()


# Vira um sprite na direção desejada.
# Considera que o sprite original olha para a direita.
func virar_sprite(sprite: Node, direita: bool):
	if sprite is AnimatedSprite2D or sprite is Sprite2D:
		sprite.flip_h = not direita


# Vira os sprites do personagem.
func virar_personagem(personagem: CharacterBody2D, direita: bool):
	var sprites = personagem.find_children(
		"*", "AnimatedSprite2D", true, false
	)

	sprites.append_array(
		personagem.find_children("*", "Sprite2D", true, false)
	)

	for sprite in sprites:
		virar_sprite(sprite, direita)


# Calcula a duração real de uma animação não repetitiva.
func duracao_animacao(
	sprite: AnimatedSprite2D,
	nome: String
) -> float:
	var frames = sprite.sprite_frames

	if frames == null or not frames.has_animation(nome):
		return 1.8

	var fps = frames.get_animation_speed(nome) * sprite.speed_scale

	if fps <= 0.0:
		return 1.8

	var total := 0.0

	for i in range(frames.get_frame_count(nome)):
		total += frames.get_frame_duration(nome, i)

	return total / fps


func iniciar_empurrao():
	if cutscene_started:
		return

	if not interacting or not player_near or player == null:
		return

	cutscene_started = true
	interacting = true

	$"../UI/DialogueBox".visible = false

	# Guarda a referência do jogador.
	var player_ref = player

	# Impede o jogador de andar durante a cutscene.
	player_ref.velocity = Vector2.ZERO
	player_ref.set_physics_process(false)

	# Vira a Velha e o jogador um para o outro.
	var velha_pos = $Empurrar.global_position
	var player_pos = player_ref.global_position

	var velha_direita = player_pos.x > velha_pos.x
	var player_direita = velha_pos.x > player_pos.x

	virar_sprite($Empurrar, velha_direita)
	virar_personagem(player_ref, player_direita)

	# Mantém o posicionamento original da câmera.
	var camera = $"../Camera2D"
	var ponto = (velha_pos + player_pos) / 2.0

	camera.enabled = true
	camera.global_position = ponto
	camera.zoom = Vector2(2, 2)

	# Aproxima a câmera lentamente.
	var zoom_tween = create_tween()

	zoom_tween.tween_property(
		camera,
		"zoom",
		Vector2(4, 4),
		3.0
	)

	await zoom_tween.finished

	# Animação do empurrão e som.
	$Empurrar.play("empurrar")
	$AudioStreamPlayer2D.play()

	await get_tree().create_timer(0.5).timeout

	# Referências da interface.
	var black_screen = $"../UI/BlackScreen"
	var falling_player = $"../UI/CaindoCutscene"

	black_screen.z_index = 5
	falling_player.z_index = 10

	# Escurece a tela.
	black_screen.visible = true
	black_screen.modulate.a = 0.0

	var fade = create_tween()
	fade.tween_property(
		black_screen,
		"modulate:a",
		1.0,
		1.0
	)

	await fade.finished

	# Esconde o jogador original.
	player_ref.visible = false

	# Prepara o sprite da queda.
	falling_player.visible = true
	falling_player.position = get_viewport_rect().size / 2.0
	falling_player.offset = Vector2.ZERO
	falling_player.rotation = 0.0
	falling_player.scale = Vector2(3.0, 3.0)

	# Animação de queda: uma única reprodução.
	falling_player.sprite_frames.set_animation_loop(
		"CaindoCutscene",
		false
	)
	falling_player.speed_scale = 0.65

	# Calcula a duração depois de definir a velocidade.
	var duracao_queda = duracao_animacao(
		falling_player,
		"CaindoCutscene"
	)
	duracao_queda = maxf(duracao_queda, 0.5)

	print("Duração da queda: ", duracao_queda)

	# Inicia a animação.
	falling_player.play("CaindoCutscene")

	# Faz o movimento terminar junto da animação.
	var queda = create_tween()
	queda.set_parallel(true)

	queda.tween_property(
		falling_player,
		"position",
		falling_player.position + Vector2(0, 100),
		duracao_queda
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	queda.tween_property(
		falling_player,
		"rotation",
		deg_to_rad(12.0),
		duracao_queda
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	queda.tween_property(
		falling_player,
		"scale",
		Vector2(4.0, 4.0),
		duracao_queda
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Aguarda a animação e o movimento.
	await falling_player.animation_finished
	await queda.finished

	# Pequena pausa antes de trocar de cena.
	await get_tree().create_timer(0.15).timeout

	# Vai para a Cabana Elizabeth.
	var erro = get_tree().change_scene_to_file(
		"res://scenes/mapas/Firekeeper.tscn"
	)

	if erro != OK:
		push_error(
			"Não foi possível abrir Firekeeper.tscn. Erro: "
			+ str(erro)
		)
