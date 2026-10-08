<#
.SYNOPSIS
Retrieves SNMP data by walking the MIB tree.

.DESCRIPTION
Retrieves one or more SNMP variables by performing successive
SNMP GETNEXT operations starting from the specified OID.

This cmdlet supports SNMP v1, v2c and v3.

By default, the walk continues until the end of the MIB view
is reached. Alternatively, the walk can be restricted to the
subtree of the specified OID by using the WalkMode parameter.

Get-SnmpWalk is useful for exploring MIB structures, retrieving
SNMP tables, and collecting large sets of SNMP data without
knowing all OIDs in advance.

.PARAMETER ComputerName
Hostname or IP address of the target device.

Accepts pipeline input directly and by property name.

.PARAMETER Port
UDP port used for SNMP communication.

The default value is 161.

.PARAMETER Oid
The starting OID for the walk operation.

.PARAMETER Timeout
Maximum time, in milliseconds, to wait for a response to each
individual SNMP request.

The default value is 5000 milliseconds. 
0 and -1 indicate an infinite timeout.

.PARAMETER WalkMode
Determines how the walk is performed.

Supported values:

Default
    Walks from the specified OID to the end of the MIB view.

WithinSubtree
    Walks only within the subtree of the specified OID and
    stops when the next OID is no longer a child of the
    starting OID.

The default value is Default.

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
Get-SnmpWalk `
    -ComputerName switch01 `
    -Oid '1.3.6.1.2.1.1'

Walks the MIB tree starting at the specified OID and continues
until the end of the MIB view is reached.

.EXAMPLE
Get-SnmpWalk `
    -ComputerName switch01 `
    -Oid '1.3.6.1.2.1.1' `
    -WalkMode WithinSubtree

Walks only the System subtree and stops when the next OID no
longer belongs to that subtree.

.EXAMPLE
Get-SnmpWalk `
    -ComputerName switch01 `
    -Version V2C `
    -Community public `
    -Oid '1.3.6.1.2.1.1'
    -WalkMode WithinSubtree

Walks the MIB using SNMPv2c authentication.

.EXAMPLE
Get-SnmpWalk `
    -ComputerName switch01 `
    -Version V3 `
    -Username snmpuser `
    -AuthenticationProtocol SHA256 `
    -AuthenticationPassword $AuthPassword `
    -PrivacyProtocol AES `
    -PrivacyPassword $PrivacyPassword `
    -Oid '1.3.6.1.2.1.1' `
    -WalkMode WithinSubtree

Walks the System subtree using SNMPv3 authentication and
privacy.

.OUTPUTS
SnmpData

.NOTES
This cmdlet performs successive SNMP GETNEXT operations to
retrieve data.

When WalkMode is set to WithinSubtree, the walk terminates as
soon as the next OID falls outside the requested subtree.

The cmdlet automatically terminates when:
- EndOfMibView is reached.
- No further OIDs are returned.
- A loop is detected and an exception is thrown
- An SNMP communication error occurs.
#>
function Get-SnmpWalk {
    [OutputType([SnmpData])]
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
        [SnmpWalkMode]$WalkMode = [SnmpWalkMode]::Default,

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
        
        # Set the next OID to the provided OID
        $CurrentOid = $Oid
        
        while ($true) {
            try {
                # Retrieve the next SNMP data point using Get-SnmpNext
                $Next = Invoke-SnmpGetnext `
                    -ComputerName $ComputerName `
                    -Port $Port `
                    -Oid $CurrentOid `
                    -Version $Version `
                    -Timeout $Timeout `
                    -Community $Community `
                    -Username $Username `
                    -AuthenticationProtocol $AuthenticationProtocol `
                    -AuthenticationPassword $AuthenticationPassword `
                    -PrivacyProtocol $PrivacyProtocol `
                    -PrivacyPassword $PrivacyPassword
                
                # Return the next SNMP data point
                $Next
            }
            catch {
                Write-Verbose "Walk terminated: $($_.Exception.Message)"
                break
            }
            
            # If no next OID is returned, we have reached the end of the walk and should stop.
            if (-not $Next) {
                Write-Verbose "Walk completed: No further OIDs returned."
                break
            }

            # If the next OID indicates the end of the MIB view, we should stop.
            if ($Next.Type -eq 'EndOfMibView') {
                Write-Verbose "Walk completed: End of MIB view reached."
                break
            }

            # If the next OID is the same as the current OID, we have a loop and should stop.
            if ($Next.Oid -eq $CurrentOid) {
                throw "SNMP walk detected a loop at OID '$($Next.Id)'."
            }

            # We need to check if the next OID is still within the subtree of the base OID.
            $InsideSubtree = $Next.Oid -eq $Oid -or $Next.Oid.StartsWith("$Oid.")

            # If the walk mode is set to WithinSubtree and the next OID is outside the subtree, we should stop.
            if ($WalkMode -eq [SnmpWalkMode]::WithinSubtree -and -not $InsideSubtree) {
                Write-Verbose "Walk completed: OID '$($Next.Oid)' is outside the subtree."
                break
            } 

            # Update the OID parameter for the next iteration
            $CurrentOid = $Next.Oid
        }
    }
}