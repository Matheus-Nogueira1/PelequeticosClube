# Desenvolvimento

Esta seção apresenta o desenvolvimento do projeto **Ascenção dos Pelecos**, reunindo as funcionalidades implementadas durante o processo de criação do jogo e a organização das versões no GitHub.

## Organização do Desenvolvimento

Durante o desenvolvimento, as funcionalidades foram sendo criadas e atualizadas de forma gradual. Para manter o projeto organizado e facilitar o acompanhamento da evolução, cada etapa foi separada em uma pasta específica no GitHub.

Atualmente, o desenvolvimento está organizado nas seguintes partes:

```text
Desenvolvimento/
│
├── Tela-De-Menu/
│   └── README.md
│
├── Tela-De-Combate/
│   └── README.md
│
├── Rolagem-Dados/
│   └── README.md
│
└── Movimento-Do-Personagem/
    └── README.md
```

Cada pasta representa uma etapa do desenvolvimento e possui seu próprio `README.md`, explicando brevemente o conteúdo daquela versão.

## Tela de Menu

A **Tela de Menu** representa uma das primeiras etapas desenvolvidas no projeto.

Nessa etapa foi criada a interface inicial do jogo, responsável por apresentar ao jogador as opções disponíveis antes de iniciar a partida.

A versão do menu também serve como base para as funcionalidades que foram adicionadas posteriormente.

## Tela de Combate

Após a criação da estrutura inicial, foi desenvolvido o sistema relacionado à **Tela de Combate**.

Essa etapa teve como objetivo criar a interface utilizada durante os confrontos do jogo, preparando a estrutura necessária para posteriormente adicionar as mecânicas de combate e interação com o jogador.

## Rolagem de Dados

Em seguida, foi desenvolvido o sistema de **Rolagem de Dados**, uma das mecânicas importantes do RPG.

O sistema foi criado para gerar resultados aleatórios que poderão ser utilizados nas ações do personagem, principalmente durante situações de combate e testes baseados nas regras do RPG.

Essa funcionalidade foi organizada separadamente no GitHub para facilitar sua manutenção e evolução.

## Movimento do Personagem

Também foi desenvolvido o **Movimento do Personagem**, permitindo que o jogador controle o personagem durante a exploração do cenário.

Essa etapa adicionou a possibilidade de movimentação dentro do ambiente do jogo e serviu como base para a interação do jogador com o mapa.

## Controle das Versões

Para facilitar o acompanhamento do projeto, as diferentes etapas foram separadas no GitHub.

Dessa maneira, é possível consultar versões anteriores do desenvolvimento sem misturar os arquivos das diferentes funcionalidades.

A organização permite visualizar a evolução do projeto desde as primeiras implementações até as funcionalidades mais recentes.

### Estrutura das versões

```text
Tela-De-Menu
      ↓
Tela-De-Combate
      ↓
Rolagem-Dados
      ↓
Movimento-Do-Personagem
```

Essa estrutura representa a ordem de desenvolvimento das principais funcionalidades documentadas até o momento.

## Organização no GitHub

O GitHub foi utilizado como ferramenta para armazenar o código-fonte e organizar as diferentes etapas do desenvolvimento.

Cada funcionalidade possui uma pasta própria, permitindo que os arquivos relacionados permaneçam separados e organizados.

Além disso, os arquivos `README.md` presentes em cada pasta servem para identificar e explicar brevemente o conteúdo de cada etapa.

Essa organização facilita:

* O acompanhamento da evolução do projeto;
* A consulta de versões anteriores;
* A identificação de cada funcionalidade;
* A manutenção dos arquivos;
* O trabalho em equipe;
* O registro do desenvolvimento do jogo.

## Tecnologias Utilizadas

O desenvolvimento do jogo está sendo realizado utilizando:

* **Godot Engine**
* **GDScript**
* **GitHub** para controle e organização do projeto

## Considerações

O desenvolvimento do **Ascenção dos Pelecos** ocorre de forma incremental. Novas funcionalidades serão adicionadas conforme o projeto evoluir.

A estrutura atual do GitHub foi criada para manter o projeto organizado e permitir que cada etapa do desenvolvimento possa ser consultada separadamente.

As pastas e seus respectivos `README.md` poderão ser atualizados conforme novas versões e funcionalidades forem desenvolvidas.
