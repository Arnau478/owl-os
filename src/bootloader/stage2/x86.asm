%macro x86_EnterRealMode 0

    [bits 32]
    jmp word 0x18:.pmode16

.pmode16:
    [bits 16]
    mov eax, cr0
    and al, ~1
    mov cr0, eax

    jmp word 0x00:.rmode

.rmode:
    mov ax, 0
    mov ds, ax
    mov ss, ax

    sti

%endmacro

%macro x86_EnterProtectedMode 0

    cli

    mov eax, cr0
    or al, 1
    mov cr0, eax

    jmp dword 0x08:.pmode

.pmode:

    [bits 32]

    mov ax, 0x10
    mov ds, ax
    mov ss, ax

%endmacro

%macro LinearToSegOffset 4

    mov %3, %1
    shr %3, 4
    mov %2, %4
    mov %3, %1
    and %3, 0xF

%endmacro

global x86_outb
x86_outb:
    [bits 32]
    mov dx, [esp + 4]
    mov al, [esp + 8]
    out dx, al
    ret

global x86_inb
x86_inb:
    [bits 32]
    mov dx, [esp + 4]
    xor eax, eax
    in al, dx
    ret

global x86_Disk_GetDriveParams
x86_Disk_GetDriveParams:
    [bits 32]

    ; make new call frame
    push ebp
    mov ebp, esp

    x86_EnterRealMode

    [bits 16]

    ; save regs
    push es
    push bx
    push esi
    push di

    ; call int 0x13
    mov dl, [bp + 8] ; dl - disk drive
    mov ah, 0x08
    mov di, 0
    mov es, di
    stc
    int 0x13

    ; out params
    mov eax, 1
    sbb eax, 0

    ; drive type from bl
    LinearToSegOffset [bp + 12], es, esi, si
    mov [es:si], bl

    ; cylinders
    mov bl, ch
    mov bh, cl
    shr bh, 6
    inc bx

    LinearToSegOffset [bp + 16], es, esi, si
    mov [es:si], bx

    ; sectors
    xor ch, ch
    and cl, 0x3F

    LinearToSegOffset [bp + 20], es, esi, si
    mov [es:si], cx

    ; heads
    mov cl, dh
    inc cx

    LinearToSegOffset [bp + 24], es, esi, si
    mov [es:si], cx

    ; restore regs
    pop di
    pop esi
    pop bx
    pop es

    ; return
    push eax

    x86_EnterProtectedMode

    [bits 32]
    
    pop eax

    ; restore old call frame
    mov esp, ebp
    pop ebp
    ret

global x86_Disk_Reset
x86_Disk_Reset:
    [bits 32]

    ; make new call frame
    push ebp
    mov ebp, esp

    x86_EnterRealMode

    mov ah, 0
    mov dl, [bp + 8] ; dl - drive
    stc
    int 0x13

    mov eax, 1
    sbb eax, 0 ; 1 on success, 0 on fail

    push eax

    x86_EnterProtectedMode

    pop eax

    ; restore old call frame
    mov esp, ebp
    pop ebp
    ret

global x86_Disk_Read
x86_Disk_Read:
    ; make new call frame
    push ebp
    mov ebp, esp

    x86_EnterRealMode

    ; save modified regs
    push ebx
    push es

    ; setup args
    mov dl, [bp + 8] ; dl - drive

    mov ch, [bp + 12] ; ch - cylinder (lower 8 bits)
    mov cl, [bp + 13] ; cl - cylinder to bits 6-7
    shl cl, 6

    mov al, [bp + 16]
    and al, 0x3F
    or cl, al ; cl - sector to bits 0-5

    mov dh, [bp + 20] ; dh - head

    mov al, [bp + 24] ; al - count

    LinearToSegOffset [bp + 28], es, ebx, bx

    ; call int 0x13
    mov ah, 0x02
    stc
    int 0x13

    ; set return value
    mov eax, 1
    sbb eax, 0 ; 1 on success, 0 on fail

    ; restore regs
    pop es
    pop ebx

    push eax

    x86_EnterProtectedMode

    pop eax

    ; restore old call frame
    mov esp, ebp
    pop ebp
    ret