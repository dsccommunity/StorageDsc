configuration MSFT_DiskAccessPath_Config {

    Import-DscResource -ModuleName StorageDsc

    node localhost {
        if ($Node.Size)
        {
            DiskAccessPath Integration_Test {
                DiskId             = $Node.DiskId
                DiskIdType         = $Node.DiskIdType
                AccessPath         = $Node.AccessPath
                FSLabel            = $Node.FSLabel
                Size               = $Node.Size
            }
        }
        else
        {
            DiskAccessPath Integration_Test {
                DiskId             = $Node.DiskId
                DiskIdType         = $Node.DiskIdType
                AccessPath         = $Node.AccessPath
                FSLabel            = $Node.FSLabel
            }
        }
    }
}
