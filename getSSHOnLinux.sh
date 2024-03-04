#!/bin/bash 


sudo systemctl stop usbmuxd
sudo usbmuxd -p -f 1>/dev/null
