#!/jbin/binpack/bin/bash
binpack=/jbin/binpack

# uicache loader app
$binpack/bin/rm -rf /var/.palera1n/loader.app
$binpack/usr/bin/uicache -p /Applications/Pogo.app/

# remount r/w
/sbin/mount -uw /
/sbin/mount -uw /private/preboot/

# lauching daemon automatically
/usr/bin/launchctl load /Library/LaunchDaemons/

# update repo 
if [ -f /usr/bin/apt ]; then
  apt-get update
fi

# activating tweaks
/etc/rc.d/substitute-launcher

# respring
$binpack/usr/bin/uicache -a
$binpack/usr/bin/killall -9 SpringBoard

echo "[post.sh] done"
exit
