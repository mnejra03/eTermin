$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSCommandPath
$apiDirectory = Join-Path $root 'API\eTermin.Api'
$apiDll = Join-Path $apiDirectory 'bin\Debug\net9.0\eTermin.Api.dll'
$adminExe = Join-Path $root 'Desktop\eTermin.Admin\build\windows\x64\runner\Release\etermin_admin.exe'
$stateDirectory = Join-Path $env:LOCALAPPDATA 'eTermin'
$stdoutLog = Join-Path $stateDirectory 'api-stdout.log'
$stderrLog = Join-Path $stateDirectory 'api-stderr.log'
$pidFile = Join-Path $stateDirectory 'api.pid'
$dialog = New-Object -ComObject WScript.Shell

New-Item -ItemType Directory -Path $stateDirectory -Force | Out-Null

if (-not (Test-Path -LiteralPath $apiDll)) {
    $dialog.Popup('API not built. Open the project in VS Code and build it before using this launcher.', 0, 'eTermin', 16) | Out-Null
    exit 1
}

if (-not (Test-Path -LiteralPath $adminExe)) {
    $dialog.Popup('Flutter admin app not found. Build it for Windows, Release, and try again.', 0, 'eTermin', 16) | Out-Null
    exit 1
}

$apiReady = $false
try {
    $null = Invoke-WebRequest -Uri 'http://localhost:5130/swagger' -TimeoutSec 2 -UseBasicParsing
    $apiReady = $true
} catch {
    $listener = Get-NetTCPConnection -LocalPort 5130 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($listener) {
        $dialog.Popup('Port 5130 koristi drugi program. Zaustavi postojeÄ‡i API ili Docker API pa pokuĹˇaj ponovo.', 0, 'eTermin', 16) | Out-Null
        exit 1
    }
}

if (-not $apiReady) {
    $env:ASPNETCORE_ENVIRONMENT = 'Development'
    $env:ASPNETCORE_URLS = 'http://localhost:5130'
    Remove-Item Env:ET_ADMIN_RESET_PASSWORD -ErrorAction SilentlyContinue

    $apiProcess = Start-Process -FilePath 'dotnet' `
        -ArgumentList ('"' + $apiDll + '"') `
        -WorkingDirectory $apiDirectory `
        -WindowStyle Hidden `
        -RedirectStandardOutput $stdoutLog `
        -RedirectStandardError $stderrLog `
        -PassThru
    Set-Content -LiteralPath $pidFile -Value $apiProcess.Id

    for ($attempt = 0; $attempt -lt 60; $attempt++) {
        Start-Sleep -Seconds 1
        if ($apiProcess.HasExited) {
            $details = if (Test-Path -LiteralPath $stderrLog) { Get-Content -LiteralPath $stderrLog -Tail 12 | Out-String } else { '' }
            $dialog.Popup("API se nije pokrenuo. Detalji su u $stderrLog`n$details", 0, 'eTermin', 16) | Out-Null
            exit 1
        }
        try {
            $null = Invoke-WebRequest -Uri 'http://localhost:5130/swagger' -TimeoutSec 2 -UseBasicParsing
            $apiReady = $true
            break
        } catch { }
    }
}

if (-not $apiReady) {
    $dialog.Popup("API se nije javio na portu 5130. Provjeri logove u $stateDirectory.", 0, 'eTermin', 16) | Out-Null
    exit 1
}

Start-Process -FilePath $adminExe -WorkingDirectory (Split-Path -Parent $adminExe)
