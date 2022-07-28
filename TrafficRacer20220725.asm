###################################################################### 
# CSCB58 Summer 2022 Project 
# University of Toronto, Scarborough 
# 
# Student Name: GARY CHEN, Student Number: 1007193065, UTorID: chengar6 
# 
# Bitmap Display Configuration: 
# - Unit width in pixels: 8 (update this as needed) 
# - Unit height in pixels: 8 (update this as needed) 
# - Display width in pixels: 256 (update this as needed) 
# - Display height in pixels: 256 (update this as needed) 
# - Base Address for Display: 0x10008000 
# 
# Basic features that were implemented successfully 
# - Basic feature a/b/c (choose the ones that apply) 
# 
# Additional features that were implemented successfully 
# - Additional feature a/b/c (choose the ones that apply) 
#  
# Link to the video demo 
# - Insert YouTube/MyMedia/other URL here and make sure the video is accessible 
# 
# Any additional information that the TA needs to know: 
# - Write here, if any 
#  
###################################################################### 

.data
displayAddress:      .word 0x10008000  
displayHeight: .byte 8
# each block is 8 size, 32 blocks screen 
red: .word 0xff0000
blue: .word 0x00ff00
green: .word 0x0000ff
yellow: .word 0xffff00
magenta: .word 0xff00ff
cyan: .word 0x00ffff
black: .word 0x000000
white: .word 0xffffff

keypressAddress: .word 0xffff0000
wKey: .byte 119
aKey: .byte 97 # 97
sKey: .byte 115
dKey: .byte 100
qKey: .byte 113

startingPositionX: .byte 128
startingPositionY: .byte 128

carX:
carY:
carSpeed:
carLives:

enemyCars: .space 400 #struct: x, y


.text 
lw $t0, displayAddress    # $t0 stores the base address for display  
lw $t1, yellow
lw $t2, displayAddress
addi $t2, $t2, 56 #around the middle

add $t3, $zero, $zero

#idea
# main loop
# call functions
# checkInput
# updateCarLocation
# checkCollision (compare every car x y)
# updateOthercars
# redrawScreen (road first, then cars)
# sleep
# repeat


# test to draw some yellow road strips
yellowLoop:
	beq $t3, 32, whitePrep
	sw $t1, 0($t2)
	addi $t2, $t2, 8 # prepare second strip to the right
	sw $t1, 0($t2)
	addi $t2, $t2, 120 #new row
	addi $t3, $t3, 1
	j yellowLoop

whitePrep:
add $t3, $zero, $zero
lw $t1, white
addi $t2, $t0, 24 #around the middle
whiteLoop:
	beq $t3, 32, exit
	sw $t1, 0($t2)
	addi $t2, $t2, 64 # 

	sw $t1, 0($t2)
	addi $t2, $t2, 128 #skip a row
	addi $t3, $t3, 1
	j whiteLoop

exit:  
li $v0, 10 # terminate the program  
syscall  