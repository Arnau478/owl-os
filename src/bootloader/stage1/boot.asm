org 0x7C00
bits 16

%define ENDL 0x0D, 0xA

; FAT12 header
jmp short start
nop

bdb_oem: db 'MSWIN4.1' ; 8 bytes
bdb_bytes_per_sector: dw 512
bdb_sectors_per_cluster: db 1
bdb_reserved_sectors: dw 1
bdb_fat_count: db 2
bdb_dir_entries_count: dw 0xE0
bdb_total_sectors: dw 2880 ; 2880 * 512 = 1.44 MB
bdb_media_descriptor_type: db 0xF0 ; F0 = 3.5" floppy disk
bdb_sectors_per_fat: dw 9 ; 9 sectors/fat
bdb_sectors_per_track: dw 18
bdb_heads: dw 2
bdb_hidden_sectors: dd 0
bdb_large_sector_count: dd 0

; extended boot record
ebr_drive_number: db 0 ; 0x00 = floppy, 0x80 = hdd, useless
db 0
ebr_signature: db 0x29
ebr_volume_id: db 0x12, 0x34, 0x56, 0x78 ; serial number
ebr_volume_label: db 'OWL OS     ' ; 11 bytes, padded with spaces
ebr_system_id: db 'FAT12   ' ; 8 bytes, padded with spaces

;
; Code goes here
;


start:
	; setup data segments
	mov ax, 0
	mov ds, ax
	mov es, ax

	; setup stack
	mov ss, ax
	mov sp, 0x7C00
	
	; some BIOSes might start us at 07C0:0000 instead of 0000:7C00
	; make sure we are in the expected location 
	push es
	push word .after
	retf
.after:

	; read something from floppy disk
	; BIOS should set DL to drive number
	mov [ebr_drive_number], dl

	; show loading message
	mov si, msg_loading
	call puts

	; read drive parameters
	push es
	mov ah, 0x08
	int 0x13
	jc floppy_error
	pop es

	and cl, 0x3F ; remove top 2 bits
	xor ch, ch ; set ch to 0
	mov [bdb_sectors_per_track], cx ; sector count

	inc dh
	mov [bdb_heads], dh ; head count

	; compute LBA of root directory = reserved + fats * sectors_per_fat
	; note: this section can be hardcoded
	mov ax, [bdb_sectors_per_fat]
	mov bl, [bdb_fat_count]
	xor bh, bh
	mul bx ; ax = (fats * sectors_per_fat)
	add ax, [bdb_reserved_sectors] ; LBA of root directory
	push ax

	; compute size of root directory = (32 * number_of_entries) / bytes_per_sector
	mov ax, [bdb_dir_entries_count]
	shl ax, 5 ; ax *= 32
	xor dx, dx ; dx = 0
	div word [bdb_bytes_per_sector] ; number of sectors we need to read

	test dx, dx ; if dx != 0, add 1
	jz .root_dir_after
	inc ax ; division reminder != 0, add 1

.root_dir_after:

	; read root directory
	mov cl, al ; cl = number of sectors to read = size of root directory
	pop ax ; ax = LBA of root directory
	mov dl, [ebr_drive_number] ; dl = drive number (we saved it previously)
	mov bx, buffer ; es:bx = buffer
	call disk_read

	; search for stage2.bin
	xor bx, bx
	mov di, buffer
	
.search_stage2:
	mov si, file_stage2_bin
	mov cx, 11 ; compare up to 11 characters
	push di
	repe cmpsb
	pop di
	je .found_stage2

	add di, 32
	inc bx
	cmp bx, [bdb_dir_entries_count]
	jl .search_stage2

	; stage2 not found
	jmp stage2_not_found_error

.found_stage2:

	; di sould have the address to the entity
	mov ax, [di + 26]
	mov [stage2_cluster], ax

	; load FAT from disk into memory
	mov ax, [bdb_reserved_sectors]
	mov bx, buffer
	mov cl, [bdb_sectors_per_fat]
	mov dl, [ebr_drive_number]
	call disk_read

	; read stage2 and process FAT chain
	mov bx, STAGE2_LOAD_SEGMENT
	mov es, bx
	mov bx, STAGE2_LOAD_OFFSET

.load_stage2_loop:
	; read next cluster
	mov ax, [stage2_cluster]

	add ax, 31 ; TODO: Avoid hardcoded value
	mov cl, 1
	mov dl, [ebr_drive_number]
	call disk_read

	add bx, [bdb_bytes_per_sector]

	; compute location of next cluster
	mov ax, [stage2_cluster]
	mov cx, 3
	mul cx
	mov cx, 2
	div cx ; ax = index of entry in FAT, dx = cluster mod 2

	mov si, buffer
	add si, ax
	mov ax, [ds:si] ; read entry from FAT table and index ax

	or dx, dx
	jz .even

.odd:
	shr ax, 4
	jmp .next_cluster_after

.even:
	and ax, 0x0FFF

.next_cluster_after:
	cmp ax, 0x0FF8 ; end of chain
	jae .read_finish

	mov [stage2_cluster], ax
	jmp .load_stage2_loop

.read_finish:

	; jump to our stage2
	mov dl, [ebr_drive_number] ; boot device in dl
	
	mov ax, STAGE2_LOAD_SEGMENT ; set segment registers
	mov ds, ax
	mov es, ax

	jmp STAGE2_LOAD_SEGMENT:STAGE2_LOAD_OFFSET

	jmp wait_key_and_reboot ; should never happen

	cli
	hlt

;
; Error handlers
;

floppy_error:
	mov si, msg_read_failed
	call puts
	jmp wait_key_and_reboot

stage2_not_found_error:
	mov si, msg_stage2_not_found
	call puts
	jmp wait_key_and_reboot

wait_key_and_reboot:
	mov ah, 0
	int 16h ; wait for keypress
	jmp 0xFFFF:0 ; jump to beginning of the BIOS, should reboot

.halt:
	cli
	hlt



; Prints a string to the screen
; Params:
;   - ds:si points to string
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

;
; Disk routines
;

; Converts an LBA address to a CHS address
; Params:
;   - ax: LBA address
; Returns:
;   - cx [bits 0-5]: sector number
;   - cx [bits 6-15]: cylinder
;   - dh: head
lba_to_chs:
	push ax
	push dx

	xor dx, dx ; dx = 0
	div word [bdb_sectors_per_track] ; ax = LBA / SectorsPerTrack
	                                 ; dx = LBA % SectorsPerTrack
	inc dx ; dx = LBA % SectorsPerTrack + 1 = sector
	mov cx, dx ; cx = sector

	xor dx, dx ; dx = 0
	div word [bdb_heads] ; ax = (LBA / SectorsPerTrack) / Heads = cylinder
	                     ; dx = (LBA / SectorsPerTrack) % Heads = head
	mov dh, dl ; dh = head
	mov ch, al ; ch = cylinder (lower 8 bits)
	shl ah, 6
	or cl, ah ; put upper 2 bits of cylinder in CL

	pop ax
	mov dl, al ; restore dl
	pop ax
	ret

; Reads sectors from a disk
; Params:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address where to store read data
disk_read:
	; save registers we will modify
	push ax
	push bx
	push cx
	push dx
	push di

	push cx ; temporarily save cl (number of sectors to read)
	call lba_to_chs ; compute CHS
	pop ax ; al = number of sectors to read
	
	mov ah, 0x02
	mov di, 3 ; retry count
.retry:
	pusha ; save all registers, we don't know what BIOS modifies
	stc ; set carry flag, some BIOSes don't set it
	int 0x13 ; carry flag cleared = success
	jnc .done ; jump if carry not set

	; read failed
	popa
	call disk_reset

	dec di
	test di, di
	jnz .retry

.fail:
	; all attempts are exhausted
	jmp floppy_error

.done:
	popa

	; restore registers we've modified
	pop di
	pop dx
	pop cx
	pop bx
	pop ax

	ret

; Resets disk controller
; Params:
;   - dl: drive number
disk_reset:
	pusha
	mov ah, 0
	stc
	int 0x13
	jc floppy_error
	popa
	ret


msg_loading: db 'Loading...', ENDL, 0
msg_read_failed: db 'Read from disk failed!', ENDL, 0
msg_stage2_not_found: db 'STAGE2.BIN file not found!', ENDL, 0
file_stage2_bin: db 'STAGE2  BIN'
stage2_cluster: dw 0

STAGE2_LOAD_SEGMENT equ 0x0
STAGE2_LOAD_OFFSET equ 0x500

times 510-($-$$) db 0
dw 0xAA55

buffer: