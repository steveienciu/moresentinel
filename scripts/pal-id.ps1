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
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.ManagementPartner/partners/$PartnerId`?api-version=2018-02-01"
    
    Write-Output "Creating management partner with ID: $PartnerId"
    $body = @{
        "properties" = @{
            "partnerId" = $PartnerId
        }
    }
    
    $result = Invoke-RestMethod -Uri $uri -Method Put -Headers $authHeader -Body ($body | ConvertTo-Json)
    
    # Verify the association was created
    $verifyUri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.ManagementPartner/partners/$PartnerId`?api-version=2018-02-01"
    $verification = Invoke-RestMethod -Uri $verifyUri -Method Get -Headers $authHeader
    
    if ($verification.properties.partnerId -eq $PartnerId) {
        Write-Output "Successfully created and verified management partner:"
        Write-Output "Partner ID: $($verification.properties.partnerId)"
        Write-Output "Partner Name: $($verification.properties.partnerName)"
        Write-Output "Tenant ID: $($verification.properties.tenantId)"
        Write-Output "Object ID: $($verification.properties.objectId)"
        
        # Add the PAL ID as a tag to the subscription
        $tagUri = "https://management.azure.com/subscriptions/$subscriptionId`?api-version=2020-01-01"
        $currentTags = (Invoke-RestMethod -Uri $tagUri -Method Get -Headers $authHeader).tags
        $currentTags["pid-$PartnerId"] = "true"
        
        $tagBody = @{
            "tags" = $currentTags
        }
        
        Invoke-RestMethod -Uri $tagUri -Method Patch -Headers $authHeader -Body ($tagBody | ConvertTo-Json)
        Write-Output "Added PAL ID tag to subscription"
    }
    else {
        throw "Failed to verify management partner association"
    }
}
catch {
    Write-Error "Failed to create management partner: $_"
    throw
}
