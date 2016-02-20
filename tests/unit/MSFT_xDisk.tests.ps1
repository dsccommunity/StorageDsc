<#
.Synopsis
   Unit tests for xDisk
.DESCRIPTION
   Unit tests for xDisk

.NOTES
   Code in HEADER and FOOTER regions are standard and may be moved into DSCResource.Tools in
   Future and therefore should not be altered if possible.
#>


# TODO: Customize these parameters...
$Global:DSCModuleName      = 'xDisk' # Example xNetworking
$Global:DSCResourceName    = 'MSFT_xDisk' # Example MSFT_xFirewall
# /TODO

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

# TODO: Other Optional Init Code Goes Here...

# Begin Testing
try
{

    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $Global:DSCResourceName {

        #region Pester Test Initialization
        # TODO: Optopnal Load Mock for use in Pester tests here...
        #endregion


        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
            Mock Get-WmiObject -mockwith {return [pscustomobject] @{BlockSize=4096}} -verifiable
            Mock Get-Disk -mockwith {@{Number=0}} -verifiable
            Mock Get-Partition -mockwith {
                return [pscustomobject] @{
                    DriveLetter='F'
                    Size=123
                }
            } -verifiable
            
            Mock Get-Volume -mockwith {
                return [pscustomobject] @{
                    FileSystemLabel='myLabel'
                }
            } -verifiable
            
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
            Mock Get-WmiObject -mockwith {return [pscustomobject] @{BlockSize=4096}} -verifiable
            Mock Get-Disk -mockwith {@{
                Number=0
                IsOffline = $false
                IsReadOnly = $false
                PartitionStyle = 'GPT'
            }} -verifiable
            Mock Get-Partition -mockwith {
                return [pscustomobject] @{
                    DriveLetter='F'
                    Size=123
                }
            } -verifiable
            
            Mock Get-Volume -mockwith {
                return [pscustomobject] @{
                    FileSystemLabel='myLabel'
                }
            } 
            
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
        #endregion


        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            # TODO: Complete Tests...
        }
        #endregion

        # TODO: Pester Tests for any Helper Cmdlets

    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion

    # TODO: Other Optional Cleanup Code Goes Here...
}
