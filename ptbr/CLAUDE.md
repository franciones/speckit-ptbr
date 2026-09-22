# Diretrizes do Projeto para o Claude Code

## Idioma de saída (regra obrigatória)

- Todo texto narrativo produzido pelos comandos `/speckit-*` (especificações, planos, tarefas, checklists, relatórios, perguntas de esclarecimento e respostas ao usuário) DEVE ser escrito em **português do Brasil**.
- Esta regra vale para TODOS os comandos da cadeia: `/speckit-constitution`, `/speckit-specify`, `/speckit-clarify`, `/speckit-plan`, `/speckit-tasks`, `/speckit-analyze`, `/speckit-checklist`, `/speckit-implement`, `/speckit-converge` e `/speckit-taskstoissues`. Nunca volte ao inglês em etapas posteriores.
- Permanecem em inglês: código-fonte, comentários de código, nomes de arquivos, caminhos, comandos de terminal, identificadores, chaves YAML/JSON, nomes de branch, mensagens de commit e os termos do glossário abaixo.
- Quando um template estiver em português, preencha-o em português. Quando um documento anterior (spec, plan, tasks) estiver em português, mantenha o mesmo idioma e os mesmos títulos de seção.

## Glossário: termos que permanecem em inglês

Use estes termos sem traduzir, para evitar ambiguidade entre spec e código:

`feature`, `branch`, `commit`, `merge`, `pull request` / `PR`, `issue`, `endpoint`, `API`, `CLI`, `deploy`, `build`, `release`, `backend`, `frontend`, `log`, `script`, `template`, `hook`, `checklist`, `MVP`, `framework`, `pipeline`, `schema`, `token`, `cache`, `mock`, `stub`, `runtime`, `middleware`, `worktree`, `spec` (quando se referir ao arquivo `spec.md`).

Termos que SÃO traduzidos: requisito, história de usuário, critério de aceitação, plano, tarefa, fase, premissa, esclarecimento, entidade, cenário, refatoração, teste.

## Marcadores e identificadores que nunca mudam

Os comandos e scripts procuram por estes tokens literalmente. Mantenha-os exatamente assim:

- IDs: `T001`, `FR-001`, `SC-001`, `CHK001`, `US1`, `P1`
- Marcadores de tarefa: `- [ ]`, `- [x]`, `[P]`, `[US1]`
- Marcador de dúvida: `[NEEDS CLARIFICATION: ...]`
- Placeholders da constituição: `[PROJECT_NAME]`, `[PRINCIPLE_1_NAME]` etc.
- Variável de entrada: `$ARGUMENTS`
- Nomes de arquivo: `spec.md`, `plan.md`, `tasks.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/`, `checklists/requirements.md`

## Mapa de títulos de seção (inglês → português)

Os comandos referenciam seções pelo título. Use sempre estes títulos nos documentos gerados:

| Inglês (upstream) | Português (este projeto) |
|---|---|
| Feature Specification | Especificação da Funcionalidade |
| Feature Branch / Created / Status / Input | Branch da Funcionalidade / Criado em / Status / Entrada |
| Draft | Rascunho |
| User Scenarios & Testing | Cenários de Usuário e Testes |
| User Story N - [Title] (Priority: P1) | História de Usuário N - [Título] (Prioridade: P1) |
| Why this priority | Por que esta prioridade |
| Independent Test | Teste Independente |
| Acceptance Scenarios | Cenários de Aceitação |
| Given / When / Then | Dado / Quando / Então |
| Edge Cases | Casos Extremos |
| Requirements | Requisitos |
| Functional Requirements | Requisitos Funcionais |
| Key Entities | Entidades Principais |
| Success Criteria | Critérios de Sucesso |
| Measurable Outcomes | Resultados Mensuráveis |
| Assumptions | Premissas |
| Clarifications | Esclarecimentos |
| Session YYYY-MM-DD | Sessão YYYY-MM-DD |
| Implementation Plan | Plano de Implementação |
| Summary | Resumo |
| Technical Context | Contexto Técnico |
| Constitution Check | Verificação da Constituição |
| Project Structure | Estrutura do Projeto |
| Documentation (this feature) | Documentação (esta feature) |
| Source Code (repository root) | Código-fonte (raiz do repositório) |
| Structure Decision | Decisão de Estrutura |
| Complexity Tracking | Rastreamento de Complexidade |
| Tasks | Tarefas |
| Phase N | Fase N |
| Setup (Shared Infrastructure) | Configuração Inicial (Infraestrutura Compartilhada) |
| Foundational (Blocking Prerequisites) | Fundacional (Pré-requisitos Bloqueantes) |
| Polish & Cross-Cutting Concerns | Polimento e Aspectos Transversais |
| Dependencies & Execution Order | Dependências e Ordem de Execução |
| Implementation Strategy | Estratégia de Implementação |
| Checkpoint | Ponto de Verificação |
| Goal | Objetivo |
| Purpose | Propósito |
| Notes | Observações |
| Constitution | Constituição |
| Core Principles | Princípios Fundamentais |
| Governance | Governança |
| Version / Ratified / Last Amended | Versão / Ratificada em / Última Emenda |
| Next Actions | Próximas Ações |
| MUST / MUST NOT / SHOULD / MAY | DEVE / NÃO DEVE / DEVERIA / PODE |
