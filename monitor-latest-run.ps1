# Monitor latest workflow run for branch and download logs/artifacts using gh
$owner='sattva2020'
$repo='N8N-Self'
$branch='feature/ci-e2e-simple-serve'

Write-Host "Querying latest run for branch $branch..."
$run = gh api repos/$owner/$repo/actions/runs?branch=$branch --jq '.workflow_runs[0].id'
if (-not $run) {
  Write-Error "No runs found for branch $branch"
  exit 2
}
Write-Host "Latest run id: $run"
$outDir = Join-Path -Path (Get-Location) -ChildPath ("ci-artifacts\$run")
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Write-Host "Polling run $run status... (ctrl-c to cancel)"
while ($true) {
  $s = gh api repos/$owner/$repo/actions/runs/$run --jq '.status'
  $c = gh api repos/$owner/$repo/actions/runs/$run --jq '.conclusion'
  Write-Host (Get-Date -Format s) "status=$s, conclusion=$c"
  if ($s -eq 'completed') { break }
  Start-Sleep -Seconds 10
}

Write-Host "Run completed with conclusion: $c"
Write-Host 'Downloading workflow logs and artifacts...'
try {
  gh api repos/$owner/$repo/actions/runs/$run/logs --output (Join-Path $outDir ("workflow-logs-$run.zip"))
} catch {
  Write-Warning "Failed to download logs via gh api: $($_.Exception.Message)"
}
try {
  gh run download $run --repo $owner/$repo -D $outDir
} catch {
  Write-Warning "No artifacts or failed to download artifacts: $($_.Exception.Message)"
}
Write-Host "Done. Files saved to: $outDir"
exit 0
