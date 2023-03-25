# downr1n
A tethered downgrade tool for checkm8 idevices on ios 14 & 15.

# Usage

download the ipsw and put it into ipsw/ directory

Example: ./downr1n.sh --downgrade 14.3 


    --downgrade         downgrade tethered your device to ios 14,15.

    --dfuhelper         A helper to help get A11 devices into DFU mode from recovery mode

    --jailbreak        jailbreak with pogo. usage ./downr1n --jailbreak 14.8 

    --taurine          jailbreak with taurine. usage ./downr1n --jailbreak 14.3 --taurine

    --boot              this boot the device.

    --fixBoot           that will boot the device using fsboot

    --debug             Debug the script

---

# Dependencies
- A deactivated passcode on A10-A11 
- unzip, python3
- Update or Install libimobiledevice-utils, libusbmuxd-tools
- A IPSW iOS 14-15 
- A MACOS or LINUX computer, it's better that you use a mac it's more stable and faster

# Warnings
- I am **NOT** responsible for any data loss. The user of this program accepts responsibility should something happen to their device.
 **If your device is stuck in recovery, please run one of the following:**
   - futurerestore --exit-recovery
   - irecovery -n


# How do i jailbreak it ?

- jailbreak with pogo: ./downr1n --downgrade (YourVer = 14.3) --jailbreak 

- taurine: ./downr1n --downgrade (YourVer = 14.3) --jailbreak --taurine

# Credits

# with love Edwin :)

<details><summary>thanks to</summary>
<p>

- [Edwin](https://github.com/edwin170) owner :)
 
</details>

<details><summary>Other credits for tools and codes used in downr1n</summary>

- [mineek](https://github.com/mineek/) because sunst0rm

- [exploit](https://github.com/exploit3dguy/) for asrpatcher

- [iSuns9](https://github.com/iSuns9/)

- [Nathan](https://github.com/verygenericname) for the ramdisk
    
- [m1sta](https://github.com/m1stadev) for [pyimg4](https://github.com/m1stadev/PyIMG4)

- [tihmstar](https://github.com/tihmstar) for [pzb](https://github.com/tihmstar/partialZipBrowser)/original [iBoot64Patcher](https://github.com/tihmstar/iBoot64Patcher)/original [liboffsetfinder64](https://github.com/tihmstar/liboffsetfinder64)/[img4tool](https://github.com/tihmstar/img4tool)

- [xerub](https://github.com/xerub) for [img4lib](https://github.com/xerub/img4lib) and [restored_external](https://github.com/xerub/sshrd) in the ramdisk

- [libimobiledevice](https://github.com/libimobiledevice) for several tools used in this project (irecovery, ideviceenterrecovery etc), and [nikias](https://github.com/nikias) for keeping it up to date

- [Ralp0045](https://github.com/Ralph0045/Kernel64Patcher) amazing dtree_patcher and kernel64patcher ;)

</p>
</details>
