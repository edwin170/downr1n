#!/usr/bin/env bash
# Futurerestore/irecovery linux fix script made by @Cryptiiiic
# Supported Distros: archlinux, ubuntu, debian
set -e
pacman=0
aptget=0
dnf=0

if [ "$EUID" -ne 0 ]
  then
  echo "-1: Please run as root"
  exit -1
fi

if [[ -f "/etc/fedora-release" ]]
then
    echo "Fedora detected installing ca-certs..."
    echo "Done!"
fi

echo "Attemping linux usb fixes please wait..."

if [[ $(which pacman 2>/dev/null) ]]
then
    pacman=1
elif [[ $(which apt-get 2>/dev/null) ]]
then
    aptget=1
elif [[ $(which dnf 2>/dev/null) ]]
then
    dnf=1
else
    echo "-2: Linux Distro not supported!"
    exit -2
fi

if [[ "$(expr $pacman)" -gt '0' ]]
then
    if [[ -f "/etc/arch-release" ]]
    then
        echo "Arch Linux Detected!"
    	sudo pacman -Syy --needed --noconfirm >/dev/null 2>/dev/null
    	sudo pacman -S --needed --noconfirm udev usbmuxd >/dev/null 2>/dev/null 
    	sudo systemctl enable systemd-udevd usbmuxd --now 2>/dev/null
        echo "QUNUSU9OPT0iYWRkIiwgU1VCU1lTVEVNPT0idXNiIiwgQVRUUntpZFZlbmRvcn09PSIwNWFjIiwgQVRUUntpZFByb2R1Y3R9PT0iMTIyWzI3XXwxMjhbMC0zXSIsIE9XTkVSPSJyb290IiwgR1JPVVA9InN0b3JhZ2UiLCBNT0RFPSIwNjYwIgoKQUNUSU9OPT0iYWRkIiwgU1VCU1lTVEVNPT0idXNiIiwgQVRUUntpZFZlbmRvcn09PSIwNWFjIiwgQVRUUntpZFByb2R1Y3R9PT0iMTMzOCIsIE9XTkVSPSJyb290IiwgR1JPVVA9InN0b3JhZ2UiLCBNT0RFPSIwNjYwIgo=" | base64 -d | sudo tee /usr/lib/udev/rules.d/39-libirecovery.rules >/dev/null
    else
        echo "-3: Linux Distro not supported!"
        exit -3
    fi
elif [[ "$(expr $aptget)" -gt '0' ]]
then
    if [[ -f "/etc/lsb-release" || -f "/etc/debian_version" ]]
    then
        echo "Ubuntu or Debian Detected!"
        sudo apt-get update -qq >/dev/null 2>/dev/null
        sudo apt-get install -yqq usbmuxd udev >/dev/null 2>/dev/null
        sudo systemctl enable udev >/dev/null 2>/dev/null || true
        sudo systemctl enable systemd-udevd >/dev/null 2>/dev/null || true
        sudo systemctl enable usbmuxd >/dev/null 2>/dev/null || true
        sudo systemctl restart udev >/dev/null 2>/dev/null
        sudo systemctl restart systemd-udevd >/dev/null 2>/dev/null
        sudo systemctl restart usbmuxd >/dev/null 2>/dev/null
        echo "QUNUSU9OPT0iYWRkIiwgU1VCU1lTVEVNPT0idXNiIiwgQVRUUntpZFZlbmRvcn09PSIwNWFjIiwgQVRUUntpZFByb2R1Y3R9PT0iMTIyWzI3XXwxMjhbMC0zXSIsIE9XTkVSPSJ1c2JtdXgiLCBHUk9VUD0icGx1Z2RldiIsIE1PREU9IjA2NjAiCgpBQ1RJT049PSJhZGQiLCBTVUJTWVNURU09PSJ1c2IiLCBBVFRSe2lkVmVuZG9yfT09IjA1YWMiLCBBVFRSe2lkUHJvZHVjdH09PSIxMzM4IiwgT1dORVI9InVzYm11eCIsIEdST1VQPSJwbHVnZGV2IiwgTU9ERT0iMDY2MCIKCg==" | base64 -d | sudo tee /usr/lib/udev/rules.d/39-libirecovery.rules >/dev/null
    else
        echo "-4: Linux Distro not supported!"
        exit -4
    fi
else
    if [[ -f "/etc/fedora-release" ]]
    then
        echo "Fedora Detected!"
    	sudo dnf install -y usbmuxd udev systemd ca-certificates >/dev/null 2>/dev/null
	sudo ln -sf /etc/pki/tls/certs/ca-bundle.crt /etc/pki/tls/certs/ca-certificates.crt >/dev/null 2>/dev/null
    	sudo systemctl enable --now systemd-udevd usbmuxd >/dev/null 2>/dev/null
	echo "QUNUSU9OPT0iYWRkIiwgU1VCU1lTVEVNPT0idXNiIiwgQVRUUntpZFZlbmRvcn09PSIwNWFjIiwgQVRUUntpZFByb2R1Y3R9PT0iMTIyWzI3XXwxMjhbMC0zXSIsIE9XTkVSPSJyb290IiwgR1JPVVA9InVzYm11eGQiLCBNT0RFPSIwNjYwIiwgVEFHKz0idWFjY2VzcyIKCkFDVElPTj09ImFkZCIsIFNVQlNZU1RFTT09InVzYiIsIEFUVFJ7aWRWZW5kb3J9PT0iMDVhYyIsIEFUVFJ7aWRQcm9kdWN0fT09IjEzMzgiLCBPV05FUj0icm9vdCIsIEdST1VQPSJ1c2JtdXhkIiwgTU9ERT0iMDY2MCIsIFRBRys9InVhY2Nlc3MiCgoK" | base64 -d | sudo tee /usr/lib/udev/rules.d/39-libirecovery.rules >/dev/null 2>/dev/null
    fi
fi
sudo chown root:root /usr/lib/udev/rules.d/39-libirecovery.rules >/dev/null 2>/dev/null 
sudo chmod 0644 /usr/lib/udev/rules.d/39-libirecovery.rules >/dev/null 2>/dev/null 
sudo udevadm control --reload-rules >/dev/null 2>/dev/null 
echo "Done!"
echo "Please unplug and replug your iDevice!"
