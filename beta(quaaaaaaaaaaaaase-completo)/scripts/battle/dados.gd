extends TextureButton
class_name DadoUI

signal dado_rolado(valor: int)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var rolando: bool = false
var travado: bool = false
var resultado_final: int = 0

@export var tamanho_botao: Vector2 = Vector2(96, 96)
@export var escala_visual: float = 6
@export var margem_vertical: float = 12.0
@export var margem_horizontal: float = 4.0

func _ready() -> void:
	custom_minimum_size = tamanho_botao
	size = tamanho_botao
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	pressed.connect(_on_pressed)
	resized.connect(_ajustar_sprite)

	sprite.centered = true
	_ajustar_sprite()
	preparar()

func _ajustar_sprite() -> void:
	var area_util: Vector2 = Vector2(
		max(size.x - margem_horizontal * 1.0, 1.0),
		max(size.y - margem_vertical * 1.0, 1.0)
	)

	sprite.position = Vector2(size.x * 0.5, size.y * 0.5)
	sprite.scale = Vector2.ONE * escala_visual

func _gui_input(event: InputEvent) -> void:
	if travado or rolando:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var local_pos: Vector2 = get_local_mouse_position()

		var limite_superior: float = margem_vertical
		var limite_inferior: float = size.y - margem_vertical
		var limite_esquerdo: float = margem_horizontal
		var limite_direito: float = size.x - margem_horizontal

		if local_pos.x >= limite_esquerdo and local_pos.x <= limite_direito and local_pos.y >= limite_superior and local_pos.y <= limite_inferior:
			rolar_dado()

func preparar() -> void:
	rolando = false
	travado = false
	resultado_final = 0
	disabled = false
	sprite.stop()
	sprite.animation = "default"
	sprite.frame = 0
	sprite.visible = true

func _on_pressed() -> void:
	# Mantido por segurança, mas o clique real é filtrado no _gui_input
	pass

func rolar_dado() -> void:
	if travado or rolando:
		return

	rolando = true
	travado = true
	disabled = true

	sprite.play("rolar")

	await get_tree().create_timer(randf_range(1.0, 1.5)).timeout

	resultado_final = randi_range(1, 6)

	sprite.stop()
	sprite.animation = "default"
	sprite.frame = resultado_final - 1

	rolando = false
	disabled = false
	dado_rolado.emit(resultado_final)
