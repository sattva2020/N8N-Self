$token = gh auth token
if (-not $token) { Write-Error 'gh auth token not available'; exit 2 }
$headers = @{ 'Authorization' = 'Bearer ' + $token }
$logsUrl = 'https://api.github.com/repos/sattva2020/N8N-Self/actions/runs/17637773660/logs'
$out = 'E:\AI\N8N\ci-artifacts\17637773660\workflow-logs-17637773660.zip'
Write-Host "Downloading logs to $out"
Invoke-RestMethod -Headers $headers -Uri $logsUrl -Method Get -OutFile $out -ErrorAction Stop
Write-Host 'Done'
