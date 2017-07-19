Configuration VMReplicationServerKerberosAndCertificate
{
    Import-DscResource -ModuleName HyperVDsc -Name VMReplicationServer
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMReplicationServer VMReplicationServerKerberosAndCertificate
    {
        SingleInstance = 'Yes'
        ReplicationEnabled = $true
        AllowedAuthenticationType = 'CertificateAndKerberos'
        KerberosAuthenticationPort = 80
        CertificateAuthenticationPort = 443
        CertificateThumbprint = '44ABE08A005ED048B4F6EE9F7A2624A53818BA36'
        ReplicationAllowedFromAnyServer = $true
        DefaultStorageLocation = 'D:\VHD'
    }
}

VMReplicationServerKerberosAndCertificate
