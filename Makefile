
all:
    nasm -Isrc src/bootloader.asm -o build/bootloader.bin
    nasm -Isrc src/ExtendedProgram.asm -o build/ExtendedProgram.bin
    cat build/bootloader.bin build/ExtendedProgram.bin > build/bootloader.flp 

run:
    bochs -q -f bochs.rc