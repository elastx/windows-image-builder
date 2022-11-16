Import-Module -Name 'NetSecurity'
 
# Setup windows update service to manual
$wuauserv = Get-WmiObject Win32_Service -Filter "Name = 'wuauserv'"
$wuauserv_starttype = $wuauserv.StartMode
Set-Service wuauserv -StartupType Manual
 
# Install OenSSH
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
 
# Set service to automatic and start
Set-Service sshd -StartupType Automatic
Start-Service sshd
 
# Setup windows update service to original
Set-Service wuauserv -StartupType $wuauserv_starttype
 
# Configure PowerShell as the default shell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "$Env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
 
# Restart the service
Restart-Service sshd
 
# Open firewall port 22
$FirewallParams = @{ 
  "DisplayName"       = 'OpenSSH SSH Server (sshd)'
  "Direction"         = 'Inbound'
  "Action"            = 'Allow'
  "Protocol"          = 'TCP'
  "LocalPort"         = '22'
  "Program"           = '%SystemRoot%\system32\OpenSSH\sshd.exe'
}
New-NetFirewallRule @FirewallParams
