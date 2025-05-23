param (
    [Parameter(Mandatory=$true)]
    [string]$PartnerId
)

try {
    Write-Output "Setting up PowerShell environment..."
    $ErrorActionPreference = 'Stop'
    
    # Install required modules
    Write-Output "Installing required Az.Accounts module..."
    Install-Module -Name Az.Accounts -RequiredVersion 4.0.1 -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
    
    Write-Output "Installing Az.ManagementPartner module..."
    Install-Module -Name Az.ManagementPartner -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
    
    # Import modules directly
    Write-Output "Importing modules..."
    Import-Module -Name Az.Accounts -RequiredVersion 4.0.1 -Force -ErrorAction Stop
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
