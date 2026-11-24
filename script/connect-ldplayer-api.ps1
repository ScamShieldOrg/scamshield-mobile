[CmdletBinding()]
param(
    [string]$Serial = 'emulator-5554',
    [ValidateRange(1, 65535)]
    [int]$HostPort = 8080,
    [string]$AdbPath = (Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe')
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $AdbPath -PathType Leaf)) {
    throw "ADB not found. Pass the path to adb.exe with -AdbPath."
}

$state = & $AdbPath -s $Serial get-state
if ($LASTEXITCODE -ne 0 -or $state -ne 'device') {
    throw "Start LDPlayer and check the device serial with adb devices."
}

$uid = & $AdbPath -s $Serial shell id -u
if ($uid -ne '0') {
    & $AdbPath -s $Serial root
    & $AdbPath -s $Serial wait-for-device
    $uid = & $AdbPath -s $Serial shell id -u
}

$rule = 'OUTPUT -d 10.0.2.2/32 -p tcp --dport 8080 -j REDIRECT --to-ports 8080'
$command = "iptables -t nat -C $rule 2>/dev/null || iptables -t nat -A $rule"
if ($uid -ne '0') {
    $uid = & $AdbPath -s $Serial shell "if command -v su >/dev/null; then su -c 'id -u'; fi"
    if ($uid -ne '0') {
        throw "Root is unavailable. Enable Root permission in LDPlayer and restart it."
    }
    $command = "su -c '$command'"
}

& $AdbPath -s $Serial reverse tcp:8080 "tcp:$HostPort"
if ($LASTEXITCODE -ne 0) {
    throw "adb reverse failed."
}

& $AdbPath -s $Serial shell $command
if ($LASTEXITCODE -ne 0) {
    throw "Failed to configure the LDPlayer redirect."
}

Write-Host "LDPlayer redirect configured: 10.0.2.2:8080 -> Windows localhost:${HostPort}"
