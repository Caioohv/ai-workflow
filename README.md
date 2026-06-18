# ai-workflow

Um workflow de desenvolvimento assistido por IA para o Claude Code, focado em eficiência de tokens.

## Como funciona

Agentes especializados cuidam de cada etapa do desenvolvimento. Você descreve o que construir, eles criam specs, implementam e revisam — enquanto as tasks avançam por um pipeline estruturado.

```
todo → in-progress → to-review → done
                          ↓ rejeitada
                    nova task em todo
```

## Setup

Copie para o seu projeto e comece:

```bash
cp -r workflow/ .claude/ CLAUDE.md ~/seu-projeto/
cd ~/seu-projeto
# abra o Claude Code e rode:
/initialize
```

## Agentes

| Agente | Invocação | Descrição |
|--------|-----------|-----------|
| `initialize` | `/initialize` | Entrevista você para definir o projeto → `workflow/definition.md` |
| `spec-creator` | `/spec-creator <brief>` | Cria uma spec de task, pode fazer perguntas |
| `spec-creator-auto` | `/spec-creator-auto <brief>` | Cria uma spec de task sem perguntar nada |
| `implementer` | `/implementer <task>` | Implementa uma task, sem commits |
| `implementer-ci` | `/implementer-ci <task>` | Implementa com Conventional Commits |
| `implementer-auto` | `/implementer-auto` | Roda todas as tasks pendentes sem supervisão |
| `reviewer` | `/reviewer <task>` | Aprova ou rejeita; cria tasks de follow-up na rejeição |

## Fluxo típico

```bash
# 1. Definir o projeto (uma vez)
/initialize

# 2. Criar uma task
/spec-creator adicionar login com email e senha

# 3a. Implementar manualmente
/implementer-ci workflow/tasks/todo/01-add-login.md

# 3b. Ou deixar rodar tudo sozinho
/implementer-auto

# 4. Revisar (se não usar o implementer-auto)
/reviewer workflow/tasks/to-review/01-add-login.md
```
