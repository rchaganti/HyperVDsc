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

    VMNetworkAdapterVlan ClusterAdapterVlan {
        Id = 'Cluster-NIC'
        Name = 'Cluster-NIC'
        VMName = 'ManagementOS'
        AdapterMode = 'Access'
        VlanId = 20
    }

    #The following configuration removes any VLAN setting, if present.
    VMNetworkAdapterVlan JustAnotherAdapterVlan {
        Id = 'JustAnother-NIC'
        Name = 'JustAnother-NIC'
        VMName = 'ManagementOS'
        AdapterMode = 'Untagged'
    }
}
