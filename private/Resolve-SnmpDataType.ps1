function Resolve-SnmpDataType
{
    param(
        [Parameter(Mandatory)]
        [SnmpDataType]$DataType,

        [Parameter(Mandatory)]
        [object]$Value
    )

    switch ($DataType)
    {
        OctetString
        {
            return [Lextm.SharpSnmpLib.OctetString]::new(
                [string]$Value
            )
        }

        Integer32
        {
            return [Lextm.SharpSnmpLib.Integer32]::new(
                [int]$Value
            )
        }

        Gauge32
        {
            return [Lextm.SharpSnmpLib.Gauge32]::new(
                [uint32]$Value
            )
        }

        Counter32
        {
            return [Lextm.SharpSnmpLib.Counter32]::new(
                [uint32]$Value
            )
        }

        Unsigned32
        {
            return [Lextm.SharpSnmpLib.Gauge32]::new(
                [uint32]$Value
            )
        }

        TimeTicks
        {
            return [Lextm.SharpSnmpLib.TimeTicks]::new(
                [uint32]$Value
            )
        }

        IpAddress
        {
            return [Lextm.SharpSnmpLib.IP]::new(
                [string]$Value
            )
        }

        default
        {
            throw "Unsupported SNMP data type '$DataType'."
        }
    }
}