Configuration VMReplicationServerCertificate
{
    Import-DscResource -ModuleName HyperVDsc -Name VMReplicationServer
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMReplicationServer VMReplicationServerCertificate
    {
        SingleInstance = 'Yes'
        ReplicationEnabled = $true
        AllowedAuthenticationType = 'Certificate'
        CertificateAuthenticationPort = 443
        CertificateThumbprint = '44ABE08A005ED048B4F6EE9F7A2624A53818BA36'
        ReplicationAllowedFromAnyServer = $true
        DefaultStorageLocation = 'D:\VHD'
    }
}

VMReplicationServerCertificate
