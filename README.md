# downr1n
Downr1n enables tethered downgrades of checkm8 iOS devices to iOS 14 and 15.

NOTE: iOS 16 is NOT SUPPORTED.

In general, dual booting is a better option than downgrading if you have the necessary storage. if you activate the localboot path it would be ultra better believe me xd.

# Usage
1: Download the IPSW file and place it in the ipsw/ directory.

2: Execute the script without using 'sudo' on Linux. if it doesn't work please use sudo then.

Example: ./downr1n.sh --downgrade 14.3

The various command-line options are as follows:

      --downgrade        : Downgrade your device to iOS 14 tethered.

      --dfuhelper        : A helper tool to transition A11 devices from recovery mode to DFU mode.

      --jailbreak        : Jailbreak with pogo. Usage: `./downr1n.sh --jailbreak 14.8`.

      --taurine          : Jailbreak with taurine. Usage: `./downr1n.sh --jailbreak 14.3 --taurine`.

      --boot             : Boot the device.

      --dont-restore     : Avoids using futurerestore, this can be used to only create boot files. Example: `--downgrade 14.3 --dont-restore`.

      --fixBoot          : Boots the device using fsboot.

      --debug            : Debug the script.

---

# Dependencies
- please exeucte this command: python3 -m pip install fastapi aiohttp ujson wikitextparser uvicorn pyimg4.
- A disabled passcode on A10 and A11 devices.
- unzip, python3, libimobiledevice-utils, libusbmuxd-tools, xz-utils.
- An .iPSW file containing iOS 14 or 15.
- A device running macOS or a Linux distro. It is recommended to use macOS, as it is likely more stable and faster.

# Issues Putting Device in PwnDFU Mode

- A DFU mode exists where the device's screen is black. However, when downgrading the device, recovery mode also turns black. To put the device into PwnDFU mode, you need to put it into real DFU mode by pressing poweroff+(volume down or home button). Look for a tutorial on YouTube to understand how. Once in PwnDFU mode, execute ./binaries/$(uname)/gaster pwn to succeed. If the device is not in DFU mode, it will loop.

- If you want to fix recovery mode, try copying the firmware/all_flash/ iboot and llb files from an IPSW of the version you are or were on before the downgrade to the IPSW for the iOS that you want to downgrade. This should restore recovery mode.

<details><summary>didn't understand ?</summary>

alright if you didn't understand well before, first: extract your ipsw by using this command, 1: cd ipsw/, 2: unzip *.ipsw -d extracted, then it is going to extract everyfile from the ipsw so now second: take the ipsw from the lastest ios or the ios that you were before (i mean the ios when the blobs were taken) and extract it and go to extracted/firmware/all_flash there will be some files called iboot and llb (only the ones that has .im4p at the end) takes that file and put it on the downr1n ipsw (this ipsw will be the ios version that you want to downgrade with) and replace the llb and iboot with the laster ios ipsw ones and then put the mod one into the ipsw/ directory on downr1n and try downgrade with it, (important: we did unzip *.ipsw -d extracted at the start because we mustn't modify the iboot file that will be used to boot ios 14 or the ios that we want downgrade if we replace that with the one from the lastest ios, ios 14 will not work (because ofc they are different version)).

</p>
</details>


# Warnings
- I am **NOT** responsible for any data loss. The user of this program accepts responsibility should something happen to their device.
 **If your device is stuck in recovery, please run one of the following:**
   - futurerestore --exit-recovery
   - irecovery -n

# fix some problems to boot
- please execute wikiproxy.py manually if it gives problem with server key.

- remember if you will use the next command or will activate localboot it is better that you first downgrade and when you success you can use --jailbreak to jailbreak the device and it will ask you to activate localboot path. why do this because the localboot need to be executed after --jailbreak

# Need Help?
- Join our discord server: https://discord.gg/AjEHs5ug

# How to Jailbreak?
- Jailbreak with dualra1n-loader: ./downr1n --jailbreak (YourVer = 14.3). Note: this does not actually jailbreak the device. When I say "jailbreak," I'm referring to the process of installing Sileo and bootstrapping the device. Dualra1n-loader only installs Sileo and bootstraps with the kernel patch.

- Taurine: ./downr1n --jailbreak (YourVer = 14.3) --taurine. Note: this is not recommended.

# This project was created with love by Edwin :)

# Credits

<details><summary>Other credits for tools and codes used in downr1n</summary>

- [wikiproxy.py](https://github.com/afastaudir8/wikiproxy).

- [futurerestore](https://github.com/futurerestore/futurerestore) without futurerestore it couldn't be downgraded.  

- [palera1nLegacy](https://github.com/palera1n/palera1n/tree/legacy) some code based on palera1n legacy.

- [exploit](https://github.com/exploit3dguy/) for asrpatcher

- [iSuns9](https://github.com/iSuns9/restored_external64patcher) thank you for restored_external64patcher

- [Nathan](https://github.com/verygenericname) for the ramdisk
    
- [m1sta](https://github.com/m1stadev) for [pyimg4](https://github.com/m1stadev/PyIMG4)

- [tihmstar](https://github.com/tihmstar) for [pzb](https://github.com/tihmstar/partialZipBrowser)/original [iBoot64Patcher](https://github.com/tihmstar/iBoot64Patcher)/original [liboffsetfinder64](https://github.com/tihmstar/liboffsetfinder64)/[img4tool](https://github.com/tihmstar/img4tool)

- [xerub](https://github.com/xerub) for [img4lib](https://github.com/xerub/img4lib) and [restored_external](https://github.com/xerub/sshrd) in the ramdisk

- [libimobiledevice](https://github.com/libimobiledevice) for several tools used in this project (irecovery, ideviceenterrecovery etc), and [nikias](https://github.com/nikias) for keeping it up to date

- [Ralp0045](https://github.com/Ralph0045/Kernel64Patcher) amazing dtree_patcher and kernel64patcher ;)

- [mineek](https://github.com/mineek/sunst0rm) because the original idea.

</p>
</details>
