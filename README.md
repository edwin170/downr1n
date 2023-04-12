# please don't use this branch, this is for personal testing 

# downr1n
downgrade tethered checkm8 idevices ios 14, 15.

# Usage

download the ipsw and put it into ipsw/ directory

on linux use this without sudo.

Example: ./downr1n.sh --downgrade 14.3 

   
    --downgrade         downgrade tethered your device to ios 14.
   
    --dfuhelper         A helper to help get A11 devices into DFU mode from recovery mode
   
    --jailbreak        jailbreak with pogo. usage ./downr1n --jailbreak 14.8 
   
    --taurine          jailbreak with taurine. usage ./downr1n --jailbreak 14.3 --taurine
   
    --boot              this boot the device.
   
    --dont-restore      this will avoid the restore using futurerestore, this can be used if you wanted only create the boot files. example: --downgrade 14.3 --dont-restore
   
    --fixBoot           that will boot the device using fsboot
   
    --debug             Debug the scrip

---

# Dependencies
- A desactivated passcode on A10-A11 
- unzip, python3
- Update or Install libimobiledevice-utils, libusbmuxd-tools
- A IPSW iOS 14-15 
- a MACOS or LINUX, it's better that you use a mac it's more estable and faster

# problems putting the device on pwndfu mode

- there is a mode name dfu which the device is in black screen but when we downgrade the device recovery mode turn into black screen as well so to put the device into pwndfu mode you need to put it on the real dfu mode by pressing poweroff+(volumendown or homebutton) look at a tutorial on youtube to got it, when you are already pwndfu execute ./binaries/$(uname)/gaster pwn to pwdnfu but the device must be on dfu mode to success, if the device is not, it will loop.

- if you want to try fix the recovery mode. copying firmware/all_flash/* of a ipsw from the version that you are or you were before downgrade to the ipsw from the ios that you want to downgrade. that should come back the recovery mode. 

# Warnings
- I am **NOT** responsible for any data loss. The user of this program accepts responsibility should something happen to their device.
 **If your device is stuck in recovery, please run one of the following:**
   - futurerestore --exit-recovery
   - irecovery -n

# fix some problems to boot

- problems with futurerestore so execute manual ./binaries/$(uname)/futurerestore -t blobs/(oneoftheblobs) --use-pwndfu --skip-blob --rdsk work/rdsk.im4p --rkrn work/krnl.im4p --latest-sep (only if your device has baseband use it --latest-baseband if not use --no-baseband') ipsw/*.ipsw

- to improve the boot. rn not working at all but you can try it 
sometimes we have problems like deep sleep or the ios doesnt boot so i add two option for that reason --localboot and --fsboot. both are patchers by palera1n team in order to fix some problems in the boot so you must use it when you will create boot files for example --downgrade () --dont-restore (--localboot) or (--fsboot), when that finish creating that you just have to boot for example --boot (--localboot) or (--fsboot), its not neccessary that you need to use them but if you had some problems you can

# help with something join to discord server https://discord.gg/AjEHs5ug
# How do i jailbreak it ?

- jailbreak with pogo: ./downr1n --jailbreak (YourVer = 14.3) 

- taurine: ./downr1n --jailbreak (YourVer = 14.3) --taurine 

# Credits

# with love Edwin :)

<details><summary>thanks to</summary>
<p>

- [Edwin](https://github.com/edwin170) owner :)
 
</details>

<details><summary>Other credits for tools and codes used in downr1n</summary>

- [futurerestore](https://github.com/futurerestore/futurerestore) thank you for futurerestore.  

- [mineek](https://github.com/mineek/) because sunst0rm

- [exploit](https://github.com/exploit3dguy/) for asrpatcher

- [iSuns9](https://github.com/iSuns9/restored_external64patcher) thank you for restored_external64patche

- [Nathan](https://github.com/verygenericname) for the ramdisk
    
- [m1sta](https://github.com/m1stadev) for [pyimg4](https://github.com/m1stadev/PyIMG4)

- [tihmstar](https://github.com/tihmstar) for [pzb](https://github.com/tihmstar/partialZipBrowser)/original [iBoot64Patcher](https://github.com/tihmstar/iBoot64Patcher)/original [liboffsetfinder64](https://github.com/tihmstar/liboffsetfinder64)/[img4tool](https://github.com/tihmstar/img4tool)

- [xerub](https://github.com/xerub) for [img4lib](https://github.com/xerub/img4lib) and [restored_external](https://github.com/xerub/sshrd) in the ramdisk

- [libimobiledevice](https://github.com/libimobiledevice) for several tools used in this project (irecovery, ideviceenterrecovery etc), and [nikias](https://github.com/nikias) for keeping it up to date

- [Ralp0045](https://github.com/Ralph0045/Kernel64Patcher) amazing dtree_patcher and kernel64patcher ;)

</p>
</details>
