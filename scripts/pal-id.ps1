param (
    [Parameter(Mandatory=$true)]
    [string]$PartnerId
)

try {
    Write-Output "Setting up PowerShell environment..."
    $ErrorActionPreference = 'Stop'
    
    # Get the current context and ensure we're authenticated
    $context = Get-AzContext
    if (!$context) {
        Connect-AzAccount -Identity
        $context = Get-AzContext
    }
    
    Write-Output "Connected to Azure with subscription: $($context.Subscription)"
    
    # Get the access token for REST API calls
    $instanceProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($instanceProfile)
    $token = $profileClient.AcquireAccessToken($context.Subscription.TenantId)
    $authHeader = @{
        'Content-Type'  = 'application/json' 
        'Authorization' = 'Bearer ' + $token.AccessToken 
    }
    
    # Create the management partner using REST API
    $subscriptionId = $context.Subscription.Id
    $uri = "https://management.azure.com/providers/Microsoft.ManagementPartner/partners/$PartnerId`?api-version=2018-02-01"
    
    Write-Output "Creating management partner with ID: $PartnerId"
    $body = @{
        "properties" = @{
            "partnerId" = $PartnerId
        }
    }
    
    $result = Invoke-RestMethod -Uri $uri -Method Put -Headers $authHeader -Body ($body | ConvertTo-Json)
    
    Write-Output "Successfully created management partner:"
    Write-Output "Partner ID: $($result.properties.partnerId)"
    Write-Output "Partner Name: $($result.properties.partnerName)"
    Write-Output "Tenant ID: $($result.properties.tenantId)"
    Write-Output "Object ID: $($result.properties.objectId)"
}
catch {
    Write-Error "Failed to create management partner: $_"
    throw
}
