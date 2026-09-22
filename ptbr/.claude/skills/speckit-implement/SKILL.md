---
name: "speckit-implement"
description: "Executa o plano de implementação processando e executando todas as tarefas definidas em tasks.md"
argument-hint: "Orientação opcional de implementação ou filtro de tarefas"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/implement.md"
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

**Verificar hooks de extensão (antes da implementação)**:
- Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se existir, leia-o e procure entradas sob a chave `hooks.before_implement`
- Se o YAML não puder ser interpretado ou for inválido, não pule silenciosamente: informe ao usuário que `.specify/extensions.yml` não pôde ser lido (inclua o erro do parser) e que nenhum hook foi verificado, incluindo quaisquer hooks obrigatórios (`optional: false`) registrados ali, e então continue normalmente
- Filtre os hooks em que `enabled` seja explicitamente `false`. Trate hooks sem o campo `enabled` como habilitados por padrão.
- Para cada hook restante, **não** tente interpretar ou avaliar expressões de `condition` do hook:
  - Se o hook não tiver o campo `condition`, ou ele for nulo/vazio, trate o hook como executável
  - Se o hook definir um `condition` não vazio, pule o hook e deixe a avaliação da condição para a implementação do HookExecutor
- Ao construir invocações de comando a partir dos nomes de comando dos hooks, substitua pontos (`.`) por hífens (`-`). Por exemplo, `speckit.git.commit` → `/speckit-git-commit`.
- Para cada hook executável, produza a saída abaixo conforme o flag `optional`:
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
    Após emitir o bloco acima você DEVE de fato invocar o hook e aguardar que ele termine antes de continuar. Execute-o da mesma forma que você executaria o comando neste agente/sessão (a invocação pode diferir do id literal `{command}` mostrado acima, por exemplo, um agente em modo skills o executa como `/skill:speckit-...` ou `$speckit-...`). Emitir o bloco sozinho não executa o hook.
- Se nenhum hook estiver registrado ou `.specify/extensions.yml` não existir, pule silenciosamente

## Roteiro

1. Execute `.specify/scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks` a partir da raiz do repositório e interprete FEATURE_DIR e a lista AVAILABLE_DOCS. Todos os caminhos devem ser absolutos. Para aspas simples em argumentos como "I'm Groot", use sintaxe de escape: por exemplo 'I'\''m Groot' (ou aspas duplas se possível: "I'm Groot").

2. **Verificar o status dos checklists** (se FEATURE_DIR/checklists/ existir):
   - Trate os marcadores dos checklists como um gate somente leitura: examine o estado dos checkboxes, reporte o status e pergunte antes de prosseguir quando necessário; NÃO modifique os arquivos de checklist nem seus marcadores
   - `checklists/requirements.md` é o checklist embutido de qualidade da spec, mantido por `/speckit-specify` e `/speckit-clarify`; checklists personalizados gerados por `/speckit-checklist` são artefatos de revisão de qualidade de requisitos de propriedade do revisor
   - Para checklists personalizados, `[x]` significa que o revisor determinou que o critério de qualidade de requisitos foi satisfeito; NÃO significa que o trabalho de implementação está concluído
   - Examine todos os arquivos de checklist no diretório checklists/
   - Para cada checklist, conte:
     - Total de itens: Todas as linhas que correspondem a `- [ ]` ou `- [X]` ou `- [x]`
     - Itens marcados: Linhas que correspondem a `- [X]` ou `- [x]`
     - Itens não marcados: Linhas que correspondem a `- [ ]`
   - Crie uma tabela de status:

     ```text
     | Checklist | Total | Marcados | Não marcados | Status |
     |-----------|-------|----------|--------------|--------|
     | ux.md     | 12    | 12       | 0            | ✓ PASS |
     | test.md   | 8     | 5        | 3            | ✗ FAIL |
     | security.md | 6   | 6        | 0            | ✓ PASS |
     ```

   - Calcule o status geral:
     - **PASS**: Todos os checklists têm 0 itens não marcados
     - **FAIL**: Um ou mais checklists têm itens não marcados

   - **Se algum checklist tiver itens não marcados**:
     - Exiba a tabela com as contagens de itens não marcados
     - **PARE** e pergunte: "Alguns checklists têm itens não marcados. Deseja prosseguir com a implementação mesmo assim? (sim/não)"
     - Aguarde a resposta do usuário antes de continuar
     - Se o usuário disser "não", "espere" ou "pare", interrompa a execução
     - Se o usuário disser "sim", "prossiga" ou "continue", prossiga para o passo 3

   - **Se todos os checklists estiverem marcados**:
     - Exiba a tabela mostrando que todos os checklists passaram
     - Prossiga automaticamente para o passo 3

3. Carregue e analise o contexto de implementação:
   - **OBRIGATÓRIO**: Leia tasks.md para a lista completa de tarefas e o plano de execução
   - **OBRIGATÓRIO**: Leia plan.md para a stack técnica, arquitetura e estrutura de arquivos
   - **SE EXISTIR**: Leia data-model.md para entidades e relacionamentos
   - **SE EXISTIR**: Leia contracts/ para especificações de API e requisitos de teste
   - **SE EXISTIR**: Leia research.md para decisões técnicas e restrições
   - **SE EXISTIR**: Leia .specify/memory/constitution.md para restrições de governança
   - **SE EXISTIR**: Leia quickstart.md para cenários de integração

4. **Verificação da Configuração do Projeto**:
   - **OBRIGATÓRIO**: Crie/verifique os arquivos de ignore com base na configuração real do projeto:

   **Lógica de Detecção e Criação**:
   - Verifique se o comando a seguir é bem-sucedido para determinar se o repositório é um repositório git (crie/verifique .gitignore em caso positivo):

     ```sh
     git rev-parse --git-dir 2>/dev/null
     ```

   - Verifique se Dockerfile* existe ou se Docker aparece em plan.md → crie/verifique .dockerignore
   - Verifique se .eslintrc* existe → crie/verifique .eslintignore
   - Verifique se eslint.config.* existe → garanta que as entradas `ignores` da configuração cubram os padrões necessários
   - Verifique se .prettierrc* existe → crie/verifique .prettierignore
   - Verifique se .npmrc ou package.json existe → crie/verifique .npmignore (se for publicar)
   - Verifique se existem arquivos terraform (*.tf) → crie/verifique .terraformignore
   - Verifique se .helmignore é necessário (helm charts presentes) → crie/verifique .helmignore

   **Se o arquivo de ignore já existir**: Verifique se contém os padrões essenciais, acrescente apenas os padrões críticos ausentes
   **Se o arquivo de ignore estiver ausente**: Crie com o conjunto completo de padrões para a tecnologia detectada

   **Padrões Comuns por Tecnologia** (a partir da stack técnica em plan.md):
   - **Node.js/JavaScript/TypeScript**: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
   - **Python**: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `dist/`, `*.egg-info/`
   - **Java**: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
   - **C#/.NET**: `bin/`, `obj/`, `*.user`, `*.suo`, `packages/`
   - **Go**: `*.exe`, `*.test`, `vendor/`, `*.out`
   - **Ruby**: `.bundle/`, `log/`, `tmp/`, `*.gem`, `vendor/bundle/`
   - **PHP**: `vendor/`, `*.log`, `*.cache`, `*.env`
   - **Rust**: `target/`, `debug/`, `release/`, `*.rs.bk`, `*.rlib`, `*.prof*`, `.idea/`, `*.log`, `.env*`
   - **Kotlin**: `build/`, `out/`, `.gradle/`, `.idea/`, `*.class`, `*.jar`, `*.iml`, `*.log`, `.env*`
   - **C++**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.so`, `*.a`, `*.exe`, `*.dll`, `.idea/`, `*.log`, `.env*`
   - **C**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.a`, `*.so`, `*.exe`, `*.dll`, `autom4te.cache/`, `config.status`, `config.log`, `.idea/`, `*.log`, `.env*`
   - **Swift**: `.build/`, `DerivedData/`, `*.swiftpm/`, `Packages/`
   - **R**: `.Rproj.user/`, `.Rhistory`, `.RData`, `.Ruserdata`, `*.Rproj`, `packrat/`, `renv/`
   - **Universal**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`

   **Padrões Específicos de Ferramentas**:
   - **Docker**: `node_modules/`, `.git/`, `Dockerfile*`, `.dockerignore`, `*.log*`, `.env*`, `coverage/`
   - **ESLint**: `node_modules/`, `dist/`, `build/`, `coverage/`, `*.min.js`
   - **Prettier**: `node_modules/`, `dist/`, `build/`, `coverage/`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
   - **Terraform**: `.terraform/`, `*.tfstate*`, `*.tfvars`, `.terraform.lock.hcl`
   - **Kubernetes/k8s**: `*.secret.yaml`, `secrets/`, `.kube/`, `kubeconfig*`, `*.key`, `*.crt`

5. Interprete a estrutura de tasks.md e extraia:
   - **Fases de tarefas**: Configuração Inicial, Testes, Núcleo, Integração, Polimento
   - **Dependências de tarefas**: Regras de execução sequencial vs paralela
   - **Detalhes das tarefas**: ID, descrição, caminhos de arquivo, marcadores de paralelismo [P]
   - **Fluxo de execução**: Ordem e requisitos de dependência

6. Execute a implementação seguindo o plano de tarefas:
   - **Execução fase por fase**: Complete cada fase antes de passar para a próxima
   - **Respeite as dependências**: Execute tarefas sequenciais em ordem, tarefas paralelas [P] podem rodar juntas
   - **Siga a abordagem TDD**: Execute as tarefas de teste antes das tarefas de implementação correspondentes
   - **Coordenação baseada em arquivos**: Tarefas que afetam os mesmos arquivos devem rodar sequencialmente
   - **Pontos de verificação de validação**: Verifique a conclusão de cada fase antes de prosseguir

7. Regras de execução da implementação:
   - **Configuração Inicial primeiro**: Inicialize a estrutura do projeto, dependências, configuração
   - **Testes antes do código**: Se você precisar escrever testes para contratos, entidades e cenários de integração
   - **Desenvolvimento do núcleo**: Implemente modelos, serviços, comandos de CLI, endpoints
   - **Trabalho de integração**: Conexões com banco de dados, middleware, logging, serviços externos
   - **Polimento e validação**: Testes unitários, otimização de desempenho, documentação

8. Acompanhamento de progresso e tratamento de erros:
   - Reporte o progresso após cada tarefa concluída
   - Interrompa a execução se qualquer tarefa não paralela falhar
   - Para tarefas paralelas [P], continue com as tarefas bem-sucedidas e reporte as que falharam
   - Forneça mensagens de erro claras com contexto para depuração
   - Sugira próximos passos se a implementação não puder prosseguir
   - **IMPORTANTE** Para tarefas concluídas, certifique-se de marcar a tarefa como [X] no arquivo de tarefas.

9. Validação de conclusão:
   - Verifique se todas as tarefas obrigatórias foram concluídas
   - Verifique se as features implementadas correspondem à especificação original
   - Valide que os testes passam e a cobertura atende aos requisitos
   - Confirme que a implementação segue o plano técnico

Observação: Este comando presume que existe um detalhamento completo de tarefas em tasks.md. Se as tarefas estiverem incompletas ou ausentes, sugira executar `/speckit-tasks` primeiro para regenerar a lista de tarefas.

## Hooks Pós-Execução Obrigatórios

**Você DEVE completar esta seção antes de reportar a conclusão ao usuário.**

Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se não existir, ou se nenhum hook estiver registrado sob `hooks.after_implement`, pule para o Relatório de Conclusão.
- Se existir, leia-o e procure entradas sob a chave `hooks.after_implement`.
- Se o YAML não puder ser interpretado ou for inválido, não pule silenciosamente: informe ao usuário que `.specify/extensions.yml` não pôde ser lido (inclua o erro do parser) e que nenhum hook foi verificado, incluindo quaisquer hooks obrigatórios (`optional: false`) registrados ali, e então continue para o Relatório de Conclusão.
- Filtre os hooks em que `enabled` seja explicitamente `false`. Trate hooks sem o campo `enabled` como habilitados por padrão.
- Para cada hook restante, **não** tente interpretar ou avaliar expressões de `condition` do hook:
  - Se o hook não tiver o campo `condition`, ou ele for nulo/vazio, trate o hook como executável
  - Se o hook definir um `condition` não vazio, pule o hook e deixe a avaliação da condição para a implementação do HookExecutor
- Ao construir invocações de comando a partir dos nomes de comando dos hooks, substitua pontos (`.`) por hífens (`-`). Por exemplo, `speckit.git.commit` → `/speckit-git-commit`.
- Para cada hook executável, produza a saída abaixo conforme o flag `optional`:
  - **Hook obrigatório** (`optional: false`) — **Você DEVE emitir `EXECUTE_COMMAND:` para cada hook obrigatório**:
    ```
    ## Hooks de Extensão

    **Hook Automático**: {extension}
    Executando: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
    Após emitir o bloco acima você DEVE de fato invocar o hook e aguardar que ele termine antes de continuar. Execute-o da mesma forma que você executaria o comando neste agente/sessão (a invocação pode diferir do id literal `{command}` mostrado acima, por exemplo, um agente em modo skills o executa como `/skill:speckit-...` ou `$speckit-...`). Emitir o bloco sozinho não executa o hook.
  - **Hook opcional** (`optional: true`):
    ```
    ## Hooks de Extensão

    **Hook Opcional**: {extension}
    Comando: `/{command}`
    Descrição: {description}

    Prompt: {prompt}
    Para executar: `/{command}`
    ```

## Relatório de Conclusão

Reporte o status final com um resumo do trabalho concluído.

## Concluído Quando

- [ ] Todas as tarefas em tasks.md concluídas e marcadas com `[X]`
- [ ] Implementação validada contra a especificação, o plano e a cobertura de testes
- [ ] Hooks de extensão despachados ou pulados conforme as regras em Hooks Pós-Execução Obrigatórios acima
- [ ] Conclusão reportada ao usuário com resumo do trabalho concluído
