$Global:DSCModuleName   = 'cHyper-V'
$Global:DSCResourceName = 'VMSwitch'

#region HEADER
if ( (-not (Test-Path -Path '.\DSCResource.Tests\')) -or `
     (-not (Test-Path -Path '.\DSCResource.Tests\TestHelper.psm1')) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git')
}
else
{
    & git @('-C',(Join-Path -Path (Get-Location) -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module .\DSCResource.Tests\TestHelper.psm1 -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit 
#endregion

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $Global:DSCResourceName {

        # Create the Mock Objects that will be used for running tests
        $MockNormalSwitch = [PSCustomObject] @{
            Name                           = 'NormalSwitch'
            SwitchType                     = 'External'
            NetAdapterName                 = 'SLOT 3'
            NetAdapterInterfaceDescription = 'Ethernet Adapter 1'
            EnableIoV                      = $False
            EnablePacketDirect             = $False
            EmbeddedTeamingEnabled         = $False
            AllowManagementOS              = $True
            BandwidthReservationMode       = 'Absolute'
            Ensure                         = 'Present' 
        }

        $MockSETSwitch = [PSCustomObject] @{
            Name                           = 'SETSwitch'
            SwitchType                     = 'External'
            TeamingMode                    = 'SwitchIndependent'
            LoadBalancingAlgorithm         = 'Dynamic'
            NetAdapterName                 = @('SLOT 3','SLOT 3 2')
            NetAdapterInterfaceDescription = @('Ethernet Adapter 1','Ethernet Adapter 2')
            EnableIoV                      = $False
            EnablePacketDirect             = $False
            EmbeddedTeamingEnabled         = $True
            AllowManagementOS              = $True
            BandwidthReservationMode       = 'Weight' 
            Ensure                         = 'Present'
        }

        $TestSwitch = [PSObject]@{
            Name                = $MockNormalSwitch.Name
            Type                = $MockNormalSwitch.SwitchType
        }         

        $MockVMSwitchTeam = [PSObject]@{
            Name                               = $TestSwitch.Name
            Id                                 = 'af9b1772-db75-4722-8c3b-53c669fa5ce4'
            NetAdapterInterfaceDescription     = @('Ethernet Adapter 1','Ethernet Adapter 2')
            TeamingMode                        = 'SwitchIndependent'
            LoadBalancingAlgorithm             = 'Dynamic'
        }                

        $MockNetAdapter1 = [PSObject]@{
            Name                 = 'SLOT 3'
            InterfaceDescription = 'Ethernet Adapter 1'             
        }

        $MockNetAdapter2 = [PSObject]@{
            Name                 = 'SLOT 3 2'
            InterfaceDescription = 'Ethernet Adapter 2'             
        }        

        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
            #Function placeholders
            function Get-VMSwitch { }
            function Get-VMSwitchTeam { }
            function Get-NetAdapter {
                param (
                    $InterfaceDescription
                )                
            }

            Context 'VM Switch does not exist' {
                Mock Get-VMSwitch
                It 'should return ensure as absent' {
                    $Result = Get-TargetResource `
                        @TestSwitch
                    $Result.Ensure | Should Be 'Absent'
                }
                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                } 
            }

            Context 'Normal VM Switch Exists' {
                Mock -CommandName Get-VMSwitch -MockWith {
                    $MockNormalSwitch
                }

                Mock -CommandName Get-NetAdapter -MockWith {
                    $MockNetAdapter1
                } -ParameterFilter { $InterfaceDescription -eq $($MockNetAdapter1.InterfaceDescription) }

                It 'should return ensure as present' {
                    $Result = Get-TargetResource `
                        @TestSwitch
                    $Result.NetAdapterName | Should Be $MockNetAdapter1.Name
                    $Result.EmbeddedTeamingEnabled | Should Be $False
                    $Result.Ensure | Should Be 'Present'
                }

                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 1
                }                 
            }

            Context 'SET VM Switch Exists' {
                Mock -CommandName Get-VMSwitch -MockWith {
                    $MockSETSwitch
                }

                Mock -CommandName Get-VMSwitchTeam -MockWith {
                    $MockVMSwitchTeam
                }

                Mock -CommandName Get-NetAdapter -MockWith {
                    $MockNetAdapter1
                } -ParameterFilter { $InterfaceDescription -eq $($MockNetAdapter1.InterfaceDescription) }

                Mock -CommandName Get-NetAdapter -MockWith {
                    $MockNetAdapter2
                } -ParameterFilter { $InterfaceDescription -eq $($MockNetAdapter2.InterfaceDescription) }                

                It 'should return ensure as present' {
                    $Result = Get-TargetResource `
                        @TestSwitch
                    $Result.TeamingMode | Should Be 'SwitchIndependent'
                    $Result.EmbeddedTeamingEnabled | Should Be $True
                    $Result.NetAdapterName | Should Be @('SLOT 3','SLOT 3 2')
                    $Result.Ensure | Should Be 'Present'
                }

                It 'should call the expected mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                    Assert-MockCalled -commandName Get-VMSwitchTeam -Exactly 1
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 2
                }                 
            }            
        }

        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            #Function placeholders
            function Get-VMSwitch { }
            function Get-VMSwitchTeam { }
            function Set-VMSwitchTeam {
                param (
                    [psobject] $VMSwitch,
                    [String[]] $NetAdapterName,
                    [String] $TeamingMode,
                    [String] $LoadBalancingAlgorithm
                )
            }
            function Get-NetAdapter {
                param (
                    $InterfaceDescription
                )                
            }
            function New-VMSwitch { }
            function Remove-VMSwitch { }
            function Set-VMSwitch { }

            $newSwitch = [PSObject]@{
                Name                    = $MockNormalSwitch.Name
                Type                    = $MockNormalSwitch.SwitchType
                AllowManagementOS       = $True
                NetAdapterName          = 'SLOT 3'
                Ensure                  = 'Present'
            }
  
            Context 'VM Switch does not exist but should' {
                
                Mock Get-VMSwitch
                Mock New-VMSwitch
                Mock Remove-VMSwitch
    
                It 'should not throw error' {
                    { 
                        Set-TargetResource @newSwitch
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                    Assert-MockCalled -commandName New-VMSwitch -Exactly 1
                    Assert-MockCalled -commandName Remove-VMSwitch -Exactly 0
                }
            }

            Context 'VM Switch should exist and it does' {
                
                Mock -CommandName Get-VMSwitch -MockWith {
                    $MockNormalSwitch
                }
                Mock New-VMSwitch
                Mock Remove-VMSwitch
    
                It 'should not throw error' {
                    { 
                        Set-TargetResource @newSwitch
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                    Assert-MockCalled -commandName New-VMSwitch -Exactly 0
                    Assert-MockCalled -commandName Remove-VMSwitch -Exactly 0
                }
            }            

            Context 'VM Switch should not exist and it does not' {
                
                Mock Get-VMSwitch
                Mock New-VMSwitch
                Mock Remove-VMSwitch
                $cloneSwitch = $newSwitch.Clone()
                $cloneSwitch.Ensure = 'Absent'

                It 'should not throw error' {
                    { 
                        Set-TargetResource @cloneSwitch
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                    Assert-MockCalled -commandName New-VMSwitch -Exactly 0
                    Assert-MockCalled -commandName Remove-VMSwitch -Exactly 0
                }
            } 

            Context 'VM Switch should not exist and it does' {
                
                Mock -CommandName Get-VMSwitch -MockWith {
                    $MockNormalSwitch
                }
                Mock New-VMSwitch
                Mock Remove-VMSwitch
                $cloneSwitch = $newSwitch.Clone()
                $cloneSwitch.Ensure = 'Absent'

                It 'should not throw error' {
                    { 
                        Set-TargetResource @cloneSwitch
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                    Assert-MockCalled -commandName New-VMSwitch -Exactly 0
                    Assert-MockCalled -commandName Remove-VMSwitch -Exactly 1
                }
            }  

            Context 'VM Switch exists but need a SET Team' {
                
                Mock -CommandName Get-VMSwitch -MockWith {
                    $MockNormalSwitch
                }

                Mock New-VMSwitch
                Mock Remove-VMSwitch

                $cloneSwitch = $newSwitch.Clone()
                $cloneSwitch.NetAdapterName = @('SLOT 3','SLOT 3 2')
                $cloneSwitch.Ensure = 'Present'

                It 'should not throw error' {
                    { 
                        Set-TargetResource @cloneSwitch
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                    Assert-MockCalled -commandName New-VMSwitch -Exactly 1
                    Assert-MockCalled -commandName Remove-VMSwitch -Exactly 1
                }
            } 

            Context 'VM SET Switch exists but LoadBalancingAlgorithm should be HyperVPort' {
                
                Mock -CommandName Get-VMSwitch -MockWith {
                    $MockSETSwitch
                }

                Mock New-VMSwitch
                Mock Remove-VMSwitch
                Mock -CommandName Get-VMSwitchTeam -MockWith {
                    $MockVMSwitchTeam
                } 
                Mock Set-VMSwitchTeam 

                Mock -CommandName Get-NetAdapter -MockWith {
                    $MockNetAdapter1
                } -ParameterFilter { $InterfaceDescription -eq $($MockNetAdapter1.InterfaceDescription) }

                Mock -CommandName Get-NetAdapter -MockWith {
                    $MockNetAdapter2
                } -ParameterFilter { $InterfaceDescription -eq $($MockNetAdapter2.InterfaceDescription) }                          

                $cloneSwitch = $newSwitch.Clone()
                $cloneSwitch.NetAdapterName = @('SLOT 3','SLOT 3 2')
                $cloneSwitch.LoadBalancingAlgorithm = 'HyperVPort'
                $cloneSwitch.Ensure = 'Present'

                It 'should not throw error' {
                    { 
                        Set-TargetResource @cloneSwitch
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                    Assert-MockCalled -commandName New-VMSwitch -Exactly 0
                    Assert-MockCalled -commandName Remove-VMSwitch -Exactly 0
                    Assert-MockCalled -commandName Get-VMSwitchTeam -Exactly 1
                    Assert-MockCalled -commandName Set-VMSwitchTeam -Exactly 1
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 2
                }
            }   

            Context 'VM SET Switch exists but NetAdapters are different' {
                
                Mock -CommandName Get-VMSwitch -MockWith {
                    $MockSETSwitch
                }

                Mock New-VMSwitch
                Mock Remove-VMSwitch
                Mock -CommandName Get-VMSwitchTeam -MockWith {
                    $MockVMSwitchTeam
                } 
                Mock Set-VMSwitchTeam 

                Mock -CommandName Get-NetAdapter -MockWith {
                    $MockNetAdapter1
                } -ParameterFilter { $InterfaceDescription -eq $($MockNetAdapter1.InterfaceDescription) }

                Mock -CommandName Get-NetAdapter -MockWith {
                    $MockNetAdapter2
                } -ParameterFilter { $InterfaceDescription -eq $($MockNetAdapter2.InterfaceDescription) }                          

                $cloneSwitch = $newSwitch.Clone()
                $cloneSwitch.NetAdapterName = @('NIC1','NIC2')

                It 'should not throw error' {
                    { 
                        Set-TargetResource @cloneSwitch
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                    Assert-MockCalled -commandName New-VMSwitch -Exactly 0
                    Assert-MockCalled -commandName Remove-VMSwitch -Exactly 0
                    Assert-MockCalled -commandName Get-VMSwitchTeam -Exactly 1
                    Assert-MockCalled -commandName Set-VMSwitchTeam -Exactly 1
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 2
                }
            }

            Context 'VM SET Switch exists but it should be a normal switch' {
                
                Mock -CommandName Get-VMSwitch -MockWith {
                    $MockSETSwitch
                }

                Mock New-VMSwitch
                Mock Remove-VMSwitch 

                Mock -CommandName Get-NetAdapter -MockWith {
                    $MockNetAdapter1
                } -ParameterFilter { $InterfaceDescription -eq $($MockNetAdapter1.InterfaceDescription) }                      

                $cloneSwitch = $newSwitch.Clone()
                $cloneSwitch.NetAdapterName = 'SLOT 3'

                It 'should not throw error' {
                    { 
                        Set-TargetResource @cloneSwitch
                    } | Should Not Throw
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                    Assert-MockCalled -commandName New-VMSwitch -Exactly 1
                    Assert-MockCalled -commandName Remove-VMSwitch -Exactly 1
                }
            }                                                                      
        }  

        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            #Function placeholders
            function Get-VMSwitch { }
            function Get-VMSwitchTeam { }
            function Set-VMSwitchTeam {
                param (
                    [psobject] $VMSwitch,
                    [String[]] $NetAdapterName,
                    [String] $TeamingMode,
                    [String] $LoadBalancingAlgorithm
                )
            }
            function Get-NetAdapter {
                param (
                    $InterfaceDescription
                )                
            }

            $newSwitch = [PSObject]@{
                Name                    = $MockNormalSwitch.Name
                Type                    = $MockNormalSwitch.SwitchType
                AllowManagementOS       = $True
                NetAdapterName          = 'SLOT 3'
                Ensure                  = 'Present'
                MinimumBandwidthMode    = 'Absolute'
            }
  
            Context 'VM Switch does not exist but should. Should return False.' {                
                Mock Get-VMSwitch
    
                It 'should return False' {
                    Test-TargetResource @newSwitch | Should Be $False
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                }
            }

            Context 'VM Switch should exist and it does. Should return true.' {                
                Mock -CommandName Get-VMSwitch -MockWith {
                    $MockNormalSwitch
                }

                Mock -CommandName Get-NetAdapter -MockWith {
                    $MockNetAdapter1
                }   
                
                It 'should return True' {
                    Test-TargetResource @newSwitch | Should Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                }
            }            

            Context 'VM Switch should not exist and it does not. Should return True.' {                
                Mock Get-VMSwitch
                $cloneSwitch = $newSwitch.Clone()
                $cloneSwitch.Ensure = 'Absent'

                It 'should return True' {
                    Test-TargetResource @cloneSwitch | Should Be $True
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                }
            } 

            Context 'VM Switch should not exist and it does. Should return false.' {                
                Mock -CommandName Get-VMSwitch -MockWith {
                    $MockNormalSwitch
                }
                $cloneSwitch = $newSwitch.Clone()
                $cloneSwitch.Ensure = 'Absent'

                It 'should return false' {
                    Test-TargetResource @cloneSwitch | Should Be $false
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                }
            }  

            Context 'VM Switch exists but need a SET Team. Should return false.' {                
                Mock -CommandName Get-VMSwitch -MockWith {
                    $MockNormalSwitch
                }

                $cloneSwitch = $newSwitch.Clone()
                $cloneSwitch.NetAdapterName = @('SLOT 3','SLOT 3 2')
                $cloneSwitch.Ensure = 'Present'

                It 'should return false' {
                    Test-TargetResource @cloneSwitch | Should Be $false
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                }
            } 

            Context 'VM SET Switch exists but LoadBalancingAlgorithm should be HyperVPort. Should return false.' {                
                Mock -CommandName Get-VMSwitch -MockWith {
                    $MockSETSwitch
                }

                Mock -CommandName Get-VMSwitchTeam -MockWith {
                    $MockVMSwitchTeam
                } 

                Mock -CommandName Get-NetAdapter -MockWith {
                    $MockNetAdapter1
                } -ParameterFilter { $InterfaceDescription -eq $($MockNetAdapter1.InterfaceDescription) }

                Mock -CommandName Get-NetAdapter -MockWith {
                    $MockNetAdapter2
                } -ParameterFilter { $InterfaceDescription -eq $($MockNetAdapter2.InterfaceDescription) }                          

                $cloneSwitch = $newSwitch.Clone()
                $cloneSwitch.NetAdapterName = @('SLOT 3','SLOT 3 2')
                $cloneSwitch.LoadBalancingAlgorithm = 'HyperVPort'
                $cloneSwitch.Ensure = 'Present'

                It 'should return false' {
                    Test-TargetResource @cloneSwitch | Should Be $false
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                    Assert-MockCalled -commandName Get-VMSwitchTeam -Exactly 1
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 2
                }
            }   

            Context 'VM SET Switch exists but NetAdapters are different. Should return false.' {                
                Mock -CommandName Get-VMSwitch -MockWith {
                    $MockSETSwitch
                }

                Mock -CommandName Get-VMSwitchTeam -MockWith {
                    $MockVMSwitchTeam
                } 

                Mock -CommandName Get-NetAdapter -MockWith {
                    $MockNetAdapter1
                } -ParameterFilter { $InterfaceDescription -eq $($MockNetAdapter1.InterfaceDescription) }

                Mock -CommandName Get-NetAdapter -MockWith {
                    $MockNetAdapter2
                } -ParameterFilter { $InterfaceDescription -eq $($MockNetAdapter2.InterfaceDescription) }                          

                $cloneSwitch = $newSwitch.Clone()
                $cloneSwitch.NetAdapterName = @('NIC1','NIC2')

                It 'should return false' {
                    Test-TargetResource @cloneSwitch | Should Be $false
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                    Assert-MockCalled -commandName Get-VMSwitchTeam -Exactly 1
                    Assert-MockCalled -commandName Get-NetAdapter -Exactly 2
                }
            }

            Context 'VM SET Switch exists but it should be a normal switch. Should return false.' {                
                Mock -CommandName Get-VMSwitch -MockWith {
                    $MockSETSwitch
                }

                Mock -CommandName Get-NetAdapter -MockWith {
                    $MockNetAdapter1
                } -ParameterFilter { $InterfaceDescription -eq $($MockNetAdapter1.InterfaceDescription) }                      

                $cloneSwitch = $newSwitch.Clone()
                $cloneSwitch.NetAdapterName = 'SLOT 3'

                It 'should return $false' {
                    Test-TargetResource @cloneSwitch | Should Be $false
                }
                It 'should call expected Mocks' {
                    Assert-MockCalled -commandName Get-VMSwitch -Exactly 1
                }
            }                                                                      
        }                
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
