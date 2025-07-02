$TagPairs = @(
    @{ TagName = "MaintWinPatch"; TagValue = "Nightly_patch" }
    @{ TagName = "MaintWinPatch"; TagValue = "PilotGrp1" }
    @{ TagName = "MaintWinPatch"; TagValue = "PilotGrp2" }
    @{ TagName = "MaintWinPatch"; TagValue = "PilotGrp3" }
    @{ TagName = "MaintWinPatch"; TagValue = "TestGrp1" }
    @{ TagName = "MaintWinPatch"; TagValue = "TestGrp2" }
    @{ TagName = "MaintWinPatch"; TagValue = "TestGrp3" }
    @{ TagName = "MaintWinPatch"; TagValue = "PrepGrp1" }
    @{ TagName = "MaintWinPatch"; TagValue = "PrepGrp2" }
    @{ TagName = "MaintWinPatch"; TagValue = "PrepGrp3" }
    @{ TagName = "MaintWinPatch"; TagValue = "ProdGrp1" }
    @{ TagName = "MaintWinPatch"; TagValue = "ProdGrp2" }
    @{ TagName = "MaintWinPatch"; TagValue = "ProdGrp3" }
    @{ TagName = "MaintWinScan"; TagValue = "Nightly_scan" }
)
 
 
 #$TagName="maintainance"
 #$TagValue="daily"
 #$resourceGroup = "DefaultResourceGroup-CCAN"
 
# Connect to Azure (if not already connected)
# Authenticate with Managed Identity
Write-OutPut "Starting Point"
#Disable-AzContextAutosave -Scope Process
Connect-AzAccount #-Identity
Write-OutPut "Authenticated"
 
# Parameters
# $tagName = "patch"    # Specify your tag name
# $tagValue = "patch-001"     # Specify your tag value
#$maxConcurrentJobs = 10    # Maximum number of concurrent jobs
 
# Function to process VMs in a subscription
function Process-VMs {
param (
    [string]$SubscriptionId,
    [string]$SubscriptionName
)
  az account set --subscription $SubscriptionId
 
 Set-AzContext -SubscriptionId $SubscriptionId
 
Write-OutPut "`nProcessing Subscription: $SubscriptionName ($SubscriptionId)"
 
# Get all VMs with the specified tag
 
$vms = Get-AzVM | Where-Object {
    $vm = $_
    $TagPairs | Where-Object {
        $vm.Tags.Keys -contains $_.TagName -and $vm.Tags[$_.TagName] -eq $_.TagValue
    }
}
if ($vms.Count -eq 0) {
    Write-OutPut "No VMs found with tag $tagName = $tagValue in subscription $SubscriptionName"
    return
}
 
# Get all existing maintenance configurations in the RG
#$maintenanceConfigs = Get-AzMaintenanceConfiguration -ResourceGroupName "DefaultResourceGroup-CCAN"
 
 
 foreach ($vm in $vms) {
   Write-Host "`nProcessing VM: $($vm.Name)"
 
    # Check OS Type
    if ($vm.StorageProfile.OSDisk.OSType -eq "Windows") {
        Write-Host "Detected Windows VM"
 
        # Set patch mode
        Set-AzVMOperatingSystem -VM $vm -Windows -PatchMode "AutomaticByPlatform" | Out-Null
 
        # Ensure patch settings exist
        if (-not $vm.OSProfile.WindowsConfiguration.PatchSettings) {
            $vm.OSProfile.WindowsConfiguration.PatchSettings = New-Object -TypeName Microsoft.Azure.Management.Compute.Models.WindowsVMGuestPatchSettings
        }
 
        # Check and apply AutomaticByPlatformSettings
        $autoSettings = $vm.OSProfile.WindowsConfiguration.PatchSettings.AutomaticByPlatformSettings
        if (-not $autoSettings) {
            $vm.OSProfile.WindowsConfiguration.PatchSettings.AutomaticByPlatformSettings = New-Object -TypeName Microsoft.Azure.Management.Compute.Models.WindowsVMGuestPatchAutomaticByPlatformSettings -Property @{
                BypassPlatformSafetyChecksOnUserSchedule = $true
            }
        } else {
            $autoSettings.BypassPlatformSafetyChecksOnUserSchedule = $true
        }
         Write-Host "Updating VM: $($vm.Name)"
    Update-AzVM -VM $vm -ResourceGroupName $vm.ResourceGroupName
    }
    elseif ($vm.StorageProfile.OSDisk.OSType -eq "Linux") {
        Write-Host "Detected Linux VM"
 
        # Set patch mode
        Set-AzVMOperatingSystem -VM $vm -Linux -PatchMode "AutomaticByPlatform" | Out-Null
 
        # Ensure patch settings exist
        if (-not $vm.OSProfile.LinuxConfiguration.PatchSettings) {
            $vm.OSProfile.LinuxConfiguration.PatchSettings = New-Object -TypeName Microsoft.Azure.Management.Compute.Models.LinuxVMGuestPatchSettings
        }
 
        # Check and apply AutomaticByPlatformSettings
        $autoSettings = $vm.OSProfile.LinuxConfiguration.PatchSettings.AutomaticByPlatformSettings
        if (-not $autoSettings) {
            $vm.OSProfile.LinuxConfiguration.PatchSettings.AutomaticByPlatformSettings = New-Object -TypeName Microsoft.Azure.Management.Compute.Models.LinuxVMGuestPatchAutomaticByPlatformSettings -Property @{
                BypassPlatformSafetyChecksOnUserSchedule = $true
            }
        } else {
            $autoSettings.BypassPlatformSafetyChecksOnUserSchedule = $true
        }
         Write-Host "Updating VM: $($vm.Name)"
    Update-AzVM -VM $vm -ResourceGroupName $vm.ResourceGroupName
    }
     else {
        Write-Warning "Unknown OS type for VM: $($vm.Name). Skipping."
        continue
    }
 
    # Apply the change
   
$vmName = $vm.Name
  $rgName = $vm.ResourceGroupName
    # Get the value of the tag for the input tag name
$tagKey = $TagPairs | Where-Object { $vm.Tags.ContainsKey($_.TagName) } | Select-Object -First 1 -ExpandProperty TagName
$tagValue = $null
if ($tagKey) {
    $tagValue = $vm.Tags[$tagKey]
}
    Write-OutPut " VM '$vmName' has tag $tagKey = '$tagValue'"
    # Step 1: Get the access token
    $configId = Get-MaintenanceConfigIdByName -ConfigName $tagValue
#$accessToken = (az account get-access-token --query accessToken -o tsv)
$accessToken = (Get-AzAccessToken -ResourceUrl "https://management.azure.com/").Token
# Step 2: Set the URL and request body
$url = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$rgName/providers/Microsoft.Compute/virtualMachines/$vmName/providers/Microsoft.Maintenance/configurationAssignments/$vmName"+"?api-version=2021-09-01-preview"
 
 
$body = @{
    location = "eastus"
    properties = @{
        maintenanceConfigurationId = $configId
    }
} | ConvertTo-Json -Depth 5
 
# Step 3: Set headers
$headers = @{
    Authorization = "Bearer $accessToken"
    "Content-Type" = "application/json"
}
 
# Step 4: Make the PUT request
 
try {
    $response = Invoke-RestMethod -Method PUT -Uri $url -Headers $headers -Body $body
    Write-OutPut "Success!"
    $response
} catch {
    Write-OutPut "Request failed:"
   
    $respStream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($respStream)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd()
   
    try {
        $json = $responseBody | ConvertFrom-Json
        $json | Format-List
    } catch {
        Write-OutPut "Raw response:"
        Write-Output $responseBody
    }
}
 
 
}
}
 
 function Get-MaintenanceConfigIdByName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigName
    )
 
    # Ensure logged in
    if (-not (Get-AzContext)) {
        Connect-AzAccount | Out-Null
    }
 
    $apiVersion = "2023-04-01"
    $subscriptions = Get-AzSubscription
    foreach ($sub in $subscriptions) {
        # Set subscription context
        Set-AzContext -SubscriptionId $sub.Id | Out-Null
 
        # Build API URI
        $uri = "https://management.azure.com/subscriptions/$($sub.Id)/providers/Microsoft.Maintenance/maintenanceConfigurations?api-version=$apiVersion"
 
        # Get access token
        $accessToken = (Get-AzAccessToken).Token
 
        $headers = @{
            'Authorization' = "Bearer $accessToken"
            'Content-Type'  = 'application/json'
        }
 
        try {
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            $configs = $response.value
 
            # Filter by name
            $match = $configs | Where-Object { $_.name -eq $ConfigName } | Select-Object -First 1
 
            if ($match) {
                return $match.id
            }
        }
        catch {
            Write-Warning "Failed to query subscription $($sub.Id): $_"
        }
    }
 
    # If nothing found, return null
    return $null
}
 
# Main script
try {
Write-OutPut "Getting Subscriptions"
$subscriptions = Get-AzSubscription
 Write-OutPut $subscriptions
 
foreach ($sub in $subscriptions) {
    Set-AzContext -SubscriptionId $sub.Id | Out-Null
    Write-OutPut $Sub.id
    Process-VMs -SubscriptionId $sub.Id -SubscriptionName $sub.Name
}
 #Process-VMs -SubscriptionId $sub.Id -SubscriptionName "CSSP_AZR_MANAGEMENT"
}
catch {
Write-OutPut "Error: $_" -ForegroundColor Red
}
finally {
Get-Job | Remove-Job -Force
Write-OutPut "`nScript execution completed"
}

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
 
