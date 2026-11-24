# Reset-SplunkAdmin.ps1
# Resets the local Splunk sign-in when the admin password is forgotten.
# Prompts for the new password at run time; nothing is stored in this file.
$ErrorActionPreference = 'Stop'
$splunk = 'C:\Program Files\Splunk'
$user = Read-Host 'New Splunk username (press Enter for admin)'
if (-not $user) { $user = 'admin' }
$sec = Read-Host 'New Splunk password (8 or more characters)' -AsSecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
if ($plain.Length -lt 8) { throw 'Password must be at least 8 characters. Nothing was changed.' }
Write-Host 'Stopping Splunk...'
Stop-Service splunkd -Force
$passwd = Join-Path $splunk 'etc\passwd'
if (Test-Path $passwd) { Move-Item $passwd ("$passwd.bak-" + (Get-Date -Format yyyyMMddHHmmss)) }
$seed = Join-Path $splunk 'etc\system\local\user-seed.conf'
Set-Content -Path $seed -Value '[user_info]', "USERNAME = $user", "PASSWORD = $plain" -Encoding ASCII
$plain = $null
Write-Host 'Starting Splunk (this takes a minute)...'
Start-Service splunkd
$waited = 0
while (-not (Test-Path $passwd) -and $waited -lt 180) { Start-Sleep 5; $waited += 5 }
if (Test-Path $seed) { Remove-Item $seed -Force }
if (Test-Path $passwd) { Write-Host "Done. Sign in at http://localhost:8000 as $user." }
else { Write-Host 'Splunk started but the new sign-in was not confirmed. Tell Claude.' }
