<#
.Synopsis
   Unit tests for xDisk
.DESCRIPTION
   Unit tests for xDisk

.NOTES
   Code in HEADER and FOOTER regions are standard and may be moved into DSCResource.Tools in
   Future and therefore should not be altered if possible.
#>

$Global:DSCModuleName      = 'xDisk' # Example xNetworking
$Global:DSCResourceName    = 'MSFT_xDisk' # Example MSFT_xFirewall

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit 
#endregion


# Begin Testing
try
{

    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $Global:DSCResourceName {

        #region Pester Test Initialization
        $global:mockedDisk0 = [pscustomobject] @{
                Number = 0
                DiskNumber = 0
                IsOffline = $false
                IsReadOnly = $false
                PartitionStyle = 'GPT'
            }
        $global:mockedDisk0Raw = [pscustomobject] @{
                Number = 0
                DiskNumber = 0
                IsOffline = $false
                IsReadOnly = $false
                PartitionStyle = 'Raw'
            }
        $global:mockedWmi = [pscustomobject] @{BlockSize=4096}
        $Global:mockedPartition = [pscustomobject] @{
                    DriveLetter='F'
                    Size=123
                }
        $global:mockedVolume = [pscustomobject] @{
                    FileSystemLabel='myLabel'
                    DriveLetter='F'
                }
        #endregion


        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
            # verifiable (should be called) mocks 
            Mock Get-WmiObject -mockwith {return $global:mockedWmi} -verifiable
            Mock Get-Disk -mockwith {return $global:mockedDisk0} -verifiable
            Mock Get-Partition -mockwith {return $Global:mockedPartition} -verifiable
            Mock Get-Volume -mockwith {return $global:mockedVolume} -verifiable
            
            $resource = Get-TargetResource -DiskNumber 0 -DriveLetter 'G' -verbose
            it "DiskNumber should be 0" {
                $resource.DiskNumber | should be 0
            } 

            it "DriveLetter should be F" {
                $resource.DriveLetter | should be 'F'
            }

            it "Size should be 123" {
                $resource.Size | should be 123
            }

            it "FSLabel should be myLabel" {
                $resource.FSLabel | should be 'myLabel'
            }

            it "AllocationUnitSize should be 4096" {
                $resource.AllocationUnitSize | should be 4096
            }

            it "all the get mocks should be called" {
                Assert-VerifiableMocks
            }
            
        }
        #endregion


        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            context 'Test matching AllocationUnitSize' {
                # verifiable (should be called) mocks 
                Mock Get-WmiObject -mockwith {return $global:mockedWmi} -verifiable
                Mock Get-Disk -mockwith {return $global:mockedDisk0} -verifiable
                Mock Get-Partition -mockwith {return $Global:mockedPartition} -verifiable               

                # mocks that should not be called
                Mock Get-Volume -mockwith {return $global:mockedVolume} 
                
                $script:result = $null
                
                it 'calling test should not throw' {
                    {$script:result = Test-TargetResource -DiskNumber 0 -DriveLetter 'F' -AllocationUnitSize 4096 -verbose} | should not throw
                }

                it "result should be true" {
                    $script:result | should be $true
                } 

                it "the correct mocks were called" {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                }
            }
            context 'Test mismatched AllocationUnitSize' {
                # verifiable (should be called) mocks 
                Mock Get-WmiObject -mockwith {return $global:mockedWmi} -verifiable
                Mock Get-Disk -mockwith {return $global:mockedDisk0} -verifiable
                Mock Get-Partition -mockwith {return $Global:mockedPartition} -verifiable

                # mocks that should not be called
                Mock Get-Volume -mockwith {return $global:mockedVolume} 
                
                $script:result = $null
                
                it 'calling test should not throw' {
                    {$script:result = Test-TargetResource -DiskNumber 0 -DriveLetter 'F' -AllocationUnitSize 4097 -verbose} | should not throw
                }

                # skipped due to:  https://github.com/PowerShell/xStorage/issues/22
                it "result should be true" -skip {
                    $script:result | should be $false
                } 

                it "the correct mocks were called" {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                }
            }
        }
        #endregion


        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            context 'Online Formatted disk' {
                # verifiable (should be called) mocks 
                Mock Format-Volume -mockwith {} 
                Mock Get-Disk -mockwith {return $global:mockedDisk0Raw} -verifiable
                Mock Initialize-Disk -mockwith {} -verifiable
                Mock New-Partition -mockwith {return [pscustomobject] @{DriveLetter='Z'}}
                Mock Set-Partition -MockWith {} 
                
                # mocks that should not be called
                Mock Get-WmiObject -mockwith {return $global:mockedWmi}
                Mock Get-Partition -mockwith {return $Global:mockedPartition}  -verifiable
                Mock Get-Volume -mockwith {return $global:mockedVolume} -verifiable
                Mock Set-Disk -mockwith {}

                
                it 'Should not throw' {
                    {Set-targetResource -diskNumber 0 -driveletter G -verbose} | should not throw
                }

                it "the correct mocks were called" {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Set-Partition -Times 1 -ParameterFilter { $DriveLetter -eq 'F' -and $NewDriveLetter -eq 'G' }
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 2
                    Assert-MockCalled -CommandName Get-Partition -Times 2
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Get-WmiObject -Times 0
                    Assert-MockCalled -CommandName New-Partition -Times 0
                }
            }
            context 'Online Unformatted disk' { 
                 # verifiable (should be called) mocks  
                 Mock Format-Volume -mockwith {}  
                 Mock Get-Disk -mockwith {return $global:mockedDisk0Raw} -verifiable 
                 Mock Initialize-Disk -mockwith {} -verifiable 
                 Mock New-Partition -mockwith {return [pscustomobject] @{DriveLetter='Z'}} 
                 Mock Get-Volume -mockwith {} -verifiable 
                 
                 # mocks that should not be called 
                 Mock Get-WmiObject -mockwith {return $global:mockedWmi} 
                 Mock Get-Partition -mockwith {return $Global:mockedPartition}  -verifiable 
                 Mock Set-Disk -mockwith {} 
                 Mock Set-Partition -MockWith {}  
 
                  
                 it 'Should not throw' { 
                     {Set-targetResource -diskNumber 0 -driveletter G -verbose} | should not throw 
                 } 
 
                  it "the correct mocks were called" { 
                     Assert-VerifiableMocks
                     Assert-MockCalled -CommandName New-Partition -Times 1  
                     Assert-MockCalled -CommandName Format-Volume -Times 1                     
                     Assert-MockCalled -CommandName Set-Partition -Times 0
                     Assert-MockCalled -CommandName Set-Disk -Times 0 
                     Assert-MockCalled -CommandName Get-WmiObject -Times 0 
                     Assert-MockCalled -CommandName Initialize-Disk -Times 1
                     Assert-MockCalled -CommandName Get-Disk -Times 1
                 } 
            }
            # TODO: Complete Tests...
        }
        #endregion
        }
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion

}
