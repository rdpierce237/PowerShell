Param 
    (
    [string]$AZEnvironment,
    [string]$resourceGroup,
    [string]$exportPath,
    [string]$nsgList
    )

#Initial format of variables
$NSGNAME = ""
$MYARRAY = @()



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
if ([string]::IsNullOrEmpty($nsgList)) 
  {
  $nsgList = Get-AzNetworkSecurityGroup -Name dal-p*
  }
#Set output path to current directory if not specified as an execution argument
if ([string]::IsNullOrEmpty($exportPath)) 
  {
  $exportPath = Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
  }



# Check to see if user is logged into Azure and present login if they're not
if ([string]::IsNullOrEmpty($(Get-AzContext).Account)) 
  {
  Connect-AzAccount -Environment $AZEnvironment
  }

# Get current date for file formatting
#$DATE = Get-Date -Format "MM/dd/yyyy"
#$DATE


foreach ($NSGNAME in $nsgList) {
# Initialize loop variables
$MYARRAY = @()
$BACKUPDATE = ""
$BACKUPNAME = ""

#Check if the output file already exists, and if it does, move it to <file>_<creation date>.csv
if ([System.IO.File]::Exists("$ExportPath\$($NSGNAME.name).csv")) {
Write-Host "Export file already exists"

$BACKUPDATE = Get-ChildItem "$ExportPath\$($NSGNAME.name).csv" | Select-Object -ExpandProperty CreationTime | Get-Date -Format "MM-dd-yyyy"
$BACKUPNAME = "$ExportPath\$($NSGNAME.name)_$BACKUPDATE.csv"

if (-NOT [System.IO.File]::Exists("$BACKUPNAME")) {
   Write-Host "Backup file doesn't exist already"
   [System.IO.File]::Move("$ExportPath\$($NSGNAME.name).csv", $BACKUPNAME)
}
}



 #create output file for writing 
 Write-Host 'Creating CSV file for: ' $NSGNAME.name
 New-Item -ItemType file -Path "$ExportPath\$($NSGNAME.name).csv" -Force

# Retrieve NSGs associated rules and export them to the CSV file

Write-Host "Presenting rules for "$NSGNAME.Name "==================="
$NSGRules = $NSGNAME.SecurityRules

foreach ($NSGRule in $NSGRules) {
    $MYSRCASG = ""
    $MYSRCIP = ""
    $MYDSTASG = ""
    $MYDSTIP = ""
    $MYSRCPORT = ""
    $MYDSTPORT = ""

  #$OUTPUT = $NSGRule | Select-Object Name,Description,Priority,@{Name=’SourceAddressPrefix’;Expression={[string]::join(“;”, ($_.SourceAddressPrefix))}},@{Name='SourceApplicationSecurityGroups';Expression={([string]::split("/",$_.SourceApplicationSecurityGroups.Id))[-1]}},@{Name=’SourcePortRange’;Expression={[string]::join(";", ($_.SourcePortRange))}},@{Name=’DestinationAddressPrefix’;Expression={[string]::join(";", ($_.DestinationAddressPrefix))}},DestinationApplicationSecurityGroups,@{Name=’DestinationPortRange’;Expression={[string]::join(";", ($_.DestinationPortRange))}},Protocol,Access,Direction 
   #| Export-Csv "$exportPath\$($NSGNAME.Name).csv" -NoTypeInformation -Encoding ASCII -Append
   #$OUTPUT

   if ([string]::IsNullOrWhitespace($NSGRule.SourceAddressPrefix)) {
     $MYSRCASG = ($NSGRULE.SourceApplicationSecurityGroups.Id).Split("/")[-1] 
     $MYSRCIP = ""
   }
   else { 
     $MYSRCIP = ([string]::join(“;”, ($NSGRule.SourceAddressPrefix)))
   }

   if ([string]::IsNullOrWhitespace($NSGRule.DestinationAddressPrefix)) {
     $MYDSTASG = ($NSGRULE.DestinationApplicationSecurityGroups.Id).Split("/")[-1] 
   }
   else {
     $MYDSTIP = ([string]::join(“;”, ($NSGRule.DestinationAddressPrefix)))
   }

   $MYSRCPORT = ([string]::join(";", ($NSGRule.SourcePortRange)))
   $MYDSTPORT = ([string]::join(";", ($NSGRule.DestinationPortRange)))


   $MYOBJ = new-object psobject
   $MYOBJ | Add-Member -type NoteProperty -name ruleName            -Value $NSGRule.Name
   $MYOBJ | Add-Member -type NoteProperty -name description         -Value $NSGRule.Description
   $MYOBJ | Add-Member -type NoteProperty -name priority            -Value $NSGRule.Priority
   $MYOBJ | Add-Member -type NoteProperty -name sourcePrefix        -Value $MYSRCIP
   $MYOBJ | Add-Member -type NoteProperty -name sourceGroup         -Value $MYSRCASG
   $MYOBJ | Add-Member -type NoteProperty -name sourcePort          -Value $MYSRCPORT
   $MYOBJ | Add-Member -type NoteProperty -name destinationPrefix   -Value $MYDSTCIP
   $MYOBJ | Add-Member -type NoteProperty -name destinationGroup    -Value $MYDSTASG
   $MYOBJ | Add-Member -type NoteProperty -name destinationPort     -Value $MYDSTPORT
   $MYOBJ | Add-Member -type NoteProperty -name protocol            -Value $NSGRule.Protocol
   $MYOBJ | Add-Member -type NoteProperty -name access              -Value $NSGRule.Access
   $MYOBJ | Add-Member -type NoteProperty -name direction           -Value $NSGRule.Direction

   $MYARRAY += $MYOBJ
    
    
    
}


$MYARRAY | Sort-Object direction,priority | Export-Csv "$exportPath\$($NSGNAME.Name).csv" -NoTypeInformation -Encoding ASCII -Append

}
