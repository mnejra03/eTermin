$ErrorActionPreference = 'SilentlyContinue'
$stateDirectory = Join-Path $env:LOCALAPPDATA 'eTermin'
$pidFile = Join-Path $stateDirectory 'api.pid'
$dialog = New-Object -ComObject WScript.Shell

if (-not (Test-Path -LiteralPath $pidFile)) {
    $dialog.Popup('API nije pokrenut preko eTermin dvoklik pokretača. Ako radi u VS Codeu, zaustavi ga dugmetom Stop.', 0, 'eTermin', 64) | Out-Null
    exit 0
}

$processId = [int](Get-Content -LiteralPath $pidFile -Raw)
$process = Get-Process -Id $processId -ErrorAction SilentlyContinue
$processDetails = Get-CimInstance Win32_Process -Filter "ProcessId = $processId"
if ($process -and $processDetails.CommandLine -like '*eTermin.Api.dll*') {
    Stop-Process -Id $processId -Force
} elseif ($process) {
    Remove-Item -LiteralPath $pidFile -Force
    $dialog.Popup('Zabilježeni API proces više ne odgovara; nijedan drugi proces nije zaustavljen.', 0, 'eTermin', 64) | Out-Null
    exit 0
}
Remove-Item -LiteralPath $pidFile -Force
$dialog.Popup('eTermin API je zaustavljen. Baza podataka nije obrisana.', 0, 'eTermin', 64) | Out-Null
