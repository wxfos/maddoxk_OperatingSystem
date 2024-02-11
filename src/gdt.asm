; [gdt] Global Desciptor Table
; GDT has a very weird layout...
; The Global Descriptor Table (GDT) is a table in memory that defines the processor's memory segments. 
; The GDT sets the behavior of the segment registers and helps to ensure that protected mode operates smoothly.
; The GDT comtains both Size and Offset.
; Size = Size of entry we are putting in,
; Offset = Memory Address of the GDT.
; In this GBT, we need a null descriptor. This is just a value in memory that is a 0. This is very important for certain functions.
; This GBT also contains a Data segment and a Code segment.

gdt_nulldesc:
	dd 0
	dd 0

gdt_codedesc:
	dw 0xFFFF		; THE LIMIT OF MEMORY WE ARE USING (0xFFFF is all of it)
	dw 0x0000		; THE BASE OF MEMORY WE ARE USING (0x0000 is the very bottom)
	db 0x00			; Base of limit
	db 0x9a			; 10011010b,  0xaf for 64bit.
					; This is the Access Byte! : 1, Valid Memory, Kernal Privledge (0-3), 
					; System segments, Executable bit (1=code 0=data),DC privledge, Read or Write bit (1=read 0=write),
					; Access bit (we should set this to 0 and the cpu will change to 1 when its accessed), b = declared at byte
	db 0xcf			; 11001111b Granularity(0=1 byte blocks, 1=4kb blocks), Size bit(0=16bit, 1=32bit),0,0, Limit (1111=biggest)
	db 0x00			; Base base (yes, the base's base)
	
gdt_datadesc:		; Everythings the same for the Data Descriptor
	dw 0xFFFF
	dw 0x0000
	db 0x00
	db 0x92			; 10010010b, but the Access Bytes 'Executable bit' is 0 because this is data not code
	db 0xcf			; 11001111b
	db 0x00

gdt_end:

gdt_descriptor:		; This is what we are actually passing to the cpu
	gdt_size:
		dw gdt_end - gdt_nulldesc - 1 
		dq gdt_nulldesc		; dq for 64 bit

; Codedescriptor Address
codeseg equ gdt_codedesc - gdt_nulldesc		; 0x8
dataseg equ gdt_datadesc - gdt_nulldesc		; 0x10

;idt_descriptor:
;	times 2048 db 0
idt_desc:
    dw 256 * 8 - 1
    dq idt
    
idt:
    times 256 dd 0

align 4
gdt_desc:
    dw 256 * 8 - 1
    dq gdt

; gdt =========================    
align 4
;idt:
;    times 256 dd 0

align 4
gdt:
    dw 0, 0, 0, 0  ; null descriptor

    dw 0x1FFF  ; code segment, 32M, start 0, readable, nonconforming
    dw 0x0000
    dw 0x9A00
    dw 0x00C0

    dw 0x1FFF  ; data segment, 32M, start 0, read/write, up-data
    dw 0x0000
    dw 0x9200
    dw 0x00C0

    times 252 dw 0  ; temporary - not use
        
[bits 32]

EditGDT: ; This function edits our GDT to 64-bits. Very nice.
	mov [gdt_codedesc + 6], byte 0xaf	;10101111b
	mov [gdt_datadesc + 6], byte 0xaf	;10101111b
	ret

setup_idt:	;32
    lea edx, [ignore_int]
    mov eax, 0x00080000
    mov dx, ax
    mov word [idt], dx
    mov word [idt + 6], 0x8E00

    lea edi, [idt]
    mov ecx, 256
rp_sidt:
    mov [edi], eax
    mov [edi + 4], edx
    add edi, 8
    loop rp_sidt
    lidt [idt_desc]
    ret
    
ignore_int:
	cli
	cld
	mov edi, 0xb8000 + 160*4
	mov eax, 0x3f203f20
	mov ecx, 80
	rep stosd			; write eax to [edi]

    hlt
    jmp short ignore_int
    iret
    
[bits 16]