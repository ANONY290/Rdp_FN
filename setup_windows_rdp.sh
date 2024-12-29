#!/bin/bash

# Constants
LOG_FILE="/var/log/rdp_setup.log"
DISK_PATH="/var/lib/libvirt/images/windows.qcow2"

# Function to log time and messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
    send_telegram_message "$1"
}

# Function to send message to Telegram bot
send_telegram_message() {
    local message=$1
    if [[ -n "$BOT_TOKEN" && -n "$USER_ID" ]]; then
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$USER_ID" \
        -d text="$message" || log "Failed to send message to Telegram."
    fi
}

# Function to handle errors
handle_error() {
    log "Error: $1. Exiting."
    exit 1
}

# Function to validate inputs
validate_input() {
    if [[ -z "$1" ]]; then
        handle_error "Mandatory input missing: $2"
    fi
}

# Function to clean up temporary files
cleanup() {
    log "Cleaning up temporary files..."
    rm -f windows.iso
    log "Cleanup complete."
}

# Log the start time
START_TIME=$(date +%s)
log "Script started."

# Prompt for inputs
read -p "Enter the URL to the Windows ISO file: " WIN_ISO_URL
read -p "Enter the amount of RAM for the VM (in MB, e.g., 4096): " RAM_SIZE
read -p "Enter the number of CPUs for the VM: " CPU_COUNT
read -s -p "Enter a password for the Windows administrator account: " ADMIN_PASSWORD
echo
read -p "Enter your Telegram Bot Token (optional): " BOT_TOKEN
read -p "Enter your Telegram User ID (optional): " USER_ID"

# Validate inputs
validate_input "$WIN_ISO_URL" "Windows ISO URL"
validate_input "$RAM_SIZE" "RAM size"
validate_input "$CPU_COUNT" "CPU count"
validate_input "$ADMIN_PASSWORD" "Administrator password"

# Notify Telegram updates
send_telegram_message "RDP setup script started. Updates will be sent here."

# Update and install required packages
log "Updating system and installing required packages..."
apt update && apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst wget curl sshpass || handle_error "Installing packages"
log "Required packages installed successfully."

# Create a network bridge if not exists
log "Checking and creating network bridge..."
if ! brctl show | grep -q br0; then
    cat <<EOF >/etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: yes
  bridges:
    br0:
      interfaces: [eth0]
      dhcp4: yes
EOF
    netplan apply || handle_error "Applying network configuration"
    log "Network bridge created successfully."
else
    log "Network bridge br0 already exists."
fi

# Download Windows ISO
log "Downloading Windows ISO..."
wget -O windows.iso "$WIN_ISO_URL" || handle_error "Downloading Windows ISO"
log "Windows ISO downloaded successfully."

# Create a virtual disk for Windows
log "Creating virtual disk..."
qemu-img create -f qcow2 "$DISK_PATH" 40G || handle_error "Creating virtual disk"
log "Virtual disk created successfully."

# Create and start the VM to install Windows
log "Starting VM installation..."
virt-install \
  --name windows11 \
  --ram "$RAM_SIZE" \
  --disk path="$DISK_PATH",format=qcow2 \
  --vcpus "$CPU_COUNT" \
  --os-type windows \
  --os-variant win10 \
  --network bridge=br0 \
  --graphics vnc \
  --cdrom windows.iso || handle_error "Starting VM installation"
log "VM installation started successfully."

# Prompt user to complete installation manually
log "Please complete the Windows installation manually. Press Enter to continue after completion."
read -p ""

# Enable RDP on Windows
log "Enabling RDP on Windows..."
sshpass -p "$ADMIN_PASSWORD" ssh Administrator@localhost <<EOF
powershell.exe -Command "
    Enable-PSRemoting -Force;
    Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name 'AllowRemoteRPC' -Value 1;
    Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name 'fDenyTSConnections' -Value 0;
    Restart-Service -Name 'TermService'"
EOF || handle_error "Enabling RDP"
log "RDP enabled successfully."

# Get the public IP of the VPS
PUBLIC_IP=$(curl -s ifconfig.me)
log "Public IP: $PUBLIC_IP"

# Cleanup temporary files
cleanup

# Calculate total time taken
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
MINUTES=$((TOTAL_TIME / 60))
SECONDS=$((TOTAL_TIME % 60))
log "Script completed in $MINUTES minutes and $SECONDS seconds."

# Send RDP details to Telegram
send_telegram_message "RDP setup complete! Connect to your Windows VM:\nIP Address: $PUBLIC_IP\nUsername: Administrator\nPassword: [Hidden]\nTotal time taken: $MINUTES minutes and $SECONDS seconds."

# Display RDP details
echo "RDP setup complete!"
echo "Connect to your Windows VM:"
echo "IP Address: $PUBLIC_IP"
echo "Username: Administrator"
echo "Password: [Hidden for security]"
