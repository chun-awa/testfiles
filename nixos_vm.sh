#!/bin/sh
[ -f VARS.fd ] || cp /usr/share/ovmf/x64/OVMF_VARS.fd VARS.fd
qemu-system-x86_64 \
    -name "NixOS" \
    -machine q35 \
    -enable-kvm \
    -cpu host \
    -smp 8 \
    -m 4096 \
    -cdrom latest-nixos-gnome-x86_64-linux.iso \
    -drive file=disk.qcow2,if=none,id=nvme0,cache=none,format=qcow2 \
    -device nvme,drive=nvme0 \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/ovmf/x64/OVMF.fd \
    -drive if=pflash,format=raw,file=VARS.fd \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device e1000,netdev=net0 \
    -display none \
    -vnc :1 \
    -vga vmware \
    -serial stdio \
    -monitor telnet:127.0.0.1:5555,server,nowait \
    -audiodev pa,id=snd0 \
    -device intel-hda -device hda-output,audiodev=snd0 \
    -device usb-tablet
