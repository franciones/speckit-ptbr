<#
.SYNOPSIS
  Sincroniza o pacote com a versão mais recente do github/spec-kit e identifica o que precisa ser retraduzido.

.DESCRIPTION
  1. Instala a `specify` a partir do ref indicado (padrão: main).
  2. Inicializa um projeto temporário e extrai os arquivos que o pacote traduz.
  3. Compara com a pasta upstream/ do pacote.
  4. Para cada arquivo alterado, grava em sync/<versao>-<commit>/ o original antigo, o novo e o diff.
  5. Atualiza upstream/, VERSION e sync/pending.json (lista do que falta traduzir).

.PARAMETER Ref
  Branch, tag ou commit do github/spec-kit (padrão: main).

.PARAMETER NoInstall
  Usa a `specify` já instalada em vez de reinstalar.

.PARAMETER CheckOnly
  Só verifica. Não altera o pacote. Sai com código 2 se houver mudanças.

.EXAMPLE
  .\scripts\sync-upstream.ps1
  .\scripts\sync-upstream.ps1 -Ref v1.0.12
  .\scripts\sync-upstream.ps1 -CheckOnly
#>
[CmdletBinding()]
param(
    [string]$Ref = 'main',
    [switch]$NoInstall,
    [switch]$CheckOnly,
    [switch]$KeepTemp
)

. (Join-Path $PSScriptRoot 'common.ps1')

$current = Get-PackVersion

# 1. Instala / resolve a versão do upstream
if (-not $NoInstall) {
    Write-Step "Instalando specify-cli do github/spec-kit@$Ref"
    $inst = Invoke-Native -Exe 'uv' -Arguments @('tool', 'install', 'specify-cli', '--force', '--from', "git+https://github.com/github/spec-kit.git@$Ref")
    if ($inst.ExitCode -ne 0) {
        Write-Fail 'Falha ao instalar specify-cli via uv'
        ($inst.Output -split "`n" | Select-Object -Last 10) | ForEach-Object { Write-Host "      $_" }
        exit 1
    }
}
$newVersion = Get-InstalledSpecifyVersion
if (-not $newVersion) { Write-Fail 'CLI specify não encontrada após a instalação'; exit 1 }

$newCommit = ''
$ls = Invoke-Native -Exe 'git' -Arguments @('ls-remote', 'https://github.com/github/spec-kit.git', $Ref)
if ($ls.ExitCode -eq 0 -and $ls.Output -match '^([0-9a-f]{40})') { $newCommit = $Matches[1] }
if (-not $newCommit) { $newCommit = 'desconhecido' }
$shortCommit = $newCommit.Substring(0, [Math]::Min(7, $newCommit.Length))

Write-Step "Upstream instalado: $newVersion ($shortCommit) | pacote acompanha: $($current.upstream_version) ($($current.upstream_commit.Substring(0,7)))"

# 2. Projeto temporário
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("speckit-sync-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
Write-Step "Gerando projeto de referência em $tmp"
$init = Invoke-Native -Exe 'specify' -Arguments @('init', $tmp, '--integration', $current.integration, '--script', $current.script, '--non-interactive', '--ignore-agent-tools')
if ($init.ExitCode -ne 0 -or -not (Test-Path (Join-Path $tmp '.specify/templates/spec-template.md'))) {
    Write-Fail "specify init falhou no projeto temporário (código $($init.ExitCode))"
    ($init.Output -split "`n" | Where-Object { $_ -notmatch '█|╗|╝|═' -and $_.Trim() } | Select-Object -Last 15) | ForEach-Object { Write-Host "      $_" }
    exit 1
}

# 2b. Projeto de referência na variante sh (só os skills diferem; usados pelo validate.ps1)
$tmpSh = "$tmp-sh"
if (Test-Path $tmpSh) { Remove-Item -Recurse -Force $tmpSh }
$initSh = Invoke-Native -Exe 'specify' -Arguments @('init', $tmpSh, '--integration', $current.integration, '--script', 'sh', '--non-interactive', '--ignore-agent-tools')
if ($initSh.ExitCode -ne 0 -or -not (Test-Path (Join-Path $tmpSh '.claude/skills/speckit-specify/SKILL.md'))) {
    Write-Fail "specify init (variante sh) falhou (código $($initSh.ExitCode))"
    exit 1
}

# 3. Comparação
$upstreamDir = Join-Path $script:PackRoot 'upstream'
$upstreamShDir = Join-Path $script:PackRoot 'upstream-sh'
$changed = @()
$missingInNew = @()
foreach ($rel in $script:UpstreamFiles) {
    $newFile = Join-Path $tmp $rel
    $oldFile = Join-Path $upstreamDir $rel
    if (-not (Test-Path $newFile)) { $missingInNew += $rel; continue }
    $newHash = Get-NormalizedTextHash $newFile
    $oldHash = Get-NormalizedTextHash $oldFile
    if ($newHash -ne $oldHash) { $changed += $rel }
}

# Arquivos novos que o upstream passou a gerar e o pacote ainda não conhece (skills novos, por exemplo)
$newSkills = @()
$skillsDir = Join-Path $tmp '.claude/skills'
if (Test-Path $skillsDir) {
    foreach ($d in Get-ChildItem $skillsDir -Directory) {
        $rel = ".claude/skills/$($d.Name)/SKILL.md"
        if ($script:UpstreamFiles -notcontains $rel -and (Test-Path (Join-Path $tmp $rel))) { $newSkills += $rel }
    }
}

if ($missingInNew.Count -gt 0) {
    Write-Warn2 "O upstream não gera mais estes arquivos (remover da lista em common.ps1 se for definitivo):"
    $missingInNew | ForEach-Object { Write-Host "      - $_" }
}
if ($newSkills.Count -gt 0) {
    Write-Warn2 "Skills novos no upstream que o pacote ainda não traduz (adicionar em common.ps1 e traduzir):"
    $newSkills | ForEach-Object { Write-Host "      - $_" }
}

function Update-UpstreamShSkills {
    foreach ($rel in ($script:UpstreamFiles | Where-Object { $_ -like '*.claude/skills/*' })) {
        $src = Join-Path $tmpSh $rel
        if (Test-Path $src) { Copy-WithDirs -Source $src -Destination (Join-Path $upstreamShDir $rel) }
    }
}
function Remove-TempDirs {
    if ($KeepTemp) { return }
    if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
    if (Test-Path $tmpSh) { Remove-Item -Recurse -Force $tmpSh }
}

if ($changed.Count -eq 0) {
    Write-Ok "Nenhum dos $($script:UpstreamFiles.Count) arquivos acompanhados mudou. Pacote está alinhado com $newVersion."
    if (-not $CheckOnly) { Update-UpstreamShSkills }
    # Só registra versão nova quando o número de versão muda. Commits do upstream que não tocam
    # nos arquivos acompanhados não alteram VERSION, para não gerar pull request de ruído.
    if (-not $CheckOnly -and $newVersion -ne $current.upstream_version) {
        $current.upstream_version = $newVersion
        $current.upstream_ref = $Ref
        $current.upstream_commit = $newCommit
        $current.synced_at = (Get-Date).ToString('yyyy-MM-dd')
        Set-PackVersion $current
        Write-Ok "VERSION atualizado para $newVersion ($shortCommit) sem retradução necessária"
    }
    Remove-TempDirs
    exit 0
}

Write-Step "$($changed.Count) arquivo(s) mudaram no upstream:"
$changed | ForEach-Object { Write-Host "      - $_" }

if ($CheckOnly) {
    Remove-TempDirs
    exit 2
}

# 4. Grava old/new/diff
$syncId = "$newVersion-$shortCommit"
$syncDir = Join-Path $script:PackRoot "sync/$syncId"
New-Item -ItemType Directory -Force -Path $syncDir | Out-Null
$changes = @()
$changes += "# Mudanças no upstream: $($current.upstream_version) -> $newVersion ($shortCommit)"
$changes += ''
$changes += "Data: $(Get-Date -Format 'yyyy-MM-dd')"
$changes += ''
foreach ($rel in $changed) {
    $oldFile = Join-Path $upstreamDir $rel
    $newFile = Join-Path $tmp $rel
    $safe = ($rel -replace '[\\/]', '__')
    if (Test-Path $oldFile) { Copy-WithDirs -Source $oldFile -Destination (Join-Path $syncDir "old/$rel") }
    Copy-WithDirs -Source $newFile -Destination (Join-Path $syncDir "new/$rel")
    $diff = ''
    if (Test-Path $oldFile) {
        # git diff --no-index retorna 1 quando há diferenças; isso é o esperado aqui.
        # Roda dentro de sync/<id>/ para o cabeçalho sair como a/old/... b/new/...
        Push-Location $syncDir
        try {
            $d = Invoke-Native -Exe 'git' -Arguments @('-c', 'core.autocrlf=false', '-c', 'core.safecrlf=false', 'diff', '--no-index', '--no-color', '--', "old/$rel", "new/$rel")
        } finally { Pop-Location }
        $diff = ($d.Output -split "`n" | Where-Object { $_ -notmatch '^warning: ' }) -join "`n"
        if (-not $diff.EndsWith("`n")) { $diff += "`n" }
    } else {
        $diff = "(arquivo novo no upstream)`n"
    }
    Write-Utf8 -Path (Join-Path $syncDir "diff/$safe.diff") -Content $diff
    # Conta linhas adicionadas/removidas ignorando os cabeçalhos +++/--- do diff
    $addLines = ([regex]::Matches($diff, '(?m)^\+(?!\+\+ )')).Count
    $delLines = ([regex]::Matches($diff, '(?m)^-(?!-- )')).Count
    $changes += "- ``$rel``  (+$addLines / -$delLines linhas)"
}
$changes += ''
$changes += 'Próximo passo: `scripts/translate-pending.ps1` (ou traduza manualmente usando os diffs acima) e depois `scripts/validate.ps1`.'
Write-Utf8 -Path (Join-Path $syncDir 'CHANGES.md') -Content (($changes -join "`n") + "`n")

# 5. Atualiza upstream/, upstream-sh/, VERSION e pending.json
foreach ($rel in $changed) {
    Copy-WithDirs -Source (Join-Path $tmp $rel) -Destination (Join-Path $upstreamDir $rel)
}
Update-UpstreamShSkills
$current.upstream_version = $newVersion
$current.upstream_ref = $Ref
$current.upstream_commit = $newCommit
$current.synced_at = (Get-Date).ToString('yyyy-MM-dd')
Set-PackVersion $current

$pending = @{
    sync_id          = $syncId
    upstream_version = $newVersion
    upstream_commit  = $newCommit
    created_at       = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')
    files            = $changed
    new_skills       = $newSkills
}
Write-Utf8 -Path (Join-Path $script:PackRoot 'sync/pending.json') -Content ($pending | ConvertTo-Json -Depth 3)

Remove-TempDirs

Write-Host ''
Write-Ok "upstream/ e VERSION atualizados para $newVersion ($shortCommit)"
Write-Ok "Diffs em sync/$syncId/  |  pendências em sync/pending.json"
Write-Host ''
Write-Host 'A pasta ptbr/ ainda está na tradução anterior. Rode agora:' -ForegroundColor Yellow
Write-Host '  .\scripts\translate-pending.ps1     # traduz só os trechos alterados com o Claude Code' -ForegroundColor Yellow
Write-Host '  .\scripts\validate.ps1              # confere integridade' -ForegroundColor Yellow
exit 0
