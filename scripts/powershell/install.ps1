param(
    [switch]$Debug,
    [string]$Version
)

if ($Debug) { $DebugPreference = "Continue" } else { $DebugPreference = "SilentlyContinue" }

function NormalizeVersion {
    param (
        [string]$version,
        [switch]$githubFormat
    )
    
    $parts = $version.Split('.')
    $normalized = @($parts[0], $parts[1], $parts[2], $parts[3])
    
    # Fill missing parts with zeros
    for ($i = $parts.Count; $i -lt 4; $i++) {
        $normalized[$i] = "0"
    }
    
    if ($githubFormat) {
        return ($normalized[0..2] -join '.')
    }
    
    return $normalized -join '.'
}

function StopMusoq {
    param([string]$path)
    Write-Host "Stopping running Musoq instance if exists..."
    try {
        $currentLocation = Get-Location
        Set-Location $path
        & "./Musoq.exe" quit
        Start-Sleep -Seconds 20
        Set-Location $currentLocation
    } catch {
        Write-Debug "Error while stopping Musoq: $($_.Exception.Message)"
    }
}

function DownloadAsset {
    param([string]$url, [string]$destination)
    if (-not (Test-Path $destination)) {
        Write-Host "Downloading $url..."
        Invoke-WebRequest -Uri $url -OutFile $destination -ErrorAction Stop
    } else {
        Write-Host "Using cached file: $destination"
    }
}

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "Script is not running as Administrator. Relaunching with elevated rights..."
    Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$installDir = Join-Path $env:ProgramFiles "Musoq"
$musoqExe = Join-Path $installDir "Musoq.exe"

$installedVersion = "0.0.0.0"
$installedVersionTriple = "0.0.0.0"

if (Test-Path $musoqExe) {
    Write-Debug "Found existing Musoq installation, checking version..."
    try {
        $output = & $musoqExe "--version" 2>&1
        if ($LASTEXITCODE -eq 0 -and $output -match 'Musoq\s+(\d+\.\d+\.\d+)') {
            $installedVersion = $Matches[1] + ".0"  # Append .0 for 4-part version
            $installedVersionTriple = $Matches[1]  # Store three-part version for comparisons
            Write-Debug "Installed version: $installedVersion"
            
            if ($Version) {
                $normalizedInstalled = $installedVersion
                $normalizedRequested = NormalizeVersion $Version
                Write-Debug "Comparing versions: Installed=$normalizedInstalled, Requested=$normalizedRequested"
                
                if ($normalizedInstalled.StartsWith($normalizedRequested)) {
                    Write-Host "Musoq version $normalizedRequested is already installed ($installedVersion)."
                    exit 0
                }
            }
        }
        else {
            Write-Debug "Could not parse installed version from output or command failed. Assuming version 0.0.0"
            Write-Debug "Output: $output, Exit code: $LASTEXITCODE"
        }
    } catch {
        Write-Debug "Error while checking installed version: $($_.Exception.Message). Assuming version 0.0.0"
    }
}

$repoOwner = "Puchaczov"
$repoName = "Musoq.CLI"
$apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/releases"

Write-Debug "Fetching releases from $apiUrl..."
try {
    $releases = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
} catch {
    Write-Error "Failed to fetch releases. API returned: $($_.Exception.Message)"
    exit 1
}
if (-not $releases) { Write-Error "No releases found."; exit 1 }
Write-Debug "Fetched releases: $($releases.Count) found."
Write-Host "$Version"

if ($Version) {
    Write-Debug "Version parameter provided: $Version"
    $normalizedVersion = NormalizeVersion $Version -githubFormat
    Write-Debug "Normalized version for GitHub comparison: $normalizedVersion"
    $releaseFilter = $releases | Where-Object { ($_.tag_name.TrimStart('v').Trim()) -eq $normalizedVersion }
    if (-not $releaseFilter) {
        Write-Error "Release version $normalizedVersion not found on GitHub."
        exit 1
    }
    $latestRelease = $releaseFilter | Select-Object -First 1
} else {
    $latestRelease = $releases | Where-Object { $_.tag_name -match '^\d+\.\d+\.\d+$' } |
                     Sort-Object { [version]($_.tag_name.TrimStart('v')) } -Descending |
                     Select-Object -First 1
}
if (-not $latestRelease) { Write-Error "No valid release version found."; exit 1 }
Write-Debug "Selected release: $($latestRelease.tag_name)"

if (-not $Version) {
    # If no specific version is requested, compare installed vs latest
    $latestVersion = $latestRelease.tag_name.TrimStart('v')
    if ([version]$installedVersionTriple -ge [version]$latestVersion) {
        Write-Host "No installation needed. Installed version ($installedVersion) is up to date."
        exit 0
    }
}

Write-Debug "Available release assets: $(( $latestRelease.assets | ForEach-Object { $_.name } ) -join ', ')"

$asset = $latestRelease.assets | Where-Object { $_.name -match '(?i)(win|windows).*\.zip$' } | Select-Object -First 1
if (-not $asset) { 
    Write-Error "No windows zip asset found in the latest release. Check asset names: $(( $latestRelease.assets | ForEach-Object { $_.name } ) -join ', ')"
    exit 1 
}
Write-Debug "Selected asset: $($asset.name)"

$downloadUrl = $asset.browser_download_url

$cacheDir = Join-Path $env:TEMP "MusoqCache"
if (-not (Test-Path $cacheDir)) { 
    New-Item -Path $cacheDir -ItemType Directory -Force | Out-Null 
}
$cacheFile = Join-Path $cacheDir $asset.name

DownloadAsset -url $downloadUrl -destination $cacheFile

$tempZip = $cacheFile

$tempExtractDir = Join-Path $env:TEMP "MusoqTemp"
try {
    if (Test-Path $tempExtractDir) {
        Remove-Item -Path $tempExtractDir -Recurse -Force
    }
    New-Item -Path $tempExtractDir -ItemType Directory -Force | Out-Null

    Write-Debug "Extracting contents to temporary location: $tempExtractDir"
    Expand-Archive -Path $tempZip -DestinationPath $tempExtractDir -Force

    $musoqExe = Join-Path $tempExtractDir "Musoq.exe"
    if (-not (Test-Path $musoqExe)) {
        throw "Invalid archive contents: Musoq.exe not found in extracted files"
    }

    $installDir = Join-Path $env:ProgramFiles "Musoq"
    Write-Debug "Installation directory set to: $installDir"

    $originalPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)

    try {
        if (Test-Path (Join-Path $installDir "Musoq.exe")) {
            StopMusoq -path $installDir
        }

        if (Test-Path $installDir) {
            Write-Host "Removing existing installation..."
            Remove-Item -Path $installDir -Recurse -Force
        }

        New-Item -Path $installDir -ItemType Directory -Force | Out-Null

        Get-ChildItem -Path $tempExtractDir | Copy-Item -Destination $installDir -Recurse -Force

        # Maintain proper privileges on existing DataSources folder
        $dataSources = Join-Path $installDir "DataSources"
        if (Test-Path $dataSources) {
            $folderPath = $dataSources
            $acl = Get-Acl $folderPath
            $identity = New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0")  # SID for "Everyone"
            $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
            $acl.SetAccessRule($accessRule)
            Set-Acl $folderPath $acl -ErrorAction Stop
        }
        else {
            Write-Host "Warning: DataSources folder not found in $installDir."
        }

        $currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
        if (-not ($currentPath.Split(';') -contains $installDir)) {
            Write-Host "Adding $installDir to system PATH..."
            $newPath = "$currentPath;$installDir"
            [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::Machine)

            Write-Host "Also updating the current session PATH..."
            $env:Path = "$($env:Path);$installDir"
        }

        Write-Host "Musoq installation completed successfully."
        Write-Host "Musoq.CLI in version $($latestRelease.tag_name) was installed and is added to environment PATH."

    } catch {
        Write-Error "Installation failed: $($_.Exception.Message)"
        
        if ($originalPath) {
            [Environment]::SetEnvironmentVariable("Path", $originalPath, [EnvironmentVariableTarget]::Machine)
        }

        if (Test-Path $installDir) {
            Remove-Item -Path $installDir -Recurse -Force
        }

        exit 1
    }

} catch {
    Write-Error "Installation preparation failed: $($_.Exception.Message)"
    exit 1
} finally {
    if (Test-Path $tempExtractDir) {
        Remove-Item -Path $tempExtractDir -Recurse -Force
    }
    if (Test-Path $tempZip) {
        Remove-Item -Path $tempZip -Force
    }
}

Write-Host "`nPress Enter to close this window..."
Read-Host
