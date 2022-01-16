org 0x0
bits 16

%define ENDL 0x0D, 0x0A

start:
    ; print hello world mwssage
    mov si, msg_hello
    call puts

.halt:
    cli
    hlt

puts:
	; save registers we will modify
	push si
	push ax
    push bx

.loop:
	lodsb ; loads next character in al
	or al, al ; verify if next character is null
	jz .done
	mov ah, 0xE
	mov bh, 0
	int 0x10
	jmp .loop
.done:
    pop bx
	pop ax
	pop si
	ret

msg_hello: db "Hello World from KERNEL!!!", ENDL, 0