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
# each pixel block is 8 size, 32 blocks per row/column on screen 
playerWidth: .byte 3
playerHeight: .byte 4
# the player is a 3x4 rectangle
red: .word 0xff0000
green: .word 0x00ff00
blue: .word 0x0000ff
blueTrail: .word 0x00004f
yellow: .word 0xffff00
magenta: .word 0xff00ff
cyan: .word 0x00ffff
black: .word 0x000000
white: .word 0xffffff
grey: .word 0x808080

keypressAddress: .word 0xffff0000
# check which key in address 4 after 
wKey: .byte 119
aKey: .byte 97 # 97
sKey: .byte 115
dKey: .byte 100
qKey: .byte 113
xKey: .byte 120

startingPositionX: .byte 16 # middle of screen
startingPositionY: .byte 28 # bottom of screen + 4 pixels for car height

maxCarX: .byte 32
minCarX: .byte 0
maxCarY: .byte 32
minCarY: .byte 0

carX: .byte 0
carY: .byte 0
carSpeed: .byte 1
carLives: .byte 3

defaultCarLives: .byte 3
defaultCarSpeed: .byte 1
maxCarSpeed: .byte 3


enemyCars: .space 16 #array of struct: current x, y positions, speed, direction (up/down)
enemyLength: .byte 2 # set to 4 if Hard Mode
# enemyCar struct: byte currentX, byte currentY, byte speed, byte direction (0/1)
# plan: fill with random cars (direction according to x position) on initialization and keep respawning them?
# plan: have 2 cars on screen for normal mode, updating positions when offscreen, 4 cars for hard mode (faster)

hardMode: .byte 0 # set to 1 if Hard Mode

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


greyPrep: # only once at start
	add $a2, $gp, $zero
	add $t3, $zero, $zero # loop incrementer
	lw $t0, displayAddress    # $t0 stores the base address for display  
	lw $a0, grey
	lw $t2, displayAddress
	move $a1, $t2
greyLoop:
	beq $t3, 1024, mainLoop
	jal drawPixel
	addi $t2, $t2, 4
	move $a1, $t2
	addi $t3, $t3, 1
	j greyLoop




mainLoop:
	jal checkInput
	jal updateCarLocationVertical
	jal drawScreen
	jal sleep1
	j mainLoop

sleep1: 
	li $v0, 32
	li $a0, 50 #sleep for 50ms = 20fps
	syscall
	jr $ra

drawPixel:
	# parameters: colour address (a0), pixel offset (a1)
	sw $a0, 0($a1)
	jr $ra

drawScreen:

	lw $t0, displayAddress    # $t0 stores the base address for display  
	lw $t2, displayAddress #$t2 to store current area to draw to
	j yellowPrep #skip black stage
	
blackPrep: #unused old code
	add $a2, $gp, $zero
	add $t3, $zero, $zero # loop incrementer

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
	lw $t6, red

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
	li $t3, 0
	addi $t2, $t0, 56 #around middle
	lw $t1, yellow

yellowLoop:
	beq $t3, 32, whitePrep
	#drawPixel
	sw $t1, 0($t2)
	addi $t2, $t2, 8 # prepare second strip to the right
	#drawPixel
	sw $t1, 0($t2)
	addi $t2, $t2, 120 #new row
	addi $t3, $t3, 1
	j yellowLoop

whitePrep:
	li $t3, 0
	lw $t1, white
	addi $t2, $t0, 28 #around the middle
whiteLoop:
	beq $t3, 32, playerPrep
	#drawPixel
	sw $t1, 0($t2)
	addi $t2, $t2, 64 # second half
	#drawPixel
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
	lw $ra, 4($sp) # get old return address from stack
	addi $sp, $sp, 8
	j drawPlayer

drawPlayer:
	# drawing a 3x4 rectangle guy
	# assumption from playerPrep: $t1 has colour, $t2 has the player's calculated address onscreen
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2) # first 3 blocks of a row
	sw $t1, 128($t2) #+128 per row
	sw $t1, 132($t2)
	sw $t1, 136($t2)
	sw $t1, 256($t2) #+128 per row
	sw $t1, 260($t2)
	sw $t1, 264($t2)
	sw $t1, 384($t2) #+128 per row
	sw $t1, 388($t2)
	sw $t1, 392($t2)
	
drawLoopExit:
	jr $ra
	
playerTrailPrep: #clean up behind us by drawing grey
	lw $t1, grey
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal getPlayerAddress
	lw $t2, 0($sp) # get player address from stack
	lw $ra, 4($sp) # get old return address from stack
	addi $sp, $sp, 8
	j drawPlayer
	
checkInput:
	lw $t8, keypressAddress
	lw $t8, 0($t8)
	beq $t8, 1, keypress_happened #if the address has 1, a keypress happens
	jr $ra

keypress_happened: # check all possible keys
	lw $t8, keypressAddress
	lw $t8, 4($t8) # the found key is 4 after the keypressAddress
	beq $t8, 97, respond_to_a
	beq $t8, 100, respond_to_d
	beq $t8, 119, respond_to_w
	beq $t8, 115, respond_to_s
	beq $t8, 113, respond_to_q
	beq $t8, 120, respond_to_x
	jr $ra
	
respond_to_a: # left
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal playerTrailPrep
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4
	
	lb $t1, carX
	addi $t1, $t1, -1
	sb $t1, carX
	
	blt $t1, 0, onCarHit
	jr $ra

respond_to_d: # right
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal playerTrailPrep
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4
	
	lb $t1, carX
	addi $t1, $t1, 1
	sb $t1, carX
	
	bgt $t1, 29, onCarHit # Right boundary = 32 - 3 (rectangle width), carX measures top left
	
	jr $ra
	
respond_to_w:	# up
	lb $t1, carSpeed
	addi $t1, $t1, 1
	sb $t1, carSpeed
	jr $ra
	
respond_to_s: #down
	lb $t1, carSpeed
	addi $t1, $t1, -1
	sb $t1, carSpeed
	jr $ra
	
respond_to_q: #reset
	j initialize

respond_to_x: #quit
	j exit
	
updateCarLocationVertical:
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal playerTrailPrep
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4
	lb $t1, carY
	lb $t2, carSpeed
	mul $t2, $t2, -1
	add $t1, $t1, $t2
	ble $t1, 0, carCapTop # cap carY at the top of the screen
	bgt $t1, 28, carCapBottom #cap carY at the bottom of the screen
	sb $t1, carY
	jr $ra
carCapTop:
	sb $zero, carY
	jr $ra
carCapBottom:
	li $t0, 28 # accounting for top of car being 4 pixels
	sb $t0, carY
	jr $ra
onCarHit:
subtractLife:
	lb $t0, carLives
	addi $t0, $t0, -1  # subtract from lives
	sb $t0, carLives
	beq $t0, 0, gameOver
	# todo: if carlives is 0, jump to game over screen
resetCarPosition:
	lb $t0, startingPositionX
	sb $t0, carX
	lb $t0, startingPositionY
	sb $t0, carY
onCarHitEnd:
	jr $ra
	
gameOver:
drawGameOver:
	lw $t0, displayAddress
	lw $t1, black
	li $t3, 0
	move $t2, $t0
gameOverLoop:
gameOverBlackLoop:
	beq $t3, 1024, gameOverLetters # draw background before letters
	sw $t1, 0($t2)
	addi $t2, $t2, 4
	addi $t3, $t3, 1
	j gameOverBlackLoop
gameOverLetters:
	# WIP: for now it just goes to a black screen
gameOverInputHandler: #loop through waiting for input
	lw $t8, keypressAddress
	lw $t8, 0($t8)
	beq $t8, 1, gameOver_keypress_happened #if the address has 1, a keypress happens
	j gameOverInputHandler
gameOver_keypress_happened:
	lw $t8, keypressAddress
	lw $t8, 4($t8) # the found key is 4 after the keypressAddress
	beq $t8, 113, respond_to_q  #can either restart
	beq $t8, 120, respond_to_x # or exit
	j gameOverInputHandler
# plan: draw a black screen, some pixel text saying game over or L or win, then Q to retry or E to exit and have keyboard responses


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
