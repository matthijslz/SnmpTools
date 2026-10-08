@{
    RootModule = 'SnmpTools.psm1'

    ModuleVersion = '0.4.0'

    GUID = '422306ee-516d-49f9-af40-afc4d1438ef1'

    Author = 'Matthijs Zwaan'

    Description = 'PowerShell module for querying and modifying SNMP-enabled devices using SNMP v1, v2c and v3. Compatible with Windows PowerShell 5.1 and PowerShell 7.'

    Copyright = '(c) 2026 Matthijs Zwaan. Licensed under the MIT License.'

    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Test-SnmpConnection',
        'Get-SnmpData',
        'Set-SnmpData',
        'Get-SnmpNext',
        'Get-SnmpWalk',
        'Get-SnmpBulk'
    )

    FormatsToProcess = @(
        'SnmpData.Format.ps1xml',
        'SnmpConnectionTest.Format.ps1xml'
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
Version 0.4.0

New Features
- Added Test-SnmpConnection cmdlet to verify SNMP connectivity and authentication.
- Added pipeline support for `ComputerName` on all public cmdlets.
- Officially validated compatibility with PowerShell 7.
- Refactored SNMP communications into an internal transport layer.
'@
        }
    }
}