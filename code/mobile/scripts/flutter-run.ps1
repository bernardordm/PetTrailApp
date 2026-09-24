param(
    [string]$Device = "",
    [switch]$Pick,
    [switch]$SkipReverse,
    [int]$ApiPort = 3001,
    [int]$WorkerPort = 3002,
    [int]$ChatPort = 3003
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

function Get-FlutterDevices {
    $json = flutter devices --machine 2>$null
    if (-not $json) { return @() }
    return @($json | ConvertFrom-Json) | Where-Object {
        $_.isSupported -eq $true -and $_.targetPlatform -like "android*"
    }
}

function Select-DeviceInteractive {
    param([array]$Devices)

    Write-Host ""
    Write-Host "Dispositivos disponiveis:"
    for ($i = 0; $i -lt $Devices.Count; $i++) {
        $d = $Devices[$i]
        Write-Host ("  [{0}] {1} ({2})" -f ($i + 1), $d.name, $d.id)
    }
    Write-Host ""
    $choice = Read-Host "Escolha o numero do dispositivo"
    $index = [int]$choice - 1
    if ($index -lt 0 -or $index -ge $Devices.Count) {
        Write-Error "Opcao invalida."
        exit 1
    }
    return $Devices[$index]
}

$devices = Get-FlutterDevices
if ($devices.Count -eq 0) {
    Write-Error "Nenhum dispositivo Flutter encontrado. Conecte um celular ou inicie o emulador."
    exit 1
}

$target = $null

if ($Device) {
    $target = $devices | Where-Object { $_.id -eq $Device -or $_.name -eq $Device } | Select-Object -First 1
    if (-not $target) {
        Write-Error "Dispositivo '$Device' nao encontrado. Use 'make flutter-devices' para listar."
        exit 1
    }
}
elseif ($Pick -or $devices.Count -gt 1) {
    $target = Select-DeviceInteractive -Devices $devices
}
else {
    $target = $devices[0]
}

Write-Host ""
Write-Host ">>> Rodando em: $($target.name) ($($target.id))"
Write-Host ""

if (-not $SkipReverse) {
    $reverseScript = Join-Path $PSScriptRoot "adb-reverse.ps1"
    & powershell -NoProfile -ExecutionPolicy Bypass -File $reverseScript -Action reverse -Device $target.id
    Write-Host ""
}

$defineArgs = @(
    "--dart-define=API_BASE_URL=http://127.0.0.1:$ApiPort",
    "--dart-define=WORKER_BASE_URL=http://127.0.0.1:$WorkerPort",
    "--dart-define=CHAT_BASE_URL=http://127.0.0.1:$ChatPort"
)

flutter run -d $target.id @defineArgs
