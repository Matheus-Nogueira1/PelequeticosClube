extends Control
class_name DadoUI

signal dado_rolado(valor: int)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var rolando: bool = false
var travado: bool = false
var resultado_final: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(96, 96)
	resized.connect(_ajustar_sprite)
	_ajustar_sprite()
	preparar()

# Ajusta o sprite para ficar centralizado e proporcional ao tamanho do Control.
func _ajustar_sprite() -> void:
	sprite.position = size * 0.5

	var menor_lado: float = min(size.x, size.y)
	if menor_lado <= 0.0:
		menor_lado = 64.0

# Deixa o dado pronto para uma nova rolagem.
func preparar() -> void:
	rolando = false
	travado = false
	resultado_final = 0
	mouse_filter = Control.MOUSE_FILTER_STOP
	sprite.stop()
	sprite.animation = "default"
	sprite.frame = 0

# Detecta o clique do usuário no dado.
func _gui_input(event: InputEvent) -> void:
	if travado or rolando:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		rolar_dado()

# Faz o dado girar e depois mostra a face final.
func rolar_dado() -> void:
	if travado or rolando:
		return

	rolando = true
	travado = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	sprite.play("rolar")

	await get_tree().create_timer(randf_range(1.0, 1.5)).timeout

	resultado_final = randi_range(1, 6)
	sprite.stop()
	sprite.animation = "default"
	sprite.frame = resultado_final - 1

	rolando = false
	dado_rolado.emit(resultado_final)
