<#
.SYNOPSIS
Retrieves SNMP data from a network device.

.DESCRIPTION
Retrieves one or more OIDs from a network device using
SNMP version 1, 2c or 3.
DES and 3DES are supported for compatibility with legacy devices
but are considered cryptographically obsolete.

.PARAMETER ComputerName
Hostname or IP address of the target device.

.PARAMETER Port
UDP port used for SNMP communication (default is 161)

.PARAMETER Oid
One or more OIDs to retrieve.

.PARAMETER Timeout
 The timeout value in milliseconds. 0 and -1 indicate infinite timeout.

.PARAMETER Version
SNMP version to use (V1, V2C or V3)

.PARAMETER Community
SNMP community string (Only V1 or V2C)

.PARAMETER Username
SNMPv3 user name (Only V3)

.PARAMETER AuthenticationProtocol
SNMPv3 authentication protocol (Only V3)

.PARAMETER AuthenticationPassword
SNMPv3 authentication password (Only V3)

.PARAMETER PrivacyProtocol
SNMPv3 privacy protocol (Only V3)

.PARAMETER PrivacyPassword
SNMPv3 privacy password (Only V3)

.EXAMPLE
Get-SnmpData `
    -ComputerName switch01 `
    -Oid '1.3.6.1.2.1.1.5.0'

Returns the system name using SNMPv2c.

.EXAMPLE
Get-SnmpData `
    -ComputerName printer01 `
    -Oid @(
        '1.3.6.1.2.1.1.5.0',
        '1.3.6.1.2.1.25.3.2.1.3.1'
    )

Retrieves multiple OIDs in a single request.

.EXAMPLE
Get-SnmpData `
    -ComputerName switch01 `
    -Version V3 `
    -Username admin `
    -AuthenticationProtocol SHA512 `
    -AuthenticationPassword $Password `
    -Oid '1.3.6.1.2.1.1.5.0'

Queries a device using SNMPv3.
#>
function Get-SnmpData
{
    [OutputType('SnmpTools.SnmpData')]
    [CmdletBinding(
        DefaultParameterSetName = 'Community'
    )]
    param (
        # General required parameters
        [Parameter(Mandatory)]
        [Alias('IPAddress')]
        [string]$ComputerName,

        [Parameter()]
        [ValidateRange(1,65535)]
        [int]$Port = 161,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Oid,

        [Parameter()]
        [ValidateRange(-1,2147483647)]
        [int]$Timeout = 5000,

        [Parameter(ParameterSetName = 'Community')]
        [Parameter(ParameterSetName = 'V3')]
        [SnmpVersion]$Version = [SnmpVersion]::V2C,

        # Parameter for SNMP version v1 and v2, both rely on a set community
        [Parameter(ParameterSetName = 'Community')]
        [string]$Community = 'public',

        # Parameters for SNMP version v3
        [Parameter(Mandatory, ParameterSetName = 'V3')]
        [string]$Username,

        [Parameter(ParameterSetName = 'V3')]
        [ValidateSet(
            'MD5',
            'SHA1',
            'SHA256',
            'SHA384',
            'SHA512'
        )]
        [string]$AuthenticationProtocol,

        [Parameter(ParameterSetName = 'V3')]
        [securestring]$AuthenticationPassword,

        [Parameter(ParameterSetName = 'V3')]
        [ValidateSet(
            'DES',
            '3DES',
            'AES',
            'AES192',
            'AES256'
        )]
        [string]$PrivacyProtocol,

        [Parameter(ParameterSetName = 'V3')]
        [securestring]$PrivacyPassword
    )

    begin {
        Write-Verbose "Selected parameter set: $($PSCmdlet.ParameterSetName)"

        # Validate ParameterSet and Version combination
        if($PSCmdlet.ParameterSetName -eq 'Community' -and $Version -eq [SnmpVersion]::V3) {
            throw "SNMP version V3 cannot be used with the Community parameter set."
        }
        if ($PSCmdlet.ParameterSetName -eq 'V3' -and $Version -ne [SnmpVersion]::V3) {
            throw "Parameter set 'V3' requires -Version V3."
        }

        # Authentication pair validation
        if ($AuthenticationProtocol -and -not $AuthenticationPassword) {
            throw "AuthenticationPassword is required when AuthenticationProtocol is specified."
        }

        if ($AuthenticationPassword -and -not $AuthenticationProtocol) {
            throw "AuthenticationProtocol is required when AuthenticationPassword is specified."
        }

        # Privacy pair validation
        if ($PrivacyProtocol -and -not $PrivacyPassword) {
            throw "PrivacyPassword is required when PrivacyProtocol is specified."
        }

        if ($PrivacyPassword -and -not $PrivacyProtocol) {
            throw "PrivacyProtocol is required when PrivacyPassword is specified."
        }

        # Privacy without Authentication is not possible
        if (($PrivacyProtocol -or $PrivacyPassword) -and -not $AuthenticationProtocol) {
            throw "Privacy settings require authentication."
        }

        # Validate supplied address and resolve endpoint
        $Endpoint = Resolve-SnmpEndpoint -ComputerName $ComputerName -Port $Port

        # Resolve SNMP version code
        $VersionCode = Resolve-SnmpVersion $Version

        # Set the timestamp
        $Timestamp = Get-Date
    }

    process {
        # Create a list of variable to send in SNMP communication to the endpoint
        $Variables = [System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]]::new()
        foreach($id in $Oid) {
            $obj = [Lextm.SharpSnmpLib.Variable]::new([Lextm.SharpSnmpLib.ObjectIdentifier]::new($id))
            $Variables.Add($obj)
        }

        # Start communication depending on SNMP version
        switch ($PSCmdlet.ParameterSetName) {
            'Community' {
                try {
                    $data = [Lextm.SharpSnmpLib.Messaging.Messenger]::Get($VersionCode, $Endpoint, $Community, $Variables, $Timeout)
                } catch {
                    throw "SNMP $Version error: $($_.Exception.Message)"
                }
            }

            'V3' {
                 # Build auth and privacy providers
                $AuthProvider = Resolve-SnmpAuthenticationProvider `
                    -AuthenticationProtocol $AuthenticationProtocol `
                    -AuthenticationPassword $AuthenticationPassword
                $PrivacyProvider = Resolve-SnmpPrivacyProvider `
                    -AuthenticationProvider $AuthProvider `
                    -PrivacyProtocol $PrivacyProtocol `                    -PrivacyPassword $PrivacyPassword

                # SNMP Discovery
                try {
                    $Discovery = [Lextm.SharpSnmpLib.Messaging.Messenger]::GetNextDiscovery([Lextm.SharpSnmpLib.SnmpType]::GetRequestPdu)
                    $Report = $Discovery.GetResponse($Timeout, $Endpoint)
                } catch {
                    throw "SNMP $Version discovery failed: $($_.Exception.Message)"
                }

                # SNMP Request
                try {
                    $Request = [Lextm.SharpSnmpLib.Messaging.GetRequestMessage]::new(
                        $VersionCode,
                        [Lextm.SharpSnmpLib.Messaging.Messenger]::NextMessageId,
                        [Lextm.SharpSnmpLib.Messaging.Messenger]::NextRequestId,
                        [Lextm.SharpSnmpLib.OctetString]::new($Username),
                        $Variables,
                        $PrivacyProvider,
                        $Report
                    )
                    $Reply = [Lextm.SharpSnmpLib.Messaging.SnmpMessageExtension]::GetResponse(
                        $Request,
                        $Timeout,
                        $Endpoint
                    )
                } catch {
                    throw "SNMP $Version request failed $($_.Exception.Message)"
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
                $data = $Reply.Scope.Pdu.Variables
            }

            default {
                throw "Unsupported parameter set: $($PSCmdlet.ParameterSetName)"
            }
        }

        #
        # Return objects
        #
        foreach ($Variable in $data) {
            New-SnmpDataObject `
                -ComputerName $ComputerName `
                -Variable $Variable `
                -Version $Version `
                -Timestamp $Timestamp
        }
    }
}