param(
    [switch]$Debug,
    [string]$Version,
    [ValidateSet("stable", "alpha", "beta", "rc")]
    [string]$Channel
)

$script:RepoOwner = "Puchaczov"
$script:RepoName = "Musoq.CLI"
$script:InstallerUrl = "https://raw.githubusercontent.com/Puchaczov/Musoq.CLI/refs/heads/main/scripts/powershell/install.ps1"
$script:SemVerPattern = '(?<major>0|[1-9]\d*)\.(?<minor>0|[1-9]\d*)\.(?<patch>0|[1-9]\d*)(?:-(?<prerelease>[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+(?<build>[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?'

function Throw-InstallerError {
    param([string]$Message)
    throw [System.InvalidOperationException]::new($Message)
}

function ConvertTo-NormalizedSemVer {
    param([Parameter(Mandatory)][string]$Value)

    $candidate = $Value.Trim()
    if ($candidate.StartsWith('v', [System.StringComparison]::OrdinalIgnoreCase)) {
        $candidate = $candidate.Substring(1)
    }

    $match = [regex]::Match($candidate, "^$($script:SemVerPattern)$")
    if (-not $match.Success) {
        Throw-InstallerError "Invalid SemVer '$Value'."
    }

    if ($match.Groups['prerelease'].Success) {
        foreach ($identifier in $match.Groups['prerelease'].Value.Split('.')) {
            if ($identifier -match '^\d+$' -and $identifier.Length -gt 1 -and $identifier.StartsWith('0')) {
                Throw-InstallerError "Invalid SemVer '$Value': numeric prerelease identifiers cannot contain leading zeroes."
            }
        }
    }

    return $candidate
}

function Get-SemVerParts {
    param([Parameter(Mandatory)][string]$Version)

    $normalized = ConvertTo-NormalizedSemVer $Version
    $match = [regex]::Match($normalized, "^$($script:SemVerPattern)$")
    [pscustomobject]@{
        Version = $normalized
        Major = $match.Groups['major'].Value
        Minor = $match.Groups['minor'].Value
        Patch = $match.Groups['patch'].Value
        Prerelease = if ($match.Groups['prerelease'].Success) { $match.Groups['prerelease'].Value } else { $null }
        Build = if ($match.Groups['build'].Success) { $match.Groups['build'].Value } else { $null }
    }
}

function Get-ReleaseChannel {
    param([Parameter(Mandatory)][string]$Version)
    $parts = Get-SemVerParts $Version
    if (-not $parts.Prerelease) { return 'stable' }
    return $parts.Prerelease.Split('.')[0].ToLowerInvariant()
}

function Compare-NumericIdentifier {
    param([string]$Left, [string]$Right)
    if ($Left.Length -lt $Right.Length) { return -1 }
    if ($Left.Length -gt $Right.Length) { return 1 }
    return [string]::CompareOrdinal($Left, $Right)
}

function Compare-SemVer {
    param(
        [Parameter(Mandatory)][string]$Left,
        [Parameter(Mandatory)][string]$Right
    )

    $leftParts = Get-SemVerParts $Left
    $rightParts = Get-SemVerParts $Right
    foreach ($name in @('Major', 'Minor', 'Patch')) {
        $comparison = Compare-NumericIdentifier $leftParts.$name $rightParts.$name
        if ($comparison -lt 0) { return -1 }
        if ($comparison -gt 0) { return 1 }
    }

    if (-not $leftParts.Prerelease -and -not $rightParts.Prerelease) { return 0 }
    if (-not $leftParts.Prerelease) { return 1 }
    if (-not $rightParts.Prerelease) { return -1 }

    $leftIdentifiers = $leftParts.Prerelease.Split('.')
    $rightIdentifiers = $rightParts.Prerelease.Split('.')
    $count = [Math]::Max($leftIdentifiers.Count, $rightIdentifiers.Count)
    for ($index = 0; $index -lt $count; $index++) {
        if ($index -ge $leftIdentifiers.Count) { return -1 }
        if ($index -ge $rightIdentifiers.Count) { return 1 }
        $leftIdentifier = $leftIdentifiers[$index]
        $rightIdentifier = $rightIdentifiers[$index]
        if ($leftIdentifier -ceq $rightIdentifier) { continue }

        $leftNumeric = $leftIdentifier -match '^\d+$'
        $rightNumeric = $rightIdentifier -match '^\d+$'
        if ($leftNumeric -and $rightNumeric) {
            $comparison = Compare-NumericIdentifier $leftIdentifier $rightIdentifier
            if ($comparison -lt 0) { return -1 }
            if ($comparison -gt 0) { return 1 }
        }
        elseif ($leftNumeric) { return -1 }
        elseif ($rightNumeric) { return 1 }
        else {
            $comparison = [string]::CompareOrdinal($leftIdentifier, $rightIdentifier)
            if ($comparison -lt 0) { return -1 }
            if ($comparison -gt 0) { return 1 }
        }
    }
    return 0
}

function Assert-ReleaseMetadata {
    param(
        [Parameter(Mandatory)]$Release,
        [string]$ExpectedVersion,
        [string]$ExpectedChannel
    )

    if (-not $Release.tag_name) { Throw-InstallerError 'GitHub returned a release without a tag.' }
    $version = ConvertTo-NormalizedSemVer ([string]$Release.tag_name)
    $releaseChannel = Get-ReleaseChannel $version
    $isPrerelease = [bool]$Release.prerelease
    if ($releaseChannel -eq 'stable' -and $isPrerelease) {
        Throw-InstallerError "Release '$($Release.tag_name)' is marked prerelease but has a stable tag."
    }
    if ($releaseChannel -ne 'stable' -and -not $isPrerelease) {
        Throw-InstallerError "Release '$($Release.tag_name)' has a prerelease tag but is not marked as a GitHub prerelease."
    }
    if ($ExpectedVersion -and $version -cne $ExpectedVersion) {
        Throw-InstallerError "GitHub returned '$($Release.tag_name)' while '$ExpectedVersion' was requested."
    }
    if ($ExpectedChannel -and $releaseChannel -cne $ExpectedChannel.ToLowerInvariant()) {
        Throw-InstallerError "Release '$($Release.tag_name)' belongs to channel '$releaseChannel', not '$ExpectedChannel'."
    }
    return $version
}

function Select-ReleaseForChannel {
    param(
        [Parameter(Mandatory)][object[]]$Releases,
        [Parameter(Mandatory)][ValidateSet('stable', 'alpha', 'beta', 'rc')][string]$Channel
    )

    $requestedChannel = $Channel.ToLowerInvariant()
    $selected = $null
    $selectedVersion = $null
    foreach ($release in $Releases) {
        if ($release.draft) { continue }
        try {
            $version = ConvertTo-NormalizedSemVer ([string]$release.tag_name)
            $releaseChannel = Get-ReleaseChannel $version
        }
        catch { continue }
        if ($releaseChannel -cne $requestedChannel) { continue }
        if ($requestedChannel -eq 'stable' -and [bool]$release.prerelease) { continue }
        if ($requestedChannel -ne 'stable' -and -not [bool]$release.prerelease) { continue }
        if (-not $selected -or (Compare-SemVer $version $selectedVersion) -gt 0) {
            $selected = $release
            $selectedVersion = $version
        }
    }

    if (-not $selected) {
        Throw-InstallerError "No published release is available for channel '$requestedChannel'."
    }
    return $selected
}

function Invoke-GitHubApi {
    param([Parameter(Mandatory)][string]$Uri)
    Invoke-RestMethod -Uri $Uri -Headers @{
        Accept = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
        'User-Agent' = 'Musoq.CLI-installer'
    } -UseBasicParsing -ErrorAction Stop
}

function Get-ReleaseByVersion {
    param([Parameter(Mandatory)][string]$Version)
    $normalized = ConvertTo-NormalizedSemVer $Version
    $encoded = [uri]::EscapeDataString($normalized)
    try {
        $release = Invoke-GitHubApi "https://api.github.com/repos/$($script:RepoOwner)/$($script:RepoName)/releases/tags/$encoded"
    }
    catch {
        Throw-InstallerError "Release version '$normalized' was not found on GitHub: $($_.Exception.Message)"
    }
    [void](Assert-ReleaseMetadata $release -ExpectedVersion $normalized)
    return $release
}

function Get-ReleaseByChannel {
    param([Parameter(Mandatory)][ValidateSet('stable', 'alpha', 'beta', 'rc')][string]$Channel)
    $requestedChannel = $Channel.ToLowerInvariant()
    if ($requestedChannel -eq 'stable') {
        try {
            $release = Invoke-GitHubApi "https://api.github.com/repos/$($script:RepoOwner)/$($script:RepoName)/releases/latest"
        }
        catch {
            Throw-InstallerError "No latest stable release was found on GitHub: $($_.Exception.Message)"
        }
        [void](Assert-ReleaseMetadata $release -ExpectedChannel stable)
        return $release
    }

    $allReleases = @()
    $page = 1
    do {
        try {
            $pageReleases = @(Invoke-GitHubApi "https://api.github.com/repos/$($script:RepoOwner)/$($script:RepoName)/releases?per_page=100&page=$page")
        }
        catch {
            Throw-InstallerError "Failed to fetch release page $page from GitHub: $($_.Exception.Message)"
        }
        $allReleases += $pageReleases
        $page++
    } while ($pageReleases.Count -eq 100)
    return Select-ReleaseForChannel -Releases $allReleases -Channel $requestedChannel
}

function Get-VersionFromOutput {
    param([string]$Output)
    foreach ($match in [regex]::Matches($Output, "v?$($script:SemVerPattern)")) {
        try { return ConvertTo-NormalizedSemVer $match.Value } catch { }
    }
    return $null
}

function Get-WindowsAssetName {
    $architecture = [string]$env:PROCESSOR_ARCHITECTURE
    if ($architecture -notmatch '^(AMD64|x86_64)$') {
        Throw-InstallerError "Unsupported Windows architecture '$architecture'. Only x64 is published."
    }
    return 'Musoq-win-x64.zip'
}

function Select-ReleaseAsset {
    param(
        [Parameter(Mandatory)]$Release,
        [Parameter(Mandatory)][string]$ExpectedName
    )
    $matches = @($Release.assets | Where-Object { $_.name -ceq $ExpectedName })
    if ($matches.Count -ne 1) {
        Throw-InstallerError "Expected exactly one '$ExpectedName' asset, found $($matches.Count)."
    }
    if ([long]$matches[0].size -le 0) {
        Throw-InstallerError "Asset '$ExpectedName' is empty."
    }
    return $matches[0]
}

function Test-AssetDigest {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$Digest
    )
    if (-not $Digest) {
        Throw-InstallerError 'Release asset is missing a SHA-256 digest.'
    }
    if ($Digest -notmatch '^sha256:[0-9A-Fa-f]{64}$') {
        Throw-InstallerError "Unsupported asset digest '$Digest'."
    }
    $expected = $Digest.Substring(7)
    $actual = (Get-FileHash -Path $Path -Algorithm SHA256).Hash
    if ($actual -cne $expected.ToUpperInvariant()) {
        Throw-InstallerError "SHA-256 mismatch for '$(Split-Path $Path -Leaf)'."
    }
    return $true
}

function New-InstallerStagingDirectory {
    param([Parameter(Mandatory)][string]$ParentDirectory)

    if (-not (Test-Path -LiteralPath $ParentDirectory -PathType Container)) {
        Throw-InstallerError "Staging parent '$ParentDirectory' does not exist."
    }
    $path = Join-Path $ParentDirectory ('.Musoq.staging.' + [guid]::NewGuid().ToString('N'))
    New-Item -Path $path -ItemType Directory -ErrorAction Stop | Out-Null
    return $path
}

function Get-ElevationArguments {
    param(
        [string]$ScriptPath,
        [string]$Version,
        [string]$Channel,
        [bool]$DebugEnabled
    )

    $installerArguments = @()
    if ($Version) { $installerArguments += @('-Version', $Version) }
    if ($Channel) { $installerArguments += @('-Channel', $Channel.ToLowerInvariant()) }
    if ($DebugEnabled) { $installerArguments += '-Debug' }

    if ($ScriptPath) {
        return @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $ScriptPath)) + $installerArguments
    }

    $invocation = "`$content = Invoke-RestMethod -Uri '$($script:InstallerUrl)'; & ([scriptblock]::Create(`$content))"
    if ($Version) {
        $escapedVersion = $Version.Replace("'", "''")
        $invocation += " -Version '$escapedVersion'"
    }
    if ($Channel) {
        $escapedChannel = $Channel.ToLowerInvariant().Replace("'", "''")
        $invocation += " -Channel '$escapedChannel'"
    }
    if ($DebugEnabled) { $invocation += ' -Debug' }
    $bytes = [Text.Encoding]::Unicode.GetBytes($invocation)
    return @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', [Convert]::ToBase64String($bytes))
}

function Restart-InstallerElevated {
    param([string]$Version, [string]$Channel, [bool]$DebugEnabled)
    $arguments = Get-ElevationArguments -ScriptPath $PSCommandPath -Version $Version -Channel $Channel -DebugEnabled $DebugEnabled
    $process = Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs -PassThru -Wait -ErrorAction Stop
    if ($process.ExitCode -ne 0) {
        Throw-InstallerError "The elevated installer failed with exit code $($process.ExitCode)."
    }
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Stop-Musoq {
    param([Parameter(Mandatory)][string]$Path)

    $executablePath = Join-Path $Path 'Musoq.exe'
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

    Throw-InstallerError 'Musoq did not stop within 20 seconds.'
}

function Get-MachinePathState {
    param([Parameter(Mandatory)][string]$InstallDirectory)

    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $segments = @($machinePath -split ';' | Where-Object { $_ })
    $changed = -not ($segments -contains $InstallDirectory)
    [pscustomobject]@{
        InstallDirectory = $InstallDirectory
        Changed = $changed
        OriginalMachinePath = $machinePath
        OriginalSessionPath = $env:Path
        UpdatedMachinePath = if ($changed) { (@($segments) + $InstallDirectory) -join ';' } else { $machinePath }
    }
}

function Set-MachinePathState {
    param([Parameter(Mandatory)]$State)
    if (-not $State.Changed) { return }
    [Environment]::SetEnvironmentVariable('Path', $State.UpdatedMachinePath, 'Machine')
    $env:Path = "$($env:Path);$($State.InstallDirectory)"
}

function Restore-MachinePathState {
    param([Parameter(Mandatory)]$State)
    if (-not $State.Changed) { return }
    [Environment]::SetEnvironmentVariable('Path', $State.OriginalMachinePath, 'Machine')
    $env:Path = $State.OriginalSessionPath
}

function Invoke-InstallDirectoryTransaction {
    param(
        [Parameter(Mandatory)][string]$PreparedDirectory,
        [Parameter(Mandatory)][string]$InstallDirectory,
        [scriptblock]$PostInstallAction,
        [scriptblock]$RollbackPostInstallAction
    )

    $installParent = Split-Path -Parent $InstallDirectory
    $backupContainer = $null
    $backupDirectory = $null
    $movedExisting = $false
    $movedPrepared = $false
    $succeeded = $false
    try {
        if (Test-Path -LiteralPath $InstallDirectory) {
            $backupContainer = New-InstallerStagingDirectory $installParent
            $backupDirectory = Join-Path $backupContainer 'previous'
            Move-Item -LiteralPath $InstallDirectory -Destination $backupDirectory -ErrorAction Stop
            $movedExisting = $true
        }

        Move-Item -LiteralPath $PreparedDirectory -Destination $InstallDirectory -ErrorAction Stop
        $movedPrepared = $true
        if ($PostInstallAction) { & $PostInstallAction }
        $succeeded = $true
    }
    catch {
        $failure = $_
        if ($RollbackPostInstallAction) {
            try { & $RollbackPostInstallAction } catch { }
        }
        if ($movedPrepared -and (Test-Path -LiteralPath $InstallDirectory)) {
            Remove-Item -LiteralPath $InstallDirectory -Recurse -Force -ErrorAction Stop
        }
        if ($movedExisting -and (Test-Path -LiteralPath $backupDirectory)) {
            Move-Item -LiteralPath $backupDirectory -Destination $InstallDirectory -ErrorAction Stop
        }
        throw $failure
    }
    finally {
        if ($backupContainer -and (Test-Path -LiteralPath $backupContainer)) {
            if ($succeeded) {
                Remove-Item -LiteralPath $backupContainer -Recurse -Force -ErrorAction Stop
            }
            else {
                Remove-Item -LiteralPath $backupContainer -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

function Install-MusoqRelease {
    param([Parameter(Mandatory)]$Release)

    $assetName = Get-WindowsAssetName
    $asset = Select-ReleaseAsset -Release $Release -ExpectedName $assetName
    $installDirectory = Join-Path $env:ProgramFiles 'Musoq'
    $installParent = Split-Path -Parent $installDirectory
    $stagingDirectory = New-InstallerStagingDirectory $installParent
    $cacheFile = Join-Path $stagingDirectory $assetName
    $extractDirectory = Join-Path $stagingDirectory 'prepared'

    try {
        Write-Host "Downloading $($asset.browser_download_url)..."
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $cacheFile -UseBasicParsing -ErrorAction Stop
        [void](Test-AssetDigest -Path $cacheFile -Digest ([string]$asset.digest))

        New-Item -Path $extractDirectory -ItemType Directory -ErrorAction Stop | Out-Null
        Expand-Archive -Path $cacheFile -DestinationPath $extractDirectory -Force -ErrorAction Stop
        $extractedExecutable = Join-Path $extractDirectory 'Musoq.exe'
        if (-not (Test-Path $extractedExecutable)) {
            Throw-InstallerError 'Archive does not contain Musoq.exe.'
        }

        Stop-Musoq $installDirectory
        $pathState = Get-MachinePathState $installDirectory
        Invoke-InstallDirectoryTransaction -PreparedDirectory $extractDirectory -InstallDirectory $installDirectory -PostInstallAction {
            Set-MachinePathState $pathState
        } -RollbackPostInstallAction {
            Restore-MachinePathState $pathState
        }
        Write-Host "Musoq.CLI version $($Release.tag_name) was installed and added to PATH."
    }
    finally {
        if (Test-Path -LiteralPath $stagingDirectory) { Remove-Item -LiteralPath $stagingDirectory -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Invoke-MusoqInstaller {
    param([string]$Version, [string]$Channel, [bool]$DebugEnabled)

    $DebugPreference = if ($DebugEnabled) { 'Continue' } else { 'SilentlyContinue' }
    if ($Version -and $Channel) {
        Throw-InstallerError '-Version and -Channel are mutually exclusive.'
    }
    $normalizedVersion = $null
    if ($Version) { $normalizedVersion = ConvertTo-NormalizedSemVer $Version }
    $requestedChannel = if ($Channel) { $Channel.ToLowerInvariant() } else { 'stable' }

    if (-not (Test-IsAdministrator)) {
        Write-Host 'Relaunching the Musoq installer with elevated rights...'
        Restart-InstallerElevated -Version $normalizedVersion -Channel $(if ($Version) { $null } else { $requestedChannel }) -DebugEnabled $DebugEnabled
        return
    }

    $release = if ($normalizedVersion) {
        Get-ReleaseByVersion $normalizedVersion
    } else {
        Get-ReleaseByChannel $requestedChannel
    }
    $selectedVersion = ConvertTo-NormalizedSemVer ([string]$release.tag_name)
    Write-Host "Selected release: $($release.tag_name) ($(if ($normalizedVersion) { 'exact' } else { $requestedChannel }))"

    $installedExecutable = Join-Path (Join-Path $env:ProgramFiles 'Musoq') 'Musoq.exe'
    if (Test-Path $installedExecutable) {
        $output = (& $installedExecutable --version 2>&1 | Out-String)
        $installedVersion = Get-VersionFromOutput $output
        if ($installedVersion) {
            Write-Host "Installed version: $installedVersion"
            if ($installedVersion -ceq $selectedVersion) {
                Write-Host "Musoq $selectedVersion is already installed."
                return
            }
            Write-Host "Switching Musoq from $installedVersion to $selectedVersion."
        }
    }

    Install-MusoqRelease $release
}

if ($env:MUSOQ_INSTALLER_SOURCE_ONLY -ne '1') {
    try {
        Invoke-MusoqInstaller -Version $Version -Channel $Channel -DebugEnabled ([bool]$Debug)
    }
    catch {
        throw
    }
}
