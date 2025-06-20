 <#
param (
     
    [Parameter(Mandatory = $true)]
    [string]$TagName="maintainance",
 
    [Parameter(Mandatory = $true)]
    [string]$TagValue="daily"
)#>
 
 $TagName="maintainance"
 $TagValue="daily"
 $resourceGroup = "DefaultResourceGroup-CCAN"

# Connect to Azure (if not already connected)
# Authenticate with Managed Identity
az login

# Parameters
# $tagName = "patch"    # Specify your tag name
# $tagValue = "patch-001"     # Specify your tag value
$maxConcurrentJobs = 10    # Maximum number of concurrent jobs
 
# Function to process VMs in a subscription
function Process-VMs {
param (
    [string]$SubscriptionId,
    [string]$SubscriptionName
)
  az account set --subscription $SubscriptionId

 Set-AzContext -SubscriptionId $SubscriptionId
 
 Get-AzContext
Write-Host "`nProcessing Subscription: $SubscriptionName ($SubscriptionId)" -ForegroundColor Yellow
 
# Get all VMs with the specified tag
$vms = Get-AzVM | Where-Object {$_.Tags.Keys -contains $tagName -and $_.Tags[$tagName] -eq $tagValue}
 
if ($vms.Count -eq 0) {
    Write-Host "No VMs found with tag $tagName = $tagValue in subscription $SubscriptionName" -ForegroundColor Yellow
    return
}

# Get all existing maintenance configurations in the RG
$maintenanceConfigs = Get-AzMaintenanceConfiguration #-ResourceGroupName $resourceGroup

 foreach ($vm in $vms) {
$vmName = $vm.Name
    $tagValue = $vm.Tags[$tagName]
    
    Write-Host " VM '$vmName' has tag $tagKey = '$tagValue'"
    
    # Find matching maintenance configuration by name
    $config = $maintenanceConfigs | Where-Object { $_.Name -eq $tagValue }
    
    if (-not $config) {
        Write-Warning " No maintenance configuration found with name '$tagValue'. Skipping VM '$vmName'"
        continue
    }
  
    # Assign VM to maintenance configuration
    $assignmentName = "$vmName-$tagValue"

    Write-Host " Assigning VM '$vmName' to maintenance config '$tagValue'"
   az maintenance assignment create   --resource-group $vm.ResourceGroupName   --location $vm.Location  --resource-name $vm.Name   --resource-type virtualMachines   --provider-name Microsoft.Compute   --configuration-assignment-name $($vm.Name)-$($config.Name)   --maintenance-configuration-id $config.Id 
}
}
 
# Main script
try {
$subscriptions = Get-AzSubscription
 
foreach ($sub in $subscriptions) {
    Set-AzContext -SubscriptionId $sub.Id | Out-Null
    Process-VMs -SubscriptionId $sub.Id -SubscriptionName $sub.Name
}
}
catch {
Write-Host "Error: $_" -ForegroundColor Red
}
finally {
Get-Job | Remove-Job -Force
Write-Host "`nScript execution completed" -ForegroundColor Green
}
 
