#Requires -Modules @{ModuleName="AzureRM.Network";ModuleVersion="1.0.5"}
#==================================================================================
<# 
    .SYNOPSIS 
        This script removes the compute, storage, network and associated resources to cleanly delete a VM.
 
    .DESCRIPTION 
        This script removes the compute, storage, network and associated resources to cleanly delete a VM.

        This is very useful when the resources are deployed across multiple resource groups.

    .PARAMETER SubscriptionID
        Let's you work on a specific azure subscription.

    .PARAMETER ResourceGroupName
        The resource group where the VM is deployed. Resource groups for other related resources
        will be retrieved automatically. 

    .PARAMETER VMName 
        Name of the VM that needs to be deleted.

    .EXAMPLE 
         Delete-AzureRmVM -SubscriptionID 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' `
                          -ResourceGroup  'sqlchow-dev-backend' `
                          -VMName 'scxazsit102'

            VERBOSE: Removing VM scxazsit102 in Resource Group sqlchow-dev-backend
            VERBOSE: Performing the operation "Remove" on target "scxazsit102".

            OperationId :
            Status      : Succeeded
            StartTime   : 5/31/2017 11:42:11 AM
            EndTime     : 5/31/2017 11:42:21 AM
            Error       :
            Name        :

            Removing osDisk https://sqlchowvmdiskstor001.blob.core.windows.net/vhds/scxazsit102os.vhd
            VERBOSE: Performing the operation "Remove blob" on target "scxazsit102os.vhd".
            VERBOSE: Removed blob 'scxazsit102os.vhd' in container 'vhds' successfully.
            VERBOSE: Removing dataDisk scxazsit102dd01.vhd
            VERBOSE: Performing the operation "Remove blob" on target "scxazsit102dd01.vhd".
            VERBOSE: Removed blob 'scxazsit102dd01.vhd' in container 'vhds' successfully.
            VERBOSE: Removing dataDisk scxazsit102dd02.vhd
            VERBOSE: Performing the operation "Remove blob" on target "scxazsit102dd02.vhd".
            VERBOSE: Removed blob 'scxazsit102dd02.vhd' in container 'vhds' successfully.
            VERBOSE: Removing NIC scxazsit102nic01
            VERBOSE: Performing the operation "Removing resource ..." on target "scxazsit102nic01".
    .INPUTS 
        System.String
        System.String
        System.String

    .OUTPUTS 
        Human-readable informational and error messages produced during the execution. 
        Not intended to be consumed by another script. 

    .NOTES
        The script expects that you have loaded Azure PowerShell modules and ran Login-AzureRMAccount
        Author: hemanth.damecharla@accenture.com
        Initial Version: 23/12/2016
        Last revised: 20/05/2017
#>
function Delete-AzureRmVmWithAllAssociatedObjects {
    
     [Cmdletbinding()]
     param(
            # The subscription on which to work
                [Parameter(Mandatory=$true,
                           Position=0)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $SubscriptionID,
            # The Name of the resource group where the VM is deployed
                [Parameter(Mandatory=$true,
                           Position=1)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $ResourceGroupName,
            # The Name of the VM which needs to be deleted
                [Parameter(Mandatory=$true,
                           Position=2)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $VMName
    )

    $CurrentVerbosePreference=$VerbosePreference
    $VerbosePreference = 'Continue'

    try {
            Set-AzureRmContext -SubscriptionId $SubscriptionID
            #get all resources to remove
            $vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName
            $osDisk = $vm.StorageProfile.OSDisk.Vhd.Uri
            $dataDisks = $vm.StorageProfile.DataDisks

            $nic = $vm.NetworkProfile.NetworkInterfaces
            $nicString = ([uri]$nic.Id).OriginalString
            $nicName = $nicString.Split("/")[-1]
            $nicObject = Get-AzureRmNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $nicName

            #remove VM
            Write-Verbose -Message "Removing VM $($vm.Name) in Resource Group $($vm.ResourceGroupName)"
            Remove-AzureRmVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Force -Verbose

            #remove osdisk
            Write-Host "Removing osDisk $osDisk"

            $osDiskSourceStorageAccount = ([System.Uri]$osDisk).Host.Split('.')[0]
            $osDiskSourceContainer = ([System.Uri]$osDisk).Segments[-2] -replace '/'
            $osDiskBlob = ([System.Uri]$osDisk).Segments[-1]
            $osDiskResourceGroup = Get-AzureRmResourceGroup | `
                                   Get-AzureRmStorageAccount -Name $osDiskSourceStorageAccount `
                                                             -ErrorAction SilentlyContinue | `
                                                              Select-Object -ExpandProperty ResourceGroupName

            $osDiskStorageKey = Get-AzureRmStorageAccountKey -ResourceGroupName $osDiskResourceGroup `
                                                             -Name $osDiskSourceStorageAccount
            $osDiskContext = New-AzureStorageContext -StorageAccountName $osDiskSourceStorageAccount `
                                                     -StorageAccountKey $osDiskStorageKey[0].Value

            Remove-AzureStorageBlob -Blob $osDiskBlob -Container $osDiskSourceContainer `
            -Context $osDiskContext -Verbose

            #remove datadisks
            foreach ($dataDisk in $dataDisks) {
                        $dataDiskUri = $dataDisk.Vhd.Uri
                        $dataDiskSourceStorageAccount = ([System.Uri]$dataDiskUri).Host.Split('.')[0]
                        $dataDiskSourceContainer = ([System.Uri]$dataDiskUri).Segments[-2] -replace '/'
                        $dataDiskBlob = ([System.Uri]$dataDiskUri).Segments[-1]
                        $dataDiskResourceGroup = Get-AzureRmResourceGroup | `
                                                 Get-AzureRmStorageAccount -Name $dataDiskSourceStorageAccount `
                                                                           -ErrorAction SilentlyContinue | `
                                                                            Select-Object -ExpandProperty ResourceGroupName

                        $dataDiskStorageKey = Get-AzureRmStorageAccountKey -ResourceGroupName $dataDiskResourceGroup `
                                                                           -Name $dataDiskSourceStorageAccount
                        $dataDiskContext = New-AzureStorageContext -StorageAccountName $dataDiskSourceStorageAccount `
                                                                   -StorageAccountKey $dataDiskStorageKey[0].Value
        
                        Write-Verbose "Removing dataDisk $dataDiskBlob"
                        Remove-AzureStorageBlob -Blob $dataDiskBlob -Container $dataDiskSourceContainer `
                                                -Context $dataDiskContext -Verbose
      }

        #remove nic
        Write-Verbose "Removing NIC $nicName"
        $nicResourceGroup = $(Get-AzureRmResource `
                                  -ResourceId $vm.NetworkProfile.NetworkInterfaces.Id).ResourceGroupName
        Remove-AzureRmNetworkInterface -ResourceGroupName $nicResourceGroup -Name $nicName -Force -Verbose
    }
    catch {
            $errorMessage = $_.Exception.Message 
            throw "Unexpected exception: $errorMessage" 
            $VerbosePreference = $CurrentVerbosePreference
     }
}