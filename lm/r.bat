nasm -fbin boot.asm -o boot.bin
qemu-system-x86_64 -hda boot.bin
