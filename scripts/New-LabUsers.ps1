<#
  New-LabUsers.ps1
  Builds the Gulfside Supply Co. lab directory from users.csv:
  one OU and one security group per department, then one account per row.
  Asks for the starting password at run time, so no password is stored in this file.
#>
param(
    [string]$CsvPath = "$PSScriptRoot\users.csv",
    [string]$CompanyOU = "Gulfside"
)

Import-Module ActiveDirectory
$domain   = Get-ADDomain
$domainDN = $domain.DistinguishedName
$upnSuffix = $domain.DNSRoot

$password = Read-Host -AsSecureString "Starting password for all new users (they must change it at first sign-in)"

# Top-level company OU
$companyDN = "OU=$CompanyOU,$domainDN"
if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$companyDN'" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name $CompanyOU -Path $domainDN
    Write-Host "Created OU $CompanyOU"
}

$rows = Import-Csv $CsvPath
$created = 0; $skipped = 0

# One OU and one security group per department
foreach ($dept in ($rows.Department | Sort-Object -Unique)) {
    $deptDN = "OU=$dept,$companyDN"
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$deptDN'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $dept -Path $companyDN
        Write-Host "Created OU $dept"
    }
    $groupName = "GRP-$dept"
    if (-not (Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $groupName -GroupScope Global -GroupCategory Security -Path $deptDN -Description "$dept department staff"
        Write-Host "Created group $groupName"
    }
}

# Accounts: first initial + last name, lower case
foreach ($r in $rows) {
    $sam = ($r.FirstName.Substring(0,1) + $r.LastName).ToLower() -replace "[^a-z]", ""
    if (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue) {
        Write-Host "Skipped $sam (already exists)"; $skipped++; continue
    }
    New-ADUser -Name "$($r.FirstName) $($r.LastName)" `
        -GivenName $r.FirstName -Surname $r.LastName `
        -SamAccountName $sam -UserPrincipalName "$sam@$upnSuffix" `
        -Department $r.Department -Title $r.Title -Company "Gulfside Supply Co." `
        -Path "OU=$($r.Department),$companyDN" `
        -AccountPassword $password -ChangePasswordAtLogon $true -Enabled $true
    Add-ADGroupMember -Identity "GRP-$($r.Department)" -Members $sam
    Write-Host "Created $sam ($($r.Title), $($r.Department))"; $created++
}

# Managers are set in a second pass, once every account exists
foreach ($r in $rows | Where-Object Manager) {
    $sam = ($r.FirstName.Substring(0,1) + $r.LastName).ToLower() -replace "[^a-z]", ""
    Set-ADUser -Identity $sam -Manager $r.Manager
}

Write-Host ""
Write-Host "Done. Created $created, skipped $skipped."
