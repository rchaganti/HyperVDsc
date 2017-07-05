Configuration SETTeamSwitch
{
    Import-DscResource -ModuleName cHyper-V -Name VMSwitch
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMSwitch HostSwitch {
        Name = 'HostSwitch'
        Type = 'External'
        AllowManagementOS = $false
        MinimumBandwidthMode = 'Weight'
        TeamingMode = 'SwitchIndependent'
        LoadBalancingAlgorithm = 'HyperVPort'
        NetAdapterName = 'NIC1','NIC2','NIC3','NIC4'
        Ensure = 'Present'
    }
}
