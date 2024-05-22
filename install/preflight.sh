#!/usr/bin/env bash


# Check if swap is needed
SWAP_MOUNTED=$(cat /proc/swaps | tail -n+2)
SWAP_IN_FSTAB=$(grep "swap" /etc/fstab)
ROOT_IS_BTRFS=$(grep "\/ .*btrfs" /proc/mounts)
TOTAL_PHYSICAL_MEM=$(head -n 1 /proc/meminfo | awk '{print $2}')
AVAILABLE_DISK_SPACE=$(df / --output=avail | tail -n 1)

if [ -z "$SWAP_MOUNTED" ] && [ -z "$SWAP_IN_FSTAB" ] && [ ! -e /swapfile ] && [ -z "$ROOT_IS_BTRFS" ] && [ $TOTAL_PHYSICAL_MEM -lt 1536000 ] && [ $AVAILABLE_DISK_SPACE -gt 5242880 ]; then
  echo "Adding a swap file to the system..."

  # Allocate and activate the swap file. Allocate in 1KB chunks
  # doing it in one go could fail on low memory systems
  sudo fallocate -l 3G /swapfile
  if [ -e /swapfile ]; then
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
  fi

  # Check if swap is mounted then activate on boot
  if swapon -s | grep -q "/swapfile"; then
    echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
  else
    echo "ERROR: Swap allocation failed"
  fi
fi

ARCHITECTURE=$(uname -m)
if [ "$ARCHITECTURE" != "x86_64" ]; then
  if [ -z "$ARM" ]; then
    echo "Yiimpool Installer only supports x86_64 and will not work on any other architecture, like ARM or 32-bit OS."
    echo "Your architecture is $ARCHITECTURE"
    exit 1
  fi
fi
