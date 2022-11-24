# Second stage of the boot loader

.code16                         # Assemble for 16-bit mode
.globl start
# Parameter references

#define col  12
#define y1  10
#define y0  8
#define x1  6
#define x0  4

# Local references

#define changex  -2  
#define e2   -4
#define c  -6
#define changey  -8
#define sy  -10
#define sx  -12
#define err -14


start:
    jmp     real_start

# Write to the console using BIOS.
# 
# Input: SI contains the address of the null-terminated string to be displayed

# Check_Y_equals:
#    movb x0, %al
#    cmp %al, x1    
#    ret
    

video_mode:
    movb    $0, %ah
    movb    $0x13, %al
    int     $0x10
    ret

drawline_absolute_X:
    push %bp
    movw %sp, %bp
    subw $10, %sp # Reserve space for variables
    pushw   %ax # Save the registers as they will get trashed
    pushw   %bx
    pushw   %cx
    pushw   %dx
    pushw   %si
    pushw   %di
    movw    $1, %si
    movw    %si, err(%bp) # err
    movw    %si, sx(%bp) # sx
    movw    %si, sy(%bp) # sy
    movw    %si, changey(%bp) # changey
    movw    %si, c(%bp) # c
    movw    %si, e2(%bp) # e2
    movw    %si, changex(%bp) # changex
    movw x1(%bp), %ax
    subw x0(%bp), %ax    # x1 - x0
    jns move_dx_into_variable
    movw $-1, %dx
    imul %dx # makes %ax positive
    movw $-1, sx(%bp) # sets sx -1 as x0 < x1
    movw %ax, changex(%bp)
    jmp get_absolute_y    
move_dx_into_variable:
    movw %ax, changex(%bp) # maintains positive
    movw $1, sx(%bp) # sets sx 1 as x0 => x1

get_absolute_y:
    movw y1(%bp), %ax
    subw y0(%bp), %ax    # y1 - y0
    jns move_dy_into_variable
    movw $-1, %dx
    imul %dx # makes %ax positive
    movw $-1, sy(%bp) # sets sy -1 as y0 < y1
    movw %ax, changey(%bp) 
    jmp set_err
move_dy_into_variable:
    movw %ax, changey(%bp) # maintains positive
    movw $1, sy(%bp) # sets sy 1 as y0 < y1

set_err:
    movw changex(%bp), %ax
    subw changey(%bp), %ax    # dx - dy
    movw %ax, err(%bp)   # result in dy also break it in current form fix swap them around

plot_pixels:
    movw x0(%bp), %ax
    cmp %ax, x1(%bp)         # current maths check
    jne pixel_calc
    movw y0(%bp), %ax
    cmp %ax, y1(%bp)    # checks to exit loop
    jne pixel_calc
    jmp End_Of_Line
    

pixel_calc:
    movw err(%bp), %ax
    imul $2, %ax
    movw %ax, e2(%bp) # sets e2
    movw changey(%bp), %ax
    movw $-1, %dx
    imul %dx # multiplies by -1 for the cmp, when doing the maths bidmas means changing the next equation e2 = 2 * err
    cmp e2(%bp), %ax 
    jg Y_pixel_change

X_pixel_change:
    movw err(%bp), %ax
    subw changey(%bp), %ax    # err - dy
    movw %ax, err(%bp)   # result in err
    movw x0(%bp), %ax
    addw sx(%bp), %ax    # sx + x0
    movw %ax, x0(%bp)   # result in x0

Y_pixel_change:
    movw e2(%bp), %ax
    cmp %ax, changex(%bp) # other possible error
    jle draw_pixel
    movw err(%bp), %ax
    addw changex(%bp), %ax    # err + dx
    movw %ax, err(%bp)   # result in err
    movw y0(%bp), %ax
    addw sy(%bp), %ax    # sy + y0
    movw %ax, y0(%bp)   # result in y0    


draw_pixel:
    movb    $0x0C, %ah  # Pass things in via registers!
    movb    col(%bp), %al    # Pixel colour  currently works with $15
    movb    $0, %bh     # Video page number
    mov     x0(%bp), %cx     # Column number
    mov     y0(%bp), %dx     # Row Number
    int     $0x10
    jmp     plot_pixels

End_Of_Line:
    popw    %di
    popw    %si
    popw    %dx
    popw    %cx
    popw    %bx
    popw    %ax
    movw    %bp, %sp
    pop    %bp     
    ret $10 # parameters x 2    

# Program data
real_start:
    call   video_mode
    # Line 1
    pushw    $15 # colour white
    pushw    $190 # y1
    pushw    $160 # y0
    pushw    $75 # x1
    pushw    $30 # x0
    call    drawline_absolute_X
    # Line 2
    pushw    $14 # colour yellow
    pushw    $45 # y1
    pushw    $67 # y0
    pushw    $87 # x1
    pushw    $87 # x0
    call    drawline_absolute_X
    # Line 3
    pushw    $13 # colour light magenta
    pushw    $144 # y1
    pushw    $144 # y0
    pushw    $50 # x1
    pushw    $79 # x0
    call    drawline_absolute_X
    # Line 4
    pushw    $12 # colour light red
    pushw    $34 # y1
    pushw    $145 # y0
    pushw    $100 # x1
    pushw    $300 # x0
    call    drawline_absolute_X
    # Line 5
    pushw    $11 # colour light cyan
    pushw    $145 # y1
    pushw    $34 # y0
    pushw    $100 # x1
    pushw    $300 # x0
    call    drawline_absolute_X
    # Line 6
    pushw    $10 # colour light green
    pushw    $18 # y1
    pushw    $26 # y0
    pushw    $56 # x1
    pushw    $75 # x0
    call    drawline_absolute_X
    # Line 7
    pushw    $9 # colour light blue
    pushw    $10 # y1
    pushw    $24 # y0
    pushw    $15 # x1
    pushw    $38 # x0
    call    drawline_absolute_X
    # Line 8
    pushw    $8 # colour dark grey
    pushw    $10 # y1
    pushw    $26 # y0
    pushw    $140 # x1
    pushw    $90 # x0
    call    drawline_absolute_X
    # Line 9
    pushw    $7 # colour light grey
    pushw    $50 # y1
    pushw    $70 # y0
    pushw    $60 # x1
    pushw    $80 # x0
    call    drawline_absolute_X
    # Line 10
    pushw    $6 # colour brown
    pushw    $100 # y1
    pushw    $120 # y0
    pushw    $120 # x1
    pushw    $140 # x0
    call    drawline_absolute_X
    # falls through
endless_loop:                   # Loop forever more
    jmp endless_loop    


