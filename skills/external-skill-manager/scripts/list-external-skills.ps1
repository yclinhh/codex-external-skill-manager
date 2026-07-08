param(
    [string] $CodexRoot = (Join-Path $env:USERPROFILE "Documents\Codex")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$configPath = Join-Path $CodexRoot "external-skills.config.json"
$externalSkillsRoot = Join-Path $CodexRoot "external-skills"

if (Test-Path -LiteralPath $configPath) {
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    if ($config.externalSkillsRoot) {
        $configuredRoot = [Environment]::ExpandEnvironmentVariables([string]$config.externalSkillsRoot)
        if (-not [System.IO.Path]::IsPathRooted($configuredRoot)) {
            $configuredRoot = Join-Path $CodexRoot $configuredRoot
        }
        $externalSkillsRoot = [System.IO.Path]::GetFullPath($configuredRoot)
    }
}

Write-Host "External skills root: $externalSkillsRoot"
Write-Host ""
Write-Host "Git repositories:"
if (Test-Path -LiteralPath $externalSkillsRoot) {
    Get-ChildItem -LiteralPath $externalSkillsRoot -Directory |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName ".git") } |
        Sort-Object -Property Name |
        Select-Object Name, FullName |
        Format-Table -AutoSize
}
else {
    Write-Host "(missing)"
}

Write-Host ""
Write-Host "Codex skill links:"
$skillsRoot = Join-Path $env:USERPROFILE ".codex\skills"
if (Test-Path -LiteralPath $skillsRoot) {
    Get-ChildItem -LiteralPath $skillsRoot -Directory |
        Where-Object { $_.Name -ne ".system" } |
        Sort-Object -Property Name |
        Select-Object Name, LinkType, Target |
        Format-Table -AutoSize
}
else {
    Write-Host "(missing)"
}
