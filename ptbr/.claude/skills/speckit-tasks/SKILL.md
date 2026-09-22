---
name: "speckit-tasks"
description: "Gera um tasks.md acionável e ordenado por dependências para a feature, com base nos artefatos de design disponíveis."
argument-hint: "Restrições opcionais para a geração de tarefas"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/tasks.md"
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

**Verificar hooks de extensão (antes da geração de tarefas)**:
- Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se existir, leia-o e procure entradas sob a chave `hooks.before_tasks`
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

1. **Configuração**: Execute `.specify/scripts/powershell/setup-tasks.ps1 -Json` a partir da raiz do repositório e interprete FEATURE_DIR, TASKS_TEMPLATE_CONTENT, TASKS_TEMPLATE e a lista AVAILABLE_DOCS. `FEATURE_DIR` e `TASKS_TEMPLATE` devem ser caminhos absolutos quando fornecidos. `AVAILABLE_DOCS` é uma lista de nomes de documentos/caminhos relativos disponíveis sob `FEATURE_DIR` (por exemplo `research.md` ou `contracts/`). Para aspas simples em argumentos como "I'm Groot", use sintaxe de escape: por exemplo 'I'\''m Groot' (ou aspas duplas se possível: "I'm Groot").

2. **Carregar documentos de design**: Leia de FEATURE_DIR:
   - **Obrigatórios**: plan.md (stack técnica, bibliotecas, estrutura), spec.md (histórias de usuário com prioridades)
   - **Opcionais**: data-model.md (entidades), contracts/ (contratos de interface), research.md (decisões), quickstart.md (cenários de teste)
   - **SE EXISTIR**: Carregue `.specify/memory/constitution.md` para os princípios do projeto e restrições de governança
   - Observação: Nem todos os projetos têm todos os documentos. Gere as tarefas com base no que estiver disponível.

3. **Executar o fluxo de geração de tarefas**:
   - Carregue plan.md e extraia stack técnica, bibliotecas e estrutura do projeto
   - Carregue spec.md e extraia as histórias de usuário com suas prioridades (P1, P2, P3, etc.)
   - Se data-model.md existir: Extraia as entidades e mapeie-as para as histórias de usuário
   - Se contracts/ existir: Mapeie os contratos de interface para as histórias de usuário
   - Se research.md existir: Extraia as decisões para as tarefas de configuração inicial
   - Gere as tarefas organizadas por história de usuário (veja as Regras de Geração de Tarefas abaixo)
   - Gere o grafo de dependências mostrando a ordem de conclusão das histórias de usuário
   - Crie exemplos de execução paralela por história de usuário
   - Valide a completude das tarefas (cada história de usuário tem todas as tarefas necessárias, testável de forma independente)

4. **Gerar tasks.md**: Use TASKS_TEMPLATE_CONTENT (da saída JSON acima) como estrutura. Para compatibilidade com scripts de configuração mais antigos que omitem TASKS_TEMPLATE_CONTENT, leia TASKS_TEMPLATE em vez disso. Preencha com:
   - Nome correto da feature a partir de plan.md
   - Fase 1: Tarefas de Configuração Inicial (inicialização do projeto)
   - Fase 2: Tarefas Fundacionais (pré-requisitos bloqueantes para todas as histórias de usuário)
   - Fase 3+: Uma fase por história de usuário (em ordem de prioridade a partir de spec.md)
   - Cada fase inclui: objetivo da história, critérios de teste independente, testes (se solicitados), tarefas de implementação
   - Fase Final: Polimento e aspectos transversais
   - Todas as tarefas devem seguir o formato estrito de checklist (veja as Regras de Geração de Tarefas abaixo)
   - Caminhos de arquivo claros para cada tarefa
   - Seção de dependências mostrando a ordem de conclusão das histórias
   - Exemplos de execução paralela por história
   - Seção de estratégia de implementação (MVP primeiro, entrega incremental)

## Hooks Pós-Execução Obrigatórios

**Você DEVE completar esta seção antes de reportar a conclusão ao usuário.**

Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se não existir, ou se nenhum hook estiver registrado sob `hooks.after_tasks`, pule para o Relatório de Conclusão.
- Se existir, leia-o e procure entradas sob a chave `hooks.after_tasks`.
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

Informe o caminho do tasks.md gerado e um resumo:
- Total de tarefas
- Quantidade de tarefas por história de usuário
- Oportunidades de paralelismo identificadas
- Critérios de teste independente para cada história
- Escopo de MVP sugerido (normalmente apenas a História de Usuário 1)
- Validação de formato: Confirme que TODAS as tarefas seguem o formato de checklist (checkbox, ID, rótulos, caminhos de arquivo)

Contexto para a geração de tarefas: $ARGUMENTS

O tasks.md deve ser imediatamente executável - cada tarefa deve ser específica o suficiente para que um LLM consiga completá-la sem contexto adicional.

## Regras de Geração de Tarefas

**CRÍTICO**: As tarefas DEVEM ser organizadas por história de usuário para permitir implementação e teste independentes.

**Testes são OPCIONAIS**: Gere tarefas de teste apenas se forem explicitamente solicitadas na especificação da feature ou se o usuário pedir abordagem TDD.

### Formato de Checklist (OBRIGATÓRIO)

Toda tarefa DEVE seguir estritamente este formato:

```text
- [ ] [TaskID] [P?] [Story?] Descrição com caminho do arquivo
```

**Componentes do Formato**:

1. **Checkbox**: SEMPRE comece com `- [ ]` (checkbox markdown)
2. **ID da Tarefa**: Número sequencial (T001, T002, T003...) em ordem de execução
3. **Marcador [P]**: Inclua APENAS se a tarefa for paralelizável (arquivos diferentes, sem dependências de tarefas incompletas)
4. **Rótulo [Story]**: OBRIGATÓRIO apenas para tarefas das fases de história de usuário
   - Formato: [US1], [US2], [US3], etc. (mapeia para as histórias de usuário de spec.md)
   - Fase de Configuração Inicial: SEM rótulo de história
   - Fase Fundacional: SEM rótulo de história
   - Fases de História de Usuário: DEVEM ter rótulo de história
   - Fase de Polimento: SEM rótulo de história
5. **Descrição**: Ação clara com o caminho exato do arquivo

**Exemplos**:

- ✅ CORRETO: `- [ ] T001 Criar estrutura do projeto conforme o plano de implementação`
- ✅ CORRETO: `- [ ] T005 [P] Implementar middleware de autenticação em src/middleware/auth.py`
- ✅ CORRETO: `- [ ] T012 [P] [US1] Criar modelo User em src/models/user.py`
- ✅ CORRETO: `- [ ] T014 [US1] Implementar UserService em src/services/user_service.py`
- ❌ ERRADO: `- [ ] Criar modelo User` (faltam ID e rótulo de história)
- ❌ ERRADO: `T001 [US1] Criar modelo` (falta checkbox)
- ❌ ERRADO: `- [ ] [US1] Criar modelo User` (falta ID da tarefa)
- ❌ ERRADO: `- [ ] T001 [US1] Criar modelo` (falta caminho do arquivo)

### Organização das Tarefas

1. **A partir das Histórias de Usuário (spec.md)** - ORGANIZAÇÃO PRIMÁRIA:
   - Cada história de usuário (P1, P2, P3...) recebe sua própria fase
   - Mapeie todos os componentes relacionados para sua história:
     - Modelos necessários para aquela história
     - Serviços necessários para aquela história
     - Interfaces/UI necessárias para aquela história
     - Se testes forem solicitados: Testes específicos daquela história
   - Marque as dependências entre histórias (a maioria das histórias deveria ser independente)

2. **A partir dos Contratos**:
   - Mapeie cada contrato de interface → para a história de usuário que ele atende
   - Se testes forem solicitados: Cada contrato de interface → tarefa de teste de contrato [P] antes da implementação na fase daquela história

3. **A partir do Modelo de Dados**:
   - Mapeie cada entidade para a(s) história(s) de usuário que precisam dela
   - Se a entidade atende múltiplas histórias: Coloque na história mais antiga ou na fase de Configuração Inicial
   - Relacionamentos → tarefas da camada de serviço na fase da história apropriada
   - Para cada campo com restrições em data-model.md (tamanho máximo, nulável/obrigatório, valores de enum, regras de validação), cite a restrição literalmente na descrição da tarefa para que ela não fique a critério do momento da implementação

4. **A partir de Configuração Inicial/Infraestrutura**:
   - Infraestrutura compartilhada → fase de Configuração Inicial (Fase 1)
   - Tarefas fundacionais/bloqueantes → fase Fundacional (Fase 2)
   - Configuração específica de uma história → dentro da fase daquela história

### Estrutura de Fases

- **Fase 1**: Configuração Inicial (inicialização do projeto)
- **Fase 2**: Fundacional (pré-requisitos bloqueantes - DEVEM ser concluídos antes das histórias de usuário)
- **Fase 3+**: Histórias de Usuário em ordem de prioridade (P1, P2, P3...)
  - Dentro de cada história: Testes (se solicitados) → Modelos → Serviços → Endpoints → Integração
  - Cada fase deveria ser um incremento completo e testável de forma independente
- **Fase Final**: Polimento e Aspectos Transversais

## Concluído Quando

- [ ] tasks.md gerado com todas as fases, IDs de tarefa e caminhos de arquivo
- [ ] Hooks de extensão despachados ou pulados conforme as regras em Hooks Pós-Execução Obrigatórios acima
- [ ] Conclusão reportada ao usuário com total de tarefas, detalhamento por história e escopo de MVP
