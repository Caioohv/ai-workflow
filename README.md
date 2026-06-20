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
| `design-system` | `/design-system` | Entrevista você para definir um design system (cores, fontes, espaçamentos) → `workflow/design.md` |

## Skills

Skills entram em ação automaticamente quando você mexe no código relacionado:

| Skill | Quando aplica | O que faz |
|-------|---------------|-----------|
| `frontend-components` | Ao criar ou alterar UI/front | Prioriza componentes reaproveitáveis e segue os tokens de `workflow/design.md` — nada de cor/fonte/espaçamento hardcoded |
| `api-responses` | Ao escrever respostas de endpoints (JS/Node) | Retornos human-friendly com formato consistente, sem vazar internals (stack trace, erro de banco, paths, segredos) |

> Defina o design system com `/design-system` antes de construir o front — o skill
> `frontend-components` lê `workflow/design.md` como fonte única de verdade.

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
