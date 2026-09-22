# Especificação da Funcionalidade: [NOME DA FEATURE]

**Branch da Funcionalidade**: `[###-nome-da-feature]`

**Criado em**: [DATA]

**Status**: Rascunho

**Entrada**: Descrição do usuário: "$ARGUMENTS"

## Cenários de Usuário e Testes *(obrigatório)*

<!--
  IMPORTANTE: As histórias de usuário devem ser PRIORIZADAS como jornadas ordenadas por importância.
  Cada história/jornada deve ser TESTÁVEL DE FORMA INDEPENDENTE - ou seja, se você implementar apenas UMA delas,
  ainda deve ter um MVP (Produto Mínimo Viável) que entrega valor.

  Atribua prioridades (P1, P2, P3 etc.) a cada história, sendo P1 a mais crítica.
  Pense em cada história como uma fatia autônoma de funcionalidade que pode ser:
  - Desenvolvida de forma independente
  - Testada de forma independente
  - Implantada de forma independente
  - Demonstrada aos usuários de forma independente
-->

### História de Usuário 1 - [Título Breve] (Prioridade: P1)

[Descreva esta jornada do usuário em linguagem simples]

**Por que esta prioridade**: [Explique o valor e por que ela tem este nível de prioridade]

**Teste Independente**: [Descreva como isso pode ser testado de forma independente - ex.: "Pode ser totalmente testado por [ação específica] e entrega [valor específico]"]

**Cenários de Aceitação**:

1. **Dado** [estado inicial], **Quando** [ação], **Então** [resultado esperado]
2. **Dado** [estado inicial], **Quando** [ação], **Então** [resultado esperado]

---

### História de Usuário 2 - [Título Breve] (Prioridade: P2)

[Descreva esta jornada do usuário em linguagem simples]

**Por que esta prioridade**: [Explique o valor e por que ela tem este nível de prioridade]

**Teste Independente**: [Descreva como isso pode ser testado de forma independente]

**Cenários de Aceitação**:

1. **Dado** [estado inicial], **Quando** [ação], **Então** [resultado esperado]

---

### História de Usuário 3 - [Título Breve] (Prioridade: P3)

[Descreva esta jornada do usuário em linguagem simples]

**Por que esta prioridade**: [Explique o valor e por que ela tem este nível de prioridade]

**Teste Independente**: [Descreva como isso pode ser testado de forma independente]

**Cenários de Aceitação**:

1. **Dado** [estado inicial], **Quando** [ação], **Então** [resultado esperado]

---

[Adicione mais histórias de usuário conforme necessário, cada uma com prioridade atribuída]

### Casos Extremos

<!--
  AÇÃO NECESSÁRIA: O conteúdo desta seção é composto por placeholders.
  Preencha com os casos extremos corretos.
-->

- O que acontece quando [condição de limite]?
- Como o sistema lida com [cenário de erro]?

## Requisitos *(obrigatório)*

<!--
  AÇÃO NECESSÁRIA: O conteúdo desta seção é composto por placeholders.
  Preencha com os requisitos funcionais corretos.
-->

### Requisitos Funcionais

- **FR-001**: O sistema DEVE [capacidade específica, ex.: "permitir que usuários criem contas"]
- **FR-002**: O sistema DEVE [capacidade específica, ex.: "validar endereços de e-mail"]
- **FR-003**: Os usuários DEVEM poder [interação principal, ex.: "redefinir a senha"]
- **FR-004**: O sistema DEVE [requisito de dados, ex.: "persistir as preferências do usuário"]
- **FR-005**: O sistema DEVE [comportamento, ex.: "registrar em log todos os eventos de segurança"]

*Exemplo de marcação de requisitos pouco claros:*

- **FR-006**: O sistema DEVE autenticar usuários via [NEEDS CLARIFICATION: método de autenticação não especificado - e-mail/senha, SSO, OAuth?]
- **FR-007**: O sistema DEVE reter os dados do usuário por [NEEDS CLARIFICATION: período de retenção não especificado]

### Entidades Principais *(incluir se a feature envolver dados)*

- **[Entidade 1]**: [O que representa, atributos principais sem detalhes de implementação]
- **[Entidade 2]**: [O que representa, relacionamentos com outras entidades]

## Critérios de Sucesso *(obrigatório)*

<!--
  AÇÃO NECESSÁRIA: Defina critérios de sucesso mensuráveis.
  Eles devem ser independentes de tecnologia e mensuráveis.
-->

### Resultados Mensuráveis

- **SC-001**: [Métrica mensurável, ex.: "Usuários concluem a criação de conta em menos de 2 minutos"]
- **SC-002**: [Métrica mensurável, ex.: "O sistema atende 1000 usuários simultâneos sem degradação"]
- **SC-003**: [Métrica de satisfação, ex.: "90% dos usuários concluem a tarefa principal na primeira tentativa"]
- **SC-004**: [Métrica de negócio, ex.: "Reduzir em 50% os chamados de suporte relacionados a [X]"]

## Premissas

<!--
  AÇÃO NECESSÁRIA: O conteúdo desta seção é composto por placeholders.
  Preencha com as premissas corretas, baseadas em padrões razoáveis
  escolhidos quando a descrição da feature não especificou certos detalhes.
-->

- [Premissa sobre os usuários-alvo, ex.: "Os usuários têm conexão estável com a internet"]
- [Premissa sobre limites de escopo, ex.: "Suporte a mobile está fora do escopo da v1"]
- [Premissa sobre dados/ambiente, ex.: "O sistema de autenticação existente será reutilizado"]
- [Dependência de sistema/serviço existente, ex.: "Requer acesso à API de perfil de usuário existente"]
