Contexto: quero gerar um conjunto de skills para o Claude Code.
As skills devem ser ORTOGONAIS e componíveis: skills de ARQUITETURA são
agnósticas de framework; skills de FRAMEWORK cobrem só a mecânica do framework
e delegam a arquitetura às skills de arquitetura. Isso evita que duas skills
disputem o mesmo gatilho e deem orientação conflitante (ex: "Nest + DDD"
carrega as duas skills, em vez de uma skill monolítica "Nest com DDD").

NÃO gere os projetos nem execute código de aplicação. Crie apenas os arquivos
SKILL.md.

Para cada item da lista, use um subagente com contexto limpo. Passe para CADA
subagente a LISTA COMPLETA abaixo, para que ele escreva uma `description` cujo
gatilho não se sobreponha às irmãs.

Instrução para o subagente:
---
Crie a definição de uma skill (SKILL.md) para: [ITEM].
Use pensamento estendido para primeiro decidir o que torna essa skill eficaz,
antes de escrever.

Conteúdo:
- Baseie-se na documentação oficial / livro de referência quando houver, e em
  boas práticas consolidadas.
- Não escreva um ensaio genérico de boas práticas. Produza convenções
  CONCRETAS: estrutura de pastas, convenções de nome, contratos/interfaces e
  ao menos um exemplo de código curto por padrão principal.
- Deixe explícito o que a skill DECIDE pelo desenvolvedor (os defaults), não só
  o que ela permite.
- Liste o que está FORA do escopo (o que pertence a uma skill irmã).

Formato:
- Frontmatter com `name` (slug) e `description` em terceira pessoa, contendo os
  termos de gatilho e QUANDO usar. A description deve diferenciar esta skill das
  irmãs listadas.
- Corpo: instruções acionáveis, não teoria.

Skills irmãs (não sobreponha o gatilho): [LISTA COMPLETA]
---

Ao final, revise as descriptions de todas as skills juntas e ajuste qualquer
gatilho que ainda se sobreponha.

LISTA:

1. Frontend Vue. Composição Atomic Design: átomos (texto, botão, título) formam
   moléculas (formulários, cards) que formam organismos/sections (hero, about,
   cta). Dados via props; design tokens em CSS (root para cores/fontes, tokens
   de spacing/sizing para tamanhos e espaços). Escopo: composição e tokens.
   Fora: estética visual, arquitetura de estado global.

2. Frontend React. Mesmo padrão do item 1 (Atomic Design + design tokens via
   CSS variables), adaptado às convenções de React (composição via
   props/children).

3. Clean Architecture (agnóstica de framework). Separação de responsabilidades e
   regra de dependência apontando pra dentro, seguindo "Clean Architecture:
   A Craftsman's Guide to Software Structure and Design" (Robert C. Martin):
   camadas, fronteiras, inversão de dependência, use cases. Fora: mecânica de
   qualquer framework específico.

4. DDD tático (agnóstico de framework). Entities, value objects, aggregates,
   repositories, domain events, seguindo "Domain-Driven Design" (Eric Evans).
   Foco nos building blocks táticos e na modelagem do domínio. Estratégia
   (bounded contexts, context mapping, ubiquitous language) entra apenas como
   nota, não como foco.

5. Verificador de segurança (auditoria, stack Node/Nest). OWASP Top 10 (2021),
   tratamento e exposição de erros, vazamento de dados sensíveis, erros de
   configuração do projeto. Modo review, não geração de código.

6. Escritor de conteúdo (PT-BR). Textos de páginas: títulos, subtítulos,
   parágrafos, CTAs. Proíbe travessão, emojis e padrões clássicos de IA
   (Não é sobre x é sobre y / tricolon / paralelismo excessivo / Não apenas...
   mas também / Além disso / Vale ressaltar / conclusões tipo Em resumo /
   hedging excessivo). Gatilho restrito a redação; não dispara em contexto de
   código, mas dispara quando criar arquivos de conteúdo.

7. Backend Express (mecânica do framework). Estrutura de projeto, organização de
   rotas/middlewares/controllers/business/repositories, setup de logger (pino ou winston) e logs estratégicos para diagnóstico e monitoramento. A arquitetura das camadas vem das skills 3 e 4. Gatilho: projeto que usa Express.

8. Backend NestJS (mecânica do framework). Módulos, providers, DI, estrutura
   recomendada pela documentação oficial, setup de logger e logs estratégicos.
   Arquitetura das camadas vem das skills 3 e 4. Gatilho: projeto que usa Nest.

9. Testing (Jest). Unit vs integration, o que mockar ou usar fake por camada,
   o que testar em cada camada, estrutura dos testes. Compõe com 3, 4, 7, 8.

10. Convenções de commit/PR. Conventional commits e formato de descrição de PR.
    Casa com o agente de review de PR que você já construiu.