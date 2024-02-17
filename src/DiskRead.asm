
; Set program space for it to run in memory
PROGRAM_SPACE equ 0x07e00

; ReadDisk Function

ReadDisk:
	mov ah, 0x02
	mov bx, PROGRAM_SPACE
	; Reminder: load more sectors as program gets bigger.
	mov al, 16	; 64*512=32k
	; Tell BIOs what drive we want to read from (cyl 0 and header 0)
	mov dl, [BOOT_DISK]
	mov ch, 0x00
	mov dh, 0x00
	mov cl, 0x02

	; int 0x13 is an interupt
	int 0x13
	jc DiskReadFailed
	ret
DiskReadFailed:
	mov bx, DiskReadErrorString
	call PrintString
	jmp $

; Declare Boot Disk Var
BOOT_DISK:
	db 0
; ReadFail Fallback
DiskReadErrorString:
	db 'Disk read failed!',0

