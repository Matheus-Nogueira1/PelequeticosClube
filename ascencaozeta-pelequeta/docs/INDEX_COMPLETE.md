# Indice Completo da Documentacao

**Data da revisao:** 13/08/2026  
**Fonte mais recente:** [ESTADO_ATUAL_CODIGO.md](ESTADO_ATUAL_CODIGO.md)

## Documentos de Entrada

| Documento | Uso |
| --- | --- |
| [README.md](README.md) | Porta de entrada da pasta `docs/`. |
| [ESTADO_ATUAL_CODIGO.md](ESTADO_ATUAL_CODIGO.md) | Retrato mais recente do codigo atual. |
| [STATUS_COMBATE.md](STATUS_COMBATE.md) | Checklist de implementado, parcial e pendente. |
| [README_COMBATE.md](README_COMBATE.md) | Indice especifico do sistema de combate. |

## Referencias Tecnicas

| Documento | Uso |
| --- | --- |
| [COMBAT_SYSTEM_README.md](COMBAT_SYSTEM_README.md) | Arquitetura atual dos scripts de combate. |
| [SIGNALS_REFERENCE.md](SIGNALS_REFERENCE.md) | Sinais atuais entre paineis e `CombatManager`. |
| [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) | Guia de implementacao e manutencao. |
| [INTEGRATION_EXAMPLE.md](INTEGRATION_EXAMPLE.md) | Exemplo de integracao. |
| [DEFENSIVE_IMPROVEMENTS.md](DEFENSIVE_IMPROVEMENTS.md) | Padroes defensivos e historico de robustez. |

## Regras e Design

| Documento | Uso |
| --- | --- |
| [ATRIBUTOS_OBLIVIO.md](ATRIBUTOS_OBLIVIO.md) | Atributos fixos, mutaveis e formulas. |
| [OBLIVIO_REFERENCE.md](OBLIVIO_REFERENCE.md) | Referencia de regras Oblivio. |
| [MAPA_VISUAL.md](MAPA_VISUAL.md) | Mapeamento visual do sistema. |

## Historico

| Documento | Uso |
| --- | --- |
| [COMBAT_FIXES_v2.md](COMBAT_FIXES_v2.md) | Historico de correcoes anteriores. |
| [REFACTORING_OBLIVIO.md](REFACTORING_OBLIVIO.md) | Historico da migracao para Estresse por regiao. |
| [SESSAO_16_05_2026.md](SESSAO_16_05_2026.md) | Registro de sessao. |
| [SUMARIO_EXECUTIVO.md](SUMARIO_EXECUTIVO.md) | Sumario historico do projeto. |
| [ENTREGA_FINAL.md](ENTREGA_FINAL.md) | Registro de entrega/documentacao final antiga. |
| [QUICK_START.md](QUICK_START.md) | Guia rapido historico. |

## Scripts Atuais do Combate

| Arquivo | Papel |
| --- | --- |
| `scripts/battle/combat_manager.gd` | Orquestrador central. |
| `scripts/battle/action_panel.gd` | Menu principal, listas e detalhes de acoes. |
| `scripts/battle/regional_selector.gd` | Selecao de regioes/riscos. |
| `scripts/battle/enemy_panel.gd` | Lista e selecao de inimigos. |
| `scripts/battle/party_panel.gd` | Lista de aliados e selecao para itens. |
| `scripts/battle/combat_log.gd` | Historico visual do combate. |
| `scripts/battle/rolagens-dados-d6.gd` | Rolagens D6 de conhecimento e combate. |

## Scripts Atuais de Dados

| Arquivo | Papel |
| --- | --- |
| `scripts/data/combatente_data.gd` | Estrutura central de combatente. |
| `scripts/data/personagens_principais.gd` | Personagens jogaveis de exemplo. |
| `scripts/data/inimigo_data.gd` | Templates de inimigos. |
| `scripts/data/pericia_data.gd` | Banco e testes de pericias. |
| `scripts/data/habilidade_data.gd` | Banco e uso de habilidades. |
| `scripts/data/item_data.gd` | Banco e uso de itens. |
| `scripts/data/arma_data.gd` | Armas e dano. |
| `scripts/data/fardo_data.gd` | Fardos por desmaio/limite de Torso. |
| `scripts/data/protese_data.gd` | Proteses e regras associadas. |

## Estado Atual Resumido

O projeto possui um combate D6 funcional com ataque, selecao de regioes, Estresse por regiao, Duelo, habilidades com PA e item Estus. O sistema ainda esta em desenvolvimento: IA, alcance/fileira, PA unificado, efeitos completos de habilidades e calculo final de pericias ainda precisam ser fechados.

## Nota

Este indice substitui afirmacoes antigas de status absoluto. Documentos historicos foram preservados, mas podem conter informacoes defasadas. Em caso de conflito, use o codigo atual e [ESTADO_ATUAL_CODIGO.md](ESTADO_ATUAL_CODIGO.md).
