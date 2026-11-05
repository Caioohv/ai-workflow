# ai-workflow

Um workflow de desenvolvimento assistido por IA compatível com **Codex**, **Claude Code** e **Google Antigravity (Gemini)**, focado em eficiência de tokens.

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
descrição → todo.md → steps/todo → steps/in-progress → steps/done (com resumo)
```

**Tarefas manuais (`workflow/manual-tasks/`)** — sempre que houver alguma ação que precise ser realizada pelo usuário (ex.: acessar servidor, configurar banco de dados, obter/configurar credenciais e chaves externas), os agentes criam um arquivo `.md` em `workflow/manual-tasks/` com orientações passo a passo claras para o usuário.

**Decisões (`workflow/decisions/`)** — decisões técnicas significativas e difíceis de reverter (banco, ORM, estratégia de auth, estilo de API) viram ADRs curtos a partir de `workflow/templates/adr.md`. Os agentes leem os ADRs relevantes antes de especificar, implementar ou revisar, e o reviewer rejeita mudanças que violem um ADR aceito sem outro que o substitua.

## Setup

```bash
./setup.sh ~/seu-projeto
cd ~/seu-projeto
```

Abra o seu assistente preferido na pasta do projeto e inicialize:

* **No Codex:**
  ```text
  $discover
  ```
* **No Claude Code:**
  ```bash
  /discover
  ```
* **No Antigravity (Gemini):**
  ```bash
  /discover
  ```

Para atualizar um projeto existente:

```bash
./setup.sh ~/seu-projeto --update
```

O setup instala os três harnesses. A atualização também adiciona suporte ao Codex
em projetos que já usam Claude Code ou Antigravity. O conteúdo de `workflow/`
é preservado, exceto os templates, que são atualizados junto com agentes, skills
e regras do framework.

O instalador mantém as instruções locais de `AGENTS.md` e atualiza apenas o bloco
entre `<!-- ai-workflow:begin -->` e `<!-- ai-workflow:end -->`. Coloque suas regras
do projeto fora desse bloco. Esses marcadores são reservados ao setup.

## Usando com Codex

O Codex carrega as instruções de `AGENTS.md` e descobre as skills em
`.agents/skills/`, compartilhadas com o Antigravity. O setup mantém as configurações
do Claude em `.claude/`.

No Codex, invoque as skills com `$nome-da-skill` ou peça pelo nome em linguagem
natural. No CLI e na extensão IDE, `/skills` permite consultar as skills disponíveis.
Os exemplos com `/nome` nas outras seções são para Claude Code e Antigravity.
Use `$nome` para executar a mesma etapa no Codex.

```text
$discover
$spec-creator adicionar login com email e senha
$implementer-ci workflow/tasks/todo/01-add-login.md
$reviewer workflow/tasks/to-review/01-add-login.md
```

Para o pipeline de steps:

```text
$todo-planner criar um app nuxt
$define-steps-auto workflow/todos/01-criar-app-nuxt-todo.md
$executor-auto
```

`$implementer-auto` processa a fila de tasks com revisão após cada implementação.
Os orquestradores usam subagentes quando a sessão oferece essa capacidade e
entregam a cada worker o caminho da skill e os arquivos de contexto. Quando a
delegação está indisponível, executam as etapas na sessão atual e informam que a
revisão ocorreu nessa mesma sessão. Itens bloqueados são registrados e os demais
itens elegíveis continuam. As permissões da sessão continuam valendo nas rotinas
automáticas.

Você pode alternar entre harnesses: todos usam os mesmos arquivos e status em
`workflow/`. Após instalar ou atualizar, reabra a sessão se as skills não aparecerem.

Referências: [instruções com AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md),
[skills do Codex](https://learn.chatgpt.com/docs/build-skills) e
[subagentes](https://learn.chatgpt.com/docs/agent-configuration/subagents).

## Agentes

Não sabe por onde começar ou qual é o próximo passo? Use o `orchestrator`
(`/orchestrator` no Claude Code e no Antigravity, `$orchestrator` no Codex). Ele lê
o estado de `workflow/`, resume como o workflow funciona, indica o próximo comando
e lista as alternativas. É somente leitura: orienta, mas não executa outros agentes.

### Pipeline de tasks (desenvolvimento estruturado)

| Agente | Invocação | Descrição |
|--------|-----------|-----------|
| `orchestrator` | `/orchestrator [pergunta]` | Orienta: indica o próximo passo, as possibilidades e resume o workflow |
| `discover` | `/discover` | Entrevista você para definir o projeto → `workflow/definition.md` |
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
| `todo-planner` | `/todo-planner <descrição>` | Transforma uma descrição livre em um `todo.md` de passos pequenos, executáveis e verificáveis (alimenta o `define-steps`) |
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
| `api-design` | Ao desenhar o contrato de uma API HTTP — URLs, métodos, status codes, paginação/filtros, versionamento, idempotência, OpenAPI |
| `database-persistence` | Ao mexer na persistência — schema, índices, migrations (expand → contract), repositories com ORM, transações, N+1 |
| `env-config` | Ao adicionar ou ler variáveis de ambiente — módulo de config tipado e validado no boot, `.env.example`, públicas vs server-only |

### Frontend

| Skill | Quando aplica |
|-------|---------------|
| `frontend-components` | Ao criar ou alterar UI — reaproveitamento de componentes e adesão aos tokens de `workflow/design.md` (nada hardcoded) |
| `vue-atomic-design` | Ao compor componentes Vue 3 (SFC, `<script setup>`) com Atomic Design |
| `react-atomic-design` | Ao compor componentes React (`.jsx`/`.tsx`) com Atomic Design |
| `nuxt-4-dev` | Ao escrever Nuxt 4 — data fetching, SSR, server routes (Nitro), hidratação |
| `state-management` | Ao decidir onde vive o estado do front — local, URL, cache do servidor ou store; Pinia/Zustand, TanStack Query |

### Testes, segurança, infra e convenções

| Skill | Quando aplica |
|-------|---------------|
| `testing-jest` | Ao escrever testes com Jest — o que testar e o que mockar por camada (domínio, use case, repo, controller) |
| `secure-coding` | Ao escrever, endurecer ou auditar código sensível (auth, crypto, queries, uploads, segredos) — seguro por padrão com checklist OWASP/CWE; no modo auditoria só gera relatório |
| `performance` | Ao otimizar — Web Vitals, bundle, custo de renderização, event loop, cache; sempre medindo antes e depois |
| `docker-ci` | Ao escrever Dockerfile, docker-compose de dependências de dev e pipelines de CI (GitHub Actions) |
| `adr-decisions` | Ao tomar uma decisão técnica significativa — registra um ADR em `workflow/decisions/` e respeita os já aceitos |
| `commit-pr-conventions` | Ao escrever mensagem de commit ou título/descrição de PR — Conventional Commits + template de PR |
| `content-writer-ptbr` | Ao redigir conteúdo textual em PT-BR (títulos, copy, microcopy) — regras duras de estilo |

> Defina o design system com `/design-system` antes de construir o front — o skill
> `frontend-components` lê `workflow/design.md` como fonte única de verdade.

### Economia de tokens

A descrição de cada skill fica no contexto o tempo todo, inclusive em cada subagente. O corpo só carrega quando a skill dispara. Por isso:

- descrições curtas (até 350 caracteres), só com o que a skill faz e os gatilhos; as fronteiras com outras skills ficam na seção "Out of scope" do corpo;
- o corpo traz regras, escolhas padrão do projeto e checklist, não teoria que o modelo já conhece;
- `CLAUDE.md`, `GEMINI.md` e `.agents/rules/rules.md` são curtos e não repetem as tabelas deste README;
- `.claude/skills/` e `.agents/skills/` têm conteúdo idêntico.

Os testes em `tests/test_skills.py` garantem essas regras.

## Fluxo típico

### Pipeline de tasks

```bash
# 1. Definir o projeto (uma vez)
/discover

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
# 1. Gerar um todo.md a partir de uma descrição
/todo-planner criar um app nuxt

# 2. Expandir a lista de tarefas em steps
/define-steps-auto workflow/todos/01-criar-app-nuxt-todo.md

# 3a. Executar um step manualmente
/executor workflow/steps/todo/01-init-project.md

# 3b. Ou executar tudo de uma vez (com commits)
/executor-auto
```

## Verificar o instalador

Os testes usam projetos temporários e exigem Python 3 e Git:

```bash
bash -n setup.sh
python3 -B -m unittest discover -s tests -v
```
