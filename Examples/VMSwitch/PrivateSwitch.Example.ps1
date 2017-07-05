Configuration PrivateSwitch
{
    Import-DscResource -ModuleName HyperVDsc -Name VMSwitch
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMSwitch HostSwitch
    {
        Name = 'HostSwitch'
        Type = 'Private'
        Ensure = 'Present'
    }
}
