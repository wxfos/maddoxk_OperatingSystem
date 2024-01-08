nasm -Isrc src\bootloader.asm -o bootloader.bin
nasm -Isrc src\ExtendedProgram.asm -o ExtendedProgram.bin
copy/b bootloader.bin+ExtendedProgram.bin bootloader.flp 

