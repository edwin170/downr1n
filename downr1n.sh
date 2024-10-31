#!/usr/bin/env bash

printb() 
{
  echo -e "\033[1;36m$1\033[0m"
}

printg()
{
    echo -e "\033[1;32m$1\033[0m"
}

printr() 
{
  echo -e "\033[1;31m$1\033[0m"
}

printy() {
  echo -e "\033[1;33m$1\033[0m"
}

if [ "$(uname)" == "Linux" ]; then
    if [ "$EUID" -ne 0 ]; then
    	printg "You have to run this as root on Linux."
     	printg "Please type your password"
        exec sudo ./downr1n.sh $@
    fi
else
    if [ "$EUID" = "0" ]; then
        printr "Please don't run as root on macOS. It just breaks permissions."
        exit 1
    fi
fi

mkdir -p logs
mkdir -p boot
mkdir -p ipsw/extracted
mainDir=$(pwd)
set -e

log="last".log
cd logs
touch "$log"
cd ..

{

printb "[*] Command ran:`if [ $EUID = 0 ]; then printb " sudo"; fi` ./downr1n.sh $@"



# =========
# Variables
# =========
version="3.0"
os=$(uname)
dir="$(pwd)/binaries/$os"
max_args=2
arg_count=0

if [ ! -d "ramdisk/" ]; then
    git clone https://github.com/dualra1n/ramdisk.git --depth 1
fi

# =========
# Functions
# =========
remote_cmd() {
    sleep 1
    "$dir"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost "$@"
}

remote_cp() {
    sleep 1
    "$dir"/sshpass -p 'alpine' scp -r -o StrictHostKeyChecking=no -P2222 $@
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
Usage: $0 [options] [vers] [ipsw] [ subcommand ] vers = the version that you want to dualboot
iOS 15 - 13.0 downgrade tool ./downr1n --downgrade 15.7 (the ios that you want to downgrade with) ipsw 

Options:
    --downgrade         downgrade tethered your device.
    --jailbreak         jailbreak with dualra1n-loader. usage ./downr1n.sh --jailbreak 14.8 
    --taurine           jailbreak with taurine. usage ./downr1n.sh --jailbreak 14.3 --taurine
    --aslrdisable       This option will path kernel to disable aslr on all process. use this when you creating boot files.
    --ptracedisable     This option will path kernel to disable ptrace debugger method detection. use this when you creating boot files.
    --boot              this boot the device.
    --keyServer         use this option to downgrade when the keys server is in problem. use ex: --downgrade 14.8 --keyServer
    --dont-restore      this will avoid the restore using futurerestore, this can be used if you wanted only create the boot files, use ex: --downgrade 14.8 --dont-restore
    --debug             Debug the script

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
        --aslrdisable)
            aslrDisabled=1
            ;;
        --ptracedisable)
            ptraceDisabled=1
            ;;
        --keyServer)
            keyServer=1
            ;;
        --fixBoot)
            fixBoot=1
            ;;
        --dont-restore)
            dontRestore=1
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
            printr "[-] Unknown option $1. Use $0 --help for help."
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
            if [[ "$arg" == *"ipsw"* ]]; then
                ipsw=$arg
            else
                parse_arg "$arg";
            fi
        else
            printr "[-] Too many arguments. Use $0 --help for help.";
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
        printg "[*] Pwning device"
        "$dir"/gaster pwn
        sleep 2
        #"$dir"/gaster reset
        #sleep 1
    fi
}

_reset() {
        printg "[*] Resetting DFU state"
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
        printr "[-] Please attach only one device" > /dev/tty
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
        printg "[*] Waiting for device in $1 mode"
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
        printg "[*] Device already on dfu mode"
        return;
    fi

    local step_one;
    deviceid=$( [ -z "$deviceid" ] && _info normal ProductType || echo $deviceid )
    if [[ "$1" = 0x801* && "$deviceid" != *"iPad"* ]]; then
        step_one="Hold volume down + side button"
    else
        step_one="Hold home + power button"
    fi
    printg "[*] To get into DFU mode, you will be guided through 2 steps:"
    printg "[*] Press any key when ready for DFU mode"
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
        printg "[*] Device entered DFU!"
    else
        printr "[-] Device did not enter DFU mode, try again"
       _detect
       _dfuhelper
    fi
}

_do_localboot() {
    ask
    while true; do
        read -r answer
        case "$(echo "$answer" | tr '[:upper:]' '[:lower:]')" in
            yes)
                printg "[*] You answered YES. so Activating the iBoot localboot path..."
                printg '[*] Patching the kernel to krnl'
                if [[ "$deviceid" == *'iPhone8'* ]] || [[ "$deviceid" == *'iPad6'* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
                    python3 -m pyimg4 im4p create -i work/$(if [ "$taurine" = "1" ]; then echo "kcache.patched"; else echo "kcache.patchedB"; fi)  -o work/krnl.im4p -f krnl --extra work/kpp.bin --lzss >/dev/null
                else
                    python3 -m pyimg4 im4p create -i work/$(if [ "$taurine" = "1" ]; then echo "kcache.patched"; else echo "kcache.patchedB"; fi)  -o work/krnl.im4p -f krnl --lzss >/dev/null
                fi
                python3 -m pyimg4 img4 create -p work/krnl.im4p -o work/kernelcachd -m work/IM4M >/dev/null
                remote_cp work/kernelcachd root@localhost:/mnt6/"$active"/System/Library/Caches/com.apple.kernelcaches/ >/dev/null
                
                #printb "[*] Renaming the snapshot"
                #output=$(remote_cmd "snaputil -l /mnt1")
        
                #SNAPSHOT=$(echo "$output" | awk '/com.apple.os.update-/ {print $1}')
                #if [ $SNAPSHOT ]; then
                #    remote_cmd "snaputil -n "$SNAPSHOT" backup."$SNAPSHOT" /mnt1"
                #fi

                if [ "$os" = 'Linux' ]; then
                    #sed -i 's/com\.apple\.os\.update-/downr1n\.rfsnapshot-/g' work/iBEC.dec
                    sed -i 's/\/\kernelcache/\/\kernelcachd/g' work/iBEC.dec
                else
                    #LC_ALL=C sed -i.bak -e 's/com\.apple\.os\.update-/downr1n\.rfsnapshot-/g' work/iBEC.dec
                    LC_ALL=C sed -i.bak -e 's/s\/\kernelcache/s\/\kernelcachd/g' work/iBEC.dec
                fi

                "$dir"/iBoot64Patcher work/iBEC.dec work/iBEC.patched -b "-v wdt=-1 debug=0x2014e `if [ "$cpid" = '0x8960' ] || [ "$cpid" = '0x7000' ] || [ "$cpid" = '0x7001' ]; then echo "-restore"; fi`" -n -l >/dev/null
                "$dir"/img4 -i work/iBEC.patched -o work/iBEC.img4 -M work/IM4M -A -T "$(if [[ "$cpid" == *"0x801"* ]]; then echo "ibss"; else echo "ibec"; fi)" >/dev/null
                cp -v work/iBEC.img4 "boot/${deviceid}"
                break
                ;;
            no)
                printg "You answered NO. so Not activating the iBoot localboot path."
                break
                ;;
            *)
                printg "Invalid answer."
                usage
                ;;
        esac
    done
}

usage() {
    printb "Please answer with YES or NO (case-insensitive)."
}

ask() {
    printg "Do you want to activate the iBoot localboot path? YES or NO."
    printg "Activating this path can help avoid a lot of problems and is generally more stable."
    #printg "If you activate it, you will need to use --boot again after it finishes to boot with localboot."
    printy "If localboot breaks your boot process (like you can't boot), please execute ./downr1n.sh --downgrade (version) --dont-restore to fix the boot files."
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
    read -p "Press ENTER to continue with futurerestore, your device will start to restoring <-"
    rm -rf /tmp/futurerestore/
    if [ "$os" == "Linux" ]; then
        sudo -u $SUDO_USER \
        "$dir"/futurerestore -t blobs/"$deviceid"-"$version".shsh2 --use-pwndfu --skip-blob \
        --rdsk work/rdsk.im4p --rkrn work/krnl.im4p \
        --latest-sep "$HasBaseband" "$ipsw"
    else    
        "$dir"/futurerestore -t blobs/"$deviceid"-"$version".shsh2 --use-pwndfu --skip-blob \
        --rdsk work/rdsk.im4p --rkrn work/krnl.im4p \
        --latest-sep "$HasBaseband" "$ipsw"
    fi
}

_detect() {
    # Get device's iOS version from ideviceinfo if in normal mode
    printg "[*] Waiting for devices"
    while [ "$(get_device_mode)" = "none" ]; do
        sleep 1;
    done
    echo $(printg "[*] Detected $(get_device_mode) mode device" | sed 's/dfu/DFU/')

    if grep -E 'pongo|checkra1n_stage2|diag' <<< "$(get_device_mode)"; then
        printr "[-] Detected device in unsupported mode '$(get_device_mode)'"
        exit 1;
    fi

    if [ "$(get_device_mode)" != "normal" ] && [ -z "$version" ] && [ "$dfuhelper" != "1" ]; then
        printr "[-] You must pass the version your device is on when not starting from normal mode"
        exit
    fi

    if [ "$(get_device_mode)" = "ramdisk" ]; then
        # If a device is in ramdisk mode, perhaps iproxy is still running?
        _kill_if_running iproxy
        printg "[*] Rebooting device in SSH Ramdisk"
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
            printr "[-] dualboot doesn't, and never will, work on non-checkm8 devices"
            exit
        fi
        echo "Hello, $(_info normal ProductType) on $version!"

        printg "[*] Switching device into recovery mode..."
        "$dir"/ideviceenterrecovery $(_info normal UniqueDeviceID)
        _wait recovery
    fi
}

_boot() {
    _pwn
    sleep 1
    _reset
    sleep 1
    
    printg "[*] Booting device"

    "$dir"/irecovery -f "blobs/"$deviceid"-"$version".shsh2"
    sleep 1

    if [[ ! "$cpid" == *"0x801"* ]]; then
        "$dir"/irecovery -f "boot/${deviceid}/iBSS.img4"
        if [ "$cpid" = '0x7000' ] || [ "$cpid" = '0x7001' ]; then
            sleep 10
        else
            sleep 2
        fi
    fi

    "$dir"/irecovery -f "boot/${deviceid}/iBEC.img4"
    if [ "$cpid" = '0x7000' ] || [ "$cpid" = '0x7001' ]; then
        sleep 10
    else
        sleep 4
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

    "$dir"/irecovery -c bootx
    exit;
}

check_and_install_package() {
    local package=$1
    local required_version=$2
    local installed_version=$(python3 -c "import pkg_resources; print(pkg_resources.get_distribution('$package').version)" 2>/dev/null || echo "not installed")

    if [ -z "$required_version" ]; then
        printr "[-] No version specified for $package. Installing the latest version."
        python3 -m pip install "$package" --break-system-packages
    elif [ "$installed_version" != "$required_version" ]; then
        printr "[-] $package version $required_version is not installed (current version: $installed_version). We can install it for you. Press any key to start installing $package $required_version, or press Ctrl + C to cancel."
        read -n 1 -s
        python3 -m pip install "$package==$required_version" #--break-system-packages
    else
        echo "[+] $package version $required_version is already installed."
    fi
}


_exit_handler() {
    if [ "$os" = "Darwin" ]; then
        killall -CONT AMPDevicesAgent AMPDeviceDiscoveryAgent MobileDeviceUpdater || true
    fi

    [ $? -eq 0 ] && exit
    printr "[-] An error occurred"

    if [ -d "logs" ]; then
        cd logs
        mv "$log" FAIL_${log}
        cd ..
    fi

    printg "[*] A failure log has been made. If you're going ask for help, please attach the latest log."
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

for cmd in unzip python3 rsync git ssh scp killall sudo grep pgrep ${linux_cmds}; do
    if ! command -v "${cmd}" > /dev/null; then
        printr "[-] Command '${cmd}' not installed, please install it!";
        cmd_not_found=1
    fi
done
if [ "$cmd_not_found" = "1" ]; then
    exit 1
fi

# Check and install pyimg4
check_and_install_package "pyimg4" "0.8"

# Check and install pylzss
check_and_install_package "pylzss" "0.3.4"

# Check and install pyliblzfse
check_and_install_package "pyliblzfse"

# Update submodules
if [ -d ".git/" ]; then
    git submodule update --init --recursive 
    git submodule foreach git pull origin main
fi

# Re-create work dir if it exists, else, make it
if [ -e work ]; then
    rm -rf work
    mkdir work
else
    mkdir work
fi

chmod +x "$dir"/*
if [ "$os" = 'Darwin' ]; then
    for file in "$dir"/*; do
        xattr -d com.apple.quarantine "$file" 2>/dev/null || true
    done
fi

# ============
# Start
# ============

printb "downr1n | Version 3.0"
printb "Created by edwin, thanks palera1n, and all people creator of path file boot"
echo ""

parse_cmdline "$@"

if [ "$debug" = "1" ]; then
    set -o xtrace
fi

if [ "$clean" = "1" ]; then
    rm -rf  work blobs/ boot/"$deviceid"/ 
    printg "[*] Removed the created boot files"
    exit
fi


# Get device's iOS version from ideviceinfo if in normal mode
printg "[*] Waiting for devices"
while [ "$(get_device_mode)" = "none" ]; do
    sleep 1;
done
echo $(printg "[*] Detected $(get_device_mode) mode device" | sed 's/dfu/DFU/')

if grep -E 'pongo|checkra1n_stage2|diag' <<< "$(get_device_mode)"; then
    printr "[-] Detected device in unsupported mode '$(get_device_mode)'"
    exit 1;
fi

if [ "$(get_device_mode)" != "normal" ] && [ -z "$version" ] && [ "$dfuhelper" != "1" ]; then
    printr "[-] You must pass the version your device is on when not starting from normal mode"
    exit
fi

if [ "$(get_device_mode)" = "ramdisk" ]; then
    # If a device is in ramdisk mode, perhaps iproxy is still running?
    _kill_if_running iproxy
    printg "[*] Rebooting device in SSH Ramdisk"
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
        printr "[-] downgrade doesn't, and never will, work on non-checkm8 devices"
        exit
    fi
    echo "Hello, $(_info normal ProductType) on $version!"

    printg "[*] Switching device into recovery mode..."
    "$dir"/ideviceenterrecovery $(_info normal UniqueDeviceID)
    printg "[/] if your device can't enter into recovery mode please try to force reboot and put it on recovery mode"
    
    _wait recovery
fi

_detect

# Grab more info
printg "[*] Getting device info..."
cpid=$(_info recovery CPID)
model=$(_info recovery MODEL)
deviceid=$(_info recovery PRODUCT)

printg "Detected cpid, your cpid is $cpid"
printg "Detected model, your model is $model"
printg "Detected deviceid, your deviceid is $deviceid"

if [ "$cpid" = '0x7000' ] || [ "$cpid" = '0x7001' ]; then
    printr "[-] Please downr1n is not recommended on A8/A8X so instead try dualra1n with --downgrade option if you want a downgrade"
fi

if [ "$dfuhelper" = "1" ]; then
    printg "[*] Running DFU helper"
    _dfuhelper "$cpid"
    exit
fi

ipswurl=$(curl -sL "https://api.ipsw.me/v4/device/$deviceid?type=ipsw" | "$dir"/jq '.firmwares | .[] | select(.version=="'$version'")' | "$dir"/jq -s '.[0] | .url' --raw-output)


# Have the user put the device into DFU
if [ "$(get_device_mode)" != "dfu" ]; then
    recovery_fix_auto_boot;
    _dfuhelper "$cpid" || {
        printr "[-] failed to enter DFU mode, run downr1n.sh again"
        exit -1
    }
fi
sleep 2


if [ "$boot" = "1" ]; then # call boot in order to boot it 
    _boot
fi

# understand my code is more difficult that understand a programing language fr
if [ ! $(ls ipsw/*.ipsw) ]; then
    printg "YOU DON'T HAVE AN IPSW SO WE ARE GONNA DOWNLOAD IT, THE IPSW WILL BE for $deviceid AND the version $version, DO YOU WANT TO CHANGE THE VERSION (YES) OR (NO)"
    while true; do
        read -r answer
        case "$(echo "$answer" | tr '[:upper:]' '[:lower:]')" in
            yes)
                printg "[*] You answered YES. PLEASE WRITE THE VERSION THAT YOU WANT TO DUALBOOT WITH:"
                read -r version
                ipswurl=$(curl -sL "https://api.ipsw.me/v4/device/$deviceid?type=ipsw" | "$dir"/jq '.firmwares | .[] | select(.version=="'$version'")' | "$dir"/jq -s '.[0] | .url' --raw-output)
                break
                ;;
            no)
                printb "You answered NO. so using the $version."
                break
                ;;
            *)
                printr "Invalid answer."
                usage
                ;;
        esac
    done

    # downloader by @sasa
    printg "[*] Downloading ipsw, it may take few minutes."
    curl -Lo ipsw/$deviceid-$version.ipsw "$ipswurl" "-#"
    ipsw=$(find ipsw/ -name "*.ipsw")
 fi

    
    # =========
    # extract ipsw 
    # =========
mkdir -p ipsw/extracted/$deviceid
mkdir -p ipsw/extracted/$deviceid/$version

extractedIpsw="ipsw/extracted/$deviceid/$version/"

if [[ "$ipsw" == *".ipsw" ]]; then
    printg "[*] Argument detected we are gonna use the ipsw specified"
else
    ipsw=()
    for file in ipsw/*.ipsw; do
        ipsw+=("$file")
    done


    if [ ${#ipsw[@]} -eq 0 ]; then
        printr "No .ipsw files found."
        exit;
    else
        for file in "${ipsw[@]}"; do
            if [[ "$file" = *"$version"* ]]; then
                while true
                do
                    printr "[-] we found $file, do you want to use it ? please write, "yes" or "no""
                    read result
                    if [ "$result" = "yes" ]; then
                        echo "$file"
                        unset ipsw
                        ipsw=$file
                        break
                    elif [ "$result" = "no" ]; then
                        break
                    fi
                done
            fi
        done
    fi
fi

# Check if ipsw is an array
if [[ "$(declare -p ipsw)" =~ "declare -a" ]]; then
    while true
    do
        printb "Choose an IPSW by entering its number:"
        for i in "${!ipsw[@]}"; do
            echo "$((i+1)). ${ipsw[i]}"
        done
        read -p "Enter your choice: " choice

        if [[ ! "$choice" =~ ^[1-${#ipsw[@]}]$ ]]; then
            printr "Invalid IPSW number. Please enter a valid number."
        else
            printg "[*] We are gonna use ${ipsw[$choice-1]}"
            ipsw="${ipsw[$choice-1]}"
            break
        fi
    done
fi

unzip -o $ipsw BuildManifest.plist -d work/ >/dev/null

if [ "$downgrade" = "1" ] || [ "$jailbreak" = "1" ]; then
    printg "[*] Checking if the ipsw is for your device"
    ipswDevicesid=()
    ipswVers=""
    ipswDevId=""
    counter=0

    while [ ! "$deviceid" = "$ipswDevId" ]
    do
        if [ "$os" = 'Darwin' ]; then
            ipswDevId=$(/usr/bin/plutil -extract "SupportedProductTypes.$counter" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
        else
            ipswDevId=$("$dir"/PlistBuddy work/BuildManifest.plist -c "Print SupportedProductTypes:$counter" | sed 's/"//g')
        fi

        ipswDevicesid[counter]=$ipswDevId

        if [ "$ipswDevId" = "" ]; then # this is to stop looking for more devices as it pass the limit and can't find deviceid
            break
        fi

        let "counter=counter+1"
    done
    
    
    if [ "$ipswDevId" = "" ]; then
        printg "[/] it looks like this ipsw file is wrong, please check your ipsw"
        
        for element in "${ipswDevicesid[@]}"; do
            echo "this are the ipsw devices support: $element"
        done
        
        printr "and your device $deviceid is not in the list"
        read -p "want to continue ? click enter ..."
    fi


    printg "[*] Checking ipsw version"
    if [ "$os" = 'Darwin' ]; then
        ipswVers=$(/usr/bin/plutil -extract "ProductVersion" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
    else
        ipswVers=$("$dir"/PlistBuddy work/BuildManifest.plist -c "Print ProductVersion" | sed 's/"//g')
    fi
    
    if [[ ! "$version" = "$ipswVers" ]]; then
        printr "ipsw version is $ipswVers, and you specify $version"
        read -p "wrong ipsw version detected, click ENTER to continue or just ctrl + c to exit"
    fi

fi    

version_code=""

if [ "$downgrade" = "1" ]; then
    if [ "$os" = 'Darwin' ]; then
        version_code=$(/usr/bin/plutil -extract "ProductBuildVersion" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
    else
        version_code=$("$dir"/PlistBuddy work/BuildManifest.plist -c "Print ProductBuildVersion" | sed 's/"//g')
    fi
    
fi

if [ "$downgrade" = "1" ] || [ "$jailbreak" = "1" ]; then
    # extracting ipsw
    printg "[*] Extracting ipsw, hang on please ..." # this will extract the ipsw into ipsw/extracted
    unzip -n $ipsw -d $extractedIpsw >/dev/null
    #cp -v "$extractedIpsw/BuildManifest.plist" work/
    printg "[*] Got extract the IPSW successfully"
fi

if [ "$jailbreak" = "1" ]; then
    cp  "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/iBoot[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
    ramdisk/"$os"/gaster decrypt work/"$(awk "/""${model}""/{x=1}x&&/iBoot[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')" work/iBEC.dec
    ramdisk/"$os"/gaster reset
fi

# ============
# Ramdisk
# ============

# Dump blobs, and install pogo if needed 
if [ true ]; then
    mkdir -p blobs

    cd ramdisk
    chmod +x sshrd.sh
    printg "[*] Creating ramdisk"
    ./sshrd.sh "15.6"

    printg "[*] Booting ramdisk"
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

    if ! ("$dir"/sshpass -p 'alpine' ssh -ostricthostkeychecking=false -ouserknownhostsfile=/dev/null -o StrictHostKeyChecking=no -q -p2222 root@localhost "echo connected" &> /dev/null); then
        printg "[*] Waiting for the ramdisk to finish booting"
    fi

    while ! ("$dir"/sshpass -p 'alpine' ssh -ostricthostkeychecking=false -ouserknownhostsfile=/dev/null -o StrictHostKeyChecking=no -q -p2222 root@localhost "echo connected" &> /dev/null); do
        sleep 1
    done

    if [ "$(remote_cmd "/usr/bin/mgask HasBaseband | grep -E 'true|false'")" = "true" ]; then
        HasBaseband='--latest-baseband'
    else
        HasBaseband='--no-baseband'
    fi

    printg "[*] Mounting filesystems ..."
    if [[ "$version" = "13."* ]]; then
        remote_cmd "/sbin/mount_apfs /dev/disk0s1s1 /mnt1"
    fi

    if [ ! "$downgrade" = "1" ] && [[ ! "$version" = "13."* ]]; then
        remote_cmd "/usr/bin/mount_filesystems 2>/dev/null"
        if [ ! "$(remote_cmd "ls /mnt6/active" 2> /dev/null)" = "/mnt6/active" ]; then
            printr "[!] Active file does not exist! Please use SSH to create it, or it means that you are on ios 13 which this can't support it"
            printr "    /mnt6/active should contain the name of the UUID in /mnt6"
            printr "    When done, type reboot in the SSH session, then rerun the script"
            printr "    ssh root@localhost -p 2222"
            exit
        fi
        active=$(remote_cmd "cat /mnt6/active" 2> /dev/null)
    
    elif [ "$downgrade" = "1" ] && [[ ! "$version" = "13."* ]]; then
        remote_cmd "/usr/bin/mount_filesystems_nouser 2>/dev/null"
    fi
    
    mkdir -p "boot/${deviceid}"

    if [ ! -e blobs/"$deviceid"-"$version".shsh2 ]; then
        remote_cmd "cat /dev/rdisk1" | dd of=dump.raw bs=256 count=$((0x4000)) 
        "$dir"/img4tool --convert -s blobs/"$deviceid"-"$version".shsh2 dump.raw
        printg "[*] Converting blob"
        sleep 3
        rm dump.raw

    fi

    "$dir"/img4tool -e -s blobs/"$deviceid"-"$version".shsh2 -m work/IM4M >/dev/null
    printg "[*] Dumpped SHSH"

    printg "[*] Checking device version"
    remote_cp other/plutil root@localhost:/mnt1/

    SystemVersion=$(remote_cmd "chmod +x /mnt1/plutil && /mnt1/plutil -key ProductVersion /mnt1/System/Library/CoreServices/SystemVersion.plist")
    printg "the version that the device is currently in is $SystemVersion"

    if [ "$jailbreak" = "1" ]; then
        printg "[*] Patching kernel" # this will send and patch the kernel
        cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
        cp  work/"$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" work/kernelcache 
        
        if [[ "$deviceid" == "iPhone8"* ]] || [[ "$deviceid" == "iPad6"* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
            python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw --extra work/kpp.bin >/dev/null
        else
            python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw >/dev/null
        fi
        
        "$dir"/img4 -i work/kernelcache -o work/kcache.raw >/dev/null


        "$dir"/Kernel64Patcher work/kcache.raw work/kcache.patched `if [ "$ptraceDisabled" = "1" ]; then echo "-t"; fi` `if [ "$aslrDisabled" = "1" ]; then echo "-c"; fi` `if [[ "$version" = "15."* ]]; then echo "-e -o -r -b15"; fi` `if [[ "$version" = "14."* ]]; then echo "-b"; fi` `if [[ "$version" = "13."* ]]; then echo "-b13 -n"; fi` `if [ ! "$taurine" = "1" ]; then echo "-l"; fi` >/dev/null

        sysDir="/mnt6/$active/"
        if [[ "$version" = "13."* ]]; then
            sysDir="/mnt1/"
        fi
        remote_cp work/kcache.patched root@localhost:"$sysDir"System/Library/Caches/com.apple.kernelcaches/kcache.patched >/dev/null
        #remote_cp boot/"${deviceid}"/kernelcache.img4 "root@localhost:/mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kernelcache" >/dev/null
        remote_cp binaries/$(if [[ "$version" = "13."* ]]; then echo "Kernel13Patcher.ios"; else echo "Kernel15Patcher.ios"; fi) root@localhost:/mnt1/private/var/root/Kernel15Patcher.ios >/dev/null
        remote_cmd "/usr/sbin/chown 0 /mnt1/private/var/root/Kernel15Patcher.ios"
        remote_cmd "/bin/chmod 755 /mnt1/private/var/root/Kernel15Patcher.ios"
        sleep 1
        if [ ! $(remote_cmd "/mnt1/private/var/root/Kernel15Patcher.ios ${sysDir}System/Library/Caches/com.apple.kernelcaches/kcache.patched ${sysDir}System/Library/Caches/com.apple.kernelcaches/kcache.patchedB  2>/dev/null") ]; then
            printg "you have the kernelpath already installed "
        fi

        sleep 2
        remote_cp root@localhost:"$sysDir"System/Library/Caches/com.apple.kernelcaches/kcache.patchedB work/ # that will return the kernelpatcher in order to be patched again and boot with it 
        
        if [[ "$deviceid" == *'iPhone8'* ]] || [[ "$deviceid" == *'iPad6'* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
            python3 -m pyimg4 im4p create -i "work/$(if [ "$taurine" = "1" ]; then echo "kcache.patched"; else echo "kcache.patchedB"; fi)" -o work/kcache.im4p -f rkrn --extra work/kpp.bin --lzss >/dev/null
        else
            python3 -m pyimg4 im4p create -i "work/$(if [ "$taurine" = "1" ]; then echo "kcache.patched"; else echo "kcache.patchedB"; fi)" -o work/kcache.im4p -f rkrn --lzss >/dev/null
        fi

        remote_cmd "rm -f ${sysDir}System/Library/Caches/com.apple.kernelcaches/kcache.raw ${sysDir}System/Library/Caches/com.apple.kernelcaches/kcache.patched ${sysDir}System/Library/Caches/com.apple.kernelcaches/kcache.im4p"
        python3 -m pyimg4 img4 create -p work/kcache.im4p -o work/kernelcache.img4 -m work/IM4M >/dev/null

        #"$dir"/kerneldiff work/kcache.raw work/kcache.patchedB work/kc.bpatch
        #"$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" -o work/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch `if [ "$os" = 'Linux' ]; then echo "-J"; fi`
        #remote_cp root@localhost:/mnt6/$active/System/Library/Caches/com.apple.kernelcaches/kernelcachd work/kernelcache.img4
        cp -v "work/kernelcache.img4" "boot/${deviceid}"
        printg "[*] Finished of patching the kernel"
        
        remote_cmd "/bin/mkdir -p /mnt1/Applications/dualra1n-loader.app && /bin/mkdir -p /mnt1/Applications/trollstore.app"

        printg "[*] installing dualra1n-loader"
        unzip -o other/dualra1n-loader.ipa -d other/
        remote_cp other/Payload/dualra1n-loader.app root@localhost:/mnt1/Applications/
        
        printg "[*] Saving snapshot"
        if [ ! "$(remote_cmd "/usr/bin/snaputil -c orig-fs /mnt1")" ]; then
            printr "[-] the snapshot are already created, SKIPPING ..."
        fi

        if [ ! $(remote_cmd "trollstoreinstaller TV") ]; then
            printg "[/] error installing trollstore on TV app"
        fi

        printg "[*] Fixing dualra1n-loader"
        if [ ! $(remote_cmd "chmod +x /mnt1/Applications/dualra1n-loader.app/dualra1n* && /usr/sbin/chown 33 /mnt1/Applications/dualra1n-loader.app/dualra1n-loader && /bin/chmod 755 /mnt1/Applications/dualra1n-loader.app/dualra1n-helper && /usr/sbin/chown 0 /mnt1/Applications/dualra1n-loader.app/dualra1n-helper" ) ]; then
            printb "install dualra1n-loader using trollstore or another methods"
        fi

        if [[ "$version" = "13."* ]]; then
            printg "[*] DONE ... now reboot and boot again"   
            remote_cmd "/sbin/reboot"
            exit;
        fi

        if [ "$taurine" = 1 ]; then
            printb "installing taurine"
            remote_cp other/taurine/* root@localhost:/mnt1/
            printg "[*] Taurine sucessfully copied"
            _do_localboot
            printg "[*] Finished, now your downgrade is jailbroken, you can boot it"
            remote_cmd "/sbin/reboot"
            exit;
        fi

        printb "installing JBINIT jailbreak, thanks palera1n"
        printg "[*] Copying files to rootfs"
        remote_cmd "rm -rf /mnt1/jbin /mnt1/.installed_palera1n"
        sleep 1
        remote_cmd "mkdir -p /mnt1/jbin/binpack /mnt1/jbin/loader.app"
        sleep 1

        # this is the jailbreak of palera1n being installing 
        
        remote_cp -r other/rootfs/* root@localhost:/mnt1/
        remote_cmd "ldid -s /mnt1/jbin/launchd /mnt1/jbin/jbloader /mnt1/jbin/jb.dylib"
        remote_cmd "chmod +rwx /mnt1/jbin/launchd /mnt1/jbin/jbloader"
        remote_cmd "tar -xvf /mnt1/jbin/binpack/binpack.tar -C /mnt1/jbin/binpack/"
        sleep 1
        remote_cmd "rm /mnt1/jbin/binpack/binpack.tar"
        remote_cmd "/usr/sbin/nvram auto-boot=true"
        printg "[*] Finished of jailbreaking"
        _do_localboot        
        printg "[*] DONE ... now reboot and boot again"   
        remote_cmd "/sbin/reboot"
        exit;

    fi
    
    printg "[*] extracting kernel ..." # this will send and patch the kernel
    
    cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/kernelcache"
    
    if [[ "$deviceid" == "iPhone8"* ]] || [[ "$deviceid" == "iPad6"* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
        python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw --extra work/kpp.bin >/dev/null
    else
        python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw >/dev/null
    fi

    "$dir"/img4 -i work/kernelcache -o work/kcache.raw >/dev/null

    printg "[*] extracted"

    printb "Reboot into recovery mode ..."
    remote_cmd "/usr/sbin/nvram auto-boot=false"
    remote_cmd "/sbin/reboot"
    sleep 10

    if [ "$(get_device_mode)" = "dfu" ]; then
        printb "device in false dfu mode. please force reboot and try to put it on dfu mode by precing the button."
        read -p "click enter if you got dfu mode on the iphone"
        "$dir"/gaster pwn
    else
        _wait recovery
        sleep 4
        _dfuhelper "$cpid"
        sleep 3
    fi

        

    printb "[* ]Patching some boot files..."
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
                "$dir"/pzb -g Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."OS"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache "$ipswurl"
            else
                "$dir"/pzb -g Firmware/"$(../binaries/Linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')".trustcache "$ipswurl"
            fi
            cd ..
        else
            #that will extract the files needed
            cp  "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/iBSS[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            cp  "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/iBoot[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            cp  "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/DeviceTree[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            cp  "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            
            if [ "$os" = 'Darwin' ]; then
                cp "$extractedIpsw"/Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."OS"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache work/
            else
                cp "$extractedIpsw"/Firmware/"$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')".trustcache work/
            fi
        fi

        if [ "$os" = "Darwin" ]; then
            "$dir"/img4 -i work/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."OS"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache -o work/trustcache.img4 -M work/IM4M -T rtsc >/dev/null
        else
            "$dir"/img4 -i work/"$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')".trustcache -o work/trustcache.img4 -M work/IM4M -T rtsc >/dev/null
        fi

        printg "[*] Finished moving the boot files to work"
        sleep 2
        
        printg "[*] Decrypthing ibss and iboot"
        "$dir"/gaster decrypt work/"$(awk "/""${model}""/{x=1}x&&/iBSS[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]dfu[/]//')" work/iBSS.dec
        
        sleep 1
        "$dir"/iBoot64Patcher work/iBSS.dec work/iBSS.patched -n >/dev/null
        "$dir"/img4 -i work/iBSS.patched -o work/iBSS.img4 -M work/IM4M -A -T ibss >/dev/null
        
        "$dir"/gaster decrypt work/"$(awk "/""${model}""/{x=1}x&&/iBoot[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')" work/iBEC.dec >/dev/null
        sleep 1

        "$dir"/iBoot64Patcher work/iBEC.dec work/iBEC.patched -b "-v wdt=-1 `if [ "$cpid" = '0x8960' ] || [ "$cpid" = '0x7000' ] || [ "$cpid" = '0x7001' ]; then echo "-restore"; fi`" -n >/dev/null
        "$dir"/img4 -i work/iBEC.patched -o work/iBEC.img4 -M work/IM4M -A -T "$(if [[ "$cpid" == *"0x801"* ]]; then echo "ibss"; else echo "ibec"; fi)" >/dev/null

        if [ "$keyServer" = "1" ]; then
            printg "[*] patching ibss and ibec for futurerestore downgrade"
            mkdir -p $TMPDIR/futurerestore
            cp  "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/iBEC[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            "$dir"/gaster decrypt work/"$(awk "/""${model}""/{x=1}x&&/iBEC[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]dfu[/]//')" work/iBECFuture.dec >/dev/null
            "$dir"/iBoot64Patcher work/iBECFuture.dec work/iBECFuture.patched -b "rd=md0 nand-enable-reformat=0x1 -v -restore debug=0x2014e keepsyms=0x1 amfi=0xff amfi_allow_any_signature=0x1 amfi_get_out_of_my_way=0x1 cs_enforcement_disable=0x1" -n >/dev/null
            "$dir"/img4 -i work/iBECFuture.patched -o "$TMPDIR/futurerestore/ibec.$model.$version_code.patched.img4" -M work/IM4M -A -T ibec >/dev/null
            cp -av work/iBSS.img4 $TMPDIR/futurerestore/ibss.$model.$version_code.patched.img4
            printb "sucessfully create files for futurerestore"
        fi

        printg "[*] Patching the kernel"
        "$dir"/Kernel64Patcher work/kcache.raw work/kcache.patched `if [ "$ptraceDisabled" = "1" ]; then echo "-t"; fi` `if [ "$aslrDisabled" = "1" ]; then echo "-c"; fi` `if [[ "$version" = "15."* ]]; then echo "-e -o -r -b15"; fi` `if [[ "$version" = "14."* ]]; then echo "-b"; fi` `if [[ "$version" = "13."* ]]; then echo "-b13 -n"; fi` >/dev/null
        
        if [[ "$deviceid" == *'iPhone8'* ]] || [[ "$deviceid" == *'iPad6'* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
            python3 -m pyimg4 im4p create -i work/kcache.patched -o work/kcache.im4p -f rkrn --extra work/kpp.bin --lzss >/dev/null
        else
            python3 -m pyimg4 im4p create -i work/kcache.patched -o work/kcache.im4p -f rkrn --lzss >/dev/null
        fi

        python3 -m pyimg4 img4 create -p work/kcache.im4p -o work/kernelcache.img4 -m work/IM4M >/dev/null

        printg "[*] Patching the kernel to restore using futurerestore"
        "$dir"/Kernel64Patcher work/kcache.raw work/krnl.patched -a -b >/dev/null
    
        if [[ "$deviceid" == "iPhone8"* ]] || [[ "$deviceid" == "iPad6"* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
            python3 -m pyimg4 im4p create -i work/krnl.patched -o work/krnl.im4p --extra work/kpp.bin -f rkrn --lzss >/dev/null
        else
            python3 -m pyimg4 im4p create -i work/krnl.patched -o work/krnl.im4p -f rkrn --lzss >/dev/null
        fi
    
        printg "[*] Patching devicetree"
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
        
        printg "[*] Patching the restored_external and asr, and saving them into the ramdisk ..."
        if [ "$os" = "Darwin" ]; then
            hdiutil attach work/ramdisk.dmg -mountpoint /tmp/SSHRD >/dev/null
            mounted="/tmp/SSHRD"
    
            "$dir"/asr64_patcher $mounted/usr/sbin/asr work/patched_asr >/dev/null
            "$dir"/ldid -e $mounted/usr/sbin/asr > work/asr.plist
            "$dir"/ldid -Swork/asr.plist work/patched_asr
            chmod -R 755 work/patched_asr
            rm $mounted/usr/sbin/asr

            mv work/patched_asr $mounted/usr/sbin/asr


            if [[ ! "$version" = "13."* ]]; then
                cp $mounted/usr/local/bin/restored_external work/restored_external
                "$dir"/restored_external64_patcher work/restored_external work/patched_restored_external >/dev/null
                "$dir"/ldid -e work/restored_external > work/restored_external.plist
                "$dir"/ldid -Swork/restored_external.plist work/patched_restored_external
                chmod -R 755 work/patched_restored_external
                rm $mounted/usr/local/bin/restored_external
                mv work/patched_restored_external $mounted/usr/local/bin/restored_external
            fi
            
    
            hdiutil detach -force /tmp/SSHRD
        else
    
            "$dir"/hfsplus work/ramdisk.dmg extract /usr/sbin/asr work/asr >/dev/null
            "$dir"/asr64_patcher work/asr work/patched_asr >/dev/null
            "$dir"/ldid -e work/asr > work/asr.plist
            "$dir"/ldid -Swork/asr.plist work/patched_asr
            chmod 755 work/patched_asr

            "$dir"/hfsplus work/ramdisk.dmg rm /usr/sbin/asr
            "$dir"/hfsplus work/ramdisk.dmg add work/patched_asr /usr/sbin/asr
            "$dir"/hfsplus work/ramdisk.dmg chmod 100755 /usr/sbin/asr

            if [[ ! "$version" = "13."* ]]; then

                "$dir"/hfsplus work/ramdisk.dmg extract /usr/local/bin/restored_external work/restored_external >/dev/null
                "$dir"/restored_external64_patcher work/restored_external work/patched_restored_external >/dev/null
                "$dir"/ldid -e work/restored_external > work/restored_external.plist
                "$dir"/ldid -Swork/restored_external.plist work/patched_restored_external
                chmod 755 work/patched_restored_external
                "$dir"/hfsplus work/ramdisk.dmg rm /usr/local/bin/restored_external
                "$dir"/hfsplus work/ramdisk.dmg add work/patched_restored_external /usr/local/bin/restored_external
                "$dir"/hfsplus work/ramdisk.dmg chmod 100755 /usr/local/bin/restored_external
            fi
        fi
    
        python3 -m pyimg4 im4p create -i work/ramdisk.dmg -o work/rdsk.im4p -f rdsk >/dev/null
    
        cp -v work/*.img4 "boot/${deviceid}" # copying all file img4 to boot

        printg "[*] Sucess Patching the boot files"
        
        printg "[*] Checking if the llb was already replaced"

        if [ ! -e "boot/${deviceid}/.llbreplaced" ]; then
            printg "[*] Patching the llb in the ipsw to avoid false dfu mode"
            printg "[=] Hi, please i need that you write the ios version that this device is on or the version of the ios that it was on (if this device is already downgraded), most of the time is the lastest version of ios. write 0 if you want to skip this (it is not recommended to skip this as this can avoid false dfu mode)"
        
            while true
            do
                if [ ! "$version" = "$SystemVersion" ] && [ ! "$SystemVersion" = "" ]; then
                    printb "Version detected!. we are gonna use $SystemVersion"
                    ipswLLB=$(curl -sL "https://api.ipsw.me/v4/device/$deviceid?type=ipsw" | "$dir"/jq '.firmwares | .[] | select(.version=="'$SystemVersion'")' | "$dir"/jq -s '.[0] | .url' --raw-output)
                else
                    read result
                    if [ "$result" = "0" ]; then
                        printg "SKIPPING ..."
                        break
                    fi
                    ipswLLB=$(curl -sL "https://api.ipsw.me/v4/device/$deviceid?type=ipsw" | "$dir"/jq '.firmwares | .[] | select(.version=="'$result'")' | "$dir"/jq -s '.[0] | .url' --raw-output)
                fi

                sleep 1

                cd work/
                if [ $("$dir"/pzb -g "$(awk "/""${model}""/{x=1}x&&/LLB[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswLLB" >/dev/null) ]; then
                    printr "failed to download LLB"
                fi
                cd ..

                if [ ! -e "work/$(awk "/""${model}""/{x=1}x&&/LLB[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')" ]; then
                    printr "[-] ERROR downloading the llb please check the ios version and write it again. if this error happens a lot of time please use 0 to skip llb"
                else
                    printg "[*] LLB downloaded correctly"
                    printg "[*] putting this LLB into the ipsw"
                    cp -f work/$(awk "/""${model}""/{x=1}x&&/LLB[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//') "$extractedIpsw/Firmware/all_flash/$(awk "/""${model}""/{x=1}x&&/LLB[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')"
                    cd $extractedIpsw
                    zip --update "$mainDir/$ipsw" Firmware/all_flash/"$(awk "/""${model}""/{x=1}x&&/LLB[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')" Firmware/all_flash//$(awk "/""${model}""/{x=1}x&&/LLB[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')
                    cd "$mainDir"
                    printg "[*] Replaced LLB suscessfully"

                    touch "boot/${deviceid}/.llbreplaced"
                    break
                fi
            done
        fi
        sleep 1
        
        set +e

        "$dir"/gaster reset >/dev/null
        sleep 1
        "$dir"/irecovery -f "blobs/"$deviceid"-"$version".shsh2" >/dev/null

        if [ "$dontRestore" = "1" ]; then
            printg "[*] Finished creating boot files now you can --boot in order to get boot to the system"
            exit;
        fi
        
        printg "[*] Executing futurerestore ..."
        _runFuturerestore
        sleep 2

        printg "if futurerestore failed you can try execute the command below"
        echo -e "\033[1;33mif futurerestore didn't finish succesfully please try to run (with sudo or without) this command:\033[0m \033[1m$dir/futurerestore -t blobs/$deviceid-$version.shsh2 --use-pwndfu --skip-blob --rdsk work/rdsk.im4p --rkrn work/krnl.im4p --latest-sep $HasBaseband $ipsw\033[0m"

        printb "if futurerestore restore sucess, you can boot using  --boot"
    fi
fi


} 2>&1 | tee logs/${log}
