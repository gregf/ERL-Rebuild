# ERL Rebuild

## Description

This script will allow you to rebuild your Edge Router Lite if its bricked. The script requires you to open the case and remove the usb ddrive mounted on the board and plugged it into your computer. Once the script is run, you can put the drive back in and reboot to a working Edge OS.

## Fixing U-Boot bootloader

If your system still won't boot after a rebuild and you are stuck at the uboot prompt you may need to change a few settings.

Try typing the following into the prompt from minicom.

	setenv bootcmd 'sleep 5; usb reset;fatload usb 0 $loadaddr vmlinux.64;bootoctlinux $loadaddr coremask=0x3 root=/dev/sda2 rootdelay=15 rw rootsqimg=squashfs.img rootsqwdir=w mtdparts=phys_mapped_flash:512k(boot0),512k(boot1),64k@3072k(eeprom)'
    saveenv
    reset

After the reset command your ERL should reboot and hopefully load the kernel, and boot.
