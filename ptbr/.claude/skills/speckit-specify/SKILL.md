---
name: "speckit-specify"
description: "Cria ou atualiza a especificação da feature a partir de uma descrição em linguagem natural."
argument-hint: "Descreva a feature que você quer especificar"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/specify.md"
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

**Verificar hooks de extensão (antes da especificação)**:
- Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se existir, leia-o e procure entradas sob a chave `hooks.before_specify`
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

O texto que o usuário digitou após `/speckit-specify` na mensagem de acionamento **é** a descrição da feature. Assuma que você sempre o tem disponível nesta conversa mesmo que `$ARGUMENTS` apareça literalmente abaixo. Não peça ao usuário para repeti-lo a menos que ele tenha fornecido um comando vazio.

Dada essa descrição da feature, faça o seguinte:

1. **Gere um nome curto e conciso** (2-4 palavras) para a feature:
   - Analise a descrição da feature e extraia as palavras-chave mais significativas
   - Crie um nome curto de 2-4 palavras que capture a essência da feature
   - Use o formato ação-substantivo quando possível (ex.: "add-user-auth", "fix-payment-bug")
   - Preserve termos técnicos e acrônimos (OAuth2, API, JWT, etc.)
   - Mantenha-o conciso, mas descritivo o suficiente para entender a feature de relance
   - Exemplos:
     - "Quero adicionar autenticação de usuários" → "user-auth"
     - "Implementar integração OAuth2 para a API" → "oauth2-api-integration"
     - "Criar um dashboard de analytics" → "analytics-dashboard"
     - "Corrigir bug de timeout no processamento de pagamento" → "fix-payment-timeout"

2. **Criação de branch** (opcional, via hook):

   Se um hook `before_specify` foi executado com sucesso nas Verificações Pré-Execução acima, ele terá criado/alternado para uma branch git e produzido JSON contendo `BRANCH_NAME` e `FEATURE_NUM`. Anote esses valores para referência, mas o nome da branch **não** determina o nome do diretório da spec.

   Se o usuário forneceu explicitamente `GIT_BRANCH_NAME`, repasse-o ao hook para que o script de branch use exatamente esse valor como nome da branch (ignorando toda a geração de prefixo/sufixo).

3. **Crie o diretório da feature da spec**:

   As specs ficam sob o diretório padrão `specs/` a menos que o usuário forneça explicitamente `SPECIFY_FEATURE_DIRECTORY`.

   **Ordem de resolução para `SPECIFY_FEATURE_DIRECTORY`**:
   1. Se o usuário forneceu explicitamente `SPECIFY_FEATURE_DIRECTORY` (ex.: via variável de ambiente, argumento ou configuração), use-o como está
   2. Caso contrário, gere-o automaticamente sob `specs/`:
      - Verifique `.specify/init-options.json` em busca de `feature_numbering` (preferido) ou `branch_numbering` (descontinuado, apenas para migração — será removido em uma versão futura)
      - Se `"timestamp"`: o prefixo é `YYYYMMDD-HHMMSS` (timestamp atual)
      - Se `"sequential"` ou ausente: o prefixo é `NNN` (próximo número de 3 dígitos disponível após varrer os diretórios existentes em `specs/`)
      - Construa o nome do diretório: `<prefixo>-<nome-curto>` (ex.: `003-user-auth` ou `20260319-143022-user-auth`)
      - Defina `SPECIFY_FEATURE_DIRECTORY` como `specs/<nome-do-diretorio>`
      - Se `branch_numbering` foi usado (e `feature_numbering` estava ausente), emita um aviso de uma linha: "⚠️ `branch_numbering` em init-options.json está descontinuado. Renomeie para `feature_numbering`."

   **Crie o diretório e o arquivo da spec**:
   - `mkdir -p SPECIFY_FEATURE_DIRECTORY`
   - Resolva o `spec-template` ativo através da pilha de resolução de preset/template do Spec Kit (equivalente a `specify preset resolve spec-template`)
   - Copie o arquivo `spec-template` resolvido para `SPECIFY_FEATURE_DIRECTORY/spec.md` como ponto de partida
   - Defina `SPEC_FILE` como `SPECIFY_FEATURE_DIRECTORY/spec.md`
   - Persista o caminho resolvido em `.specify/feature.json`:
     ```json
     {
       "feature_directory": "<diretório da feature resolvido>"
     }
     ```
     Escreva o valor real do caminho do diretório resolvido (por exemplo, `specs/003-user-auth`), não a string literal `SPECIFY_FEATURE_DIRECTORY`.
     Isso permite que comandos subsequentes (`/speckit-plan`, `/speckit-tasks`, etc.) localizem o diretório da feature sem depender de convenções de nome de branch git.

   **IMPORTANTE**:
   - Você deve criar apenas uma feature por invocação de `/speckit-specify`
   - O nome do diretório da spec e o nome da branch git são independentes — podem ser iguais, mas isso é escolha do usuário
   - O diretório e o arquivo da spec são sempre criados por este comando, nunca pelo hook

4. Carregue o arquivo `spec-template` ativo resolvido para entender as seções obrigatórias.

5. **SE EXISTIR**: Carregue `.specify/memory/constitution.md` para obter os princípios do projeto e as restrições de governança.

6. Siga este fluxo de execução:
    1. Interprete a descrição do usuário a partir dos argumentos
       Se vazia: ERRO "Nenhuma descrição de feature fornecida"
    2. Extraia os conceitos-chave da descrição
       Identifique: atores, ações, dados, restrições
    3. Para aspectos pouco claros:
       - Faça suposições fundamentadas com base no contexto e em padrões da indústria
       - Marque com [NEEDS CLARIFICATION: pergunta específica] apenas se:
         - A escolha impacta significativamente o escopo da feature ou a experiência do usuário
         - Existem múltiplas interpretações razoáveis com implicações diferentes
         - Não existe um padrão razoável
       - **LIMITE: Máximo de 3 marcadores [NEEDS CLARIFICATION] no total**
       - Priorize os esclarecimentos por impacto: escopo > segurança/privacidade > experiência do usuário > detalhes técnicos
    4. Preencha a seção Cenários de Usuário e Testes
       Se não houver fluxo de usuário claro: ERRO "Não é possível determinar os cenários de usuário"
    5. Gere os Requisitos Funcionais
       Cada requisito deve ser testável
       Use padrões razoáveis para detalhes não especificados (documente as premissas na seção Premissas)
    6. Defina os Critérios de Sucesso
       Crie resultados mensuráveis e independentes de tecnologia
       Inclua tanto métricas quantitativas (tempo, desempenho, volume) quanto medidas qualitativas (satisfação do usuário, conclusão de tarefas)
       Cada critério deve ser verificável sem detalhes de implementação
    7. Identifique as Entidades Principais (se houver dados envolvidos)
    8. Retorne: SUCESSO (spec pronta para planejamento)

7. Escreva a especificação em SPEC_FILE usando a estrutura do template, substituindo os placeholders por detalhes concretos derivados da descrição da feature (argumentos) e preservando a ordem das seções e os títulos.

8. **Validação de Qualidade da Especificação**: Após escrever a spec inicial, valide-a contra os critérios de qualidade:

   a. **Crie o Checklist de Qualidade da Spec**: Gere um arquivo de checklist em `SPECIFY_FEATURE_DIRECTORY/checklists/requirements.md` usando a estrutura do template de checklist com estes itens de validação:

      ```markdown
      # Checklist de Qualidade da Especificação: [NOME DA FEATURE]

      **Propósito**: Validar a completude e a qualidade da especificação antes de prosseguir para o planejamento
      **Criado em**: [DATA]
      **Feature**: [Link para spec.md]

      ## Qualidade do Conteúdo

      - [ ] Sem detalhes de implementação (linguagens, frameworks, APIs)
      - [ ] Focada no valor para o usuário e nas necessidades do negócio
      - [ ] Escrita para stakeholders não técnicos
      - [ ] Todas as seções obrigatórias preenchidas

      ## Completude dos Requisitos

      - [ ] Nenhum marcador [NEEDS CLARIFICATION] restante
      - [ ] Requisitos são testáveis e não ambíguos
      - [ ] Critérios de sucesso são mensuráveis
      - [ ] Critérios de sucesso são independentes de tecnologia (sem detalhes de implementação)
      - [ ] Todos os cenários de aceitação estão definidos
      - [ ] Casos extremos estão identificados
      - [ ] Escopo está claramente delimitado
      - [ ] Dependências e premissas identificadas

      ## Prontidão da Feature

      - [ ] Todos os requisitos funcionais têm critérios de aceitação claros
      - [ ] Cenários de usuário cobrem os fluxos principais
      - [ ] Feature atende aos resultados mensuráveis definidos em Critérios de Sucesso
      - [ ] Nenhum detalhe de implementação vaza para a especificação

      ## Observações

      - Itens marcados como incompletos exigem atualizações na spec antes de `/speckit-clarify` ou `/speckit-plan`
      ```

   b. **Execute a Verificação de Validação**: Revise a spec contra cada item do checklist:
      - Para cada item, determine se passa ou falha
      - Documente os problemas específicos encontrados (cite as seções relevantes da spec)

   c. **Trate os Resultados da Validação**:

      - **Se todos os itens passarem**: Marque o checklist como completo e prossiga para a seção Hooks Pós-Execução Obrigatórios

      - **Se houver itens falhando (excluindo [NEEDS CLARIFICATION])**:
        1. Liste os itens que falharam e os problemas específicos
        2. Atualize a spec para resolver cada problema
        3. Execute novamente a validação até que todos os itens passem (máximo de 3 iterações)
        4. Se ainda falhar após 3 iterações, documente os problemas restantes nas observações do checklist e avise o usuário

      - **Se restarem marcadores [NEEDS CLARIFICATION]**:
        1. Extraia todos os marcadores [NEEDS CLARIFICATION: ...] da spec
        2. **VERIFICAÇÃO DE LIMITE**: Se existirem mais de 3 marcadores, mantenha apenas os 3 mais críticos (por impacto em escopo/segurança/UX) e faça suposições fundamentadas para o restante
        3. Para cada esclarecimento necessário (máx. 3), apresente as opções ao usuário neste formato:

           ```markdown
           ## Pergunta [N]: [Tópico]

           **Contexto**: [Cite a seção relevante da spec]

           **O que precisamos saber**: [Pergunta específica do marcador NEEDS CLARIFICATION]

           **Respostas Sugeridas**:

           | Opção | Resposta | Implicações |
           |-------|----------|-------------|
           | A     | [Primeira resposta sugerida] | [O que isso significa para a feature] |
           | B     | [Segunda resposta sugerida] | [O que isso significa para a feature] |
           | C     | [Terceira resposta sugerida] | [O que isso significa para a feature] |
           | Personalizada | Forneça sua própria resposta | [Explique como fornecer uma entrada personalizada] |

           **Sua escolha**: _[Aguarde a resposta do usuário]_
           ```

        4. **CRÍTICO - Formatação de Tabelas**: Garanta que as tabelas markdown estejam formatadas corretamente:
           - Use espaçamento consistente com os pipes alinhados
           - Cada célula deve ter espaços ao redor do conteúdo: `| Conteúdo |` e não `|Conteúdo|`
           - O separador do cabeçalho deve ter pelo menos 3 traços: `|--------|`
           - Teste se a tabela renderiza corretamente no preview de markdown
        5. Numere as perguntas sequencialmente (Q1, Q2, Q3 - máx. 3 no total)
        6. Apresente todas as perguntas juntas antes de aguardar as respostas
        7. Aguarde o usuário responder com suas escolhas para todas as perguntas (ex.: "Q1: A, Q2: Personalizada - [detalhes], Q3: B")
        8. Atualize a spec substituindo cada marcador [NEEDS CLARIFICATION] pela resposta selecionada ou fornecida pelo usuário
        9. Execute novamente a validação após todos os esclarecimentos serem resolvidos

   d. **Atualize o Checklist**: Após cada iteração de validação, atualize o arquivo de checklist com o status atual de aprovação/falha

## Hooks Pós-Execução Obrigatórios

**Você DEVE completar esta seção antes de relatar a conclusão ao usuário.**

Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se não existir, ou se nenhum hook estiver registrado sob `hooks.after_specify`, pule para o Relatório de Conclusão.
- Se existir, leia-o e procure entradas sob a chave `hooks.after_specify`.
- Se o YAML não puder ser interpretado ou for inválido, não pule silenciosamente: informe ao usuário que `.specify/extensions.yml` não pôde ser lido (inclua o erro do parser) e que nenhum hook foi verificado, incluindo quaisquer hooks obrigatórios (`optional: false`) registrados ali, e então continue para o Relatório de Conclusão.
- Descarte hooks cujo `enabled` seja explicitamente `false`. Trate hooks sem o campo `enabled` como habilitados por padrão.
- Para cada hook restante, **não** tente interpretar ou avaliar expressões de `condition` do hook:
  - Se o hook não tiver campo `condition`, ou ele for nulo/vazio, trate o hook como executável
  - Se o hook definir um `condition` não vazio, pule o hook e deixe a avaliação da condição para a implementação do HookExecutor
- Ao construir invocações de comando a partir dos nomes de comando dos hooks, substitua pontos (`.`) por hífens (`-`). Por exemplo, `speckit.git.commit` → `/speckit-git-commit`.
- Para cada hook executável, produza a saída abaixo conforme seu flag `optional`:
  - **Hook obrigatório** (`optional: false`) — **Você DEVE emitir `EXECUTE_COMMAND:` para cada hook obrigatório**:
    ```
    ## Hooks de Extensão

    **Hook Automático**: {extension}
    Executando: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
    Após emitir o bloco acima você DEVE de fato invocar o hook e aguardar sua conclusão antes de continuar. Execute-o da mesma forma que você executaria o comando neste agente/sessão (a invocação pode diferir do id literal `{command}` mostrado acima, por exemplo, um agente em modo skills o executa como `/skill:speckit-...` ou `$speckit-...`). Emitir o bloco sozinho não executa o hook.
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

Relate a conclusão ao usuário com:
- `SPECIFY_FEATURE_DIRECTORY` — o caminho do diretório da feature
- `SPEC_FILE` — o caminho do arquivo da spec
- Resumo dos resultados do checklist
- Prontidão para a próxima fase (`/speckit-clarify` ou `/speckit-plan`)

**OBSERVAÇÃO:** A criação da branch é tratada pelo hook `before_specify` (extensão git). A criação do diretório e do arquivo da spec é sempre tratada por este comando principal.

## Diretrizes Rápidas

- Foque em **O QUE** os usuários precisam e **POR QUÊ**.
- Evite COMO implementar (sem stack tecnológica, APIs, estrutura de código).
- Escrita para stakeholders de negócio, não para desenvolvedores.
- NÃO crie checklists embutidos na spec. Isso será um comando separado.

### Requisitos das Seções

- **Seções obrigatórias**: Devem ser preenchidas para toda feature
- **Seções opcionais**: Inclua apenas quando relevantes para a feature
- Quando uma seção não se aplicar, remova-a inteiramente (não deixe como "N/A")

### Para Geração por IA

Ao criar esta spec a partir de um prompt do usuário:

1. **Faça suposições fundamentadas**: Use o contexto, padrões da indústria e padrões comuns para preencher lacunas
2. **Documente as premissas**: Registre os padrões razoáveis na seção Premissas
3. **Limite os esclarecimentos**: Máximo de 3 marcadores [NEEDS CLARIFICATION] - use apenas para decisões críticas que:
   - Impactem significativamente o escopo da feature ou a experiência do usuário
   - Tenham múltiplas interpretações razoáveis com implicações diferentes
   - Não tenham nenhum padrão razoável
4. **Priorize os esclarecimentos**: escopo > segurança/privacidade > experiência do usuário > detalhes técnicos
5. **Pense como um testador**: Todo requisito vago deve falhar no item "testável e não ambíguo" do checklist
6. **Áreas comuns que precisam de esclarecimento** (apenas se não existir padrão razoável):
   - Escopo e limites da feature (incluir/excluir casos de uso específicos)
   - Tipos de usuário e permissões (se houver múltiplas interpretações conflitantes possíveis)
   - Requisitos de segurança/conformidade (quando legal ou financeiramente significativos)

**Exemplos de padrões razoáveis** (não pergunte sobre estes):

- Retenção de dados: Práticas padrão da indústria para o domínio
- Metas de desempenho: Expectativas padrão de aplicações web/mobile, salvo especificação em contrário
- Tratamento de erros: Mensagens amigáveis ao usuário com fallbacks apropriados
- Método de autenticação: Padrão baseado em sessão ou OAuth2 para aplicações web
- Padrões de integração: Use padrões apropriados ao projeto (REST/GraphQL para serviços web, chamadas de função para bibliotecas, argumentos de CLI para ferramentas, etc.)

### Diretrizes para Critérios de Sucesso

Os critérios de sucesso devem ser:

1. **Mensuráveis**: Incluir métricas específicas (tempo, percentual, contagem, taxa)
2. **Independentes de tecnologia**: Sem menção a frameworks, linguagens, bancos de dados ou ferramentas
3. **Focados no usuário**: Descrever resultados da perspectiva do usuário/negócio, não dos internos do sistema
4. **Verificáveis**: Podem ser testados/validados sem conhecer detalhes de implementação

**Bons exemplos**:

- "Usuários conseguem concluir o checkout em menos de 3 minutos"
- "Sistema suporta 10.000 usuários simultâneos"
- "95% das buscas retornam resultados em menos de 1 segundo"
- "Taxa de conclusão de tarefas melhora em 40%"

**Maus exemplos** (focados em implementação):

- "Tempo de resposta da API é inferior a 200ms" (técnico demais, use "Usuários veem os resultados instantaneamente")
- "Banco de dados suporta 1000 TPS" (detalhe de implementação, use uma métrica voltada ao usuário)
- "Componentes React renderizam de forma eficiente" (específico de framework)
- "Taxa de acerto do cache Redis acima de 80%" (específico de tecnologia)

## Concluído Quando

- [ ] Especificação escrita em `SPEC_FILE` e validada contra o checklist de qualidade
- [ ] Hooks de extensão despachados ou pulados conforme as regras em Hooks Pós-Execução Obrigatórios acima
- [ ] Conclusão relatada ao usuário com o diretório da feature, o caminho do arquivo da spec e os resultados do checklist
