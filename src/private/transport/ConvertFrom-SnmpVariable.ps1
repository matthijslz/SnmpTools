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
        # Return a SnmpData object with the relevant information from the SNMP variable
        [SnmpData]::new(
            $ComputerName,
            $Variable.Id.ToString(),
            $Variable.Data.GetType().Name,
            $Variable.Data,
            $Variable.Data.ToString(),
            $Version,
            $Timestamp
        )
    }
}