<#
.SYNOPSIS
Retrieves multiple SNMP objects efficiently using the GETBULK operation

.DESCRIPTION
Performs an SNMP GETBULK request against a network device.
 
GETBULK is supported by SNMP v2c and SNMP v3 and provides a more
efficient alternative to repeated GETNEXT operations when retrieving
large portions of an SNMP subtree or table.
 
The cmdlet starts at the specified OID and returns one or more
subsequent OIDs and their values, depending on the configured
NonRepeaters and MaxRepetitions values.

.PARAMETER ComputerName
Hostname or IP address of the target device.

Accepts pipeline input directly and by property name.

.PARAMETER Port
UDP port used for SNMP communication.

The default value is 161.

.PARAMETER Oid
The starting OID for the GETBULK operation.

This OID is used as the starting point for the request.
The returned objects depend on the values specified for
NonRepeaters and MaxRepetitions.

.PARAMETER Timeout
The timeout value in milliseconds.

The default value is 5000 milliseconds. 
0 and -1 indicate an infinite timeout.

.PARAMETER NonRepeaters
Specifies the number of supplied OIDs that should behave as
GETNEXT requests rather than repeating requests.
 
For each non-repeater OID, a single successor OID is returned.
 
The default value is 0.

.PARAMETER MaxRepetitions
Specifies the maximum number of repeating objects returned for
the supplied OIDs.
 
Higher values can reduce the number of network round trips when
retrieving large SNMP tables but may increase response size.
 
The default value is 10.

.PARAMETER Version
SNMP version to use. 
Default version is V2C. 

supported values are V2C and V3. SNMP V1 does not support GETBULK requests.

.PARAMETER Community
SNMP community string.

Default value is 'public'.
Only available when using SNMP v1 or SNMP v2c.

.PARAMETER Username
SNMPv3 user name.

Only available when using SNMP v3.

.PARAMETER AuthenticationProtocol
SNMPv3 authentication protocol.

Supported values:
- MD5
- SHA1
- SHA256
- SHA384
- SHA512

Only available when using SNMP v3.

.PARAMETER AuthenticationPassword
SNMPv3 authentication password.

Only available when using SNMP v3.

.PARAMETER PrivacyProtocol
SNMPv3 privacy protocol.

Supported values:
- DES
- 3DES
- AES
- AES192
- AES256

Only available when using SNMP v3.

.PARAMETER PrivacyPassword
SNMPv3 privacy password.

Only available when using SNMP v3.

.EXAMPLE
Get-SnmpBulk `
    -ComputerName switch01 `
    -Oid 1.3.6.1.2.1.2.2 `
    -NonRepeaters 0 `
    -MaxRepetitions 25

Retrieves up to 25 rows from the interface table.

.EXAMPLE
Get-SnmpBulk `
-ComputerName switch01 `
-Oid 1.3.6.1.2.1.31.1.1.1.1 `
-MaxRepetitions 50
 
Retrieves up to 50 interface names using IF-MIB::ifName.

.EXAMPLE
'printer01','printer02' |
    Get-SnmpBulk `
        -Oid 1.3.6.1.2.1.25.3.2.1.3 `
        -MaxRepetitions 20
 
Uses pipeline input to retrieve multiple entries from the
Host Resources MIB on multiple devices.

.EXAMPLE
Get-SnmpBulk `
    -ComputerName switch01 `
    -Version V3 `
    -Username monitor `
    -AuthenticationProtocol SHA512 `
    -AuthenticationPassword $AuthenticationPassword `
    -PrivacyProtocol AES `
    -PrivacyPassword $PrivacyPassword `
    -Oid 1.3.6.1.2.1.2.2 `
    -MaxRepetitions 25
 
Retrieves interface data using SNMPv3 with authentication
and privacy enabled.

.OUTPUTS
SnmpTools.SnmpData

Returns one or more SnmpTools.SnmpData objects representing
the OIDs and values returned by the remote SNMP agent.

.NOTES
GETBULK is intended for efficient retrieval of SNMP tables and
large subtrees.
 
When retrieving large datasets, increasing MaxRepetitions can
significantly reduce the number of network round trips compared
to repeated GETNEXT requests.
 
Some SNMP agents may impose implementation-specific limits on
the number of values returned in a single GETBULK response.
#>
function Get-SnmpBulk {
    [OutputType('SnmpTools.SnmpData')]
    [CmdletBinding(
        DefaultParameterSetName = 'Community'
    )]
    param (
        # General required parameters
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('IPAddress')]
        [string]$ComputerName,

        [Parameter()]
        [ValidateRange(1, 65535)]
        [int]$Port = 161,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Oid,

        [Parameter()]
        [ValidateRange(-1, 2147483647)]
        [int]$Timeout = 5000,

        [Parameter()]
        [ValidateRange(0, 2147483647)]
        [int]$NonRepeaters = 0,

        [Parameter()]
        [ValidateRange(1, 2147483647)]
        [int]$MaxRepetitions = 10,

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
        
        # Validate SNMP parameters
        Test-SnmpParameters `
            -Version $Version `
            -Community $Community `
            -Username $Username `
            -AuthenticationProtocol $AuthenticationProtocol `
            -AuthenticationPassword $AuthenticationPassword `
            -PrivacyProtocol $PrivacyProtocol `
            -PrivacyPassword $PrivacyPassword
    }

    process {
        Write-Verbose "Processing $ComputerName"

        # Prepare parameters for Invoke-SnmpGetbulk
        $invokeParams = @{
            ComputerName    = $ComputerName
            Port            = $Port
            Version         = $Version
            Timeout         = $Timeout
            Oid             = $Oid
            NonRepeaters    = $NonRepeaters
            MaxRepetitions  = $MaxRepetitions
        }
        if ($PSCmdlet.ParameterSetName -eq 'Community') {
            $invokeParams.Community = $Community
        }
        else {
            $invokeParams.Username = $Username
            $invokeParams.AuthenticationProtocol = $AuthenticationProtocol
            $invokeParams.AuthenticationPassword = $AuthenticationPassword
            $invokeParams.PrivacyProtocol = $PrivacyProtocol
            $invokeParams.PrivacyPassword = $PrivacyPassword
        }

        # Get SNMP data and return the results
        Invoke-SnmpGetbulk @invokeParams
    }
}