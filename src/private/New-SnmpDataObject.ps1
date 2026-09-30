function New-SnmpDataObject
{
    param(
        [string]$ComputerName,

        [Lextm.SharpSnmpLib.Variable]$Variable,

        [SnmpVersion]$Version,

        [datetime]$Timestamp
    )

    [PSCustomObject]@{
        PSTypeName   = 'SnmpTools.SnmpData'
        ComputerName = $ComputerName
        Oid          = $Variable.Id.ToString()
        Type         = $Variable.Data.GetType().Name
        RawValue     = $Variable.Data.ToString()
        Value        = $Variable.Data.ToString()
        Version      = $Version
        Timestamp    = $Timestamp
    }
}