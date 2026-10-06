function Invoke-SnmpGetnext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Net.IPEndPoint]$Endpoint,

        [Parameter(Mandatory)]
        [string[]]$Oid,

        [Parameter(Mandatory)]
        [SnmpVersion]$Version,

        [Parameter(Mandatory)]
        [int]$Timeout,

        [string]$Community,

        [string]$Username,

        [string]$AuthenticationProtocol,

        [securestring]$AuthenticationPassword,

        [string]$PrivacyProtocol,

        [securestring]$PrivacyPassword
    )

    # Resolve SNMP version code
    $VersionCode = Resolve-SnmpVersion $Version

    # Create a list of variable to send in SNMP communication to the endpoint
    $Variables = [System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]]::new()
    $Variables.Add(
        [Lextm.SharpSnmpLib.Variable]::new(
            [Lextm.SharpSnmpLib.ObjectIdentifier]::new($Oid)
        ))

    switch ($Version) {
        # SNMP v1 and v2c
        { $_ -in ([SnmpVersion]::V1, [SnmpVersion]::V2C) } {
            try {
                # SharpSnmpLib doesn't expose a Messenger.GetNext(), so using Messaging.GetNextRequestMessage instead.
                $Request = [Lextm.SharpSnmpLib.Messaging.GetNextRequestMessage]::new(
                    [Lextm.SharpSnmpLib.Messaging.Messenger]::NextRequestId,
                    $VersionCode,
                    [Lextm.SharpSnmpLib.OctetString]::new($Community),
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
                $Discovery = [Lextm.SharpSnmpLib.Messaging.Messenger]::GetNextDiscovery([Lextm.SharpSnmpLib.SnmpType]::GetNextRequestPdu)
                $Report = $Discovery.GetResponse($Timeout, $Endpoint)
            }
            catch {
                throw "SNMP $Version discovery failed: $($_.Exception.Message)"
            }

            # SNMP Request
            try {
                $Request = [Lextm.SharpSnmpLib.Messaging.GetNextRequestMessage]::new(
                    $VersionCode,
                    [Lextm.SharpSnmpLib.Messaging.Messenger]::NextMessageId,
                    [Lextm.SharpSnmpLib.Messaging.Messenger]::NextRequestId,
                    [Lextm.SharpSnmpLib.OctetString]::new($Username),
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
    return $Reply.Scope.Pdu.Variables
}