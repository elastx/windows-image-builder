# Cleanup of the OpenSSH server that setup-openssh.ps1 installed so the build
# could run its Ansible playbook over SSH. The shipped image must not expose
# an SSH server, so this runs as the first step of the Packer shutdown command
# (A:\sysprep.bat), over the very session it is about to terminate.
#
# Stopping sshd here is safe:
#   - Packer's SSH communicator treats a connection drop during the shutdown
#     command as a normal disconnect and simply waits for the VM to power off
#     (packer-plugin-qemu: stepShutdown ignores the command's exit status).
#   - Windows OpenSSH does not tie non-pty session children to the sshd
#     process lifecycle (no kill-on-close job object, see
#     PowerShell/Win32-OpenSSH issue #1751), so cmd.exe, this script and
#     sysprep continue as orphaned processes until sysprep /shutdown powers
#     the machine off.
#
# Ordering is deliberate: the firewall rules and the service autostart are
# removed before anything lethal happens, so a deployed image can never bring
# up sshd even if the later steps of this script fail. After Stop-Service sshd
# the SSH stdout pipe is gone, so all remaining output goes to the log file
# at $env:SystemRoot\Temp\openssh-cleanup.log.

$ErrorActionPreference = 'Continue'
$Log = Join-Path $env:SystemRoot 'Temp\openssh-cleanup.log'

function Write-Log {
    param([string]$Message)
    $Line = (Get-Date -Format u) + ' ' + $Message
    Add-Content -Path $Log -Value $Line -ErrorAction SilentlyContinue
    # Goes to the SSH session (and packer's build log) until sshd is stopped.
    Write-Output $Line
}

Write-Log 'Starting OpenSSH cleanup'

# Firewall rules only admit new inbound connections; the established session
# this script runs over keeps working while they are removed.
# setup-openssh.ps1 created the first rule; the OpenSSH capability installer
# adds 'OpenSSH-Server-In-TCP' by itself.
Get-NetFirewallRule -DisplayName @('OpenSSH SSH Server (sshd)', 'OpenSSH-Server-In-TCP') -ErrorAction SilentlyContinue |
    Remove-NetFirewallRule -ErrorAction SilentlyContinue
Write-Log 'Removed OpenSSH firewall rules'

# The DefaultShell pointer made sshd hand sessions to powershell.exe, which
# the Ansible connection required. It has no purpose once sshd is gone.
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -ErrorAction SilentlyContinue
Write-Log 'Removed OpenSSH DefaultShell registry value'

# Insurance: even if the capability removal below fails, sshd must never start
# again on a deployed machine.
foreach ($Service in 'sshd', 'ssh-agent') {
    try {
        Set-Service -Name $Service -StartupType Disabled -ErrorAction Stop
    }
    catch {
        Write-Log "Service $Service not present or already gone: $($_.Exception.Message)"
    }
}
Stop-Service -Name ssh-agent -Force -ErrorAction SilentlyContinue
Write-Log 'sshd and ssh-agent disabled, ssh-agent stopped'

# This ends the SSH session this script was invoked from. Everything below
# runs as an orphan and only reaches the log file - sshd is dead, sysprep
# follows in sysprep.bat once this script exits.
Stop-Service -Name sshd -Force -ErrorAction SilentlyContinue

# Remove the OpenSSH server capability: binaries and service registration.
# This is a DISM operation and takes a few minutes; sysprep.bat waits for
# this script to exit before starting sysprep.
try {
    $Capability = Get-WindowsCapability -Online |
        Where-Object { $_.Name -like 'OpenSSH.Server*' -and $_.State -ne 'NotPresent' }
    foreach ($Cap in $Capability) {
        Remove-WindowsCapability -Online -Name $Cap.Name | Out-Null
        Write-Log "Removed Windows capability: $($Cap.Name)"
    }
    if (-not $Capability) {
        Write-Log 'OpenSSH.Server capability not installed, nothing to remove'
    }
}
catch {
    Write-Log "Capability removal failed (services are disabled in any case): $($_.Exception.Message)"
}

# The capability removal leaves the configuration directory behind: host keys
# and sshd_config. Host keys are private key material instantiated in every
# machine built from this image, so they must not ship.
Remove-Item -Path (Join-Path $env:ProgramData 'ssh') -Recurse -Force -ErrorAction SilentlyContinue
Write-Log 'Removed ProgramData ssh configuration (host keys, sshd_config)'

Write-Log 'OpenSSH cleanup finished'