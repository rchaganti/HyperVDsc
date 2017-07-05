Configuration SimpleHostTeamvSwitch
{
    Import-DscResource -ModuleName HyperVDsc -Name VMSwitch
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMSwitch HostSwitch
    {
        Name = 'HostSwitch'
        Type = 'External'
        AllowManagementOS = $true
        MinimumBandwidthMode = 'Weight'
        NetAdapterName = 'HostTeam'
        Ensure = 'Present'
    }
}
