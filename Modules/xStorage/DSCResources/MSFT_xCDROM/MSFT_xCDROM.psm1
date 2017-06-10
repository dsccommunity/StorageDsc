
<#
    .SYNOPSIS
    Returns the current drive letter assigned to the CDROM.

    .PARAMETER DriveLetter
    Specifies the preferred letter to assign to the CDROM.

#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        # specify the drive letter as a single letter, optionally include the colon
        [parameter(Mandatory = $true)]
        [System.String]
        $DriveLetter
    )

    # allow use of drive letter without colon
    $DriveLetter = $DriveLetter[0] + ":"

    Write-Verbose "Using Get-CimInstance to get the cdrom drives in the system"

    # Get the current drive letter corresponding to the virtual cdrom drive
    # the Caption and DeviceID properties are used to avoid mounted ISO images in Windows 2012+ and Windows 10.
    # with the Device ID, we look for the length of the string after the final backslash (crude, but appears to work so far)

    # Example DeviceID for a virtual drive in a Hyper-V VM - SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\000006
    # Example DeviceID for a mounted ISO   in a Hyper-V VM - SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\2&1F4ADFFE&0&000002
    $currentDriveLetter = (Get-CimInstance -ClassName win32_cdromdrive | Where-Object {
                        -not (
                                $_.Caption -eq "Microsoft Virtual DVD-ROM" -and
                                ($_.DeviceID.Split("\")[-1]).Length -gt 10
                            )
                        }
                        ).Drive
    
    if (-not $currentDriveLetter)
    {
        Write-Verbose "Without a cdrom drive in the system, this resource has nothing to do."
        $Ensure = 'Present'
    }
    else {
        # check if $driveletter is the location of the CD drive
        if ($currentDriveLetter -eq $DriveLetter)
        {
            Write-Verbose "cdrom is currently set to $DriveLetter as requested"
            $Ensure = 'Present'
        }
        else
        {
            Write-Verbose "cdrom is currently set to $currentDriveLetter, not $DriveLetter as requested"
            $Ensure = 'Absent'
        }       
    }

    $returnValue = @{
    DriveLetter = $currentDriveLetter
    Ensure = $Ensure
    }

    $returnValue

} # Get-TargetResource


<#
    .SYNOPSIS
    Sets the drive letter of the CDROM.

    .PARAMETER DriveLetter
    Specifies the drive letter to assign to the CDROM.

    .PARAMETER Ensure
    Determines whether the setting should be applied or removed.
#>
function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$True,
                   ConfirmImpact="Low")]
    param
    (
        # specify the drive letter as a single letter, optionally include the colon
        [parameter(Mandatory = $true)]
        [System.String]
        $DriveLetter,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    # allow use of drive letter without colon
    $DriveLetter = $DriveLetter[0] + ":"

    # Get the current drive letter corresponding to the virtual cdrom drive
    # the Caption and DeviceID properties are used to avoid mounted ISO images in Windows 2012+ and Windows 10.
    # with the Device ID, we look for the length of the string after the final backslash (crude, but appears to work so far)

    # Example DeviceID for a virtual drive in a Hyper-V VM - SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\000006
    # Example DeviceID for a mounted ISO   in a Hyper-V VM - SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\2&1F4ADFFE&0&000002
    $currentDriveLetter = (Get-CimInstance -ClassName win32_cdromdrive | Where-Object {
                        -not (
                                $_.Caption -eq "Microsoft Virtual DVD-ROM" -and
                                ($_.DeviceID.Split("\")[-1]).Length -gt 10
                             )
                        }
                   ).Drive
    
    if ($currentDriveLetter -eq $DriveLetter -and $Ensure -eq 'Present') { 
        return 
    }

    # assuming a drive letter is found
    if ($currentDriveLetter)
    {
        Write-Verbose "The current drive letter is $currentDriveLetter, attempting to set to $driveletter"

        if ($PSCmdlet.ShouldProcess("Setting cdrom drive letter to $DriveLetter")) {

            # if $Ensure -eq Absent this will remove the drive letter from the cdrom
            if ($Ensure -eq 'Absent')
            {
                $DriveLetter = $null
            }
            Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$currentDriveLetter'" | 
            Set-CimInstance -Property @{ DriveLetter=$DriveLetter}
        }
    }
    else {
        Write-Verbose "No CDROM can be found.  Note that this resource does not change the drive letter of mounted ISOs "
    }
} # Set-TargetResource


<#
    .SYNOPSIS
    Tests the CDROM drive letter is set as expected

    .PARAMETER DriveLetter
    Specifies the drive letter to test if it is assigned to the CDROM.

    .PARAMETER Ensure
    Determines whether the setting should be applied or removed.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        # specify the drive letter as a single letter, optionally include the colon
        [parameter(Mandatory = $true)]
        [System.String]
        $DriveLetter,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    # allow use of drive letter without colon
    $DriveLetter = $DriveLetter[0] + ":"

    # is there a cdrom
    $cdrom = Get-CimInstance -ClassName Win32_cdromdrive -Property Id
    # what type of drive is attached to $driveletter
    $volumeDriveType = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$DriveLetter'" -Property DriveType
    
    # check there is a cdrom
    if ($cdrom)
    {
        Write-Verbose ("cdrom found with device id: " + $cdrom.id)
        if ($volumeDriveType) {
            Write-Verbose ("volume with driveletter $driveletter is type " + $volumeDriveType.DriveType + " (5 is a cdrom drive).")
        }
        else {
            Write-Warning ("volume with driveletter $driveletter is already present but is not a cdrom drive")
        }
        
        # return true if the drive letter is a cdrom resource
        $result = [System.Boolean]($volumeDriveType.DriveType -eq 5)
        
        # return false if the drive letter specified is a cdrom resource & $Ensure -eq 'Absent'
        if ($Ensure -eq 'Absent')
        {
            $result = -not $result
        }
    }
    else { 
        # return true if there is no cdrom - can't set what isn't there!
        Write-Warning ("There is no cdrom in this system, so no drive letter can be set.")
        $result = $false 
    }
          
    $result

}


Export-ModuleMember -Function *-TargetResource

