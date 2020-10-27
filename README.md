Clean Azure VM Deletion
=======================

            

Normally using default PS script the VM deletion is not a clean deletion as that not delete many resources for example O/S disk, data disk & NIC card. This script provide an way to do a clean deletion.


Example1




 If the need is to delete multiple VM,


 Log,

 VERBOSE: Removing VM scxazsit102 in Resource Group sqlchow-dev-backend           

 VERBOSE: Performing the operation 'Remove' on target 'scxazsit102'.
            
 OperationId :           

 Status      : Succeeded           

 StartTime   : 5/31/2017 11:42:11 AM           

 EndTime     : 5/31/2017 11:42:21 AM           

 Error       :           

 Name        :
            
Removing osDisk https://sqlchowvmdiskstor001.blob.core.windows.net/vhds/scxazsit102os.vhd           

VERBOSE: Performing the operation 'Remove blob' on target 'scxazsit102os.vhd'.           

VERBOSE: Removed blob 'scxazsit102os.vhd' in container 'vhds' successfully.           

VERBOSE: Removing dataDisk scxazsit102dd01.vhd           

VERBOSE: Performing the operation 'Remove blob' on target 'scxazsit102dd01.vhd'.           

VERBOSE: Removed blob 'scxazsit102dd01.vhd' in container 'vhds' successfully.           

VERBOSE: Removing dataDisk scxazsit102dd02.vhd           

VERBOSE: Performing the operation 'Remove blob' on target 'scxazsit102dd02.vhd'.           

VERBOSE: Removed blob 'scxazsit102dd02.vhd' in container 'vhds' successfully.           
VERBOSE: Removing NIC scxazsit102nic01           

VERBOSE: Performing the operation 'Removing resource ...' on target 'scxazsit102nic01'.


 


 


        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
