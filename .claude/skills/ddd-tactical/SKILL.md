---
name: ddd-tactical
description: >-
  Modelagem tática de domínio (DDD): Entity vs Value Object, Aggregates e
  fronteira de consistência, invariantes, contrato de Repository por raiz,
  Domain Events, Domain Services e Factories. Use ao criar ou refatorar o modelo
  de negócio, mesmo sem citar DDD.
---

Você modela o domínio com os blocos táticos de DDD. Produza modelo concreto, não teoria. **Onde** cada peça mora e quem depende de quem é da `clean-architecture`; aqui só se decide **como** modelar.

## Defaults (aplique sem perguntar; se aplicar um, diga qual em uma linha)

1. **Value Objects são imutáveis e auto-validados:** validam na criação, sem setters; objeto inválido nunca existe.
2. **Invariantes vivem no agregado.** A raiz é a única porta de mutação e garante estado válido a cada operação.
3. **Referência entre agregados só por id** (VO de identidade como `OrderId`, não `string` cru).
4. **Um Repository por raiz de agregado**, nunca para entidade interna ou VO.
5. **Igualdade:** Entity por id; VO por valor.
6. **Transação = um agregado.** Entre agregados a consistência é eventual, via Domain Events.

## Decisões rápidas

- **Entity ou VO?** Tem identidade que persiste quando os atributos mudam, ou ciclo de vida rastreado → Entity. Intercambiável quando os valores batem → VO. Na dúvida, VO.
- **Agregado pequeno.** Regra que precisa valer a cada commit cabe num agregado só; se cruza dois, é consistência eventual. Na dúvida, quebre em dois ligados por id.
- **Mutação só por métodos de intenção** na raiz (`order.addItem()`, `confirm()`, `cancel()`), nunca `set*` nem coleção exposta.
- **Repository** fala a língua do domínio: `findById`, `save` (agregado inteiro), `remove` se fizer sentido, consultas nomeadas (`findOpenOrdersFor(customerId)`). Não vaza SQL/ORM.
- **Domain Event:** nome no passado (`OrderPlaced`), imutável, ids + dados mínimos + `occurredOn`. A raiz registra; publicar é infraestrutura.
- **Domain Service** só para operação de negócio que não pertence a nenhuma Entity/VO (ex.: `TransferFunds`); sem estado.
- **Factory** quando montar um agregado válido é complexo demais para o construtor.
- Nomes seguem a ubiquitous language; um bounded context por vez; traduza no limite ao cruzar contextos.

## Exemplo

```ts
export class Email {
  private constructor(readonly value: string) {}
  static create(raw: string): Email {
    const v = raw.trim().toLowerCase()
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(v)) throw new InvalidEmailError(raw)
    return new Email(v)
  }
  equals(o: Email) { return this.value === o.value }
}

export class Order {                       // aggregate root
  private lines: OrderLine[] = []
  private confirmed = false
  private events: DomainEvent[] = []
  constructor(readonly id: OrderId, private readonly customerId: CustomerId) {}

  addItem(sku: string, qty: number) {
    if (this.confirmed) throw new OrderAlreadyConfirmedError(this.id)
    this.lines.push(new OrderLine(sku, qty))   // OrderLine valida qty > 0
  }
  confirm() {
    if (this.lines.length === 0) throw new EmptyOrderError(this.id)  // invariante
    this.confirmed = true
    this.events.push(new OrderPlaced(this.id, this.customerId, new Date()))
  }
  pullEvents() { const e = this.events; this.events = []; return e }
}
```

## Checklist

- [ ] Cada conceito classificado como Entity ou VO com justificativa.
- [ ] VOs imutáveis e validados na criação.
- [ ] Invariantes dentro da raiz; mutação só por métodos de intenção.
- [ ] Agregados se referenciam só por id; um repository por raiz.
- [ ] Eventos no passado, imutáveis, registrados pela raiz.

## Fora do escopo

- Camadas e direção das dependências → `clean-architecture`.
- Persistência (schema, mapper, transações) → `database-persistence`.
- Mecânica de framework → `express-backend` / `nestjs-backend`.
- Testes → `testing-jest`.
