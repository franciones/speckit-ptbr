<#
.SYNOPSIS
  Verifica a integridade estrutural da tradução em ptbr/ contra os originais em upstream/.

.DESCRIPTION
  Para cada arquivo acompanhado confere que a tradução não quebrou o que os comandos e scripts do
  Spec Kit dependem: frontmatter, $ARGUMENTS, chaves de hooks, caminhos de scripts, blocos de código,
  marcadores NEEDS CLARIFICATION, linhas de tarefa e placeholders da constituição.
  Sai com código 1 se houver qualquer falha.
#>
[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot 'common.ps1')

$ptDir = Join-Path $script:PackRoot 'ptbr'
$upDir = Join-Path $script:PackRoot 'upstream'
$failures = @()
$checked = 0

function Count-Matches { param([string]$Text, [string]$Pattern) return ([regex]::Matches($Text, $Pattern)).Count }
function Set-Of { param([string]$Text, [string]$Pattern)
    return @([regex]::Matches($Text, $Pattern) | ForEach-Object { $_.Value } | Sort-Object -Unique)
}
function Assert-Equal { param([string]$Label, $Expected, $Actual, [string]$File)
    if ("$Expected" -ne "$Actual") { $script:failures += "$File | $Label | upstream=$Expected ptbr=$Actual" }
}
function Assert-SetEqual { param([string]$Label, [string[]]$Expected, [string[]]$Actual, [string]$File)
    $missing = @($Expected | Where-Object { $Actual -notcontains $_ })
    $extra = @($Actual | Where-Object { $Expected -notcontains $_ })
    if ($missing.Count -gt 0) { $script:failures += "$File | $Label faltando: $($missing -join ', ')" }
    if ($extra.Count -gt 0) { $script:failures += "$File | $Label a mais: $($extra -join ', ')" }
}

foreach ($rel in $script:UpstreamFiles) {
    $pt = Join-Path $ptDir $rel
    $up = Join-Path $upDir $rel
    if (-not (Test-Path $up)) { $failures += "$rel | original ausente em upstream/"; continue }
    if (-not (Test-Path $pt)) { $failures += "$rel | tradução ausente em ptbr/"; continue }
    $checked++
    $u = Read-Utf8 $up
    $p = Read-Utf8 $pt

    if ($rel -like '*.claude/skills/*') {
        $pLines = $p -split "`r?`n"
        if ($pLines[0] -ne '---') { $failures += "$rel | frontmatter não começa na linha 1" }
        $uName = [regex]::Match($u, '(?m)^name:\s*.*$').Value
        $pName = [regex]::Match($p, '(?m)^name:\s*.*$').Value
        Assert-Equal 'frontmatter name' $uName $pName $rel
        foreach ($key in @('compatibility', 'user-invocable', 'disable-model-invocation', 'author', 'source')) {
            $uv = [regex]::Match($u, "(?m)^\s*$key`:\s*.*$").Value.Trim()
            $pv = [regex]::Match($p, "(?m)^\s*$key`:\s*.*$").Value.Trim()
            Assert-Equal "frontmatter $key" $uv $pv $rel
        }
        if ($p -notmatch '## Idioma de saída') { $failures += "$rel | bloco 'Idioma de saída' ausente" }
        Assert-Equal 'contagem de $ARGUMENTS' (Count-Matches $u '\$ARGUMENTS') (Count-Matches $p '\$ARGUMENTS') $rel
        Assert-SetEqual 'chaves hooks.*' (Set-Of $u 'hooks\.[a-z_]+') (Set-Of $p 'hooks\.[a-z_]+') $rel
        Assert-SetEqual 'scripts .ps1' (Set-Of $u '\.specify/scripts/powershell/[a-z-]+\.ps1') (Set-Of $p '\.specify/scripts/powershell/[a-z-]+\.ps1') $rel
        Assert-SetEqual 'comandos /speckit-*' (Set-Of $u '/speckit-[a-z]+') (Set-Of $p '/speckit-[a-z]+') $rel
        Assert-Equal 'cercas de código' (Count-Matches $u '(?m)^\s*```') (Count-Matches $p '(?m)^\s*```') $rel
        Assert-Equal 'EXECUTE_COMMAND' (Count-Matches $u 'EXECUTE_COMMAND') (Count-Matches $p 'EXECUTE_COMMAND') $rel
        Assert-Equal 'NEEDS CLARIFICATION' (Count-Matches $u 'NEEDS CLARIFICATION') (Count-Matches $p 'NEEDS CLARIFICATION') $rel
        # Títulos de seção em inglês que os templates pt-BR não usam mais
        $leftover = Set-Of $p '(?m)^#{2,3} (Requirements|Success Criteria|User Scenarios & Testing|Clarifications|Technical Context|Constitution Check|Project Structure|Complexity Tracking|Functional Requirements|Key Entities|Edge Cases|Assumptions)\s*$'
        if ($leftover.Count -gt 0) { $failures += "$rel | títulos em inglês restantes: $($leftover -join '; ')" }
    }
    elseif ($rel -like '*spec-template.md') {
        Assert-Equal 'NEEDS CLARIFICATION' (Count-Matches $u 'NEEDS CLARIFICATION') (Count-Matches $p 'NEEDS CLARIFICATION') $rel
        Assert-SetEqual 'IDs FR/SC' (Set-Of $u '\b(FR|SC)-\d{3}\b') (Set-Of $p '\b(FR|SC)-\d{3}\b') $rel
        Assert-Equal '$ARGUMENTS' (Count-Matches $u '\$ARGUMENTS') (Count-Matches $p '\$ARGUMENTS') $rel
        foreach ($h in @('## Cenários de Usuário e Testes', '### Casos Extremos', '## Requisitos', '### Requisitos Funcionais', '### Entidades Principais', '## Critérios de Sucesso', '### Resultados Mensuráveis', '## Premissas')) {
            if ($p -notmatch [regex]::Escape($h)) { $failures += "$rel | título esperado ausente: $h" }
        }
    }
    elseif ($rel -like '*plan-template.md') {
        Assert-Equal 'NEEDS CLARIFICATION' (Count-Matches $u 'NEEDS CLARIFICATION') (Count-Matches $p 'NEEDS CLARIFICATION') $rel
        foreach ($h in @('## Resumo', '## Contexto Técnico', '## Verificação da Constituição', '## Estrutura do Projeto', '## Rastreamento de Complexidade')) {
            if ($p -notmatch [regex]::Escape($h)) { $failures += "$rel | título esperado ausente: $h" }
        }
        Assert-SetEqual 'arquivos de saída' (Set-Of $u '(research|data-model|quickstart|tasks|plan)\.md') (Set-Of $p '(research|data-model|quickstart|tasks|plan)\.md') $rel
    }
    elseif ($rel -like '*tasks-template.md') {
        Assert-Equal 'linhas de tarefa' (Count-Matches $u '(?m)^- \[ \] T[0-9X]{3}') (Count-Matches $p '(?m)^- \[ \] T[0-9X]{3}') $rel
        Assert-Equal 'marcadores [P]' (Count-Matches $u '\[P\]') (Count-Matches $p '\[P\]') $rel
        Assert-SetEqual 'rótulos [USn]' (Set-Of $u '\[US\d\]') (Set-Of $p '\[US\d\]') $rel
        Assert-Equal 'títulos ## Fase' (Count-Matches $u '(?m)^## Phase ') (Count-Matches $p '(?m)^## Fase ') $rel
        foreach ($h in @('## Fase 1: Configuração Inicial', '## Fase 2: Fundacional', '## Fase N: Polimento e Aspectos Transversais', '## Dependências e Ordem de Execução', '## Estratégia de Implementação')) {
            if ($p -notmatch [regex]::Escape($h)) { $failures += "$rel | título esperado ausente: $h" }
        }
    }
    elseif ($rel -like '*checklist-template.md') {
        Assert-SetEqual 'IDs CHK' (Set-Of $u 'CHK\d{3}') (Set-Of $p 'CHK\d{3}') $rel
        Assert-SetEqual 'comandos /speckit-*' (Set-Of $u '/speckit-[a-z]+') (Set-Of $p '/speckit-[a-z]+') $rel
    }
    elseif ($rel -like '*constitution*') {
        Assert-SetEqual 'placeholders' (Set-Of $u '\[[A-Z][A-Z0-9_]{2,}\]') (Set-Of $p '\[[A-Z][A-Z0-9_]{2,}\]') $rel
        if ($p -notmatch '## Governança') { $failures += "$rel | título '## Governança' ausente" }
        if ($p -notmatch '## Idioma e Terminologia') { $failures += "$rel | seção '## Idioma e Terminologia' ausente" }
    }
}

# Consistência interna: constituição inicial deve ser igual ao template de constituição
$ctpl = Read-Utf8 (Join-Path $ptDir '.specify/templates/constitution-template.md')
$cmem = Read-Utf8 (Join-Path $ptDir '.specify/memory/constitution.md')
if ($ctpl -ne $cmem) { $failures += '.specify/memory/constitution.md | difere de constitution-template.md (devem ser idênticos no pacote)' }

# CLAUDE.md do pacote precisa das seções que os skills referenciam
$claudeMd = Read-Utf8 (Join-Path $ptDir 'CLAUDE.md')
foreach ($h in @('## Idioma de saída', '## Glossário', '## Mapa de títulos de seção')) {
    if ($claudeMd -notmatch [regex]::Escape($h)) { $failures += "CLAUDE.md | seção ausente: $h" }
}

Write-Host ''
if ($failures.Count -eq 0) {
    Write-Ok "Validação passou: $checked arquivos conferidos contra o upstream."
    exit 0
}
Write-Fail "Validação encontrou $($failures.Count) problema(s):"
$failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
exit 1
