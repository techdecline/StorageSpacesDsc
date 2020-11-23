[DscResource()]
class Partition {
    [DscProperty(Key)]
    [string] $VirtualDiskName

    [DscProperty(Mandatory)]
    [string]$DriveLetter

    [DscProperty(NotConfigurable)]
    [int64]$DiskNumber

    [DscProperty(NotConfigurable)]
    [int64]$PartitionNumber

    [DscProperty(NotConfigurable)]
    [bool]$IsPresent

    # Gets the resource's current state.
    [Partition] Get() {
        $ErrorActionPreference = 'Stop'
        try {
            $partitionObj = Get-Partition -DiskPath (Get-Disk -FriendlyName $this.VirtualDiskName).path | Where-Object {$this.DriveLetter -eq $_.DriveLetter}
        }
        catch {
            throw "Could not get disk properties"
        }
        if (!$partitionObj) {
            Write-Verbose "No Partition found"
            $this.PartitionNumber = $null
            $this.DiskNumber = $null
            $this.IsPresent = $false
        }
        else {
            $this.IsPresent = $true
            $this.PartitionNumber = $partitionObj.PartitionNumber
            $this.DiskNumber = $partitionObj.DiskNumber
        }
        return $this
    }
    
    # Sets the desired state of the resource.
    [void] Set() {
        $ErrorActionPreference = 'Stop'
        try {
            $diskObject = Get-Disk -FriendlyName $this.VirtualDiskName
            $diskObject | New-Partition -UseMaximumSize -DriveLetter $this.DriveLetter
        }
        catch [System.Management.Automation.ActionPreferenceStopException] {
            throw "Could not create Partition: $($error[0].exception.message)"
        }
    }
    
    # Tests if the resource is in the desired state.
    [bool] Test() {
        $ErrorActionPreference = 'Stop'
        $resultObj = $this.Get()
        if ($resultObj.IsPresent) {
            return $true
        }
        else {
            return $false
        }
    }
}