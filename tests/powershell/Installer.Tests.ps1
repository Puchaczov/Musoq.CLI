$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$env:MUSOQ_INSTALLER_SOURCE_ONLY = '1'
. (Join-Path $repoRoot 'scripts\powershell\install.ps1')
$parsedReleases = Get-Content (Join-Path $repoRoot 'tests\fixtures\releases.json') -Raw | ConvertFrom-Json
$releases = @()
foreach ($parsedRelease in $parsedReleases) { $releases += $parsedRelease }
$script:Tests = 0

function Assert-Equal($Expected, $Actual, [string]$Message) {
    $script:Tests++
    if ($Expected -cne $Actual) { throw "FAIL: $Message (expected '$Expected', got '$Actual')" }
}

function Assert-Throws([scriptblock]$Action, [string]$Message) {
    $script:Tests++
    try { & $Action; throw "FAIL: $Message" } catch {
        if ($_.Exception.Message -eq "FAIL: $Message") { throw }
    }
}

Assert-Equal '0.40.0-alpha.1' (ConvertTo-NormalizedSemVer 'v0.40.0-alpha.1') 'leading v is normalized'
Assert-Equal 'alpha' (Get-ReleaseChannel '0.40.0-alpha.1') 'alpha channel is parsed'
Assert-Equal 'stable' (Get-ReleaseChannel '0.40.0') 'stable channel is parsed'
Assert-Throws { ConvertTo-NormalizedSemVer '1.0.0-alpha.01' } 'leading-zero prerelease is invalid'
Assert-Equal 1 (Compare-SemVer '1.3.0-alpha.10' '1.3.0-alpha.2') 'numeric prerelease precedence'
Assert-Equal -1 (Compare-SemVer '1.3.0-alpha.10' '1.3.0-beta.1') 'identifier precedence'
Assert-Equal 1 (Compare-SemVer '1.3.0' '1.3.0-rc.1') 'stable outranks prerelease'

$alpha = Select-ReleaseForChannel -Releases $releases -Channel alpha
Assert-Equal '1.3.0-alpha.10' $alpha.tag_name 'highest exact alpha is selected'
Assert-Equal '1.3.0-beta.3' (Select-ReleaseForChannel $releases beta).tag_name 'beta remains isolated'
Assert-Equal '1.3.0-rc.1' (Select-ReleaseForChannel $releases rc).tag_name 'rc remains isolated'
Assert-Equal '1.2.0' (Select-ReleaseForChannel $releases stable).tag_name 'stable remains isolated'

Assert-Equal '0.40.0-alpha.1' (Get-VersionFromOutput 'Musoq 0.40.0-alpha.1') 'complete installed version is parsed'
Assert-Equal 'Musoq-win-x64.zip' (Select-ReleaseAsset $releases[0] 'Musoq-win-x64.zip').name 'asset selection is exact'
Assert-Throws { Select-ReleaseAsset $alpha 'Musoq.Cloud.AgentLocal.Api-win-x64.zip' } 'AgentLocal asset is not accepted'

$tempFile = [IO.Path]::GetTempFileName()
try {
    [IO.File]::WriteAllText($tempFile, 'musoq-test')
    $digest = 'sha256:' + (Get-FileHash $tempFile -Algorithm SHA256).Hash.ToLowerInvariant()
    Assert-Equal $true (Test-AssetDigest $tempFile $digest) 'valid digest passes'
    Assert-Throws { Test-AssetDigest $tempFile 'sha256:0000' } 'invalid digest fails'
    Assert-Throws { Test-AssetDigest $tempFile $null } 'missing digest is rejected'
}
finally { Remove-Item $tempFile -Force }

$stagingParent = Join-Path ([IO.Path]::GetTempPath()) ('MusoqInstallerTests.' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -Path $stagingParent -ItemType Directory -ErrorAction Stop | Out-Null
    $firstStagingDirectory = New-InstallerStagingDirectory $stagingParent
    $secondStagingDirectory = New-InstallerStagingDirectory $stagingParent
    Assert-Equal $true (Test-Path -LiteralPath $firstStagingDirectory -PathType Container) 'first staging directory is created'
    Assert-Equal $false ($firstStagingDirectory -ceq $secondStagingDirectory) 'staging directory names are unique'
    Assert-Throws { New-InstallerStagingDirectory (Join-Path $stagingParent 'missing') } 'missing staging parent is rejected'
}
finally { Remove-Item $stagingParent -Recurse -Force -ErrorAction SilentlyContinue }

$transactionParent = Join-Path ([IO.Path]::GetTempPath()) ('MusoqTransactionTests.' + [guid]::NewGuid().ToString('N'))
try {
    $installDirectory = Join-Path $transactionParent 'Musoq'
    $preparedDirectory = Join-Path $transactionParent 'prepared-success'
    New-Item -Path $installDirectory, $preparedDirectory -ItemType Directory -ErrorAction Stop | Out-Null
    [IO.File]::WriteAllText((Join-Path $installDirectory 'Musoq.exe'), 'old')
    [IO.File]::WriteAllText((Join-Path $preparedDirectory 'Musoq.exe'), 'new')
    Invoke-InstallDirectoryTransaction -PreparedDirectory $preparedDirectory -InstallDirectory $installDirectory
    Assert-Equal 'new' ([IO.File]::ReadAllText((Join-Path $installDirectory 'Musoq.exe'))) 'prepared directory replaces existing install'

    $failingPreparedDirectory = Join-Path $transactionParent 'prepared-failure'
    New-Item -Path $failingPreparedDirectory -ItemType Directory -ErrorAction Stop | Out-Null
    [IO.File]::WriteAllText((Join-Path $installDirectory 'Musoq.exe'), 'old-again')
    [IO.File]::WriteAllText((Join-Path $failingPreparedDirectory 'Musoq.exe'), 'new-but-failing')
    $script:RollbackActionWasCalled = $false
    Assert-Throws {
        Invoke-InstallDirectoryTransaction -PreparedDirectory $failingPreparedDirectory -InstallDirectory $installDirectory -PostInstallAction { throw 'simulated post-install failure' } -RollbackPostInstallAction { $script:RollbackActionWasCalled = $true }
    } 'post-install failure rolls back install directory'
    Assert-Equal $true $script:RollbackActionWasCalled 'rollback action is called'
    Assert-Equal 'old-again' ([IO.File]::ReadAllText((Join-Path $installDirectory 'Musoq.exe'))) 'failed transaction restores previous install'
}
finally { Remove-Item $transactionParent -Recurse -Force -ErrorAction SilentlyContinue }

$fileArguments = Get-ElevationArguments -ScriptPath 'C:\install.ps1' -Version '1.3.0-alpha.10' -Channel $null -DebugEnabled $true
Assert-Equal $true ($fileArguments -contains '1.3.0-alpha.10') 'elevation forwards exact version'
Assert-Equal $true ($fileArguments -contains '-Debug') 'elevation forwards debug'
$memoryArguments = Get-ElevationArguments -ScriptPath $null -Version $null -Channel 'alpha' -DebugEnabled $false
Assert-Equal $true ($memoryArguments -contains '-EncodedCommand') 'in-memory elevation uses encoded redownload command'
$encodedCommand = $memoryArguments[$memoryArguments.IndexOf('-EncodedCommand') + 1]
$decodedCommand = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encodedCommand))
Assert-Equal $true ($decodedCommand.Contains("& ([scriptblock]::Create(`$content)) -Channel 'alpha'")) 'in-memory elevation preserves channel binding'
Assert-Equal $false ($decodedCommand.Contains(") 'alpha'")) 'in-memory elevation does not pass channel positionally'

function Invoke-GitHubApi([string]$Uri) {
    if ($Uri.EndsWith('/releases/latest')) { return @($releases | Where-Object tag_name -ceq '1.2.0')[0] }
    if ($Uri.EndsWith('/releases/tags/1.3.0-alpha.10')) { return @($releases | Where-Object tag_name -ceq '1.3.0-alpha.10')[0] }
    if ($Uri -match 'releases\?per_page=100&page=1') { return $releases }
    throw "Unexpected mock URI: $Uri"
}
Assert-Equal '1.2.0' (Get-ReleaseByChannel stable).tag_name 'stable API resolution'
Assert-Equal '1.3.0-alpha.10' (Get-ReleaseByChannel alpha).tag_name 'paginated channel resolution'
Assert-Equal '1.3.0-alpha.10' (Get-ReleaseByVersion '1.3.0-alpha.10').tag_name 'exact tag resolution'

Write-Host "PASS: $($script:Tests) PowerShell installer assertions"
