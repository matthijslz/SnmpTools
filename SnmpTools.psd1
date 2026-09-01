@{
    RootModule = 'SnmpTools.psm1'

    ModuleVersion = '0.1.0'

    GUID = '422306ee-516d-49f9-af40-afc4d1438ef1'

    Author = 'Matthijs Zwaan'

    Description = 'PowerShell module for querying and modifying SNMP-enabled devices using SNMP v1, v2c and v3.'

    Copyright = '(c) 2026 Matthijs Zwaan. Licensed under the MIT License.'

    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Get-SnmpData',
        'Set-SnmpData'
    )

    FormatsToProcess = @(
        'SnmpTools.Format.ps1xml'
    )

    PrivateData = @{
        PSData = @{
            Tags = @(
                'SNMP'
                'SNMPv1'
                'SNMPv2c'
                'SNMPv3'
                'Network'
                'Monitoring'
                'Automation'
                'PowerShell'
            )

            LicenseUri = 'https://opensource.org/licenses/MIT'

            ProjectUri = 'https://github.com/matthijslz/SnmpTools'

            ReleaseNotes = @'
Initial unofficial release.

Supports:
- SNMP v1 GET
- SNMP v2c GET
- SNMP v3 GET
- SNMP v1 SET
- SNMP v2c SET
- SNMP v3 SET
- Single and multiple OID GET requests
- Single OID SET requests with configurable SNMP data types

Built on top of SharpSnmpLib.
SharpSnmpLib is licensed under the MIT/X11 License.
'@
        }
    }
}