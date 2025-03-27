#!/bin/bash

# Set log file path
LOG_FILE="/tmp/performance-vm-$(date +"%d-%h-%Y-%H-%M").log"
echo "[ Log File ]: $LOG_FILE"

# Redirect stdout and stderr to log file
exec > >(tee -a "$LOG_FILE") 2>&1

# Set strict error handling
set -e
set -o errexit   # Exit on any command failure
set -o nounset   # Exit on uninitialized variable usage
set -o errtrace  # Trace ERR signals in functions and subshells
set -o pipefail  # Catch errors in pipeline chains

# Get the actual logged-in user (not root)
USER_NAME=$(logname)
USER_HOME=$(eval echo ~$USER_NAME)

echo "[ Detected User ]: $USER_NAME"
echo "[ User Home Directory ]: $USER_HOME"

# Update and upgrade system packages
echo "[ Updating System Packages ]"
sudo apt update -y && sudo apt upgrade -y

# Install Java 11
echo "[ Installing Java 11 ]"
sudo apt install -y openjdk-11-jdk
java -version

# Install WireGuard
echo "[ Installing WireGuard ]"
sudo apt install -y wireguard

# Enable IP forwarding for WireGuard
echo "[ Enabling IP Forwarding for WireGuard ]"
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Install VNC Server and XFCE4
echo "[ Installing TightVNC Server and XFCE4 ]"
sudo apt install -y tightvncserver xfce4 xfce4-goodies

# Start VNC Server as the logged-in user to set an initial password
echo "[ Setting VNC Password ]"
sudo -u $USER_NAME vncserver
sudo -u $USER_NAME vncserver -kill :1  # Kill the first session to configure it

# Configure VNC Startup Script
echo "[ Configuring VNC Startup Script ]"
sudo -u $USER_NAME bash -c "cat <<EOF > $USER_HOME/.vnc/xstartup
#!/bin/bash
xrdb \$HOME/.Xresources
startxfce4 &
EOF"

sudo -u $USER_NAME chmod +x $USER_HOME/.vnc/xstartup

# Restart VNC Server
echo "[ Restarting VNC Server ]"
sudo -u $USER_NAME vncserver :1

# Configure Firewall
echo "[ Configuring Firewall for VNC and SSH ]"
sudo ufw allow 5901/tcp  # Allow VNC traffic
sudo ufw allow 22/tcp    # Allow SSH traffic
sudo ufw allow 80/tcp    # Allow HTTP (Optional)
sudo ufw allow 443/tcp   # Allow HTTPS (Optional)

# Enable and start the firewall
echo "[ Enabling Firewall ]"
sudo ufw enable

# Restart VNC Server
echo "[ Restarting VNC Server ]"
sudo -u $USER_NAME vncserver :1

# Install JProfiler 13
JPROFILER_VERSION="13_0_1"
JPROFILER_URL="https://download.ej-technologies.com/jprofiler/jprofiler_linux_${JPROFILER_VERSION}.tar.gz"

echo "[ Downloading JProfiler 13 ]"
wget -O /tmp/jprofiler.tar.gz "$JPROFILER_URL"

echo "[ Extracting JProfiler ]"
sudo tar -xvzf /tmp/jprofiler.tar.gz -C /opt/

echo "[ Creating JProfiler Symlink ]"
sudo ln -sf /opt/jprofiler13/bin/jprofiler /usr/local/bin/jprofiler

# Cleanup
echo "[ Cleaning up temporary files ]"
rm -f /tmp/jprofiler.tar.gz

echo "[ Installation Complete! ]"
