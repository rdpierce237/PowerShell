Param 
    (
    [string]$AZEnvironment,
    [string]$resourceGroup,
    [string]$exportPath,
    [string]$nsgInput
    )

#Initial format of variables
$NSGNAME = ""
$MYARRAY = @()
$NSGTEMP = @()
$nsgSchema = "dal-p*"

#Clear the screen
clear-host

#Set output path to current directory if not specified as an execution argument
if ([string]::IsNullOrEmpty($exportPath)) 
   {
   $exportPath = Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
   }
else
   {
   #Validate existance and syntax for output path
   if (-NOT (test-path -Path $exportPath -IsValid))
      {
      write-host "The output path specified is invalid.  Aborting."
      Start-Sleep -Seconds 1.5
      exit
      }
   elseif (-NOT (test-path -Path $exportPath))
      {
      write-host "The output path specified does not exist.  Aborting."
      Start-Sleep -Seconds 1.5
      exit
      }
   }
write-host "Export files will be saved to the directory: " $exportPath
Start-Sleep -Seconds 1.5


#Set resource group to default if not specified as an execution argument
if ([string]::IsNullOrEmpty($AZEnvironment)) 
   {
   $AZEnvironment = "AzureUSGovernment"
   }
#Set resource group to default if not specified as an execution argument
if ([string]::IsNullOrEmpty($resourceGroup)) 
   {
   $resourceGroup = "AA01_RG_DAL_A_NETWORK"
   }

#Pull in all production NSG's if no name is specified
if ([string]::IsNullOrEmpty($nsgInput)) 
   {
   $nsgList = Get-AzNetworkSecurityGroup -Name $nsgSchema
   }
else 
   {
   $ARRAYTMP = @()
   $nsgList = @()
   $NSGTEMP = ""
   write-host "Enumerating elements for: " $nsgInput
   foreach ($NSGITEM in $nsgInput.split(" ")) 
      {
      Write-host "Retrieving NSG elements for: " $NSGITEM
      $NSGTEMP = Get-AzNetworkSecurityGroup -Name $NSGITEM
      $nsgList += $NSGTEMP
      }
   }



# Check to see if user is logged into Azure and present login if they're not
if ([string]::IsNullOrEmpty($(Get-AzContext).Account)) 
   {
   write-host "User not logged in.  Directing to Azure login."
   Start-Sleep -Seconds 1.5
   Connect-AzAccount -Environment $AZEnvironment
   }

# Get current date for file formatting
#$DATE = Get-Date -Format "MM/dd/yyyy"
#$DATE


foreach ($NSGNAME in $nsgList) 
{
   # Initialize loop variables
   $MYARRAY = @()
   $BACKUPDATE = ""
   $BACKUPNAME = ""
   write-host "`n`nWriting to file: " $exportPath\$($NSGNAME.Name)".csv"


   #Check if the output file already exists, and if it does, move it to <file>_<creation date>.csv
   if ([System.IO.File]::Exists("$exportPath\$($NSGNAME.Name).csv")) 
   {
      Write-Host "Export file already exists.  Renaming to backup file."

      $BACKUPDATE = Get-ChildItem "$exportPath\$($NSGNAME.name).csv" | Select-Object -ExpandProperty CreationTime | Get-Date -Format "MM-dd-yyyy"
      $BACKUPNAME = "$exportPath\$($NSGNAME.Name)_$BACKUPDATE.csv"

      if (-NOT [System.IO.File]::Exists("$BACKUPNAME")) 
      {
         Write-Host "Creating backup of existing export file."
         [System.IO.File]::Move("$exportPath\$($NSGNAME.name).csv", $BACKUPNAME)
      }
      else 
      {
         write-host "Backup of existing export already exists.  Skipping file backup creation."
      }
   }



   #Create output file for writing 
   Write-Host 'Creating CSV file for: ' $NSGNAME.name
   New-Item -ItemType file -Path "$exportPath\$($NSGNAME.name).csv" -Force | Out-Null

   #Retrieve NSGs associated rules and export them to the CSV file
   Write-Host "Processing rules for "$NSGNAME.Name "==================="
   $nsgRules = $NSGNAME.SecurityRules

   foreach ($NSGRULE in $nsgRules) 
   {
      $MYSRCASG = ""
      $MYSRCIP = ""
      $MYDSTASG = ""
      $MYDSTIP = ""
      $MYSRCPORT = ""
      $MYDSTPORT = ""


      if ([string]::IsNullOrWhitespace($NSGRULE.SourceAddressPrefix)) 
      {
         $MYSRCASG = ($NSGRULE.SourceApplicationSecurityGroups.Id).Split("/")[-1] 
         $MYSRCIP = ""
      }
      else 
      { 
         $MYSRCIP = ([string]::join(“;”, ($NSGRULE.SourceAddressPrefix)))
      }

      if ([string]::IsNullOrWhitespace($NSGRULE.DestinationAddressPrefix)) 
      {
         $MYDSTASG = ($NSGRULE.DestinationApplicationSecurityGroups.Id).Split("/")[-1] 
      }
      else 
      {
         $MYDSTIP = ([string]::join(“;”, ($NSGRULE.DestinationAddressPrefix)))
      }

      $MYSRCPORT = ([string]::join(";", ($NSGRULE.SourcePortRange)))
      $MYDSTPORT = ([string]::join(";", ($NSGRULE.DestinationPortRange)))


      $MYOBJ = new-object psobject
      $MYOBJ | Add-Member -type NoteProperty -name ruleName            -Value $NSGRULE.Name
      $MYOBJ | Add-Member -type NoteProperty -name description         -Value $NSGRULE.Description
      $MYOBJ | Add-Member -type NoteProperty -name priority            -Value $NSGRULE.Priority
      $MYOBJ | Add-Member -type NoteProperty -name sourcePrefix        -Value $MYSRCIP
      $MYOBJ | Add-Member -type NoteProperty -name sourceGroup         -Value $MYSRCASG
      $MYOBJ | Add-Member -type NoteProperty -name sourcePort          -Value $MYSRCPORT
      $MYOBJ | Add-Member -type NoteProperty -name destinationPrefix   -Value $MYDSTCIP
      $MYOBJ | Add-Member -type NoteProperty -name destinationGroup    -Value $MYDSTASG
      $MYOBJ | Add-Member -type NoteProperty -name destinationPort     -Value $MYDSTPORT
      $MYOBJ | Add-Member -type NoteProperty -name protocol            -Value $NSGRULE.Protocol
      $MYOBJ | Add-Member -type NoteProperty -name access              -Value $NSGRULE.Access
      $MYOBJ | Add-Member -type NoteProperty -name direction           -Value $NSGRULE.Direction

      $MYARRAY += $MYOBJ
    
    
    
   }

   #Write NSG rules to output file
   $MYARRAY | Sort-Object direction,priority | Export-Csv "$exportPath\$($NSGNAME.Name).csv" -NoTypeInformation -Encoding ASCII -Append

}