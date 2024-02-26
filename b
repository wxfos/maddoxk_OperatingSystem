nasm -Isrc src/bootloader.asm -o build/bootloader.bin
nasm -Isrc src/ExtendedProgram.asm -o build/ExtendedProgram.bin
cat build/bootloader.bin build/ExtendedProgram.bin > build/bootloader.flp 

#alias ob='i386-elf-objdump -D -b binary -m i386:x86-64'
bochs -q -f bochs.rc 