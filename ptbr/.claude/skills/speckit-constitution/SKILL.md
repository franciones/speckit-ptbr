---
name: "speckit-constitution"
description: "Cria ou atualiza a constituição do projeto a partir de princípios fornecidos ou coletados interativamente."
argument-hint: "Princípios ou valores para a constituição do projeto"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/constitution.md"
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

## Guarda de Escopo

O trabalho deste comando limita-se a atualizar a própria constituição do projeto. Templates e
comandos dependentes leem a constituição em tempo de execução e não são modificados aqui.

- Classifique cada parte da entrada do usuário como conteúdo da constituição ou como uma
  intenção separada, não relacionada a governança.
- Se a entrada incluir pedidos de implementação de feature, geração de código, refatoração, build ou
  deploy, você **NÃO DEVE** executá-los. Em vez disso, extraia-os como intenções adiadas.
- Você **NÃO DEVE** criar, modificar ou excluir arquivos-fonte da aplicação, rotas de feature,
  componentes, testes, arquivos de deploy ou outros artefatos não relacionados ao fluxo da
  constituição.
- Se não estiver claro se uma instrução é conteúdo da constituição, peça esclarecimento antes de
  fazer alterações.
- Após concluir a atualização da constituição, inclua uma seção `Próximas Ações` para cada intenção
  adiada. Liste a intenção original e sugira o comando Spec Kit apropriado para dar sequência, como
  `/speckit-specify`, sem invocá-lo.
- Se não houver intenções não relacionadas a governança, omita a seção `Próximas Ações`.

## Verificações Pré-Execução

**Verificar hooks de extensão (antes da atualização da constituição)**:
- Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se existir, leia-o e procure entradas sob a chave `hooks.before_constitution`
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

Você está atualizando a constituição do projeto em `.specify/memory/constitution.md`. O esqueleto
ativo da constituição é resolvido no momento do comando a partir de `constitution-template` através da
pilha de resolução de preset/template do Spec Kit.

Siga este fluxo de execução:

1. Execute `.specify/scripts/powershell/resolve-template.ps1 constitution-template -Json` a partir da raiz do repositório e interprete `TEMPLATE_CONTENT` como o template ativo.
   - O resolvedor compartilhado aplica sobrescritas do projeto, compondo camadas de preset e camadas
     de extensão antes do fallback para o template principal. Ele DEVE ter sucesso antes de continuar.
   - Se falhar, pare e relate o erro de resolução; não continue com apenas uma camada de template
     contribuinte.
   - Se `.specify/memory/constitution.md` existir, carregue-o como fonte dos valores atuais específicos
     do projeto e das emendas. Preserve as informações que ainda forem aplicáveis ao aplicar o novo
     esqueleto resolvido.
   - Se não existir, use o template resolvido como documento inicial.
   - Não escreva de volta em nenhuma camada de template versionada.
   - Identifique todo token de placeholder no formato `[IDENTIFICADOR_EM_MAIUSCULAS]`.
   **IMPORTANTE**: O usuário pode precisar de menos ou mais princípios do que os usados no template. Se um número for especificado, respeite-o - siga o template geral. Você atualizará o documento de acordo.

2. Colete/derive valores para os placeholders:
   - Se a entrada do usuário (conversa) fornecer um valor, use-o.
   - Caso contrário, infira a partir do contexto existente do repositório (README, docs, versões anteriores da constituição, se embutidas).
   - Para datas de governança: `RATIFICATION_DATE` é a data de adoção original (se desconhecida, pergunte ou marque como TODO), `LAST_AMENDED_DATE` é hoje se houver alterações, caso contrário mantenha a anterior.
   - `CONSTITUTION_VERSION` deve incrementar conforme as regras de versionamento semântico:
     - MAJOR: Remoções ou redefinições de governança/princípios incompatíveis com versões anteriores.
     - MINOR: Novo princípio/seção adicionado ou orientação materialmente expandida.
     - PATCH: Esclarecimentos, redação, correções de digitação, refinamentos não semânticos.
   - Se o tipo de incremento de versão for ambíguo, proponha o raciocínio antes de finalizar.

3. Redija o conteúdo atualizado da constituição usando o template resolvido como estrutura obrigatória:
   - Substitua cada placeholder por texto concreto (sem tokens entre colchetes restantes, exceto slots de template intencionalmente mantidos que o projeto escolheu ainda não definir — justifique explicitamente qualquer um deixado).
   - Preserve a hierarquia de títulos; os comentários podem ser removidos após substituídos, a menos que ainda acrescentem orientação esclarecedora.
   - Garanta que cada seção de Princípio tenha: linha de nome sucinta, parágrafo (ou lista) capturando as regras inegociáveis, justificativa explícita se não for óbvia.
   - Garanta que a seção Governança liste o procedimento de emenda, a política de versionamento e as expectativas de revisão de conformidade.

4. Produza um Relatório de Impacto de Sincronização como comentário HTML no topo do arquivo da constituição após a atualização.
   Este relatório é material de rascunho temporário para revisão humana da emenda, não conteúdo de
   governança; espera-se que seja removido antes de o arquivo da constituição emendada ser commitado.
   - Mudança de versão: antiga → nova
   - Lista de princípios modificados (título antigo → título novo, se renomeado)
   - Seções adicionadas
   - Seções removidas
   - TODOs de acompanhamento, se houver placeholders intencionalmente adiados.

5. Validação antes da saída final:
   - Nenhum token entre colchetes sem explicação restante.
   - Linha de versão corresponde ao relatório.
   - Datas no formato ISO YYYY-MM-DD.
   - Princípios são declarativos, testáveis e livres de linguagem vaga ("deveria" → substitua por DEVE/DEVERIA com justificativa quando apropriado).

6. Escreva a constituição concluída de volta em `.specify/memory/constitution.md` (sobrescrever).

7. Produza um resumo final para o usuário com:
   - Nova versão e justificativa do incremento.
   - Quaisquer placeholders TODO ou itens adiados que exijam acompanhamento manual.
   - Mensagem de commit sugerida (ex.: `docs: amend constitution to vX.Y.Z (principle additions + governance update)`).
   - Uma seção `Próximas Ações` para quaisquer intenções adiadas não relacionadas a governança.

Requisitos de Formatação e Estilo:

- Use os títulos Markdown exatamente como no template (não rebaixe/promova níveis).
- Quebre linhas longas de justificativa para manter a legibilidade (<100 caracteres idealmente), mas não force quebras estranhas.
- Mantenha uma única linha em branco entre seções.
- Evite espaços em branco no final das linhas.

Se o usuário fornecer atualizações parciais (ex.: apenas a revisão de um princípio), ainda assim execute as etapas de validação e de decisão de versão.

Se faltar informação crítica (ex.: data de ratificação realmente desconhecida), insira `TODO(<NOME_DO_CAMPO>): explicação` e inclua no Relatório de Impacto de Sincronização sob itens adiados.

Escreva apenas em `.specify/memory/constitution.md`; não crie nem modifique arquivos-fonte de template.

## Verificações Pós-Execução

**Verificar hooks de extensão (após a atualização da constituição)**:
Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se existir, leia-o e procure entradas sob a chave `hooks.after_constitution`
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
