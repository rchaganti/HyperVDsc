Configuration SimpleHostTeamvSwitch
{
    Import-DscResource -ModuleName cHyper-V -Name VMSwitch
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMSwitch HostSwitch {
        Name = 'HostSwitch'
        Type = 'External'
        AllowManagementOS = $true
        MinimumBandwidthMode = 'Weight'
        NetAdapterName = 'HostTeam'
        Ensure = 'Present'
    }
}
