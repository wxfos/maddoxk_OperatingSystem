[org 0x7e00]
	
jmp EnterProtectedMode

%include "gdt.asm"
%include "print.asm"

cleanLine2Real:			; clean one line in real mode, we can use 32bit registers in real mode
	cld
	mov eax, 0xb800
	mov es, eax
	mov di, 0x0000
	mov eax, 0x2f202f20
	mov ecx, 80
;	rep stosw			; write ax * 80 
	rep stosd			; write eax * 80
	ret
	
EnterProtectedMode:
	call cleanLine2Real

	call EnableA20
	cli
	; Loads gdt and bits so we can get protected mode!!! >:D
	lgdt [gdt_descriptor]	;exception
	;lgdt [gdt_desc]		;wxf, ok

	mov eax, cr0
	or eax, 1
	mov cr0, eax

	; Flushes cpu pipeline
	jmp codeseg:StartProtectedMode

EnableA20:
	in al, 0x92
	or al, 2
	out 0x92, al
	ret

[bits 32]

%include "SimplePaging.asm"
%include "CPUID.asm"

; Hello World!
hello:
	db 'H', 0x1f, 'e', 0x1f, 'l', 0x1f, 'l', 0x1f, 'o', 0x1f, ' ', 0x1f, 'W', 0x1f, 'o', 0x1f, 'r', 0x1f, 'l', 0x1f, 'd', 0x1f, '!', 0x1f

cleanLine2Pro:			; clean one line in protected mode, we can use 32bit registers in real mode
	cld
	mov edi, 0xb8000 + 160*2
	mov eax, 0x1f201f20
	mov ecx, 80
	rep stosd			; write eax to [edi]
	ret
	
StartProtectedMode:
	; We need to point our new data to the GDT
	mov ax, dataseg
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	call cleanLine2Pro
	;jmp $
;	call setup_idt
;	sti					;idt is wrong, exception will occur
;	cli
.loop nop
;	hlt
;	jmp .loop
	
	;lidt [idt_descriptor]	;wxf
	;lgdt [gdt_descriptor]
	;lgdt [gdt_desc]

	; mov edp, 0x90000 ; Position of our stack if needed space
	; mov esp, ebp

	; Now that we are in ProtectedMode, we have to edit the video memory of text mode to type
	; 0xb8000 is the start of video memory
	; clear screen
	cld
	mov edi, 0xb8000
	mov eax, 0x1f201f20
	mov ecx, 80*25/2
	rep stosd			; write eax to es:[edi]
	
	cld
	mov edi, 0xb8000	; print hello
	mov esi, hello
	mov ecx, 24
	rep movsb

	call DetectCPUID
	call DetectLongMode
	call SetUpIdentityPaging	; must enable pageing before switch to 64bit, but it'll cause idt32 exception
	call EditGDT
	jmp codeseg:Start64Bit

; Hello 64bit!
hello64:
	db 'H', 0x1f, 'e', 0x1f, 'l', 0x1f, 'l', 0x1f, 'o', 0x1f, ' ', 0x1f, '6', 0x1f, '4', 0x1f, 'B', 0x1f, 'i', 0x1f, 't', 0x1f, '!', 0x1f

[bits 64]

Start64Bit:
	cld
	mov rdi, 0xb80a0	;print hello 64
	mov rsi, hello64
	mov rcx, 24
	rep movsb			; copy [rsi] to [rdi]

    mov ax, 2			; row
	mov bx, 13			; col
    call set_cursor
	call setup_idt64
    sti
	; hlt
    ; mov ax, 1
	; mov bx, 1
    ; call set_cursor
.loop:
	nop
	hlt
	jmp .loop


set_cursor:
	dec ax
	dec bx
	imul ax, 80
	add bx, ax			; bx = 80 * row + col
;	mov bx, 80*1+12		; bx = 80 * row + col

	mov dx, 0x3d4
	mov al, 0x0e
	out dx, al
	mov dx, 0x3d5
	mov al, bh
	out dx, ax
	mov dx, 0x3d4
	mov al, 0x0f
	out dx, al
	mov dx, 0x3d5
	mov al, bl
	out dx, al

    ret

get_cursor:
	mov dx,0x3d4
	mov al,0x0e
	out dx,al
	mov dx,0x3d5
	in al,dx
	mov ah,al

	mov dx,0x3d4
	mov al,0x0f
	out dx,al
	mov dx,0x3d5
	in al,dx
	mov bx,ax
	ret

; Fill memory with 2048 bytes
	align 16

;times 4096-($-$$) db 0