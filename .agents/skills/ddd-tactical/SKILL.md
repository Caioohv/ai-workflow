---
name: ddd-tactical
description: >-
  Modela o domínio com os building blocks táticos de DDD (Eric Evans): decide
  Entity vs Value Object, desenha Aggregates e sua fronteira de consistência,
  protege invariantes, define contratos de Repository (por raiz de agregado),
  Domain Events, Domain Services e Factories. Use quando o desenvolvedor for
  criar/refatorar o modelo de negócio, escolher entre Entity e Value Object,
  decidir onde uma invariante vive, definir aggregate roots ou modelar
  referências entre agregados — mesmo sem citar "DDD". Agnóstica de framework e
  linguagem. NÃO cobre em qual camada cada peça vive nem a direção das
  dependências: isso é Clean Architecture (skill irmã). Esta skill decide COMO
  modelar o domínio; a de camadas decide ONDE cada coisa mora. Gatilhos: entity,
  value object, aggregate, aggregate root, invariante, repository de domínio,
  domain event, domain service, factory, modelagem de domínio, ubiquitous
  language.
---

# DDD Tático — modelagem de domínio

Você modela o domínio usando os blocos táticos de Eric Evans. Produza modelos
concretos, não teoria. Aplique os defaults abaixo sem perguntar, a menos que o
domínio contradiga explicitamente.

## Fronteira com a skill irmã (Clean Architecture)

Ambas mencionam `entities` e `repositories`. Não invada a outra:

- **Esta skill (DDD tático)** decide **COMO modelar** o domínio: uma coisa é
  Entity ou Value Object? o que é aggregate root? onde a invariante mora? qual é
  o contrato do repository?
- **Clean Architecture** decide **EM QUAL CAMADA** cada peça vive e a **direção
  das dependências** (domínio não depende de infra, use cases orquestram, etc.).

Quando a pergunta for "onde coloco isso" ou "quem pode depender de quem", pare —
é a outra skill. Aqui só resolvemos a forma do modelo.

## Decisões que esta skill toma por você (defaults)

1. **Value Objects são imutáveis e auto-validados.** Validam no construtor;
   objeto inválido nunca chega a existir. Sem setters.
2. **Invariantes vivem dentro do agregado.** A raiz do agregado é a única porta
   de entrada para mutação; ela garante o estado válido a cada operação.
3. **Referência entre agregados é só por id** (VO de identidade), nunca por
   objeto direto. Um agregado não segura a instância de outro.
4. **Um Repository por raiz de agregado.** Nada de repository para entidade
   interna ou para Value Object.
5. **Igualdade:** Entity compara por id; Value Object compara por valor (todos os
   campos).
6. **Transação = um agregado.** A fronteira do agregado é a fronteira de
   consistência forte; consistência entre agregados é eventual (via Domain
   Events).

Se você aplicou um default, diga qual e por quê em uma linha.

## Entity vs Value Object — como decidir

Faça as perguntas nesta ordem:

- **Tem identidade que persiste mesmo quando os atributos mudam?** Se dois
  objetos com os mesmos atributos ainda são coisas diferentes → **Entity**
  (ex.: `User`, `Order`). Se são intercambiáveis quando os atributos batem →
  **Value Object** (ex.: `Money`, `Email`, `DateRange`).
- **Você se importa com "qual" ou só com "o quê"?** "Qual" → Entity. "O quê" →
  Value Object.
- **O ciclo de vida importa (criado, alterado, removido, rastreado)?** Sim →
  Entity. Não, é descartável/substituível → Value Object.

Na dúvida, prefira **Value Object**: é mais barato, imutável e testável. Promova
a Entity só quando a identidade for realmente necessária.

## Aggregate — regras de desenho

- Escolha a **raiz do agregado** (aggregate root): a única Entity acessível de
  fora. Entidades e VOs internos só são tocados através dela.
- Mantenha o agregado **pequeno**. Se hesitar, quebre em dois agregados ligados
  por id. Agregados grandes viram gargalo de concorrência.
- **Toda invariante que precisa ser verdadeira a cada commit** deve caber dentro
  de um único agregado. Se uma regra cruza dois agregados, ela é consistência
  eventual, não invariante.
- Mutações entram só por **métodos de intenção** na raiz (`order.addItem(...)`),
  nunca expondo coleções ou campos para mutação externa.

## Contrato de um Repository de agregado

Um repository é uma coleção de agregados em memória, do ponto de vista do
domínio. Contrato mínimo e agnóstico:

- `findById(id): Aggregate | null` — reidrata o agregado inteiro.
- `save(aggregate): void` — persiste o agregado inteiro (novo ou alterado).
- `remove(aggregate | id): void` — quando fizer sentido no domínio.
- Consultas de negócio nomeadas na linguagem do domínio
  (`findOpenOrdersFor(customerId)`), não queries genéricas.

Regras: um repository por raiz; nunca retorna entidade interna solta; a
interface é escrita na linguagem do domínio e não vaza detalhe de persistência
(SQL, ORM, tabela). Onde essa interface vive é assunto da Clean Architecture.

## Domain Events

- Nomeie no **passado**, na linguagem ubíqua: `OrderPlaced`, `PaymentReceived`.
- São **imutáveis** e carregam ids + os dados mínimos do fato, mais quando
  ocorreu.
- A raiz do agregado **registra** o evento ao aplicar a mudança; a publicação/
  entrega é infraestrutura (fora daqui).
- Use-os para propagar consistência **entre** agregados.

## Domain Services e Factories

- **Domain Service:** só quando uma operação de negócio é significativa mas não
  pertence naturalmente a nenhuma Entity/VO (ex.: `TransferFunds` entre duas
  contas). Sem estado. Não use como depósito de lógica que deveria estar no
  agregado.
- **Factory:** quando criar um agregado/VO consistente é complexo demais para um
  construtor. Encapsula a montagem e garante que o objeto nasce válido.

## Convenções de nome

- Classes: `PascalCase`, substantivos do domínio (`Customer`, `Money`,
  `OrderLine`).
- Identidade: VO dedicado `OrderId`, `CustomerId` (não `string` cru).
- Métodos da raiz: verbos de intenção do negócio (`confirm`, `cancel`,
  `addItem`), não `set*`/`update*`.
- Eventos: verbo no passado (`InvoiceIssued`).
- Toda a nomenclatura segue a **ubiquitous language** — o mesmo termo do
  negócio, no código.

## Exemplos (TypeScript neutro, sem framework)

### Value Object imutável e auto-validado

```ts
export class Email {
  private constructor(public readonly value: string) {}

  static create(raw: string): Email {
    const v = raw.trim().toLowerCase();
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(v)) {
      throw new Error(`Invalid email: ${raw}`);
    }
    return new Email(v); // inválido nunca existe
  }

  equals(other: Email): boolean {
    return this.value === other.value; // igualdade por valor
  }
}
```

### Value Object de identidade

```ts
export class OrderId {
  private constructor(public readonly value: string) {}
  static of(value: string): OrderId {
    if (!value) throw new Error("OrderId required");
    return new OrderId(value);
  }
  equals(other: OrderId): boolean {
    return this.value === other.value;
  }
}
```

### Entity com identidade + Aggregate protegendo invariante

```ts
export class OrderLine {
  constructor(
    public readonly sku: string,
    public readonly quantity: number,
  ) {
    if (quantity <= 0) throw new Error("quantity must be positive");
  }
}

export class Order {
  private lines: OrderLine[] = [];
  private confirmed = false;
  private readonly events: OrderPlaced[] = [];

  // referência a outro agregado só por id
  constructor(
    public readonly id: OrderId,
    private readonly customerId: CustomerId,
  ) {}

  // mutação só por método de intenção na raiz
  addItem(sku: string, quantity: number): void {
    if (this.confirmed) throw new Error("cannot modify a confirmed order");
    this.lines.push(new OrderLine(sku, quantity));
  }

  confirm(): void {
    // invariante do agregado, garantida a cada operação
    if (this.lines.length === 0) throw new Error("order needs at least one line");
    this.confirmed = true;
    this.events.push(new OrderPlaced(this.id, this.customerId, new Date()));
  }

  pullEvents(): readonly OrderPlaced[] {
    return [...this.events];
  }

  equals(other: Order): boolean {
    return this.id.equals(other.id); // Entity: igualdade por id
  }
}
```

### Domain Event

```ts
export class OrderPlaced {
  constructor(
    public readonly orderId: OrderId,
    public readonly customerId: CustomerId,
    public readonly occurredOn: Date,
  ) {}
}
```

## Estratégico (só nota curta)

Bounded contexts, context mapping e ubiquitous language são **estratégicos** e
ficam fora do foco aqui. Guarde só isto: modele dentro de **um** bounded context
por vez, use os termos do negócio nos nomes (ubiquitous language) e, ao cruzar
contextos, traduza no limite em vez de compartilhar o modelo.

## Fora do escopo

- **Organização em camadas e regra de dependência** (onde domínio/use case/infra
  vivem, quem depende de quem) → Clean Architecture (skill irmã, item 3).
- **Mecânica de framework** (Express, NestJS: controllers, DI, decorators,
  módulos) → skills de backend (itens 7 e 8).
- **Testes** (Jest, como testar o modelo) → skill de testing (item 9).
