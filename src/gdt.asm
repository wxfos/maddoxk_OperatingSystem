; [gdt] Global Desciptor Table
; GDT has a very weird layout...
; The Global Descriptor Table (GDT) is a table in memory that defines the processor's memory segments. 
; The GDT sets the behavior of the segment registers and helps to ensure that protected mode operates smoothly.
; The GDT comtains both Size and Offset.
; Size = Size of entry we are putting in,
; Offset = Memory Address of the GDT.
; In this GBT, we need a null descriptor. This is just a value in memory that is a 0. This is very important for certain functions.
; This GBT also contains a Data segment and a Code segment.
align 16

gdt_nulldesc:       ; 64bit
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
    dw gdt_end - gdt_nulldesc - 1 ; 	gdt_size:
    dq gdt_nulldesc		; dq for 64 bit

; Codedescriptor Address
codeseg equ gdt_codedesc - gdt_nulldesc		; 0x8
dataseg equ gdt_datadesc - gdt_nulldesc		; 0x10

;idt_descriptor:
;	times 2048 db 0
idt_desc:   ; idt32
    dw 256 * 8 - 1
    dq idt
idt:
    times 256 dq 0

idt64_desc: 								; Interrupt Descriptor Table Register
	dw 256*16-1								; limit of IDT (size minus one) (4096 bytes - 1)
    ; dq idt64
	dq 0x0000000000000000					; linear address of IDT
idt64:
    times 256 dq 0


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

;struct IDT_entry {
;    uint16 offset_lowerbits;
;    uint16 selector;
;    uint8 zero;
;    uint8 type_attr;
;    uint16 offset_higherbits;
;};
;void idt_set(int idt_no, void* handler){
;	uint32 handler_addr = (uint32)handler;
;	IDT[idt_no].offset_lowerbits = handler_addr & 0xffff;
;	IDT[idt_no].selector = KERNEL_CODE_SEGMENT_OFFSET;
;	IDT[idt_no].zero = 0;
;	IDT[idt_no].type_attr = INTERRUPT_GATE;
;	IDT[idt_no].offset_higherbits = (handler_addr & 0xffff0000) >> 16;
;}
setup_idt:	;32
;    lea edx, [ignore_int]
;    mov eax, 0x00080000
;    mov dx, ax
;    mov word [idt], dx
;    mov word [idt + 6], 0x8E00  ;INTERRUPT_GATE

    lea edi, [idt]
    mov ecx, 256
    lea eax, [ignore_int]
    mov edx, eax
    and eax, 0xffff
    mov ebx, 0x00080000
    or eax, ebx
    mov dh, 0x8e
    mov dl, 0
.rp_sidt:
    mov [edi], eax
    mov [edi + 4], edx
    add edi, 8
    loop .rp_sidt
;    jmp $
    lidt [idt_desc]
    ret


ignore_int:
	cli
	cld
	mov edi, 0xb8000 + 160*4
    push edi
	mov eax, 0x3f203f20
	mov ecx, 80
	rep stosd			; write eax to [edi]
    pop edi
    mov al, [count]
    inc al
    mov [count], al
    mov [edi], al

;    hlt
;    jmp short ignore_int
    sti
    iret
count:
    dq '0'

[bits 64]
ignore_int64:
	cli
	cld
	mov rdi, 0xb8000 + 160*4
    push rdi
	mov rax, 0x3f203f20
	mov rcx, 80
	rep stosd			; write eax to [edi]
    pop rdi
    mov al, [count]
    inc al
    mov [count], al
    mov [rdi], al
;    hlt
;    jmp short ignore_int
    sti
    iretq

exception_gate:
	cli
	cld
	mov rdi, 0xb8000 + 160*8
    push rdi
	mov rax, 0x6f206f20
	mov rcx, 80
	rep stosd			; write eax to [edi]
    pop rdi
    add qword [count],1
    mov al, [count]
    mov [rdi], al
;    hlt
;    jmp short ignore_int
    sti
    iretq

setup_idt64:
; Build a temporary IDT
	xor edi, edi 			; create the 64-bit IDT (at linear address 0x0000000000000000)
	mov rcx, 32
make_exception_gates: 			; make gates for exception handlers
	mov rax, exception_gate
	push rax			; save the exception gate to the stack for later use
	stosw				; store the low word (15:0) of the address
	mov ax, codeseg     ; SYS64_CODE_SEL
	stosw				; store the segment selector
	mov ax, 0x8E00
	stosw				; store exception gate marker
	pop rax				; get the exception gate back
	shr rax, 16
	stosw				; store the high word (31:16) of the address
	shr rax, 16
	stosd				; store the extra high dword (63:32) of the address.
	xor rax, rax
	stosd				; reserved
	dec rcx
	jnz make_exception_gates

	mov rcx, 256-32
make_interrupt_gates: 			; make gates for the other interrupts
	mov rax, ignore_int64 ; interrupt_gate
	push rax			; save the interrupt gate to the stack for later use
	stosw				; store the low word (15:0) of the address
	mov ax, codeseg     ; SYS64_CODE_SEL
	stosw				; store the segment selector
	mov ax, 0x8e00
	stosw				; store interrupt gate marker
	pop rax				; get the interrupt gate back
	shr rax, 16
	stosw				; store the high word (31:16) of the address
	shr rax, 16
	stosd				; store the extra high dword (63:32) of the address.
	xor eax, eax
	stosd				; reserved
	dec rcx
	jnz make_interrupt_gates

	; Set up the exception gates for all of the CPU exceptions
	; The following code will be seriously busted if the exception gates are moved above 16MB
	mov word [0x00*16], exception_gate_00
	mov word [0x01*16], exception_gate_01
	mov word [0x02*16], exception_gate_02
	mov word [0x03*16], exception_gate_03
	mov word [0x04*16], exception_gate_04
	mov word [0x05*16], exception_gate_05
	mov word [0x06*16], exception_gate_06
	mov word [0x07*16], exception_gate_07
	mov word [0x08*16], exception_gate_08
	mov word [0x09*16], exception_gate_09
	mov word [0x0A*16], exception_gate_10
	mov word [0x0B*16], exception_gate_11
	mov word [0x0C*16], exception_gate_12
	mov word [0x0D*16], exception_gate_13
	mov word [0x0E*16], exception_gate_14
	mov word [0x0F*16], exception_gate_15
	mov word [0x10*16], exception_gate_16
	mov word [0x11*16], exception_gate_17
	mov word [0x12*16], exception_gate_18
	mov word [0x13*16], exception_gate_19

	mov rdi, 0x21			; Set up Keyboard handler
	mov rax, keyboard
	call create_gate
	mov rdi, 0x22			; Set up Cascade handler
	mov rax, cascade
	call create_gate
	mov rdi, 0x28			; Set up RTC handler
	mov rax, rtc
	call create_gate

	lidt [idt64_desc]			; load IDT register

    ret

; -----------------------------------------------------------------------------
; Keyboard interrupt. IRQ 0x01, INT 0x21
; This IRQ runs whenever there is input on the keyboard
align 16
keyboard:
	push rdi
	push rax

	xor eax, eax

	in al, 0x60			; Get the scancode from the keyboard
	cld
	mov rdi, 0xb8000 + 160*6
    push rdi
	mov eax, 0x4f204f20
	mov ecx, 80
	rep stosd			; write eax to [edi]
    pop rdi
    mov [rdi], al

	test al, 0x80
	jnz keyboard_done

keyboard_done:
	mov al, 0x20			; Acknowledge the IRQ
	out 0x20, al

	pop rax
	pop rdi
	iretq
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Cascade interrupt. IRQ 0x02, INT 0x22
cascade:
	push rax

	mov al, 0x20			; Acknowledge the IRQ
	out 0x20, al

	pop rax
	iretq
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Real-time clock interrupt. IRQ 0x08, INT 0x28
align 16
rtc:
	push rdi
	push rax

	add qword [os_Counter_RTC], 1	; 64-bit counter started at boot up

	mov al, 0x0C			; Select RTC register C
	out 0x70, al			; Port 0x70 is the RTC index, and 0x71 is the RTC data
	in al, 0x71			; Read the value in register C

	mov al, 0x20			; Acknowledge the IRQ
	out 0xA0, al
	out 0x20, al

	cld
	mov rdi, 0xb8000 + 160*6
    push rdi
	mov eax, 0x4f204f20
	mov ecx, 80
	rep stosd			; write eax to [edi]
    pop rdi
    mov rax, qword [os_Counter_RTC]
    mov [rdi], al

	pop rax
	pop rdi
	iretq
; -----------------------------------------------------------------------------
os_Counter_RTC:
    dq 0

; -----------------------------------------------------------------------------
; Spurious interrupt. INT 0xFF
align 16
spurious:				; handler for spurious interrupts
	iretq
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; CPU Exception Gates
exception_gate_00:
	mov al, 0x00
	jmp exception_gate_main

exception_gate_01:
	mov al, 0x01
	jmp exception_gate_main

exception_gate_02:
	mov al, 0x02
	jmp exception_gate_main

exception_gate_03:
	mov al, 0x03
	jmp exception_gate_main

exception_gate_04:
	mov al, 0x04
	jmp exception_gate_main

exception_gate_05:
	mov al, 0x05
	jmp exception_gate_main

exception_gate_06:
	mov al, 0x06
	jmp exception_gate_main

exception_gate_07:
	mov al, 0x07
	jmp exception_gate_main

exception_gate_08:
	mov al, 0x08
	jmp exception_gate_main

exception_gate_09:	;0x9346
	mov al, 0x09
	jmp exception_gate_main

exception_gate_10:
	mov al, 0x0A
	jmp exception_gate_main

exception_gate_11:
	mov al, 0x0B
	jmp exception_gate_main

exception_gate_12:
	mov al, 0x0C
	jmp exception_gate_main

exception_gate_13:
	mov al, 0x0D
	jmp exception_gate_main

exception_gate_14:
	mov al, 0x0E
	jmp exception_gate_main

exception_gate_15:
	mov al, 0x0F
	jmp exception_gate_main

exception_gate_16:
	mov al, 0x10
	jmp exception_gate_main

exception_gate_17:
	mov al, 0x11
	jmp exception_gate_main

exception_gate_18:
	mov al, 0x12
	jmp exception_gate_main

exception_gate_19:
	mov al, 0x13
	jmp exception_gate_main

exception_gate_main: ;0x9372
	pushf
	cld
	mov rdi, 0xb8000 + 160*8
    push rdi
    push rax
	mov eax, 0x5f205f20
	mov ecx, 80
	rep stosd			; write eax to [edi]
    pop rax
    pop rdi
    ; mov rax, qword [os_Counter_RTC]
    add al, 0x30
    mov [rdi], al
    add qword [e_count],1
	mov al, byte [e_count]
    add al, 0x30
	add rdi, 4
    mov [rdi], al
	  
exception_gate_main_hang:	;0x93a4
	nop
	sti
	popf
    iretq
	; jmp exception_gate_main_hang	; Hang. User must reset machine at this point
e_count: dq 0
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; create_gate
; rax = address of handler
; rdi = gate # to configure
create_gate:	;0x93b0
	push rdi
	push rax

	shl rdi, 4			; quickly multiply rdi by 16
	stosw				; store the low word (15:0)
	shr rax, 16
	add rdi, 4			; skip the gate marker
	stosw				; store the high word (31:16)
	shr rax, 16
	stosd				; store the high dword (63:32)

	pop rax
	pop rdi
	ret

 init_pic:
	; Enable specific interrupts
	in al, 0x21
	mov al, 11111001b		; Enable Cascade, Keyboard
	out 0x21, al
	in al, 0xA1
	mov al, 11111110b		; Enable RTC
	out 0xA1, al

	; Set the periodic flag in the RTC
	mov al, 0x0B			; Status Register B
	out 0x70, al			; Select the address
	in al, 0x71			; Read the current settings
	push rax
	mov al, 0x0B			; Status Register B
	out 0x70, al			; Select the address
	pop rax
	bts ax, 6			; Set Periodic(6)
	out 0x71, al			; Write the new settings

	sti				; Enable interrupts

	; Acknowledge the RTC
	mov al, 0x0C			; Status Register C
	out 0x70, al			; Select the address
	in al, 0x71			; Read the current settings

	ret   
; -----------------------------------------------------------------------------
[bits 16]
