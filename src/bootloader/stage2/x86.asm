bits 16

section _TEXT class=CODE

global _x86_div64_32
_x86_div64_32:
    ; make new call frame
    push bp
    mov bp, sp

    ; save registers we'll modify
    push bx

    ; divide upper 32 bits
    mov eax, [bp + 8] ; eax <- upper 32 bits of dividend
    mov ecx, [bp + 12] ; ecx <- divisor
    xor edx, edx
    div ecx ; eax <- quot, edx <- remainder

    ; store upper 32 bits of quotient
    mov bx, [bp + 16]
    mov [bx + 4], eax

    ; divide lower 32 bits
    mov eax, [bp + 4] ; eax <- lower 32 bits of divident, edx <- old remainder
    div ecx

    ; store results
    mov [bx], eax
    mov bx, [bp + 18]
    mov [bx], edx

    ; restore registers we've modified
    pop bx

    ; restore old call frame
    mov sp, bp
    pop bp
    ret

global _x86_Video_WriteCharTeletype
_x86_Video_WriteCharTeletype:
    ; make new call frame
    push bp
    mov bp, sp

    push bx

    mov ah, 0x0E
    mov al, [bp + 4]
    mov bh, [bp + 6]
    mov bl, 0xF

    int 0x10

    ; restore bx
    pop bx

    ; restore old call frame
    mov sp, bp
    pop bp
    ret

global _x86_Disk_Reset
_x86_Disk_Reset:
    ; make new call frame
    push bp
    mov bp, sp

    mov ah, 0
    mov dl, [bp + 4] ; dl - drive
    stc
    int 0x13

    mov ax, 1
    sbb ax, 0 ; 1 on success, 0 on fail

    ; restore old call frame
    mov sp, bp
    pop bp
    ret

global _x86_Disk_Read
_x86_Disk_Read:
    ; make new call frame
    push bp
    mov bp, sp

    ; save modified regs
    push bx
    push es

    ; setup args
    mov dl, [bp + 4] ; dl - drive

    mov ch, [bp + 6] ; ch - cylinder (lower 8 bits)
    mov cl, [bp + 7] ; cl - cylinder to bits 6-7
    shl cl, 6

    mov dh, [bp + 10]

    mov al, [bp + 8]
    and al, 0x3F
    or cl, al ; cl - sector to bits 0-5

    mov al, [bp + 12] ; al - count

    mov bx, [bp + 16] ; es:bx - far pointer to data out
    mov es, bx
    mov bx, [bp + 14]

    ; call int 0x13
    mov ah, 0x02
    stc
    int 0x13

    ; set return value
    mov ax, 1
    sbb ax, 0 ; 1 on success, 0 on fail

    ; restore regs
    pop es
    pop bx

    ; restore old call frame
    mov sp, bp
    pop bp
    ret

global _x86_Disk_GetDriveParams
_x86_Disk_GetDriveParams:
    ; make new call frame
    push bp
    mov bp, sp

    ; save regs
    push es
    push bx
    push si
    push di

    ; call int 0x13
    mov dl, [bp + 4] ; dl - disk drive
    mov ah, 0x08
    mov di, 0
    mov es, di
    stc
    int 0x13

    ; return
    mov ax, 1
    sbb ax, 0

    ; out params
    mov si, [bp + 6] ; drive type from bl
    mov [si], bl

    mov bl, ch ; lower bits in ch
    mov bh, cl ; higher bits in cl
    shr bh, 6
    mov si, [bp + 8] ; cylindersOut
    mov [si], bx

    xor ch, ch
    and cl, 0x3F
    mov si, [bp + 10]
    mov [si], cx

    mov cl, dh ; heads - dh
    mov si, [bp + 12]
    mov [si], cx

    ; restore regs
    pop di
    pop si
    pop bx
    pop es

    ; restore old call frame
    mov sp, bp
    pop bp
    ret