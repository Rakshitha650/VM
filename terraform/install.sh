#!/bin/bash

# Log file path
echo "[ Set Log File ] : "
LOG_FILE="/tmp/performance-vm-$( date +"%d-%h-%Y-%H-%M" ).log"

# Redirect stdout and stderr to log file
exec > >(tee -a "$LOG_FILE") 2>&1

# Set commands for error handling.
set -e
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value
set -o nounset   ## set -u : exit the script if you try to use an uninitialized variable
set -o errtrace  # Trace ERR through 'time command' and other functions
set -o pipefail  # Trace ERR through pipes

# Update package list and install dependencies
sudo apt update -y && sudo apt upgrade -y

# Install Java 11
sudo apt install -y openjdk-11-jdk

# Install WireGuard
sudo apt install -y wireguard

# Install VNC Server
sudo apt install -y tightvncserver

# Download and install JProfiler 13 (Update the link if needed)
wget -O /tmp/jprofiler.tar.gz https://download.ej-technologies.com/jprofiler/jprofiler_linux_13_0_1.tar.gz
tar -xvzf /tmp/jprofiler.tar.gz -C /opt/
ln -s /opt/jprofiler13/bin/jprofiler /usr/local/bin/jprofiler

echo "Installation complete!"
