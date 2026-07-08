param(
    [string] $TaskName = "CodexUpdateExternalSkills",
    [string] $CodexRoot = (Join-Path $env:USERPROFILE "Documents\Codex"),
    [string] $Time = "09:00"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $CodexRoot "update-external-skills.ps1"
if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Update script not found: $scriptPath"
}

$action = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
schtasks /Create /TN $TaskName /SC DAILY /ST $Time /TR $action /F

if ($LASTEXITCODE -ne 0) {
    throw "Failed to create scheduled task: $TaskName"
}

Write-Host "Scheduled task created: $TaskName"
Write-Host "Daily time: $Time"
Write-Host "Action: $action"
