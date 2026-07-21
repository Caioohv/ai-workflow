# ai-workflow

Um workflow de desenvolvimento assistido por IA para o Claude Code, focado em eficiência de tokens.

## Como funciona

Dois pipelines complementares cobrem diferentes formas de trabalho:

**Pipeline de tasks** — para desenvolvimento estruturado: specs detalhadas, implementação, revisão.

```
todo → in-progress → to-review → done
                          ↓ rejeitada
                    nova task em todo
```

**Pipeline de steps** — para execução ágil a partir de uma lista de tarefas simples.

```
todo.md → steps/todo → steps/in-progress → steps/done (com resumo)
```

## Setup

```bash
./setup.sh ~/seu-projeto
cd ~/seu-projeto
# abra o Claude Code e rode:
/initialize
```

Para atualizar um projeto existente:

```bash
./setup.sh ~/seu-projeto --update
```

## Agentes

### Pipeline de tasks (desenvolvimento estruturado)

| Agente | Invocação | Descrição |
|--------|-----------|-----------|
| `initialize` | `/initialize` | Entrevista você para definir o projeto → `workflow/definition.md` |
| `spec-creator` | `/spec-creator <brief>` | Cria uma spec de task, pode fazer perguntas |
| `spec-creator-auto` | `/spec-creator-auto <brief>` | Cria uma spec de task sem perguntar nada |
| `implementer` | `/implementer <task>` | Implementa uma task, sem commits |
| `implementer-ci` | `/implementer-ci <task>` | Implementa com Conventional Commits |
| `implementer-auto` | `/implementer-auto` | Roda todas as tasks pendentes sem supervisão |
| `reviewer` | `/reviewer <task>` | Aprova ou rejeita; cria tasks de follow-up na rejeição |
| `design-system` | `/design-system` | Define design system (cores, fontes, espaçamentos) → `workflow/design.md` |

### Pipeline de steps (execução de lista de tarefas)

| Agente | Invocação | Descrição |
|--------|-----------|-----------|
| `define-steps` | `/define-steps <todo.md>` | Expande um todo.md em step specs, pode fazer perguntas |
| `define-steps-auto` | `/define-steps-auto <todo.md>` | Expande um todo.md em step specs sem perguntar nada |
| `executor` | `/executor <step>` | Executa um step e registra resumo ao finalizar |
| `executor-auto` | `/executor-auto` | Roda todos os steps pendentes com Conventional Commits |

## Skills

Skills entram em ação automaticamente quando você mexe no código relacionado. São **ortogonais e componíveis**: skills de arquitetura são agnósticas de framework; skills de framework cobrem só a mecânica e delegam a arquitetura às skills de arquitetura (ex.: "Nest + DDD" carrega as duas, sem conflito).

### Arquitetura (agnósticas de framework)

| Skill | Quando aplica |
|-------|---------------|
| `clean-architecture` | Ao decidir em que camada o código vive e para onde as dependências apontam (entities/use cases/adapters, ports & adapters, Dependency Rule) |
| `ddd-tactical` | Ao modelar o domínio — Entity vs Value Object, Aggregates e invariantes, Repository, Domain Events/Services, Factories |

### Backend

| Skill | Quando aplica |
|-------|---------------|
| `express-backend` | Ao estruturar código Express — routers, ordem de middlewares, controllers finos, logger com request-id |
| `nestjs-backend` | Ao escrever código NestJS — módulos, providers, DI, pipes/guards/interceptors/filters, logging |
| `api-responses` | Ao escrever respostas de endpoints (JS/Node) — retornos human-friendly, sem vazar internals (stack trace, erro de banco, paths, segredos) |

### Frontend

| Skill | Quando aplica |
|-------|---------------|
| `frontend-components` | Ao criar ou alterar UI — reaproveitamento de componentes e adesão aos tokens de `workflow/design.md` (nada hardcoded) |
| `vue-atomic-design` | Ao compor componentes Vue 3 (SFC, `<script setup>`) com Atomic Design |
| `react-atomic-design` | Ao compor componentes React (`.jsx`/`.tsx`) com Atomic Design |
| `nuxt-4-dev` | Ao escrever Nuxt 4 — data fetching, SSR, server routes (Nitro), hidratação |

### Testes, segurança e convenções

| Skill | Quando aplica |
|-------|---------------|
| `testing-jest` | Ao escrever testes com Jest — o que testar e o que mockar por camada (domínio, use case, repo, controller) |
| `security-audit-node` | Ao auditar segurança de código Node/Express/Nest — relatório de findings (OWASP); não escreve código |
| `commit-pr-conventions` | Ao escrever mensagem de commit ou título/descrição de PR — Conventional Commits + template de PR |
| `content-writer-ptbr` | Ao redigir conteúdo textual em PT-BR (títulos, copy, microcopy) — regras duras de estilo |

> Defina o design system com `/design-system` antes de construir o front — o skill
> `frontend-components` lê `workflow/design.md` como fonte única de verdade.

## Fluxo típico

### Pipeline de tasks

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

### Pipeline de steps

```bash
# 1. Expandir uma lista de tarefas em steps
/define-steps-auto examples/todo.md

# 2a. Executar um step manualmente
/executor workflow/steps/todo/01-init-project.md

# 2b. Ou executar tudo de uma vez (com commits)
/executor-auto
```
