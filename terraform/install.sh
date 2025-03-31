#!/bin/bash

# Check for required arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <VNC_USERNAME> <VNC_PASSWORD>"
    exit 1
fi

VNC_USERNAME=$1
VNC_PASSWORD=$2

# Log file setup
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

# Detect user home directory
USER_HOME=$(eval echo ~$VNC_USERNAME)

echo "[ VNC User ]: $VNC_USERNAME"
echo "[ User Home Directory ]: $USER_HOME"

# Ensure the user exists
if ! id "$VNC_USERNAME" &>/dev/null; then
    echo "User '$VNC_USERNAME' does not exist. Creating user..."
    sudo useradd -m -s /bin/bash "$VNC_USERNAME"
    echo "$VNC_USERNAME:$VNC_PASSWORD" | sudo chpasswd
fi

# Update and upgrade system packages
echo "[ Updating System Packages ]"
sudo apt update -y && sudo apt upgrade -y

# Install necessary packages
echo "[ Installing Required Packages ]"
sudo apt install -y openjdk-11-jdk wireguard tightvncserver xfce4 xfce4-goodies ufw

# Enable IP forwarding for WireGuard
echo "[ Enabling IP Forwarding for WireGuard ]"
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Setup VNC
mkdir -p "$USER_HOME/.vnc"
echo -e "$VNC_PASSWORD\n$VNC_PASSWORD\nn" | sudo -u "$VNC_USERNAME" vncpasswd -f > "$USER_HOME/.vnc/passwd"
sudo chmod 600 "$USER_HOME/.vnc/passwd"
sudo chown -R "$VNC_USERNAME:$VNC_USERNAME" "$USER_HOME/.vnc"

# Configure VNC Startup Script
echo "[ Configuring VNC Startup Script ]"
VNC_STARTUP="$USER_HOME/.vnc/xstartup"
echo "#!/bin/bash" | sudo tee "$VNC_STARTUP"
echo "xrdb \$HOME/.Xresources" | sudo tee -a "$VNC_STARTUP"
echo "startxfce4 &" | sudo tee -a "$VNC_STARTUP"
sudo chmod +x "$VNC_STARTUP"
sudo chown "$VNC_USERNAME:$VNC_USERNAME" "$VNC_STARTUP"

# Start VNC Server
echo "[ Starting VNC Server ]"
sudo -u "$VNC_USERNAME" vncserver :1 || echo "VNC Server failed to start"
sleep 5  # Allow some time before restarting
sudo -u "$VNC_USERNAME" vncserver -kill :1 || echo "VNC Server was not running"
sudo -u "$VNC_USERNAME" vncserver :1

# Configure Firewall
echo "[ Configuring Firewall ]"
sudo ufw allow 5901/tcp
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Install JProfiler 13
JPROFILER_VERSION="13_0_1"
JPROFILER_URL="https://download.ej-technologies.com/jprofiler/jprofiler_linux_${JPROFILER_VERSION}.tar.gz"

if [ ! -f /opt/jprofiler/bin/jprofiler ]; then
    echo "[ Downloading JProfiler 13 ]"
    wget -O /tmp/jprofiler.tar.gz "$JPROFILER_URL"

    echo "[ Extracting JProfiler ]"
    sudo tar -xvzf /tmp/jprofiler.tar.gz -C /opt/

    echo "[ Creating JProfiler Symlink ]"
    sudo ln -sf /opt/jprofiler13/bin/jprofiler /usr/local/bin/jprofiler

    echo "[ Cleaning up temporary files ]"
    rm -f /tmp/jprofiler.tar.gz
fi

# Verification of Installed Packages
echo "[ Verifying Installed Packages ]"
REQUIRED_PKGS=("openjdk-11-jdk" "wireguard" "tightvncserver" "xfce4" "ufw")
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! dpkg -l | grep -q "$pkg"; then
        echo "Package $pkg is missing. Reinstalling..."
        sudo apt install -y "$pkg"
    fi
done

echo "[ Installation and Configuration Completed Successfully ]"
