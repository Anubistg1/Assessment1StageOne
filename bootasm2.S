# Second stage of the boot loader

.code16                         # Assemble for 16-bit mode
.globl start

#define dx  -2
#define x0  -4
#define x1  -6
#define dy  -8
#define y0  -10
#define y1  -12
#define c   -14
#define sx  -16
#define sy  -18
#define err -20
#define e1  -22
#define e2  -24

start:
    jmp     real_start

# Write to the console using BIOS.
# 
# Input: SI contains the address of the null-terminated string to be displayed

cons_write:
    movb    $0x0e, %ah           # 0x0e is the INT 10h BIOS call to output the value contained in AL to screen

cons_write_rpt:
    movb    (%si), %al          # Load the byte at the location contained in the SI register into AL   
    inc     %si                 # Add 1 to the value in SI
    cmp     $0, %al             # Compare the value in AL with 0
    jz      cons_write_done     # If it is zero, then we are done
    int     $0x10               # Output the character in AL to the screen
    jmp     cons_write_rpt      # and continue

cons_write_done:                # Something that is called will never return 
    ret                         # until a 'ret' instruction is encountered.  Labels do 
                                # not give a program any structure.  They just give a 
                                # memory location a name that we can use in our code. 

cons_write_crlf:
    movb    $0x0e, %ah          # Output CR
    movb    $0x0d, %al
    int     $0x10
    movb    $0x0a, %al          # Output LF
    int     $0x10
    ret

cons_writeline:
    call    cons_write
    call    cons_write_crlf
    ret    

real_start:
    movw    $boot_message, %si  # Display our boot message
    call    cons_writeline
    call    video_mode

endless_loop:                   # Loop forever more
    jmp     endless_loop    

Set_sx:
    mov sx(%bp), $-1
    ret

Set_sy:
    mov sx(%bp), $-1
    ret

Check_Y_equals:

video_mode:
    movb    $0, %ah
    movb    $0x13, %al
    int     $0x10

drawline:
    push %bp
    movw %sp, %bp
    subw $4, %sp # Reserve sapce for variables
    movw x1(%bp), %ax
    subw %ax, 0x(%bp)    # x1 - x0
    movw dx(%bp), %ax   # result in dx
    movw y1(%bp), %ax
    subw %ax, 0y(%bp)    # y1 - y0
    movw dy(%bp), %ax   # result in dy
    mov sx(%bp), $1
    cmp x1(%bp), x0(%bp) # Sets sx
    jl Set_sx
    mov sy(%bp), $1
    cmp y1(%bp), y0(%bp) # Sets sy
    jl Set_sy
    movw dx(%bp), %ax
    subw %ax, dy(%bp)    # dx - dy
    movw err(%bp), %ax   # result in dy

plot_pixels:
    movb    $0x0C, %ah
    movb    $15, %al    # Pixel colour
    movb    $0, %bh     # Video page number
    mov    $78, %cx     # Column number
    mov    $50, %dx     # Row Number
    int     $0x10

    cmp x0(%bp), x1(%bp)
    je

# Program data

boot_message:     
    .string "Boot Loader Stage 2 loaded"             

pixel_one_data:
    .string "9"     # Pixel colour
    .string "40"    # x location
    .string "70"    # y location

pixel_two_data:
    .string "85"    # x location
    .string "7"    # y location
