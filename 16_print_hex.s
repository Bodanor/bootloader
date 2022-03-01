/*
 * Prints Hexadecimal numbers using a string
 *
 *
 * '0'-'9' = hex 0x30-0x39
 * 'A'-'F' = hex 0x41-0x46
 * 'a'-'f' = hex 0x61-0x66 
 */


print_hex:
    pusha

    mov cx, 0

hex_loop:
    cmp cx, 4           # 16 bit = 16 bits for an address --> 0x0000
    je end_hexloop

    mov ax, dx
    and ax, 0x000F      #Mask to get digit to the absolute right in HEX
    add al, 0x30
    cmp al, 0x39
    jle mov_intoBX
    add al, 0x7

mov_intoBX:
    mov bx, offset flat:hexString + 5
    sub bx, cx
    mov byte ptr[bx], al
    ror dx, 4

    add cx, 1
    jmp hex_loop



end_hexloop:
    mov bx, offset flat:hexString
    call print_string
    popa
    ret



hexString:
    .asciz "0x0000"
    