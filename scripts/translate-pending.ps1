<#
.SYNOPSIS
  Traduz para pt-BR apenas os arquivos que mudaram no upstream, usando o Claude Code em modo headless.

.DESCRIPTION
  Lê sync/pending.json (gerado por sync-upstream.ps1). Para cada arquivo pendente monta um prompt com:
  as regras de CLAUDE.md, o original antigo, o original novo, o diff entre eles e a tradução atual.
  Pede ao Claude a tradução completa atualizada, aplicando somente o que mudou, e grava em ptbr/.
  Ao final roda validate.ps1. Se tudo passar, limpa o pending.json.

.PARAMETER File
  Traduz apenas os arquivos informados (caminhos relativos como em pending.json).

.PARAMETER Model
  Modelo a usar no `claude -p` (opcional).

.PARAMETER PromptsOnly
  Não chama o Claude. Só grava os prompts em sync/<id>/prompts/ para tradução manual ou em outra máquina.

.EXAMPLE
  .\scripts\translate-pending.ps1
  .\scripts\translate-pending.ps1 -File .claude/skills/speckit-plan/SKILL.md
  .\scripts\translate-pending.ps1 -PromptsOnly
#>
[CmdletBinding()]
param(
    [string[]]$File = @(),
    [string]$Model = '',
    [switch]$PromptsOnly
)

. (Join-Path $PSScriptRoot 'common.ps1')

$pendingFile = Join-Path $script:PackRoot 'sync/pending.json'
if (-not (Test-Path $pendingFile)) { Write-Ok 'Nada pendente (sync/pending.json não existe).'; exit 0 }
$pending = Get-Content $pendingFile -Raw | ConvertFrom-Json
$syncDir = Join-Path $script:PackRoot "sync/$($pending.sync_id)"
$targets = @($pending.files)
if ($File.Count -gt 0) { $targets = @($targets | Where-Object { $File -contains $_ }) }
if ($targets.Count -eq 0) { Write-Ok 'Nenhum arquivo pendente para traduzir.'; exit 0 }

$claude = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claude -and -not $PromptsOnly) {
    Write-Warn2 'CLI `claude` (Claude Code) não encontrada. Gerando apenas os prompts com -PromptsOnly.'
    $PromptsOnly = $true
}

$rules = Read-Utf8 (Join-Path $script:PackRoot 'ptbr/CLAUDE.md')
$promptsDir = Join-Path $syncDir 'prompts'
New-Item -ItemType Directory -Force -Path $promptsDir | Out-Null

$results = @{}
foreach ($rel in $targets) {
    Write-Step "Traduzindo $rel"
    $safe = ($rel -replace '[\\/]', '__')
    $oldPath = Join-Path $syncDir "old/$rel"
    $newPath = Join-Path $syncDir "new/$rel"
    $diffPath = Join-Path $syncDir "diff/$safe.diff"
    $ptPath = Join-Path $script:PackRoot "ptbr/$rel"

    $oldText = ''
    if (Test-Path $oldPath) { $oldText = Read-Utf8 $oldPath }
    $newText = Read-Utf8 $newPath
    $diffText = ''
    if (Test-Path $diffPath) { $diffText = Read-Utf8 $diffPath }
    $ptText = ''
    if (Test-Path $ptPath) { $ptText = Read-Utf8 $ptPath }

    $isSkill = $rel -like '*.claude/skills/*'
    $idiomaBlock = @'
## Idioma de saída (obrigatório)

Todo texto narrativo que este comando produzir (documentos, seções, perguntas, relatórios e respostas ao usuário) DEVE ser escrito em português do Brasil. Código, nomes de arquivos, caminhos, comandos, identificadores e os termos do glossário em `CLAUDE.md` permanecem em inglês. Use os títulos de seção definidos no mapa de `CLAUDE.md`.
'@

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('Você é o tradutor oficial do pacote speckit-ptbr. Sua tarefa: produzir a versão pt-BR ATUALIZADA de um arquivo do GitHub Spec Kit.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("Arquivo: $rel")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('# REGRAS (CLAUDE.md do pacote)')
    [void]$sb.AppendLine($rules)
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('# REGRAS ADICIONAIS PARA ESTA TAREFA')
    [void]$sb.AppendLine('1. Parta da TRADUÇÃO ATUAL. Aplique nela SOMENTE as mudanças que o DIFF mostra entre o original antigo e o novo. Não retraduza trechos que não mudaram e não altere escolhas de tradução já feitas.')
    [void]$sb.AppendLine('2. Trechos adicionados no upstream devem ser traduzidos com o mesmo estilo e o mesmo vocabulário da tradução atual.')
    [void]$sb.AppendLine('3. Trechos removidos no upstream devem ser removidos da tradução.')
    [void]$sb.AppendLine('4. Preserve estrutura, blocos de código, tabelas, comentários HTML e frontmatter. No frontmatter, traduza apenas os valores de `description` e `argument-hint`.')
    if ($isSkill) {
        [void]$sb.AppendLine('5. O arquivo é um skill: mantenha o bloco abaixo logo após o frontmatter, exatamente como está:')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine($idiomaBlock)
    }
    [void]$sb.AppendLine('6. Se a tradução atual estiver vazia (arquivo novo no upstream), traduza o ORIGINAL NOVO por completo seguindo as regras.')
    [void]$sb.AppendLine('7. RESPONDA SOMENTE COM O CONTEÚDO COMPLETO DO ARQUIVO FINAL. Sem explicações, sem cercas de código envolvendo o arquivo inteiro, sem texto antes ou depois.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('# ORIGINAL ANTIGO (inglês)')
    [void]$sb.AppendLine('<<<ORIGINAL_ANTIGO')
    [void]$sb.AppendLine($oldText)
    [void]$sb.AppendLine('ORIGINAL_ANTIGO>>>')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('# ORIGINAL NOVO (inglês)')
    [void]$sb.AppendLine('<<<ORIGINAL_NOVO')
    [void]$sb.AppendLine($newText)
    [void]$sb.AppendLine('ORIGINAL_NOVO>>>')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('# DIFF (antigo -> novo)')
    [void]$sb.AppendLine('<<<DIFF')
    [void]$sb.AppendLine($diffText)
    [void]$sb.AppendLine('DIFF>>>')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('# TRADUÇÃO ATUAL (pt-BR)')
    [void]$sb.AppendLine('<<<TRADUCAO_ATUAL')
    [void]$sb.AppendLine($ptText)
    [void]$sb.AppendLine('TRADUCAO_ATUAL>>>')

    $promptPath = Join-Path $promptsDir "$safe.prompt.md"
    Write-Utf8 -Path $promptPath -Content $sb.ToString()

    if ($PromptsOnly) { Write-Ok "Prompt gravado em $promptPath"; continue }

    $claudeArgs = @('-p', 'Execute a tarefa descrita na entrada. Responda apenas com o conteúdo do arquivo final.', '--output-format', 'text')
    if ($Model) { $claudeArgs += @('--model', $Model) }
    $promptText = Read-Utf8 $promptPath
    $run = Invoke-Native -Exe 'claude' -Arguments $claudeArgs -StdinText $promptText
    $output = $run.Output
    if ($run.ExitCode -ne 0 -or -not $output.Trim()) {
        Write-Fail "claude -p falhou para $rel (código $($run.ExitCode)). Prompt disponível em $promptPath"
        ($output -split "`n" | Select-Object -Last 5) | ForEach-Object { Write-Host "      $_" }
        $results[$rel] = $false
        continue
    }

    # Remove cercas de código se o modelo envolveu o arquivo inteiro
    $text = $output -replace "`r`n", "`n"
    $text = $text.Trim()
    if ($text -match '^```[a-zA-Z]*\n([\s\S]*)\n```$') { $text = $Matches[1] }
    if (-not $text.EndsWith("`n")) { $text += "`n" }

    Write-Utf8 -Path $ptPath -Content $text
    Write-Ok "ptbr/$rel atualizado"
    $results[$rel] = $true
}

if ($PromptsOnly) {
    Write-Host ''
    Write-Host "Prompts em $promptsDir. Cole cada um no Claude Code e salve a resposta no caminho correspondente em ptbr/." -ForegroundColor Yellow
    exit 0
}

Write-Host ''
Write-Step 'Validando'
& (Join-Path $PSScriptRoot 'validate.ps1')
$valid = ($LASTEXITCODE -eq 0)

$failed = @($results.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object { $_.Key })
if ($valid -and $failed.Count -eq 0 -and $File.Count -eq 0) {
    Remove-Item $pendingFile -Force
    Write-Ok 'Tudo traduzido e validado. sync/pending.json removido. Revise o diff no git e abra o pull request.'
    exit 0
}
if ($failed.Count -gt 0) { Write-Fail "Falharam: $($failed -join ', ')" }
if (-not $valid) { Write-Fail 'A validação encontrou problemas. Corrija em ptbr/ e rode validate.ps1 de novo.' }
exit 1
