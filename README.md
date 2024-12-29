# Windows RDP Setup Script

This repository contains a script to set up Windows 12 with Remote Desktop Protocol (RDP) on a VPS. The script automates the process of installing Windows, configuring RDP, and providing the necessary login details.

## Features
- Automates the installation of Windows 12 on a VPS.
- Configures Remote Desktop Protocol (RDP) for remote access.
- Prompts the user for necessary inputs during execution.
- Provides the IP address, username, and password for RDP login.

## Prerequisites
- A VPS with root access (e.g., DigitalOcean Droplet).
- SSH access to the VPS.
- Git installed on the VPS.

## Usage

1. **Clone the Repository**:
    ```bash
    git clone https://github.com/ANONY290/Rdp_FN.git
    ```

2. **Navigate to the Script Directory**:
    ```bash
    cd Rdp_FN
    ```

3. **Make the Script Executable**:
    ```bash
    chmod +x setup_windows_rdp.sh
    ```

4. **Run the Script**:
    ```bash
    ./setup_windows_rdp.sh
    ```

5. **Follow the Prompts**:
    - Enter the URL to the Windows ISO file.
    - Enter the amount of RAM for the VM.
    - Enter the number of CPUs for the VM.
    - Enter a password for the Windows administrator account.

6. **Complete Windows Installation**:
    - Follow the on-screen instructions to complete the Windows installation.

7. **Access RDP**:
    - After the installation is complete, the script will provide the IP address, username, and password for RDP login.

## Example
Here’s an example of how to run the script:
```bash
git clone https://github.com/ANONY290/Rdp_FN.git
cd Rdp_FN
chmod +x setup_windows_rdp.sh
./setup_windows_rdp.sh
