function ConvertFrom-SnmpVariable {
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Lextm.SharpSnmpLib.Variable]$Variable,

        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [SnmpVersion]$Version,

        [Parameter()]
        [datetime]$Timestamp = (Get-Date)
    )

    process {
        # Return a PSCustomObject with the SNMP data
        [PSCustomObject]@{
            PSTypeName   = 'SnmpTools.SnmpData'
            ComputerName = $ComputerName
            Oid          = $Variable.Id.ToString()
            Type         = $Variable.Data.GetType().Name
            RawValue     = $Variable.Data
            Value        = $Variable.Data.ToString()
            Version      = $Version
            Timestamp    = $Timestamp
        }
    }
}