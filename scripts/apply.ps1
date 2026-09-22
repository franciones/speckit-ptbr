<#
.SYNOPSIS
  Aplica a tradução pt-BR do Spec Kit sobre um projeto já inicializado com `specify init`.

.DESCRIPTION
  Copia os templates, a constituição e os skills traduzidos (pasta ptbr/) por cima do projeto,
  cria ou complementa o CLAUDE.md e grava .specify/ptbr.json com a versão aplicada.

.PARAMETER ProjectPath
  Raiz do projeto (padrão: diretório atual).

.PARAMETER Force
  Aplica mesmo se a versão da CLI `specify` instalada for diferente da versão acompanhada pelo pacote.

.EXAMPLE
  .\scripts\apply.ps1 -ProjectPath C:\Projetos\meu-projeto
#>
[CmdletBinding()]
param(
    [string]$ProjectPath = '.',
    [switch]$Force
)

. (Join-Path $PSScriptRoot 'common.ps1')

$ProjectPath = (Resolve-Path $ProjectPath).Path
$overlay = Join-Path $script:PackRoot 'ptbr'
$version = Get-PackVersion

Write-Step "Aplicando speckit-ptbr (upstream $($version.upstream_version)) em $ProjectPath"

# 1. Pré-condições
if (-not (Test-Path (Join-Path $ProjectPath '.specify'))) {
    Write-Fail "Pasta .specify não encontrada. Rode antes: specify init . --integration claude --script ps"
    exit 1
}
if (-not (Test-Path (Join-Path $ProjectPath '.claude/skills/speckit-specify/SKILL.md'))) {
    Write-Fail "Skills do Claude Code não encontrados em .claude/skills. Este pacote suporta apenas --integration claude."
    exit 1
}

$integrationFile = Join-Path $ProjectPath '.specify/integration.json'
if (Test-Path $integrationFile) {
    $integration = Get-Content $integrationFile -Raw | ConvertFrom-Json
    $scriptType = $null
    if ($integration.integration_settings -and $integration.integration_settings.claude) {
        $scriptType = $integration.integration_settings.claude.script
    }
    if ($scriptType -and $scriptType -ne $version.script) {
        Write-Warn2 "Projeto usa scripts '$scriptType', mas os skills traduzidos referenciam scripts '$($version.script)'. Reinicialize com --script $($version.script)."
        if (-not $Force) { exit 1 }
    }
    if ($integration.version -and $integration.version -ne $version.upstream_version) {
        Write-Warn2 "Projeto foi gerado pela specify $($integration.version); o pacote acompanha a $($version.upstream_version)."
        if (-not $Force) {
            Write-Warn2 "Use -Force para aplicar mesmo assim, ou rode scripts/sync-upstream.ps1 para atualizar o pacote."
            exit 1
        }
    }
}

# 2. Copia os arquivos traduzidos derivados do upstream
$applied = @()
foreach ($rel in $script:UpstreamFiles) {
    $src = Join-Path $overlay $rel
    $dst = Join-Path $ProjectPath $rel
    if (-not (Test-Path $src)) { Write-Warn2 "Arquivo ausente no pacote, pulando: $rel"; continue }
    Copy-WithDirs -Source $src -Destination $dst
    $applied += $rel
}
Write-Ok "$($applied.Count) arquivos traduzidos aplicados"

# 3. CLAUDE.md: cria ou complementa
$claudeSrc = Join-Path $overlay 'CLAUDE.md'
$claudeDst = Join-Path $ProjectPath 'CLAUDE.md'
$packBlock = Read-Utf8 $claudeSrc
if (Test-Path $claudeDst) {
    $existing = Read-Utf8 $claudeDst
    if ($existing -match '## Idioma de saída') {
        Write-Ok "CLAUDE.md já contém a seção de idioma, mantido"
    } else {
        Write-Utf8 -Path $claudeDst -Content ($existing.TrimEnd() + "`n`n" + $packBlock)
        Write-Ok "CLAUDE.md existente complementado com as regras de idioma"
    }
} else {
    Copy-WithDirs -Source $claudeSrc -Destination $claudeDst
    Write-Ok "CLAUDE.md criado"
}

# 4. Registro da aplicação
$stamp = @{
    pack_upstream_version = $version.upstream_version
    pack_upstream_commit  = $version.upstream_commit
    applied_at            = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')
    files                 = $applied
}
Write-Utf8 -Path (Join-Path $ProjectPath '.specify/ptbr.json') -Content ($stamp | ConvertTo-Json -Depth 3)
Write-Ok "Registro gravado em .specify/ptbr.json"

Write-Host ''
Write-Host 'Pronto. Abra o Claude Code no projeto e comece por /speckit-constitution.' -ForegroundColor Green
Write-Host 'Observação: um futuro `specify init --here` em versão nova vai detectar os arquivos editados e parar.' -ForegroundColor DarkGray
Write-Host 'Para atualizar, use o pacote: scripts/sync-upstream.ps1 e depois scripts/apply.ps1 -Force.' -ForegroundColor DarkGray
