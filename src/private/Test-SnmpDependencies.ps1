function Test-SnmpDependencies
{
    [CmdletBinding()]
    param()

    $moduleRoot = Split-Path $PSScriptRoot -Parent

    if ($PSVersionTable.PSEdition -eq 'Desktop')
    {
        $assembly = Join-Path $moduleRoot 'lib\net471\SharpSnmpLib.dll'

        if (-not (Test-Path $assembly))
        {
            throw "SharpSnmpLib for .NET Framework 4.7.1 not found."
        }

        return $assembly
    }

    if ($PSVersionTable.PSEdition -eq 'Core')
    {
        $assembly = Join-Path $moduleRoot 'lib\net8.0\SharpSnmpLib.dll'

        if (-not (Test-Path $assembly))
        {
            throw "SharpSnmpLib for .NET 8 not found."
        }

        return $assembly
    }

    throw "Unsupported PowerShell runtime."
}