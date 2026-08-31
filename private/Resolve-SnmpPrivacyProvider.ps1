function Resolve-SnmpPrivacyProvider
{
    param(
        [Parameter(Mandatory)]
        [Lextm.SharpSnmpLib.Security.IAuthenticationProvider]
        $AuthenticationProvider,

        [string]$PrivacyProtocol,

        [securestring]$PrivacyPassword
    )

    # SNMPV3 noAuthNoPriv / authNoPriv
    if ([string]::IsNullOrWhiteSpace($PrivacyProtocol))
    {
        return [Lextm.SharpSnmpLib.Security.DefaultPrivacyProvider]::new(
            $AuthenticationProvider
        )
    }

    # SNMPv3 with AuthPriv
    
    # Convert the password from securestring via plaintext to octetstring
    $Password = [Lextm.SharpSnmpLib.OctetString]::new((
        [System.Net.NetworkCredential]::new(
            '',
            $PrivacyPassword
        ).Password
    ))

    # Create and return matching privacy provider
    switch ($PrivacyProtocol)
    {
        # Obsolete
        'DES'
        {
            return [Lextm.SharpSnmpLib.Security.DESPrivacyProvider]::new(
                $Password,
                $AuthenticationProvider
            )
        }

        # Obsolete
        '3DES'
        {
            return [Lextm.SharpSnmpLib.Security.TripleDESPrivacyProvider]::new(
                $Password,
                $AuthenticationProvider
            )
        }

        'AES'
        {
            return [Lextm.SharpSnmpLib.Security.AESPrivacyProvider]::new(
                $Password,
                $AuthenticationProvider
            )
        }

        'AES192'
        {
            return [Lextm.SharpSnmpLib.Security.AES192PrivacyProvider]::new(
                $Password,
                $AuthenticationProvider
            )
        }

        'AES256'
        {
            return [Lextm.SharpSnmpLib.Security.AES256PrivacyProvider]::new(
                $Password,
                $AuthenticationProvider
            )
        }

        # Anything else is unsupported
        default
        {
            throw "Unsupported privacy protocol '$PrivacyProtocol'."
        }
    }
}