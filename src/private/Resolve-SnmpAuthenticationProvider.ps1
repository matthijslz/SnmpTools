function Resolve-SnmpAuthenticationProvider
{
    param(
        [string]$AuthenticationProtocol,
        [securestring]$AuthenticationPassword
    )

    # SNMPv3 with noAuthNoPriv
    if ([string]::IsNullOrEmpty($AuthenticationProtocol))
    {
        return [Lextm.SharpSnmpLib.Security.DefaultAuthenticationProvider]::new()
    }

    # Convert the password from securestring via plaintext to octetstring
    $Password = [Lextm.SharpSnmpLib.OctetString]::new((
        [System.Net.NetworkCredential]::new(
            '',
            $AuthenticationPassword
        ).Password
    ))

    # Create and return matching authentication provider
    switch ($AuthenticationProtocol)
    {
        # Obsolete
        'MD5'
        {
            return [Lextm.SharpSnmpLib.Security.MD5AuthenticationProvider]::new($Password)
        }

        # Obsolete
        'SHA1'
        {
            return [Lextm.SharpSnmpLib.Security.SHA1AuthenticationProvider]::new($Password)
        }

        'SHA256'
        {
            return [Lextm.SharpSnmpLib.Security.SHA256AuthenticationProvider]::new($Password)
        }

        'SHA384'
        {
            return [Lextm.SharpSnmpLib.Security.SHA384AuthenticationProvider]::new($Password)
        }

        'SHA512'
        {
            return [Lextm.SharpSnmpLib.Security.SHA512AuthenticationProvider]::new($Password)
        }

        # Anything else is unsupported
        default
        {
            throw "Unsupported authentication protocol '$AuthenticationProtocol'."
        }
    }
}