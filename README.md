# SnmpTools
SnmpTools is a PowerShell module for querying and modifying SNMP-enabled devices.
The module provides a PowerShell-native interface for SNMP v1, v2c and v3, built on top of SharpSnmpLib. Compatible with Windows PowerShell 5.1 and PowerShell 7.

## Features
- Support for SNMP v1, v2c and v3
- SNMPv3 authentication and privacy support
- GET operations for single OID and multiple OID retrieval
- SET operations
- GETNEXT operations
- WALK operations to end of subtree or end of MIB
- Operation to test SNMP connection
- All public cmdlets support pipeline input for `ComputerName`.
- PowerShell object output
- PowerShell formatting support

## Installation
### PowerShell Gallery
Make sure you can install modules from the PSGallery, then simply run:
```powershell
Install-Module SnmpTools
```
Verify the available commands:
```powershell
Get-Command -Module SnmpTools
```

### Manual Installation
Clone or download this repository, then import the module by path:
```powershell
Import-Module "C:\Path\To\SnmpTools\src\SnmpTools.psm1"
```
Or copy the module files in the src folder to one of the default PowerShell paths, and then import the module by name:
```powershell
Import-Module SnmpTools
```

## Available Commands
### Get-SnmpData
Retrieves one or more OIDs from an SNMP-enabled device. This and all other commands return data in object notation for easy further processing:

```
ComputerName : switch01
Oid          : 1.3.6.1.2.1.1.5.0
Type         : OctetString
Value        : switch01
Version      : V2C
Timestamp    : <Current Timestamp>
```

### Set-SnmpData
Modifies a writable OID on an SNMP-enabled device.

Supports:
- OctetString
- Integer32
- Gauge32
- Counter32
- Unsigned32
- TimeTicks
- IpAddress

### Get-SnmpNext
Retrieves the next OID in the SNMP MIB tree. See also Get-SnmpWalk for successive SNMP GETNEXT operations.

### Get-SnmpWalk
Retrieves SNMP data by walking the MIB tree. By default the whole MIB tree will be walked, use `-WalkMode WithinSubtree` to only walk the specified subtree. The walk automatically stops when EndOfMibView is reached, the requested subtree is exhausted, or no further OIDs are available.

### Test-SnmpConnection
Verifies that an SNMP-enabled device is reachable and responds to SNMP requests using the specified credentials. The cmdlet performs a GET request against the specified OID and returns information about the success or failure of the test.
Supports `-Quiet` for simple success/failure output.

## Examples
### Retrieve system name using defaults
```powershell
Get-SnmpData `
    -ComputerName switch01 `
    -Oid '1.3.6.1.2.1.1.5.0'
```

### Retrieve multiple OIDs using SNMPv1
```powershell
Get-SnmpData `
    -ComputerName 192.168.1.100 `
    -Version V1 `
    -Community private `
    -Oid @(
        '1.3.6.1.2.1.1.5.0',
        '1.3.6.1.2.1.1.1.0'
    )
```

### Retrieve data using SNMP v3
```powershell
$AuthenticationPassword = ConvertTo-SecureString `
    'AuthenticationPassword' `
    -AsPlainText `
    -Force

$PrivacyPassword = ConvertTo-SecureString `
    'PrivacyPassword' `
    -AsPlainText `
    -Force

Get-SnmpData `
    -ComputerName switch01 `
    -Version V3 `
    -Username admin `
    -AuthenticationProtocol SHA512 `
    -AuthenticationPassword $AuthenticationPassword `
    -PrivacyProtocol AES `
    -PrivacyPassword $PrivacyPassword `
    -Oid '1.3.6.1.2.1.1.5.0'
```

### Modify sysName.0 value using SET
```powershell
Set-SnmpData `
    -ComputerName printer01 `
    -Version V3 `
    -Username admin `
    -AuthenticationProtocol SHA512 `
    -AuthenticationPassword $AuthenticationPassword `
    -PrivacyProtocol AES `
    -PrivacyPassword $PrivacyPassword `
    -Oid '1.3.6.1.2.1.1.5.0' `
    -NewValue 'printer01' `
    -Confirm
```
	
### Retrieve the next OID after sysName.0 using SNMPv1.
```powershell
Get-SnmpNext `
    -ComputerName switch01 `
    -Oid '1.3.6.1.2.1.1.5.0' `
    -Version V1
```
### Walk the system subtree
```powershell
Get-SnmpWalk `
    -ComputerName switch01 `
    -Oid '1.3.6.1.2.1.1' `
    -WalkMode WithinSubtree
```

### Test connection of multiple devices
```powershell
'printer01','printer02','switch01' |
    Test-SnmpConnection `
        -Version V1
```
### Test connection of a single device without info (returns boolean)
```powershell
Test-SnmpConnection 
    -ComputerName device `
    -Version V3 `
    -Username admin `
    -AuthenticationProtocol SHA512 `
    -AuthenticationPassword $AuthenticationPassword `
    -PrivacyProtocol AES `
    -PrivacyPassword $PrivacyPassword `
    -Quiet
```

## License
SnmpTools is licensed under the MIT License.

This project includes third-party software. For details, see
[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).