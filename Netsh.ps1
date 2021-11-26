<# Useful Command that can be used in powershell as an alternate that previously 
   required you to use netsh.
#>

#Enable and disable Windows Firewall
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

#Change the network adapter to use DHCP addressing
$netadapter = Get-NetAdapter -Name Ethernet
$netadapter | Set-NetIPInterface -Dhcp Enabled

#Set a new static IP address
$netadapter = Get-NetAdapter -Name Ethernet
$netadapter | New-NetIPAddress   -IPAddress 123.124.125.1
-PrefixLength 24 –DefaultGateway 123.124.125.1

#Rename a network adapter
Rename-NetAdapter -Name "Ethernet" -NewName "Public"

#Show the system's TCP/IP information
Get-NetIPConfiguration -Detailed

#Disable and enable adapters
Disable-NetAdapter -Name "Wireless Network Connection"
Enable-NetAdapter -Name "Wireless Network Connection"

#List network adapters
Get-NetAdapater
