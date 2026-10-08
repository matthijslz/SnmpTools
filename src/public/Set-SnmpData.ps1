<#
.SYNOPSIS
Sets the value of a writable SNMP OID on a target device.

.DESCRIPTION
Sets the value of a writable OID on an SNMP-enabled device using
SNMP v1, v2c or v3.

The cmdlet supports multiple SNMP data types and returns the value
reported by the device after the operation.

Supports -WhatIf and -Confirm for safe execution.

.PARAMETER ComputerName
Hostname or IP address of the target device.

Accepts pipeline input directly and by property name.

.PARAMETER Port
UDP port used for SNMP communication.

The default value is 161.

.PARAMETER Oid
OID to modify.

.PARAMETER NewValue
The new value to assign to the specified OID.

The value is converted to the SNMP data type specified by
the DataType parameter.

.PARAMETER DataType
Specifies the SNMP data type used when setting the value.

Supported values include:
- OctetString
- Integer32
- Gauge32
- Counter32
- Unsigned32
- TimeTicks
- IpAddress

If omitted, OctetString is used.

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
Set-SnmpData `
    -ComputerName printer `
    -Oid '1.3.6.1.x.x.x' `
    -NewValue 'Printer'

Sets the specified OID to the string value 'Printer'.

.EXAMPLE
Set-SnmpData `
    -ComputerName switch01 `
    -Oid '1.3.6.1.x.x.x' `
    -NewValue 1 `
    -DataType Integer32

Sets the specified OID to the Integer32 value 1.

.EXAMPLE
Set-SnmpData `
    -ComputerName switch01 `
    -Oid '1.3.6.1.x.x.x' `
    -NewValue '192.168.1.100' `
    -DataType IpAddress
    -WhatIf

Shows what would happen without sending the SNMP SET request.

.OUTPUTS
SnmpData

.NOTES
This cmdlet only supports single OID SET operations.

SNMP SET requests require the target OID to be writable and
the supplied credentials to have write permissions.
#>
function Set-SnmpData {
    [OutputType([SnmpData])]
    [CmdletBinding(
        DefaultParameterSetName = 'Community',
        SupportsShouldProcess = $true
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

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [object]$NewValue,

        [Parameter()]
        [SnmpDataType]$DataType = [SnmpDataType]::OctetString,

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
        
        # Add support for -WhatIf and -Confirm
        if (-not $PSCmdlet.ShouldProcess(
                "$ComputerName ($Oid)",
                "Set value to '$NewValue'"
            )) {
            return
        }

        # Prepare parameters for Invoke-SnmpSet
        $invokeParams = @{
            ComputerName    = $ComputerName
            Port            = $Port
            Version         = $Version
            Timeout         = $Timeout
            Oid             = $Oid
            NewValue        = $NewValue
            DataType        = $DataType
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
        
        # Invoke SNMP SET command and return results
        Invoke-SnmpSet @invokeParams
    }
}