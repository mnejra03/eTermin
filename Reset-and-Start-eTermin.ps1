$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSCommandPath
$apiDirectory = Join-Path $root 'API\eTermin.Api'
$apiProject = Join-Path $apiDirectory 'eTermin.Api.csproj'
$stateDirectory = Join-Path $env:LOCALAPPDATA 'eTermin'
$buildOutput = Join-Path $stateDirectory 'reset-build.log'
$resetOutput = Join-Path $stateDirectory 'reset-admin.log'
$dialog = New-Object -ComObject WScript.Shell

New-Item -ItemType Directory -Path $stateDirectory -Force | Out-Null

$listeners = Get-NetTCPConnection -LocalPort 5130 -State Listen -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique
foreach ($listenerProcessId in $listeners) {
    try {
        $listenerProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $listenerProcessId" -ErrorAction Stop
    } catch {
        $dialog.Popup('Zaustavi trenutni API u VS Codeu (Shift+F5), pa ponovo dvoklikni ovaj fajl.', 0, 'eTermin', 16) | Out-Null
        exit 1
    }

    if ($listenerProcess.CommandLine -match 'eTermin\.Api\.dll') {
        Stop-Process -Id $listenerProcessId -Force
    } else {
        $dialog.Popup('Port 5130 koristi drugi program. Zaustavi API u VS Codeu (Shift+F5), pa pokušaj ponovo.', 0, 'eTermin', 16) | Out-Null
        exit 1
    }
}

$build = Start-Process -FilePath 'dotnet' `
    -ArgumentList @('build', ('"' + $apiProject + '"')) `
    -WorkingDirectory $root `
    -WindowStyle Hidden `
    -RedirectStandardOutput $buildOutput `
    -RedirectStandardError (Join-Path $stateDirectory 'reset-build-error.log') `
    -PassThru -Wait

if ($build.ExitCode -ne 0) {
    $dialog.Popup("API build nije uspio. Otvori log: $buildOutput", 0, 'eTermin', 16) | Out-Null
    exit 1
}

$env:ASPNETCORE_ENVIRONMENT = 'Development'
$env:ET_ADMIN_RESET_PASSWORD = 'true'
$apiDll = Join-Path $apiDirectory 'bin\Debug\net9.0\eTermin.Api.dll'
$reset = Start-Process -FilePath 'dotnet' `
    -ArgumentList ('"' + $apiDll + '"') `
    -WorkingDirectory $apiDirectory `
    -WindowStyle Hidden `
    -RedirectStandardOutput $resetOutput `
    -RedirectStandardError (Join-Path $stateDirectory 'reset-admin-error.log') `
    -PassThru -Wait
Remove-Item Env:ET_ADMIN_RESET_PASSWORD -ErrorAction SilentlyContinue

if ($reset.ExitCode -ne 0) {
    $dialog.Popup("Reset admin naloga nije uspio. Otvori log: $resetOutput", 0, 'eTermin', 16) | Out-Null
    exit 1
}

$resetText = if (Test-Path -LiteralPath $resetOutput) { Get-Content -LiteralPath $resetOutput -Raw } else { '' }
if ($resetText -notmatch 'Admin lozinka je resetovana') {
    $dialog.Popup("API nije potvrdio reset. Otvori log: $resetOutput", 0, 'eTermin', 16) | Out-Null
    exit 1
}

& (Join-Path $root 'Start-eTermin.ps1')
