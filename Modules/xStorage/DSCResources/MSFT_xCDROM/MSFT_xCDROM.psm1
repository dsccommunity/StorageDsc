
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
    try {
        $currentDriveLetter = (Get-CimInstance -ClassName win32_cdromdrive | Where-Object {
                                    $_.Caption -eq "Microsoft Virtual DVD-ROM"
                                    }
                               ).Drive
    }
    catch
    {
        Write-Verbose "Without a cdrom drive in the system, this resource has nothing to do."
        $Ensure = 'Present'
    }

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
    # the Caption and DeviceID properties are used to avoid mounted ISO images
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
    
    if ($currentDriveLetter -eq $DriveLetter) { 
        return 
    }

    Write-Verbose "The current drive letter is $currentDriveLetter, attempting to set to $driveletter"

    # assuming a drive letter is found
    if ($currentDriveLetter)
    {
        # get the volume corresponding to the drive letter, and set the drive letter of this volume to $DriveLetter
        if ($PSCmdlet.ShouldProcess("Setting cdrom drive letter to $DriveLetter")) {
            Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$currentDriveLetter'" | 
            Set-CimInstance -Property @{ DriveLetter="$DriveLetter"}
        }
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
    $cdrom = Get-CimInstance -ClassName WIn32_cdromdrive -Property Id
    # what type of drive is attached to $driveletter
    $volumeDriveType = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$DriveLetter'" -Property DriveType
    
    if ($Ensure -eq 'Present')
    {
        # check there is a cdrom
        if ($cdrom)
        {
            Write-Verbose ("cdrom found with device id: " + $cdrom.id)
            if ($volumeDriveType) {
                Write-Verbose ("volume with driveletter $driveletter is type " + $volumeDriveType.DriveType + " (5 is a cdrom drive).")
            }
            else {
                Write-Verbose ("there doesn't appear to be a driveletter $driveletter")
            }            
            # return true if the requested volume is a cdrom
            $result = [System.Boolean]($volumeDriveType.DriveType -eq 5)
        }
        else { 
            # return true if there is no cdrom - can't set what isn't there!
            Write-Verbose ("No cdrom found.")
            $result = $true 
        }
    }
    # $Ensure -eq 'Absent', do nothing
    else { 
        Write-Verbose 'When $Ensure is set to Absent this resource does nothing.'
        $result = $true 
    }
          
    $result

}


Export-ModuleMember -Function *-TargetResource

