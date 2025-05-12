param (
    [Parameter(Mandatory=$true)]
    [string]$PartnerId
)

try {
    # Check if PSGallery is registered
    $psGallery = Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue
    if (-not $psGallery) {
        Write-Output "PSGallery not found. Registering PSGallery repository..."
        Register-PSRepository -Default -ErrorAction Stop
    } else {
        Write-Output "PSGallery is already registered."
    }
    
    Write-Output "Installing required Az.Accounts module..."
    Install-Module -Name Az.Accounts -RequiredVersion 4.0.1 -Force -ErrorAction Stop
    Import-Module -Name Az.Accounts -RequiredVersion 4.0.1 -Force -ErrorAction Stop
    
    Write-Output "Installing Az.ManagementPartner module..."
    Install-Module -Name Az.ManagementPartner -Force -ErrorAction Stop
    Import-Module -Name Az.ManagementPartner -Force -ErrorAction Stop
    
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
