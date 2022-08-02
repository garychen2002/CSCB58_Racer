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
defaultScore: .byte 0
score: .byte 0


enemyCars: .space 16 #array of struct: current x, y positions, speed, direction (up/down)
enemyLength: .byte 2 # set to 4 if Hard Mode
# enemyCar struct: byte currentX, byte currentY, byte speed, byte direction (1/-1) (down/up) (decide on spawn?)
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
	lb $t0, defaultScore
	sb $t0, score
	jal initializeEnemyCars
	j greyPrep

initializeEnemyCars:
	# default enemy cars: one left, one right
	la $t0, enemyCars
	li $t1, 2 # x=2
	sb $t1, 0($t0) #save into struct 
	li $t1, 0 # y=0
	sb $t1, 1($t0)
	li $t1, 1 #speed=1
	sb $t1, 2($t0)
	li $t1, 1 #direction=1 (down)
	sb $t1, 3($t0)
	# right car
	li $t1, 26 # x=24
	sb $t1, 4($t0) #save into struct 
	li $t1, 28 #y=28
	sb $t1, 5($t0)
	li $t1, 1 #speed=1
	sb $t1, 6($t0)
	li $t1, -1 #direction=-1(up)
	sb $t1, 7($t0)
	
	# add more for hard mode
	
	jr $ra


greyPrep: # only once at start
	add $a2, $gp, $zero
	add $t3, $zero, $zero # loop incrementer
	lw $t0, displayAddress    # $t0 stores the base address for display  
	lw $t1, grey
	lw $t2, displayAddress
greyLoop:
	beq $t3, 1024, mainLoop
	sw $t1, 0($t2)
	addi $t2, $t2, 4
	addi $t3, $t3, 1
	j greyLoop


mainLoop:
	jal checkInput
	jal updateCarLocationVertical
	jal updateEnemyCars
	jal drawScreen
	jal sleep1
	j mainLoop

sleep1: 
	li $v0, 32
	li $a0, 50 #sleep for 50ms = 20fps
	syscall
	jr $ra


drawScreen:

	lw $t0, displayAddress    # $t0 stores the base address for display  
	lw $t2, displayAddress #$t2 to store current area to draw to
	j yellowPrep
	
	# test to draw some yellow road strips
yellowPrep:
	li $t3, 0
	addi $t2, $t0, 56 #around middle
	lw $t1, yellow
	lw $t5, grey
yellowLoop:
	beq $t3, 32, whitePrep
	# redraw if grey trailed

	lw $t4, 0($t2)
	bne $t4, $t5, yellowLoop2 #do not redraw if not grey
	#drawPixel
	sw $t1, 0($t2)
yellowLoop2:
	addi $t2, $t2, 8 # prepare second strip to the right
	lw $t4, 0($t2)
	bne $t4, $t5, yellowLoopIncrement #do not redraw if not grey
	#drawPixel
	sw $t1, 0($t2)
yellowLoopIncrement:
	addi $t2, $t2, 120 #new row
	addi $t3, $t3, 1
	j yellowLoop

whitePrep:
	li $t3, 0
	lw $t1, white
	addi $t2, $t0, 28 #around the middle
	lw $t5, grey
whiteLoop:
	beq $t3, 32, drawEnemyCarPrep
	# redraw grey trails
	lw $t4, 0($t2)
	bne $t4, $t5, whiteLoop2
	#drawPixel
	sw $t1, 0($t2)
whiteLoop2:
	addi $t2, $t2, 64 # second half
	lw $t4, 0($t2)
	bne $t4, $t5, whiteLoopIncrement
	#drawPixel
	sw $t1, 0($t2)
whiteLoopIncrement:
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
	
	
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal drawPlayer
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4
	j drawEnemyCarPrep

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
	jr $ra
	
getEnemyAddress:
	# pass in x, y from stack pointer
	# obliterates t4, t5, t2
	lb $t5, 0($sp) # t4 gets X
	lb $t4, 4($sp) # t5 gets Y
	addi $sp, $sp, 8
	mul $t4, $t4, 4 # need to multiply 4 for each pixel address
	add $t2, $gp, $t4
	mul $t5, $t5, 4
	mul $t5, $t5, 32 #multiply by 32 for a new row
	add $t2, $t2, $t5
	addi $sp, $sp, -4
	sw $t2, 0($sp) #save enemy address to stack

	jr $ra

	
drawEnemyCarPrep:
	lw $t1, red

	lb $t3, enemyLength
	li $t8, 0 # loop incrementer
	li $t6, 0 # loop +4 for each car
	la $t7, enemyCars
drawEnemyCarLoop:
	beq $t3, $t8, drawLivesPrep
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	
	addi $sp, $sp, -4 #saving 1 byte to stack
	lb $t4, enemyCars($t6) # enemy car X store in t4
	sb $t4, 0($sp)
	addi $sp, $sp, -4
	lb $t4, enemyCars+1($t6) # enemy car Y store in t4
	sb $t4, 0($sp)
	
	jal getEnemyAddress
	
	lw $t2, 0($sp) # get enemy address from stack
	lw $ra, 4($sp) # get old return address from stack
	addi $sp, $sp, 8
	
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal drawEnemyCar
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4
	
	addi $t8, $t8, 1
	addi $t2, $t2, 4
	addi $t6, $t6, 4
	j drawEnemyCarLoop
	
	
drawEnemyCar:
	# drawing a 3x4 rectangle guy
	# assumption: $t1 has colour, $t2 has the player's calculated address onscreen
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
	jr $ra

drawLivesPrep:
	lw $t1, green
	# draw lives starting in the bottom left
	add $t2, $gp, 0 #t2 = address
	li $t4, 30 #row 30 (second last)
	mul $t4, $t4, 128 
	add $t2, $t2, $t4

	lb $t3, carLives
	li $t5, 0 # loop incrementer
	
	j drawLives
drawLives: 
	beq $t5, $t3, drawScorePrep
	sw $t1, 0($t2)
	addi $t2, $t2, 4
	addi $t5, $t5, 1
	j drawLives
	
drawScorePrep:
# bottom row pink bar filling up
	lw $t1, magenta
	add $t2, $gp, 0
	li $t4, 31 # last row
	mul $t4, $t4, 128
	add $t2, $t2, $t4
	
	lb $t3, score
	li $t5, 0
	j drawScoreLoop
drawScoreLoop:
	beq $t5, $t3, drawLoopExit #exit if increment==score
	sw $t1, 0($t2) # draw 1 magenta for each score
	addi $t2, $t2, 4 #increment
	addi $t5, $t5, 1
	j drawScoreLoop
	
drawLoopExit:
	jr $ra
	
undrawScorePrep:
# bottom row undraw the pink
	lw $t1, grey
	add $t2, $gp, 0
	li $t4, 31 # last row
	mul $t4, $t4, 128
	add $t2, $t2, $t4
	
	lb $t3, score
	li $t5, 0
	j undrawScoreLoop
undrawScoreLoop:
	beq $t5, $t3, drawLoopExit #exit if increment==score
	sw $t1, 0($t2) # draw 1 grey for each score
	addi $t2, $t2, 4 #increment
	addi $t5, $t5, 1
	j undrawScoreLoop
	
undrawLifePrep:
	lw $t1, grey
	# draw lives starting in the bottom left
	lb $t3, carLives
	mul $t3, $t3, 4
	add $t2, $gp, $t3 #t2 = address of last life
	li $t4, 30 #row 30
	mul $t4, $t4, 128 
	add $t2, $t2, $t4

	j undrawLife
undrawLife: 
	sw $t1, 0($t2)
	jr $ra
	
playerTrailPrep: #clean up behind us by drawing grey
	lw $t1, grey
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal getPlayerAddress
	lw $t2, 0($sp) # get player address from stack
	lw $ra, 4($sp) # get old return address from stack
	addi $sp, $sp, 8

	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal drawPlayer
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4
	
	jr $ra
	
redrawPlayerPrep: 
	lw $t1, blue
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal getPlayerAddress
	lw $t2, 0($sp) # get player address from stack
	lw $ra, 4($sp) # get old return address from stack
	addi $sp, $sp, 8

	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal drawPlayer
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4
	
	jr $ra
	
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
	
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal redrawPlayerPrep
	lw $ra, 0($sp) # get old return address from stack
	lw $t1, 4($sp)
	addi $sp, $sp, 8
	
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
	
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal redrawPlayerPrep
	lw $ra, 0($sp) # get old return address from stack
	lw $t1, 4($sp)
	addi $sp, $sp, 8
	
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
	lb $t2, carSpeed
	beq $t2, 0, updateCarLocationEnd # dont need to update if not moving
updateCarLocationTrail:
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal playerTrailPrep
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4
	
updateCarLocationValue:
	lb $t1, carY
	lb $t2, carSpeed
	mul $t2, $t2, -1
	add $t1, $t1, $t2
	ble $t1, 0, carCapTop # cap carY at the top of the screen
	bgt $t1, 28, carCapBottom #cap carY at the bottom of the screen
	sb $t1, carY
updateCarLocationRedraw:
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal redrawPlayerPrep
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4
updateCarLocationEnd:
	jr $ra
carCapTop:
	sb $zero, carY
	j updateCarLocationRedraw
	jr $ra
carCapBottom:
	li $t0, 28 # accounting for top of car being 4 pixels
	sb $t0, carY
	j updateCarLocationRedraw
	jr $ra
onCarHit:

subtractLife:
	lb $t0, carLives
	addi $t0, $t0, -1  # subtract from lives
	sb $t0, carLives
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack
	jal undrawLifePrep
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4
	#todo: undraw life
	beq $t0, 0, gameOver
	
resetCarPosition:
	# clean player corpse from screen
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack
	jal playerTrailPrep #clear corpse
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4

	# reset car position
	lb $t0, startingPositionX
	sb $t0, carX
	lb $t0, startingPositionY
	sb $t0, carY
	lb $t0, defaultCarSpeed
	sb $t0, carSpeed
	
	#clean score bar on collision
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack
	jal undrawScorePrep #clear corpse
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4
	
	# reset score
	lb $t0, defaultScore
	sb $t0, score
	

	
	# reset enemy cars? the old ones remain though
	# add invincibility function probably and call it on respawn
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

enemyTrailPrep: #clean up behind us by drawing grey
	lw $t1, grey
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	
	
	addi $sp, $sp, -4 #saving 1 byte to stack + padding
	lb $t4, enemyCars($t6) # enemy car X store in t4
	sb $t4, 0($sp)
	addi $sp, $sp, -4 # padding
	lb $t4, enemyCars+1($t6) # enemy car Y store in t4
	sb $t4, 0($sp)
	
	jal getEnemyAddress # sending enemy car x, y to getEnemyAddress
	lw $t2, 0($sp) # get enemy address from stack
	lw $ra, 4($sp) # get old return address from stack
	addi $sp, $sp, 8

	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal drawEnemyCar
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4
	
	jr $ra
	
redrawEnemyPrep: 
	lw $t1, red
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	
	
	addi $sp, $sp, -4 #saving 1 byte to stack
	lb $t4, enemyCars($t6) # enemy car X store in t4
	sb $t4, 0($sp)
	addi $sp, $sp, -4
	lb $t4, enemyCars+1($t6) # enemy car Y store in t4
	sb $t4, 0($sp)
	
	jal getEnemyAddress # sending enemy car x, y to getEnemyAddress
	lw $t2, 0($sp) # get enemy address from stack
	lw $ra, 4($sp) # get old return address from stack
	addi $sp, $sp, 8

	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal drawEnemyCar
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4
	
	jr $ra

updateEnemyCars:
	lb $t3, enemyLength # number of cars to loop through
	li $t8, 0 # loop incrementer
	li $t6, 0 # loop +4 for each car
	j updateEnemyCarsLoop
	
	# update each car by their y value and direction and speed

updateEnemyCarsLoop:
	beq $t3, $t8, updateEnemyCarsEnd
	lb $t2, enemyCars($t6) # get x value
	lb $t4, enemyCars+1($t6) # get  y value
	lb $t5, enemyCars+2($t6) # get speed
	lb $t7, enemyCars+3($t6) # get direction
	mul $t5, $t5, $t7
	add $t4, $t4, $t5
	
#draw enemy trail grey
updateEnemyCarsTrail:
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	addi $sp, $sp, -4
	sb $t4, 0($sp)
	jal enemyTrailPrep
	lb $t4, 0($sp)
	addi $sp, $sp, 4
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4

updateEnemyCarsY:
	sb $t4, enemyCars+1($t6) # update y value
	blt $t4, -4, updateEnemyCarsOffscreen # disappears 4 off screen
	bgt $t4, 32, updateEnemyCarsOffscreen
	# screen limits
	j updateEnemyCarsRedraw
#TODO: if enemy car goes offscreen, update with a new random location, add 1 to score
updateEnemyCarsOffscreen:
	# increment score for enemy car going offscreen
	lb $t1, score
	addi $t1, $t1, 1
	sb $t1, score
	# randomizer
	li $a1, 29
	li $v0, 42
	li $a0, 0
	syscall #get a random x value from 0 to 32-3 (width) in a0
	move $t2, $a0
	sb $t2, enemyCars($t6)

	li $a1, 2
	li $v0, 42
	li $a0, 0
	syscall #get a random speed value from 1 to 3 (0 to 2, + 1)
	move $t5, $a0
	addi $t5, $t5, 1
	sb $t5, enemyCars+2($t6)
	# if x <= 13, make it a left side downward moving car
	ble $t2, 15, updateEnemyCarsOffscreenLeft
	bge $t2, 16, updateEnemyCarsOffscreenRight
updateEnemyCarsOffscreenLeft: # y should be 0: top to bottom
	li $t4, 0
	sb $t4, enemyCars+1($t6)
	li $t7, 1 #direction 1 for down
	sb $t7, enemyCars+3($t6)
	j updateEnemyCarsRedraw
updateEnemyCarsOffscreenRight: # y should be 32: bottom to top
	li $t4, 32
	sb $t4, enemyCars+1($t6)
	li $t7, -1 #direction 1 for down
	sb $t7, enemyCars+3($t6)
	j updateEnemyCarsRedraw
#redraw enemy
updateEnemyCarsRedraw:
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save old return address to stack 
	jal redrawEnemyPrep
	lw $ra, 0($sp) # get old return address from stack
	addi $sp, $sp, 4
	
#loop increments
updateEnemyCarsIncrement:
	addi $t8, $t8, 1
	addi $t6, $t6, 4
	j updateEnemyCarsLoop


	
updateEnemyCarsEnd:
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

# flickering improvement: undraw the last row/column being moved?


exit:  
li $v0, 10 # terminate the program  
syscall  
