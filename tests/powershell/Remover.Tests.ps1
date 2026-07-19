$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$env:MUSOQ_REMOVER_SOURCE_ONLY = '1'
. (Join-Path $repoRoot 'scripts\powershell\remove.ps1')
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

$memoryArguments = Get-RemovalElevationArguments -ScriptPath $null -DebugEnabled $true -PurgeEnabled $true -UserProfile 'C:\Users\Musoq User' -AppData 'C:\Users\Musoq User\AppData\Roaming'
Assert-Equal $true ($memoryArguments -contains '-EncodedCommand') 'in-memory elevation uses encoded command'
$encodedCommand = $memoryArguments[$memoryArguments.IndexOf('-EncodedCommand') + 1]
$decodedCommand = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encodedCommand))
Assert-Equal $true ($decodedCommand.Contains('-Debug -Purge')) 'in-memory elevation preserves switches'
Assert-Equal $true ($decodedCommand.Contains("-OriginalUserProfile 'C:\Users\Musoq User'")) 'in-memory elevation preserves original user profile'
Assert-Equal $true ($decodedCommand.Contains("-OriginalAppData 'C:\Users\Musoq User\AppData\Roaming'")) 'in-memory elevation preserves original app data'

$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('MusoqRemoverTests.' + [guid]::NewGuid().ToString('N'))
try {
    $userProfile = Join-Path $testRoot 'profile'
    $appData = Join-Path $testRoot 'appdata'
    $paths = @(Get-UserDataPaths -UserProfile $userProfile -AppData $appData)
    Assert-Equal (Join-Path $appData 'Musoq') $paths[0] 'app data path is included in purge'
    Assert-Equal (Join-Path $userProfile '.musoq') $paths[1] 'plugin path is included in purge'

    foreach ($path in $paths) { New-Item -Path $path -ItemType Directory -Force | Out-Null }
    Remove-UserData $paths
    Assert-Equal $false (Test-Path -LiteralPath $paths[0]) 'purge removes app data'
    Assert-Equal $false (Test-Path -LiteralPath $paths[1]) 'purge removes plugin data'
}
finally { Remove-Item $testRoot -Recurse -Force -ErrorAction SilentlyContinue }

$removerSource = Get-Content (Join-Path $repoRoot 'scripts\powershell\remove.ps1') -Raw
Assert-Equal $false ($removerSource -match '\bRead-Host\b') 'remover does not pause the caller shell'
Assert-Equal $false ($removerSource -match '(?m)^\s*exit(?:\s|$)') 'remover does not exit the caller shell'
Assert-Throws { Throw-RemoverError 'test error' } 'remover errors are throwable'

Write-Host "PASS: $($script:Tests) PowerShell remover assertions"
