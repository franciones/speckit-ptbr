---
name: "speckit-plan"
description: "Executa o fluxo de planejamento da implementação usando o template de plano para gerar os artefatos de design."
argument-hint: "Orientações opcionais para a fase de planejamento"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/plan.md"
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

**Verificar hooks de extensão (antes do planejamento)**:
- Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se existir, leia-o e procure entradas sob a chave `hooks.before_plan`
- Se o YAML não puder ser interpretado ou for inválido, não pule silenciosamente: informe ao usuário que `.specify/extensions.yml` não pôde ser lido (inclua o erro do parser) e que nenhum hook foi verificado, incluindo quaisquer hooks obrigatórios (`optional: false`) registrados ali, e então continue normalmente
- Filtre os hooks em que `enabled` é explicitamente `false`. Trate hooks sem o campo `enabled` como habilitados por padrão.
- Para cada hook restante, **não** tente interpretar ou avaliar expressões de `condition` do hook:
  - Se o hook não tiver o campo `condition`, ou ele for nulo/vazio, trate o hook como executável
  - Se o hook definir uma `condition` não vazia, pule o hook e deixe a avaliação da condição para a implementação do HookExecutor
- Ao construir invocações de comando a partir dos nomes de comando dos hooks, substitua pontos (`.`) por hífens (`-`). Por exemplo, `speckit.git.commit` → `/speckit-git-commit`.
- Para cada hook executável, produza a saída abaixo conforme o valor de `optional`:
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
    Após emitir o bloco acima você DEVE de fato invocar o hook e aguardar sua conclusão antes de continuar. Execute-o da mesma forma que você executaria o comando neste agente/sessão (a invocação pode diferir do id literal `{command}` mostrado acima, por exemplo um agente em modo skills o executa como `/skill:speckit-...` ou `$speckit-...`). Emitir o bloco sozinho não executa o hook.
- Se nenhum hook estiver registrado ou `.specify/extensions.yml` não existir, pule silenciosamente

## Roteiro

1. **Preparação**: Execute `.specify/scripts/powershell/setup-plan.ps1 -Json` a partir da raiz do repositório e interprete o JSON para obter FEATURE_SPEC, IMPL_PLAN, FEATURE_DIR, BRANCH. Para aspas simples em argumentos como "I'm Groot", use a sintaxe de escape: por exemplo 'I'\''m Groot' (ou aspas duplas se possível: "I'm Groot").

2. **Carregar contexto**: Leia FEATURE_SPEC e `.specify/memory/constitution.md`. Carregue o template IMPL_PLAN (já copiado).

3. **Executar o fluxo de planejamento**: Siga a estrutura do template IMPL_PLAN para:
   - Preencher o Contexto Técnico (marque as incógnitas como "NEEDS CLARIFICATION")
   - Preencher a seção Verificação da Constituição a partir da constituição
   - Avaliar os gates (ERRO se houver violações não justificadas)
   - Fase 0: Gerar research.md (resolver todos os NEEDS CLARIFICATION)
   - Fase 1: Gerar data-model.md, contracts/, quickstart.md
   - Reavaliar a Verificação da Constituição após o design

## Hooks Pós-Execução Obrigatórios

**Você DEVE concluir esta seção antes de reportar a conclusão ao usuário.**

Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se não existir, ou se nenhum hook estiver registrado sob `hooks.after_plan`, pule para o Relatório de Conclusão.
- Se existir, leia-o e procure entradas sob a chave `hooks.after_plan`.
- Se o YAML não puder ser interpretado ou for inválido, não pule silenciosamente: informe ao usuário que `.specify/extensions.yml` não pôde ser lido (inclua o erro do parser) e que nenhum hook foi verificado, incluindo quaisquer hooks obrigatórios (`optional: false`) registrados ali, e então continue para o Relatório de Conclusão.
- Filtre os hooks em que `enabled` é explicitamente `false`. Trate hooks sem o campo `enabled` como habilitados por padrão.
- Para cada hook restante, **não** tente interpretar ou avaliar expressões de `condition` do hook:
  - Se o hook não tiver o campo `condition`, ou ele for nulo/vazio, trate o hook como executável
  - Se o hook definir uma `condition` não vazia, pule o hook e deixe a avaliação da condição para a implementação do HookExecutor
- Ao construir invocações de comando a partir dos nomes de comando dos hooks, substitua pontos (`.`) por hífens (`-`). Por exemplo, `speckit.git.commit` → `/speckit-git-commit`.
- Para cada hook executável, produza a saída abaixo conforme o valor de `optional`:
  - **Hook obrigatório** (`optional: false`) — **Você DEVE emitir `EXECUTE_COMMAND:` para cada hook obrigatório**:
    ```
    ## Hooks de Extensão

    **Hook Automático**: {extension}
    Executando: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
    Após emitir o bloco acima você DEVE de fato invocar o hook e aguardar sua conclusão antes de continuar. Execute-o da mesma forma que você executaria o comando neste agente/sessão (a invocação pode diferir do id literal `{command}` mostrado acima, por exemplo um agente em modo skills o executa como `/skill:speckit-...` ou `$speckit-...`). Emitir o bloco sozinho não executa o hook.
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

O comando termina após o design da Fase 1. Reporte a branch, o caminho do IMPL_PLAN e os artefatos gerados.

## Fases

### Fase 0: Roteiro e Pesquisa

1. **Extrair incógnitas do Contexto Técnico** acima:
   - Para cada NEEDS CLARIFICATION → tarefa de pesquisa
   - Para cada dependência → tarefa de melhores práticas
   - Para cada integração → tarefa de padrões

2. **Gerar e despachar agentes de pesquisa**:

   ```text
   Para cada incógnita no Contexto Técnico:
     Tarefa: "Pesquisar {incógnita} para {contexto da feature}"
   Para cada escolha de tecnologia:
     Tarefa: "Encontrar melhores práticas para {tecnologia} em {domínio}"
   ```

3. **Consolidar as descobertas** em `research.md` usando o formato:
   - Decisão: [o que foi escolhido]
   - Justificativa: [por que foi escolhido]
   - Alternativas consideradas: [o que mais foi avaliado]

**Saída**: research.md com todos os NEEDS CLARIFICATION resolvidos

### Fase 1: Design e Contratos

**Pré-requisitos:** `research.md` concluído

1. **Extrair entidades da spec da feature** → `data-model.md`:
   - Nome da entidade, campos, relacionamentos
   - Regras de validação a partir dos requisitos
   - Transições de estado, se aplicável

2. **Definir contratos de interface** (se o projeto tiver interfaces externas) → `/contracts/`:
   - Identifique quais interfaces o projeto expõe a usuários ou a outros sistemas
   - Documente o formato de contrato apropriado para o tipo de projeto
   - Exemplos: APIs públicas para bibliotecas, schemas de comando para ferramentas CLI, endpoints para serviços web, gramáticas para parsers, contratos de UI para aplicações
   - Pule se o projeto for puramente interno (scripts de build, ferramentas pontuais etc.)

3. **Criar o guia de validação quickstart** → `quickstart.md`:
   - Documente cenários de validação executáveis que provem que a feature funciona de ponta a ponta
   - Inclua pré-requisitos, comandos de configuração, comandos de teste/execução e resultados esperados
   - Use links ou referências aos contratos e ao modelo de dados em vez de duplicá-los
   - Não inclua código de implementação completo, corpos de model/service/controller, migrations ou suítes de teste completas
   - Mantenha este artefato como guia de validação/execução; detalhes de implementação pertencem ao `tasks.md` e à fase de implementação

**Saída**: data-model.md, /contracts/*, quickstart.md

## Regras principais

- Use caminhos absolutos para operações no sistema de arquivos; use caminhos relativos ao projeto para referências na documentação
- ERRO em falhas de gate ou esclarecimentos não resolvidos

## Concluído Quando

- [ ] Fluxo de planejamento executado e artefatos de design gerados
- [ ] Hooks de extensão despachados ou pulados conforme as regras em Hooks Pós-Execução Obrigatórios acima
- [ ] Conclusão reportada ao usuário com branch, caminho do plano e artefatos gerados
