Param(
    [string]$KrokiUrl = $env:KROKI_URL
)

if (-not $KrokiUrl) {
    $KrokiUrl = 'https://kroki.io'
}

$OutDir = Join-Path -Path (Get-Location) -ChildPath 'docs/architecture/out'
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

Write-Host "Rendering diagrams to $OutDir using Kroki at $KrokiUrl"

function Retry-InvokeRestMethod {
    param(
        [string]$Uri,
        [string]$InFile,
        [string]$OutFile,
        [int]$MaxAttempts = 5
    )

    $attempt = 1
    $sleep = 1
    while ($attempt -le $MaxAttempts) {
        try {
            Write-Host "Attempt $attempt: POST $InFile -> $OutFile"
            Invoke-RestMethod -Method Post -Uri $Uri -InFile $InFile -OutFile $OutFile -ErrorAction Stop
            return $true
        } catch {
            Write-Warning "Attempt $attempt failed: $($_.Exception.Message)"
            Start-Sleep -Seconds $sleep
            $attempt++
            $sleep = $sleep * 2
        }
    }
    return $false
}

Get-ChildItem -Path docs/architecture -Recurse -Filter *.mmd | ForEach-Object {
    $src = $_.FullName
    $base = [System.IO.Path]::GetFileNameWithoutExtension($src)
    $out = Join-Path $OutDir ($base + '.png')
    Write-Host "Rendering $src -> $out"
    if (-not (Retry-InvokeRestMethod -Uri "$KrokiUrl/mermaid/png" -InFile $src -OutFile $out)) {
        Write-Warning "Rendering failed for $src after retries"
    }
}

Get-ChildItem -Path docs/architecture -Recurse -Filter *.dsl | ForEach-Object {
    $src = $_.FullName
    Copy-Item -Path $src -Destination $OutDir -Force
    Write-Host "Copied Structurizr DSL $src to $OutDir (use Structurizr CLI to push/render)"
}

Write-Host "Done. Outputs in $OutDir"
