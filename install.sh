#!/bin/bash

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exec sudo "$0" "$@"
    exit
fi

# Detect operating system - Archlinux or Debian/Ubuntu
if [ -f /etc/arch-release ]; then
    OS="Archlinux"
elif [ -f /etc/debian_version ]; then
    OS="Debian/Ubuntu"
else
    OS="Unsupported OS - this script only supports Archlinux and Debian/Ubuntu"
fi

echo "$OS detected"

# Install dependencies based on OS
case $OS in
    "Archlinux")
        sudo pacman -S --noconfirm git cmake base-devel openssl zlib pcre pkgconf c-ares re2
        ;;
    "Debian/Ubuntu")
        sudo apt-get update
        sudo apt-get install -y git cmake build-essential libssl-dev zlib1g-dev libpcre3-dev pkg-config libc-ares-dev libre2-dev
        ;;
    *)
        echo "Unsupported OS"
        exit 1
        ;;
esac

# Clone nginx source code
git clone https://github.com/nginx/nginx.git



