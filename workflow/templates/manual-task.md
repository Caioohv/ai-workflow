# NN — [Ação no imperativo, ex.: "Criar o usuário do banco na VPS"]

**Status:** `pending` | `done`
**Criada em:** YYYY-MM-DD
**Desbloqueia:** [`workflow/steps/todo/NN-slug.md` ou `workflow/tasks/...`]
**Onde:** [ex.: VPS via SSH (`deploy@<VPS_HOST>`) · terminal local na raiz do projeto · painel https://...]
**Tempo estimado:** [~N min]

<!-- Para o agente:
- Escreva no idioma do usuário. Ele vai seguir isto sem conhecer o código.
- Um bloco por lugar onde algo é feito, com o título dizendo onde (máquina, pasta, painel).
- Todo comando precisa poder ser copiado e colado como está. Use os valores reais do projeto
  (nome do banco, usuário, porta, variáveis de ambiente, caminhos) tirados do código e do definition.md.
- Placeholders <EM_MAIUSCULAS> só para o que você não tem como saber (segredos, IP, conta) e
  todos listados em "Valores que você precisa". Nunca escreva um segredo real neste arquivo.
- Termine com um comando de conferência que você mesmo usaria para validar. -->

## Por quê

[1 a 2 linhas: o que isso destrava e por que o agente não consegue fazer sozinho.]

## Valores que você precisa

| Placeholder | O que é | Onde conseguir |
|-------------|---------|----------------|
| `<VPS_HOST>` | [IP ou domínio da VPS] | [painel do provedor] |

## Passo a passo

### 1. [Onde: na VPS]

```bash
[comandos exatos]
```

### 2. [Onde: na sua máquina, na raiz do projeto]

[Ex.: adicione ao `.env`, que não é versionado:]

```dotenv
[CHAVE=valor]
```

## Como conferir

```bash
[comando de verificação]
```

Esperado: [saída que mostra que deu certo].

## Quando terminar

Mude o **Status** para `done` e rode de novo [o comando que estava executando, ex.: `/executor-auto`]. O item bloqueado é retomado.
