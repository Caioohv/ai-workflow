---
name: testing-jest
description: >-
  Escreve e estrutura testes automatizados com Jest (unit e integration) para
  backends TypeScript/JavaScript, decidindo POR CAMADA o que testar e o que
  mockar ou usar fake: domínio (unit puro, sem mocks), use cases (unit mockando
  as portas), repositories/adapters (integration contra a dependência real ou
  double de infra) e controllers/rotas (integration com supertest ou Nest
  Testing module). Use quando o desenvolvedor for escrever, organizar ou
  revisar testes com Jest — nomes de describe/it, estrutura AAA, `jest.fn()`
  vs fakes à mão, o que é unit vs integration, o que dublar em cada camada —
  mesmo sem citar "Jest". COMPÕE com as skills de arquitetura (itens 3 e 4) e
  de backend (itens 7 e 8): elas definem as camadas e a mecânica dos
  frameworks; esta decide como testá-las. NÃO redefine camadas nem mecânica de
  framework. Gatilhos: teste, testar, unit test, integration test, jest,
  supertest, mock, fake, stub, spy, describe/it, cobertura de camada,
  test double.
---

# Testing (Jest) — unit vs integration, o que mockar por camada

Você escreve testes com Jest. Produza testes concretos e acionáveis, não teoria
sobre testar. Aplique os defaults abaixo sem perguntar, a menos que o caso
contradiga explicitamente.

## Fronteira com as skills irmãs (leia primeiro)

Esta skill **compõe** com outras; não invade o gatilho delas:

- **Clean Architecture (item 3)** decide **quais camadas existem** e para onde
  as dependências apontam. Aqui você só assume que elas existem e as testa.
- **DDD tático (item 4)** decide **como o domínio é modelado** (Entity, Value
  Object, Aggregate). Aqui você testa o comportamento desse modelo, não redefine
  o modelo.
- **Backend Express / NestJS (itens 7 e 8)** decidem a **mecânica do framework**
  (como registrar rota, módulo, provider, DI). Aqui você usa supertest ou o Nest
  Testing module para exercitar essa mecânica já pronta.

Se a pergunta for "onde essa peça vive", "como modelo isso" ou "como registro
essa rota/provider", pare — é a outra skill. Aqui só decidimos **como testar**.

## Decisões que esta skill toma por você (defaults)

1. **Fakes à mão para as portas de domínio** (repositórios, gateways). Um fake é
   uma classe pequena que implementa a interface da porta com um `Map` em
   memória. Prefira fake a `jest.mock()` para portas: é reutilizável, tipado e
   não quebra a cada refatoração.
2. **Mock só nas fronteiras.** `jest.fn()` / `jest.spyOn()` para colaboradores de
   borda (relógio, gerador de id, SDK externo, envio de e-mail) ou para verificar
   que um efeito ocorreu. Nunca mocke o objeto que você está testando.
3. **Um assert lógico por teste.** Um `it` verifica um comportamento. Vários
   `expect` que descrevem o mesmo fato são ok; testar dois comportamentos
   distintos no mesmo `it` não é.
4. **Teste comportamento observável, não detalhe de implementação.** Não afirme
   que um método privado foi chamado nem espie internals; afirme o resultado ou o
   efeito visível na fronteira.
5. **Domínio nunca leva mock.** É lógica pura: entra valor, sai valor/erro.
6. **Integration usa o double no nível mais externo possível** (o banco de teste,
   ou um in-memory adapter que fale o mesmo protocolo), não um mock do driver.

Se você aplicou um default, diga qual em uma linha.

## Unit vs integration — a régua

- **Unit:** exercita **uma unidade em isolamento**, substituindo suas
  dependências por doubles. Rápido, sem I/O, sem rede, sem banco. Domínio e use
  cases.
- **Integration:** exercita **duas ou mais peças reais juntas**, incluindo pelo
  menos uma dependência de infra concreta (banco, HTTP, fila) ou um double de
  infra fiel. Repositories/adapters e controllers/rotas.

Regra prática: se o teste toca I/O real ou sobe o app, é integration; se não
toca, é unit.

## O que testar e o que dublar — POR CAMADA

Alinhado com as camadas das skills 3/4 e os backends 7/8.

| Camada | Tipo | O que testar | O que dublar |
|---|---|---|---|
| **Domínio** (entity / value object / aggregate) | unit puro | invariantes, validação no construtor, igualdade, transições de estado, eventos registrados | **nada** — é lógica pura |
| **Use case / business** | unit | a orquestração: chamou a porta certa, aplicou a regra, retornou o output boundary, propagou erro | as **portas** (repositório, gateway) via **fake à mão**; colaboradores de borda (clock, id) via `jest.fn()` |
| **Repository / adapter** | integration | que o adapter realmente lê/grava e mapeia row ↔ modelo corretamente | a dependência **real** (banco de teste) ou um **double de infra** fiel; nada acima do adapter |
| **Controller / rota** (Express / Nest) | integration | contrato HTTP: status, corpo, headers, validação de entrada, caminho de erro | o app sobe de verdade; **use cases** podem ser fakes/mocks para isolar a camada web, ou reais num teste ponta-a-ponta |

Princípio: **quanto mais interno, menos mock**; **quanto mais externo, mais real
a infra**. O domínio não dubla nada; o use case dubla suas portas; o adapter usa
infra real; a rota sobe o app.

## Convenções concretas

- **Localização:** `*.spec.ts` **co-located** ao lado do arquivo testado
  (`order.ts` → `order.spec.ts`). Use `__tests__/` só para suites de integration
  que agrupam vários alvos. Sufixo `*.spec.ts` para unit, `*.e2e-spec.ts` para
  integration de rota (padrão Nest).
- **Estrutura AAA** dentro de cada `it`, separada por linha em branco:
  **Arrange** (monta dados e doubles) → **Act** (uma chamada ao alvo) → **Assert**
  (verifica o resultado/efeito).
- **`describe`** nomeia a unidade sob teste (a classe/função ou a rota):
  `describe("PayOrderUseCase")`, `describe("POST /orders")`.
- **`it`** descreve o comportamento em frase, tempo presente:
  `it("marca o pedido como pago")`, `it("rejeita pedido vazio")`,
  `it("retorna 404 quando o pedido não existe")`. Não use "should".
- **Fakes** ficam em `test/fakes/` (ou co-located se usados por uma suite só),
  nomeados `InMemory*` (`InMemoryOrderRepository`).
- **Setup:** prefira montar o alvo dentro do `beforeEach` para isolar estado
  entre testes. Nunca compartilhe estado mutável entre `it`s.

## `jest.fn()` / `jest.mock()` vs fakes à mão

- **Fake à mão** quando a dependência tem **comportamento** que o teste precisa
  (um repositório que guarda e devolve): implemente a interface com um `Map`.
  Reaproveitável e resistente a refatoração.
- **`jest.fn()`** para um colaborador **sem comportamento**, do qual você só
  precisa de um retorno fixo ou de verificar a chamada (`expect(fn).toHaveBeenCalledWith(...)`).
- **`jest.spyOn(obj, "m")`** para observar/estubar um método de um objeto real
  sem trocá-lo inteiro. Restaure com `jest.restoreAllMocks()` no `afterEach`.
- **`jest.mock("modulo")`** só como último recurso, para cortar um módulo de
  borda inteiro (SDK externo). Evite em favor de injeção de dependência + fake.

## Exemplos curtos

### 1. Value object — unit puro, sem mock

```ts
// email.spec.ts
import { Email } from "./email";

describe("Email", () => {
  it("normaliza e aceita um endereço válido", () => {
    const email = Email.create("  User@Example.com ");

    expect(email.value).toBe("user@example.com");
  });

  it("rejeita um endereço inválido", () => {
    expect(() => Email.create("not-an-email")).toThrow("Invalid email");
  });
});
```

### 2. Use case — unit, mockando a porta de repositório com fake à mão

```ts
// test/fakes/in-memory-order-repository.ts
import { OrderRepository } from "../../use-cases/pay-order/ports/order-repository";
import { Order } from "../../entities/order";

export class InMemoryOrderRepository implements OrderRepository {
  private store = new Map<string, Order>();
  seed(order: Order) { this.store.set(order.id, order); }
  async findById(id: string) { return this.store.get(id) ?? null; }
  async save(order: Order) { this.store.set(order.id, order); }
}
```

```ts
// pay-order.usecase.spec.ts
import { PayOrderUseCase } from "./pay-order.usecase";
import { InMemoryOrderRepository } from "../../test/fakes/in-memory-order-repository";
import { Order } from "../../entities/order";

describe("PayOrderUseCase", () => {
  let orders: InMemoryOrderRepository;
  let useCase: PayOrderUseCase;

  beforeEach(() => {
    orders = new InMemoryOrderRepository();
    useCase = new PayOrderUseCase(orders); // porta injetada = fake
  });

  it("marca o pedido como pago e persiste", async () => {
    orders.seed(new Order("o-1", 2));

    const out = await useCase.execute({ orderId: "o-1" });

    expect(out).toEqual({ orderId: "o-1", paid: true });
    expect((await orders.findById("o-1"))!.isPaid()).toBe(true);
  });

  it("propaga erro quando o pedido não existe", async () => {
    await expect(useCase.execute({ orderId: "x" })).rejects.toThrow("Order not found");
  });
});
```

Note que o teste verifica **orquestração e efeito observável**, não que um método
interno foi chamado.

### 3. Rota — integration com supertest (Express)

```ts
// orders.routes.e2e-spec.ts
import request from "supertest";
import { buildApp } from "../main";

describe("POST /orders", () => {
  const app = buildApp(); // app real; infra pode ser in-memory de teste

  it("cria um pedido e retorna 201", async () => {
    const res = await request(app)
      .post("/orders")
      .send({ items: 2 });

    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ paid: false });
  });

  it("retorna 400 para corpo inválido", async () => {
    const res = await request(app).post("/orders").send({ items: 0 });

    expect(res.status).toBe(400);
  });
});
```

Para NestJS, o equivalente é o **Nest Testing module**
(`Test.createTestingModule({...}).compile()` → `app.getHttpServer()` →
`request(server)`); a montagem do módulo é assunto da skill de Nest (item 8), aqui
você só o exercita.

## Anti-padrões (evite)

- Mockar o próprio objeto sob teste, ou espiar métodos privados.
- Afirmar ordem/quantidade de chamadas internas quando o resultado observável já
  cobre o comportamento.
- Teste de domínio com qualquer mock — sinal de que a lógica não é pura ou está
  na camada errada.
- Um `it` gigante testando vários comportamentos.
- Integration de rota que mocka o banco no nível do driver em vez de usar um
  double de infra fiel ou o banco de teste.
- Snapshot de payload inteiro como muleta para não decidir o que importa.

## Fora do escopo — delegue às skills irmãs

- **Definição das camadas e direção das dependências** (o que é entity, use case,
  adapter; quem depende de quem) → Clean Architecture (item 3).
- **Modelagem do domínio** (Entity vs Value Object, aggregates, invariantes) →
  DDD tático (item 4). Aqui só testamos o modelo pronto.
- **Mecânica dos frameworks** (registrar rota Express, módulo/provider/DI do Nest,
  configurar o app) → skills de backend (itens 7 e 8). Esta skill exercita o que
  elas montam.
- **Convenções de commit/PR** para os testes → skill de commits (item 10).

## Checklist rápido

- [ ] Camada certa, tipo certo: domínio/use case = unit; adapter/rota = integration.
- [ ] Domínio sem nenhum mock.
- [ ] Use case com portas dubladas por fake à mão; borda com `jest.fn()`.
- [ ] Adapter testado contra infra real ou double de infra fiel.
- [ ] Rota exercitada com supertest / Nest Testing module.
- [ ] AAA visível; `describe` = unidade, `it` = comportamento no presente.
- [ ] Um comportamento por `it`; assert de efeito observável, não de implementação.
