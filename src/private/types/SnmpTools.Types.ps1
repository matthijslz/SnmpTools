<#
.SYNOPSIS
Internal type definitions used by SnmpTools.

.DESCRIPTION
This file contains all PowerShell enums and classes used by the
SnmpTools module.

The definitions are intentionally consolidated into a single file
to ensure that dependent types are available at parse time. This
avoids issues where classes reference enums that have not yet been
loaded.

.NOTES
This file should be loaded before any providers, transport
functions, validation functions, or public cmdlets.

PowerShell classes are resolved at parse time. Keeping all enum and
class definitions in a single file simplifies loading and prevents
TypeNotFound parser warnings in PowerShell and Visual Studio Code.
#>

<#
.DESCRIPTION
SNMP protocol versions supported by SnmpTools.
#>
enum SnmpVersion {
    V1
    V2C
    V3
}

<#
.DESCRIPTION
Data types returned by SNMP agents.
#>
enum SnmpDataType {
    OctetString
    Integer32
    Gauge32
    Counter32
    Unsigned32
    TimeTicks
    IpAddress
}

<#
.DESCRIPTION
Modes supported by Get-SnmpWalk.
#>
enum SnmpWalkMode {
    Default         # Walks the entire MIB tree starting from the specified OID.
    WithinSubtree   # Walks only within the subtree of the specified OID, stopping when the next OID is no longer a child of the base OID.
}

<#
.DESCRIPTION
Represents a single SNMP variable returned by an SNMP agent.

Instances of this class are produced by Get-SnmpData,
Get-SnmpNext, Get-SnmpBulk and Get-SnmpWalk.

Properties:
- ComputerName: Device queried.
- Oid: Returned object identifier.
- Type: SNMP data type.
- RawValue: Original SharpSnmpLib value object.
- Value: String representation of the value.
- Version: SNMP version used.
- Timestamp: Time the data was retrieved.
#>
class SnmpData
{
    [string]$ComputerName

    [string]$Oid

    [string]$Type

    [object]$RawValue

    [object]$Value

    [SnmpVersion]$Version

    [datetime]$Timestamp

    SnmpData() {}

    SnmpData(
        [string]$ComputerName,
        [string]$Oid,
        [string]$Type,
        [object]$RawValue,
        [object]$Value,
        [SnmpVersion]$Version,
        [datetime]$Timestamp
    )
    {
        $this.ComputerName = $ComputerName
        $this.Oid          = $Oid
        $this.Type         = $Type
        $this.RawValue     = $RawValue
        $this.Value        = $Value
        $this.Version      = $Version
        $this.Timestamp    = $Timestamp
    }

    [string] ToString()
    {
        return $this.Value
    }
}

<#
.DESCRIPTION
Represents the result of an SNMP connectivity test.

Instances of this class are produced by Test-SnmpConnection.

Properties:
- ComputerName: Device tested.
- Version: SNMP version used.
- Success: Indicates whether communication succeeded.
- ErrorMessage: Error returned by the SNMP operation.
- ResponseTime: Round-trip time in milliseconds.
- Oid: OID used during the test.
- Type: Returned SNMP data type.
- Value: Returned value.
#>
class SnmpConnectionTest
{
    [string]$ComputerName

    [SnmpVersion]$Version

    [bool]$Success

    [string]$ErrorMessage

    [long]$ResponseTime

    [string]$Oid

    [string]$Type

    [object]$Value

    SnmpConnectionTest() {}

    SnmpConnectionTest(
        [string]$ComputerName,
        [SnmpVersion]$Version,
        [bool]$Success,
        [string]$ErrorMessage,
        [long]$ResponseTime,
        [string]$Oid,
        [string]$Type,
        [object]$Value
    )
    {
        $this.ComputerName = $ComputerName
        $this.Version      = $Version
        $this.Success      = $Success
        $this.ErrorMessage = $ErrorMessage
        $this.ResponseTime = $ResponseTime
        $this.Oid          = $Oid
        $this.Type         = $Type
        $this.Value        = $Value
    }
}