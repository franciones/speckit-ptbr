<#
.SYNOPSIS
  Cria um projeto Spec Kit novo já em pt-BR: roda `specify init` e aplica a tradução.

.PARAMETER Name
  Nome (ou caminho) do diretório do projeto. Use "." ou -Here para o diretório atual.

.PARAMETER Here
  Inicializa no diretório atual.

.PARAMETER Extension
  Extensões do Spec Kit a instalar no init (pode repetir, ex.: -Extension git).

.EXAMPLE
  .\scripts\new-project.ps1 -Name meu-projeto
  .\scripts\new-project.ps1 -Here
#>
[CmdletBinding()]
param(
    [string]$Name,
    [switch]$Here,
    [string[]]$Extension = @()
)

. (Join-Path $PSScriptRoot 'common.ps1')

if (-not $Here -and -not $Name) { Write-Fail 'Informe -Name <diretorio> ou -Here.'; exit 1 }

$version = Get-PackVersion
$installed = Get-InstalledSpecifyVersion
if (-not $installed) {
    Write-Fail 'CLI `specify` não encontrada. Instale com:'
    Write-Host '  uv tool install specify-cli --from git+https://github.com/github/spec-kit.git' -ForegroundColor Yellow
    exit 1
}
if ($installed -ne $version.upstream_version) {
    Write-Warn2 "specify instalada: $installed | pacote acompanha: $($version.upstream_version)"
    Write-Warn2 "Para alinhar: uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git@$($version.upstream_commit)"
}

$args = @('init')
if ($Here) { $args += '--here'; $args += '--force' } else { $args += $Name }
$args += @('--integration', $version.integration, '--script', $version.script, '--non-interactive')
foreach ($e in $Extension) { $args += @('--extension', $e) }

Write-Step "specify $($args -join ' ')"
& specify @args
if ($LASTEXITCODE -ne 0) { Write-Fail "specify init falhou (código $LASTEXITCODE)"; exit $LASTEXITCODE }

$target = '.'
if (-not $Here) { $target = $Name }
& (Join-Path $PSScriptRoot 'apply.ps1') -ProjectPath $target -Force
exit $LASTEXITCODE
