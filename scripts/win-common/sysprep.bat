powershell.exe -NoProfile -ExecutionPolicy Bypass -File A:\cleanup-openssh.ps1
%WINDIR%\System32\Sysprep\sysprep.exe /generalize /oobe /mode:vm /shutdown /unattend:A:\unattend.xml
