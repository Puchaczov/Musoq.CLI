param(
    [switch]$Debug,
    [switch]$Purge,
    [string]$OriginalUserProfile,
    [string]$OriginalAppData
)

$script:RemoverUrl = 'https://raw.githubusercontent.com/Puchaczov/Musoq.CLI/refs/heads/main/scripts/powershell/remove.ps1'

function Throw-RemoverError {
    param([Parameter(Mandatory)][string]$Message)
    throw [System.InvalidOperationException]::new($Message)
}

function Get-RemovalElevationArguments {
    param(
        [string]$ScriptPath,
        [bool]$DebugEnabled,
        [bool]$PurgeEnabled,
        [string]$UserProfile,
        [string]$AppData
    )

    $arguments = @()
    if ($DebugEnabled) { $arguments += '-Debug' }
    if ($PurgeEnabled) { $arguments += '-Purge' }
    if ($UserProfile) { $arguments += @('-OriginalUserProfile', $UserProfile) }
    if ($AppData) { $arguments += @('-OriginalAppData', $AppData) }

    if ($ScriptPath) {
        return @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $ScriptPath)) + $arguments
    }

    $invocation = "`$content = Invoke-RestMethod -Uri '$($script:RemoverUrl)'; & ([scriptblock]::Create(`$content))"
    if ($DebugEnabled) { $invocation += ' -Debug' }
    if ($PurgeEnabled) { $invocation += ' -Purge' }
    if ($UserProfile) { $invocation += " -OriginalUserProfile '$($UserProfile.Replace("'", "''"))'" }
    if ($AppData) { $invocation += " -OriginalAppData '$($AppData.Replace("'", "''"))'" }
    $bytes = [Text.Encoding]::Unicode.GetBytes($invocation)
    return @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', [Convert]::ToBase64String($bytes))
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Restart-RemoverElevated {
    param([bool]$DebugEnabled, [bool]$PurgeEnabled, [string]$UserProfile, [string]$AppData)
    $arguments = Get-RemovalElevationArguments -ScriptPath $PSCommandPath -DebugEnabled $DebugEnabled -PurgeEnabled $PurgeEnabled -UserProfile $UserProfile -AppData $AppData
    $process = Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs -PassThru -Wait -ErrorAction Stop
    if ($process.ExitCode -ne 0) {
        Throw-RemoverError "The elevated remover failed with exit code $($process.ExitCode)."
    }
}

function Stop-Musoq {
    param([Parameter(Mandatory)][string]$InstallDirectory)

    $executablePath = Join-Path $InstallDirectory 'Musoq.exe'
    if (-not (Test-Path -LiteralPath $executablePath -PathType Leaf)) { return }

    Write-Host 'Stopping running Musoq instance if it exists...'
    & $executablePath quit 2>$null
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    do {
        $matchingProcesses = @()
        foreach ($process in @(Get-Process -Name Musoq -ErrorAction SilentlyContinue)) {
            try {
                if ($process.Path -ceq $executablePath) { $matchingProcesses += $process }
            }
            catch { }
        }
        if ($matchingProcesses.Count -eq 0) { return }
        Start-Sleep -Seconds 1
    } while ([DateTime]::UtcNow -lt $deadline)

    Throw-RemoverError 'Musoq did not stop within 20 seconds.'
}

function Remove-MachinePathEntry {
    param([Parameter(Mandatory)][string]$InstallDirectory)

    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $segments = @($machinePath -split ';' | Where-Object { $_ -and $_ -cne $InstallDirectory })
    $updatedPath = $segments -join ';'
    if ($updatedPath -cne $machinePath) {
        [Environment]::SetEnvironmentVariable('Path', $updatedPath, 'Machine')
    }
    $env:Path = (@($env:Path -split ';' | Where-Object { $_ -and $_ -cne $InstallDirectory }) -join ';')
}

function Get-UserDataPaths {
    param([string]$UserProfile, [string]$AppData)

    $paths = @()
    if ($AppData) { $paths += Join-Path $AppData 'Musoq' }
    if ($UserProfile) { $paths += Join-Path $UserProfile '.musoq' }
    return $paths
}

function Remove-UserData {
    param([Parameter(Mandatory)][string[]]$Paths)
    foreach ($path in $Paths) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop
            Write-Host "Removed user data $path"
        }
    }
}

function Invoke-MusoqRemover {
    param(
        [bool]$DebugEnabled,
        [bool]$PurgeEnabled,
        [string]$UserProfile,
        [string]$AppData,
        [string]$InstallDirectory = (Join-Path $env:ProgramFiles 'Musoq')
    )

    $DebugPreference = if ($DebugEnabled) { 'Continue' } else { 'SilentlyContinue' }
    $callerProfile = if ($UserProfile) { $UserProfile } else { $env:USERPROFILE }
    $callerAppData = if ($AppData) { $AppData } else { $env:APPDATA }
    if (-not (Test-IsAdministrator)) {
        Write-Host 'Relaunching the Musoq remover with elevated rights...'
        Restart-RemoverElevated -DebugEnabled $DebugEnabled -PurgeEnabled $PurgeEnabled -UserProfile $callerProfile -AppData $callerAppData
        return
    }

    if (Test-Path -LiteralPath $InstallDirectory) {
        Stop-Musoq $InstallDirectory
        Remove-Item -LiteralPath $InstallDirectory -Recurse -Force -ErrorAction Stop
        Write-Host "Removed installation directory $InstallDirectory"
    }
    else {
        Write-Host "Installation directory $InstallDirectory does not exist."
    }

    Remove-MachinePathEntry $InstallDirectory
    if ($PurgeEnabled) {
        Remove-UserData (Get-UserDataPaths -UserProfile $callerProfile -AppData $callerAppData)
    }
    Write-Host 'Musoq removal completed.'
}

if ($env:MUSOQ_REMOVER_SOURCE_ONLY -ne '1') {
    try {
        Invoke-MusoqRemover -DebugEnabled ([bool]$Debug) -PurgeEnabled ([bool]$Purge) -UserProfile $OriginalUserProfile -AppData $OriginalAppData
    }
    catch {
        throw
    }
}
