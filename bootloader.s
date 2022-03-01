.intel_syntax noprefix
.code16
.section .stage1, "ax"

.set SETUP_BUFFER, 0x8000

/*
 * Defining a macro tu use the Magic Breakpoint from Bochs
 */
.macro DEBUG
xchg bx, bx
.endm

_start:
    jmp _start_16       # Specific instruction for BIOSes to boot
    nop
    .space 59, 0        # Faking a BPB, might add a real one later

_start_16:
    ljmp 0x0000:_init   # Clearing CS:IP. Some BIOSes tends to set CS:IP as follow : _init:0x0000, which is not what we want

_init:
    /*  We have to disable interrupts while we setup the stack because they use the stack
     *  If an interrupt happens in the middle of setting up the stack
     *  We won't know where the stack is and we could overwrite code
     */

    cld     #Disable Interrupts

    mov bp, _start      # Setting up the stack while interrupts beeing disabled
    mov sp, bp

    xor ax, ax          # Xoring is better than doing : mov ax, 0 because it uses less byte instructions (WE ARE LIMITED !)
    mov es, ax          # Extra segment
    mov ss ,ax          # Stack Segment
    mov ds, ax          # Data Segment
    mov fs, ax          # General Purpose Segment
    mov gs, ax          # General Purpose Segments
    
    cli                 # Reenable interrupts

    /*
     * When the BIOS starts, it places the boot driver number in the <dl> register for us
     * Therefore, I prefer so save the boot driver number to a variable to be extra sure..
     * 
     * Floppy A = 0, Drive 1 = 0x80, Drive 2 = 0x80, ...
     */

    mov [boot_param_disk_drive], dl       # boot_param_disk_drive contains the drive number to read sectors from 

    
    mov bx, offset flat:initStr
    call print_string
    
    mov dx, cs
    call print_hex
    
    mov bl, ':'
    call print_char

    call get_ip_register                # Store IP to AX
    sub ax, . - _start                  # . - _start = an offset. So we sub this from AX to get 0x7c000 as it is supposed to be loaded at this address
    mov dx, ax
    call print_hex

    mov bx, SETUP_BUFFER
    mov dl, [boot_param_disk_drive]     # As we have used dl register, we have overwritten the disk number given by the BIOS. So we restore it thanks to the variable
    call load_sectors

    ljmp 0x0000:SETUP_BUFFER

/*
 * In 16 bit, we cannot ge the value from IP. 
 * However, when we call a function, the IP register is pushed to the stack. So by exploiting this, we call 
 * The function get_ip_register. At this point we sould have the IP value to the stack. 
 * However, we cannot use sp as a base index. So we mov sp to bx and dereference BX to get the value of IP.
 */

get_ip_register:
    mov bx, sp
    mov ax, [bx]
    ret

.include "16_print.s"
.include "16_print_hex.s"
.include "disk.s"
boot_param_disk_drive:
    .byte 0x0

initStr:
    .asciz "Loaded bootloader at : "


# Fill space from _start to here (510) with zero because the first sector must be exactly 512 byte. At the 512th byte there must be the magic number 
. = _start + 510 
.word 0xAA55        # Magic number in order for the BIOS to boot the bootloader. Without this, it's not bootable

.section .stage2, "ax"

second:
    mov bx, offset flat:str
    call print_string
    jmp .

    str:
        .asciz "test"