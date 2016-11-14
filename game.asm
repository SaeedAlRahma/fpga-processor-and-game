.text
main:
add $r0, $r0, $r0
initializeRegisters:
addi $r1, $r0, 1
addi $r4, $r0, 4
addi $r7, $r0, 7
addi $r8, $r0, 8
addi $r9, $r0, 9
sll $r20, $r1, 20 #for button timer
sll $r19, $r1, 19
initializeMemory:#first store number 8 in enemy columns data to signify inactive rows
sw $r8, 0($r0)
sw $r8, 1($r0)
sw $r8, 2($r0)
sw $r8, 3($r0)
sw $r8, 4($r0)
sw $r8, 5($r0)
sw $r8, 6($r0)
sw $r8, 7($r0)
addi $r3, $r0, 3
sw $r3, 20($r0)
sw $r3, -4($r0)
sll $r8, $r1, 18 #for speed up
initializeButtonCheckTimer:
add $r21, $r20, $r19 #r21 = 2^20 + 2^19. Game stalls for 3*r21 cycles after button press
initializeGameCycleTimer:
sll $r23, $r1, 20 #r23 = 2^20
initializeVGA:j sendDataToVGA
movePlayerLoop:
checkLeft: bne $r29, $r1, checkRight
clearLeftBtn: add $r29, $r0, $r0
lw $r10, 20($r0)
blt $r10, $r1, noMoveLeft
moveLeft:
addi $r10, $r10, -1
sw $r10, -4($r0)
sw $r10, 20($r0)
noMoveLeft: j buttonStall
checkRight: bne $r30, $r1, endButtonCheck
clearRightBtn:add $r30, $r0, $r0
lw $r10, 20($r0)
blt $r10, $r7, moveRight
j buttonStall
moveRight:
addi $r10, $r10, 1
sw $r10, -4($r0)
sw $r10, 20($r0)
buttonStall: blt $r21, $r22, endButtonStall
addi $r22, $r22, 1
j buttonStall
endButtonStall:
add $r24, $r24, $r20
add $r24, $r24, $r19
endButtonCheck:
addi $r22, $r0, 0
add $r29, $r0, $r0
add $r30, $r0, $r0
gameCycleCheck:
blt $r23, $r24, gameCycle
addi $r24, $r24, 1
j movePlayerLoop
gameCycle:
addi $r24, $r0, 0 #reset gamecycle timer
#Move enemy 1 down a row
lw $r11, 1($r0)
sw $r11, 0($r0)
lw $r12, 11($r0)
sw $r12, 10($r0)
#Move enemy 2 down a row
lw $r11, 2($r0)
sw $r11, 1($r0)
lw $r12, 12($r0)
sw $r12, 11($r0)
#Move enemy 3 down a row
lw $r11, 3($r0)
sw $r11, 2($r0)
lw $r12, 13($r0)
sw $r12, 12($r0)
#Move enemy 4 down a row
lw $r11, 4($r0)
sw $r11, 3($r0)
lw $r12, 14($r0)
sw $r12, 13($r0)
#Move enemy 5 down a row
lw $r11, 5($r0)
sw $r11, 4($r0)
lw $r12, 15($r0)
sw $r12, 14($r0)
#Move enemy 6 down a row
lw $r11, 6($r0)
sw $r11, 5($r0)
lw $r12, 16($r0)
sw $r12, 15($r0)
#Move enemy 7 down a row
lw $r11, 7($r0)
sw $r11, 6($r0)
lw $r12, 17($r0)
sw $r12, 16($r0)
#Retrieve random number for col/color, save to enemy 7
setx 0
sw $r27, 7($r0)
setx 0
sw $r27, 17($r0)
#Collision detection $r13 = player col, $r14 = enemy0col, $r15 enemy0color
lw $r13, 20($r0)
lw $r14, 0($r0)
bne $r13, $r14, endOfCollisionDetection
Collision:
lw $r15, 10($r0)
blt $r15, $r4, goodCollision
j badCollision
goodCollision:
addi $r5, $r5, 1
addi $r18, $r18 ,-1 # speed up counter (speed up when it gets to -5)
blt $r5, $r1, goodNeg
bne $r6, $r9, onesDigitAddPos
tenthsDigitAddPos:
addi $r2, $r2, 1
add $r6, $r0, $r0
j endOfCollisionDetection
onesDigitAddPos:
addi $r6, $r6, 1
j endOfCollisionDetection
goodNeg:
bne $r6, $r0, onesDigitAddNeg
tenthsDigitAddNeg:
addi $r2, $r2, -1
addi $r6, $r0, 9
j endOfCollisionDetection
onesDigitAddNeg:
addi $r6, $r6, -1
j endOfCollisionDetection
badCollision:
addi $r5, $r5, -1
blt $r5, $r0, badNeg
bne $r6, $r0, onesDigitSubPos
tenthsDigitSubPos:
addi $r2, $r2, -1
addi $r6, $r0, 9
j endOfCollisionDetection
onesDigitSubPos:
addi $r6, $r6, -1
j endOfCollisionDetection
badNeg:
bne $r6, $r9, onesDigitSubNeg
tenthsDigitSubNeg:
addi $r2, $r2, 1
addi $r6, $r0, 0
j endOfCollisionDetection
onesDigitSubNeg:
addi $r6, $r6, 1
endOfCollisionDetection:
updateScore:
sw $r6, -6($r0)
sw $r2, -7($r0)
sw $r5, -8($r0)
sw $r5, -9($r0)
checkEnd:
addi $r16, $r0, 49
blt $r16, $r5, gameWon
addi $r16, $r0, -49
blt $r5, $r16, gameLost
addi $r16, $r0, -4
blt $r18, $r16, speedUp
j sendDataToVGA
speedUp:
blt $r7, $r17, noSpeedUp # only speed up 7 times
sll $r3, $r1, 15
sub $r23, $r23, $r3 # subtract from gamecycle timer, effectively speeding up game
sll $r8, $r8, 3
add $r20, $r20, $r8 # add to amount that we compensate for button stalls
addi $r18, $r0, 0 #reset green enemy counter to determine if we should speed up
addi $r17, $r17, 1 #keep track of # times we’ve sped up
noSpeedUp:
sendDataToVGA:
#put row 1 into r15 (one hot), update output row register (WE)
sll $r15, $r1, 1
sw $r15, -1($r0)
#Put col 0 into r15, update hardware column register
lw $r15, 1($r0)
sw $r15, -2($r0)
#Put color 0 into r15, update hardware color register
lw $r15, 11($r0)
sw $r15, -3($r0)
#Repeat for rows 2 to 7
sll $r15, $r1, 2
sw $r15, -1($r0)
lw $r15, 2($r0)
sw $r15, -2($r0)
lw $r15, 12($r0)
sw $r15, -3($r0)
sll $r15, $r1, 3
sw $r15, -1($r0)
lw $r15, 3($r0)
sw $r15, -2($r0)
lw $r15, 13($r0)
sw $r15, -3($r0)
sll $r15, $r1, 4
sw $r15, -1($r0)
lw $r15, 4($r0)
sw $r15, -2($r0)
lw $r15, 14($r0)
sw $r15, -3($r0)
sll $r15, $r1, 5
sw $r15, -1($r0)
lw $r15, 5($r0)
sw $r15, -2($r0)
lw $r15, 15($r0)
sw $r15, -3($r0)
sll $r15, $r1, 6
sw $r15, -1($r0)
lw $r15, 6($r0)
sw $r15, -2($r0)
lw $r15, 16($r0)
sw $r15, -3($r0)
sll $r15, $r1,7
sw $r15, -1($r0)
lw $r15, 7($r0)
sw $r15, -2($r0)
lw $r15, 17($r0)
sw $r15, -3($r0)
#update VGA
sw $r0, -5($r0)
endOfGameCycle:
j movePlayerLoop # return to continuously checking for user input
gameWon:
gameLost:
quit: halt
.data
