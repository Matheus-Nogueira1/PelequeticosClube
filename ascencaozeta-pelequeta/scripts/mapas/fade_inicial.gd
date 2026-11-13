extends ColorRect

# Revela o mapa de forma gradual ao entrar na cena.
@export var duracao: float = 1.2


func _ready() -> void:
	visible = true
	modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duracao)
	await tween.finished
	visible = false
