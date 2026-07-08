param(
    [string] $CodexRoot = (Join-Path $env:USERPROFILE "Documents\Codex"),
    [string] $ExternalSkillsRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$configPath = Join-Path $CodexRoot "external-skills.config.json"

if (-not $ExternalSkillsRoot) {
    $ExternalSkillsRoot = Join-Path $CodexRoot "external-skills"

    if (Test-Path -LiteralPath $configPath) {
        $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
        if ($config.externalSkillsRoot) {
            $configuredRoot = [Environment]::ExpandEnvironmentVariables([string]$config.externalSkillsRoot)
            if (-not [System.IO.Path]::IsPathRooted($configuredRoot)) {
                $configuredRoot = Join-Path $CodexRoot $configuredRoot
            }
            $ExternalSkillsRoot = [System.IO.Path]::GetFullPath($configuredRoot)
        }
    }
}

$repos = @()
if (Test-Path -LiteralPath $ExternalSkillsRoot) {
    $repos = @(
        Get-ChildItem -LiteralPath $ExternalSkillsRoot -Directory |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName ".git") } |
            Sort-Object -Property Name |
            Select-Object -ExpandProperty FullName
    )
}

$logRoot = Join-Path $CodexRoot "logs"
$runStarted = Get-Date
$stamp = $runStarted.ToString("yyyyMMdd-HHmmss")
$latestReportPath = Join-Path $logRoot "external-skills-update-latest.md"
$historyReportPath = Join-Path $logRoot "external-skills-update-$stamp.md"
$plainLogPath = Join-Path $logRoot "external-skills-update.log"
$easyReportPath = Join-Path $CodexRoot "external-skills-update-latest.md"
$statusPath = Join-Path $CodexRoot "external-skills-update-status.txt"

New-Item -ItemType Directory -Force -Path $logRoot | Out-Null

$originalLocation = Get-Location
$results = @()

function Invoke-GitCommand {
    param(
        [Parameter(Mandatory = $true)] [string] $Repo,
        [Parameter(Mandatory = $true)] [string[]] $Arguments
    )

    $output = & git -C $Repo @Arguments 2>&1
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    }
}

function Get-GitText {
    param(
        [Parameter(Mandatory = $true)] [string] $Repo,
        [Parameter(Mandatory = $true)] [string[]] $Arguments
    )

    $result = Invoke-GitCommand -Repo $Repo -Arguments $Arguments
    if ($result.ExitCode -ne 0) {
        return ""
    }

    return $result.Output.Trim()
}

function Show-UpdatePopup {
    param(
        [Parameter(Mandatory = $true)] [string] $Title,
        [Parameter(Mandatory = $true)] [string] $Message
    )

    try {
        $shell = New-Object -ComObject WScript.Shell
        $shell.Popup($Message, 20, $Title, 0x40) | Out-Null
    }
    catch {
        # Popups are best-effort; reports remain canonical.
    }
}

try {
    if (-not (Test-Path -LiteralPath $ExternalSkillsRoot)) {
        throw "External skills root does not exist: $ExternalSkillsRoot"
    }

    if ($repos.Count -eq 0) {
        throw "No Git repositories were found under: $ExternalSkillsRoot"
    }

    foreach ($repo in $repos) {
        Write-Host ""
        Write-Host "Updating: $repo"

        $repoName = Split-Path -Leaf $repo
        $status = "Success"
        $message = ""
        $before = ""
        $after = ""
        $branch = ""
        $remote = ""
        $pullOutput = ""

        try {
            $branch = Get-GitText -Repo $repo -Arguments @("branch", "--show-current")
            $remote = Get-GitText -Repo $repo -Arguments @("remote", "get-url", "origin")
            $before = Get-GitText -Repo $repo -Arguments @("rev-parse", "--short", "HEAD")

            $fetch = Invoke-GitCommand -Repo $repo -Arguments @("fetch", "--prune")
            if ($fetch.ExitCode -ne 0) {
                throw "git fetch --prune failed.`n$($fetch.Output)"
            }

            $pull = Invoke-GitCommand -Repo $repo -Arguments @("pull", "--ff-only")
            $pullOutput = $pull.Output.Trim()
            if ($pull.ExitCode -ne 0) {
                throw "git pull --ff-only failed.`n$pullOutput"
            }

            $after = Get-GitText -Repo $repo -Arguments @("rev-parse", "--short", "HEAD")

            if ($before -eq $after) {
                $message = "Already up to date."
            }
            else {
                $message = "Updated from $before to $after."
            }
        }
        catch {
            $status = "Failed"
            $message = $_.Exception.Message.Trim()
            if (-not $after -and (Test-Path -LiteralPath (Join-Path $repo ".git"))) {
                $after = Get-GitText -Repo $repo -Arguments @("rev-parse", "--short", "HEAD")
            }
        }

        $results += [pscustomobject]@{
            Name = $repoName
            Path = $repo
            Branch = $branch
            Remote = $remote
            Before = $before
            After = $after
            Status = $status
            Message = $message
            PullOutput = $pullOutput
        }
    }
}
catch {
    $results += [pscustomobject]@{
        Name = "external-skills-scan"
        Path = $ExternalSkillsRoot
        Branch = ""
        Remote = ""
        Before = ""
        After = ""
        Status = "Failed"
        Message = $_.Exception.Message.Trim()
        PullOutput = ""
    }
}
finally {
    Set-Location -LiteralPath $originalLocation
}

$runFinished = Get-Date
$failedCount = @($results | Where-Object { $_.Status -ne "Success" }).Count
$updatedCount = @($results | Where-Object { $_.Status -eq "Success" -and $_.Before -and $_.After -and $_.Before -ne $_.After }).Count
$okCount = @($results | Where-Object { $_.Status -eq "Success" }).Count

$report = New-Object System.Collections.Generic.List[string]
$report.Add("# External Skills Update Report")
$report.Add("")
$report.Add("- Started: $($runStarted.ToString("yyyy-MM-dd HH:mm:ss"))")
$report.Add("- Finished: $($runFinished.ToString("yyyy-MM-dd HH:mm:ss"))")
$report.Add("- External skills root: $ExternalSkillsRoot")
$report.Add("- Total repositories: $($results.Count)")
$report.Add("- Successful: $okCount")
$report.Add("- Updated: $updatedCount")
$report.Add("- Failed: $failedCount")
$report.Add("")
$report.Add("| Repository | Branch | Before | After | Status | Message |")
$report.Add("|---|---:|---:|---:|---|---|")

foreach ($result in $results) {
    $safeMessage = ($result.Message -replace "\|", "\|" -replace "`r?`n", "<br>")
    $report.Add("| $($result.Name) | $($result.Branch) | $($result.Before) | $($result.After) | $($result.Status) | $safeMessage |")
}

$report.Add("")
$report.Add("## Details")

foreach ($result in $results) {
    $report.Add("")
    $report.Add("### $($result.Name)")
    $report.Add("")
    $report.Add(('- Path: `{0}`' -f $result.Path))
    $report.Add(('- Remote: `{0}`' -f $result.Remote))
    $report.Add("- Status: $($result.Status)")
    $report.Add("- Message: $($result.Message)")

    if ($result.PullOutput) {
        $report.Add("")
        $report.Add('```text')
        $report.Add($result.PullOutput)
        $report.Add('```')
    }
}

$reportText = $report -join "`r`n"
Set-Content -LiteralPath $latestReportPath -Value $reportText -Encoding UTF8
Set-Content -LiteralPath $historyReportPath -Value $reportText -Encoding UTF8
Set-Content -LiteralPath $easyReportPath -Value $reportText -Encoding UTF8

$summaryLine = "{0} total={1} success={2} updated={3} failed={4} report={5}" -f $runFinished.ToString("yyyy-MM-dd HH:mm:ss"), $results.Count, $okCount, $updatedCount, $failedCount, $easyReportPath
Add-Content -LiteralPath $plainLogPath -Value $summaryLine -Encoding UTF8

$failedRepos = @($results | Where-Object { $_.Status -ne "Success" } | ForEach-Object { $_.Name })
$updatedRepos = @($results | Where-Object { $_.Status -eq "Success" -and $_.Before -and $_.After -and $_.Before -ne $_.After } | ForEach-Object { $_.Name })
$status = if ($failedCount -gt 0) { "FAILED" } elseif ($updatedCount -gt 0) { "UPDATED" } else { "OK" }

$statusLines = New-Object System.Collections.Generic.List[string]
$statusLines.Add("Status: $status")
$statusLines.Add("Finished: $($runFinished.ToString("yyyy-MM-dd HH:mm:ss"))")
$statusLines.Add("Repositories: $($results.Count)")
$statusLines.Add("Successful: $okCount")
$statusLines.Add("Updated: $updatedCount")
$statusLines.Add("Failed: $failedCount")
$statusLines.Add("Latest report: $easyReportPath")

if ($updatedRepos.Count -gt 0) {
    $statusLines.Add("Updated repositories: $($updatedRepos -join ', ')")
}

if ($failedRepos.Count -gt 0) {
    $statusLines.Add("Failed repositories: $($failedRepos -join ', ')")
}

Set-Content -LiteralPath $statusPath -Value ($statusLines -join "`r`n") -Encoding UTF8

if ($failedCount -gt 0) {
    Show-UpdatePopup -Title "Codex skills update failed" -Message "$failedCount external skill repository update(s) failed. See:`n$easyReportPath"
}
elseif ($updatedCount -gt 0) {
    Show-UpdatePopup -Title "Codex skills updated" -Message "$updatedCount external skill repository/repositories updated. Restart Codex to load changes.`n$easyReportPath"
}

Write-Host ""
Write-Host "Report written to: $latestReportPath"
Write-Host "History report: $historyReportPath"
Write-Host "Quick status: $statusPath"

if ($failedCount -eq 0) {
    if ($updatedCount -gt 0) {
        Write-Host "$updatedCount external skill repository/repositories updated."
        Write-Host "Restart Codex to load skill changes."
    }
    else {
        Write-Host "All external skills are up to date."
        Write-Host "No Codex restart is needed for skill updates."
    }
    exit 0
}

Write-Warning "$failedCount external skill repository update(s) failed. See the report for details."
exit 1
