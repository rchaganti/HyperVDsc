# Desired State Configuration Resources for Microsoft Hyper-V #
This project aims to develop a set of PowereShell DSC resources for managing Windows Server Hyper-V resource configurations.

There are existing resource modules that address some of these configurations.

- [cHyper-V](https://github.com/rchaganti/DSCResources/tree/master/cHyper-V)
- [xHyper-V](https://github.com/PowerShell/xHyper-V)

However, these existing modules offer only a subset of resource configurations possible and are not [HQRM compliant](https://github.com/PowerShell/DscResources/blob/master/HighQualityModuleGuidelines.md).

So, the objectives of this HyperVDsc resource module is to ensure that

- we have a good coverage for different Hyper-V host and VM configurations.
- we offer granular resource configurations. 
- the resources are HQRM compliant. 

To meet these objectives, I am starting this new repository and will start adding the new set of resources I have been developing. THe primary aim is to ensure we have broader coverage of resource configurations while we make each and every resource in this repository HQRM compliant. Where applicable and easy to manage, we will take the resources from the existing modules listed above to eliminate duplication of work. It may not always be possible if we don't like the current design. There is no point refactoring code when we can easily implement one from scratch.

Here is a list of resources that I have been working on.

| Resource Name  | Description | Status in the repository |
| -------------   | ------------- | ------- |
| VMHostServerConfiguration | Server configuration items in Hyper-V host settings. | Not Available |
| VMHostUserConfiguration | User Configuration items in Hyper-V host Settings. | Not Available |
| VMHostLiveMigration | Live migration settings for the Hyper-V host.| Not Available |
| VMHostReplication | Replication configuration for the Hyper-V host.| Not Available |
| VirtualSAN | Virtual SAN Configuration on the Hyper-V host.| Not Available |
| VMSwitch | VM switch management.| [Available without tests.](https://github.com/rchaganti/HyperVDsc/tree/dev/DSCResources/VMSwitch) |
| VMNetworkAdapter | VM network adapter management.| [Available without tests.](https://github.com/rchaganti/HyperVDsc/tree/dev/DSCResources/VMNetworkAdapter) |
| VMNetworkAdapterVlan | VM Network adapter VLAN management.| [Available without tests.](https://github.com/rchaganti/HyperVDsc/tree/dev/DSCResources/VMNetworkAdapterVlan) |
| VMNetworkAdapterSettings | VM network adapter settings management.| [Available without tests.](https://github.com/rchaganti/HyperVDsc/tree/dev/DSCResources/VMNetworkAdapterSettings) |
| SimpleVM | A simple bare-bones VM.| [Available without tests](https://github.com/rchaganti/HyperVDsc/tree/dev/DSCResources/SimpleVM). |
| VMSCSIController | VM SCSI controller management. | Not Available |
| VMIDEController | VM IDE controller management.| Not Available |
| VMVirtualHarddrive | Virtual Hard disk management. | Not Available |
| VMVirtualHarddriveQoS | Virtual Hard disk QoS management. | Not Available |
| VMDVDDrive | Virtual DVD drive management.| Not Available |
| VMIntegrationService | VM Integration Services management. | Not Available |
| VMCheckPointConfiguration | VM checkpoint configuration management. | Not Available |
| VMStateConfiguration | VM state configuration such as Automatic stop and start actions. | Not Available |
| VMMemory | VM memory and dynamic memory configuration.| Not Available |
| VMCPU | VM CPU and NUMA configuration.| Not Available |
| VMSecureBoot | VM Secure boot configuration.| Not Available |
| VMBootOrder | VM boot order configuration.| Not Available |
| VMIPAddress | Injects an IP Address into a VM.| [Available without tests](https://github.com/rchaganti/HyperVDsc/tree/dev/DSCResources/VMIPAddress).|
| WaitForVMGuestIntegration | Wait for VM guest integration service to become available.| [Available without tests.](https://github.com/rchaganti/HyperVDsc/tree/dev/DSCResources/WaitForVMGuestIntegration)|
| VMDscConfigurationPublish | Publish configuration and DSC modules into a VM.| Available without tests.|
| VMDscConfigurationEnact | Enact a pending configuration inside a VM.| [Available without tests.](https://github.com/rchaganti/HyperVDsc/tree/dev/DSCResources/VMDscConfigurationEnact)|
| VMFile | Copy files and folders in to a VM.| Not Available.|
