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
# - Base Address for Display: 0x10008000 ($gp)
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
unitHeight: .byte 8
unitWidth: .byte 8
displayWidth: .word 256
displayHeight: .word 256
rowUnits: .byte 32 # displayWidth/unitWidth
heightUnits: .byte 32 # displayWidth/unitWidth
# each block is 8 size, 32 blocks screen 
red: .word 0xff0000
green: .word 0x00ff00
blue: .word 0x0000ff
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

startingPositionX: .byte 16
startingPositionY: .byte 16

maxCarX: .byte 32
minCarX: .byte 0
maxCarY: .byte 32
minCarY: .byte 0

carX: .byte 16
carY: .byte 16
carSpeed: .byte 1
carLives: .byte 3

defaultCarLives: .byte 3
defaultCarSpeed: .byte 1
maxCarSpeed: .byte 3


enemyCars: .space 400 #struct: x, y


.text 
initialize:
	lb $t0, startingPositionX
	sb $t0, carX
	lb $t0, startingPositionY
	sb $t0, carY
	lb $t0, defaultCarLives
	sb $t0, carLives
	lb $t0, defaultCarSpeed
	sb $t0, carSpeed
	


lw $t0, displayAddress    # $t0 stores the base address for display  

lw $t2, displayAddress #$t2 to store current area to draw to


add $t3, $zero, $zero #loop incrementer




mainLoop:
	jal checkInput
	jal updateCarLocation
	jal drawScreen
	jal sleep1
	j mainLoop

sleep1: 
	li $v0, 32
	li $a0, 100 #sleep for 250ms
	syscall
	jr $ra

drawPixel:
	# parameters: colour address (a0), pixel offset (a1)
	sw $a0, 0($a1)
	jr $ra

drawScreen:

	lw $t0, displayAddress    # $t0 stores the base address for display  
	lw $t2, displayAddress #$t2 to store current area to draw to
	j blackPrep
	
blackPrep:
	add $a2, $gp, $zero
	add $t3, $zero, $zero

	lw $a0, black
	lw $t2, displayAddress
	move $a1, $t2
blackLoop:
	beq $t3, 1024, yellowPrep
	addi $sp, $sp, -4
	sw $t2, ($sp) #save t2
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal getPlayerAddress #obliterates t4, t5, t2
	lw $t7, ($sp) #get player address
	addi $sp, $sp, 4
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4
	lw $t2, ($sp) #get t2 back
	addi $sp, $sp, 4
	
	lw $t5, 0($a1)
	lw $t6, blue

	beq $t7, $t2, blackEnd # dont draw if on the player
	beq $t5, $t6, blackDraw # only redraw black if it is blue (player), NOT road/yellow/white

	# also check to not redraw the current carX carY positions? just trails
	# add more colours for enemies and others
	j blackEnd
blackDraw:

	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal drawPixel
	lw $ra, ($sp)
	addi $sp, $sp, 4
	j blackEnd
blackEnd:
	addi $t2, $t2, 4
	move $a1, $t2
	addi $t3, $t3, 1
	j blackLoop
	# find a better way to avoid flickering. if already, dont repaint?

	# test to draw some yellow road strips
yellowPrep:

	add $t3, $zero, $zero
	addi $t2, $t0, 56 #around middle
	
	lw $a0, yellow

yellowLoop:

	beq $t3, 32, whitePrep

	move $a1, $t2
	addi $sp, $sp, -4
	sw $ra, ($sp) #save return address
	jal drawPixel
	lw $ra, ($sp) #get return address back
	addi $sp, $sp, 4
	
	addi $t2, $t2, 8 # prepare second strip to the right
	move $a1, $t2
	
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal drawPixel
	lw $ra, ($sp)
	addi $sp, $sp, 4
	
	addi $t2, $t2, 120 #new row
	addi $t3, $t3, 1
	j yellowLoop

whitePrep:

	add $t3, $zero, $zero
	lw $t1, white
	addi $t2, $t0, 28 #around the middle
whiteLoop:
	beq $t3, 32, playerPrep
	sw $t1, 0($t2)
	addi $t2, $t2, 64 # 

	sw $t1, 0($t2)
	addi $t2, $t2, 128 #skip a row
	addi $t3, $t3, 1
	j whiteLoop

getPlayerAddress: #obliterates t4, t5, t2
	lb $t4, carX
	mul $t4, $t4, 4 # need to multiply 4 for each pixel address
	add $t2, $gp, $t4
	lb $t5, carY	
	mul $t5, $t5, 4
	mul $t5, $t5, 32 #multiply by 32 for a new row
	add $t2, $t2, $t5
	addi $sp, $sp, -4
	sw $t2, 0($sp) #save player address to stack

	jr $ra

playerPrep: 

	lw $t1, blue
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal getPlayerAddress
	lw $t2, 0($sp) # get player address from stack
	addi $sp, $sp, 4
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4

drawPlayer:
	sw $t1, 0($t2)
	
drawLoopExit:
	jr $ra
	
checkInput:
	li $t9, 0xffff0000 # 
	lw $t8, 0($t9)
	beq $t8, 1, keypress_happened #if the address has 1, a keypress happens
	jr $ra

keypress_happened: # check all possible keys
	lw $t8, 4($t9)
	beq $t8, 97, respond_to_a
	beq $t8, 100, respond_to_d
	beq $t8, 119, respond_to_w
	beq $t8, 115, respond_to_s
	beq $t8, 113, respond_to_q
	jr $ra
	
respond_to_a:
	lb $t1, carX
	addi $t1, $t1, -1
	sb $t1, carX
	jr $ra

respond_to_d:
	lb $t1, carX
	addi $t1, $t1, 1
	sb $t1, carX
	jr $ra
	
respond_to_w:
	lb $t1, carSpeed
	addi $t1, $t1, 1
	sb $t1, carSpeed
	jr $ra
	
respond_to_s:
	lb $t1, carSpeed
	addi $t1, $t1, -1
	sb $t1, carSpeed
	jr $ra
	
respond_to_q:
	j initialize
	
updateCarLocation:
	lb $t1, carY
	lb $t2, carSpeed
	mul $t2, $t2, -1
	add $t1, $t1, $t2
	sb $t1, carY
	jr $ra
	
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




exit:  
li $v0, 10 # terminate the program  
syscall  
