# speckit-ptbr

Tradução para português do Brasil do [GitHub Spec Kit](https://github.com/github/spec-kit), pronta para aplicar em qualquer projeto novo, com um fluxo de atualização contínua que acompanha as versões lançadas pelo GitHub.

Não é um fork. O pacote sobrepõe os 16 arquivos que moldam a saída do Spec Kit (templates, constituição e skills do Claude Code) a um projeto gerado pela CLI oficial `specify`. A CLI, os scripts e o catálogo de extensões continuam sendo os do upstream.

## O que você ganha

- Specs, planos, tarefas, checklists e relatórios gerados em pt-BR, com termos técnicos em inglês.
- Um `CLAUDE.md` com a regra de idioma, glossário e mapa de títulos, para o modelo não voltar ao inglês nas etapas seguintes.
- Scripts para criar projeto novo já traduzido e para atualizar a tradução quando o upstream mudar.

## Requisitos

- Windows PowerShell 5.1 ou PowerShell 7+
- [uv](https://docs.astral.sh/uv/) e git
- CLI `specify` na mesma versão que o pacote acompanha (ver `VERSION`):

```powershell
uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git@<upstream_commit do VERSION>
```

- Claude Code (o pacote suporta apenas a integração `claude`, com scripts `ps`)
- Política de execução do PowerShell liberada para scripts locais. O Windows vem com "Restricted" e bloqueia qualquer `.ps1`. Uma vez por usuário, sem administrador:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Alternativa sem mudar a política: `powershell -ExecutionPolicy Bypass -File <script> <argumentos>`.

## Linux e macOS

Os scripts de uso diário existem também em bash puro, sem PowerShell: `scripts/new-project.sh` e `scripts/apply.sh`. Eles geram o projeto com `--script sh` e convertem os skills na hora para chamar os scripts bash do Spec Kit. Templates e constituição são idênticos nas duas variantes.

```bash
git clone https://github.com/franciones/speckit-ptbr.git ~/ferramentas/speckit-ptbr
chmod +x ~/ferramentas/speckit-ptbr/scripts/*.sh
~/ferramentas/speckit-ptbr/scripts/new-project.sh meu-projeto
```

Requisitos no Linux: `uv`, `git`, `perl` (padrão em qualquer distribuição) e a CLI `specify`. Os scripts de manutenção (`sync-upstream`, `translate-pending`, `validate`) continuam em PowerShell e rodam no CI ou sob `pwsh`; um mantenedor em Linux pode instalar o PowerShell 7 ou deixar o CI fazer o sync.

## Uso no dia a dia (time)

Clone este repositório uma vez, por exemplo em `C:\Ferramentas\speckit-ptbr`:

```powershell
git clone https://github.com/franciones/speckit-ptbr.git C:\Ferramentas\speckit-ptbr
```

**Projeto novo, já em pt-BR:**

```powershell
C:\Ferramentas\speckit-ptbr\scripts\new-project.ps1 -Name meu-projeto
```

**Projeto existente que já rodou `specify init`:**

```powershell
C:\Ferramentas\speckit-ptbr\scripts\apply.ps1 -ProjectPath C:\Projetos\meu-projeto
```

Depois abra o Claude Code no projeto e comece por `/speckit-constitution`. O arquivo `.specify/ptbr.json` registra qual versão do pacote foi aplicada.

Se o projeto já tiver um `CLAUDE.md`, o script anexa a seção de idioma em vez de sobrescrever.

## Atualização contínua (mantenedores)

O GitHub lança versões do Spec Kit com frequência. A maioria não toca nos 16 arquivos traduzidos, e o fluxo abaixo detecta isso automaticamente.

```powershell
.\scripts\sync-upstream.ps1          # instala a specify mais nova, compara e grava diffs em sync/
.\scripts\translate-pending.ps1      # traduz só o que mudou, via Claude Code headless
.\scripts\validate.ps1               # confere integridade estrutural
git add -A; git commit -m "sync: upstream <versao>"
```

O que cada passo faz:

1. `sync-upstream.ps1` instala a `specify` do ref indicado (padrão `main`), gera um projeto temporário, compara os 16 arquivos com `upstream/` e, para cada um que mudou, grava em `sync/<versão>-<commit>/` o original antigo, o novo e o diff. Atualiza `upstream/`, `VERSION` e `sync/pending.json`. Se nada mudou, só atualiza `VERSION`.
2. `translate-pending.ps1` monta um prompt por arquivo pendente com as regras do `CLAUDE.md`, o diff e a tradução atual, e pede ao Claude a versão atualizada aplicando somente o que mudou. Sem a CLI `claude`, use `-PromptsOnly` e cole os prompts no Claude Code manualmente.
3. `validate.ps1` confere que a tradução preserva o que os comandos dependem: frontmatter, `$ARGUMENTS`, chaves de hooks, caminhos de scripts, blocos de código, marcadores e placeholders. Roda também no CI a cada pull request.

Revise sempre o diff da tradução antes de mesclar. O modelo traduz bem, mas a revisão humana é o gate.

**Skills novos no upstream:** o sync avisa quando aparece um skill que o pacote não conhece. Adicione o caminho em `scripts/common.ps1`, copie o original para `upstream/`, traduza e valide.

## Pipeline (GitHub Actions)

Dois workflows em `.github/workflows/`:

- `validate.yml`: roda em todo push na `main` e em todo pull request.
- `sync-upstream.yml`: roda toda segunda-feira e sob demanda (Actions > sync-upstream > Run workflow). Se o upstream mudou, cria a branch `sync/<versão>-<commit>`, faz commit de `upstream/`, `VERSION` e `sync/`, e abre um pull request com os diffs. A tradução fica para um mantenedor rodar `translate-pending.ps1` localmente, ou para o próprio workflow quando disparado manualmente com a opção `translate` marcada e o secret `ANTHROPIC_API_KEY` cadastrado.

Configuração única no repositório: em Settings > Actions > General > Workflow permissions, escolher "Read and write permissions" e marcar "Allow GitHub Actions to create and approve pull requests". Sem isso o job não consegue abrir o PR.

## Estrutura

```text
speckit-ptbr/
├── VERSION                 # versão e commit do upstream acompanhados
├── ptbr/                   # sobreposição traduzida, no mesmo layout de um projeto gerado
│   ├── CLAUDE.md
│   ├── .specify/templates/*.md
│   ├── .specify/memory/constitution.md
│   └── .claude/skills/speckit-*/SKILL.md
├── upstream/               # originais em inglês da versão acompanhada, variante ps (base dos diffs)
├── upstream-sh/            # skills originais da variante sh (só para validar a derivação)
├── sync/                   # histórico de sincronizações e pendências
├── scripts/
│   ├── new-project.ps1     # specify init + apply (Windows)
│   ├── new-project.sh      # idem, bash (Linux/macOS)
│   ├── apply.ps1           # aplica ptbr/ sobre um projeto (Windows)
│   ├── apply.sh            # idem, bash (Linux/macOS)
│   ├── sync-upstream.ps1   # detecta mudanças no upstream
│   ├── translate-pending.ps1
│   ├── validate.ps1
│   └── common.ps1
└── .github/workflows/      # validate.yml e sync-upstream.yml
```

## O que fica em inglês, de propósito

- Nomes de arquivos, pastas, comandos `/speckit-*`, chaves de frontmatter, scripts e manifests.
- Tokens que os comandos procuram literalmente: `[P]`, `[US1]`, `T001`, `FR-001`, `SC-001`, `CHK001`, `[NEEDS CLARIFICATION: ...]`, `$ARGUMENTS`, placeholders `[PROJECT_NAME]` e afins.
- Código-fonte gerado, comentários de código e mensagens de commit.
- Termos do glossário em `ptbr/CLAUDE.md` (feature, branch, endpoint, deploy, backend etc.).

As decisões de tradução tomadas nos skills estão registradas em `DECISOES.md`.

## Limitações conhecidas

- Suporta só a integração Claude Code. As duas variantes de script do Spec Kit (`ps` e `sh`) são atendidas: a tradução canônica é `ps` e a `sh` é derivada ao aplicar, validada contra os skills bash do upstream guardados em `upstream-sh/`. Outros agentes (Copilot, Cursor, Gemini) têm arquivos de comando em outros caminhos e precisariam de uma variante do pacote.
- Depois de aplicar a tradução, um `specify init --here` em versão nova vai parar ao detectar arquivos editados. Isso é esperado. Atualize pelo pacote: `sync-upstream.ps1` e depois `apply.ps1 -Force`.
- O GitHub fechou como "não planejado" os pedidos de suporte a idioma (issues 116 e 1239). Se um dia o upstream ganhar essa opção, este pacote deixa de ser necessário.
