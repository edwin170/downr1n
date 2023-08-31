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

- If you want to fix recovery mode, try copying the firmware/all_flash/* from an IPSW of the version you are or were on before the downgrade to the IPSW for the iOS that you want to downgrade. This should restore recovery mode.

# Warnings
- I am **NOT** responsible for any data loss. The user of this program accepts responsibility should something happen to their device.
 **If your device is stuck in recovery, please run one of the following:**
   - futurerestore --exit-recovery
   - irecovery -n

# fix some problems to boot
- please execute wikiproxy.py manually.

- If you encounter issues with futurerestore, try manually executing: ./binaries/$(uname)/futurerestore -t blobs/(oneoftheblobs) --use-pwndfu --skip-blob --rdsk work/rdsk.im4p --rkrn work/krnl.im4p --latest-sep (if your device has a baseband, use --latest-baseband, if not, use --no-baseband') ipsw/*.ipsw.

- remember if you will use the next command or will activate localboot it is better that you first downgrade and when you success you can use --jailbreak to jailbreak the device and it will ask you to activate localboot path. why do this because the localboot need to be executed after --jailbreak
- Sometimes, issues such as deep sleep or iOS not booting occur. To mitigate this, two options --localboot and --fsboot were added. Both are patches by the palera1n team meant to fix boot problems. You should use them when creating boot files, for example --downgrade () --dont-restore (--localboot) or (--fsboot). After finishing, boot with --boot (--localboot) or (--fsboot). It's not necessary to use them, but if you encounter problems, you can.

# Need Help?
- Join our discord server: https://discord.gg/AjEHs5ug

# How to Jailbreak?
- Jailbreak with dualra1n-loader: ./downr1n --jailbreak (YourVer = 14.3). Note: this does not actually jailbreak the device. When I say "jailbreak," I'm referring to the process of installing Sileo and bootstrapping the device. Dualra1n-loader only installs Sileo and bootstraps with the kernel patch.

- Taurine: ./downr1n --jailbreak (YourVer = 14.3) --taurine. Note: this is not recommended.

# This project was created with love by Edwin :)

# Credits

<details><summary>Other credits for tools and codes used in downr1n</summary>

- [wikiproxy.py](https://github.com/afastaudir8/wikiproxy).

- [futurerestore](https://github.com/futurerestore/futurerestore) thank you for futurerestore.  

- [mineek](https://github.com/mineek/) because the original downgrade sunst0rm.

- [exploit](https://github.com/exploit3dguy/) for asrpatcher

- [iSuns9](https://github.com/iSuns9/restored_external64patcher) thank you for restored_external64patcher

- [Nathan](https://github.com/verygenericname) for the ramdisk
    
- [m1sta](https://github.com/m1stadev) for [pyimg4](https://github.com/m1stadev/PyIMG4)

- [tihmstar](https://github.com/tihmstar) for [pzb](https://github.com/tihmstar/partialZipBrowser)/original [iBoot64Patcher](https://github.com/tihmstar/iBoot64Patcher)/original [liboffsetfinder64](https://github.com/tihmstar/liboffsetfinder64)/[img4tool](https://github.com/tihmstar/img4tool)

- [xerub](https://github.com/xerub) for [img4lib](https://github.com/xerub/img4lib) and [restored_external](https://github.com/xerub/sshrd) in the ramdisk

- [libimobiledevice](https://github.com/libimobiledevice) for several tools used in this project (irecovery, ideviceenterrecovery etc), and [nikias](https://github.com/nikias) for keeping it up to date

- [Ralp0045](https://github.com/Ralph0045/Kernel64Patcher) amazing dtree_patcher and kernel64patcher ;)

</p>
</details>
