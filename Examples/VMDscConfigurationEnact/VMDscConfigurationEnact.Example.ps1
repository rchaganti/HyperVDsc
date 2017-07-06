Configuration VmDscCompleteDemo
{
    param (
        [pscredential] $VmCredential,
        [pscredential] $FallbackVMCredential
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName HyperVDsc

    Node localhost
    {
        VMDscConfigurationPublish DomainjoinConfig 
        {
            VMName = 'TestVM'
            VMCredential = $VmCredential
            FallbackVMCredential = $FallbackVMCredential
            ConfigurationMof = 'C:\VMDomainJoin\localhost.mof'
            MetaConfigurationMof = 'C:\lcmdemo\localhost.meta.mof'
            ModuleZip = 'C:\Scripts\xComputerManagement.zip'
        }

        VMDscConfigurationEnact DomainJoinEnact
        {
            VMName = 'TestVM'
            VMCredential = $VmCredential
            FallbackVMCredential = $FallbackVMCredential
            DependsOn = '[VMDscConfigurationPublish]DomainjoinConfig'
        }        
    }
}
