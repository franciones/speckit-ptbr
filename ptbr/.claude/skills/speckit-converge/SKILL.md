---
name: "speckit-converge"
description: "Avalia o código atual em relação à spec, ao plano e às tarefas da feature, e então acrescenta ao tasks.md, como novas tarefas, todo o trabalho ainda não construído, para que o implement possa completá-lo."
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/converge.md"
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

**Verificar hooks de extensão (antes da convergência)**:

- Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se existir, leia-o e procure entradas sob a chave `hooks.before_converge`
- Se o YAML não puder ser interpretado ou for inválido, não pule silenciosamente: informe ao usuário que `.specify/extensions.yml` não pôde ser lido (inclua o erro do parser) e que nenhum hook foi verificado, incluindo quaisquer hooks obrigatórios (`optional: false`) registrados ali, e então continue normalmente
- Filtre os hooks em que `enabled` seja explicitamente `false`. Trate hooks sem o campo `enabled` como habilitados por padrão.
- Para cada hook restante, **não** tente interpretar ou avaliar expressões de `condition` do hook:
  - Se o hook não tiver o campo `condition`, ou ele for nulo/vazio, trate o hook como executável
  - Se o hook definir um `condition` não vazio, pule o hook e deixe a avaliação da condição para a implementação do HookExecutor
- Ao construir invocações de comando a partir dos nomes de comando dos hooks, substitua pontos (`.`) por hífens (`-`). Por exemplo, `speckit.git.commit` → `/speckit-git-commit`.
- Para cada hook executável, produza a saída abaixo conforme o flag `optional`:
  - **Hook opcional** (`optional: true`):

    ```text
    ## Hooks de Extensão

    **Pré-Hook Opcional**: {extension}
    Comando: `/{command}`
    Descrição: {description}

    Prompt: {prompt}
    Para executar: `/{command}`
    ```

  - **Hook obrigatório** (`optional: false`):

    ```text
    ## Hooks de Extensão

    **Pré-Hook Automático**: {extension}
    Executando: `/{command}`
    EXECUTE_COMMAND: {command}

    Aguarde o resultado do comando do hook antes de prosseguir para o Objetivo.
    ```
    Após emitir o bloco acima você DEVE de fato invocar o hook e aguardar que ele termine antes de continuar. Execute-o da mesma forma que você executaria o comando neste agente/sessão (a invocação pode diferir do id literal `{command}` mostrado acima, por exemplo, um agente em modo skills o executa como `/skill:speckit-...` ou `$speckit-...`). Emitir o bloco sozinho não executa o hook.

- Se nenhum hook estiver registrado ou `.specify/extensions.yml` não existir, pule silenciosamente

## Objetivo

Fechar a lacuna entre o que a especificação, o plano e as tarefas de uma feature exigem e o que
o código atualmente implementa. Leia `spec.md`, `plan.md` e `tasks.md` como a **única
fonte de intenção** (com a constituição como restrições governantes), avalie o estado atual
do código, determine quais requisitos, critérios de aceitação, decisões do plano e
tarefas existentes estão não atendidos, incompletos ou apenas parcialmente satisfeitos, e **acrescente cada parte
do trabalho restante como uma nova tarefa rastreável** ao final de `tasks.md`, de modo que
`/speckit-implement` possa completá-la. Este comando DEVE rodar somente depois que
`/speckit-implement` tiver rodado sobre o `tasks.md` atual, e depois que `/speckit-tasks` tiver produzido um `tasks.md` completo.

Isto **não** é uma ferramenta de diff e **não** rastreia mudanças. Ele avalia o estado presente
do código em relação aos artefatos da feature — sem git, sem comparação de branches, sem histórico.

## Restrições Operacionais

**SOMENTE ACRESCENTAR, NUNCA REESCREVER**: A **única** escrita do comando é acrescentar uma nova
seção `## Fase N: Convergência` ao `tasks.md`. Ele NÃO DEVE:

- modificar `spec.md` ou `plan.md` de forma alguma;
- reescrever, renumerar, reordenar ou excluir qualquer tarefa existente (incluindo tarefas de uma
  fase de Convergência anterior);
- modificar, criar ou excluir qualquer código de aplicação — completar as tarefas acrescentadas é
  trabalho do `/speckit-implement`.

Quando o código já satisfaz tudo, o comando DEVE deixar o `tasks.md`
**inalterado byte a byte** (sem cabeçalho de Convergência vazio) e reportar um resultado limpo.

**Autoridade da Constituição**: A constituição do projeto (`.specify/memory/constitution.md`) é
**inegociável**. Código que viola um princípio DEVE é o achado de maior severidade e
produz uma tarefa de correção correspondente. Se a constituição for um template não preenchido,
pule as verificações de constituição de forma graciosa em vez de falhar.

## Passos de Execução

### 1. Inicializar o Contexto de Convergência

Execute `.specify/scripts/powershell/check-prerequisites.ps1 -Json -RequireSpec -RequireTasks -IncludeTasks` uma vez a partir da raiz do repositório e interprete o JSON para FEATURE_DIR e AVAILABLE_DOCS. Derive os caminhos absolutos:

- SPEC = FEATURE_DIR/spec.md
- PLAN = FEATURE_DIR/plan.md
- TASKS = FEATURE_DIR/tasks.md
- CONSTITUTION = `.specify/memory/constitution.md` (se presente)
Se `spec.md`, `plan.md` ou `tasks.md` estiver ausente, PARE com uma mensagem clara e acionável nomeando o
comando pré-requisito a executar (`/speckit-specify` para spec ausente, `/speckit-plan` para plano ausente,
`/speckit-tasks` para tarefas ausentes). Não produza saída parcial.
Para aspas simples em argumentos como "I'm Groot", use sintaxe de escape: por exemplo 'I'\''m Groot' (ou aspas duplas se possível: "I'm Groot").

### 2. Carregar Artefatos (Divulgação Progressiva)

Carregue apenas o contexto mínimo necessário de cada artefato:

**De spec.md:**

- Requisitos Funcionais (FR-###)
- Critérios de Sucesso (SC-###) — inclua apenas itens que exigem trabalho construível; exclua
  métricas de resultado pós-lançamento e KPIs de negócio
- Histórias de Usuário e seus Cenários de Aceitação
- Casos Extremos (se presentes)

**De plan.md:**

- Escolhas de arquitetura/stack e decisões técnicas
- Referências ao Modelo de Dados
- Fases e pontos de contato nomeados (arquivos/componentes que o plano diz que serão criados ou editados)
- Restrições técnicas

**De tasks.md:**

- IDs de tarefa (para calcular o próximo ID e o próximo número de fase)
- Descrições, agrupamento por fase e caminhos de arquivo referenciados

**Da constituição (se não for um template não preenchido):**

- Nomes dos princípios e declarações normativas DEVE/DEVERIA

### 3. Construir o Inventário de Intenção

Crie um modelo interno (não ecoe os artefatos brutos):

- **Inventário de requisitos**: uma chave estável por FR-### / SC-### / cenário de aceitação de
  história de usuário (por exemplo `US1/AC2`), mais as decisões do plano e os princípios da constituição que
  impõem obrigações construíveis.
- **Mapa de escopo do código**: a partir dos caminhos de arquivo nomeados em `plan.md` e `tasks.md`, mais uma busca
  por palavras-chave dos conceitos que cada requisito descreve, derive o conjunto de arquivos-fonte e
  componentes no escopo da avaliação. Limite a avaliação a esses — **não** infira
  escopo além do que os artefatos definem.

### 4. Avaliar o Código e Classificar os Achados

Inclua toda tarefa existente no inventário de intenção, independentemente do estado do checkbox ou
da fase de Convergência: alegações de conclusão não são evidência. Verifique o comportamento atual contra
a spec, o plano, as tarefas e a constituição; para cadeias de tarefas corretivas, avalie o comportamento
resultante, não detalhes de implementação superados. Verifique tanto obrigações não atendidas quanto
implementação que contradiz, excede ou fica fora da intenção declarada.

Para cada item do inventário de intenção, inspecione o código atual no escopo e produza um
`Finding` apenas onde houver uma lacuna. Classifique todo achado por **tipo de lacuna**:

- **`missing`**: o trabalho exigido está totalmente ausente do código.
- **`partial`**: o trabalho existe, mas ainda não satisfaz plenamente o requisito /
  critério de aceitação / decisão do plano.
- **`contradicts`**: o código faz algo que conflita com a intenção declarada ou com um
  princípio DEVE da constituição.
- **`unrequested`**: o código contém trabalho não exigido pela spec, plano ou tarefas
  (exposto para conhecimento — o converge **não** exclui código, apenas acrescenta uma tarefa para
  revisar/justificar ou removê-lo).

Cada `Finding` registra: um id estável, o `source-ref` ao qual se rastreia, o `gap-type`, uma
severidade e uma descrição curta legível por humanos com a evidência (o arquivo/área observado).

**Casos extremos:**

- **Pouco ou nenhum código ainda**: trate todo o escopo especificado como trabalho restante `missing`
  em vez de falhar.
- **Nada resta**: produza zero achados e siga o ramo convergido no Passo 7.

### 5. Atribuir Severidade

- **CRITICAL**: viola um princípio DEVE da constituição, ou uma lacuna `missing`/`contradicts` que
  bloqueia a funcionalidade básica de uma história de usuário P1.
- **HIGH**: uma lacuna `missing` ou `partial` em um requisito funcional central ou critério de
  aceitação.
- **MEDIUM**: uma lacuna `partial` em um requisito secundário, ou uma adição `unrequested` com
  justificativa pouco clara.
- **LOW**: lacunas parciais menores, polimento, ou adições `unrequested` de baixo risco.

### 6. Apresentar o Resumo de Achados na Sessão

Antes de acrescentar qualquer coisa, produza um resumo compacto, graduado por severidade (ainda sem escrita em arquivos):

## Achados da Convergência

| ID | Tipo de Lacuna | Severidade | Origem | Evidência | Trabalho Restante |
|----|----------------|------------|--------|-----------|-------------------|
| F1 | missing        | HIGH       | FR-008 | Exemplo: nenhuma proteção de somente-acréscimo detectada em path/to/module.py ao escrever tasks.md | Adicionar aplicação de somente-acréscimo |

**Métricas de resumo:**

- Requisitos / critérios de aceitação verificados
- Decisões do plano verificadas
- Princípios da constituição verificados (ou "pulado — template")
- Achados por tipo de lacuna (missing / partial / contradicts / unrequested)
- Achados por severidade

### 7. Acrescentar Tarefas de Convergência (ou reportar convergido)

**Se houver um ou mais achados acionáveis** (resultado `tasks_appended`):

Acrescente ao **final** de `tasks.md`, conforme o contrato de acréscimo:

1. Examine todos os IDs de tarefa existentes; seja `M` o máximo. Determine o próximo número de fase `N`
   (maior fase existente + 1).
2. Escreva um único novo cabeçalho de seção `## Fase N: Convergência`.
3. Emita um item de checklist por achado acionável, ordenados com CRITICAL/HIGH primeiro, atribuindo
   IDs com zeros à esquerda `T{M+1:03d}, T{M+2:03d}, …`:

   ```markdown
   - [ ] T042 <descrição imperativa> conforme <source-ref> (<gap-type>)
   ```

   `<source-ref>` rastreia a tarefa até sua origem: por exemplo `FR-003`, `SC-002`,
   `US1/AC2`, `plan: decisão de armazenamento`, `Constituição II`.

   `<gap-type>` é um de `missing`, `partial`, `contradicts`, `unrequested`.

   Tarefas de violação da constituição DEVEM ser emitidas primeiro e descritas como
   `CRITICAL`.
4. Nunca reutilize ou renumere IDs existentes. Se uma fase de Convergência anterior existir, adicione uma nova,
   numerada separadamente, abaixo dela — não toque na antiga.

**Se não houver achados acionáveis** (resultado `converged`):

- **Não** modifique `tasks.md` de forma alguma — sem cabeçalho de fase vazio.
- Reporte: **"✅ Convergido — a implementação satisfaz a spec, o plano e as tarefas."**
- Inclua as contagens de resumo do que foi verificado.

### 8. Fornecer Próximas Ações (Passagem de Bastão)

- Em `tasks_appended`: informe quantas tarefas foram acrescentadas e sob qual fase, e recomende
  executar `/speckit-implement` para completá-las; observe que uma execução subsequente do converge
  encontrará menos itens restantes ou nenhum.
- Em `converged`: recomende prosseguir para a revisão / abertura de um PR. Nenhuma passagem adicional de implement
  é necessária para o escopo especificado desta feature.

### 9. Verificar hooks de extensão

Após produzir o resultado, verifique se `.specify/extensions.yml` existe na raiz do projeto.

- Se existir, leia-o e procure entradas sob a chave `hooks.after_converge`
- Se o YAML não puder ser interpretado ou for inválido, não pule silenciosamente: informe ao usuário que `.specify/extensions.yml` não pôde ser lido (inclua o erro do parser) e que nenhum hook foi verificado, incluindo quaisquer hooks obrigatórios (`optional: false`) registrados ali, e então continue normalmente
- Filtre os hooks em que `enabled` seja explicitamente `false`. Trate hooks sem o campo `enabled` como habilitados por padrão.
- Para cada hook restante, **não** tente interpretar ou avaliar expressões de `condition` do hook:
  - Se o hook não tiver o campo `condition`, ou ele for nulo/vazio, trate o hook como executável
  - Se o hook definir um `condition` não vazio, pule o hook e deixe a avaliação da condição para a implementação do HookExecutor
- Reporte o resultado da convergência (`converged` ou `tasks_appended`) na sessão antes de listar
  quaisquer hooks, para que os usuários possam decidir se executam comandos opcionais de acompanhamento.
- Ao construir invocações de comando a partir dos nomes de comando dos hooks, substitua pontos (`.`) por hífens (`-`). Por exemplo, `speckit.git.commit` → `/speckit-git-commit`.
- Para cada hook executável, produza a saída abaixo conforme o flag `optional`:
  - **Hook opcional** (`optional: true`):

    ```text
    ## Hooks de Extensão

    **Hook Opcional**: {extension}
    Comando: `/{command}`
    Descrição: {description}

    Prompt: {prompt}
    Para executar: `/{command}`
    ```

  - **Hook obrigatório** (`optional: false`):

    ```text
    ## Hooks de Extensão

    **Hook Automático**: {extension}
    Executando: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
    Após emitir o bloco acima você DEVE de fato invocar o hook e aguardar que ele termine antes de continuar. Execute-o da mesma forma que você executaria o comando neste agente/sessão (a invocação pode diferir do id literal `{command}` mostrado acima, por exemplo, um agente em modo skills o executa como `/skill:speckit-...` ou `$speckit-...`). Emitir o bloco sozinho não executa o hook.

- Se nenhum hook estiver registrado ou `.specify/extensions.yml` não existir, pule silenciosamente
