Configuration VMReplicationServerDisable
{
    Import-DscResource -ModuleName HyperVDsc -Name VMReplicationServer
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMReplicationServer VMReplicationServerDisable
    {
        SingleInstance = 'Yes'
        ReplicationEnabled = $false
    }
}

VMReplicationServerDisable
