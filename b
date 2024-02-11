nasm -Isrc src/bootloader.asm -o bootloader.bin
nasm -Isrc src/ExtendedProgram.asm -o ExtendedProgram.bin
cat bootloader.bin ExtendedProgram.bin > bootloader.flp 

#alias ob='i386-elf-objdump -D -b binary -m i386:x86-64'
