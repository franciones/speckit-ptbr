# Checklist de [TIPO DO CHECKLIST]: [NOME DA FEATURE]

**Propósito**: [Descrição breve do que este checklist cobre]
**Criado em**: [DATA]
**Feature**: [Link para spec.md ou documentação relevante]

**Observação**: Este checklist personalizado é gerado pelo comando `/speckit-checklist` com base no contexto e nos requisitos da feature.
**Responsabilidade da Revisão**: Este checklist é um artefato de revisão da qualidade dos requisitos, de responsabilidade do revisor. Marque um item como `[x]` somente quando o revisor determinar que o critério de qualidade do requisito foi satisfeito.
**Semântica dos Marcadores**: `[x]` significa que o critério foi revisado e satisfeito quanto à qualidade do requisito. Não significa que o trabalho de implementação está concluído.

<!--
  ============================================================================
  IMPORTANTE: Os itens abaixo são EXEMPLOS apenas para ilustração.

  O comando /speckit-checklist DEVE substituí-los por itens reais baseados em:
  - Pedido específico do usuário para o checklist
  - Requisitos da feature em spec.md
  - Contexto técnico em plan.md
  - Detalhes de implementação em tasks.md

  NÃO mantenha estes itens de exemplo no arquivo de checklist gerado.
  ============================================================================
-->

## [Categoria 1]

- [ ] CHK001 Primeiro item do checklist com ação clara
- [ ] CHK002 Segundo item do checklist
- [ ] CHK003 Terceiro item do checklist

## [Categoria 2]

- [ ] CHK004 Item de outra categoria
- [ ] CHK005 Item com critérios específicos
- [ ] CHK006 Último item desta categoria

## Observações

- Marque itens como `[x]` somente após a revisão confirmar que o critério de qualidade do requisito foi satisfeito
- Deixe itens desmarcados enquanto ainda exigirem esclarecimento, correção ou avaliação do revisor
- `/speckit-implement` lê o estado das caixas de seleção do checklist como gate e não deve modificar os marcadores
- `checklists/requirements.md` tem um ciclo de vida próprio, mantido por `/speckit-specify` e `/speckit-clarify`
- Adicione comentários ou achados inline
- Referencie recursos ou documentação relevantes
- Os itens são numerados sequencialmente para facilitar a referência
