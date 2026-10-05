<#
.SYNOPSIS
Tests connectivity and authentication to an SNMP-enabled device.

.DESCRIPTION
Verifies that an SNMP-enabled device is reachable and responds
to SNMP requests using the specified credentials.

The cmdlet performs a GET request against the specified OID and
returns information about the success or failure of the test.

Supports -Quiet for simple success/failure output.

.PARAMETER ComputerName
Hostname or IP address of the target device.

.PARAMETER Port
UDP port used for SNMP communication.

The default value is 161.

.PARAMETER Oid
OID used to verify connectivity.

The default value is sysDescr.0
(1.3.6.1.2.1.1.1.0).

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
Test-SnmpConnection `
    -ComputerName printer01

Tests connectivity to the SNMP-enabled device at printer01 using
the default SNMP version (V2C) and community string (public).

.EXAMPLE
Test-SnmpConnection `
    -ComputerName printer01 `
    -Quiet

Returns True when the SNMP agent responds successfully, otherwise 
returns False. This is useful for scripting and conditional logic.

.EXAMPLE
Test-SnmpConnection `
    -ComputerName switch01 `
    -Version V1 

Tests connectivity to the SNMP-enabled device at switch01 using
SNMP version 1 and the default community string (public).

.EXAMPLE
Test-SnmpConnection `
    -ComputerName switch01 `
    -Version V3 `
    -Username admin `
    -AuthenticationProtocol SHA512 `
    -AuthenticationPassword $AuthenticationPassword `
    -PrivacyProtocol AES `
    -PrivacyPassword $PrivacyPassword

Tests connectivity to the SNMP-enabled device at switch01 using
SNMP version 3 with the specified username, authentication protocol, 
authentication password, privacy protocol, and privacy password.

.OUTPUTS
SnmpTools.ConnectionTest

Returns a connection test result containing the
target device, SNMP version, success state,
response time and any error message.

.NOTES
This cmdlet performs an SNMP GET request against the
specified OID to verify connectivity and credentials.

A successful result indicates:
- The target device is reachable.
- The SNMP service is responding.
- The supplied credentials are valid.
- The requested OID is accessible.

When -Quiet is specified, the cmdlet returns only
True or False.
#>
function Test-SnmpConnection
{
    [OutputType('SnmpTools.ConnectionTest')]
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

        [Parameter()]
        [string]$Oid = "1.3.6.1.2.1.1.1.0", #sysDescr

        [Parameter()]
        [ValidateRange(-1,2147483647)]
        [int]$Timeout = 5000,

        [Parameter()]
        [switch]$Quiet,

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
    }

    process {
        # Create parameters to use for Get-SnmpData communication
        $params = @{
            ComputerName = $ComputerName
            Port         = $Port
            Oid          = $Oid
            Timeout      = $Timeout
            Version      = $Version
        }

        if ($PSCmdlet.ParameterSetName -eq 'Community') {
            $params.Community = $Community
        }
        else {
            $params.Username = $Username
            $params.AuthenticationProtocol = $AuthenticationProtocol
            $params.AuthenticationPassword = $AuthenticationPassword
            $params.PrivacyProtocol = $PrivacyProtocol
            $params.PrivacyPassword = $PrivacyPassword
        }

        # Attempt to get SNMP data and measure response time
        $success = $false
        $Reply = $null
        $errorMessage = $null
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            $Reply = Get-SnmpData @params
            $success = $true
        }
        catch {
            # Failed to get SNMP data
            $errorMessage = $_.Exception.Message
        } finally {
            $stopwatch.Stop()
        } 

        if ($Quiet) {
            $success
        } else {
            [PSCustomObject]@{
                PSTypeName   = 'SnmpTools.ConnectionTest'
                ComputerName = $ComputerName
                Version      = $Version
                Success      = $success
                ErrorMessage = $errorMessage
                ResponseTime = $stopwatch.ElapsedMilliseconds
                Oid          = $Oid
                Type         = if ($Reply) { $Reply.Type } else { $null }
                Value        = if ($Reply) { $Reply.Value } else { $null }
            }
        }

        
    }
}