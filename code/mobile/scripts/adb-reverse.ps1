param(
    [ValidateSet("reverse", "list", "clean")]
    [string]$Action = "reverse",
    [string]$Device = "",
    [int[]]$Ports = @(3001, 3002, 3003)
)

$sdkRoot = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { Join-Path $env:LOCALAPPDATA "Android\Sdk" }
$adb = Join-Path $sdkRoot "platform-tools\adb.exe"

if (-not (Test-Path $adb)) {
    $adb = (Get-Command adb -ErrorAction SilentlyContinue).Source
}

if (-not $adb) {
    Write-Error "adb nao encontrado. Instale o Android SDK Platform-Tools ou adicione ao PATH."
    exit 1
}

$devices = @(& $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "\tdevice$" } | ForEach-Object { ($_ -split "\t")[0] })

if ($Device) {
    if ($devices -notcontains $Device) {
        Write-Error "Dispositivo '$Device' nao conectado via adb."
        exit 1
    }
    $devices = @($Device)
}

if ($devices.Count -eq 0) {
    Write-Host "Nenhum dispositivo conectado."
    if ($Action -eq "reverse") { exit 1 }
    exit 0
}

switch ($Action) {
    "reverse" {
        foreach ($device in $devices) {
            Write-Host ">>> $device"
            foreach ($port in $Ports) {
                & $adb -s $device reverse "tcp:$port" "tcp:$port" | Out-Null
                Write-Host "    tcp:$port -> tcp:$port"
            }
        }
        if (-not $Device) {
            Write-Host ""
            Write-Host "Pronto. Rode o app com: make run"
        }
    }
    "list" {
        & $adb devices
        Write-Host ""
        Write-Host "Reverses ativos:"
        foreach ($device in $devices) {
            Write-Host ">>> $device"
            & $adb -s $device reverse --list
        }
    }
    "clean" {
        foreach ($device in $devices) {
            Write-Host ">>> removendo reverses em $device"
            & $adb -s $device reverse --remove-all
        }
        Write-Host "Reverses removidos."
    }
}
