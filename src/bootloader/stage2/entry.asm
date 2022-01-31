bits 16

section .entry

extern __bss_start
extern __end

extern start
global entry

entry:
	cli
	
	; save boot drive
	mov [g_BootDrive], dl

	; setup stack
	mov ax, ds
	mov ss, ax
	mov sp, 0xFFF0
	mov bp, sp

	; switch to protected mode
	call EnableA20
	call LoadGDT

	mov eax, cr0
	or al, 1
	mov cr0, eax

	; far jump into PM
	jmp dword 0x08:.pmode

.pmode:
	[bits 32]

	; setup segment registers
	mov ax, 0x10
	mov ds, ax
	mov ss, ax

	; clear bss
	mov edi, __bss_start
	mov ecx, __end
	sub ecx, edi
	mov al, 0
	cld
	rep stosb

	; expect boot drive in dl, send it to cstart function
	xor edx, edx
	mov dl, [g_BootDrive]
	push edx
	call start

	cli
	hlt

EnableA20:
	[bits 16]
	; disable keyboard
	call A20WaitInput
	mov al, KbdControllerDisableKeyboard
	out KbdControllerCommandPort, al

	; read control output port
	call A20WaitInput
	mov al, KbdControllerReadCtrlOutputPort
	out KbdControllerCommandPort, al

	call A20WaitOutput
	in al, KbdControllerDataPort
	push eax

	; write control output port
	call A20WaitInput
	mov al, KbdControllerWriteCtrlOutputPort
	out KbdControllerCommandPort, al

	call A20WaitInput
	pop eax
	or al, 2
	out KbdControllerDataPort, al

	; enable keyboard
	call A20WaitInput
	mov al, KbdControllerEnableKeyboard
	out KbdControllerCommandPort, al

	call A20WaitInput
	ret

A20WaitInput:
	[bits 16]
	; wait until status bit 2 (input buffer) is 0
	in al, KbdControllerCommandPort
	test al, 2
	jnz A20WaitInput
	ret

A20WaitOutput:
	[bits 16]
	; wait until status bit 1 (output buffer) is 1
	in al, KbdControllerCommandPort
	test al, 1
	jz A20WaitOutput
	ret

LoadGDT:
	[bits 16]
	lgdt [g_GDTDesc]
	ret



KbdControllerDataPort equ 0x60
KbdControllerCommandPort equ 0x64
KbdControllerDisableKeyboard equ 0xAD
KbdControllerEnableKeyboard equ 0xAE
KbdControllerReadCtrlOutputPort equ 0xD0
KbdControllerWriteCtrlOutputPort equ 0xD1

ScreenBuffer equ 0xB8000

g_GDT:
	dq 0 ; NULL descriptor

	; 32 bit code segment
	dw 0x0FFFF ; limit (bits 0-15)
	dw 0 ; base (bits 0-15)
	db 0 ; base (bits 16-23)
	db 0b10011010 ; access
	db 0b11001111 ; granularity + limit (bits 16-19)
	db 0 ; base high

	; 32 bit data segment
	dw 0x0FFFF ; limit (bits 0-15)
	dw 0 ; base (bits 0-15)
	db 0 ; base (bits 16-23)
	db 0b10010010 ; access
	db 0b11001111 ; granularity + limit (bits 16-19)
	db 0 ; base high

	; 16 bit code segment
	dw 0x0FFFF ; limit (bits 0-15)
	dw 0 ; base (bits 0-15)
	db 0 ; base (bits 16-23)
	db 0b10011010 ; access
	db 0b00001111 ; granularity + limit (bits 16-19)
	db 0 ; base high

	; 16 bit data segment
	dw 0x0FFFF ; limit (bits 0-15)
	dw 0 ; base (bits 0-15)
	db 0 ; base (bits 16-23)
	db 0b10010010 ; access
	db 0b00001111 ; granularity + limit (bits 16-19)
	db 0 ; base high

g_GDTDesc:
	dw g_GDTDesc - g_GDT - 1 ; limit (size of GDT)
	dd g_GDT ; address

g_BootDrive: db 0