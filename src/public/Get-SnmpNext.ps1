<#
.SYNOPSIS
Retrieves the next OID in the SNMP MIB tree.

.DESCRIPTION
Retrieves the next available OID after the specified OID using
an SNMP GETNEXT request.

This cmdlet supports SNMP v1, v2c and v3 and returns the
next variable together with its value.

Get-SnmpNext can be used to explore MIB trees and serves as
the foundation for MIB walking operations.

.PARAMETER ComputerName
Hostname or IP address of the target device.

.PARAMETER Port
UDP port used for SNMP communication.

The default value is 161.

.PARAMETER Oid
The starting OID for the GETNEXT operation.

The cmdlet returns the next OID and its value after the
specified OID.

.PARAMETER Timeout
The timeout value in milliseconds.

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
Get-SnmpNext `
    -ComputerName switch01 `
    -Oid '1.3.6.1.2.1.1'

Returns the next OID and value after
1.3.6.1.2.1.1.

.EXAMPLE
Get-SnmpNext `
    -ComputerName switch01 `
    -Oid '1.3.6.1.2.1.1.5.0' `
    -Version V1

Returns the next OID after sysName.0 using SNMPv1.

.EXAMPLE
Get-SnmpNext `
    -ComputerName switch01 `
    -Oid '1.3.6.1.2.1.1' `
    -Version V3 `
    -Username admin `
    -AuthenticationProtocol SHA512 `
    -AuthenticationPassword $AuthenticationPasqsword `
    -PrivacyProtocol AES `
    -PrivacyPassword $PrivacyPassword `

Returns the next OID using SNMPv3 authentication and privacy.

.OUTPUTS
SnmpTools.SnmpData

.NOTES
Uses an SNMP GETNEXT request to retrieve the next OID in
lexicographical order.

This cmdlet returns a single result and is used as the
foundation for the SNMP walk operation.
#>
function Get-SnmpNext {
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
        [ValidateRange(1, 65535)]
        [int]$Port = 161,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Oid,

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
        # Validate supplied address and resolve endpoint
        $Endpoint = Resolve-SnmpEndpoint -ComputerName $ComputerName -Port $Port

        # Set the timestamp
        $Timestamp = Get-Date

        # Get SNMP data
        $reply = Invoke-SnmpGetnext `
            -Endpoint $Endpoint `
            -Oid $Oid `
            -Version $Version `
            -Timeout $Timeout `
            -Community $Community `
            -Username $Username `
            -AuthenticationProtocol $AuthenticationProtocol `
            -AuthenticationPassword $AuthenticationPassword `
            -PrivacyProtocol $PrivacyProtocol `
            -PrivacyPassword $PrivacyPassword
        
        # Return objects
        foreach ($Variable in $reply) {
            New-SnmpDataObject `
                -ComputerName $ComputerName `
                -Variable $Variable `
                -Version $Version `
                -Timestamp $Timestamp
        }
    }
}