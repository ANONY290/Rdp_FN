#!/bin/bash

# Function to log time and messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Log the start time
START_TIME=$(date +%s)
log "Script started."

# Prompt for inputs
read -p "Enter the URL to the Windows ISO file: " WIN_ISO_URL
read -p "Enter the amount of RAM for the VM (in MB, e.g., 4096): " RAM_SIZE
read -p "Enter the number of CPUs for the VM: " CPU_COUNT
read -p "Enter a password for the Windows administrator account: " ADMIN_PASSWORD

# Fixed variables
DISK_PATH="$HOME/windows.qcow2"

# Error handling function
handle_error() {
    log "Error encountered during: $1"
    exit 1
}

# Update and install required packages
log "Updating system and installing required packages..."
sudo apt update && sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst wget || handle_error "installing packages"
log "Packages installed successfully."

# Create a network bridge
log "Creating network bridge..."
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
log "Applying network configuration..."
sudo netplan apply || handle_error "creating network bridge"
log "Network bridge created successfully. Verifying..."

# Verify bridge creation
sudo brctl show | grep br0 || handle_error "creating network bridge"
log "Network bridge br0 verified successfully."

# Download Windows ISO
log "Downloading Windows ISO..."
wget -O windows.iso $WIN_ISO_URL || handle_error "downloading Windows ISO"
log "Windows ISO downloaded successfully."

# Create a virtual disk for Windows
log "Creating virtual disk..."
sudo qemu-img create -f qcow2 $DISK_PATH 40G || handle_error "creating virtual disk"
log "Virtual disk created successfully."

# Create and start the VM to install Windows
log "Starting VM installation..."
sudo virt-install \
  --name windows11 \
  --ram $RAM_SIZE \
  --disk path=$DISK_PATH,format=qcow2 \
  --vcpus $CPU_COUNT \
  --os-type windows \
  --os-variant win10 \
  --network bridge=br0 \
  --graphics none \
  --cdrom windows.iso \
  --console pty,target_type=serial \
  --extra-args "console=ttyS0,115200n8 serial" || handle_error "starting VM installation"
log "VM installation started successfully."

# Wait for Windows installation to complete...
log "Waiting for Windows installation to complete..."
echo "Please complete the Windows installation via console."
echo "Once the installation is complete, press Enter to continue."
read -p "Press Enter to continue..."

# Enable RDP on Windows
log "Enabling RDP on Windows..."
ssh root@localhost "powershell.exe -Command \"Enable-PSRemoting -Force\"" || handle_error "enabling RDP on Windows"
ssh root@localhost "powershell.exe -Command \"Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name 'AllowRemoteRPC' -Value 1\"" || handle_error "enabling RDP on Windows"
ssh root@localhost "powershell.exe -Command \"Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name 'fDenyTSConnections' -Value 0\"" || handle_error "enabling RDP on Windows"
ssh root@localhost "powershell.exe -Command \"Restart-Service -Name 'TermService'\"" || handle_error "enabling RDP on Windows"
log "RDP enabled on Windows successfully."

# Set the administrator password
log "Setting administrator password..."
ssh root@localhost "net user Administrator $ADMIN_PASSWORD" || handle_error "setting administrator password"
log "Administrator password set successfully."

# Get the public IP of the VPS
PUBLIC_IP=$(curl -s ifconfig.me)
log "Public IP obtained: $PUBLIC_IP"

# Calculate and log the total time taken
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
log "Script completed. Total time taken: $TOTAL_TIME seconds."

# Output the RDP details
echo "RDP setup complete!"
echo "Connect to your Windows VM using the following details:"
echo "IP Address: $PUBLIC_IP"
echo "Username: Administrator"
echo "Password: $ADMIN_PASSWORD"
