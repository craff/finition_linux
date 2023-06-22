#!/bin/bash

# run finition.sh after copy in /tmp to allow removing the usb key

cp -r "/media/tech/8 GO" /tmp/finition
sleep 1

cd /tmp/finition
umount "/media/tech/8 GO" 

sudo bash -e ./finition.sh
