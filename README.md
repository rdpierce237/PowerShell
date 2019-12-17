# PowerShell
PowerShell scripts
Sript to export Network Security Groups including application security groups

Command arguments include:
AZEnvironment - Specify the Azure login environment.  AzureUSGovernment is the default
resourceGroup - Specify the resource group for the NSG's.  Script can be modified to change the default which is set to 
                 AA01_RG_DAL_A_NETWORK, which is our resource group
exportPath - Specify the path for exported files.  By default, it will use the active directory from which the command was executed
nsgList - Specify a comma separated list of NSG's to export.  By default, the script will enumerate NSG's matching a naming schema.
          Modify the naming schema to match your NSG naming convention (working on this - 12/17/19)
          

By default, this script will backup all NSG's matching the default naming criteria to the execution directory as CSV files.  If a
backup file already exists, it will rename the existing file by appending the creation date to the end of the filename, formatted
MM-dd-yyyy (eg. backup_file.csv becomes backup_file_12-17-19.CSV)
          
