# ERL Rebuild

## Description

This script will allow you to rebuild your Edge Router Lite if its bricked. The script requires you to open the case and remove the usb ddrive mounted on the board and plugged it into your computer. Once the script is run, you can put the drive back in and reboot to a working Edge OS.

## Connecting via console cable

If you own a cisco console cable you can connect to your router and see the boot process.

I use the following command once connected to see the output and enter commands.

    sudo picocom -b 115200 -d 8 -f n -p 1 -y n /dev/ttyUSB0


You'll want to run this before you plug your router's power cable in.

## Fixing U-Boot bootloader

If your system still won't boot after a rebuild and you are stuck at the uboot prompt you may need to change a few settings.

Try typing the following into the prompt from minicom.

	setenv bootcmd 'sleep 5; usb reset;fatload usb 0 $loadaddr vmlinux.64;bootoctlinux $loadaddr coremask=0x3 root=/dev/sda2 rootdelay=15 rw rootsqimg=squashfs.img rootsqwdir=w mtdparts=phys_mapped_flash:512k(boot0),512k(boot1),64k@3072k(eeprom)'
    saveenv
    reset

After the reset command your ERL should reboot and hopefully load the kernel, and boot.
