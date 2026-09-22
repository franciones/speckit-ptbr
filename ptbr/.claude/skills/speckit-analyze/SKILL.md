---
name: "speckit-analyze"
description: "Realizar uma análise não destrutiva de consistência e qualidade entre artefatos, cobrindo spec.md, plan.md e tasks.md após a geração de tarefas."
argument-hint: "Áreas de foco opcionais para a análise"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/analyze.md"
user-invocable: true
disable-model-invocation: false
---

## Idioma de saída (obrigatório)

Todo texto narrativo que este comando produzir (documentos, seções, perguntas, relatórios e respostas ao usuário) DEVE ser escrito em português do Brasil. Código, nomes de arquivos, caminhos, comandos, identificadores e os termos do glossário em `CLAUDE.md` permanecem em inglês. Use os títulos de seção definidos no mapa de `CLAUDE.md`.

## Entrada do Usuário

```text
$ARGUMENTS
```

Você **DEVE** considerar a entrada do usuário antes de prosseguir (se não estiver vazia).

## Verificações Pré-Execução

**Verificar hooks de extensão (antes da análise)**:
- Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se existir, leia-o e procure entradas sob a chave `hooks.before_analyze`
- Se o YAML não puder ser interpretado ou for inválido, não pule silenciosamente: informe ao usuário que `.specify/extensions.yml` não pôde ser lido (inclua o erro do parser) e que nenhum hook foi verificado, incluindo quaisquer hooks obrigatórios (`optional: false`) registrados ali, e então continue normalmente
- Filtre os hooks em que `enabled` é explicitamente `false`. Trate hooks sem o campo `enabled` como habilitados por padrão.
- Para cada hook restante, **não** tente interpretar ou avaliar expressões de `condition` do hook:
  - Se o hook não tiver o campo `condition`, ou ele for nulo/vazio, trate o hook como executável
  - Se o hook definir uma `condition` não vazia, pule o hook e deixe a avaliação da condição para a implementação do HookExecutor
- Ao construir invocações de comando a partir dos nomes de comando dos hooks, substitua pontos (`.`) por hífens (`-`). Por exemplo, `speckit.git.commit` → `/speckit-git-commit`.
- Para cada hook executável, emita o seguinte com base no seu sinalizador `optional`:
  - **Hook opcional** (`optional: true`):
    ```
    ## Hooks de Extensão

    **Pré-Hook Opcional**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Hook obrigatório** (`optional: false`):
    ```
    ## Hooks de Extensão

    **Pré-Hook Automático**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}

    Wait for the result of the hook command before proceeding to the Goal.
    ```
    Após emitir o bloco acima você DEVE de fato invocar o hook e aguardar sua conclusão antes de continuar. Execute-o da mesma forma que executaria o comando você mesmo neste agente/sessão (a invocação pode diferir do id literal `{command}` mostrado acima, por exemplo um agente em modo skills executa como `/skill:speckit-...` ou `$speckit-...`). Emitir o bloco sozinho não executa o hook.
- Se nenhum hook estiver registrado ou `.specify/extensions.yml` não existir, pule silenciosamente

## Objetivo

Identificar inconsistências, duplicações, ambiguidades e itens subespecificados entre os três artefatos centrais (`spec.md`, `plan.md`, `tasks.md`) antes da implementação. Este comando DEVE ser executado somente após `/speckit-tasks` ter produzido com sucesso um `tasks.md` completo.

## Restrições de Operação

**ESTRITAMENTE SOMENTE LEITURA**: **Não** modifique nenhum arquivo. Emita um relatório de análise estruturado. Ofereça um plano de correção opcional (o usuário deve aprovar explicitamente antes que quaisquer comandos de edição subsequentes sejam invocados manualmente).

**Autoridade da Constituição**: A constituição do projeto (`.specify/memory/constitution.md`) é **inegociável** dentro do escopo desta análise. Conflitos com a constituição são automaticamente CRÍTICOS e exigem ajuste da spec, do plano ou das tarefas — não diluição, reinterpretação ou ignorar silenciosamente o princípio. Se um princípio em si precisar mudar, isso deve ocorrer em uma atualização separada e explícita da constituição, fora de `/speckit-analyze`.

## Passos de Execução

### 1. Inicializar o Contexto da Análise

Execute `.specify/scripts/powershell/check-prerequisites.ps1 -Json -RequireSpec -RequireTasks -IncludeTasks` uma vez a partir da raiz do repositório e interprete o JSON para FEATURE_DIR e AVAILABLE_DOCS. Derive os caminhos absolutos:

- SPEC = FEATURE_DIR/spec.md
- PLAN = FEATURE_DIR/plan.md
- TASKS = FEATURE_DIR/tasks.md

Aborte com uma mensagem de erro se algum arquivo obrigatório estiver ausente (instrua o usuário a executar o comando de pré-requisito faltante).
Para aspas simples em argumentos como "I'm Groot", use a sintaxe de escape: por exemplo 'I'\''m Groot' (ou aspas duplas se possível: "I'm Groot").

### 2. Carregar Artefatos (Divulgação Progressiva)

Carregue apenas o contexto mínimo necessário de cada artefato:

**De spec.md:**

- Visão geral/Contexto
- Requisitos Funcionais
- Critérios de Sucesso (resultados mensuráveis — por exemplo, desempenho, segurança, disponibilidade, sucesso do usuário, impacto no negócio)
- Histórias de Usuário
- Casos Extremos (se presentes)

**De plan.md:**

- Escolhas de arquitetura/stack
- Referências ao Modelo de Dados
- Fases
- Restrições técnicas

**De tasks.md:**

- IDs das tarefas
- Descrições
- Agrupamento por fase
- Marcadores de paralelismo [P]
- Caminhos de arquivo referenciados

**Da constituição:**

- Carregue `.specify/memory/constitution.md` para validação de princípios

### 3. Construir Modelos Semânticos

Crie representações internas (não inclua artefatos brutos na saída):

- **Inventário de requisitos**: Para cada Requisito Funcional (FR-###) e Critério de Sucesso (SC-###), registre uma chave estável. Use o identificador explícito FR-/SC- como chave primária quando presente, e opcionalmente derive também um slug de frase imperativa para legibilidade (por exemplo, "Usuário pode enviar arquivo" → `usuario-pode-enviar-arquivo`). Inclua apenas itens de Critérios de Sucesso que exijam trabalho construível (por exemplo, infraestrutura de teste de carga, ferramentas de auditoria de segurança), e exclua métricas de resultado pós-lançamento e KPIs de negócio (por exemplo, "Reduzir tickets de suporte em 50%").
- **Inventário de histórias de usuário/ações**: Ações discretas do usuário com critérios de aceitação
- **Mapeamento de cobertura de tarefas**: Mapeie cada tarefa para um ou mais requisitos ou histórias (inferência por palavra-chave / padrões de referência explícita como IDs ou frases-chave)
- **Conjunto de regras da constituição**: Extraia nomes de princípios e declarações normativas DEVE/DEVERIA

### 4. Passagens de Detecção (Análise Eficiente em Tokens)

Foque em achados de alto sinal. Limite a 50 achados no total; agregue o restante em um resumo de excedente.

#### A. Detecção de Duplicação

- Identifique requisitos quase duplicados
- Marque a redação de menor qualidade para consolidação

#### B. Detecção de Ambiguidade

- Sinalize adjetivos vagos (rápido, escalável, seguro, intuitivo, robusto) sem critérios mensuráveis
- Sinalize placeholders não resolvidos (TODO, TKTK, ???, `<placeholder>`, etc.)

#### C. Subespecificação

- Requisitos com verbos mas sem objeto ou resultado mensurável
- Histórias de usuário sem alinhamento com critérios de aceitação
- Tarefas que referenciam arquivos ou componentes não definidos na spec/plano

#### D. Alinhamento com a Constituição

- Qualquer requisito ou elemento do plano em conflito com um princípio DEVE
- Seções obrigatórias ou quality gates da constituição ausentes

#### E. Lacunas de Cobertura

- Requisitos sem nenhuma tarefa associada
- Tarefas sem requisito/história mapeados
- Critérios de Sucesso que exigem trabalho construível (desempenho, segurança, disponibilidade) não refletidos nas tarefas

#### F. Inconsistência

- Deriva de terminologia (mesmo conceito nomeado de forma diferente entre arquivos)
- Entidades de dados referenciadas no plano mas ausentes na spec (ou vice-versa)
- Contradições na ordem das tarefas (por exemplo, tarefas de integração antes das tarefas de configuração fundacional sem nota de dependência)
- Requisitos conflitantes (por exemplo, um exige Next.js enquanto outro especifica Vue)

### 5. Atribuição de Severidade

Use esta heurística para priorizar os achados:

- **CRÍTICO**: Viola um DEVE da constituição, artefato central da spec ausente, ou requisito com cobertura zero que bloqueia a funcionalidade básica
- **ALTO**: Requisito duplicado ou conflitante, atributo de segurança/desempenho ambíguo, critério de aceitação não testável
- **MÉDIO**: Deriva de terminologia, cobertura de tarefas não funcionais ausente, caso extremo subespecificado
- **BAIXO**: Melhorias de estilo/redação, redundância menor que não afeta a ordem de execução

### 6. Produzir Relatório de Análise Compacto

Emita um relatório Markdown (sem gravação de arquivos) com a seguinte estrutura:

## Relatório de Análise da Especificação

| ID | Categoria | Severidade | Localização(ões) | Resumo | Recomendação |
|----|-----------|------------|------------------|--------|--------------|
| A1 | Duplicação | ALTO | spec.md:L120-134 | Dois requisitos similares ... | Unificar redação; manter a versão mais clara |

(Adicione uma linha por achado; gere IDs estáveis prefixados pela inicial da categoria.)

**Tabela de Resumo de Cobertura:**

| Chave do Requisito | Tem Tarefa? | IDs das Tarefas | Observações |
|--------------------|-------------|-----------------|-------------|

**Problemas de Alinhamento com a Constituição:** (se houver)

**Tarefas Não Mapeadas:** (se houver)

**Métricas:**

- Total de Requisitos
- Total de Tarefas
- Cobertura % (requisitos com >=1 tarefa)
- Contagem de Ambiguidades
- Contagem de Duplicações
- Contagem de Problemas Críticos

### 7. Fornecer Próximas Ações

Ao final do relatório, emita um bloco conciso de Próximas Ações:

- Se existirem problemas CRÍTICOS: Recomende resolvê-los antes de `/speckit-implement`
- Se apenas BAIXO/MÉDIO: O usuário pode prosseguir, mas forneça sugestões de melhoria
- Forneça sugestões explícitas de comandos: por exemplo, "Execute /speckit-specify com refinamento", "Execute /speckit-plan para ajustar a arquitetura", "Edite manualmente tasks.md para adicionar cobertura para 'performance-metrics'"

### 8. Oferecer Correção

Pergunte ao usuário: "Você gostaria que eu sugerisse edições concretas de correção para os N principais problemas?" (NÃO as aplique automaticamente.)

### 9. Verificar hooks de extensão

Após reportar, verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se existir, leia-o e procure entradas sob a chave `hooks.after_analyze`
- Se o YAML não puder ser interpretado ou for inválido, não pule silenciosamente: informe ao usuário que `.specify/extensions.yml` não pôde ser lido (inclua o erro do parser) e que nenhum hook foi verificado, incluindo quaisquer hooks obrigatórios (`optional: false`) registrados ali, e então continue normalmente
- Filtre os hooks em que `enabled` é explicitamente `false`. Trate hooks sem o campo `enabled` como habilitados por padrão.
- Para cada hook restante, **não** tente interpretar ou avaliar expressões de `condition` do hook:
  - Se o hook não tiver o campo `condition`, ou ele for nulo/vazio, trate o hook como executável
  - Se o hook definir uma `condition` não vazia, pule o hook e deixe a avaliação da condição para a implementação do HookExecutor
- Ao construir invocações de comando a partir dos nomes de comando dos hooks, substitua pontos (`.`) por hífens (`-`). Por exemplo, `speckit.git.commit` → `/speckit-git-commit`.
- Para cada hook executável, emita o seguinte com base no seu sinalizador `optional`:
  - **Hook opcional** (`optional: true`):
    ```
    ## Hooks de Extensão

    **Optional Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Hook obrigatório** (`optional: false`):
    ```
    ## Hooks de Extensão

    **Automatic Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
    Após emitir o bloco acima você DEVE de fato invocar o hook e aguardar sua conclusão antes de continuar. Execute-o da mesma forma que executaria o comando você mesmo neste agente/sessão (a invocação pode diferir do id literal `{command}` mostrado acima, por exemplo um agente em modo skills executa como `/skill:speckit-...` ou `$speckit-...`). Emitir o bloco sozinho não executa o hook.
- Se nenhum hook estiver registrado ou `.specify/extensions.yml` não existir, pule silenciosamente

## Princípios de Operação

### Eficiência de Contexto

- **Mínimo de tokens de alto sinal**: Foque em achados acionáveis, não em documentação exaustiva
- **Divulgação progressiva**: Carregue artefatos incrementalmente; não despeje todo o conteúdo na análise
- **Saída eficiente em tokens**: Limite a tabela de achados a 50 linhas; resuma o excedente
- **Resultados determinísticos**: Executar novamente sem mudanças deve produzir IDs e contagens consistentes

### Diretrizes de Análise

- **NUNCA modifique arquivos** (esta é uma análise somente leitura)
- **NUNCA alucine seções ausentes** (se ausentes, reporte com precisão)
- **Priorize violações da constituição** (estas são sempre CRÍTICAS)
- **Use exemplos em vez de regras exaustivas** (cite instâncias específicas, não padrões genéricos)
- **Reporte zero problemas com naturalidade** (emita relatório de sucesso com estatísticas de cobertura)

## Contexto

$ARGUMENTS
