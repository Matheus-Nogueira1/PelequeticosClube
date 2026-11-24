
extends Node

const VOLUME_PADRAO: float = -6.0
const VOLUME_SILENCIO: float = -80.0
const DURACAO_TRANSICAO: float = 3.5

const MUSICA_MENU: AudioStream = preload(
	"res://music/CINEMATICS/ClementPanchout_Shadows-MENUzETicoTRISTETICO.wav"
	
)

const MUSICA_CICLO: AudioStream = preload(
	"res://music/CINEMATICS/ClementPanchout_2024_A-look-at-what-has-been-lost-CICLO.wav"
	
)

const MUSICA_ELIZABETH: AudioStream = preload(
	"res://music/Let's Adventure oggs sonatina.itch.io/sonatina_letsadventure_10Well-knownToMyHeart-VIBE-ELIZABETH.ogg"
)

const MUSICA_BAU: AudioStream = preload(
	"res://music/ACTION/Clement Panchout_ Kick Me Harder_ 2001-BAU.wav"
)

var music_player: AudioStreamPlayer
var music_tween: Tween
var solicitacao_atual: int = 0


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	music_player.volume_db = VOLUME_SILENCIO

	add_child(music_player)


func tocar_musica(nome: StringName) -> void:
	var faixa: AudioStream

	match nome:
		&"ciclo":
			faixa = MUSICA_CICLO
		&"elizabeth":
			faixa = MUSICA_ELIZABETH
		&"bau":
			faixa = MUSICA_BAU
		_:
			push_warning("[AudioManager] Música desconhecida: " + String(nome))
			return

	solicitacao_atual += 1
	var solicitacao := solicitacao_atual

	_cancelar_tween()

	# Se a faixa já estiver tocando, apenas garante o volume.
	if music_player.playing and music_player.stream == faixa:
		_animar_volume(VOLUME_PADRAO, DURACAO_TRANSICAO)
		return

	# Se houver outra música, termina com fade-out antes da próxima.
	if music_player.playing:
		music_tween = create_tween()
		music_tween.set_trans(Tween.TRANS_SINE)
		music_tween.set_ease(Tween.EASE_IN_OUT)

		music_tween.tween_property(
			music_player,
			"volume_db",
			VOLUME_SILENCIO,
			DURACAO_TRANSICAO
		)

		music_tween.tween_callback(func() -> void:
			if solicitacao != solicitacao_atual:
				return

			music_player.stop()
			music_tween = null
			_iniciar_faixa(faixa, solicitacao)
		)
	else:
		_iniciar_faixa(faixa, solicitacao)


func _iniciar_faixa(
	faixa: AudioStream,
	solicitacao: int
) -> void:
	if solicitacao != solicitacao_atual:
		return

	# Configura a repetição contínua da música.
	if faixa is AudioStreamWAV:
		(faixa as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif faixa is AudioStreamOggVorbis:
		(faixa as AudioStreamOggVorbis).loop = true

	music_player.stream = faixa
	music_player.volume_db = VOLUME_SILENCIO
	music_player.play()

	_animar_volume(VOLUME_PADRAO, DURACAO_TRANSICAO)


func _animar_volume(volume_db: float, duracao: float) -> void:
	_cancelar_tween()

	if duracao <= 0.0:
		music_player.volume_db = volume_db
		return

	music_tween = create_tween()
	music_tween.set_trans(Tween.TRANS_SINE)
	music_tween.set_ease(Tween.EASE_IN_OUT)

	music_tween.tween_property(
		music_player,
		"volume_db",
		volume_db,
		duracao
	)


func fade_in(duracao: float = DURACAO_TRANSICAO) -> void:
	if music_player.stream == null:
		return

	if not music_player.playing:
		music_player.volume_db = VOLUME_SILENCIO
		music_player.play()

	_animar_volume(VOLUME_PADRAO, duracao)


func fade_out(duracao: float = DURACAO_TRANSICAO) -> void:
	solicitacao_atual += 1
	var solicitacao := solicitacao_atual

	_cancelar_tween()

	if not music_player.playing:
		return

	if duracao <= 0.0:
		music_player.stop()
		music_player.volume_db = VOLUME_SILENCIO
		return

	music_tween = create_tween()
	music_tween.set_trans(Tween.TRANS_SINE)
	music_tween.set_ease(Tween.EASE_IN_OUT)

	music_tween.tween_property(
		music_player,
		"volume_db",
		VOLUME_SILENCIO,
		duracao
	)

	music_tween.tween_callback(func() -> void:
		if solicitacao != solicitacao_atual:
			return

		music_player.stop()
		music_player.volume_db = VOLUME_SILENCIO
		music_tween = null
	)


func _cancelar_tween() -> void:
	if music_tween != null and music_tween.is_running():
		music_tween.kill()

	music_tween = null
