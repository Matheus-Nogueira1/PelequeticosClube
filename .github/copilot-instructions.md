# Instruções para mensagens de commit (Copilot / sugestões)

Este arquivo orienta ferramentas (Copilot, assistentes de commit, revisores humanos) a gerar mensagens de commit em Português do Brasil (pt-BR) e seguindo boas práticas.

- Linguagem: Português do Brasil (pt-BR).
- Formato: Conventional Commits (https://www.conventionalcommits.org/pt-br/v1.0.0/).
- Tom: imperativo, curto e objetivo.

Formato recomendado

1. Linha de assunto (subject): curta (máx. 50 caracteres), modo imperativo, minúsculas, sem ponto final.
2. Linha em branco.
3. Corpo (opcional): explique o que e por que (72 caracteres por linha como referência).
4. Rodapé (opcional): referências a issues, breaking changes, closes, etc.

Tipos comuns (exemplos)

- feat: adiciona autenticação por email
- fix: corrige validação do formulário de login
- docs: atualiza README com instruções de deploy
- style: ajustes de formatação (sem alteração de lógica)
- refactor: refatora módulo de autenticação
- perf: melhora performance na listagem de itens
- test: adiciona testes para função X
- chore: tarefas de manutenção (dependências, scripts)

Exemplos de mensagens

- feat: adiciona integração com API de pagamentos
- fix: corrige condição de corrida no cache de sessão
- docs: documenta endpoint /users e exemplos de resposta

Prompt de exemplo para o Copilot / assistente de commit

"Gere uma mensagem de commit em português do Brasil seguindo Conventional Commits para estas mudanças: <descrição das alterações>"

Uso local (opcional)

Você pode adicionar este conteúdo como template de commit localmente se quiser que o editor já sugira o formato ao criar commits:

1. Salve um arquivo local, por exemplo: .git/COMMIT_TEMPLATE
2. Habilite no git:
   git config commit.template .git/COMMIT_TEMPLATE

O que mais eu posso fazer

- Posso adicionar um arquivo de template no repositório (.github/COMMIT_TEMPLATE.md) para referência;
- Posso criar um GitHub Action que valide mensagens de commit;
- Posso gerar hooks de pré-commit/commit-msg (por exemplo, Husky) que forçam o padrão.

Se quiser que eu adicione o template ao repositório ou configure validação automática, me diga qual opção prefere.