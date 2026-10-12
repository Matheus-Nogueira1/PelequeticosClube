extends CharacterBody2D

var player_near := false
var player: CharacterBody2D = null
var interacting := false


func _ready():
	player_near = false
	player = null
	interacting = false
	
	$InteractionArea.body_entered.connect(_on_body_entered)
	$InteractionArea.body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body is CharacterBody2D:
		player_near = true
		player = body


func _on_body_exited(body):
	if body == player:
		player_near = false
		player = null
		
		# FECHA TUDO
		interacting = false
		$"../UI/DialogueBox".visible = false


func _process(_delta):
	if player_near and not interacting:
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


func iniciar_empurrao():
	interacting = true
	
	$"../UI/DialogueBox".visible = false
	
	var camera = $"../Camera2D"
	
	# Posição real da Velha e do Player
	var velha_pos = $Empurrar.global_position
	var player_pos = player.global_position
	
	# Ponto entre os dois
	var ponto = (velha_pos + player_pos) / 2.0
	
	# Ativa a câmera SOMENTE agora
	camera.enabled = true
	
	# Coloca a câmera no ponto entre os dois
	camera.global_position = ponto
	
	# Começa sem zoom
	camera.zoom = Vector2(1, 1)
	
	# Aproxima lentamente
	var tween = create_tween()
	
	tween.tween_property(
		camera,
		"zoom",
		Vector2(2.0, 2.0),
		2.0
	)
	
	await tween.finished
	
	# Empurrão
	$Empurrar.play("empurrar")
	$AudioStreamPlayer2D.play()
	
	print("Empurrando!")
	
	await get_tree().create_timer(0.5).timeout
	
	# Tela preta
	var black_screen = $"../UI/BlackScreen"
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
	
	print("Tela preta - iniciar cutscene")
