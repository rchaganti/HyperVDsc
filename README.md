#Desired State Configuration Resources for Microsoft Hyper-V#
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

Here is a lit of resources that I have been working on.

| Resource Name  | Description |
| -------------   | ------------- |
| VMHostServerConfiguration | Server configuration items in Hyper-V host settings. |
| VMHostUserConfiguration | User Configuration items in Hyper-V host Settings. |
| VMHostLiveMigration | Live migration settings for the Hyper-V host.|
| VMHostReplication | Replication configuration for the Hyper-V host.|
| VirtualSAN | Virtual SAN Configuration on the Hyper-V host.|
| VMSwitch | VM switch management.|
| VMNetworkAdapter | VM network adapter management.|
| VMNetworkAdapterVlan | VM Network adapter VLAN management.|
| VMNetworkAdapterSettings | VM network adapter settings management.|
| SimpleVM | A simple bare-bones VM.|
| VMSCSIController | VM SCSI controller management. |
| VMIDEController | VM IDE controller management.|
| VMVirtualHarddrive | Virtual Hard disk management. |
| VMVirtualHarddriveQoS | Virtual Hard disk QoS management. |
| VMDVDDrive | Virtual DVD drive management.|
| VMIntegrationService | VM Integration Services management. |
| VMCheckPointConfiguration | VM checkpoint configuration management. |
| VMStateConfiguration | VM state configuration such as Automatic stop and start actions. |
| VMMemory | VM memory and dynamic memory configuration.|
| VMCPU | VM CPU and NUMA configuration.|
| VMSecureBoot | VM Secure boot configuration.|
| VMBootOrder | VM boot order configuration.|
| VMIPAddress | Injects an IP Address into a VM.|
| WaitForVMGuestIntegration | Wait for VM guest integration service to become available.|
| VMDscConfigurationPublish | Publish configuration and DSC modules into a VM.|
| VMDscConfigurationEnact | Enact a pending configuration inside a VM.|
| VMFile | Copy files and folders in to a VM.|

The list above is a wishlist and not everything that we already have.