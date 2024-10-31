#!/bin/sh
grub-mkimage -o core.img -O i386-pc -C xz --prefix=/boot/grub biosdisk iso9660 normal
cat /usr/lib/grub/i386-pc/cdboot.img core.img > iso/boot/grub/grub_eltorito

grub-mkstandalone -O i386-efi \
    --compress="xz" \
    --locales="" \
    --themes="" \
    --fonts="" \
    --output="iso/EFI/BOOT/BOOTIA32.EFI" \
    "boot/grub/grub.cfg=grub-embed.cfg"

grub-mkstandalone -O x86_64-efi \
    --compress="xz" \
    --locales="" \
    --themes="" \
    --fonts="" \
    --output="iso/EFI/BOOT/BOOTx64.EFI" \
    "boot/grub/grub.cfg=grub-embed.cfg"

mkfs.fat -C -n EFIBOOT efiboot.img 8192
mmd -i efiboot.img ::/EFI ::/EFI/BOOT
mcopy -vi efiboot.img \
        "iso/EFI/BOOT/BOOTIA32.EFI" \
        "iso/EFI/BOOT/BOOTx64.EFI" \
        ::/EFI/BOOT/

xorriso \
    -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    --mbr-force-bootable -partition_offset 16 \
    -joliet -joliet-long -rational-rock \
    --grub2-boot-info \
    --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -eltorito-boot \
        boot/grub/grub_eltorito \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog boot/grub/boot.cat \
    -eltorito-alt-boot \
        -e --interval:appended_partition_2:all:: \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
    -append_partition 2 C12A7328-F81F-11D2-BA4B-00A0C93EC93B efiboot.img \
    -output grub.iso \
    iso
