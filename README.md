# HP Microserver Gen 7 (N36L/N40L/N54L) BIOS modder

Want to upgrade the BIOS on your Gen7 Microserver but don't have a Windows machine standing around? This tool builds a FreeDOS-based USB image that flashes the modded 
["Russian BIOS"](https://www.nathanielperez.us/blog/hp-proliant-n40l-bios-modification-guide)
onto an HP ProLiant MicroServer Gen7 (N36L/N40L/N54L) without requiring Windows. The modded BIOS enables, among other things, full speed on the 5th SATA port and enables hot-swap on all ports.

## Requirements

`curl`, `mtools`, and `bsdtar` or 7-Zip (`7zz`/`7z`). Tested on macOS, but should also run on Linux and FreeBSD.

## Usage

```sh
./build.sh
dd if=n40l-bios.img of=/dev/<usb-disk> bs=4m
```

Boot the server from the stick. Flashing starts without prompts. Power cycle
after `BIOS flash finished`. Remember to "Load optimal defaults" in BIOS setup after flashing.

## What it does

- Downloads `FD14-LiteUSB.zip` and `N40L-Mod-Files.zip` if missing, and checks
  them against [FreeDOS SHA-256 hashes](https://freedos.org/download/verify.txt).
- Extracts HP's `kbd.exe` and `flash.bat` from SoftPaq `SP64420.exe`.
- Uses mtools to modify a copy of `FD14LITE.img`:
  replaces `FDCONFIG.SYS` and `FDAUTO.BAT` with minimal versions that skip the
  installer and run `flash.bat` (similar to a HP-created stick), and adds the modded ROM as `N40LMOD.ROM`.
