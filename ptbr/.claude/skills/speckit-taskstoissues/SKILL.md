---
name: "speckit-taskstoissues"
description: "Converte as tarefas existentes em issues do GitHub acionáveis e ordenadas por dependência para a feature, com base nos artefatos de design disponíveis."
argument-hint: "Filtro ou label opcional para as issues do GitHub"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/taskstoissues.md"
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

**Verificar hooks de extensão (antes da conversão de tarefas em issues)**:
- Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se existir, leia-o e procure entradas sob a chave `hooks.before_taskstoissues`
- Se o YAML não puder ser interpretado ou for inválido, não pule silenciosamente: informe ao usuário que `.specify/extensions.yml` não pôde ser lido (inclua o erro do parser) e que nenhum hook foi verificado, incluindo quaisquer hooks obrigatórios (`optional: false`) registrados ali, e então continue normalmente
- Descarte hooks cujo `enabled` seja explicitamente `false`. Trate hooks sem o campo `enabled` como habilitados por padrão.
- Para cada hook restante, **não** tente interpretar ou avaliar expressões de `condition` do hook:
  - Se o hook não tiver campo `condition`, ou ele for nulo/vazio, trate o hook como executável
  - Se o hook definir um `condition` não vazio, pule o hook e deixe a avaliação da condição para a implementação do HookExecutor
- Ao construir invocações de comando a partir dos nomes de comando dos hooks, substitua pontos (`.`) por hífens (`-`). Por exemplo, `speckit.git.commit` → `/speckit-git-commit`.
- Para cada hook executável, produza a saída abaixo conforme seu flag `optional`:
  - **Hook opcional** (`optional: true`):
    ```
    ## Hooks de Extensão

    **Pré-Hook Opcional**: {extension}
    Comando: `/{command}`
    Descrição: {description}

    Prompt: {prompt}
    Para executar: `/{command}`
    ```
  - **Hook obrigatório** (`optional: false`):
    ```
    ## Hooks de Extensão

    **Pré-Hook Automático**: {extension}
    Executando: `/{command}`
    EXECUTE_COMMAND: {command}

    Aguarde o resultado do comando do hook antes de prosseguir para o Roteiro.
    ```
    Após emitir o bloco acima você DEVE de fato invocar o hook e aguardar sua conclusão antes de continuar. Execute-o da mesma forma que você executaria o comando neste agente/sessão (a invocação pode diferir do id literal `{command}` mostrado acima, por exemplo, um agente em modo skills o executa como `/skill:speckit-...` ou `$speckit-...`). Emitir o bloco sozinho não executa o hook.
- Se nenhum hook estiver registrado ou `.specify/extensions.yml` não existir, pule silenciosamente

## Roteiro

1. Execute `.specify/scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks` a partir da raiz do repositório e interprete FEATURE_DIR e a lista AVAILABLE_DOCS. Todos os caminhos devem ser absolutos. Para aspas simples em argumentos como "I'm Groot", use a sintaxe de escape: ex. 'I'\''m Groot' (ou aspas duplas se possível: "I'm Groot").
1. **SE EXISTIR**: Carregue `.specify/memory/constitution.md` para obter os princípios do projeto e as restrições de governança.
1. A partir do script executado, extraia o caminho para **tasks**.
1. Obtenha o remote do Git executando:

```bash
git config --get remote.origin.url
```

> [!CAUTION]
> SÓ PROSSIGA PARA AS PRÓXIMAS ETAPAS SE O REMOTE FOR UMA URL DO GITHUB

1. **Busque as issues existentes para deduplicação**: Antes de criar qualquer coisa, monte o conjunto de IDs de tarefa que você está prestes a processar a partir de `tasks.md` (cada um é um `T` seguido de **pelo menos** três dígitos, ex.: `T001` — `/speckit-converge` atribui novos IDs com `T{M+1:03d}`, que é um mínimo e não um máximo, então quando um arquivo tiver mais de 999 tarefas os IDs terão quatro dígitos ou mais). Em seguida, use a ferramenta `list_issues` do servidor MCP do GitHub para procurar issues que já cubram esses IDs. Não passe um valor de `state`, pois omiti-lo faz a ferramenta retornar issues abertas e fechadas. Solicite `perPage: 100` para reduzir o número de chamadas e, como a ferramenta usa paginação por cursor, solicite as páginas com o parâmetro `after` (usando o `endCursor` da resposta anterior). Para cada título de issue, compare-o com o padrão de ID de tarefa `\bT\d{3,}\b` (o `{3,}` aceita IDs de quatro dígitos ou mais — com `\d{3}` um título contendo `T1000` não casaria de jeito nenhum, porque o `\b` final não pode ficar entre dois dígitos, e assim essa tarefa silenciosamente não seria nem deduplicada nem criada; os limites de palavra ainda impedem que um token como `ST001` case, e forçam que toda a sequência de dígitos seja consumida, de modo que `T100` nunca casa dentro de `T1000`; isso também reconhece títulos escritos como `T001 ...`, `T001: ...` ou `[T001] ...`) e, quando casar com um dos seus IDs de tarefa, marque esse ID como já tendo uma issue. Pare de paginar assim que todos os IDs de tarefa tiverem sido encontrados, ou quando não houver mais páginas, para não continuar buscando todo o histórico de issues do repositório depois que todos os IDs de tarefa já estiverem contabilizados. Isso limita o número de chamadas em repositórios com históricos grandes de issues e ainda evita duplicatas quando o comando é executado novamente após `tasks.md` ser regenerado ou a skill ser reinvocada.
1. Para cada tarefa da lista, use o servidor MCP do GitHub para criar uma nova issue no repositório correspondente ao remote do Git. As linhas de tarefa em `tasks.md` começam com um checkbox markdown, então primeiro remova o `- [ ]` inicial (e quaisquer marcadores `[P]` / `[US#]`) para recuperar o ID da tarefa e sua descrição. Crie a issue com um único título canônico no formato `T001: <descrição>`, com o ID escrito uma vez seguido da descrição da tarefa (por exemplo, a linha `- [ ] T001 Criar estrutura do projeto` vira o título `T001: Criar estrutura do projeto`).
   - **Pule** qualquer tarefa cujo ID já esteja presente no conjunto de issues existentes da etapa anterior, e informe isso (por exemplo, `T001 já possui uma issue, pulando`).
   - Crie issues apenas para tarefas que ainda não tenham uma issue correspondente.

> [!CAUTION]
> EM NENHUMA CIRCUNSTÂNCIA CRIE ISSUES EM REPOSITÓRIOS QUE NÃO CORRESPONDAM À URL DO REMOTE

## Verificações Pós-Execução

**Verificar hooks de extensão (após a conversão de tarefas em issues)**:
Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se existir, leia-o e procure entradas sob a chave `hooks.after_taskstoissues`
- Se o YAML não puder ser interpretado ou for inválido, não pule silenciosamente: informe ao usuário que `.specify/extensions.yml` não pôde ser lido (inclua o erro do parser) e que nenhum hook foi verificado, incluindo quaisquer hooks obrigatórios (`optional: false`) registrados ali, e então continue normalmente
- Descarte hooks cujo `enabled` seja explicitamente `false`. Trate hooks sem o campo `enabled` como habilitados por padrão.
- Para cada hook restante, **não** tente interpretar ou avaliar expressões de `condition` do hook:
  - Se o hook não tiver campo `condition`, ou ele for nulo/vazio, trate o hook como executável
  - Se o hook definir um `condition` não vazio, pule o hook e deixe a avaliação da condição para a implementação do HookExecutor
- Ao construir invocações de comando a partir dos nomes de comando dos hooks, substitua pontos (`.`) por hífens (`-`). Por exemplo, `speckit.git.commit` → `/speckit-git-commit`.
- Para cada hook executável, produza a saída abaixo conforme seu flag `optional`:
  - **Hook opcional** (`optional: true`):
    ```
    ## Hooks de Extensão

    **Hook Opcional**: {extension}
    Comando: `/{command}`
    Descrição: {description}

    Prompt: {prompt}
    Para executar: `/{command}`
    ```
  - **Hook obrigatório** (`optional: false`):
    ```
    ## Hooks de Extensão

    **Hook Automático**: {extension}
    Executando: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
    Após emitir o bloco acima você DEVE de fato invocar o hook e aguardar sua conclusão antes de continuar. Execute-o da mesma forma que você executaria o comando neste agente/sessão (a invocação pode diferir do id literal `{command}` mostrado acima, por exemplo, um agente em modo skills o executa como `/skill:speckit-...` ou `$speckit-...`). Emitir o bloco sozinho não executa o hook.
- Se nenhum hook estiver registrado ou `.specify/extensions.yml` não existir, pule silenciosamente
