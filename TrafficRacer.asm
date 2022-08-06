###################################################################### 
# CSCB58 Summer 2022 Project 
# University of Toronto, Scarborough 
# 
# Student Name: GARY CHEN, Student Number: 1007193065, UTorID: chengar6 
# 
# Bitmap Display Configuration: 
# - Unit width in pixels: 8 
# - Unit height in pixels: 8 
# - Display width in pixels: 256 
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
# 
# Basic features that were implemented successfully 
# - Basic feature a/b/c (choose the ones that apply) 
# Implemented a (life counter), b (different cars with different speed), and c (game over screen)
# All basic features implemented
#
# Additional features that were implemented successfully 
# - Additional feature a/b/c (choose the ones that apply) 
# Implemented a (pickups), b (live score bar) and c (hard mode level)
# All additional features implemented
#  
# Link to the video demo 
# - Insert YouTube/MyMedia/other URL here and make sure the video is accessible 
# YouTube Link: https://www.youtube.com/watch?v=LWAQZ2jVJTg
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

startingPositionX: .byte 14 # middle of screen
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
currentColour: .word 0xff0000 # red, can become cyan when invincible
invincible: .byte 1 # 1 if invincible
invincibleCurrentTimer: .byte 0
invincibleTime: .byte 50 # 100 ticks

enemyCars: .space 16 #array of struct: current x, y positions, speed, direction (up/down)
enemyLength: .byte 2 # set to 4 if Hard Mode
hardModeEnemyLength: .byte 4
# enemyCar struct: byte currentX, byte currentY, byte speed, byte direction (1/-1) (down/up) (decide on spawn?)
# plan: fill with random cars (direction according to x position) on initialization and keep respawning them?
# plan: have 2 cars on screen for normal mode, updating positions when offscreen, 4 cars for hard mode (faster)

hardMode: .byte 0 # set to 1 if Hard Mode

extraLifeVisible: .byte 0 # 1 if visible
shieldVisible: .byte 0 # 1 if visible
extraLifeX: .byte 2 # top left
extraLifeY: .byte 2
shieldX: .byte 28 # bottom right
shieldY: .byte 28

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
	li $t0, 1 # invincible
	sb $t0, invincible
	lb $t0, invincibleTime
	sb $t0, invincibleCurrentTimer
	li $t0, 0
	sb $t0, extraLifeVisible
	sb $t0, shieldVisible
	jal initializeEnemyCars
	lb $t0, hardMode
	beq $t0, 1, hardModeInitialize
	j greyPrep
hardModeInitialize:
	lb $t0, hardModeEnemyLength
	sb $t0, enemyLength
	jal initializeEnemyCarsHardMode
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

initializeEnemyCarsHardMode:
	# add more enemy cars: one left, one right
	la $t0, enemyCars
	li $t1, 6 # x
	sb $t1, 8($t0) #save into struct 
	li $t1, 0 # y
	sb $t1, 9($t0)
	li $t1, 2 #speed
	sb $t1, 10($t0)
	li $t1, 1 #direction=1 (down)
	sb $t1, 11($t0)
	# right car
	li $t1, 18 # x
	sb $t1, 12($t0) #save into struct 
	li $t1, 28 #y
	sb $t1, 13($t0)
	li $t1, 2 #speed
	sb $t1, 14($t0)
	li $t1, -1 #direction=-1(up)
	sb $t1, 15($t0)
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
	jal detectEnemyCollision
	jal detectItemCollision
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
	# redraw grey trails only; if not grey, dont draw
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

playerPrep:  # unused now
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
	beq $t5, $t3, drawLifePrep #exit if increment==score
	sw $t1, 0($t2) # draw 1 magenta for each score
	addi $t2, $t2, 4 #increment
	addi $t5, $t5, 1
	j drawScoreLoop
	
drawLifePrep:
	lb $t0, extraLifeVisible
	bne $t0, 1, drawShieldPrep
	lw $t1, green
	add $t2, $gp, 0 #t2 = draw address
	lb $t3, extraLifeX # calculate offsets
	mul $t3, $t3, 4
	lb $t4, extraLifeY
	mul $t4, $t4, 128 # 32*4
	add $t2, $t2, $t3
	add $t2, $t2, $t4
	j drawLife
drawLife: # draw a cross
	sw $t1, 4($t2)
	sw $t1, 128($t2)
	sw $t1, 132($t2)
	sw $t1, 136($t2)
	sw $t1, 260($t2)
	j drawShieldPrep
drawShieldPrep:
	lb $t0, shieldVisible
	bne $t0, 1, drawLoopExit
	lw $t1, cyan
	add $t2, $gp, 0 #t2 = draw address
	lb $t3, shieldX # calculate offsets
	mul $t3, $t3, 4
	lb $t4, shieldY
	mul $t4, $t4, 128 # 32*4
	add $t2, $t2, $t3
	add $t2, $t2, $t4
	j drawShield
drawShield: # draw a shield
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
	sw $t1, 128($t2)
	sw $t1, 132($t2)
	sw $t1, 136($t2)
	sw $t1, 260($t2)
	j drawLoopExit
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
	
undrawLivesPrep:
	lw $t1, grey
	# draw lives starting in the bottom left
	lb $t3, carLives
	mul $t3, $t3, 4
	add $t2, $gp, $t3 #t2 = address of last life
	li $t4, 30 #row 30
	mul $t4, $t4, 128 
	add $t2, $t2, $t4

	j undrawLives
undrawLives: 
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
	lb $t0, invincible
	beq $t0, 0, loadBlue
	beq $t0, 1, loadCyan # draw as cyan if invincible
loadCyan:
	lw $t1, cyan
	j redrawPlayerMain
loadBlue:
	lw $t1, blue
	j redrawPlayerMain	
redrawPlayerMain:
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
	addi $t1, $t1, -1 # move x value
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
	addi $t1, $t1, 1 # move x value
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
	#beq $t2, 0, updateCarLocationEnd # dont need to update if not moving
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
	jal undrawLivesPrep
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
	li $t0, 1 # invincible
	sb $t0, invincible
	lb $t0, invincibleTime
	sb $t0, invincibleCurrentTimer
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
	lw $t1, white
	move $t2, $t0
	addi $t2, $t2, 4 #column 1
	addi $t2, $t2, 2048 # row 16
	# drawing a q
	# top of o part
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
	# columns
	sw $t1, 128($t2)
	sw $t1, 136($t2)
	sw $t1, 256($t2)
	# bottom of o 
	sw $t1, 260($t2)
	sw $t1, 264($t2)
	# lower tail
	sw $t1, 392($t2)
	sw $t1, 520($t2)
	sw $t1, 524($t2)
	# drawing a r
	move $t2, $t0
	addi $t2, $t2, 40 # column 10
	addi $t2, $t2, 2048
	# top horizontal
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
	# vertical part
	sw $t1, 128($t2)
	sw $t1, 256($t2)
	sw $t1, 384($t2)
	sw $t1, 512($t2)
	# drawing e
	move $t2, $t0
	addi $t2, $t2, 56 # column 14
	addi $t2, $t2, 2048
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
	sw $t1, 128($t2)
	sw $t1, 256($t2)
	sw $t1, 260($t2)
	sw $t1, 384($t2)
	sw $t1, 512($t2)
	sw $t1, 516($t2)
	sw $t1, 520($t2)
	# drawing d
	move $t2, $t0
	addi $t2, $t2, 72 # column 18
	addi $t2, $t2, 2048
	# top of d has to be horizontally right
	sw $t1, 8($t2)
	sw $t1, 136($t2)
	sw $t1, 264($t2)
	# the o part of the lower d
	sw $t1, 260($t2)
	sw $t1, 256($t2)
	sw $t1, 384($t2)
	sw $t1, 392($t2)
	sw $t1, 512($t2)
	sw $t1, 516($t2)
	sw $t1, 520($t2)
	# drawing o
	move $t2, $t0
	addi $t2, $t2, 88 # column 22
	addi $t2, $t2, 2048
	# copying o from d
	sw $t1, 264($t2)
	sw $t1, 260($t2)
	sw $t1, 256($t2)
	sw $t1, 384($t2)
	sw $t1, 392($t2)
	sw $t1, 512($t2)
	sw $t1, 516($t2)
	sw $t1, 520($t2)
	# WIP: for now it just goes to a black screen
gameOverInputHandler: #loop through waiting for input
	lw $t8, keypressAddress
	lw $t8, 0($t8)
	beq $t8, 1, gameOver_keypress_happened #if the address has 1, a keypress happens
	jal sleep1
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
	bge $t8, $t3, updateEnemyCarsEnd
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
updateScore:
	# increment score for enemy car going offscreen
	lb $t1, score
	addi $t1, $t1, 1
	sb $t1, score
	beq $t1, 8, updateLife # spawn extra life at 8
	beq $t1, 16, updateShield # spawn shield at 16
	j updateScoreHardMode
updateLife:
	li $t0, 1
	sb $t0, extraLifeVisible
	j updateScoreHardMode
updateShield:
	li $t0, 1
	sb $t0, shieldVisible
	j updateScoreHardMode
updateScoreHardMode:
	lb $t0, hardMode
	beq $t0, 0, hardModeCheck
	bge $t1, 32, skipHardModeCheck
	j updateEnemyCarsRandomize
hardModeCheck:
	bge $t1, 32, hardModeActivate # turn on hard mode at 32 score if on normal mode and reinitialize
	j updateEnemyCarsRandomize
skipHardModeCheck: # cap score at 32 on hard mode or end game with special screen
	li $t1, 32
	sb $t1, score
updateEnemyCarsRandomize:
	# randomizer
	li $a1, 29
	li $v0, 42
	li $a0, 0
	syscall #get a random x value from 0 to 32-3 (width) in a0
	move $t2, $a0
	sb $t2, enemyCars($t6)

	li $a1, 1
	li $v0, 42
	li $a0, 0
	syscall #get a random speed value from 1 to 2 (0 to 1, + 1)
	move $t5, $a0
	addi $t5, $t5, 1
	sb $t5, enemyCars+2($t6)
	# if x <= middle, make it a left side downward moving car
	ble $t2, 14, updateEnemyCarsOffscreenLeft
	bge $t2, 15, updateEnemyCarsOffscreenRight
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
	
hardModeActivate:
	li $t0, 1
	sb $t0, hardMode # set hard mode flag
	j initialize # reinitialize
	
invincibleRemove:
	li $t0, 0
	sb $t0, invincible
	jr $ra
invincibleTimerTick:
	lb $t1, invincibleCurrentTimer
	addiu $t1, $t1, -1 # subtraction unsigned for >128 ticks
	sb $t1, invincibleCurrentTimer
	bleu $t1, 0, invincibleRemove # unsigned check
	jr $ra
detectEnemyCollision:
	lb $t0, invincible
	beq $t0, 1, invincibleTimerTick # do not check for collision if invincible
	lb $t3, enemyLength # number of cars to loop through
	li $t8, 0 # loop incrementer
	li $t6, 0 # loop +4 for each car
	lb $t5, carX # player car X
	lb $t7, carY # player car Y
	j detectEnemyCollisionLoop
detectEnemyCollisionLoop:
	bge $t8, $t3, detectEnemyCollisionEnd
	lb $t2, enemyCars($t6) # get x value
	lb $t4, enemyCars+1($t6) # get  y value
	# car widths: 3, car heights: 4
	# if player Y is within 4 of enemy car and X is within 3 of enemy car 
	# calc absolute value difference
detectEnemyCollisionSubtractX:
	bge $t2, $t5, subtractEnemyPlayerX # enemy > player
	bge $t5, $t2, subtractPlayerEnemyX
subtractEnemyPlayerX:
	sub $t1, $t2, $t5 
	j detectEnemyCollisionSubtractY
subtractPlayerEnemyX:
	sub $t1, $t5, $t2 # x diff
	j detectEnemyCollisionSubtractY
detectEnemyCollisionSubtractY:
	bge $t4, $t7, subtractEnemyPlayerY # enemy > player
	ble $t4, $t7, subtractPlayerEnemyY
subtractEnemyPlayerY:
	sub $t9, $t4, $t7 # y diff
	j detectEnemyCollisionCompare
subtractPlayerEnemyY:
	sub $t9, $t7, $t4
	j detectEnemyCollisionCompare
detectEnemyCollisionCompare:
	# check if x within 3 and y within 4
	bgt $t1, 2, detectEnemyCollisionIncrement 
	bgt $t9, 3, detectEnemyCollisionIncrement
detectEnemyCollisionAct:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal onCarHit
	lw $ra, 0($sp)
	addi $sp, $sp, 4
detectEnemyCollisionIncrement:
	addi $t8, $t8, 1
	addi $t6, $t6, 4
	j detectEnemyCollisionLoop
detectEnemyCollisionEnd:
	jr $ra
	
undrawLifePrep:
	lw $t1, grey
	add $t2, $gp, 0 #t2 = draw address
	lb $t3, extraLifeX # calculate offsets
	mul $t3, $t3, 4
	lb $t4, extraLifeY
	mul $t4, $t4, 128 # 32*4
	add $t2, $t2, $t3
	add $t2, $t2, $t4
	j undrawLife
	
undrawLife: # draw a cross
	sw $t1, 4($t2)
	sw $t1, 128($t2)
	sw $t1, 132($t2)
	sw $t1, 136($t2)
	sw $t1, 260($t2)
	jr $ra
	
undrawShieldPrep:
	lw $t1, grey
	add $t2, $gp, 0 #t2 = draw address
	lb $t3, shieldX # calculate offsets
	mul $t3, $t3, 4
	lb $t4, shieldY
	mul $t4, $t4, 128 # 32*4
	add $t2, $t2, $t3
	add $t2, $t2, $t4
	j undrawShield
undrawShield: # draw a shield
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
	sw $t1, 128($t2)
	sw $t1, 132($t2)
	sw $t1, 136($t2)
	sw $t1, 260($t2)
	jr $ra
	
detectItemCollision:
	lb $t5, carX # player car X
	lb $t7, carY # player car Y
detectLifeCollision:
	lb $t0, extraLifeVisible
	beq $t0, 0, detectShieldCollision # skip if not there
	lb $t2, extraLifeX # get x value
	lb $t4, extraLifeY # get  y value
detectLifeCollisionSubtractX:
	bge $t2, $t5, subtractLifePlayerX # life > player
	bge $t5, $t2, subtractPlayerLifeX
subtractLifePlayerX:
	sub $t1, $t2, $t5 
	j detectLifeCollisionSubtractY
subtractPlayerLifeX:
	sub $t1, $t5, $t2 # x diff
	j detectLifeCollisionSubtractY
detectLifeCollisionSubtractY:
	bge $t4, $t7, subtractLifePlayerY # enemy > player
	ble $t4, $t7, subtractPlayerLifeY
subtractLifePlayerY:
	sub $t9, $t4, $t7 # y diff
	j detectLifeCollisionCompare
subtractPlayerLifeY:
	sub $t9, $t7, $t4
	j detectLifeCollisionCompare
detectLifeCollisionCompare:
	# check if x within boundaries (3x3 cross)
	bgt $t1, 2, detectShieldCollision 
	bgt $t9, 2, detectShieldCollision
	#if not , jump next section
detectLifeCollisionAct:
	lb $t0, carLives
	addi $t0, $t0, 1  # add a life
	sb $t0, carLives
	li $t0, 0
	sb $t0, extraLifeVisible # remove powerup from field
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal undrawLifePrep
	lw $ra, 0($sp)
	addi $sp, $sp, 4


detectShieldCollision:
	lb $t0, shieldVisible
	beq $t0, 0, detectItemCollisionEnd #skip if not there
	lb $t2, shieldX # get x value
	lb $t4, shieldY # get  y value
detectShieldCollisionSubtractX:
	bge $t2, $t5, subtractShieldPlayerX # shield > player
	bge $t5, $t2, subtractPlayerShieldX
subtractShieldPlayerX:
	sub $t1, $t2, $t5 
	j detectShieldCollisionSubtractY
subtractPlayerShieldX:
	sub $t1, $t5, $t2 # x diff
	j detectShieldCollisionSubtractY
detectShieldCollisionSubtractY:
	bge $t4, $t7, subtractShieldPlayerY # enemy > player
	ble $t4, $t7, subtractPlayerShieldY
subtractShieldPlayerY:
	sub $t9, $t4, $t7 # y diff
	j detectShieldCollisionCompare
subtractPlayerShieldY:
	sub $t9, $t7, $t4
	j detectShieldCollisionCompare
detectShieldCollisionCompare:
	# check if x within boundaries (3x3 shield)
	bgt $t1, 2, detectItemCollisionEnd 
	bgt $t9, 2, detectItemCollisionEnd
	# if not, jump next section
detectShieldCollisionAct:
	# turn on invincible flag + timer
	li $t0, 1 # invincible
	sb $t0, invincible
	li $t0, 100 # 100 ticks
	sb $t0, invincibleCurrentTimer
	li $t0, 0
	sb $t0, shieldVisible # remove powerup from field
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal undrawShieldPrep
	lw $ra, 0($sp)
	addi $sp, $sp, 4
detectItemCollisionEnd:
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
