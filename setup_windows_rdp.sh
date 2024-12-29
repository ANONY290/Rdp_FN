#!/bin/bash

# Function to log time and messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
    send_telegram_message "$1"
}

# Function to send message to Telegram bot
send_telegram_message() {
    local message=$1
    if [ -z "$BOT_TOKEN" ] || [ -z "$USER_ID" ]; then
        echo "Bot token or user ID not provided."
    else
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id=$USER_ID \
        -d text="$message" || echo "Failed to send message to Telegram."
    fi
}

# Function to show a progress bar
show_progress() {
    local duration=$1
    local steps=100
    for i in $(seq 1 $steps); do
        sleep $(bc <<< "scale=2; $duration / $steps")
        echo $i
    done
}

# Log the start time
START_TIME=$(date +%s)
log "Script started." 0

# Prompt for inputs
read -p "Enter the URL to the Windows ISO file: " WIN_ISO_URL
read -p "Enter the amount of RAM for the VM (in MB, e.g., 4096): " RAM_SIZE
read -p "Enter the number of CPUs for the VM: " CPU_COUNT
read -p "Enter a password for the Windows administrator account: " ADMIN_PASSWORD
read -p "Enter your Telegram Bot Token: " BOT_TOKEN
read -p "Enter your Telegram User ID: " USER_ID

# Fixed variables
DISK_PATH="/var/lib/libvirt/images/windows.qcow2"

# Initial message to inform about Telegram updates
send_telegram_message "RDP setup script is now starting. You will receive updates at each step. If the terminal closes, you will still get all updates and final details here."

# Error handling function
handle_error() {
    log "Error encountered during: $1" 100
    send_telegram_message "Error encountered during: $1"
    exit 1
}

# Update and install required packages with progress bar
log "Updating system and installing required packages..." 10
apt update && apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst wget || handle_error "installing packages"
log "Packages installed successfully." 30

# Create a network bridge
log "Creating network bridge..." 40
echo '
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: yes
  bridges:
    br0:
      interfaces: [eth0]
      dhcp4: yes
' | tee /etc/netplan/01-netcfg.yaml
log "Applying network configuration..." 50
netplan apply || handle_error "creating network bridge"
log "Network bridge created successfully. Verifying..." 60

# Verify bridge creation
brctl show | grep br0 || handle_error "creating network bridge"
log "Network bridge br0 verified successfully." 70

# Download Windows ISO with progress bar
log "Downloading Windows ISO..." 80
wget -O windows.iso $WIN_ISO_URL || handle_error "downloading Windows ISO"
log "Windows ISO downloaded successfully." 90

# Create a virtual disk for Windows
log "Creating virtual disk..." 95
qemu-img create -f qcow2 $DISK_PATH 40G || handle_error "creating virtual disk"
log "Virtual disk created successfully." 100

# Create and start the VM to install Windows
log "Starting VM installation..." 40
virt-install \
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
log "VM installation started successfully." 60

# Wait for Windows installation to complete...
log "Waiting for Windows installation to complete..." 80
echo "Please complete the Windows installation via console."
echo "Once the installation is complete, press Enter to continue."
read -p "Press Enter to continue..."

# Enable RDP on Windows
log "Enabling RDP on Windows..." 90
ssh root@localhost "powershell.exe -Command \"Enable-PSRemoting -Force\"" || handle_error "enabling RDP on Windows"
ssh root@localhost "powershell.exe -Command \"Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name 'AllowRemoteRPC' -Value 1\"" || handle_error "enabling RDP on Windows"
ssh root@localhost "powershell.exe -Command \"Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name 'fDenyTSConnections' -Value 0\"" || handle_error "enabling RDP on Windows"
ssh root@localhost "powershell.exe -Command \"Restart-Service -Name 'TermService'\"" || handle_error "enabling RDP on Windows"
log "RDP enabled on Windows successfully." 95

# Set the administrator password
log "Setting administrator password..." 98
ssh root@localhost "net user Administrator $ADMIN_PASSWORD" || handle_error "setting administrator password"
log "Administrator password set successfully." 100

# Get the public IP of the VPS
PUBLIC_IP=$(curl -s ifconfig.me)
log "Public IP obtained: $PUBLIC_IP" 100

# Calculate and log the total time taken
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
MINUTES=$((TOTAL_TIME / 60))
SECONDS=$((TOTAL_TIME % 60))
log "Script completed. Total time taken: $MINUTES minutes and $SECONDS seconds." 100

# Send RDP details to Telegram
send_telegram_message "RDP setup complete! Connect to your Windows VM using the following details:\nIP Address: $PUBLIC_IP\nUsername: Administrator\nPassword: $ADMIN_PASSWORD\nTotal time taken: $MINUTES minutes and $SECONDS seconds."

# Output the RDP details
echo "RDP setup complete!"
echo "Connect to your Windows VM using the following details:"
echo "IP Address: $PUBLIC_IP"
echo "Username: Administrator"
echo "Password: $ADMIN_PASSWORD"
