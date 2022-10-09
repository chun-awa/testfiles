#!/bin/sh
qemu-system-x86_64 $(if [ -e /dev/kvm ];then echo "-enable-kvm";fi) -kernel vmlinuz-6.0 -initrd rootfs.bz2 -m 96 -append "vga=836 quiet" -smp 2
