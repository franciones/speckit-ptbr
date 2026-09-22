# Constituição do Projeto [PROJECT_NAME]
<!-- Exemplo: Constituição do Spec, Constituição do TaskFlow etc. -->

## Princípios Fundamentais

### [PRINCIPLE_1_NAME]
<!-- Exemplo: I. Biblioteca Primeiro -->
[PRINCIPLE_1_DESCRIPTION]
<!-- Exemplo: Toda feature começa como uma biblioteca independente; Bibliotecas devem ser autocontidas, testáveis de forma independente e documentadas; Propósito claro obrigatório - nenhuma biblioteca apenas organizacional -->

### [PRINCIPLE_2_NAME]
<!-- Exemplo: II. Interface de CLI -->
[PRINCIPLE_2_DESCRIPTION]
<!-- Exemplo: Toda biblioteca expõe funcionalidade via CLI; Protocolo de texto: stdin/args → stdout, erros → stderr; Suporte a JSON + formato legível por humanos -->

### [PRINCIPLE_3_NAME]
<!-- Exemplo: III. Testes Primeiro (INEGOCIÁVEL) -->
[PRINCIPLE_3_DESCRIPTION]
<!-- Exemplo: TDD obrigatório: Testes escritos → Aprovados pelo usuário → Testes falham → Então implementar; Ciclo Red-Green-Refactor aplicado rigorosamente -->

### [PRINCIPLE_4_NAME]
<!-- Exemplo: IV. Testes de Integração -->
[PRINCIPLE_4_DESCRIPTION]
<!-- Exemplo: Áreas que exigem testes de integração: Testes de contrato de novas bibliotecas, Mudanças de contrato, Comunicação entre serviços, Schemas compartilhados -->

### [PRINCIPLE_5_NAME]
<!-- Exemplo: V. Observabilidade, VI. Versionamento e Mudanças Incompatíveis, VII. Simplicidade -->
[PRINCIPLE_5_DESCRIPTION]
<!-- Exemplo: E/S em texto garante depurabilidade; Logging estruturado obrigatório; Ou: formato MAJOR.MINOR.BUILD; Ou: Comece simples, princípios YAGNI -->

## [SECTION_2_NAME]
<!-- Exemplo: Restrições Adicionais, Requisitos de Segurança, Padrões de Desempenho etc. -->

[SECTION_2_CONTENT]
<!-- Exemplo: Requisitos de stack tecnológica, padrões de conformidade, políticas de deploy etc. -->

## [SECTION_3_NAME]
<!-- Exemplo: Fluxo de Desenvolvimento, Processo de Revisão, Gates de Qualidade etc. -->

[SECTION_3_CONTENT]
<!-- Exemplo: Requisitos de revisão de código, gates de teste, processo de aprovação de deploy etc. -->

## Idioma e Terminologia

Todo artefato gerado pelos comandos `/speckit-*` (especificações, planos, tarefas, checklists e relatórios) DEVE ser escrito em português do Brasil. Código-fonte, comentários de código, nomes de arquivos, caminhos, comandos, identificadores e mensagens de commit permanecem em inglês. Os termos técnicos listados no glossário de `CLAUDE.md` não são traduzidos. Os títulos de seção dos documentos seguem o mapa definido em `CLAUDE.md`.

## Governança
<!-- Exemplo: A constituição prevalece sobre todas as outras práticas; Emendas exigem documentação, aprovação e plano de migração -->

[GOVERNANCE_RULES]
<!-- Exemplo: Todos os PRs/revisões devem verificar conformidade; Complexidade deve ser justificada; Use [GUIDANCE_FILE] para orientação de desenvolvimento em tempo de execução -->

**Versão**: [CONSTITUTION_VERSION] | **Ratificada em**: [RATIFICATION_DATE] | **Última Emenda**: [LAST_AMENDED_DATE]
<!-- Exemplo: Versão: 2.1.1 | Ratificada em: 2025-06-13 | Última Emenda: 2025-07-16 -->
