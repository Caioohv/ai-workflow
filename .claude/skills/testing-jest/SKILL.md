---
name: testing-jest
description: >-
  Escreve e organiza testes Jest (unit e integration) para backends TS/JS,
  decidindo por camada o que testar e o que dublar: domínio, use cases,
  repositories e controllers (supertest, Nest Testing). Gatilhos: teste, jest,
  mock, fake, supertest, describe/it.
---

Você escreve testes Jest concretos. Camadas vêm da `clean-architecture`, o modelo da `ddd-tactical`, a montagem do app das skills de backend; aqui só se decide **como testar**.

## Defaults (aplique sem perguntar; se aplicar um, diga qual em uma linha)

1. **Fake à mão para portas** (repositórios, gateways): classe `InMemory*` que implementa a interface com um `Map`. Preferir a `jest.mock()`: tipado, reutilizável, não quebra em refatoração.
2. **Mock só na borda:** `jest.fn()`/`jest.spyOn()` para relógio, gerador de id, SDK externo, e-mail, ou para verificar que um efeito ocorreu. `jest.mock('modulo')` só em último caso. Nunca mocke o alvo do teste.
3. **Domínio nunca leva mock.** Entra valor, sai valor ou erro.
4. **Teste comportamento observável**, não detalhe interno (nada de espiar método privado ou contar chamadas que o resultado já cobre).
5. **Um comportamento por `it`.**
6. **Integration usa infra real** (banco de teste) ou double de infra fiel, nunca mock do driver.

Régua: toca I/O real ou sobe o app → integration; senão → unit.

## Por camada

| Camada | Tipo | Testar | Dublar |
|---|---|---|---|
| Domínio (entity, VO, aggregate) | unit | invariantes, validação, igualdade, transições, eventos | nada |
| Use case | unit | orquestração, regra aplicada, output, erro propagado | portas via fake; borda via `jest.fn()` |
| Repository / adapter | integration | leitura/gravação e mapeamento row ⇄ modelo | banco de teste real |
| Controller / rota | integration | status, corpo, headers, validação, caminho de erro | app sobe de verdade (supertest ou `Test.createTestingModule`); use cases podem ser fakes |

## Convenções

- `*.spec.ts` ao lado do arquivo testado; `*.e2e-spec.ts` para rotas; `__tests__/` só para suites que agrupam vários alvos. Fakes em `test/fakes/`.
- AAA visível (Arrange, Act, Assert separados por linha em branco).
- `describe` = unidade (`"PayOrderUseCase"`, `"POST /orders"`); `it` = comportamento no presente, sem "should" (`"rejeita pedido vazio"`).
- Monte o alvo no `beforeEach`; nenhum estado mutável compartilhado entre `it`s; `jest.restoreAllMocks()` no `afterEach` quando usar spies.
- Sem snapshot de payload inteiro como substituto de decidir o que importa.

## Exemplo

```ts
// test/fakes/in-memory-order-repository.ts
export class InMemoryOrderRepository implements OrderRepository {
  private store = new Map<string, Order>()
  seed(o: Order) { this.store.set(o.id, o) }
  async findById(id: string) { return this.store.get(id) ?? null }
  async save(o: Order) { this.store.set(o.id, o) }
}

// pay-order.usecase.spec.ts
describe('PayOrderUseCase', () => {
  let orders: InMemoryOrderRepository
  let useCase: PayOrderUseCase
  beforeEach(() => {
    orders = new InMemoryOrderRepository()
    useCase = new PayOrderUseCase(orders)
  })

  it('marca o pedido como pago e persiste', async () => {
    orders.seed(new Order('o-1', 2))

    const out = await useCase.execute({ orderId: 'o-1' })

    expect(out).toEqual({ orderId: 'o-1', paid: true })
    expect((await orders.findById('o-1'))!.isPaid()).toBe(true)
  })

  it('propaga erro quando o pedido não existe', async () => {
    await expect(useCase.execute({ orderId: 'x' })).rejects.toThrow(OrderNotFoundError)
  })
})

// orders.e2e-spec.ts
describe('POST /orders', () => {
  const app = buildApp()
  it('retorna 400 para corpo inválido', async () => {
    const res = await request(app).post('/orders').send({ items: 0 })
    expect(res.status).toBe(400)
  })
})
```

## Checklist

- [ ] Tipo certo por camada: domínio/use case = unit; adapter/rota = integration.
- [ ] Domínio sem mock; portas com fake; borda com `jest.fn()`.
- [ ] Adapter contra banco de teste; rota com supertest/Nest Testing.
- [ ] AAA, `describe`/`it` no padrão, um comportamento por `it`.
- [ ] Asserts sobre efeito observável.

## Fora do escopo

- Camadas → `clean-architecture`; modelo de domínio → `ddd-tactical`.
- Montagem de rotas, módulos e DI → `express-backend` / `nestjs-backend`.
- Casos de teste de segurança obrigatórios → `secure-coding`.
