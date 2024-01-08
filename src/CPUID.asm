; How we detect if the CPUID is supported
; We XOR a bit in the CPU's flag register and if it comes back the same it is supported.
; CPUID can give us lots of information about the processor

DetectCPUID:
	pushfd
	pop eax

	mov ecx, eax
	xor eax, 1 << 21

	push eax
	popfd

	pushfd
	pop eax

	push ecx
	popfd

	xor eax,ecx
	jz NoCPUID
	ret

NoCPUID:
	hlt 		; No CPUID Supported

DetectLongMode:
	mov eax, 0x80000001
	cpuid
	test edx, 1 << 29
	jz NoLongMode
	mov eax, 1	; return true
	ret 		; If this comes back as 0 longmode is not supported :(

NoLongMode:
	mov eax, 0
	ret			; return false
;	hlt 		; No longmdoe


; Important: We need to enable Paging for LongMode. Paging is where we have to copy all physical memory to match the virtual memory.