function Resolve-SnmpVersion
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [SnmpVersion]$Version
    )

    switch ($Version)
    {
        'V1'
        {
            return [Lextm.SharpSnmpLib.VersionCode]::V1
        }

        'V2C'
        {
            return [Lextm.SharpSnmpLib.VersionCode]::V2
        }

        'V3'
        {
            return [Lextm.SharpSnmpLib.VersionCode]::V3
        }

        default
        {
            throw "Unsupported SNMP version: $Version"
        }
    }
}