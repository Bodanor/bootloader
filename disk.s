load_sectors:
    pusha
/*
 * AH : Read Disk Sectors
 * AL = number of sectors to read
 * CH = Track/cylinder number
 * CL = Sector Number (our bootloader is the 1 one, so we start reading at sector 2)
 * DH = Head number
 * DL = Drive number -->  Floppy A = 0, Drive 1 = 0x80, Drive 2 = 0x80, ...
 * ES:BX = Pointer to buffer
 */

    mov cl, 2       # We place this here because if we loop, then it's gonna be resetted if we write this instruction in the loop

/*
 * This is a loop where at each iteration we read 1 sector. We could have said to read how many sectors we "need", but this is unknown
 * To us except if we calculate how many we really need. But doing so will lead to recompile the bootloader...
 * So We read until we fail. If we have read 0 sectors then there was a disk error. Else, we have read the whole disk
 */

sectors_loop:

    mov al, 0x1 # read one sector at each iteration
    mov ah, 0x02
    mov ch, 0
    mov dh, 0
    # Here, dl contains the disk number to read sectors from.

    int 0x13                            #Interrupt to read sectors with ah = 0x02 (Read Disk Sectors)
    jc check_sectors_read                # Carry flag if success. Did we succeede ?

    cmp al, 1                           # If we succeeded, we compare al with 1 as al contains how many sectors int 0x13 has read.
    jne check_sectors_read               # Same as the carry flag

    /*
     * Remember that cl contains where int 0x13 should start reading into the floppy disk. 
     *  If this is constant then we would read the same sector...
     */
    inc cl                            


    push bx                             # Save value in BX (pointer buffer)
    xor bx, bx
    mov bl, byte ptr[SECTORS_READ]       # SECTORS_READ contains how many sectors in total we have read. So we load this in BX, increment it and replace in the variable
    inc bx
    mov byte ptr [SECTORS_READ], bl
    pop bx                              # Restore pointer to buffer

    add bx, 512                         # As we read 1 sector (512 bytes) at a time, if this is constant we would overwritten what we have read previously 
    jmp sectors_loop                    # Loop until we error


check_sectors_read:

    mov bl, byte ptr[SECTORS_READ]           # Load SECTORS_READ, if it's zero then there was a fatal error with the disk 
    cmp bx, 0
    je sectors_error

    mov bx, offset flat:sector_read_total    # If no problem occured, we show how many sectors in total we have read !
    call print_string

    xor dx, dx
    mov dl, byte ptr[SECTORS_READ]
    call print_hex

    mov bl, '\n'
    call print_char
    mov bl, '\r'
    call print_char
    jmp disk_end


sectors_error:

    mov bx, offset flat:sectors_Error_Str
    call print_string
    jmp disk_inf_loop



disk_end:

    popa            # If we are here, then everything went fine
    ret

disk_inf_loop:

    jmp .           # Only a reboot can get you out of this :(((


SECTORS_READ:
    .byte 0         # Variable that contains how many sectors we have read in total.

disk_Error_Str:
    .asciz "\nDisk Error Please Reboot !"
sectors_Error_Str:
    .asciz "\nSectors Error\n"
    
sector_read_total:
    .asciz "\Numbers of sectors read -->"

    