
PageTableEntry equ 0x1000

SetUpIdentityPaging:
	mov edi, PageTableEntry
	mov cr3, edi
	mov dword [edi], 0x2003
	add edi, 0x1000
	mov dword [edi], 0x3003
	add edi, 0x1000
	mov dword [edi], 0x4003
	add edi, 0x1000

	mov ebx, 0x00000003
	mov ecx, 512 ; Loops 512 times which will add 512 entries

.SetEntry:
	mov dword [edi], ebx
	add ebx, 0x1000
	add edi, 8
	loop .SetEntry

	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax

	mov ecx, 0xC0000080
	rdmsr
	or eax, 1 << 8
	wrmsr

	mov eax, cr0
	or eax, 1 << 31
	mov cr0, eax

	ret

vesamap:
	; page directory
    mov dword [0x90000], 0x91007
    mov dword [0x90800], 0x91007
	; page directory class 2
    mov dword [0x91000], 0x92007
	; page directory class 3, 2M
    mov dword [0x92000], 0x000083
    mov dword [0x92008], 0x200083
    mov dword [0x92010], 0x400083
    mov dword [0x92018], 0x600083
    mov dword [0x92020], 0x800083
    mov dword [0x92028], 0xe0000083
    mov dword [0x92030], 0xe0200083
    mov dword [0x92038], 0xe0400083
    mov dword [0x92040], 0xe0600083

    mov dword [0x92048], 0xe0800083
    mov dword [0x92050], 0xe0a00083
    mov dword [0x92058], 0xe0c00083
    mov dword [0x92060], 0xe0e00083
    mov dword [0x92068], 0xe1000083

	; load 64 bit gdt
;    db 0x66
;    lgdt [GdtPtr64]
;    mov ax, 0x10
;    mov ds, ax
;    mov es, ax
;    mov ss, ax
;    mov fs, ax
;    mov gs, ax
;    mov esp, 0x7c00

	; enable PAE
;    mov eax, cr4
;    bts eax, 5
;    mov cr4, eax

	; load page director
    mov eax, 0x90000
    mov cr3, eax
    ret