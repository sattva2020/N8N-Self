$owner='sattva2020'
$repo='N8N-Self'
$run=17635903716
$child = 'ci-artifacts\' + $run.ToString()
$outDir = Join-Path -Path (Get-Location) -ChildPath $child
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Write-Host ('Polling run ' + $run + ' status...')
while ($true) {
  $s = gh api repos/$owner/$repo/actions/runs/$run --jq '.status'
  $c = gh api repos/$owner/$repo/actions/runs/$run --jq '.conclusion'
  Write-Host (Get-Date -Format s) "status=$s, conclusion=$c"
  if ($s -eq 'completed') { break }
  Start-Sleep -Seconds 8
}
Write-Host 'Run completed, downloading logs and artifacts...'
gh api repos/$owner/$repo/actions/runs/$run/logs --output (Join-Path $outDir "workflow-logs-$run.zip")
gh run download $run --repo $owner/$repo -D $outDir
Write-Host 'Done. Files in:' $outDir
