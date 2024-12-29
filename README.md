

# RDP Setup Script

![RDP Setup](https://img.shields.io/badge/RDP-Setup-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Version](https://img.shields.io/badge/Version-1.0-brightgreen)

## Overview
This repository contains a script to set up a Windows Remote Desktop Protocol (RDP) virtual machine on a VPS. The script installs necessary packages, configures network settings, downloads a Windows ISO, creates a virtual disk, and sets up the VM. It also integrates with a Telegram bot to provide real-time updates and notifications throughout the process.

## Prerequisites
- A VPS with root access
- A Telegram bot and user ID for receiving updates
- Git installed on the VPS

## Features
- **Automated Setup**: Automatically sets up the entire RDP environment.
- **Real-Time Updates**: Get real-time updates on your Telegram bot about the progress of each step.
- **Error Handling**: Immediate notifications for any errors encountered during the process.
- **Customizable**: Configure the amount of RAM, number of CPUs, and admin password.

## Setup Instructions

### Step 1: Clone the Repository
Clone this repository to your VPS:
```bash
git clone https://github.com/ANONY290/Rdp_FN.git
cd Rdp_FN
```

### Step 2: Make the Script Executable
Make the setup script executable:
```bash
chmod +x setup_windows_rdp.sh
```

### Step 3: Run the Script
Run the script to start the setup process:
```bash
nohup ./setup_windows_rdp.sh > output.log 2>&1 &
```

### Step 4: Monitor the Logs
Open another terminal window to monitor the logs and ensure everything is progressing smoothly:
```bash
tail -f output.log
```

### Step 5: Provide Required Inputs
When prompted, provide the following inputs:
- URL to the Windows ISO file
- Amount of RAM for the VM (in MB, e.g., 4096)
- Number of CPUs for the VM
- Password for the Windows administrator account
- Your Telegram Bot Token
- Your Telegram User ID

### Step 6: Receive Real-Time Updates
- **Real-Time Updates**: You will receive real-time updates on your Telegram bot about the progress of each step.
- **Error Handling**: Any errors encountered will be reported to you on Telegram.
- **Completion**: Once the setup is complete, you will receive the RDP connection details and the total time taken on your Telegram bot.

## Advanced Features
### Telegram Integration
- **Bot Token**: Securely input your Telegram bot token to receive updates.
- **User ID**: Configure your Telegram user ID for personalized notifications.

### Network Configuration
- **Bridge Creation**: Automatically creates and configures a network bridge for the VM.

### Error Notifications
- **Detailed Logs**: Comprehensive error messages to assist in troubleshooting.
- **Immediate Alerts**: Get notified instantly if any step encounters an issue.

### Custom Resource Allocation
- **RAM & CPU Configuration**: Customize the virtual machine's RAM and CPU settings according to your needs.

## Screenshots
![Real-Time Telegram Updates](https://via.placeholder.com/500x300.png?text=Real-Time+Telegram+Updates)
![Setup Progress](https://via.placeholder.com/500x300.png?text=Setup+Progress)

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Created By
**Anuj**

## Acknowledgments
Special thanks to the contributors and the open-source community for their valuable tools and libraries.
