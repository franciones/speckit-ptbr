---
name: "speckit-clarify"
description: "Identificar áreas subespecificadas na spec da feature atual fazendo até 5 perguntas de esclarecimento altamente direcionadas e registrando as respostas de volta na spec."
argument-hint: "Áreas opcionais a esclarecer na spec"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/clarify.md"
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

**Verificar hooks de extensão (antes do esclarecimento)**:
- Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se existir, leia-o e procure entradas sob a chave `hooks.before_clarify`
- Se o YAML não puder ser interpretado ou for inválido, não pule silenciosamente: informe ao usuário que `.specify/extensions.yml` não pôde ser lido (inclua o erro do parser) e que nenhum hook foi verificado, incluindo quaisquer hooks obrigatórios (`optional: false`) registrados ali, e então continue normalmente
- Filtre os hooks em que `enabled` é explicitamente `false`. Trate hooks sem o campo `enabled` como habilitados por padrão.
- Para cada hook restante, **não** tente interpretar ou avaliar expressões de `condition` do hook:
  - Se o hook não tiver o campo `condition`, ou ele for nulo/vazio, trate o hook como executável
  - Se o hook definir uma `condition` não vazia, pule o hook e deixe a avaliação da condição para a implementação do HookExecutor
- Ao construir invocações de comando a partir dos nomes de comando dos hooks, substitua pontos (`.`) por hífens (`-`). Por exemplo, `speckit.git.commit` → `/speckit-git-commit`.
- Para cada hook executável, emita o seguinte com base no seu sinalizador `optional`:
  - **Hook opcional** (`optional: true`):
    ```
    ## Hooks de Extensão

    **Pré-Hook Opcional**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Hook obrigatório** (`optional: false`):
    ```
    ## Hooks de Extensão

    **Pré-Hook Automático**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}

    Wait for the result of the hook command before proceeding to the Outline.
    ```
    Após emitir o bloco acima você DEVE de fato invocar o hook e aguardar sua conclusão antes de continuar. Execute-o da mesma forma que executaria o comando você mesmo neste agente/sessão (a invocação pode diferir do id literal `{command}` mostrado acima, por exemplo um agente em modo skills executa como `/skill:speckit-...` ou `$speckit-...`). Emitir o bloco sozinho não executa o hook.
- Se nenhum hook estiver registrado ou `.specify/extensions.yml` não existir, pule silenciosamente

## Roteiro

Objetivo: Detectar e reduzir ambiguidade ou pontos de decisão ausentes na especificação da feature ativa e registrar os esclarecimentos diretamente no arquivo da spec.

Nota: Este fluxo de esclarecimento deve ser executado (e concluído) ANTES de invocar `/speckit-plan`. Se o usuário declarar explicitamente que está pulando o esclarecimento (por exemplo, spike exploratório), você pode prosseguir, mas deve avisar que o risco de retrabalho posterior aumenta.

Passos de execução:

1. Execute `.specify/scripts/powershell/check-prerequisites.ps1 -Json -PathsOnly` a partir da raiz do repositório **uma vez** (modo combinado `--json --paths-only` / `-Json -PathsOnly`). Interprete os campos mínimos do payload JSON:
   - `FEATURE_DIR`
   - `FEATURE_SPEC`
   - (Opcionalmente capture `IMPL_PLAN`, `TASKS` para fluxos encadeados futuros.)
   - Se a interpretação do JSON falhar, aborte e instrua o usuário a executar novamente `/speckit-specify` ou verificar o ambiente da branch da feature.
   - Para aspas simples em argumentos como "I'm Groot", use a sintaxe de escape: por exemplo 'I'\''m Groot' (ou aspas duplas se possível: "I'm Groot").

2. **SE EXISTIR**: Carregue `.specify/memory/constitution.md` para os princípios do projeto e restrições de governança.

3. Carregue o arquivo de spec atual. Realize uma varredura estruturada de ambiguidade e cobertura usando esta taxonomia. Para cada categoria, marque o status: Claro / Parcial / Ausente. Produza um mapa de cobertura interno usado para priorização (não exiba o mapa bruto a menos que nenhuma pergunta vá ser feita).

   Escopo Funcional e Comportamento:
   - Objetivos centrais do usuário e critérios de sucesso
   - Declarações explícitas de fora do escopo
   - Diferenciação de papéis de usuário / personas

   Domínio e Modelo de Dados:
   - Entidades, atributos, relacionamentos
   - Regras de identidade e unicidade
   - Transições de ciclo de vida/estado
   - Premissas de volume de dados / escala

   Interação e Fluxo de UX:
   - Jornadas / sequências críticas do usuário
   - Estados de erro/vazio/carregamento
   - Notas de acessibilidade ou localização

   Atributos de Qualidade Não Funcionais:
   - Desempenho (latência, metas de throughput)
   - Escalabilidade (horizontal/vertical, limites)
   - Confiabilidade e disponibilidade (uptime, expectativas de recuperação)
   - Observabilidade (logging, métricas, sinais de tracing)
   - Segurança e privacidade (autenticação/autorização, proteção de dados, premissas de ameaça)
   - Restrições de conformidade / regulatórias (se houver)

   Integração e Dependências Externas:
   - Serviços/APIs externos e modos de falha
   - Formatos de importação/exportação de dados
   - Premissas de protocolo/versionamento

   Casos Extremos e Tratamento de Falhas:
   - Cenários negativos
   - Rate limiting / throttling
   - Resolução de conflitos (por exemplo, edições concorrentes)

   Restrições e Trade-offs:
   - Restrições técnicas (linguagem, armazenamento, hospedagem)
   - Trade-offs explícitos ou alternativas rejeitadas

   Terminologia e Consistência:
   - Termos canônicos do glossário
   - Sinônimos evitados / termos descontinuados

   Sinais de Conclusão:
   - Testabilidade dos critérios de aceitação
   - Indicadores mensuráveis no estilo Definition of Done

   Diversos / Placeholders:
   - Marcadores TODO / decisões não resolvidas
   - Adjetivos ambíguos ("robusto", "intuitivo") sem quantificação

   Para cada categoria com status Parcial ou Ausente, adicione uma oportunidade de pergunta candidata, a menos que:
   - O esclarecimento não mudaria materialmente a estratégia de implementação ou validação
   - O item seja especificamente sobre método de implementação, comparação de stack tecnológica ou decomposição de tarefas (anote internamente)

4. Gere (internamente) uma fila priorizada de perguntas de esclarecimento candidatas (máximo 5). NÃO as exiba todas de uma vez. Aplique estas restrições:
    - Máximo de 5 perguntas no total ao longo de toda a sessão.
    - Cada pergunta deve ser respondível com OU:
       - Uma seleção curta de múltipla escolha (2–5 opções distintas e mutuamente exclusivas), OU
       - Uma resposta de uma palavra / frase curta (restrinja explicitamente: "Responda em <=5 palavras").
    - Inclua apenas perguntas cujas respostas impactem materialmente arquitetura, modelagem de dados, decomposição de tarefas, design de testes, comportamento de UX, prontidão operacional ou validação de conformidade.
    - Garanta equilíbrio na cobertura de categorias: tente cobrir primeiro as categorias não resolvidas de maior impacto; evite fazer duas perguntas de baixo impacto quando uma única área de alto impacto (por exemplo, postura de segurança) está sem resolução.
    - Exclua perguntas já respondidas, preferências estilísticas triviais ou detalhes de execução em nível de plano (a menos que bloqueiem a correção).
    - Favoreça esclarecimentos que reduzam o risco de retrabalho posterior ou previnam testes de aceitação desalinhados.
    - Se mais de 5 categorias permanecerem sem resolução, selecione as 5 principais pela heurística (Impacto * Incerteza).

5. Loop de perguntas sequencial (interativo):
    - Apresente EXATAMENTE UMA pergunta por vez.
    - **Qualidade de redação da pergunta (aplica-se a toda pergunta, múltipla escolha ou resposta curta):**
       - Comece com `**Pergunta:**` seguido de uma interrogativa completa que termine com `?`. O texto da pergunta antes do `?` deve fazer sentido por si só.
       - NUNCA use um rótulo de tópico, título de seção ou id de requisito como a própria pergunta. Por exemplo, `Matriz de dispositivos/runtime de aceitação (FR-023)` é INVÁLIDO — é um rótulo, não uma pergunta.
       - Após o `?`, o único sufixo permitido é um id opcional de requisito/pergunta entre parênteses. Formato exato: `**Pergunta:** <interrogativa>?` ou `**Pergunta:** <interrogativa>? (FR-023)`. Nunca coloque o id antes do `?`, e nunca use o id (sozinho ou com um rótulo de tópico) como o prompt inteiro.
       - Imediatamente após a linha da pergunta, adicione uma frase em linguagem simples "Por que importa" (o que está em jogo para aceitação ou entrega) antes da recomendação/opções.
       - Use vocabulário cotidiano; introduza jargão apenas se definido na mesma frase. Autoverificação: um leitor que não conhece o Spec Kit deve conseguir responder apenas a partir da linha da Pergunta. Ser conciso é bom; rótulos crípticos não são.
    - Para perguntas de múltipla escolha:
       - **Analise todas as opções** e determine a **opção mais adequada** com base em:
          - Boas práticas para o tipo de projeto
          - Padrões comuns em implementações similares
          - Redução de risco (segurança, desempenho, manutenibilidade)
          - Alinhamento com quaisquer objetivos ou restrições explícitos do projeto visíveis na spec
       - Apresente sua **opção recomendada com destaque** no topo, com raciocínio claro (1-2 frases explicando por que esta é a melhor escolha).
       - Formate como: `**Recomendado:** Opção [X] - <raciocínio>`
       - Em seguida, renderize todas as opções como uma tabela Markdown:

       | Opção | Descrição |
       |-------|-----------|
       | A | <Descrição da opção A> |
       | B | <Descrição da opção B> |
       | C | <Descrição da opção C> (adicione D/E conforme necessário, até 5) |
       | Curta | Forneça uma resposta curta diferente (<=5 palavras) (Inclua apenas se uma alternativa livre for apropriada) |

       - Após a tabela, adicione: `Você pode responder com a letra da opção (por exemplo, "A"), aceitar a recomendação dizendo "sim" ou "recomendado", ou fornecer sua própria resposta curta.`
    - Para o estilo de resposta curta (sem opções discretas significativas):
       - Forneça sua **resposta sugerida** com base em boas práticas e contexto.
       - Formate como: `**Sugerido:** <sua resposta proposta> - <breve raciocínio>`
       - Em seguida, exiba: `Formato: Resposta curta (<=5 palavras). Você pode aceitar a sugestão dizendo "sim" ou "sugerido", ou fornecer sua própria resposta.`
    - Após o usuário responder:
       - Se o usuário responder com "sim", "recomendado" ou "sugerido", use a recomendação/sugestão declarada anteriormente como a resposta.
       - Caso contrário, valide se a resposta corresponde a uma opção ou se enquadra na restrição de <=5 palavras.
       - Se ambígua, peça uma desambiguação rápida (a contagem ainda pertence à mesma pergunta; não avance).
       - Quando satisfatória, registre-a na memória de trabalho (ainda não grave em disco) e passe para a próxima pergunta da fila.
    - Pare de fazer mais perguntas quando:
       - Todas as ambiguidades críticas forem resolvidas cedo (os itens restantes da fila se tornam desnecessários), OU
       - O usuário sinalizar conclusão ("pronto", "ok", "chega"), OU
       - Você atingir 5 perguntas feitas.
    - Nunca revele antecipadamente as perguntas futuras da fila.
    - Se não existirem perguntas válidas no início, informe imediatamente que não há ambiguidades críticas.

6. Integração após CADA resposta aceita (abordagem de atualização incremental):
    - Mantenha uma representação em memória da spec (carregada uma vez no início) mais o conteúdo bruto do arquivo.
    - Para a primeira resposta integrada nesta sessão:
       - Garanta que exista uma seção `## Esclarecimentos` (crie-a logo após a seção de contexto/visão geral de mais alto nível conforme o template da spec, se ausente).
       - Sob ela, crie (se não existir) um subtítulo `### Sessão YYYY-MM-DD` para hoje.
    - Acrescente uma linha de bullet imediatamente após a aceitação: `- P: <pergunta> → R: <resposta final>`.
    - Em seguida, aplique imediatamente o esclarecimento à(s) seção(ões) mais apropriada(s):
       - Ambiguidade funcional → Atualize ou adicione um bullet em Requisitos Funcionais.
       - Interação do usuário / distinção de ator → Atualize a subseção Histórias de Usuário ou Atores (se presente) com o papel, restrição ou cenário esclarecido.
       - Formato de dados / entidades → Atualize o Modelo de Dados (adicione campos, tipos, relacionamentos) preservando a ordem; anote as restrições adicionadas de forma sucinta.
       - Restrição não funcional → Adicione/modifique critérios mensuráveis em Critérios de Sucesso > Resultados Mensuráveis (converta adjetivo vago em métrica ou meta explícita).
       - Caso extremo / fluxo negativo → Adicione um novo bullet sob Casos Extremos / Tratamento de Erros (ou crie tal subseção se o template fornecer placeholder para ela).
       - Conflito de terminologia → Normalize o termo em toda a spec; mantenha o original apenas se necessário, adicionando `(anteriormente referido como "X")` uma vez.
    - Se o esclarecimento invalidar uma declaração ambígua anterior, substitua essa declaração em vez de duplicar; não deixe texto contraditório obsoleto.
    - Salve o arquivo da spec APÓS cada integração para minimizar o risco de perda de contexto (sobrescrita atômica).
    - Preserve a formatação: não reordene seções não relacionadas; mantenha a hierarquia de títulos intacta.
    - Mantenha cada esclarecimento inserido mínimo e testável (evite deriva narrativa).

7. Validação (realizada após CADA gravação mais uma passagem final):
   - A sessão de Esclarecimentos contém exatamente um bullet por resposta aceita (sem duplicatas).
   - Total de perguntas feitas (aceitas) ≤ 5.
   - As seções atualizadas não contêm placeholders vagos remanescentes que a nova resposta deveria resolver.
   - Nenhuma declaração anterior contraditória permanece (varra em busca de escolhas alternativas agora inválidas e removidas).
   - Estrutura Markdown válida; únicos novos títulos permitidos: `## Esclarecimentos`, `### Sessão YYYY-MM-DD`.
   - Consistência de terminologia: o mesmo termo canônico usado em todas as seções atualizadas.

8. Grave a spec atualizada de volta em `FEATURE_SPEC`.

9. **Revalidar o Checklist de Qualidade da Spec** (se existir):
   - Verifique se `FEATURE_DIR/checklists/requirements.md` existe.
   - Se NÃO existir, pule este passo silenciosamente.
   - Se existir:
     1. Leia o arquivo do checklist.
     2. Identifique todas as linhas de checkbox de task-list do GitHub — linhas que correspondem a `- [ ]`, `- [x]` ou `- [X]` (sem distinção de maiúsculas, tolerante a espaços à esquerda para itens aninhados) fora de blocos de código. Ignore todo o restante do conteúdo (títulos, notas, bullets sem checkbox, metadados).
     3. Para cada linha de checkbox, registre seu estado atual de marcador (marcado ou desmarcado) e o texto do item em uma lista de snapshot anterior.
     4. Reavalie cada item de checkbox contra a spec **atualizada** (a versão recém-salva no passo 7).
     5. Para cada item de checkbox, atualize apenas se o estado marcado/desmarcado realmente mudar:
        - Se o item agora passa e estava desmarcado: mude `[ ]` para `[x]`.
        - Se o item agora falha e estava marcado: mude `[x]`/`[X]` para `[ ]`.
        - Se o estado não mudou: deixe o marcador como está (preserve a caixa existente para evitar diffs cosméticos).
     6. Salve o arquivo do checklist atualizado. **Alterne apenas a porção do marcador `[ ]`/`[x]` das linhas de checkbox cujo estado mudou.** Todo o restante do conteúdo do arquivo — títulos, metadados, notas, ordem das linhas, espaços em branco — deve permanecer inalterado para evitar diffs ruidosos.
     7. Compare o snapshot anterior com o estado atual para calcular três listas para o Relatório de Conclusão:
        - **Passando agora**: itens que mudaram de desmarcado para marcado.
        - **Regressões**: itens que mudaram de marcado para desmarcado.
        - **Ainda desmarcados**: itens que permanecem desmarcados.
     8. Registre as contagens de aprovação antes/depois como itens marcados/total de checkboxes (por exemplo, "12/16 → 15/16 itens passando").

Regras de comportamento:

- Se nenhuma ambiguidade significativa for encontrada (ou todas as perguntas potenciais forem de baixo impacto), responda: "Nenhuma ambiguidade crítica detectada que mereça esclarecimento formal." e sugira prosseguir.
- Se o arquivo da spec estiver ausente, instrua o usuário a executar `/speckit-specify` primeiro (não crie uma nova spec aqui).
- Nunca exceda 5 perguntas feitas no total (novas tentativas de esclarecimento para uma única pergunta não contam como novas perguntas).
- Evite perguntas especulativas sobre stack tecnológica, a menos que a ausência bloqueie a clareza funcional.
- Respeite sinais de encerramento antecipado do usuário ("parar", "pronto", "prosseguir").
- Se nenhuma pergunta for feita devido à cobertura completa, exiba um resumo compacto de cobertura (todas as categorias Claras) e então sugira avançar.
- Se a cota for atingida com categorias de alto impacto ainda não resolvidas, sinalize-as explicitamente sob Adiadas com justificativa.

Contexto para priorização: $ARGUMENTS

## Hooks Pós-Execução Obrigatórios

**Você DEVE concluir esta seção antes de reportar a conclusão ao usuário.**

Verifique se `.specify/extensions.yml` existe na raiz do projeto.
- Se não existir, ou nenhum hook estiver registrado sob `hooks.after_clarify`, pule para o Relatório de Conclusão.
- Se existir, leia-o e procure entradas sob a chave `hooks.after_clarify`.
- Se o YAML não puder ser interpretado ou for inválido, não pule silenciosamente: informe ao usuário que `.specify/extensions.yml` não pôde ser lido (inclua o erro do parser) e que nenhum hook foi verificado, incluindo quaisquer hooks obrigatórios (`optional: false`) registrados ali, e então continue para o Relatório de Conclusão.
- Filtre os hooks em que `enabled` é explicitamente `false`. Trate hooks sem o campo `enabled` como habilitados por padrão.
- Para cada hook restante, **não** tente interpretar ou avaliar expressões de `condition` do hook:
  - Se o hook não tiver o campo `condition`, ou ele for nulo/vazio, trate o hook como executável
  - Se o hook definir uma `condition` não vazia, pule o hook e deixe a avaliação da condição para a implementação do HookExecutor
- Ao construir invocações de comando a partir dos nomes de comando dos hooks, substitua pontos (`.`) por hífens (`-`). Por exemplo, `speckit.git.commit` → `/speckit-git-commit`.
- Para cada hook executável, emita o seguinte com base no seu sinalizador `optional`:
  - **Hook obrigatório** (`optional: false`) — **Você DEVE emitir `EXECUTE_COMMAND:` para cada hook obrigatório**:
    ```
    ## Hooks de Extensão

    **Automatic Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
    Após emitir o bloco acima você DEVE de fato invocar o hook e aguardar sua conclusão antes de continuar. Execute-o da mesma forma que executaria o comando você mesmo neste agente/sessão (a invocação pode diferir do id literal `{command}` mostrado acima, por exemplo um agente em modo skills executa como `/skill:speckit-...` ou `$speckit-...`). Emitir o bloco sozinho não executa o hook.
  - **Hook opcional** (`optional: true`):
    ```
    ## Hooks de Extensão

    **Optional Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```

## Relatório de Conclusão

Reporte a conclusão (após o loop de perguntas terminar ou encerramento antecipado):
- Número de perguntas feitas e respondidas.
- Caminho da spec atualizada.
- Seções alteradas (liste os nomes).
- Status do checklist de qualidade da spec (se `FEATURE_DIR/checklists/requirements.md` foi revalidado): mostre as contagens de aprovação antes/depois (por exemplo, "Checklist de Qualidade da Spec: 12/16 → 15/16 itens passando") e liste quaisquer itens que mudaram de estado — tanto os recém-marcados (desmarcado → marcado) quanto quaisquer regressões (marcado → desmarcado). Se algum item permanecer desmarcado, liste-o como área que precisa de atenção.
- Tabela de resumo de cobertura listando cada categoria da taxonomia com Status: Resolvida (era Parcial/Ausente e foi tratada), Adiada (excede a cota de perguntas, ou o item restante é especificamente método de implementação, comparação de stack tecnológica ou decomposição de tarefas), Clara (já suficiente), Pendente (ainda Parcial/Ausente, mas de baixo impacto).
- Se restar alguma Pendente ou Adiada, recomende se deve prosseguir para `/speckit-plan` ou executar `/speckit-clarify` novamente mais tarde, após o plano.
- Próximo comando sugerido.

## Concluído Quando

- [ ] Ambiguidades da spec identificadas e esclarecimentos integrados ao arquivo da spec
- [ ] Checklist de qualidade da spec revalidado contra a spec atualizada (se `FEATURE_DIR/checklists/requirements.md` existir)
- [ ] Hooks de extensão despachados ou pulados de acordo com as regras em Hooks Pós-Execução Obrigatórios acima
- [ ] Conclusão reportada ao usuário com perguntas respondidas, seções alteradas, status do checklist e resumo de cobertura
