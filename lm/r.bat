nasm -fbin boot.asm -o boot
:qemu-system-x86_64 -hda boot
call qe -hda boot