# Demo for painting  
# Bitmap Display Configuration:  
# - Unit width in pixels: 8  
# - Unit height in pixels: 8  
# - Display width in pixels: 256  
# - Display height in pixels: 256  
# - Base Address for Display: 0x10008000 ($gp) 
.data 
displayAddress:      .word 0x10008000  
red: .word 0xff0000
blue: .word 0x00ff00
green: .word 0x0000ff
yellow: .word 0xffff00
.text  
lw $t0, displayAddress    # $t0 stores the base address for display  
lw $t1, red                    # $t1 stores the red colour code  
lw $t2, blue                    # $t2 stores the green colour code  
lw $t3, green                     # $t3 stores the blue colour code  
lw $t4, yellow                     # $t4 stores the yellow
sw $t1, 0($t0)             # paint the first (top-left) unit red  
sw $t2, 4($t0)   # paint the second unit on the first row green 
sw $t3, 128($t0)   # paint the first unit on the second row blue  
sw $t4, 132($t0)#paint second unit 2nd row yello
Exit:  
li $v0, 10 # terminate the program  
syscall  