# downr1n
Downr1n enables tethered downgrades of checkm8 iOS devices to iOS 15, 14 and 13.

there is dualra1n too, which is a dualboot for ios like having two different ios [dualra1n](https://github.com/dualra1n/dualra1n), i would recommend more dualra1n as it is very stable.

# Usage
1: Download the IPSW file and place it in the ipsw/ directory.

2: execute: ./downr1n.sh --downgrade 14.3.

Example: ./downr1n.sh --downgrade 14.3

The various command-line options are as follows:

      --downgrade        : Downgrade your device to iOS 14 tethered.

      --jailbreak        : Jailbreak with dualra1n-loader. Usage: `./downr1n.sh --jailbreak 14.8`.

      --taurine          : Jailbreak with taurine. Usage: `./downr1n.sh --jailbreak 14.3 --taurine`.

      --boot             : Boot the device.

      --keyServer         use this option to downgrade when the keys server is in problem. only on MacOS. use ex: --downgrade 14.8 --keyServer 

      --dont-restore     : Avoids using futurerestore, this can be used to only create boot files. Example: `--downgrade 14.3 --dont-restore`.

      --debug            : Debug the script.

---

# Dependencies
- please execute this command: python3 -m pip install pyimg4[compression] fastapi aiohttp ujson wikitextparser uvicorn.
- unzip, python3, libimobiledevice-utils, libusbmuxd-tools, xz-utils, wget, curl, git, libssl-dev, usbmuxd.
- A disabled passcode on A10 and A11 devices.
- An .iPSW file containing iOS 15, 14, 13.
- A device running macOS or a Linux distro. It is recommended to use macOS, as it is likely more stable and faster. and for linux it is recommended to use ubuntu or debian.

# Issues Putting Device in PwnDFU Mode

- A DFU mode exists where the device's screen is black. However, when downgrading the device, recovery mode also turns black. To put the device into PwnDFU mode, you need to put it into real DFU mode by pressing poweroff+(volume down or home button). Look for a tutorial on YouTube to understand how. Once in PwnDFU mode, execute ./binaries/$(uname)/gaster pwn to succeed. If the device is not in DFU mode, it will loop.

# importants things

- A8/A8x devices downr1n is not recommended please instead use dualra1n with --downgrade option (if you don't have enough storage for a dualboot)

- you can't downgrade an iphone x if the device is on ios 16

- downgrading ios 16 to 14 or another version, you will have to bypass the setup somehow. good luck on it.

- on ios 13 the touch id doesn't work so the home button on iphone 7 will not work sadly.

- you can't downgrade to ios 14.2 lower on a11 devices

# Warnings
- I am **NOT** responsible for any data loss. The user of this program accepts responsibility should something happen to their device.
 **If your device is stuck in recovery, please run one of the following:**
   - futurerestore --exit-recovery
   - irecovery -n

# fix some problems

- please execute wikiproxy.py manually if it gives problem with server key. for ex: sudo python3 wikiproxy.py

- if the error still after above fix, if this happend to you when you are downgrading with futurerestore again please add this arg --keyServer for example ./downr1n.sh --downgrade 14.5 --keyServer.

- remember if you will use the next command or will activate localboot it is better that you first downgrade and when you success you can use --jailbreak to jailbreak the device and it will ask you to activate localboot path. why do this because the localboot need to be executed after --jailbreak

# Need Help?
- Join my discord server: [Dualra1nServer](https://discord.gg/Gjs2P7FBuk)

# How to Jailbreak?
- Jailbreak with dualra1n-loader: ./downr1n --jailbreak (YourVer = 14.3). Note: this does not actually jailbreak the device. When I say "jailbreak," I'm referring to the process of installing Sileo and bootstrapping the device. Dualra1n-loader only installs Sileo and bootstraps with the kpf kernel patch. (you will be able to use tweaks and most of things as normal).

- Taurine: ./downr1n --jailbreak (ex: 14.3 or YouVers) --taurine.

# Credits

- thanks to [uckermark](https://github.com/Uckermark/) for the amazing dualra1n-loader

- thanks to [sasa](https://github.com/sasa8810) for the code of download futurerestore ;| 

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
