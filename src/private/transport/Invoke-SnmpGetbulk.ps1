function Invoke-SnmpGetbulk {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [int]$Port,

        [Parameter(Mandatory)]
        [string]$Oid,

        [Parameter(Mandatory)]
        [SnmpVersion]$Version,

        [Parameter(Mandatory)]
        [int]$Timeout,

        [Parameter(Mandatory)]
        [int]$NonRepeaters,

        [Parameter(Mandatory)]
        [int]$MaxRepetitions,

        [string]$Community,

        [string]$Username,

        [string]$AuthenticationProtocol,

        [securestring]$AuthenticationPassword,

        [string]$PrivacyProtocol,

        [securestring]$PrivacyPassword
    )

    # Resolve endpoint
    $Endpoint = Resolve-SnmpEndpoint -ComputerName $ComputerName -Port $Port
    
    # Resolve SNMP version code
    $VersionCode = Resolve-SnmpVersion $Version

    # Create a list of variable to send in SNMP communication to the endpoint
    $Variables = [System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]]::new()
    $Variables.Add(
        [Lextm.SharpSnmpLib.Variable]::new(
            [Lextm.SharpSnmpLib.ObjectIdentifier]::new($Oid)
        ))

    switch ($Version) {
        ([SnmpVersion]::V1) {
            throw "SNMP V1 does not support GETBULK requests. Please use SNMP V2C or V3 instead."
        }

        ([SnmpVersion]::V2C) {
            try {
                $Request = [Lextm.SharpSnmpLib.Messaging.GetBulkRequestMessage]::new(
                    [Lextm.SharpSnmpLib.Messaging.Messenger]::NextRequestId,
                    $VersionCode,
                    [Lextm.SharpSnmpLib.OctetString]::new($Community),
                    $NonRepeaters,
                    $MaxRepetitions,
                    $Variables
                )
            }
            catch {
                throw "SNMP $Version request failed: $($_.Exception.Message)"
            }
        }
        
        # SNMP v3
        ([SnmpVersion]::V3) {
            # Build auth and privacy providers
            $AuthProvider = Resolve-SnmpAuthenticationProvider `
                -AuthenticationProtocol $AuthenticationProtocol `
                -AuthenticationPassword $AuthenticationPassword
            $PrivacyProvider = Resolve-SnmpPrivacyProvider `
                -AuthenticationProvider $AuthProvider `
                -PrivacyProtocol $PrivacyProtocol `
                -PrivacyPassword $PrivacyPassword

            # SNMP Discovery
            try {
                $Discovery = [Lextm.SharpSnmpLib.Messaging.Messenger]::GetNextDiscovery([Lextm.SharpSnmpLib.SnmpType]::GetBulkRequestPdu)
                $Report = $Discovery.GetResponse($Timeout, $Endpoint)
            }
            catch {
                throw "SNMP $Version discovery failed: $($_.Exception.Message)"
            }

            # SNMP Request
            try {
                $Request = [Lextm.SharpSnmpLib.Messaging.GetBulkRequestMessage]::new(
                    $VersionCode,
                    [Lextm.SharpSnmpLib.Messaging.Messenger]::NextMessageId,
                    [Lextm.SharpSnmpLib.Messaging.Messenger]::NextRequestId,
                    [Lextm.SharpSnmpLib.OctetString]::new($Username),
                    $NonRepeaters,
                    $MaxRepetitions,
                    $Variables,
                    $PrivacyProvider,
                    $Report
                )
            }
            catch {
                throw "SNMP $Version request failed: $($_.Exception.Message)"
            }

        }

        default {
            throw "Unsupported SNMP version: $Version"
        }
    }

    # Get SNMP response
    $Timestamp = Get-Date
    try {
        $Reply = [Lextm.SharpSnmpLib.Messaging.SnmpMessageExtension]::GetResponse(
            $Request,
            $Timeout,
            $Endpoint
        )
    }
    catch {
        throw "SNMP $Version reply error: $($_.Exception.Message)"
    }

    # Check for agent errors
    if ($Reply.Scope.Pdu.ErrorStatus.ToInt32() -ne 0) {
        throw (
            "SNMP {0} error returned by device {1}. ErrorStatus: {2}, ErrorIndex: {3}" -f
            $Version,
            $Endpoint.Address,
            $Reply.Scope.Pdu.ErrorStatus,
            $Reply.Scope.Pdu.ErrorIndex
        )
    }
        
    # Return objects
    return $Reply.Scope.Pdu.Variables | ConvertFrom-SnmpVariable `
        -ComputerName $ComputerName `
        -Version $Version `
        -Timestamp $Timestamp
}