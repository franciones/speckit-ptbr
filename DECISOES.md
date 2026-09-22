# Decisões de tradução

Registro das escolhas feitas ao traduzir os skills e templates. Serve para manter consistência nas
atualizações: o `translate-pending.ps1` instrui o modelo a preservar essas escolhas, e o revisor
humano usa esta lista como referência.

## Regras gerais

- Títulos de seção seguem o mapa em `ptbr/CLAUDE.md`. Templates e skills usam exatamente os mesmos títulos, porque um comando procura a seção que o outro gerou.
- Cada skill recebe o bloco "## Idioma de saída (obrigatório)" logo após o frontmatter.
- No frontmatter só os valores de `description` e `argument-hint` são traduzidos.
- `MUST` vira `DEVE`, `MUST NOT` vira `NÃO DEVE`, `SHOULD` vira `DEVERIA`, `MAY` vira `PODE`.
- Estrutura, ordem das seções, blocos de código, tabelas e comentários HTML são preservados.

## Tokens que ficam literais em inglês

- IDs: `T001`, `FR-001`, `SC-001`, `CHK001`, `US1`, `P1`
- Marcadores: `- [ ]`, `- [x]`, `[P]`, `[US1]`, `[NEEDS CLARIFICATION: ...]`
- Placeholders da constituição: `[PROJECT_NAME]`, `[PRINCIPLE_1_NAME]`, `[GOVERNANCE_RULES]` etc.
- Variáveis de fluxo dos skills: `SPEC_FILE`, `FEATURE_DIR`, `AVAILABLE_DOCS`, `TEMPLATE_CONTENT`, `SPECIFY_FEATURE_DIRECTORY`, `BRANCH_NAME`, `FEATURE_NUM`, `GIT_BRANCH_NAME`, `RATIFICATION_DATE`, `LAST_AMENDED_DATE`, `CONSTITUTION_VERSION`
- `TODO(<CAMPO>)` (só a dica interna é traduzida)
- Nomes de arquivo: `spec.md`, `plan.md`, `tasks.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/`, `checklists/requirements.md`
- `$ARGUMENTS`, chaves YAML/JSON, chaves `hooks.*`, comandos `/speckit-*`

## Bloco de saída dos hooks de extensão (todos os skills)

Título `## Hooks de Extensão`. Rótulos `**Pré-Hook Opcional**`, `**Pré-Hook Automático**`,
`**Hook Opcional**`, `**Hook Automático**`, `Comando:`, `Descrição:`, `Executando:`, `Para executar:`.
A linha `EXECUTE_COMMAND: {command}` e os placeholders `{extension}`, `{command}`, `{prompt}`,
`{description}` ficam literais.

## Por skill

**speckit-specify**
- O checklist `checklists/requirements.md` usa: "Checklist de Qualidade da Especificação", seções
  "Qualidade do Conteúdo", "Completude dos Requisitos", "Prontidão da Feature", "Observações".
- Opção de resposta "Custom" vira "Personalizada". Rótulos `Q1`, `Q2`, `Q3` ficam.
- Seção de encerramento "Próximas Ações" (mapa do CLAUDE.md).

**speckit-clarify**
- Seção inserida na spec: `## Esclarecimentos` com subseções `### Sessão YYYY-MM-DD`.
- Log de respostas: `- P: ... → R: ...` (era `Q:`/`A:`).
- Rótulos: `**Pergunta:**`, `**Recomendado:**`, `**Sugerido:**`.
- Palavras de gatilho do usuário: "sim", "recomendado", "sugerido", "pronto", "parar", "prosseguir".

**speckit-plan**
- Seções do plano: "Resumo", "Contexto Técnico", "Verificação da Constituição", "Estrutura do
  Projeto", "Rastreamento de Complexidade". Fases: "Fase 0", "Fase 1".

**speckit-tasks**
- Fases: `## Fase 1: Configuração Inicial (Infraestrutura Compartilhada)`, `## Fase 2: Fundacional
  (Pré-requisitos Bloqueantes)`, `## Fase 3: História de Usuário 1 - [Título] (Prioridade: P1) 🎯 MVP`,
  `## Fase N: Polimento e Aspectos Transversais`.
- Rótulos: `**Objetivo**`, `**Propósito**`, `**Teste Independente**`, `**Ponto de Verificação**`.
- Linha de tarefa mantém o formato `- [ ] T001 [P] [US1] Descrição em caminho/arquivo`.

**speckit-analyze**
- Relatório: `## Relatório de Análise da Especificação`. Colunas: ID, Categoria, Severidade,
  Localização(ões), Resumo, Recomendação. Severidades CRÍTICO/ALTO/MÉDIO/BAIXO.
- Exemplo de slug `user-can-upload-file` traduzido como `usuario-pode-enviar-arquivo` (é ilustrativo).

**speckit-checklist**
- "Unit Tests for English" traduzido como "Testes Unitários para o Texto dos Requisitos".
- Marcadores de rastreabilidade `[Gap]`, `[Ambiguity]`, `[Conflict]`, `[Assumption]`,
  `[Traceability]`, `[Spec §X.Y]` ficam em inglês. Rótulos de dimensão nos exemplos em prosa
  ([Completude], [Clareza] etc.) foram traduzidos.
- Argumento `-Template checklist-template` e nomes de arquivo de exemplo (`ux.md`, `security.md`) ficam.

**speckit-implement**
- Confirmação ao usuário em "(sim/não)"; aceita "sim/prossiga/continue" e "não/espere/pare".

**speckit-converge**
- Seção anexada ao tasks.md: `## Fase N: Convergência`.
- Tipos de lacuna (`missing`, `partial`, `contradicts`, `unrequested`), severidades
  (`CRITICAL`..`LOW`), resultados (`converged`, `tasks_appended`), `PASS`/`FAIL`, `Finding`,
  `source-ref`, `gap-type` ficam em inglês por serem tokens de saída.
- Colunas da tabela de achados: ID, Tipo de Lacuna, Severidade, Origem, Evidência, Trabalho Restante.

**speckit-constitution**
- Descrição de placeholder `[ALL_CAPS_IDENTIFIER]` rendida como `[IDENTIFICADOR_EM_MAIUSCULAS]`
  (é descritiva, não um token). Placeholders reais como `[PROJECT_NAME]` intactos.
- Constituição traduzida ganha a seção `## Idioma e Terminologia`, pré-preenchida.

**speckit-taskstoissues**
- Formato de título de issue `T001: <descrição>` mantido; descrições de exemplo em pt-BR.
