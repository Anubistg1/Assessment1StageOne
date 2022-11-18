# Second stage of the boot loader

.code16                         # Assemble for 16-bit mode
.globl start

#define changex  30
#define e2  28
#define c  26
#define changey  24
#define sy  22
#define err  20
#define sx   18
#define x0  16
#define x1  14
#define y0  12
#define y1  10
#define col 8
#define     number      6
#define     base        4

#define     endofstring -2

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

# Output the 16-bit value in BX to the screen has a 4 digit hex value	
#
# Input:  BX = Value to output	

HexChars:	.ascii "0123456789ABCDEF"

# Output the value passed on the stack to the screen using the specified base
#



cons_write_number:
    pushw   %bp                 # Save existing frame pointer
    movw    %sp, %bp            # Setup our frame pointer
    subw    $18, %sp            # Reserve space for our string buffer
    pushw   %ax                 # Save the registers we will trash
    pushw   %bx
    pushw   %cx
    pushw   %dx
    pushw   %si
    pushw   %di

    movw    %bp, %si
    subw    $3, %si
    movb    $0, endofstring(%bp)    # Insert end of string indicator (0)    
    movw    number(%bp), %ax
	
getdigit:
	xor		%dx, %dx                # Divide number by base
	movw	base(%bp), %cx
	div		%cx
    movw    %dx, %di                # Convert remainder to hex character
    movb    HexChars(%di), %dl      # and stpre in buffer
	movb	%dl, (%si)
	dec		%si
	cmpw	$0, %ax                 # Have we extracted all digits?
	jne		getdigit
	inc		%si
	call	cons_write              # Output the string

    popw    %di                     # Restore the registers
    popw    %si
    popw    %dx
    popw    %cx
    popw    %bx
    popw    %ax
    movw    %bp, %sp                # Delete the local variables
    popw    %bp
    ret     $4                      # Return, removing paramters from stack


	ret
	
IntBuffer:   .string "     "


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


Check_Y_equals:
    movb x0, %al
    cmp %al, x1    
    ret
    

video_mode:
    movb    $0, %ah
    movb    $0x13, %al
    int     $0x10
    ret

drawline_absolute_X:
    movw    %si, col(%bp)
    movw    %ax, y1(%bp)
    movw    %bx, y0(%bp)
    movw    %cx, x1(%bp)
    movw    %dx, x0(%bp)
    movw    $1, %si
    movw    %si, sx(%bp)
    movw    %si, err(%bp)
    movw    %si, sy(%bp)
    movw    %si, changey(%bp)
    movw    %si, c(%bp)
    movw    %si, e2(%bp)
    movw    %si, changex(%bp)
    push %bp
    movw %sp, %bp
    subw $30, %sp # Reserve space for variables
    movw x1, %ax
    subw x0, %ax    # x1 - x0
    jns move_dx_into_variable
    movw $-1, %dx
    imul %dx # makes %ax positive
    movw $-1, sx # sets sx -1 as x0 < x1
    movw %ax, changex
    jmp get_absolute_y    
move_dx_into_variable:
    movw %ax, changex # maintains positive
    movw $1, sx # sets sx 1 as x0 => x1

get_absolute_y:
    movw y1, %ax
    subw y0, %ax    # y1 - y0
    jns move_dy_into_variable
    movw $-1, %dx
    imul %dx # makes %ax positive
    movw $-1, sy # sets sy -1 as y0 < y1
    movw %ax, changey 
    jmp set_err
move_dy_into_variable:
    movw %ax, changey # maintains positive
    movw $1, sy # sets sy 1 as y0 < y1

set_err:
    movw changex, %ax
    subw changey, %ax    # dx - dy
    movw %ax, err   # result in dy also break it in current form fix swap them around

plot_pixels:
    movw x0, %ax
    cmp %ax, x1         # current maths check
    jne pixel_calc
    movw y0, %ax
    cmp %ax, y1    # checks to exit loop
    jne pixel_calc
    jmp End_Of_Line
    

pixel_calc:
    movw err, %ax
    imul $2, %ax
    movw %ax, e2 # sets e2
    movw changey, %ax
    movw $-1, %dx
    imul %dx # multiplies by -1 for the cmp, when doing the maths bidmas means changing the next equation e2 = 2 * err
    cmp e2, %ax 
    jg Y_pixel_change

X_pixel_change:
    movw err, %ax
    subw changey, %ax    # err - dy
    movw %ax, err   # result in err
    movw x0, %ax
    addw sx, %ax    # sx + x0
    movw %ax, x0   # result in x0

Y_pixel_change:
    movw e2, %ax
    cmp %ax, changex # other possible error
    jle draw_pixel
    movw err, %ax
    addw changex, %ax    # err + dx
    movw %ax, err   # result in err
    movw y0, %ax
    addw sy, %ax    # sy + y0
    movw %ax, y0   # result in y0    


draw_pixel:
    movb    $0x0C, %ah # Pass things in via registers!
    movb    col, %al    # Pixel colour  currently works with $15
    movb    $0, %bh     # Video page number
    mov     x0, %cx     # Column number
    mov     y0, %dx     # Row Number
    int     $0x10
    jmp     plot_pixels

End_Of_Line:
    movw %bp, %sp
    pop %bp     
    ret    

# Program data
real_start:
    movw    $boot_message, %si  # Display our boot message
    call    cons_writeline
    call    video_mode
    # Line 1
    movw    $15, %si # colour white
    movw    $190, %ax # y1
    movw    $160, %bx # y0
    movw    $75, %cx # x1
    movw    $30, %dx # x0
    call    drawline_absolute_X
    # Line 2
    movw    $14, %si # colour yellow
    movw    $45, %ax # y1
    movw    $67, %bx # y0
    movw    $87, %cx # x1
    movw    $87, %dx # x0
    call    drawline_absolute_X
    # Line 3
    movw    $13, %si # colour light magenta
    movw    $144, %ax # y1
    movw    $144, %bx # y0
    movw    $50, %cx # x1
    movw    $79, %dx # x0
    call    drawline_absolute_X
    # Line 4
    movw    $12, %si # colour light red
    movw    $34, %ax # y1
    movw    $145, %bx # y0
    movw    $100, %cx # x1
    movw    $300, %dx # x0
    call    drawline_absolute_X
    # Line 5
    movw    $11, %si # colour light cyan
    movw    $145, %ax # y1
    movw    $34, %bx # y0
    movw    $100, %cx # x1
    movw    $300, %dx # x0
    call    drawline_absolute_X
    # Line 6
    movw    $10, %si # colour light green
    movw    $18, %ax # y1
    movw    $26, %bx # y0
    movw    $56, %cx # x1
    movw    $75, %dx # x0
    call    drawline_absolute_X
    # Line 7
    movw    $9, %si # colour light blue
    movw    $10, %ax # y1
    movw    $24, %bx # y0
    movw    $15, %cx # x1
    movw    $38, %dx # x0
    call    drawline_absolute_X
    # Line 8
    movw    $8, %si # colour dark grey
    movw    $10, %ax # y1
    movw    $26, %bx # y0
    movw    $140, %cx # x1
    movw    $90, %dx # x0
    call    drawline_absolute_X
    # Line 9
    movw    $7, %si # colour light grey
    movw    $50, %ax # y1
    movw    $70, %bx # y0
    movw    $60, %cx # x1
    movw    $80, %dx # x0
    call    drawline_absolute_X
    # Line 10
    movw    $6, %si # colour brown
    movw    $100, %ax # y1
    movw    $120, %bx # y0
    movw    $120, %cx # x1
    movw    $140, %dx # x0
    call    drawline_absolute_X

endless_loop:                   # Loop forever more
    jmp endless_loop    

boot_message:     
    .string "Boot Loader Stage 2 loaded"             

# .word variables
