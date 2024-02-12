
all:
    nasm -Isrc src/bootloader.asm -o bootloader.bin
    nasm -Isrc src/ExtendedProgram.asm -o ExtendedProgram.bin
    cat bootloader.bin ExtendedProgram.bin > bootloader.flp 

run:
    bochs -q -f bochs.rc