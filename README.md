# downr1n
downgrade tethered checkm8 iDevices to iOS 14 or 15.

# Usage

Download the iPSW and put it into ipsw/ directory

Example: ./downr1n.sh --downgrade 14.3 

   
    --downgrade         downgrade tethered your device to iOS 14.* or 15.*
   
    --dfuhelper         A helper to help get A11 devices into DFU mode from recovery mode
   
    --jailbreak        jailbreak with pogo. usage ./downr1n --jailbreak 14.8 
   
    --taurine          jailbreak with taurine. usage ./downr1n --jailbreak 14.3 --taurine
   
    --boot              this will boot the iDevice.
   
    --dont-restore      this will avoid the restore using futurerestore, this can be used if you only wanted to create the boot files. example: --downgrade 14.3 --dont-restore
   
    --fixBoot           this will boot the device using fsboot
   
    --debug             Debug the script

---

# Dependencies
- A deactivated passcode on A10-A11 Devices
- unzip, python3
- Update or Install libimobiledevice-utils, libusbmuxd-tools
- An iOS 14-15 iPSW 
- a macOS or Linux Computer, it's better that you use a Mac because it's more stable and faster

# Warnings
- I am **NOT** responsible for any data loss. The user of this program accepts responsibility should something happen to their device.
 **If your device is stuck in recovery, please run one of the following:**
   - futurerestore --exit-recovery
   - irecovery -n

# fix some problems to boot

rn not working at all but you can try it 
sometimes we have problems like deep sleep or the ios doesnt boot so i add two option for that reason --localboot and --fsboot. both are patchers by palera1n team in order to fix some problems in the boot so you must use it when you will create boot files for example --downgrade () --dont-restore (--localboot) or (--fsboot), when that finish creating that you just have to boot for example --boot (--localboot) or (--fsboot), its not neccessary that you need to use them but if you had some problems you can

# help with something join to discord server https://discord.gg/S9XyNkwqRb
# How do i jailbreak my downgraded iDevice ?

- jailbreak with pogo: ./downr1n --jailbreak (YourVer = 14.3) 

- taurine: ./downr1n --jailbreak (YourVer = 14.3) --taurine 

# Credits

# with love from Edwin :)

<details><summary>thanks to</summary>
<p>

- [Edwin](https://github.com/edwin170) owner :)
 
</details>

<details><summary>Other credits for tools and code used in downr1n</summary>

- [mineek](https://github.com/mineek/) because sunst0rm

- [exploit](https://github.com/exploit3dguy/) for asr64_patcher

- [iSuns9](https://github.com/iSuns9/)

- [Nathan](https://github.com/verygenericname) for the SSH ramdisk
    
- [m1sta](https://github.com/m1stadev) for [pyimg4](https://github.com/m1stadev/PyIMG4)

- [tihmstar](https://github.com/tihmstar) for [pzb](https://github.com/tihmstar/partialZipBrowser)/original [iBoot64Patcher](https://github.com/tihmstar/iBoot64Patcher)/original [liboffsetfinder64](https://github.com/tihmstar/liboffsetfinder64)/[img4tool](https://github.com/tihmstar/img4tool)

- [xerub](https://github.com/xerub) for [img4lib](https://github.com/xerub/img4lib) and [restored_external](https://github.com/xerub/sshrd) in the ramdisk

- [libimobiledevice](https://github.com/libimobiledevice) for several tools used in this project (irecovery, ideviceenterrecovery, etc) and [nikias](https://github.com/nikias) for keeping them up to date

- [Ralp0045](https://github.com/Ralph0045/Kernel64Patcher) for the amazing dtree_patcher and Kernel64Patcher ;)

</p>
</details>
