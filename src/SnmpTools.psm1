$privateFolder = Join-Path $PSScriptRoot 'private'
$publicFolder  = Join-Path $PSScriptRoot 'public'

# Load bootstrap functions required to load dependencies
. "$privateFolder\Test-SnmpDependencies.ps1"

# Load SharpSnmpLib
$assemblyPath = Test-SnmpDependencies
Add-Type -Path $assemblyPath

# Load types (enums, classes, exceptions)
Get-ChildItem "$privateFolder\types\*.ps1" |
    Sort-Object Name |
        ForEach-Object {
            . $_.FullName
        }

# Load validate folder
Get-ChildItem "$(Join-Path $PSScriptRoot "validate")\*.ps1" |
    Sort-Object Name |
    Where-Object Name -ne 'Test-SnmpDependencies.ps1' |
    ForEach-Object {
        . $_.FullName
    }

# Load private functions
Get-ChildItem "$privateFolder\*.ps1" |
    Sort-Object Name |
    Where-Object Name -ne 'Test-SnmpDependencies.ps1' |
    ForEach-Object {
        . $_.FullName
    }

# Load public functions
Get-ChildItem "$publicFolder\*.ps1" |
    Sort-Object Name |
    ForEach-Object {
        . $_.FullName
    }