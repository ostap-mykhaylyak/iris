#!/bin/bash

# Check if the script is being run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run with root privileges. Exiting."
  exit 1
fi

# Remove any existing LXD installation
apt remove --purge -y lxd lxd-client

# Update the system
apt update && apt upgrade -y

# Install the Snap package manager
apt install -y snapd

# Install LXD using Snap with the latest stable channel
snap install lxd --channel=latest/stable

# Restart the LXD service
systemctl restart snap.lxd.daemon

# Wait for LXD to fully start
sleep 5

# Create a 10GB virtual disk (adjust size as needed)
DISK_PATH="/path/to/virtual_disk.img"
DISK_SIZE="10G"
truncate -s $DISK_SIZE $DISK_PATH

# Configure the ZFS pool on the virtual disk
POOL_NAME="lxdpool"
zpool create $POOL_NAME $DISK_PATH

# Configure LXD with the ZFS backend
cat <<EOL | lxd init --preseed
config:
  storage_pools:
  - name: default
    driver: zfs
    config:
      source: $POOL_NAME
EOL

# Add the current user to the lxd group
usermod -aG lxd $USER

echo "LXD installed and configured successfully with the latest stable version via Snap and ZFS filesystem."