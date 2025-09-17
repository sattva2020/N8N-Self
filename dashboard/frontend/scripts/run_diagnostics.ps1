# Diagnostic script for simple-serve binding issues
Set-StrictMode -Version Latest
Set-Location -LiteralPath (Split-Path -LiteralPath $MyInvocation.MyCommand.Path -Parent)
Write-Output "PWD: $(Get-Location)"

# PID file
if (Test-Path .\tmp\simple-serve.pid) {
  $pid = Get-Content .\tmp\simple-serve.pid -ErrorAction SilentlyContinue
  Write-Output "PIDFILE: $pid"
  try { Get-Process -Id $pid -ErrorAction Stop | Select-Object Id, ProcessName, StartTime | Format-List } catch { Write-Output "PID file exists but process not found or access denied" }
} else {
  Write-Output "PIDFILE: none"
}

# Check listeners for ports
Write-Output "--- Get-NetTCPConnection 5175 ---"
try { Get-NetTCPConnection -LocalPort 5175 -ErrorAction Stop | Format-List } catch { Write-Output "no listener on 5175 or insufficient privileges" }
Write-Output "--- Get-NetTCPConnection 62000 ---"
try { Get-NetTCPConnection -LocalPort 62000 -ErrorAction Stop | Format-List } catch { Write-Output "no listener on 62000 or insufficient privileges" }

Write-Output "--- netstat -ano (filter 5175|62000) ---"
netstat -ano | Select-String '5175|62000' | ForEach-Object { $_ }

# Try HTTP requests
Write-Output "--- HTTP check 5175 ---"
try {
  $r = Invoke-WebRequest -Uri 'http://127.0.0.1:5175/' -UseBasicParsing -TimeoutSec 5
  Write-Output "HTTP5175: $($r.StatusCode)"
  $s = $r.Content
  if ($s.Length -gt 400) { $s = $s.Substring(0,400) + '...[truncated]' }
  Write-Output "HTTP5175_CONTENT_SNIPPET: $s"
} catch {
  Write-Output "HTTP5175_ERR: $($_.Exception.Message)"
}

Write-Output "--- HTTP check 62000 ---"
try {
  $r = Invoke-WebRequest -Uri 'http://127.0.0.1:62000/' -UseBasicParsing -TimeoutSec 5
  Write-Output "HTTP62000: $($r.StatusCode)"
  $s = $r.Content
  if ($s.Length -gt 400) { $s = $s.Substring(0,400) + '...[truncated]' }
  Write-Output "HTTP62000_CONTENT_SNIPPET: $s"
} catch {
  Write-Output "HTTP62000_ERR: $($_.Exception.Message)"
}

# netsh checks (may require admin for some outputs)
Write-Output "--- netsh interface ipv4 show excludedportrange protocol=tcp ---"
try { netsh interface ipv4 show excludedportrange protocol=tcp } catch { Write-Output "failed to run netsh excludedportrange (maybe not admin)" }

Write-Output "--- netsh http show urlacl ---"
try { netsh http show urlacl } catch { Write-Output "failed to run netsh http show urlacl (maybe not admin)" }

Write-Output "--- done ---" 
