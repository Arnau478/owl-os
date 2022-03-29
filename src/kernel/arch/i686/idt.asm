[bits 32]

global i686_IDT_Load
i686_IDT_Load:
    ; make new call frame
    push ebp
    mov ebp, esp

    mov eax, [ebp + 8]
    lidt [eax]

    ; restore old call frame
    mov esp, ebp
    pop ebp
    ret
