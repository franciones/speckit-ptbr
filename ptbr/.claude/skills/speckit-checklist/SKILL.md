---
name: "speckit-checklist"
description: "Gera um checklist personalizado para a feature atual com base nos requisitos do usuário."
argument-hint: "Domínio ou área de foco do checklist"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/checklist.md"
user-invocable: true
disable-model-invocation: false
---

## Idioma de saída (obrigatório)

Todo texto narrativo que este comando produzir (documentos, seções, perguntas, relatórios e respostas ao usuário) DEVE ser escrito em português do Brasil. Código, nomes de arquivos, caminhos, comandos, identificadores e os termos do glossário em `CLAUDE.md` permanecem em inglês. Use os títulos de seção definidos no mapa de `CLAUDE.md`.

## Propósito do Checklist: "Testes Unitários para o Texto dos Requisitos"

**CONCEITO CRÍTICO**: Checklists são **TESTES UNITÁRIOS PARA A ESCRITA DE REQUISITOS** - eles validam a qualidade, a clareza e a completude dos requisitos em um determinado domínio.

**NÃO servem para verificação/teste**:

- ❌ NÃO "Verificar se o botão clica corretamente"
- ❌ NÃO "Testar se o tratamento de erros funciona"
- ❌ NÃO "Confirmar que a API retorna 200"
- ❌ NÃO verificar se o código/implementação corresponde à spec

**SERVEM para validação da qualidade dos requisitos**:

- ✅ "Os requisitos de hierarquia visual estão definidos para todos os tipos de card?" (completude)
- ✅ "'Exibição em destaque' está quantificada com tamanho/posicionamento específicos?" (clareza)
- ✅ "Os requisitos de estado hover são consistentes em todos os elementos interativos?" (consistência)
- ✅ "Os requisitos de acessibilidade estão definidos para navegação por teclado?" (cobertura)
- ✅ "A spec define o que acontece quando a imagem do logo falha ao carregar?" (casos extremos)

**Metáfora**: Se a sua spec é código escrito em linguagem natural, o checklist é a sua suíte de testes unitários. Você está testando se os requisitos estão bem escritos, completos, sem ambiguidade e prontos para implementação - e NÃO se a implementação funciona.

**Propriedade e ciclo de vida das caixas de seleção**:

- Checklists personalizados gerados por este comando são artefatos de revisão da qualidade dos requisitos, de propriedade do revisor.
- `[x]` significa que o revisor determinou que o critério de qualidade do requisito está satisfeito.
- `[x]` NÃO significa que o trabalho de implementação está concluído.
- Este comando gera ou acrescenta itens de checklist; ele NÃO DEVE marcar os itens gerados como `[x]`.
- Um agente pode auxiliar na avaliação dos itens apenas quando explicitamente solicitado pelo revisor.
- `checklists/requirements.md` é um checklist embutido e separado de qualidade da spec, mantido por `/speckit-specify` e `/speckit-clarify`; não trate essa exceção como aplicável aos checklists personalizados gerados aqui.

## Entrada do Usuário

```text
$ARGUMENTS
```

Você **DEVE** considerar a entrada do usuário antes de prosseguir (se não estiver vazia).

## Verificações Pré-Execução

**Verificar hooks de extensão (antes da geração do checklist)**:
- Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se existir, leia-o e procure entradas sob a chave `hooks.before_checklist`
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

    Aguarde o resultado do comando do hook antes de prosseguir para as Etapas de Execução.
    ```
    Após emitir o bloco acima você DEVE de fato invocar o hook e aguardar sua conclusão antes de continuar. Execute-o da mesma forma que você executaria o comando neste agente/sessão (a invocação pode diferir do id literal `{command}` mostrado acima, por exemplo um agente em modo skills o executa como `/skill:speckit-...` ou `$speckit-...`). Emitir o bloco sozinho não executa o hook.
- Se nenhum hook estiver registrado ou `.specify/extensions.yml` não existir, pule silenciosamente

## Etapas de Execução

1. **Preparação**: Execute `.specify/scripts/powershell/check-prerequisites.ps1 -Json -Template checklist-template` a partir da raiz do repositório e interprete o JSON para obter FEATURE_DIR, a lista AVAILABLE_DOCS e TEMPLATE_CONTENT.
   - Todos os caminhos de arquivo devem ser absolutos.
   - Para aspas simples em argumentos como "I'm Groot", use a sintaxe de escape: por exemplo 'I'\''m Groot' (ou aspas duplas se possível: "I'm Groot").

2. **SE EXISTIR**: Carregue `.specify/memory/constitution.md` para obter os princípios do projeto e as restrições de governança.

3. **Esclarecer a intenção (dinâmico)**: Derive até TRÊS perguntas iniciais de esclarecimento contextuais (sem catálogo pré-definido). Elas DEVEM:
   - Ser geradas a partir da formulação do usuário + sinais extraídos de spec/plan/tasks
   - Perguntar apenas sobre informações que alterem materialmente o conteúdo do checklist
   - Ser puladas individualmente se já estiverem sem ambiguidade em `$ARGUMENTS`
   - Preferir precisão a abrangência

   Algoritmo de geração:
   1. Extraia sinais: palavras-chave do domínio da feature (por exemplo, autenticação, latência, UX, API), indicadores de risco ("crítico", "deve", "conformidade"), pistas de stakeholders ("QA", "revisão", "time de segurança") e entregáveis explícitos ("a11y", "rollback", "contratos").
   2. Agrupe os sinais em áreas de foco candidatas (máximo 4) classificadas por relevância.
   3. Identifique o público e o momento prováveis (autor, revisor, QA, release) se não estiverem explícitos.
   4. Detecte dimensões ausentes: abrangência do escopo, profundidade/rigor, ênfase em risco, limites de exclusão, critérios de aceitação mensuráveis.
   5. Formule perguntas escolhidas a partir destes arquétipos:
      - Refinamento de escopo (por exemplo, "Isso deve incluir pontos de integração com X e Y ou ficar limitado à correção do módulo local?")
      - Priorização de risco (por exemplo, "Quais destas áreas de risco potenciais devem receber verificações de gate obrigatórias?")
      - Calibração de profundidade (por exemplo, "Esta é uma lista leve de sanidade pré-commit ou um gate formal de release?")
      - Enquadramento de público (por exemplo, "Será usado apenas pelo autor ou por colegas durante a revisão de PR?")
      - Exclusão de fronteira (por exemplo, "Devemos excluir explicitamente itens de ajuste de desempenho nesta rodada?")
      - Lacuna de classe de cenário (por exemplo, "Nenhum fluxo de recuperação detectado — caminhos de rollback / falha parcial estão no escopo?")

   Regras de formatação das perguntas:
   - Se apresentar opções, gere uma tabela compacta com as colunas: Opção | Candidata | Por que Importa
   - Limite a no máximo opções A–E; omita a tabela se uma resposta livre for mais clara
   - Nunca peça ao usuário para repetir o que ele já disse
   - Evite categorias especulativas (sem alucinação). Se houver incerteza, pergunte explicitamente: "Confirme se X pertence ao escopo."

   Padrões quando a interação for impossível:
   - Profundidade: Padrão
   - Público: Revisor (PR) se relacionado a código; Autor caso contrário
   - Foco: Os 2 grupos mais relevantes

   Apresente as perguntas (rotule Q1/Q2/Q3). Após as respostas: se ≥2 classes de cenário (Alternativo / Exceção / Recuperação / domínio Não Funcional) permanecerem pouco claras, você PODE fazer até DUAS perguntas complementares direcionadas (Q4/Q5) com uma justificativa de uma linha cada (por exemplo, "Risco de caminho de recuperação não resolvido"). Não exceda cinco perguntas no total. Pule a escalada se o usuário recusar explicitamente mais perguntas.

4. **Entender a solicitação do usuário**: Combine `$ARGUMENTS` + respostas de esclarecimento:
   - Derive o tema do checklist (por exemplo, segurança, revisão, deploy, ux)
   - Consolide os itens obrigatórios explícitos mencionados pelo usuário
   - Mapeie as seleções de foco para a estrutura de categorias
   - Infira qualquer contexto ausente a partir de spec/plan/tasks (NÃO alucine)

5. **Carregar o contexto da feature**: Leia de FEATURE_DIR:
   - spec.md: Requisitos e escopo da feature
   - plan.md (se existir): Detalhes técnicos, dependências
   - tasks.md (se existir): Tarefas de implementação

   **Estratégia de Carregamento de Contexto**:
   - Carregue apenas as partes necessárias e relevantes para as áreas de foco ativas (evite despejar arquivos inteiros)
   - Prefira resumir seções longas em itens concisos de cenário/requisito
   - Use revelação progressiva: adicione buscas complementares apenas se lacunas forem detectadas
   - Se os documentos de origem forem grandes, gere itens de resumo intermediários em vez de incorporar texto bruto

6. **Gerar o checklist** - Use TEMPLATE_CONTENT como template estrutural e crie "Testes Unitários para Requisitos":
   - Crie o diretório `FEATURE_DIR/checklists/` se ele não existir
   - Gere um nome de arquivo único para o checklist:
     - Use um nome curto e descritivo baseado no domínio (por exemplo, `ux.md`, `api.md`, `security.md`)
     - Formato: `[domain].md`
   - Comportamento de manipulação de arquivos:
     - Se o arquivo NÃO existir: crie um novo arquivo e numere os itens a partir de CHK001
     - Se o arquivo existir: acrescente os novos itens ao arquivo existente, continuando a partir do último ID CHK (por exemplo, se o último item for CHK015, comece os novos itens em CHK016)
   - Nunca exclua ou substitua o conteúdo existente do checklist - sempre preserve e acrescente
   - Deixe todo item recém-gerado desmarcado (`[ ]`); o estado da caixa de seleção pertence ao revisor

   **PRINCÍPIO CENTRAL - Teste os Requisitos, Não a Implementação**:
   Todo item do checklist DEVE avaliar os PRÓPRIOS REQUISITOS quanto a:
   - **Completude**: Todos os requisitos necessários estão presentes?
   - **Clareza**: Os requisitos são específicos e sem ambiguidade?
   - **Consistência**: Os requisitos estão alinhados entre si?
   - **Mensurabilidade**: Os requisitos podem ser verificados objetivamente?
   - **Cobertura**: Todos os cenários/casos extremos estão contemplados?

   **Estrutura de Categorias** - Agrupe os itens por dimensões de qualidade dos requisitos:
   - **Completude dos Requisitos** (Todos os requisitos necessários estão documentados?)
   - **Clareza dos Requisitos** (Os requisitos são específicos e sem ambiguidade?)
   - **Consistência dos Requisitos** (Os requisitos se alinham sem conflitos?)
   - **Qualidade dos Critérios de Aceitação** (Os critérios de sucesso são mensuráveis?)
   - **Cobertura de Cenários** (Todos os fluxos/casos estão contemplados?)
   - **Cobertura de Casos Extremos** (As condições de fronteira estão definidas?)
   - **Requisitos Não Funcionais** (Desempenho, Segurança, Acessibilidade etc. - estão especificados?)
   - **Dependências e Premissas** (Estão documentadas e validadas?)
   - **Ambiguidades e Conflitos** (O que precisa de esclarecimento?)

   **COMO ESCREVER ITENS DE CHECKLIST - "Testes Unitários para o Texto dos Requisitos"**:

   ❌ **ERRADO** (Testando a implementação):
   - "Verificar se a landing page exibe 3 cards de episódio"
   - "Testar se os estados hover funcionam no desktop"
   - "Confirmar que o clique no logo navega para a home"

   ✅ **CORRETO** (Testando a qualidade dos requisitos):
   - "O número exato e o layout dos episódios em destaque estão especificados?" [Completude]
   - "'Exibição em destaque' está quantificada com tamanho/posicionamento específicos?" [Clareza]
   - "Os requisitos de estado hover são consistentes em todos os elementos interativos?" [Consistência]
   - "Os requisitos de navegação por teclado estão definidos para toda a UI interativa?" [Cobertura]
   - "O comportamento de fallback está especificado para quando a imagem do logo falhar ao carregar?" [Casos Extremos]
   - "Os estados de carregamento estão definidos para os dados assíncronos de episódios?" [Completude]
   - "A spec define a hierarquia visual para elementos de UI concorrentes?" [Clareza]

   **ESTRUTURA DO ITEM**:
   Cada item deve seguir este padrão:
   - Formato de pergunta sobre a qualidade do requisito
   - Foco no que está ESCRITO (ou não escrito) na spec/plano
   - Inclua a dimensão de qualidade entre colchetes [Completude/Clareza/Consistência/etc.]
   - Referencie a seção da spec `[Spec §X.Y]` ao verificar requisitos existentes
   - Use o marcador `[Gap]` ao verificar requisitos ausentes

   **EXEMPLOS POR DIMENSÃO DE QUALIDADE**:

   Completude:
   - "Os requisitos de tratamento de erros estão definidos para todos os modos de falha da API? [Gap]"
   - "Os requisitos de acessibilidade estão especificados para todos os elementos interativos? [Completude]"
   - "Os requisitos de breakpoint mobile estão definidos para layouts responsivos? [Gap]"

   Clareza:
   - "'Carregamento rápido' está quantificado com limites de tempo específicos? [Clareza, Spec §NFR-2]"
   - "Os critérios de seleção de 'episódios relacionados' estão explicitamente definidos? [Clareza, Spec §FR-5]"
   - "'Em destaque' está definido com propriedades visuais mensuráveis? [Ambiguidade, Spec §FR-4]"

   Consistência:
   - "Os requisitos de navegação estão alinhados em todas as páginas? [Consistência, Spec §FR-10]"
   - "Os requisitos do componente de card são consistentes entre a landing page e as páginas de detalhe? [Consistência]"

   Cobertura:
   - "Os requisitos estão definidos para cenários de estado zero (nenhum episódio)? [Cobertura, Caso Extremo]"
   - "Os cenários de interação simultânea de usuários estão contemplados? [Cobertura, Gap]"
   - "Os requisitos estão especificados para falhas parciais de carregamento de dados? [Cobertura, Fluxo de Exceção]"

   Mensurabilidade:
   - "Os requisitos de hierarquia visual são mensuráveis/testáveis? [Critérios de Aceitação, Spec §FR-1]"
   - "'Peso visual equilibrado' pode ser verificado objetivamente? [Mensurabilidade, Spec §FR-2]"

   **Classificação e Cobertura de Cenários** (Foco na Qualidade dos Requisitos):
   - Verifique se existem requisitos para cenários: Primário, Alternativo, Exceção/Erro, Recuperação, Não Funcional
   - Para cada classe de cenário, pergunte: "Os requisitos de [tipo de cenário] estão completos, claros e consistentes?"
   - Se uma classe de cenário estiver ausente: "Os requisitos de [tipo de cenário] foram intencionalmente excluídos ou estão faltando? [Gap]"
   - Inclua resiliência/rollback quando houver mutação de estado: "Os requisitos de rollback estão definidos para falhas de migration? [Gap]"

   **Requisitos de Rastreabilidade**:
   - MÍNIMO: ≥80% dos itens DEVEM incluir pelo menos uma referência de rastreabilidade
   - Cada item deve referenciar: a seção da spec `[Spec §X.Y]`, ou usar os marcadores: `[Gap]`, `[Ambiguity]`, `[Conflict]`, `[Assumption]`
   - Se não existir um sistema de IDs: "Existe um esquema de IDs de requisitos e critérios de aceitação estabelecido? [Traceability]"

   **Expor e Resolver Problemas** (Problemas de Qualidade dos Requisitos):
   Faça perguntas sobre os próprios requisitos:
   - Ambiguidades: "O termo 'rápido' está quantificado com métricas específicas? [Ambiguidade, Spec §NFR-1]"
   - Conflitos: "Os requisitos de navegação conflitam entre §FR-10 e §FR-10a? [Conflito]"
   - Premissas: "A premissa de 'API de podcast sempre disponível' está validada? [Premissa]"
   - Dependências: "Os requisitos da API externa de podcast estão documentados? [Dependência, Gap]"
   - Definições ausentes: "'Hierarquia visual' está definida com critérios mensuráveis? [Gap]"

   **Consolidação de Conteúdo**:
   - Limite flexível: Se os itens candidatos brutos forem > 40, priorize por risco/impacto
   - Mescle quase-duplicatas que verificam o mesmo aspecto do requisito
   - Se houver >5 casos extremos de baixo impacto, crie um único item: "Os casos extremos X, Y, Z estão contemplados nos requisitos? [Cobertura]"

   **🚫 ABSOLUTAMENTE PROIBIDO** - Isto transforma o item em teste de implementação, não de requisitos:
   - ❌ Qualquer item começando com "Verificar", "Testar", "Confirmar", "Checar" + comportamento da implementação
   - ❌ Referências à execução de código, ações do usuário, comportamento do sistema
   - ❌ "Exibe corretamente", "funciona adequadamente", "funciona como esperado"
   - ❌ "Clicar", "navegar", "renderizar", "carregar", "executar"
   - ❌ Casos de teste, planos de teste, procedimentos de QA
   - ❌ Detalhes de implementação (frameworks, APIs, algoritmos)

   **✅ PADRÕES OBRIGATÓRIOS** - Estes testam a qualidade dos requisitos:
   - ✅ "Os [tipo de requisito] estão definidos/especificados/documentados para [cenário]?"
   - ✅ "[termo vago] está quantificado/esclarecido com critérios específicos?"
   - ✅ "Os requisitos são consistentes entre [seção A] e [seção B]?"
   - ✅ "[requisito] pode ser medido/verificado objetivamente?"
   - ✅ "Os [casos extremos/cenários] estão contemplados nos requisitos?"
   - ✅ "A spec define [aspecto ausente]?"

7. **Referência de Estrutura**: Gere o checklist seguindo o template canônico em `.specify/templates/checklist-template.md` para título, seção de metadados, títulos de categoria, nota de propriedade, seção de observações e formatação de IDs. Se o template não estiver disponível, use: título H1, linhas de metadados de propósito/criação, uma nota de propriedade explicando que `[x]` significa aprovação do revisor quanto à qualidade dos requisitos, seções de categoria `##` contendo linhas `- [ ] CHK### <item de requisito>` com IDs incrementais globais começando em CHK001, e observações de que `/speckit-implement` lê o estado do checklist mas não modifica os marcadores.

8. **Relatório**: Apresente o caminho completo do arquivo de checklist, a contagem de itens, e resuma se a execução criou um novo arquivo ou acrescentou a um existente. Resuma:
   - Áreas de foco selecionadas
   - Nível de profundidade
   - Ator/momento
   - Quaisquer itens obrigatórios explicitamente especificados pelo usuário que foram incorporados

**Importante**: Cada invocação do comando `/speckit-checklist` usa um nome de arquivo de checklist curto e descritivo e cria um novo arquivo ou acrescenta a um existente. Isso permite:

- Múltiplos checklists de tipos diferentes (por exemplo, `ux.md`, `test.md`, `security.md`)
- Nomes de arquivo simples e memoráveis que indicam o propósito do checklist
- Identificação e navegação fáceis na pasta `checklists/`

Para evitar acúmulo, use tipos descritivos e limpe os checklists obsoletos quando terminar.

## Exemplos de Tipos de Checklist e Itens de Amostra

**Qualidade dos Requisitos de UX:** `ux.md`

Itens de amostra (testando os requisitos, NÃO a implementação):

- "Os requisitos de hierarquia visual estão definidos com critérios mensuráveis? [Clareza, Spec §FR-1]"
- "O número e o posicionamento dos elementos de UI estão explicitamente especificados? [Completude, Spec §FR-1]"
- "Os requisitos de estado de interação (hover, focus, active) estão definidos de forma consistente? [Consistência]"
- "Os requisitos de acessibilidade estão especificados para todos os elementos interativos? [Cobertura, Gap]"
- "O comportamento de fallback está definido para quando as imagens falharem ao carregar? [Caso Extremo, Gap]"
- "'Exibição em destaque' pode ser medida objetivamente? [Mensurabilidade, Spec §FR-4]"

**Qualidade dos Requisitos de API:** `api.md`

Itens de amostra:

- "Os formatos de resposta de erro estão especificados para todos os cenários de falha? [Completude]"
- "Os requisitos de rate limiting estão quantificados com limites específicos? [Clareza]"
- "Os requisitos de autenticação são consistentes em todos os endpoints? [Consistência]"
- "Os requisitos de retry/timeout estão definidos para dependências externas? [Cobertura, Gap]"
- "A estratégia de versionamento está documentada nos requisitos? [Gap]"

**Qualidade dos Requisitos de Desempenho:** `performance.md`

Itens de amostra:

- "Os requisitos de desempenho estão quantificados com métricas específicas? [Clareza]"
- "As metas de desempenho estão definidas para todas as jornadas críticas do usuário? [Cobertura]"
- "Os requisitos de desempenho sob diferentes condições de carga estão especificados? [Completude]"
- "Os requisitos de desempenho podem ser medidos objetivamente? [Mensurabilidade]"
- "Os requisitos de degradação estão definidos para cenários de alta carga? [Caso Extremo, Gap]"

**Qualidade dos Requisitos de Segurança:** `security.md`

Itens de amostra:

- "Os requisitos de autenticação estão especificados para todos os recursos protegidos? [Cobertura]"
- "Os requisitos de proteção de dados estão definidos para informações sensíveis? [Completude]"
- "O modelo de ameaças está documentado e os requisitos estão alinhados a ele? [Traceability]"
- "Os requisitos de segurança são consistentes com as obrigações de conformidade? [Consistência]"
- "Os requisitos de resposta a falhas/violações de segurança estão definidos? [Gap, Fluxo de Exceção]"

## Anti-Exemplos: O Que NÃO Fazer

**❌ ERRADO - Estes testam a implementação, não os requisitos:**

```markdown
- [ ] CHK001 - Verificar se a landing page exibe 3 cards de episódio [Spec §FR-001]
- [ ] CHK002 - Testar se os estados hover funcionam corretamente no desktop [Spec §FR-003]
- [ ] CHK003 - Confirmar que o clique no logo navega para a página inicial [Spec §FR-010]
- [ ] CHK004 - Checar que a seção de episódios relacionados mostra de 3 a 5 itens [Spec §FR-005]
```

**✅ CORRETO - Estes testam a qualidade dos requisitos:**

```markdown
- [ ] CHK001 - O número e o layout dos episódios em destaque estão explicitamente especificados? [Completude, Spec §FR-001]
- [ ] CHK002 - Os requisitos de estado hover estão definidos de forma consistente para todos os elementos interativos? [Consistência, Spec §FR-003]
- [ ] CHK003 - Os requisitos de navegação estão claros para todos os elementos de marca clicáveis? [Clareza, Spec §FR-010]
- [ ] CHK004 - Os critérios de seleção de episódios relacionados estão documentados? [Gap, Spec §FR-005]
- [ ] CHK005 - Os requisitos de estado de carregamento estão definidos para os dados assíncronos de episódios? [Gap]
- [ ] CHK006 - Os requisitos de "hierarquia visual" podem ser medidos objetivamente? [Mensurabilidade, Spec §FR-001]
```

**Diferenças-Chave:**

- Errado: Testa se o sistema funciona corretamente
- Correto: Testa se os requisitos estão escritos corretamente
- Errado: Verificação de comportamento
- Correto: Validação da qualidade do requisito
- Errado: "Ele faz X?"
- Correto: "X está claramente especificado?"

## Verificações Pós-Execução

**Verificar hooks de extensão (após a geração do checklist)**:
Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se existir, leia-o e procure entradas sob a chave `hooks.after_checklist`
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
    Após emitir o bloco acima você DEVE de fato invocar o hook e aguardar sua conclusão antes de continuar. Execute-o da mesma forma que você executaria o comando neste agente/sessão (a invocação pode diferir do id literal `{command}` mostrado acima, por exemplo um agente em modo skills o executa como `/skill:speckit-...` ou `$speckit-...`). Emitir o bloco sozinho não executa o hook.
- Se nenhum hook estiver registrado ou `.specify/extensions.yml` não existir, pule silenciosamente
