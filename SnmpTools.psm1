$privateFolder = Join-Path $PSScriptRoot 'private'
$publicFolder  = Join-Path $PSScriptRoot 'public'

# Load bootstrap functions required to load dependencies
. "$privateFolder\Test-SnmpDependencies.ps1"

# Load SharpSnmpLib
$assemblyPath = Test-SnmpDependencies
Add-Type -Path $assemblyPath

# Load enums
. "$privateFolder\SnmpVersion.ps1"
. "$privateFolder\SnmpDataType.ps1"

# Load remaining private functions
$excludedFiles = @(
    'Test-SnmpDependencies.ps1'
    'SnmpVersion.ps1'
    'SnmpDataType.ps1'
)

Get-ChildItem "$privateFolder\*.ps1" |
    Sort-Object Name |
    Where-Object Name -notin $excludedFiles |
    ForEach-Object {
        . $_.FullName
    }

# Load public functions
Get-ChildItem "$publicFolder\*.ps1" |
    Sort-Object Name |
    ForEach-Object {
        . $_.FullName
    }