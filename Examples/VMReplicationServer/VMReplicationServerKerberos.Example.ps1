Configuration VMReplicationServerKerberos
{
    Import-DscResource -ModuleName HyperVDsc -Name VMReplicationServer
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMReplicationServer VMReplicationServerKerberos
    {
        SingleInstance = 'Yes'
        ReplicationEnabled = $true
        AllowedAuthenticationType = 'Kerberos'
        KerberosAuthenticationPort = 80
        ReplicationAllowedFromAnyServer = $true
        DefaultStorageLocation = 'D:\VHD'
    }
}

VMReplicationServerKerberos
