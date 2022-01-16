bits 16

section _ENTRY class=CODE

extern _cstart_
global entry

entry:
	; setup stack
	cli
	mov ax, ds
	mov ss, ax
	mov sp, 0
	mov bp, sp
	sti

	; setup graphic mode
	mov ah, 0x00
	mov al, 0x12
	int 0x10

	; expect boot drive in dl, send it as argument to cstart function
	xor dh, dh
	push dx
	call _cstart_

	cli
	hlt