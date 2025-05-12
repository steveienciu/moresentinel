param (
    [Parameter(Mandatory=$true)]
    [string]$PartnerId
)

try {
    Write-Output "Registering PowerShell Gallery repository..."
    Register-PSRepository -Default -ErrorAction Stop
    
    Write-Output "Installing Az.AzManagementPartner module..."
    Install-Module -Name Az.AzManagementPartner -Force -ErrorAction Stop
    
    Write-Output "Creating management partner with ID: $PartnerId"
    $result = New-AzManagementPartner -PartnerId $PartnerId -ErrorAction Stop
    
    Write-Output "Successfully created management partner:"
    Write-Output "Partner ID: $($result.PartnerId)"
    Write-Output "Partner Name: $($result.PartnerName)"
    Write-Output "Tenant ID: $($result.TenantId)"
    Write-Output "Object ID: $($result.ObjectId)"
}
catch {
    Write-Error "Failed to create management partner: $_"
    throw
}
