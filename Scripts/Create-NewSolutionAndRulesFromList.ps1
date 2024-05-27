param(
    [Parameter(Mandatory = $true)][string]$ResourceGroup,
    [Parameter(Mandatory = $true)][string]$Workspace,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $false)][string[]]$Solutions,
    [Parameter(Mandatory = $false)][string[]]$SeveritiesToInclude = @("Informational", "Low", "Medium", "High")
)

$context = Get-AzContext


if (!$context) {
    Connect-AzAccount
    $context = Get-AzContext
}


Write-Host "Connected to Azure with subscription: " $context.Subscription
$context = Get-AzContext
$instanceProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($instanceProfile)
$token = $profileClient.AcquireAccessToken($context.Subscription.TenantId)
$authHeader = @{
    'Content-Type'  = 'application/json' 
    'Authorization' = 'Bearer ' + $token.AccessToken 
}
$SubscriptionId = $context.Subscription.Id


$baseUri = "https://management.azure.com/subscriptions/${SubscriptionId}/resourceGroups/${ResourceGroup}/providers/Microsoft.OperationalInsights/workspaces/${Workspace}"
$alertUri = "$baseUri/providers/Microsoft.SecurityInsights/alertRules/"

# Get a list of all the solutions
$url = $baseUri + "/providers/Microsoft.SecurityInsights/contentProductPackages?api-version=2024-01-01-preview"
$allSolutions = (Invoke-RestMethod -Method "Get" -Uri $url -Headers $authHeader ).value

#Deploy each single solution
#$templateParameter = @{"workspace-location" = $Region; workspace = $Workspace }
foreach ($deploySolution in $Solutions) {
    $singleSolution = $allSolutions | Where-Object { $_.properties.displayName -Contains $deploySolution }
    if ($null -eq $singleSolution) {
        Write-Error "Unable to get find solution with name $deploySolution" 
    }
    else {
        $solutionURL = $baseUri + "/providers/Microsoft.SecurityInsights/contentProductPackages/$($singleSolution.name)?api-version=2024-01-01-preview"
        $solution = (Invoke-RestMethod -Method "Get" -Uri $solutionURL -Headers $authHeader )
        Write-Host "Solution name: " $solution.name
        $packagedContent = $solution.properties.packagedContent
        #Some of the post deployment instruction contains invalid characters and since this is not displayed anywhere
        #get rid of them.
        foreach ($resource in $packagedContent.resources) { 
            if ($null -ne $resource.properties.mainTemplate.metadata.postDeployment ) { 
                $resource.properties.mainTemplate.metadata.postDeployment = $null 
            } 
        }
        $installBody = @{"properties" = @{
                "parameters" = @{
                    "workspace"          = @{"value" = $Workspace }
                    "workspace-location" = @{"value" = $Region }
                }
                "template"   = $packagedContent
                "mode"       = "Incremental"
            }
        }
        $deploymentName = ("allinone-" + $solution.name)
        if ($deploymentName.Length -ge 64){
            $deploymentName = $deploymentName.Substring(0,64)
        }
        $installURL = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourcegroups/$($ResourceGroup)/providers/Microsoft.Resources/deployments/" + $deploymentName + "?api-version=2024-01-01-preview"
        #$templateUri = $singleSolution.plans.artifacts | Where-Object -Property "name" -EQ "DefaultTemplate"
        Write-Host "Deploying solution:  $deploySolution"
        
        try{
            Invoke-RestMethod -Uri $installURL -Method Put -Headers $authHeader -Body ($installBody | ConvertTo-Json -EnumsAsStrings -Depth 50 -EscapeHandling EscapeNonAscii)
        Write-Host "Deployed solution:  $deploySolution"
        }
        catch {
            $errorReturn = $_
            Write-Error $errorReturn
        }
    }

}

return $return
