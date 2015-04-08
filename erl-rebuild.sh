#!/bin/bash
#
# Maintainer: Greg Fitzgerald <greg@gregf.org>
# Maintainer: Daniil Baturin <daniil at baturin dot org>
#
# Copyright (C) 2013 SO3Group
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

set -o nounset
set -o errexit

# It's time to reinstall EdgeOS!
# EdgeOS won't reinstall itself!

# Find the latest here https://www.ubnt.com/download/?group=edgerouter-lite
RELEASE_TARBALL="http://dl.ubnt.com/firmwares/edgemax/v1.6.0/ER-e100.v1.6.0.4716006.tar"
DEV=/dev/sdd
BOOT=/dev/sdd1
ROOT=/dev/sdd2
BOOT_MNT_DIR=/mnt/boot
ROOT_MNT_DIR=/mnt/root
TMP_DIR=/tmp/tmp.$RANDOM
W_DIR=w

mkdir -p $BOOT_MNT_DIR 2>/dev/null
mkdir -p $ROOT_MNT_DIR 2>/dev/null
mkdir -p $TMP_DIR 2>/dev/null

# Release tarball file names
KERNEL_ORIG=vmlinux.tmp
KERNEL_ORIG_MD5=vmlinux.tmp.md5
SQUASHFS_ORIG=squashfs.tmp
SQUASHFS_MD5_ORIG=squashfs.tmp.md5
VERSION_ORIG=version.tmp

# Target file names
KERNEL=vmlinux.64
KERNEL_MD5=vmlinux.64.md5
SQUASHFS=squashfs.img
SQUASHFS_MD5=squashfs.img.md5
VERSION=version

if [ -x /sbin/parted ]; then
  PARTED=/sbin/parted
elif [ -x /usr/sbin/parted]; then
  PARTED=/usr/sbin/parted
else
  echo "Couldn't find parted"
  exit 1
fi

if [ -x /usr/bin/wget ]; then
  FETCH="wget -O "
elif [ -x /usr/bin/curl ]; then
  FETCH="curl -o "
else
  echo "Could not find wget or curl"
  exit 1
fi


function askyesno {
  read -p "yes/no " b
  if [ "${b:0:1}" == "y" ] || [ "${b:0:1}" == "Y" ]; then
    return 0
  fi
  return 1
}

# Scary disclaimer
echo "WARNING: This script will reinstall EdgeOS from scratch"
echo "If you have any usable data on your router storage,"
echo "it will be irrecoverably destroyed!"
echo "Do you want to continue?"
askyesno

if [ $? == 1 ]; then
  exit 0
fi

# Umount USB stick filesystems that could be mounted at boot time
if mount | grep $BOOT > /dev/null; then
  echo "Unmounting boot partition"
  umount $BOOT
fi

if mount | grep $ROOT > /dev/null; then
  echo "Unmounting root partition"
  umount $ROOT
fi

## Repartition

# Remove everything
echo "Re-creating partition table"
$PARTED --script $DEV mktable msdos

# Boot
echo "Creating boot partition"
$PARTED --script $DEV mkpart primary fat32 1 150MB
echo "Formatting boot partition"
mkfs.vfat $BOOT

# Root
echo "Creating root partition"
$PARTED --script $DEV mkpart primary ext3 150MB 1900MB
echo "Formatting root partition"
mkfs.ext3 -q $ROOT

## Mount partitions
echo "Mounting boot parition"
mount -t vfat $BOOT $BOOT_MNT_DIR

echo "Mounting root partition"
mount -t ext3 $ROOT $ROOT_MNT_DIR

## Download image
mkdir $ROOT_MNT_DIR/tmp
$FETCH $TMP_DIR/edgeos.tar $RELASE_TARBALL
if [ $? == 0 ]; then
  break
else
  echo "Could not download EdgeOS image, try again!"
fi

## Reinstall

# Unpack image
echo "Unpacking EdgeOS release image"
tar xf $TMP_DIR/edgeos.tar -C $TMP_DIR

# The kernel
echo "Verifying EdgeOS kernel"
if [ `md5sum $TMP_DIR/$KERNEL_ORIG | awk -F ' ' '{print $1}'` != `cat $TMP_DIR/$KERNEL_ORIG_MD5` ]; then
  echo "Kernel from your image is corrupted! Check your image and start over."
  exit 1
fi
echo "Copying EdgeOS kernel to boot partition"
cp $TMP_DIR/$KERNEL_ORIG $BOOT_MNT_DIR/$KERNEL
cp $TMP_DIR/$KERNEL_ORIG_MD5 $BOOT_MNT_DIR/$KERNEL_MD5

# The image
echo "Verifying EdgeOS system image"
if [ `md5sum $TMP_DIR/$SQUASHFS_ORIG | awk -F ' ' '{print $1}'` != `cat $TMP_DIR/$SQUASHFS_MD5_ORIG` ]; then
echo "System image from your image is corrupted! Check your image and start over."
  exit 1
fi

echo "Copying EdgeOS system image to root partition"
mv $TMP_DIR/$SQUASHFS_ORIG $ROOT_MNT_DIR/$SQUASHFS
mv $TMP_DIR/$SQUASHFS_MD5_ORIG $ROOT_MNT_DIR/$SQUASHFS_MD5

echo "Copying version file to the root partition"
mv $TMP_DIR/$VERSION_ORIG $ROOT_MNT_DIR/$VERSION

# Writable data dir
echo "Creating EdgeOS writable data directory"
mkdir $ROOT_MNT_DIR/$W_DIR

## Cleanup
echo "Cleaning up"
rm -rf $TMP_DIR

echo "Installation finished"
echo "Insert USB drive back into ERL and reset"
