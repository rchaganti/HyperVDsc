Configuration HostOSAdapterVlan
{
    Import-DscResource -ModuleName HyperVDsc -Name VMNetworkAdapterVlan
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMNetworkAdapterVlan HostOSAdapterVlan
    {
        Id = 'Management-NIC'
        Name = 'Management-NIC'
        VMName = 'ManagementOS'
        AdapterMode = 'Access'
        VlanId = 10
    }
}
