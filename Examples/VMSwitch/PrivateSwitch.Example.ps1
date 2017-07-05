Configuration PrivateSwitch
{
    Import-DscResource -ModuleName cHyper-V -Name VMSwitch
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMSwitch HostSwitch {
        Name = 'HostSwitch'
        Type = 'Private'
        Ensure = 'Present'
    }
}
