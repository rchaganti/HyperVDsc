Configuration HostOSAdapterVlan
{
    Import-DscResource -ModuleName cHyper-V -Name VMNetworkAdapterVlan
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMNetworkAdapterVlan HostOSAdapterVlan {
        Id = 'Management-NIC'
        Name = 'Management-NIC'
        VMName = 'ManagementOS'
        AdapterMode = 'Access'
        VlanId = 10
    }
}
