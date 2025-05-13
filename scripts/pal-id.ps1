param (
    [Parameter(Mandatory=$true)]
    [string]$PartnerId
)

try {
    Write-Output "Setting up PowerShell environment..."
    $ErrorActionPreference = 'Stop'
    
    # Ensure PSGallery is trusted
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    
    Write-Output "Installing required Az.Accounts module..."
    Install-Module -Name Az.Accounts -RequiredVersion 4.0.1 -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
    
    Write-Output "Verifying Az.Accounts installation..."
    $accountsModule = Get-Module -Name Az.Accounts -ListAvailable | Where-Object { $_.Version -eq '4.0.1' }
    if (-not $accountsModule) {
        throw "Failed to install Az.Accounts version 4.0.1"
    }
    
    Write-Output "Installing Az.ManagementPartner module..."
    Install-Module -Name Az.ManagementPartner -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
    
    Write-Output "Verifying Az.ManagementPartner installation..."
    $managementPartnerModule = Get-Module -Name Az.ManagementPartner -ListAvailable
    if (-not $managementPartnerModule) {
        throw "Failed to install Az.ManagementPartner"
    }
    
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
