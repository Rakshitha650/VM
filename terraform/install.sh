#!/bin/bash
set -e

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
