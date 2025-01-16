param (
    [string]$PartnerId
)

Install-Module -Name Az.AzManagementPartner -force

New-AzManagementPartner -PartnerId $PartnerId
