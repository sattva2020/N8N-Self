# Starts simple-serve.js with given PORT/HOST and writes PID to .tmp/simple-serve.pid
param(
    [string]$Port = '62000',
    [string]$ListenHost = '127.0.0.1',
    [int]$KeepSeconds = 60
)
Set-Location -LiteralPath (Split-Path -LiteralPath $MyInvocation.MyCommand.Path -Parent)
$env:PORT = $Port
$env:HOST = $ListenHost
$pidFile = Join-Path -Path (Get-Location) -ChildPath '.tmp\simple-serve.pid'
if (-not (Test-Path -Path (Split-Path $pidFile -Parent))) { New-Item -ItemType Directory -Path (Split-Path $pidFile -Parent) | Out-Null }
$p = Start-Process -FilePath 'node' -ArgumentList '.\scripts\simple-serve.js' -WorkingDirectory (Get-Location) -PassThru
$p.Id | Out-File -FilePath $pidFile -Encoding ascii
Write-Output "SIMPLE_SERVE_PID=$($p.Id)"
# keep process alive for a short time so callers can test and then stop it via PID
Start-Sleep -Seconds $KeepSeconds
