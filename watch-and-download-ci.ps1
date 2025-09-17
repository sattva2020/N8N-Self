# Watcher script for GitHub Actions runs and artifact downloader
# Saves artifacts and workflow logs into ./ci-artifacts/<run_id>
# Usage: pwsh -NoProfile -File .\watch-and-download-ci.ps1

param(
    [string]$Owner = 'sattva2020',
    [string]$Repo = 'N8N-Self',
    [string]$Branch = 'feature/ci-e2e-simple-serve',
    [int]$PollIntervalSec = 10
)

function Fail($msg) {
    Write-Error $msg
    exit 2
}

if (-not $env:GITHUB_TOKEN) {
    Fail "GITHUB_TOKEN is not set in the environment. Please set it before running this script."
}

$headers = @{ Authorization = "Bearer $env:GITHUB_TOKEN"; "User-Agent" = "ci-watcher-script" }
$base = "https://api.github.com/repos/$Owner/$Repo/actions"

Write-Host "Looking up latest workflow run for branch '$Branch'..."
$runsUrl = "$base/runs?branch=$Branch&per_page=1"
try {
    $resp = Invoke-RestMethod -Headers $headers -Uri $runsUrl -Method Get -ErrorAction Stop
} catch {
    Fail "Failed to query workflow runs: $($_.Exception.Message)"
}

if (-not $resp.workflow_runs -or $resp.workflow_runs.Count -eq 0) {
    Fail "No workflow runs found for branch $Branch."
}

$run = $resp.workflow_runs[0]
$runId = $run.id
Write-Host "Found run id: $runId  (workflow: $($run.name), status: $($run.status), conclusion: $($run.conclusion))"

# Poll until completed
while ($true) {
    Start-Sleep -Seconds $PollIntervalSec
    try {
        $statusResp = Invoke-RestMethod -Headers $headers -Uri "$base/runs/$runId" -Method Get -ErrorAction Stop
    } catch {
        Write-Warning "Failed to fetch run status (will retry): $($_.Exception.Message)"
        continue
    }
    $status = $statusResp.status
    $conclusion = $statusResp.conclusion
    Write-Host "$(Get-Date -Format s) - status=$status, conclusion=$conclusion"
    if ($status -eq 'completed') { break }
}

if ($conclusion -eq $null) { $conclusion = 'unknown' }
Write-Host "Run $runId completed with conclusion: $conclusion"

# Prepare output dir
$outDir = Join-Path -Path (Get-Location) -ChildPath "ci-artifacts\$runId"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# Download logs (zip)
$logsUrl = "$base/runs/$runId/logs"
$logsFile = Join-Path $outDir "workflow-logs-$runId.zip"
Write-Host "Downloading workflow logs to $logsFile ..."
try {
    Invoke-WebRequest -Headers $headers -Uri $logsUrl -OutFile $logsFile -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Warning "Failed to download workflow logs: $($_.Exception.Message)"
}

# List and download artifacts
$artifactsResp = Invoke-RestMethod -Headers $headers -Uri "$base/runs/$runId/artifacts" -Method Get
if ($artifactsResp.total_count -gt 0) {
    foreach ($a in $artifactsResp.artifacts) {
        $aid = $a.id; $aname = $a.name
        $safeName = ($aname -replace '[^a-zA-Z0-9._-]', '_')
        $dest = Join-Path $outDir "$safeName-$aid.zip"
        Write-Host "Downloading artifact '$aname' (id=$aid) -> $dest"
        $downloadUrl = "https://api.github.com/repos/$Owner/$Repo/actions/artifacts/$aid/zip"
        try {
            Invoke-WebRequest -Headers $headers -Uri $downloadUrl -OutFile $dest -UseBasicParsing -ErrorAction Stop
        } catch {
            Write-Warning "Failed to download artifact $aname (id=$aid): $($_.Exception.Message)"
        }
    }
} else {
    Write-Host "No artifacts found for run $runId."
}

Write-Host "Finished. Files saved to: $outDir"
Write-Host "Conclusion: $conclusion"
if ($conclusion -ne 'success') { exit 3 } else { exit 0 }
