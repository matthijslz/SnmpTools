function Resolve-SnmpEndpoint
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter()]
        [int]$Port = 161
    )

    try
    {
        $ipAddress = $null

        if ([System.Net.IPAddress]::TryParse($ComputerName, [ref]$ipAddress))
        {
            return [System.Net.IPEndPoint]::new(
                $ipAddress,
                $Port
            )
        }

        $Addresses = [System.Net.Dns]::GetHostAddresses($ComputerName)

        if ($Addresses.Count -eq 0)
        {
            throw
        }

        return [System.Net.IPEndPoint]::new(
            $Addresses[0],
            $Port
        )
    }
    catch
    {
        throw "Unable to resolve host '$ComputerName'."
    }
}