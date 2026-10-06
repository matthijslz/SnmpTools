function Test-SnmpParameters
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [SnmpVersion]$Version,

        [string]$Community,

        [string]$Username,

        [string]$AuthenticationProtocol,

        [securestring]$AuthenticationPassword,

        [string]$PrivacyProtocol,

        [securestring]$PrivacyPassword
    )

    # SNMPv1 and SNMPv2c both require a community
    $isCommunityVersion = $Version -in @(
        [SnmpVersion]::V1,
        [SnmpVersion]::V2C
    )
    
    # SNMPv1 and SNMPv2c require a community string to be specified
    if ($isCommunityVersion -and [string]::IsNullOrWhiteSpace($Community) ) {
        throw "SNMP versions V1 and V2C require a community."
    }

    # SNMPv1 and SNMPv2c cannot use authentication or privacy settings
    if ($isCommunityVersion -and ($AuthenticationProtocol -or $AuthenticationPassword -or $PrivacyProtocol -or $PrivacyPassword)) {
        throw "SNMP versions V1 and V2C cannot use authentication or privacy settings."
    }

    # SNMPv3 requires a username to be specified (even if no authentication or privacy is used)
    if ($Version -eq [SnmpVersion]::V3 -and [string]::IsNullOrWhiteSpace($Username) ) {
        throw "SNMP version V3 requires a username."
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