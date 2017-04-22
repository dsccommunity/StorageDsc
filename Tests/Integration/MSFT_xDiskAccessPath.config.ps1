configuration MSFT_xDiskAccessPath_Config {

    Import-DscResource -ModuleName xStorage

    node localhost {
        if ($Node.Size)
        {
            xDiskAccessPath Integration_Test {
                DiskId             = $Node.DiskId
                DiskIdType         = $Node.DiskIdType
                AccessPath         = $Node.AccessPath
                FSLabel            = $Node.FSLabel
                Size               = $Node.Size
            }
        }
        else
        {
            xDiskAccessPath Integration_Test {
                DiskId             = $Node.DiskId
                DiskIdType         = $Node.DiskIdType
                AccessPath         = $Node.AccessPath
                FSLabel            = $Node.FSLabel
            }
        }
    }
}
