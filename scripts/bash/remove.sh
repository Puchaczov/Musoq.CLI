#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

# Ensure script is run with bash
if [ -z "$BASH_VERSION" ]; then
  echo "Please run this script with bash instead of sh."
  exit 1
fi

DEBUG=0

# Parse options: -d for debug
while getopts "d" opt; do
  case $opt in
    d)
      DEBUG=1
      ;;
    *)
      echo "Usage: $0 [-d]"
      exit 1
      ;;
  esac
done

[ $DEBUG -eq 1 ] && set -x

INSTALL_DIR="/opt/Musoq"

echo "Stopping any running Musoq instances..."
pkill -f Musoq 2>/dev/null || true
sleep 5

if [ -d "$INSTALL_DIR" ]; then
  echo "Removing installation directory: $INSTALL_DIR"
  rm -rf "$INSTALL_DIR"
else
  echo "Installation directory $INSTALL_DIR does not exist."
fi

if [ -L "/usr/local/bin/Musoq" ]; then
  echo "Removing symlink /usr/local/bin/Musoq"
  rm "/usr/local/bin/Musoq"
else
  echo "Symlink /usr/local/bin/Musoq does not exist."
fi

if [ -L "/usr/local/bin/musoq" ]; then
  echo "Removing symlink /usr/local/bin/musoq"
  rm "/usr/local/bin/musoq"
else
  echo "Symlink /usr/local/bin/musoq does not exist."
fi

if [ -f "/etc/profile.d/musoq.sh" ]; then
  echo "Removing profile script /etc/profile.d/musoq.sh"
  rm "/etc/profile.d/musoq.sh"
else
  echo "Profile script /etc/profile.d/musoq.sh not found."
fi

echo "Musoq removal completed."
