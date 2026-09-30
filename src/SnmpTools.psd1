@{
    RootModule = 'SnmpTools.psm1'

    ModuleVersion = '0.3.0'

    GUID = '422306ee-516d-49f9-af40-afc4d1438ef1'

    Author = 'Matthijs Zwaan'

    Description = 'PowerShell module for querying and modifying SNMP-enabled devices using SNMP v1, v2c and v3.'

    Copyright = '(c) 2026 Matthijs Zwaan. Licensed under the MIT License.'

    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Get-SnmpData',
        'Set-SnmpData',
        'Get-SnmpNext',
        'Get-SnmpWalk'
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
Version 0.3.0

New Features
- Added Get-SnmpWalk cmdlet
- Added SnmpWalkMode enumeration
- Support for walking entire MIB trees
- Support for subtree-limited walks

Improvements
- Improved module documentation
- Updated CI/CD workflow

Supported Operations
- GET
- SET
- GETNEXT
- WALK

Supported Versions
- SNMP v1
- SNMP v2c
- SNMP v3

Built on top of SharpSnmpLib.
SharpSnmpLib is licensed under the MIT/X11 License.
'@
        }
    }
}