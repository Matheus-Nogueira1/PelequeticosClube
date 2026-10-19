class_name ArmaData
extends RefCounted

class Arma extends RefCounted:
	var nome: String = ""
	var dano_dados: int = 0
	var dano_faces: int = 0
	var alcance: String = ""
	var propriedades = []
# Called when the node enters the scene tree for the first time.

static func criar_besta() -> Arma:
	var arma = Arma.new()
	arma.nome = "Besta"
	arma.dano_dados = 1
	arma.dano_faces = 6
	arma.alcance = "Médio"
	arma.propriedades = [
		"RECARGA",
		"TIRO_CERTEIRO"
	]
	return arma

static func criar_boladefogo() -> Arma:
	var arma = Arma.new()
	arma.nome = "BolaDeFogo"
	arma.dano_dados = 1
	arma.dano_faces = 6
	arma.alcance = "Médio"
	arma.propriedades = [
		"RECARGA",
		"TIRO_CERTEIRO"
	]
	return arma

static func criar_tacogigante() -> Arma:
	var arma = Arma.new()
	arma.nome = "TacoGigante"
	arma.dano_dados = 1
	arma.dano_faces = 10
	arma.alcance = "Longo"
	arma.propriedades = [
		"RECARGA",
		"TUDO_QUE_VAI_VOLTA"
	]
	return arma

static func obter_arma(nome_arma: String) -> Arma:
	match nome_arma:
		"Besta":
			return criar_besta()
	match nome_arma:
		"BolaDeFogo":
			return criar_boladefogo()
	match nome_arma:
		"TacoGigante":
			return criar_tacogigante()
	return null

static func rolar_dano_arma(nome_arma: String) -> int:
	var arma = obter_arma(nome_arma)
	if arma == null:
		return 0
	var dano := 0
	for i in range(arma.dano_dados):
		dano += randi_range(1, arma.dano_faces)
	return dano
