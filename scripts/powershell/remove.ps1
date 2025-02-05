param(
    [switch]$Debug
)

if ($Debug) { $DebugPreference = "Continue" } else { $DebugPreference = "SilentlyContinue" }

# Elevate if not running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "Script is not running as Administrator. Relaunching with elevated rights..."
    Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$installDir = Join-Path $env:ProgramFiles "Musoq"

# New: Check if Musoq is installed; if not, exit immediately.
if (-not (Test-Path $installDir)) {
    Write-Host "Musoq is not installed on this machine."
    exit 0
}

$musoqExe = Join-Path $installDir "Musoq.exe"

function StopMusoq {
    param([string]$path)
    Write-Host "Stopping running Musoq instance if exists..."
    try {
        $currentLocation = Get-Location
        Set-Location $path
        & "./Musoq.exe" quit
        Start-Sleep -Seconds 10
        Set-Location $currentLocation
    } catch {
        Write-Debug "Error while stopping Musoq: $($_.Exception.Message)"
    }
}

# Stop Musoq if running
if (Test-Path $musoqExe) {
    StopMusoq -path $installDir
}

# Remove installation directory
Write-Host "Removing Musoq installation from $installDir..."
Remove-Item -Path $installDir -Recurse -Force

# Remove installDir from system PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if ($currentPath.Split(';') -contains $installDir) {
    Write-Host "Removing $installDir from system PATH..."
    $newPath = ($currentPath.Split(';') | Where-Object { $_ -ne $installDir }) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::Machine)
    Write-Host "Updating current session PATH..."
    $env:Path = ($env:Path.Split(';') | Where-Object { $_ -ne $installDir }) -join ';'
}

Write-Host "Musoq has been successfully removed."
