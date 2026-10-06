<#
.SYNOPSIS
Retrieves SNMP data from a network device.

.DESCRIPTION
Retrieves one or more OIDs from a network device.
This cmdlet supports SNMP v1, v2c and v3.

.PARAMETER ComputerName
Hostname or IP address of the target device.

Accepts pipeline input directly and by property name.

.PARAMETER Port
UDP port used for SNMP communication.

The default value is 161.

.PARAMETER Oid
One or more OIDs to retrieve.

.PARAMETER Timeout
Maximum time, in milliseconds, to wait for a response to each
individual SNMP request.

The default value is 5000 milliseconds. 
0 and -1 indicate an infinite timeout.

.PARAMETER Version
SNMP version to use. 
Default version is V2C. 

supported values:
- V1
- V2C
- V3

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

Queries a device using SNMPv3 and authNoPriv

.EXAMPLE
Get-SnmpData `
    -ComputerName printer01 `
    -Version V3 `
    -Username admin `
    -AuthenticationProtocol SHA512 `
    -AuthenticationPassword $AuthenticationPasqsword `
    -PrivacyProtocol AES `
    -PrivacyPassword $PrivacyPassword `
    -Oid '1.3.6.1.2.1.1.1.0'

Queries a device using SNMPv3 and authPriv

.OUTPUTS
SnmpTools.SnmpData

.NOTES
DES and 3DES are supported for compatibility with legacy devices
but are considered cryptographically obsolete.
#>
function Get-SnmpData {
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
        [string[]]$Oid,

        [Parameter()]
        [ValidateRange(-1, 2147483647)]
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
        
        # Validate supplied address and resolve endpoint
        $Endpoint = Resolve-SnmpEndpoint -ComputerName $ComputerName -Port $Port
        
        # Prepare parameters for Invoke-SnmpGet
        $invokeParams = @{
            Endpoint = $Endpoint
            Version  = $Version
            Timeout  = $Timeout
            Oid      = $Oid
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
        Invoke-SnmpGet @invokeParams
    }
}