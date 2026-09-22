# Funções e listas compartilhadas pelos scripts do speckit-ptbr.
# Compatível com Windows PowerShell 5.1 e PowerShell 7+.

$ErrorActionPreference = 'Stop'

$script:PackRoot = Split-Path -Parent $PSScriptRoot

# Arquivos que vêm do upstream (github/spec-kit) e são traduzidos.
# Caminhos relativos à raiz de um projeto inicializado com:
#   specify init <nome> --integration claude --script ps
$script:UpstreamFiles = @(
    '.specify/templates/spec-template.md',
    '.specify/templates/plan-template.md',
    '.specify/templates/tasks-template.md',
    '.specify/templates/checklist-template.md',
    '.specify/templates/constitution-template.md',
    '.specify/memory/constitution.md',
    '.claude/skills/speckit-analyze/SKILL.md',
    '.claude/skills/speckit-checklist/SKILL.md',
    '.claude/skills/speckit-clarify/SKILL.md',
    '.claude/skills/speckit-constitution/SKILL.md',
    '.claude/skills/speckit-converge/SKILL.md',
    '.claude/skills/speckit-implement/SKILL.md',
    '.claude/skills/speckit-plan/SKILL.md',
    '.claude/skills/speckit-specify/SKILL.md',
    '.claude/skills/speckit-tasks/SKILL.md',
    '.claude/skills/speckit-taskstoissues/SKILL.md'
)

# Arquivos que pertencem ao pacote (não existem no upstream).
$script:PackOwnedFiles = @(
    'CLAUDE.md'
)

function Get-PackVersion {
    $result = @{}
    $versionFile = Join-Path $script:PackRoot 'VERSION'
    if (-not (Test-Path $versionFile)) { throw "Arquivo VERSION não encontrado em $script:PackRoot" }
    foreach ($line in Get-Content $versionFile) {
        if ($line -match '^\s*([A-Za-z_]+)\s*=\s*(.*)$') { $result[$Matches[1]] = $Matches[2].Trim() }
    }
    return $result
}

function Set-PackVersion {
    param([hashtable]$Values)
    $lines = @()
    foreach ($key in @('upstream_version', 'upstream_ref', 'upstream_commit', 'integration', 'script', 'synced_at')) {
        if ($Values.ContainsKey($key)) { $lines += "$key=$($Values[$key])" }
    }
    $versionFile = Join-Path $script:PackRoot 'VERSION'
    [System.IO.File]::WriteAllText($versionFile, ($lines -join "`n") + "`n", (New-Object System.Text.UTF8Encoding($false)))
}

function Get-InstalledSpecifyVersion {
    $cmd = Get-Command specify -ErrorAction SilentlyContinue
    if (-not $cmd) { return $null }
    $out = & specify version 2>&1 | Out-String
    if ($out -match 'CLI Version\s+(\S+)') { return $Matches[1] }
    return $null
}

function Get-FileHashSha256 {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Read-Utf8 {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Write-Utf8 {
    param([string]$Path, [string]$Content)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function Copy-WithDirs {
    param([string]$Source, [string]$Destination)
    $dir = Split-Path -Parent $Destination
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Copy-Item -Path $Source -Destination $Destination -Force
}

# Executa um programa externo capturando stdout+stderr como texto, sem que avisos em stderr
# virem exceção (comportamento do Windows PowerShell 5.1 com $ErrorActionPreference = 'Stop').
function Invoke-Native {
    param(
        [Parameter(Mandatory)][string]$Exe,
        [string[]]$Arguments = @(),
        [string]$StdinText = $null
    )
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    # PowerShell 7.4+ transforma código de saída diferente de zero em erro; aqui o código é tratado à mão.
    $prevNative = $null
    if (Test-Path variable:global:PSNativeCommandUseErrorActionPreference) {
        $prevNative = $global:PSNativeCommandUseErrorActionPreference
        $global:PSNativeCommandUseErrorActionPreference = $false
    }
    try {
        if ($null -ne $StdinText) {
            $raw = $StdinText | & $Exe @Arguments 2>&1
        } else {
            $raw = & $Exe @Arguments 2>&1
        }
        $code = $LASTEXITCODE
        $lines = @($raw | ForEach-Object {
            if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message } else { "$_" }
        })
        return @{ Output = ($lines -join "`n"); ExitCode = $code }
    } finally {
        $ErrorActionPreference = $prev
        if ($null -ne $prevNative) { $global:PSNativeCommandUseErrorActionPreference = $prevNative }
    }
}

function Write-Step { param([string]$Message) Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Message) Write-Host "    OK  $Message" -ForegroundColor Green }
function Write-Warn2 { param([string]$Message) Write-Host "    AVISO  $Message" -ForegroundColor Yellow }
function Write-Fail { param([string]$Message) Write-Host "    ERRO  $Message" -ForegroundColor Red }
