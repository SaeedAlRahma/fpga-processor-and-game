# fpga-processor-and-game
Simple 5-stage pipeline processor designed in Verilog and an assembly game program to run on it

## Processor
The processor is a 5-stage pipeline that runs at 50 MHz. We implemented an arcade game
that takes 2 buttons on the FPGA as inputs and displays output on a 1280x1024 VGA display.

## Game
The game consists of an 8x8 grid with a player at the bottom grid. The goal of the game is to
collect the falling green blocks while avoiding the falling red blocks. The player can only move
left and right and the blocks fall 1 row at a time at a fixed interval. The blocks remain at their
starting column and color during their fall. A new block of a random color and at a random
column is introduced at the top row each game cycle. A game cycle is a fixed interval prebuilt
in the game design. Catching a green block is +1 while catching a red block is -1
to the total score. The score is displayed on the seven segment displays. There is no penalty for missing
blocks. After every 5 green blocks caught, the game speeds up regardless of current score
(so REALLY avoid the red blocks!). After 7 speed ups, the game no longer speeds up
(reaches maximum speed). The game is won when the score reaches 50. The game is lost
when the score reaches -50.
When the game ends, the display freezes.

## Design
### Input:
Key[0] for move player right
Key[1] for move player left
Key[3] for reset (hardware)
### Output
1280x1024 @60 Hz VGA. VGA output is updated using sw to negative addresses (most
significant bit is 1) as explained below.
### Processor Hardware Additions:
#### VGA:
The VGA consists of a VGA controller and image generator described below. Sixteen extra
32bit
registers and sixteen D-Flip
Flops were initialized in the processor and used to save the
positions and colors of each block (or player) in a row. Eight registers were connected to eight
registers in series for position. Likewise, eight DFF were connected in series for color. The
first eight registers update the positions (and eight DFF update the colors) of each block one
at a time. Once all registers (and DFFs) have been updated, all blocks’ positions and colors
are written to another set of registers (and DFFs). The outputs of the second set of registers
(and DFFs) were directly wired to the VGA. The reasoning behind using 2 sets of registers
was because we can only update and write one register (position) at a time, but we only
wanted to update the display when all data is ready and updated (See figure 1 in the appendix
for a block diagram).
##### VGA Controller:
The VGA Controller takes the clock, reset, all enemies and player positions and colors as
input and outputs the timing required for a 1280x1024 display as well as the RGB colors to
display. The 50 MHz clock input is passed for a PLL megafunctions to produce the required
108 MHz clock for the VGA. The VGA displays pixels from top to bottom and left to right. The
VGA output must turn off (blank) at the end of each line (left to right) and after the last line
(top to bottom). The number of pixels were used to configure and find the correct timing for
the VGA as demanded by a 1280x1024 @ 60Hz display. The VGA Controller passes the
enemy positions and pixel position to image generator to display the image.
##### Image Generator:
The image generator displays a fixed 8x8 grid. This module takes in the current pixel and all
positions and colors as input and returns the pixel’s RGB values. The module uses behavioral
verilog to assign the appropriate pixel boundaries for each position, and the correct color for
each color bit. The code consists of initializing and setting up all variables for pixel
boundaries, and then multiple if/else if/else statements are used to decide what color is used
for the current pixel.
#### Buttons:
Two buttons were added to the processor as inputs. These two buttons (Key[0] and Key[1])
were connected to registers $r29 and $r30 respectively. When a button is pressed, a “1” is
stored in the respective register. We constantly check for button clicks by reading and
comparing the register to zero (bne instruction).
#### HEX display:
To output to the seven segment displays, we kept track of the tens and ones digit in addition
to the total score. We send the tens digit value to one seven segment display, the ones digit
value to another, and the 31st bit of the total score to turn the 3rd seven segment displays
middle segment on or off (to represent negative or positive). Keeping track of this made our
update score assembly code more complicated, but saved us work in hardware. There were 4
interesting cases where we had to do something different than just add 1 or add -1
to ones
digit: add 1 to + number with 9 in ones place, add -1
to + number with 0 in ones place, add 1
to - number
with 0 in ones place, and add -1
to - number
with 9 in ones place.
### Processor Hardware Modifications:
#### Registers:
* Register 29: assigned for left button click (Key[1] on FPGA)
  * $r29 stores 1 anytime Key[0] is clicked
  * otherwise functions normally
  * control enable for $r29 = old we | left_button_clicked
  * write data for $r29 = old data | left_button (if left_button_clicked)
* Register 30: assigned for right button click (Key[0] on FPGA)
  * $r30 stores 1 anytime Key[1] is clicked
  * otherwise functions normally
  * control enable for $r30 = old we | right_button_clicked
  * write data for $r30 = old data | right_button (if right_button_clicked)
 
#### setx (4bit
LFSR random number generator):
setx was modified to save the current value of a random number generator that was added to
the processor. The random number generator uses a 4bit
Linear Feedback Shift Register
(LFSR) with external feedback (next[0] = ~(present[3]^present[2])), while all other next bits are
shifted present DFF values. A 3bit
bus is wired to the 3 least significant bits of the random
number generator so that we only get values between 0 and 7 (representing columns). The
LFSR follows a sequence of length 16 and changes the current random number on every
clock cycle. The present value of the LFSR is stored in register 27 (in writeback stage) when
setx is called. setx is used as a random number generator.
#### Output (sw to a negative number):
The instruction sw was modified so that when a sw instruction on a negative number was
called, the instruction will have different functionality. We decided to use this approach
because we do not need large memory space for our game and it is simpler to implement
than adding a completely new instruction. Here is a brief explanation to what sw to negative
numbers does:
* sw -1($r0): update a write enable register used for enemy position update (row)
* sw -2($r0): update enemy column registers
* sw -3($r0): update enemy color registers
* sw -4($r0): update player column
* sw -5($r0): update VGA (actual output)
* sw -6($r0): update 1s digits register
* sw -7($r0): update 10s digit register
* sw -8($r0): update pos/neg register
* sw -9($r0): update scoreboard (actual output)

It takes multiple instructions to update the column and color data for every row of the game.
Because of this, we couldn’t just have one sw instruction that updated the output VGA display.
Instead, we send the column and color data one row at a time, then actually update the VGA
display with a final sw -5
instruction. Also, instead of having separate sw instructions for each
column and color for each row, we have one store word instruction for column, one for color,
and one for a write enable register. We send a one hot encoding of the row to this 8 bit write
enable register, then use those bits as the write enables to the column and color registers (i.e.
column0we = 8bitWERegister[0] & sw -2,
column1we = 8bitWERegister[1] & sw -2,
etc)(color
is similar but with sw -3
instead of sw -3).
In our assembly code, we update the row to the 8
bit we register, then send the column and color data for that row. We repeat that for all the
rows, and then finally update the VGA display with sw -5.
We did something similar with the scoreboard output. We added registers to store the tens
digit, the ones digit, and negative or positive bit. The outputs of these registers get sent to
another register, with a write enable that is only active on sw -9.
The output of this register
gets sent to the actual LEDs on the seven segment displays. In this way, the scoreboard will
be updated at once instead of ones, then tens, then negative separately.
### Game Logic (Assembly)
Variables:

Register 1 was set to value 1 and used as a constant 1 throughout the assembly code.

Register 2 was used to store the tens digit of the total score.

Register 5 was used to store the total score of the running game.

Register 6 was used to store the ones digit of the total score.

Register 7 was set to value 7 and used as a constant 7 throughout the assembly code.

Register 8 was set to value 8 and used as a constant 8 throughout the assembly code.

Register 9 was set to value 9 and used as a constant 9 throughout the assembly code.

Register 17 was used to stall when button is clicked (to avoid multiple button clicks)

Registers 21, 22 were used for the button stall timer.

Register 23, 24 were used for the game cycle timer.

Register 27 was updated with the random number from the lfsr.

Register 29 was used for button left.

Register 30 was used for button right.

### Game Assembly Code Logic (general layout):
#### Initialization
Initialize certain registers with constants
  - some used for easy comparison, others for timers
  
Initialize column data to 8 in memory (8 = off the board = no enemies)
  - otherwise, the game would start with green enemies all in column 0
  
Initialize player position to column 3

Update VGA display
#### Gameplay code (move player loop):
Continuously check for input

If button pressed, move player
  - store player column in memory and update VGA
  - after button is pressed, stall using the button timer, so that player only moves
one column per press
  - update game cycle timer with lost time from stall
  
When game cycle timer ends, do gamecycle code and reset timer
#### Gamecycle code
Move enemies down
  - series of loads and stores, moving col/color 6 (row 6) to col/color 5 (row 5) data
address, 5 to 4, …, 2 to 0
  - generate 2 random number using setx, use 1 of them for col 7, other for color 7
  
Update Score (Collision detection + scoreboard output)
  - if col 0 = player col, → collision
  - if color0 = 0, add 1 to score. if color0 = 1, add -1 to score
  - also update ones digit and tens digit registers accordingly
  - update scoreboard
  
Check if it’s time to speed up
  - speed up every 5 greens collected, up to maximum of 7 times
  - speed up by updating the value of the register that we use for our game cycle
timer, and adjust the amount we compensate this timer when we stall for a button press

Update VGA

Repeat Gameplay code
#### Data
We reserved certain data addresses to hold the data for the column/color in each row
(that way, we didn’t have to store the row data, we just knew, for example, that the data in
data address 0 corresponded to the column # of the enemy in row 0).

variable : data address

enemy0col: 0

enemy1col: 1

enemy2col: 2

enemy3col: 3

enemy4col: 4

enemy5col: 5

enemy6col: 6

enemy7col: 7

enemy0color: 10

enemy1color: 11

enemy2color: 12

enemy3color: 13

enemy4color: 14

enemy5color: 15

enemy6color: 16

enemy7color: 17

playerCol: 20
