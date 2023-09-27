#!/usr/bin/env bash

mkdir -p logs
mkdir -p boot
set -e

log="last".log
cd logs
touch "$log"
cd ..

{

echo "[*] Command ran:`if [ $EUID = 0 ]; then echo " sudo"; fi` ./downr1n.sh $@"



# =========
# Variables
# =========
ipsw=$(find ipsw/ -name "*.ipsw") # put your ipsw 
version="3.0"
os=$(uname)
dir="$(pwd)/binaries/$os"
max_args=2
arg_count=0
extractedIpsw="ipsw/extracted/"

if [ ! -d "ramdisk/" ]; then
    git clone https://github.com/dualra1n/ramdisk.git --depth 1
fi

# =========
# Functions
# =========
remote_cmd() {
    sleep 1
    "$dir"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost "$@"
    sleep 1
}

remote_cp() {
    sleep 1
    "$dir"/sshpass -p 'alpine' scp -r -o StrictHostKeyChecking=no -P2222 $@

    sleep 1
}

step() {
    rm -f .entered_dfu
    for i in $(seq "$1" -1 0); do
        if [[ -e .entered_dfu ]]; then
            rm -f .entered_dfu
            break
        fi
        if [[ $(get_device_mode) == "dfu" || ($1 == "10" && $(get_device_mode) != "none") ]]; then
            touch .entered_dfu
        fi &
        printf '\r\e[K\e[1;36m%s (%d)' "$2" "$i"
        sleep 1
    done
    printf '\e[0m\n'
}

print_help() {
    cat << EOF
Usage: $0 [Options] [ subcommand | iOS version which are you]. put your ipsw in the directory ipsw/
iOS 15 - 14.0 downgrade tool ./downr1n --downgrade 15.7 (the ios of your device) ipsw 

Options:
    --downgrade         Downgrade your device to iOS 14/15 tethered.
    --dfuhelper         A helper tool to transition A11 devices from recovery mode to DFU mode.
    --jailbreak         Jailbreak with pogo. Usage: ./downr1n.sh --jailbreak 14.8.
    --taurine           Jailbreak with taurine. Usage: './downr1n.sh --jailbreak 14.3 --taurine'.
    --boot              Boots the device.
    --dont-restore      Avoids using futurerestore, this can be used to only create boot files as opposed to restoring to that version. Example: '--downgrade 14.3 --dont-restore'.
    --fixBoot           Boots the device using fsboot.
    --debug             Runs the script in Debug Mode.

Subcommands:
    clean               clean the downgrade tool in order to downgrade again.



EOF
}

parse_opt() {
    case "$1" in
        --)
            no_more_opts=1
            ;;
        --downgrade)
            downgrade=1
            ;;
        --boot)
            boot=1
            ;;
        --jailbreak)
            jailbreak=1
            ;;
        --taurine)
            taurine=1
            ;;
        --fixBoot)
            fixBoot=1
            ;;
        --dont-restore)
            dontRestore=1
            ;;
        --localboot)
            local=1
            ;;
        --fsboot)
            fsboot=1
            ;;
        --dfuhelper)
            dfuhelper=1
            ;;
        --debug)
            debug=1
            ;;
        --help)
            print_help
            exit 0
            ;;
        *)
            echo "[-] Unknown option $1. Use $0 --help for help."
            exit 1;
    esac
}

parse_arg() {
    arg_count=$((arg_count + 1))
    case "$1" in
        dfuhelper)
            dfuhelper=1
            ;;
        clean)
            clean=1
            ;;
        *)
            version="$1"
            ;;
    esac
}

parse_cmdline() {
    for arg in $@; do
        if [[ "$arg" == --* ]] && [ -z "$no_more_opts" ]; then
            parse_opt "$arg";
        elif [ "$arg_count" -lt "$max_args" ]; then
            parse_arg "$arg";
        else
            echo "[-] Too many arguments. Use $0 --help for help.";
            exit 1;
        fi
    done
}

recovery_fix_auto_boot() {
    "$dir"/irecovery -c "setenv auto-boot true"
    "$dir"/irecovery -c "saveenv"
}

_info() {
    if [ "$1" = 'recovery' ]; then
        echo $("$dir"/irecovery -q | grep "$2" | sed "s/$2: //")
    elif [ "$1" = 'normal' ]; then
        echo $("$dir"/ideviceinfo | grep "$2: " | sed "s/$2: //")
    fi
}

_pwn() {
    pwnd=$(_info recovery PWND)
    if [ "$pwnd" = "" ]; then
        echo "[*] Pwning device"
        "$dir"/gaster pwn
        sleep 2
        #"$dir"/gaster reset
        #sleep 1
    fi
}

_reset() {
        echo "[*] Resetting DFU state"
        "$dir"/gaster reset
}

get_device_mode() {
    if [ "$os" = "Darwin" ]; then
        sp="$(system_profiler SPUSBDataType 2> /dev/null)"
        apples="$(printf '%s' "$sp" | grep -B1 'Vendor ID: 0x05ac' | grep 'Product ID:' | cut -dx -f2 | cut -d' ' -f1 | tail -r)"
    elif [ "$os" = "Linux" ]; then
        apples="$(lsusb | cut -d' ' -f6 | grep '05ac:' | cut -d: -f2)"
    fi
    local device_count=0
    local usbserials=""
    for apple in $apples; do
        case "$apple" in
            12a8|12aa|12ab)
            device_mode=normal
            device_count=$((device_count+1))
            ;;
            1281)
            device_mode=recovery
            device_count=$((device_count+1))
            ;;
            1227)
            device_mode=dfu
            device_count=$((device_count+1))
            ;;
            1222)
            device_mode=diag
            device_count=$((device_count+1))
            ;;
            1338)
            device_mode=checkra1n_stage2
            device_count=$((device_count+1))
            ;;
            4141)
            device_mode=pongo
            device_count=$((device_count+1))
            ;;
        esac
    done
    if [ "$device_count" = "0" ]; then
        device_mode=none
    elif [ "$device_count" -ge "2" ]; then
        echo "[-] Please attach only one device" > /dev/tty
        kill -30 0
        exit 1;
    fi
    if [ "$os" = "Linux" ]; then
        usbserials=$(cat /sys/bus/usb/devices/*/serial)
    elif [ "$os" = "Darwin" ]; then
        usbserials=$(printf '%s' "$sp" | grep 'Serial Number' | cut -d: -f2- | sed 's/ //')
    fi
    if grep -qE '(ramdisk tool|SSHRD_Script) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{1,2} [0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}' <<< "$usbserials"; then
        device_mode=ramdisk
    fi
    echo "$device_mode"
}

_wait() {
    if [ "$(get_device_mode)" != "$1" ]; then
        echo "[*] Waiting for device in $1 mode"
    fi

    while [ "$(get_device_mode)" != "$1" ]; do
        sleep 1
    done

    if [ "$1" = 'recovery' ]; then
        recovery_fix_auto_boot;
    fi
}

_dfuhelper() {
    if [ "$(get_device_mode)" = "dfu" ]; then
        echo "[*] Device already on dfu mode"
        return;
    fi

    local step_one;
    deviceid=$( [ -z "$deviceid" ] && _info normal ProductType || echo $deviceid )
    if [[ "$1" = 0x801* && "$deviceid" != *"iPad"* ]]; then
        step_one="Hold volume down + side button"
    else
        step_one="Hold home + power button"
    fi
    echo "[*] To get into DFU mode, you will be guided through 2 steps:"
    echo "[*] Press any key when ready for DFU mode"
    read -n 1 -s
    step 3 "Get ready"
    step 4 "$step_one" &
    sleep 3
    "$dir"/irecovery -c "reset" &
    sleep 1
    if [[ "$1" = 0x801* && "$deviceid" != *"iPad"* ]]; then
        step 10 'Release side button, but keep holding volume down'
    else
        step 10 'Release power button, but keep holding home button'
    fi
    sleep 1

    if [ "$(get_device_mode)" = "recovery" ]; then
        _dfuhelper
    fi

    if [ "$(get_device_mode)" = "dfu" ]; then
        echo "[*] Device entered DFU!"
    else
        echo "[-] Device did not enter DFU mode, try again"
       _detect
       _dfuhelper
    fi
}

usage() {
    echo "Please answer with YES or NO (case-insensitive)."
}

ask() {
    echo "Do you want to activate the iBoot localboot path? YES or NO."
    echo "Activating this path can help avoid a lot of problems and is generally more stable."
    echo "If you activate it, you will need to use --boot again after it finishes to boot with localboot."
    echo "If localboot breaks your boot process (like you can't boot), please execute ./downr1n.sh --downgrade (version) --dont-restore to fix the boot files."
}

_kill_if_running() {
    if (pgrep -u root -x "$1" &> /dev/null > /dev/null); then
        # yes, it's running as root. kill it
        sudo killall $1 &> /dev/null
    else
        if (pgrep -x "$1" &> /dev/null > /dev/null); then
            killall $1 &> /dev/null
        fi
    fi
}


_runFuturerestore() {
    read -p "Press ENTER to continue with futurerestore, your device will start restoring <-"
    rm -rf /tmp/futurerestore/
    "$dir"/futurerestore -t blobs/"$deviceid"-"$version".shsh2 --use-pwndfu --skip-blob \
    --rdsk work/rdsk.im4p --rkrn work/krnl.im4p \
    --latest-sep "$HasBaseband" "$ipsw"
}

_detect() {
    # Get device's iOS version from ideviceinfo if in normal mode
    echo "[*] Waiting for devices"
    while [ "$(get_device_mode)" = "none" ]; do
        sleep 1;
    done
    echo $(echo "[*] Detected $(get_device_mode) mode device" | sed 's/dfu/DFU/')

    if grep -E 'pongo|checkra1n_stage2|diag' <<< "$(get_device_mode)"; then
        echo "[-] Detected device in unsupported mode '$(get_device_mode)'"
        exit 1;
    fi

    if [ "$(get_device_mode)" != "normal" ] && [ -z "$version" ] && [ "$dfuhelper" != "1" ]; then
        echo "[-] You must pass the version your device is on when not starting from normal mode"
        exit
    fi

    if [ "$(get_device_mode)" = "ramdisk" ]; then
        # If a device is in ramdisk mode, perhaps iproxy is still running?
        _kill_if_running iproxy
        echo "[*] Rebooting device in SSH Ramdisk"
        if [ "$os" = 'Linux' ]; then
            sudo "$dir"/iproxy 2222 22 >/dev/null &
        else
            "$dir"/iproxy 2222 22 >/dev/null &
        fi
        sleep 1
        remote_cmd "/sbin/reboot"
        _kill_if_running iproxy
        _wait recovery
    fi

    if [ "$(get_device_mode)" = "normal" ]; then
        version=${version:-$(_info normal ProductVersion)}
        arch=$(_info normal CPUArchitecture)
        if [ "$arch" = "arm64e" ]; then
            echo "[-] dualboot doesn't, and never will, work on non-checkm8 devices"
            exit
        fi
        echo "Hello, $(_info normal ProductType) on $version!"

        echo "[*] Switching device into recovery mode..."
        "$dir"/ideviceenterrecovery $(_info normal UniqueDeviceID)
        _wait recovery
    fi
}

_boot() {
    _pwn
    sleep 1
    _reset
    sleep 1
    
    echo "[*] Booting device"

    "$dir"/irecovery -f "blobs/"$deviceid"-"$version".shsh2"
    sleep 1

    if [[ ! "$cpid" == *"0x801"* ]]; then
        "$dir"/irecovery -f "boot/${deviceid}/iBSS.img4"
        sleep 1
    fi

    "$dir"/irecovery -f "boot/${deviceid}/iBEC.img4"
    sleep 3
    
    if [ "$local" = "1" ]; then 
        echo "booting ..."
        echo "Your device should now be booting into the iOS using localboot! :)"
        exit;
    fi

    if [[ "$cpid" == *"0x801"* ]]; then
        "$dir"/irecovery -c "go"
        sleep 2
    else
       "$dir"/irecovery -c "bootx"
        sleep 2
    
    fi


    "$dir"/irecovery -f "boot/${deviceid}/devicetree.img4"
    sleep 1 

    "$dir"/irecovery -c "devicetree"
    sleep 1
    
    "$dir"/irecovery -v -f "boot/${deviceid}/trustcache.img4"    

    "$dir"/irecovery -c "firmware"
    sleep 1

    "$dir"/irecovery -f "boot/${deviceid}/kernelcache.img4" 
    sleep 1

    "$dir"/irecovery -c "$(if [ ! "$fsboot" = "1" ]; then echo "bootx"; else echo "fsboot"; fi)"
    exit;
}

_exit_handler() {
    if [ "$os" = "Darwin" ]; then
        killall -CONT AMPDevicesAgent AMPDeviceDiscoveryAgent MobileDeviceUpdater || true
    fi

    [ $? -eq 0 ] && exit
    echo "[-] An error occurred"

    if [ -d "logs" ]; then
        cd logs
        mv "$log" FAIL_${log}
        cd ..
    fi

    echo "[*] A failure log has been made. If you're going ask for help, please attach the latest log."
}
trap _exit_handler EXIT


# ============
# Dependencies
# ============

if [ "$os" = "Linux"  ]; then
    chmod +x getSSHOnLinux.sh
    ./getSSHOnLinux.sh &
fi

if [ "$os" = 'Linux' ]; then
    linux_cmds='lsusb'
fi

for cmd in unzip python3 rsync git ssh scp killall sudo grep pgrep xz ${linux_cmds}; do
    if ! command -v "${cmd}" > /dev/null; then
        echo "[-] Command '${cmd}' not installed, please install it!";
        cmd_not_found=1
    fi
done
if [ "$cmd_not_found" = "1" ]; then
    exit 1
fi

# Check for pyimg4
if ! python3 -c 'import pkgutil; exit(not pkgutil.find_loader("lzss") and not pkgutil.find_loader("pyliblzfse") and not pkgutil.find_loader("pyimg4"))'; then
    echo '[-] One or more required modules are not installed. Press any key to install them, or press ctrl + c to cancel'
    read -n 1 -s
    python3 -m pip install fastapi aiohttp ujson wikitextparser uvicorn pyimg4 pyliblzfse lzss
fi

# Check if futurerestore exists
if [ ! -e "$dir"/futurerestore ]; then 
    echo "[*] Downloading futurerestore please wait..." # futurerestore downloader by sasa :)
    if [ "$os" = "Darwin" ]; then
        curl -sLo futurerestore-macOS-RELEASE.zip https://nightly.link/futurerestore/futurerestore/workflows/ci/main/futurerestore-macOS-RELEASE.zip
        unzip futurerestore-macOS-RELEASE.zip
        xz -dc futurerestore-*.xz | tar xfv -
    else
        curl -sLo futurerestore-Linux-x86_64-RELEASE.zip https://nightly.link/futurerestore/futurerestore/workflows/ci/main/futurerestore-Linux-x86_64-RELEASE.zip
        unzip futurerestore-Linux-x86_64-RELEASE.zip
        xz -dc futurerestore-*.xz | tar xfv -
    fi
    mv futurerestore "$dir"/
    rm -rf futurerestore-*
fi
    


# Update submodules
git submodule update --init --recursive 
git submodule foreach git pull origin main

# Re-create work dir if it exists, else, make it
if [ -e work ]; then
    rm -rf work
    mkdir work
else
    mkdir work
fi

if [ ! -e "$dir"/gaster ]; then
    curl -sLO https://nightly.link/verygenericname/gaster/workflows/makefile/main/gaster-"$os".zip
    unzip gaster-"$os".zip
    mv gaster "$dir"/
    rm -rf gaster gaster-"$os".zip
fi

chmod +x "$dir"/*

# ============
# Start
# ============

echo "downr1n | Version 3.0"
echo "Created by edwin, thanks palera1n, and all people creator of path file boot"
echo ""

parse_cmdline "$@"

if [ "$debug" = "1" ]; then
    set -o xtrace
fi

if [ "$clean" = "1" ]; then
    rm -rf  work blobs/ boot/"$deviceid"/  ipsw/extracted
    echo "[*] Removed the created boot files"
    exit
fi


# Get device's iOS version from ideviceinfo if in normal mode
echo "[*] Waiting for devices"
while [ "$(get_device_mode)" = "none" ]; do
    sleep 1;
done
echo $(echo "[*] Detected $(get_device_mode) mode device" | sed 's/dfu/DFU/')

if grep -E 'pongo|checkra1n_stage2|diag' <<< "$(get_device_mode)"; then
    echo "[-] Detected device in unsupported mode '$(get_device_mode)'"
    exit 1;
fi

if [ "$(get_device_mode)" != "normal" ] && [ -z "$version" ] && [ "$dfuhelper" != "1" ]; then
    echo "[-] You must pass the version your device is on when not starting from normal mode"
    exit
fi

if [ "$(get_device_mode)" = "ramdisk" ]; then
    # If a device is in ramdisk mode, perhaps iproxy is still running?
    _kill_if_running iproxy
    echo "[*] Rebooting device in SSH Ramdisk"
    if [ "$os" = 'Linux' ]; then
        sudo "$dir"/iproxy 2222 22 >/dev/null &
    else
        "$dir"/iproxy 2222 22 >/dev/null &
    fi
    sleep 2
    remote_cmd "/usr/sbin/nvram auto-boot=false"
    remote_cmd "/sbin/reboot"
    _kill_if_running iproxy
    _wait recovery
fi

if [ "$(get_device_mode)" = "normal" ]; then
    version=${version:-$(_info normal ProductVersion)}
    arch=$(_info normal CPUArchitecture)
    if [ "$arch" = "arm64e" ]; then
        echo "[-] Downgrade does not, and will not ever work on non-checkm8 devices."
        exit
    fi
    echo "Hello, $(_info normal ProductType) on $version!"

    echo "[*] Switching device into recovery mode..."
    if [ ! $("$dir"/ideviceenterrecovery $(_info normal UniqueDeviceID)) ]; then
        echo "[/] If your device can't enter into recovery mode, please try to force reboot it and put it into recovery mode."
    fi
    _wait recovery
fi

_detect

# Grab more info
echo "[*] Getting device info..."
cpid=$(_info recovery CPID)
model=$(_info recovery MODEL)
deviceid=$(_info recovery PRODUCT)

echo "Detected cpid, your cpid is $cpid"
echo "Detected model, your model is $model"
echo "Detected deviceid, your deviceid is $deviceid"

if [ "$dfuhelper" = "1" ]; then
    echo "[*] Running DFU helper"
    _dfuhelper "$cpid"
    exit
fi

ipswurl=$(curl -sL "https://api.ipsw.me/v4/device/$deviceid?type=ipsw" | "$dir"/jq '.firmwares | .[] | select(.version=="'$version'")' | "$dir"/jq -s '.[0] | .url' --raw-output)


# Have the user put the device into DFU
if [ "$(get_device_mode)" != "dfu" ]; then
    recovery_fix_auto_boot;
    _dfuhelper "$cpid" || {
        echo "[-] Failed to enter DFU mode, run downr1n.sh again"
        exit -1
    }
fi
sleep 2


if [ "$boot" = "1" ]; then # call boot in order to boot it 
    _boot
fi
    # =========
    # extract ipsw 
    # =========

# understand my code is more difficult that understand a programing language fr
if [ ! $(ls ipsw/*.ipsw) ]; then
    echo "YOU DON'T HAVE AN IPSW SO WE ARE GONNA DOWNLOAD IT, THE IPSW WILL BE for $deviceid AND the version $version, DO YOU WANT TO CHANGE THE VERSION (YES) OR (NO)"
    while true; do
        read -r answer
        case "$(echo "$answer" | tr '[:upper:]' '[:lower:]')" in
            yes)
                echo "[*] You answered YES. PLEASE WRITE THE VERSION THAT YOU WANT TO DUALBOOT WITH:"
                read -r version
                ipswurl=$(curl -sL "https://api.ipsw.me/v4/device/$deviceid?type=ipsw" | "$dir"/jq '.firmwares | .[] | select(.version=="'$version'")' | "$dir"/jq -s '.[0] | .url' --raw-output)
                break
                ;;
            no)
                echo "You answered NO. so using the $version."
                break
                ;;
            *)
                echo "Invalid answer."
                usage
                ;;
        esac
    done
    # downloader by @sasa
    echo "[*] Downloading ipsw, it may take few minutes."
    curl -Lo ipsw/$deviceid-$version.ipsw "$ipswurl" "-#"
    ipsw=$(find ipsw/ -name "*.ipsw")
 fi

    
cd ipsw/
ipsw_files=(*.ipsw)
if [[ ${#ipsw_files[@]} -gt 1 ]]; then
    echo "There is more than one IPSW file in the IPSW directory. Please make sure there is only one and then try again!"
    cd ..
    exit;
fi
cd ..

if [ -a $ipsw ] || [ "${ipsw: -5}" == ".ipsw" ]; then
  echo "[*] Continuing..."
else
  _eexit $ipsw "[-] is not a valid ipsw file."
fi

if [ "$downgrade" = "1" ] || [ "$jailbreak" = "1" ]; then
    # extracting ipsw
    echo "[*] Extracting ipsw, hang on please ..." # this will extract the ipsw into ipsw/extracted
    unzip -n $ipsw -d "ipsw/extracted" >/dev/null
    cp -v "$extractedIpsw/BuildManifest.plist" work/
    echo "[*] The IPSW has been successfully extracted."
fi

if [ "$jailbreak" = "1" ]; then
    cp  "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/iBoot[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
    "$dir"/gaster decrypt work/"$(awk "/""${model}""/{x=1}x&&/iBoot[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')" work/iBEC.dec
fi

# ============
# Ramdisk
# ============

# Dump blobs, and install pogo if needed 
if [ true ]; then
    mkdir -p blobs

    cd ramdisk
    chmod +x sshrd.sh
    echo "[*] Creating ramdisk"
    ./sshrd.sh 15.6 

    echo "[*] Booting ramdisk"
    ./sshrd.sh boot
    cd ..
    # remove special lines from known_hosts
    if [ -f ~/.ssh/known_hosts ]; then
        if [ "$os" = "Darwin" ]; then
            sed -i.bak '/localhost/d' ~/.ssh/known_hosts
            sed -i.bak '/127\.0\.0\.1/d' ~/.ssh/known_hosts
        elif [ "$os" = "Linux" ]; then
            sed -i '/localhost/d' ~/.ssh/known_hosts
            sed -i '/127\.0\.0\.1/d' ~/.ssh/known_hosts
        fi
    fi

    # Execute the commands once the rd is booted
    if [ "$os" = 'Linux' ]; then
        sudo "$dir"/iproxy 2222 22 >/dev/null &
    else
        "$dir"/iproxy 2222 22 >/dev/null &
    fi

    if ! ("$dir"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost "echo connected" &> /dev/null); then
        echo "[*] Waiting for the ramdisk to finish booting"
    fi

    while ! ("$dir"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost "echo connected" &> /dev/null); do
        sleep 1
    done

    if [ "$(remote_cmd "/usr/bin/mgask HasBaseband | grep -E 'true|false'")" = "true" ]; then
        HasBaseband='--latest-baseband'
    else
        HasBaseband='--no-baseband'
    fi

    echo "[*] Mounting filesystems ..."
    remote_cmd "/usr/bin/mount_filesystems  2>/dev/null"

    has_active=$(remote_cmd "ls /mnt6/active" 2> /dev/null)
    if [ ! "$has_active" = "/mnt6/active" ]; then
        echo "[!] Active file does not exist! Please use SSH to create it"
        echo "    /mnt6/active should contain the name of the UUID in /mnt6"
        echo "    When done, type reboot in the SSH session, then rerun the script"
        echo "    ssh root@localhost -p 2222"
        exit
    fi
    active=$(remote_cmd "cat /mnt6/active" 2> /dev/null)
    mkdir -p "boot/${deviceid}"

    if [ ! -e blobs/"$deviceid"-"$version".shsh2 ]; then
        remote_cmd "cat /dev/rdisk1" | dd of=dump.raw bs=256 count=$((0x4000)) 
        "$dir"/img4tool --convert -s blobs/"$deviceid"-"$version".shsh2 dump.raw
        echo "[*] Converting blob"
        sleep 3
        rm dump.raw

    fi

    "$dir"/img4tool -e -s blobs/"$deviceid"-"$version".shsh2 -m work/IM4M >/dev/null
    echo "[*] Dumpped SHSH"

    if [ "$jailbreak" = "1" ]; then
        echo "[*] Patching kernel" # this will send and patch the kernel
        cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
        cp  work/"$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" work/kernelcache 
        
        if [[ "$deviceid" == "iPhone8"* ]] || [[ "$deviceid" == "iPad6"* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
            python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw --extra work/kpp.bin >/dev/null
        else
            python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw >/dev/null
        fi
        
        remote_cp work/kcache.raw root@localhost:/mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.raw >/dev/null
        remote_cp boot/"${deviceid}"/kernelcache.img4 "root@localhost:/mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kernelcache" >/dev/null
        remote_cp binaries/Kernel15Patcher.ios root@localhost:/mnt1/private/var/root/Kernel15Patcher.ios >/dev/null
        remote_cmd "/usr/sbin/chown 0 /mnt1/private/var/root/Kernel15Patcher.ios"
        remote_cmd "/bin/chmod 755 /mnt1/private/var/root/Kernel15Patcher.ios"
        sleep 1
        if [ ! $(remote_cmd "/mnt1/private/var/root/Kernel15Patcher.ios /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.raw /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.patched  2>/dev/null") ]; then
            echo "you have the kernelpath already installed "
        fi

        sleep 2
        remote_cp root@localhost:/mnt6/"$active"/System/Library/Caches/com.apple.kernelcaches/kcache.patched work/ # that will return the kernelpatcher in order to be patched again and boot with it 
        "$dir"/Kernel64Patcher work/kcache.patched work/kcache.patchedB -e $(if [[ ! "$version" = "15."* ]]; then echo "-b"; else echo "-b15 -r"; fi) $(if [ ! "$taurine" = "1" ]; then echo "-l"; fi) >/dev/null
        
        if [[ "$deviceid" == *'iPhone8'* ]] || [[ "$deviceid" == *'iPad6'* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
            python3 -m pyimg4 im4p create -i work/kcache.patchedB -o work/kcache.im4p -f rknl --extra work/kpp.bin --lzss >/dev/null
        else
            python3 -m pyimg4 im4p create -i work/kcache.patchedB -o work/kcache.im4p -f rknl --lzss >/dev/null
        fi

        remote_cmd "rm -f /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.raw /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.patched /mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kcache.im4p"
        python3 -m pyimg4 img4 create -p work/kcache.im4p -o work/kernelcache.img4 -m work/IM4M >/dev/null

        #"$dir"/kerneldiff work/kcache.raw work/kcache.patchedB work/kc.bpatch
        #"$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" -o work/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch `if [ "$os" = 'Linux' ]; then echo "-J"; fi`
        #remote_cp root@localhost:/mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kernelcachd work/kernelcache.img4
        cp -v "work/kernelcache.img4" "boot/${deviceid}"
        echo "[*] Finished patching the kernel"

        echo "[*] installing dualra1n-loader"
        unzip other/dualra1n-loader.ipa -d other/
        mkdir -p other/Payload/Applications/
        mv -nv other/Payload/dualra1n-loader.app  other/Payload/Applications/
        remote_cp other/Payload/Applications/ root@localhost:/mnt1/Applications
        
        echo "[*] Saving snapshot"
        if [ ! "$(remote_cmd "/usr/bin/snaputil -c orig-fs /mnt1")" ]; then
            echo "[-] The snapshot is already created, SKIPPING ..."
        fi

        if [ ! $(remote_cmd "trollstoreinstaller TV") ]; then
            echo "[/] An error occured while installing TrollStore to the TV app."
        fi

        echo "[*] Fixing dualra1n-loader"
        if [ ! $(remote_cmd "chmod +x /mnt1/Applications/dualra1n-loader.app/dualra1n* && /usr/sbin/chown 33 /mnt1/Applications/dualra1n-loader.app/dualra1n-loader && /bin/chmod 755 /mnt1/Applications/dualra1n-loader.app/dualra1n-helper && /usr/sbin/chown 0 /mnt1/Applications/dualra1n-loader.app/dualra1n-helper" ) ]; then
            echo "install dualra1n-loader using trollstore or another methods"
        fi

        if [ "$taurine" = 1 ]; then
            echo "Installing taurine"
            remote_cp other/taurine/* root@localhost:/mnt1/
            echo "[*] Finished, now your downgrade is jailbroken, you can boot it"
            remote_cmd "/sbin/reboot"
            exit;
        fi

        echo "installing JBINIT jailbreak, thanks palera1n"
        echo "[*] Copying files to rootfs"
        remote_cmd "rm -rf /mnt1/jbin /mnt1/.installed_palera1n"
        sleep 1
        remote_cmd "mkdir -p /mnt1/jbin/binpack /mnt1/jbin/loader.app"
        sleep 1

        # this is the jailbreak of palera1n being installing 
        
        cp -v other/post.sh other/rootfs/jbin/
        remote_cp -r other/rootfs/* root@localhost:/mnt1/
        remote_cmd "ldid -s /mnt1/jbin/launchd /mnt1/jbin/jbloader /mnt1/jbin/jb.dylib"
        remote_cmd "chmod +rwx /mnt1/jbin/launchd /mnt1/jbin/jbloader /mnt1/jbin/post.sh"
        remote_cmd "tar -xvf /mnt1/jbin/binpack/binpack.tar -C /mnt1/jbin/binpack/"
        sleep 1
        remote_cmd "rm /mnt1/jbin/binpack/binpack.tar"
        remote_cmd "/usr/sbin/nvram auto-boot=true"
        echo "[*] Finished of jailbreaking"
        ask
        while true; do
            read -r answer
            case "$(echo "$answer" | tr '[:upper:]' '[:lower:]')" in
                yes)
                    echo "[*] You answered YES. so Activating the iBoot localboot path..."
                    echo '[*] Patching the kernel to krnl'
                    if [[ "$deviceid" == *'iPhone8'* ]] || [[ "$deviceid" == *'iPad6'* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
                        python3 -m pyimg4 im4p create -i work/kcache.patchedB -o work/krnl.im4p -f krnl --extra work/kpp.bin --lzss >/dev/null

                    else
                        python3 -m pyimg4 im4p create -i work/kcache.patchedB -o work/krnl.im4p -f krnl --lzss >/dev/null
                    fi

                    python3 -m pyimg4 img4 create -p work/krnl.im4p -o work/kernelcachd -m work/IM4M >/dev/null
                    remote_cp work/kernelcachd root@localhost:/mnt6/"$active"/System/Library/Caches/com.apple.kernelcaches/ >/dev/null
                    
                     if [ "$os" = 'Linux' ]; then
                        sed -i 's/\/\kernelcache/\/\kernelcachd/g' work/iBEC.dec
                     else
                        LC_ALL=C sed -i.bak -e 's/s\/\kernelcache/s\/\kernelcachd/g' work/iBEC.dec
                     fi
            
                    "$dir"/iBoot64Patcher work/iBEC.dec work/iBEC.patched -b "-v wdt=-1 debug=0x2014e `if [ "$cpid" = '0x8960' ] || [ "$cpid" = '0x7000' ] || [ "$cpid" = '0x7001' ]; then echo "-restore"; fi`" -n -l >/dev/null
                    "$dir"/img4 -i work/iBEC.patched -o work/iBEC.img4 -M work/IM4M -A -T "$(if [[ "$cpid" == *"0x801"* ]]; then echo "ibss"; else echo "ibec"; fi)" >/dev/null
                    cp -v work/iBEC.img4 "boot/${deviceid}"
                    break
                    ;;
                no)
                    echo "You answered NO. so Not activating the iBoot localboot path."
                    break
                    ;;
                *)
                    echo "Invalid answer."
                    usage
                    ;;
            esac
        done
        
        echo "[*] DONE ... now reboot and boot again"   
        remote_cmd "/sbin/reboot"
        exit;

    fi
    
    echo "[*] Patching kernel ..." # this will send and patch the kernel
    
    cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/kernelcache"
    
    if [[ "$deviceid" == "iPhone8"* ]] || [[ "$deviceid" == "iPad6"* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
        python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw --extra work/kpp.bin >/dev/null
    else
        python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw >/dev/null
    fi
    remote_cp work/kcache.raw root@localhost:/mnt1/System/Library/Caches/com.apple.kernelcaches/kcache.raw >/dev/null
    remote_cp binaries/Kernel15Patcher.ios root@localhost:/mnt1/private/var/root/kpf15.ios >/dev/null
    remote_cmd "/usr/sbin/chown 0 /mnt1/private/var/root/kpf15.ios"
    remote_cmd "/bin/chmod 755 /mnt1/private/var/root/kpf15.ios"
    sleep 1
    
    if [ ! $(remote_cmd "/mnt1/private/var/root/kpf15.ios /mnt1/System/Library/Caches/com.apple.kernelcaches/kcache.raw /mnt1/System/Library/Caches/com.apple.kernelcaches/kcache.patched  2>/dev/null") ]; then
        echo "you have the kernelpath already installed "
    fi
    echo "[*] kernel patched with kpf"
    remote_cp root@localhost:/mnt1/System/Library/Caches/com.apple.kernelcaches/kcache.patched work/ >/dev/null

    echo "Reboot into recovery mode ..."
    remote_cmd "/usr/sbin/nvram auto-boot=false"
    remote_cmd "/sbin/reboot"
    sleep 10

    if [ "$(get_device_mode)" = "dfu" ]; then
        echo "The device is in a false dfu mode. Please force reboot and try to put it on dfu mode by pressing the buttons"
        read -p "Press enter if you got dfu mode on the iphone"
        "$dir"/gaster pwn
    else
        _wait recovery
        sleep 4
        _dfuhelper "$cpid"
        sleep 3
    fi

        

    echo "[* ]Patching some boot files..."
    if [ "$downgrade" = "1" ]; then
        sleep 1

        mkdir -p boot/"$deviceid"


        if [ "$fixBoot" = "1" ]; then # i put it because my friend tested on his ipad and that does not boot so when we download all file from the internet so not extracting ipsw that boot fine idk why 

            cd work
            #that will download the files needed
            sleep 1
            "$dir"/pzb -g "$(awk "/""${model}""/{x=1}x&&/iBSS[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
            "$dir"/pzb -g "$(awk "/""${model}""/{x=1}x&&/iBoot[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
            "$dir"/pzb -g "$(awk "/""${model}""/{x=1}x&&/DeviceTree[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
            "$dir"/pzb -g "$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
            
            if [ "$os" = 'Darwin' ]; then
                "$dir"/pzb -g Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache "$ipswurl"
            else
                "$dir"/pzb -g Firmware/"$(../Linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')".trustcache "$ipswurl"
            fi
            cd ..
        else
            #that will extract the files needed
            cp  "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/iBSS[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            cp  "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/iBoot[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            cp  "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/DeviceTree[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            cp  "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            
            if [ "$os" = "Darwin" ]; then
                "$dir"/img4 -i "$extractedIpsw"/Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."OS"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache -o work/trustcache.img4 -M work/IM4M >/dev/null
            else
                "$dir"/img4 -i "$extractedIpsw"/Firmware/"$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')".trustcache -o work/trustcache.img4 -M work/IM4M >/dev/null
            fi
        fi

        echo "[*] Finished moving the boot files to work"
        sleep 2
        
        echo "[*] Decrypthing ibss and iboot"
        "$dir"/gaster decrypt work/"$(awk "/""${model}""/{x=1}x&&/iBSS[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]dfu[/]//')" work/iBSS.dec
        
        sleep 1
        "$dir"/iBoot64Patcher work/iBSS.dec work/iBSS.patched >/dev/null
        "$dir"/img4 -i work/iBSS.patched -o work/iBSS.img4 -M work/IM4M -A -T ibss >/dev/null
        
        "$dir"/gaster decrypt work/"$(awk "/""${model}""/{x=1}x&&/iBoot[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')" work/iBEC.dec >/dev/null
        sleep 1
        
        echo "[*] Applying patches to the iboot"
        if [ "$os" = 'Linux' ]; then
            sed -i 's/\/\kernelcache/\/\kernelcachd/g' work/iBEC.dec
        else
            LC_ALL=C sed -i.bak -e 's/s\/\kernelcache/s\/\kernelcachd/g' work/iBEC.dec
        fi
        
        "$dir"/iBoot64Patcher work/iBEC.dec work/iBEC.patched -b "-v wdt=-1 `if [ "$cpid" = '0x8960' ] || [ "$cpid" = '0x7000' ] || [ "$cpid" = '0x7001' ]; then echo "-restore"; fi`" -n "$(if [ "$local" = "1" ]; then echo "-l"; fi)" >/dev/null
        "$dir"/img4 -i work/iBEC.patched -o work/iBEC.img4 -M work/IM4M -A -T "$(if [[ "$cpid" == *"0x801"* ]]; then echo "ibss"; else echo "ibec"; fi)" >/dev/null

        echo "[*] Patching the kernel"
        "$dir"/Kernel64Patcher work/kcache.patched work/kcache.patchedB -e $(if [[ "$version" = "14."* ]]; then echo "-b"; else echo "-b15 -r"; fi) >/dev/null
        
        if [[ "$deviceid" == *'iPhone8'* ]] || [[ "$deviceid" == *'iPad6'* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
            python3 -m pyimg4 im4p create -i work/kcache.patchedB -o work/kcache.im4p -f rkrn --extra work/kpp.bin --lzss >/dev/null
        else
            python3 -m pyimg4 im4p create -i work/kcache.patchedB -o work/kcache.im4p -f rkrn --lzss >/dev/null
        fi

        python3 -m pyimg4 img4 create -p work/kcache.im4p -o work/kernelcache.img4 -m work/IM4M >/dev/null

        echo "[*] Patching the kernel to restore using futurerestore"
        if [[ "$deviceid" == "iPhone8"* ]] || [[ "$deviceid" == "iPad6"* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
            if [ "$os" = "Darwin" ]; then
                python3 -m pyimg4 im4p extract -i "$extractedIpsw$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreKernelCache"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" -o work/kcache.dec --extra work/kpp.bin >/dev/null
            else
                python3 -m pyimg4 im4p extract -i "$extractedIpsw$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreKernelCache:Info:Path" | sed 's/"//g')" -o work/kcache.dec --extra work/kpp.bin >/dev/null
            fi
        else
            if [ "$os" = "Darwin" ]; then
                python3 -m pyimg4 im4p extract -i "$extractedIpsw$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreKernelCache"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" -o work/kcache.dec >/dev/null
            else
                python3 -m pyimg4 im4p extract -i "$extractedIpsw$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreKernelCache:Info:Path" | sed 's/"//g')" -o work/kcache.dec >/dev/null
            fi
        fi
        
        "$dir"/Kernel64Patcher work/kcache.dec work/krnl.patched -a -b  >/dev/null
    
        if [[ "$deviceid" == "iPhone8"* ]] || [[ "$deviceid" == "iPad6"* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
            python3 -m pyimg4 im4p create -i work/krnl.patched -o work/krnl.im4p --extra work/kpp.bin -f rkrn --lzss >/dev/null
        else
            python3 -m pyimg4 im4p create -i work/krnl.patched -o work/krnl.im4p -f rkrn --lzss >/dev/null
        fi
    
    
        "$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/DeviceTree[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')" work/devicetree.img4 -M work/IM4M -T rdtr >/dev/null
        
        if [ "$os" = "Darwin" ]; then
            cp "$extractedIpsw$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "work/" >/dev/null
        else
            cp "$extractedIpsw$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')" "work/" >/dev/null
        fi
    
        if [ "$os" = "Darwin" ]; then
            "$dir"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" -o work/ramdisk.dmg >/dev/null
        else
            "$dir"/img4 -i work/"$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')" -o work/ramdisk.dmg >/dev/null
        fi
        
        echo "[*] Patching the restored_external and asr, and saving them into the ramdisk ..."
        if [ "$os" = "Darwin" ]; then
            hdiutil attach work/ramdisk.dmg -mountpoint /tmp/SSHRD >/dev/null
            mounted="/tmp/SSHRD"
    
            "$dir"/asr64_patcher $mounted/usr/sbin/asr work/patched_asr >/dev/null
            "$dir"/ldid -e $mounted/usr/sbin/asr > work/asr.plist
            "$dir"/ldid -Swork/asr.plist work/patched_asr
            chmod -R 755 work/patched_asr
    
            cp $mounted/usr/local/bin/restored_external work/restored_external
            "$dir"/restored_external64_patcher work/restored_external work/patched_restored_external >/dev/null
            "$dir"/ldid -e work/restored_external > work/restored_external.plist
            "$dir"/ldid -Swork/restored_external.plist work/patched_restored_external
            chmod -R 755 work/patched_restored_external
    
            rm $mounted/usr/sbin/asr
            rm $mounted/usr/local/bin/restored_external
            
            mv work/patched_asr $mounted/usr/sbin/asr
            mv work/patched_restored_external $mounted/usr/local/bin/restored_external
    
            hdiutil detach -force /tmp/SSHRD
        else
    
            "$dir"/hfsplus work/ramdisk.dmg extract /usr/sbin/asr work/asr >/dev/null
            "$dir"/asr64_patcher work/asr work/patched_asr >/dev/null
            "$dir"/ldid -e work/asr > work/asr.plist
            "$dir"/ldid -Swork/asr.plist work/patched_asr
            chmod 755 work/patched_asr
    
            "$dir"/hfsplus work/ramdisk.dmg extract /usr/local/bin/restored_external work/restored_external >/dev/null
            "$dir"/restored_external64_patcher work/restored_external work/patched_restored_external >/dev/null
            "$dir"/ldid -e work/restored_external > work/restored_external.plist
            "$dir"/ldid -Swork/restored_external.plist work/patched_restored_external
            chmod 755 work/patched_restored_external
    
            "$dir"/hfsplus work/ramdisk.dmg rm /usr/sbin/asr
            "$dir"/hfsplus work/ramdisk.dmg rm /usr/local/bin/restored_external
            
            "$dir"/hfsplus work/ramdisk.dmg add work/patched_asr /usr/sbin/asr
            "$dir"/hfsplus work/ramdisk.dmg add work/patched_restored_external /usr/local/bin/restored_external
    
            "$dir"/hfsplus work/ramdisk.dmg chmod 100755 /usr/sbin/asr
            "$dir"/hfsplus work/ramdisk.dmg chmod 100755 /usr/local/bin/restored_external
        fi
    
        python3 -m pyimg4 im4p create -i work/ramdisk.dmg -o work/rdsk.im4p -f rdsk >/dev/null
    
        cp -v work/*.img4 "boot/${deviceid}" # copying all file img4 to boot

        echo "[*] Successfully patched the boot files"
        sleep 1
        
        set +e

        "$dir"/gaster reset >/dev/null
        sleep 1
        "$dir"/irecovery -f "blobs/"$deviceid"-"$version".shsh2" >/dev/null

        if [ "$dontRestore" = "1" ]; then
            echo "[*] Finished creating boot files now you can --boot in order to get boot to the system"
            exit;
        fi
        
        echo "[*] Executing futurerestore ..."
        _runFuturerestore
        sleep 2
        echo -e "\033[1;33mif nothing works just try to run (with sudo or without) this command:\033[0m \033[1m$dir/futurerestore -t blobs/$deviceid-$version.shsh2 --use-pwndfu --skip-blob --rdsk work/rdsk.im4p --rkrn work/krnl.im4p --latest-sep $HasBaseband $ipsw\033[0m"

        echo "if futurerestore restore sucess, you can boot using  --boot"
    fi
fi


} 2>&1 | tee logs/${log}
