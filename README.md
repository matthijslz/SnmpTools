# SnmpTools
SnmpTools is a PowerShell module for querying and modifying SNMP-enabled devices.
The module provides a PowerShell-native interface for SNMP v1, v2c and v3, built on top of SharpSnmpLib.

## Features
- SNMP v1 support
- SNMP v2c support
- SNMP v3 support
- GET operations
- SET operations
- Multiple OID retrieval in a single request
- SNMPv3 authentication support
- SNMPv3 privacy support
- PowerShell object output
- PowerShell formatting support

## Installation
### PowerShell Gallery

```powershell
Install-Module SnmpTools
```

### Manual Installation
Clone or download this repository and copy the module folder to one of the paths in:
```powershell
$env:PSModulePath -split ';'
```
Then import the module:
```powershell
Import-Module SnmpTools
```

## Supported SNMP Versions
| Version | Supported |
|----------|----------|
| SNMP v1 | Yes |
| SNMP v2c | Yes |
| SNMP v3 noAuthNoPriv | Yes |
| SNMP v3 authNoPriv | Yes |
| SNMP v3 authPriv | Yes |

## Available Commands
### Get-SnmpData
Retrieves one or more OIDs from an SNMP-enabled device.

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

## Examples

### Retrieve system name (SNMP v2c)
```powershell
Get-SnmpData `
    -ComputerName switch01 `
    -Community public `
    -Oid '1.3.6.1.2.1.1.5.0'
```

### Retrieve multiple OIDs
```powershell
Get-SnmpData `
    -ComputerName printer01 `
    -Oid @(
        '1.3.6.1.2.1.1.5.0',
        '1.3.6.1.2.1.1.1.0'
    )
```

### Retrieve data using SNMP v3
```powershell
$Password = ConvertTo-SecureString `
    'Password123!' `
    -AsPlainText `
    -Force

Get-SnmpData `
    -ComputerName switch01 `
    -Version V3 `
    -Username admin `
    -AuthenticationProtocol SHA512 `
    -AuthenticationPassword $Password `
    -Oid '1.3.6.1.2.1.1.5.0'
```

### Modify a string value
```powershell
Set-SnmpData `
    -ComputerName switch01 `
    -Community private `
    -Oid '1.3.6.1.x.x.x'