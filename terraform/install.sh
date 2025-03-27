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

# Install VNC Server
echo "[ Installing TightVNC Server ]"
sudo apt install -y tightvncserver

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
