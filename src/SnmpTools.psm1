$privateFolder = Join-Path $PSScriptRoot 'private'
$publicFolder = Join-Path $PSScriptRoot 'public'

# Load bootstrap functions required to load dependencies
. "$privateFolder\Test-SnmpDependencies.ps1"

# Load SharpSnmpLib assembly
$assemblyPath = Test-SnmpDependencies
Add-Type -Path $assemblyPath

# Load order is important, types should be loaded first
$privateLoadOrder = @(
    'types'
    'providers'
    'validation'
    'transport'
)

# Load private functions in the specified order
foreach ($folder in $privateLoadOrder) {
    $path = Join-Path $privateFolder $folder
    if (-not (Test-Path $path)) {
        continue
    }
    Get-ChildItem $path -Filter '*.ps1' |
        Sort-Object Name |
        ForEach-Object {
            . $_.FullName
        }
}

# Load public functions
Get-ChildItem $publicFolder -Filter '*.ps1' |
    Sort-Object Name |
    ForEach-Object {
        . $_.FullName
    }