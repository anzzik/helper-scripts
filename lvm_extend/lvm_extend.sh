#!/bin/bash

set -e

ext_pv=$1
devname=$(echo $ext_pv | sed 's/\/dev\///g')

if [ -z "$ext_pv" ]; then
	echo "Usage: $0 device"
	exit 1
fi

if [ ! -b "$ext_pv" ]; then
	echo "Block device $ext_pv not found in /dev"
	exit 1
fi

vg=$(vgscan | grep "Found volume" | awk '{print $4}' | sed 's/\"//g')
if [ -z "$vg" ]; then
	echo "Volume group not found"
	exit 1
fi

lv=$(lvscan | grep $vg | awk '{print $2}' | sed "s/'//g")
if [ -z "$lv" ]; then
	echo "Logical volume not found"
	exit 1
fi


extra_space=$(lsblk $ext_pv | grep $devname | awk '{print $4}')

read -p "About to extend the logical volume $lv in volume group $vg with $extra_space. Is this okay? (y/n) " confirm
if [ "$confirm" != "y" ]; then
	echo "Aborting.."
	exit 0
fi

echo "Extending volume group $vg"
vgextend $vg $ext_pv

echo "Extending logical volume $lv"
lvextend -l +100%FREE $lv

echo "Resizing the file system"
resize2fs $lv

exit 0

