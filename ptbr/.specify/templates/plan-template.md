# Plano de Implementação: [FEATURE]

**Branch**: `[###-nome-da-feature]` | **Data**: [DATA] | **Spec**: [link]

**Entrada**: Especificação da funcionalidade em `/specs/[###-nome-da-feature]/spec.md`

**Observação**: Este template é preenchido pelo comando `/speckit-plan`; a definição do comando descreve o fluxo de execução.

## Resumo

[Extrair da spec: requisito principal + abordagem técnica vinda da pesquisa]

## Contexto Técnico

<!--
  AÇÃO NECESSÁRIA: Substitua o conteúdo desta seção pelos detalhes técnicos
  do projeto. A estrutura aqui é apresentada como orientação para guiar
  o processo de iteração.
-->

**Linguagem/Versão**: [ex.: Python 3.11, Swift 5.9, Rust 1.75 ou NEEDS CLARIFICATION]

**Dependências Principais**: [ex.: FastAPI, UIKit, LLVM ou NEEDS CLARIFICATION]

**Armazenamento**: [se aplicável, ex.: PostgreSQL, CoreData, arquivos ou N/A]

**Testes**: [ex.: pytest, XCTest, cargo test ou NEEDS CLARIFICATION]

**Plataforma-alvo**: [ex.: servidor Linux, iOS 15+, WASM ou NEEDS CLARIFICATION]

**Tipo de Projeto**: [ex.: library/cli/web-service/mobile-app/compiler/desktop-app ou NEEDS CLARIFICATION]

**Metas de Desempenho**: [específico do domínio, ex.: 1000 req/s, 10k linhas/s, 60 fps ou NEEDS CLARIFICATION]

**Restrições**: [específico do domínio, ex.: <200ms p95, <100MB de memória, funciona offline ou NEEDS CLARIFICATION]

**Escala/Escopo**: [específico do domínio, ex.: 10k usuários, 1M LOC, 50 telas ou NEEDS CLARIFICATION]

## Verificação da Constituição

*GATE: Deve passar antes da pesquisa da Fase 0. Reverificar após o design da Fase 1.*

[Gates determinados com base no arquivo de constituição]

## Estrutura do Projeto

### Documentação (esta feature)

```text
specs/[###-feature]/
├── plan.md              # Este arquivo (saída do comando /speckit-plan)
├── research.md          # Saída da Fase 0 (comando /speckit-plan)
├── data-model.md        # Saída da Fase 1 (comando /speckit-plan)
├── quickstart.md        # Saída da Fase 1 (comando /speckit-plan)
├── contracts/           # Saída da Fase 1 (comando /speckit-plan)
└── tasks.md             # Saída da Fase 2 (comando /speckit-tasks - NÃO é criado pelo /speckit-plan)
```

### Código-fonte (raiz do repositório)
<!--
  AÇÃO NECESSÁRIA: Substitua a árvore de placeholders abaixo pelo layout concreto
  desta feature. Apague as opções não usadas e expanda a estrutura escolhida com
  caminhos reais (ex.: apps/admin, packages/algo). O plano entregue não deve
  conter os rótulos de Opção.
-->

```text
# [REMOVER SE NÃO USADO] Opção 1: Projeto único (PADRÃO)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVER SE NÃO USADO] Opção 2: Aplicação web (quando "frontend" + "backend" detectados)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVER SE NÃO USADO] Opção 3: Mobile + API (quando "iOS/Android" detectado)
api/
└── [igual ao backend acima]

ios/ ou android/
└── [estrutura específica da plataforma: módulos de feature, fluxos de UI, testes de plataforma]
```

**Decisão de Estrutura**: [Documente a estrutura selecionada e referencie os
diretórios reais capturados acima]

## Rastreamento de Complexidade

> **Preencha SOMENTE se a Verificação da Constituição tiver violações que precisam ser justificadas**

| Violação | Por que é necessária | Alternativa mais simples rejeitada porque |
|----------|----------------------|-------------------------------------------|
| [ex.: 4º projeto] | [necessidade atual] | [por que 3 projetos são insuficientes] |
| [ex.: padrão Repository] | [problema específico] | [por que acesso direto ao BD é insuficiente] |
