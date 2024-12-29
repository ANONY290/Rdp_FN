#!/bin/bash

# Prompt for inputs
read -p "Enter the URL to the Windows ISO file: " WIN_ISO_URL
read -p "Enter the amount of RAM for the VM (in MB, e.g., 4096): " RAM_SIZE
read -p "Enter the number of CPUs for the VM: " CPU_COUNT
read -p "Enter a password for the Windows administrator account: " ADMIN_PASSWORD

# Fixed variables
DISK_PATH="/var/lib/libvirt/images/windows.qcow2"

# Update and install required packages
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst wget

# Create a network bridge
echo '
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
  bridges:
    br0:
      interfaces: [eth0]
      dhcp4: yes
' | sudo tee /etc/netplan/01-netcfg.yaml

sudo netplan apply

# Download Windows ISO
wget -O windows.iso $WIN_ISO_URL

# Create a virtual disk for Windows
sudo qemu-img create -f qcow2 $DISK_PATH 40G

# Create and start the VM to install Windows
sudo virt-install \
  --name windows12 \
  --ram $RAM_SIZE \
  --disk path=$DISK_PATH,format=qcow2 \
  --vcpus $CPU_COUNT \
  --os-type windows \
  --os-variant win10 \
  --network bridge=br0 \
  --graphics none \
  --cdrom windows.iso \
  --console pty,target_type=serial \
  --extra-args "console=ttyS0,115200n8 serial"

# Wait for Windows installation to complete...
echo "Please complete the Windows installation via console."
echo "Once the installation is complete, press Enter to continue."
read -p "Press Enter to continue..."

# Enable RDP on Windows
ssh root@localhost "powershell.exe -Command \"Enable-PSRemoting -Force\""
ssh root@localhost "powershell.exe -Command \"Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name 'AllowRemoteRPC' -Value 1\""
ssh root@localhost "powershell.exe -Command \"Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name 'fDenyTSConnections' -Value 0\""
ssh root@localhost "powershell.exe -Command \"Restart-Service -Name 'TermService'\""

# Set the administrator password
ssh root@localhost "net user Administrator $ADMIN_PASSWORD"

# Get the public IP of the VPS
PUBLIC_IP=$(curl -s ifconfig.me)

# Output the RDP details
echo "RDP setup complete!"
echo "Connect to your Windows VM using the following details:"
echo "IP Address: $PUBLIC_IP"
echo "Username: Administrator"
echo "Password: $ADMIN_PASSWORD"
