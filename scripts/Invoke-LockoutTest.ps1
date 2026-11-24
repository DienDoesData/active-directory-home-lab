<#
  Invoke-LockoutTest.ps1
  Simulates a user mistyping their password so the account lockout policy can be tested.
  Uses deliberately wrong values; no real password is stored or needed.
#>
param(
    [string]$User = 'lortega',
    [int]$Attempts = 6
)

Import-Module ActiveDirectory
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$domain = (Get-ADDomain).DNSRoot
$context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('Domain', $domain)

Write-Host "Simulating $Attempts failed sign-ins for $User on $domain ..."
1..$Attempts | ForEach-Object {
    $accepted = $context.ValidateCredentials($User, "not-the-password-$_")
    Write-Host ("Attempt {0}: sign-in accepted = {1}" -f $_, $accepted)
    Start-Sleep -Milliseconds 300
}

Write-Host ""
Write-Host "Accounts currently locked out:"
Search-ADAccount -LockedOut | Select-Object Name, SamAccountName, LockedOut | Format-Table -AutoSize | Out-String | Write-Host
