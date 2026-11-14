
extends TileMapLayer

@export var intensidade := 1.0
@export var velocidade := 1.6

var posicao_original: Vector2
var tempo := 0.0


func _ready() -> void:
	posicao_original = position


func _process(delta: float) -> void:
	tempo += delta * velocidade

	position = posicao_original + Vector2(
		sin(tempo) * intensidade,
		sin(tempo * 0.7) * intensidade * 0.35
	)
