# Second stage of the boot loader

.code16                         # Assemble for 16-bit mode
.globl start

#define changex  -2
#define x0  -4
#define x1  -6
#define changey  -8
#define y0  -10
#define y1  -12
#define c   -14
#define sx  -16
#define sy  -18
#define err -20
#define e2  -22
#define col -24


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
    movb    $15, %al
    movb    $50, %dh
    movb    $65, %dl
    movb    $34, %ch
    movb    $24, %cl
    call    video_mode

endless_loop:                   # Loop forever more
    jmp     endless_loop    



Check_Y_equals:
    movb x0(%bp), %al
    cmp %al, x1(%bp)
    call endless_loop


video_mode:
    movb    $0, %ah
    movb    $0x13, %al
    int     $0x10
    call drawline

Set_sx:
    movw $-1, sx(%bp)
    

Set_sy:
    movw $-1, sy(%bp)
    

drawline:
    movb    %al, (col)
    movb    %dh, (y1)
    movb    %dl, (y0)
    movb    %ch, (x1)
    movb    %cl, (x0)
    push %bp
    movw %sp, %bp
    subw $4, %sp # Reserve space for variables
    movw x1(%bp), %ax
    subw %ax, x0(%bp)    # x1 - x0
    movw changex(%bp), %ax   # result in dx
    movw y1(%bp), %ax
    subw %ax, y0(%bp)    
    movw changey(%bp), %ax   # result in dy
    movw $1, sx(%bp)
    movw x1(%bp), %ax
    cmp %ax, x0(%bp) # Sets sx
    jl Set_sx
    movw $1, sy(%bp)
    movw y1(%bp), %ax
    cmp %ax, y0(%bp) # Sets sy
    jl Set_sy
    movw changex(%bp), %ax
    subw %ax, changey(%bp)    # dx - dy
    movw err(%bp), %ax   # result in dy
    call plot_pixels

X_pixel_change:
    movw err(%bp), %ax
    addw %ax, changey(%bp)    # err + dy
    movw err(%bp), %ax   # result in err
    movw x0(%bp), %ax
    addw %ax, sx(%bp)    # sx + x0
    movw x0(%bp), %ax   # result in x0


Y_pixel_change:
    movw err(%bp), %ax
    addw %ax, changex(%bp)    # err + dy
    movw err(%bp), %ax   # result in derr
    movw y0(%bp), %ax
    addw %ax, sy(%bp)    # sy + y0
    movw y0(%bp), %ax   # result in y0 
    
plot_pixels:
    movw x0(%bp), %ax
    cmp %ax, x1(%bp)
    je Check_Y_equals # checks to exit loop
    movw err(%bp), %ax
    imul $2, %ax
    movw e2(%bp), %ax # sets e2
    movw changey(%bp), %ax
    movw $-1, %dx
    imul %dx # multiplies by -1 for the cmp, when doing the maths bidmas means changing the next equation
    movw %ax, changey(%bp)
    movw e2(%bp), %ax
    cmp %ax, changey(%bp)
    jge X_pixel_change
    movw e2(%bp), %ax
    cmp %ax, changex(%bp)
    jl Y_pixel_change

    movb    $0x0C, %ah
    movb    col(%bp), %al    # Pixel colour
    movb    $0, %bh     # Video page number
    mov     x0(%bp), %cx     # Column number
    mov     y0(%bp), %dx     # Row Number
    int     $0x10
    ret

# Program data

boot_message:     
    .string "Boot Loader Stage 2 loaded"             


