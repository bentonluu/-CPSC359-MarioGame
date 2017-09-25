//Init section
.section    .init

.globl     _start
_start:
    b       main

//Text section
.section        .text

//Initializes everything to be used for the game, which includes the SNES controller, the interrupt table, the JTAG and the frame buffer.
main:
        bl      InstallIntTable                 //Install the interrupt table to be used when an interrupt occurs.

	bl	EnableJTAG                      //Enables JTAG to be used.
	bl	InitFrameBuffer                 //Initializes the frame buffer to draw on screen.

        mov     r0, #9                          //Move immediate value 9 (LATCH GPIO pin number) into argument register r0
        mov     r1, #1                          //Move immediate value 1 (output) into argument register r1
        bl      Init_GPIO                       //Branch and link to the Init_GPIO subroutine

        mov     r0, #10                         //Move immediate value 10 (DATA GPIO pin number) into argument register r0
        mov     r1, #0                          //Move immediate value 0 (input) into argument register r1
        bl      Init_GPIO                       //Branch and link to the Init_GPIO subroutine

        mov     r0, #11                         //Move immediate value 11 (CLOCK GPIO pin number) into argument register r0
        mov     r1, #1                          //Move immediate value 1 (output) into argument register r1
        bl      Init_GPIO                       //Branch and link to the Init_GPIO subroutine

//This is essentially the start screen of the game where the player is able to choose whether they will play or quit the game
.globl startGame
startGame:
        bl      Interrupt             //Calls the interrupt subroutine to perform an interrupt every 30 seconds.

        bl      startScreen           //Draws the start screen for the Mario game.
        mov     r0, #160
        mov     r1, #224
        bl      mushroomSelector      //Draws the muhsroom selector for the start screen of Mario.

        ldr     r9, =gamemode         //Sets the gamemode to be 0 (intro controls).
        ldr     r8, [r9]
        mov     r8, #0
        str     r8, [r9]

        ldr     r9, =worldCounter     //Sets the world counter to be the first level.
        mov     r8, #0
        str     r8, [r9]

        ldr     r9, =marioLives       //Sets Mario's lives to be 3.
        mov     r8, #3
        str     r8, [r9]

        ldr     r9, =killedGoomba     //Sets killedGoomba label to be 0, meaning that the goomba was not killed.
        mov     r8, #0
        str     r8, [r9]

        ldr     r9, =coinCount         //Sets the coin count to 0.
        mov     r8, #0
        str     r8, [r9]

        ldr     r9, =scoreCount        //Sets the score count to 0.
        str     r8, [r9]

        ldr     r9, =coinJustHit       //Reset that the coins have appeared on the screen.
        mov     r8, #0
        str     r8, [r9]
        str     r8, [r9, #4]
        str     r8, [r9, #8]

        ldr     r9, =mysteryBox        //Reset that the coin blocks have been hit.
        str     r8, [r9]
        str     r8, [r9, #4]
        str     r8, [r9, #8]

        ldr     r9, =hitBrick         //Reset that the breakable brick have been hit.
        str     r8, [r9]
        str     r8, [r9, #4]
        str     r8, [r9, #8]

        bl      startNumbers          //Prints the starting values of the score, coins and lives for Mario.
        bl      restart               //Resets the initial position of Mario.

Read_SNES:  //Main SNES subroutine that reads input from controller. Returns the code of a pressed button in a register.
        mov     r10, #0                                  //Register sampling button.

        mov     r0, #1                                //Pass parameter to set latch pin.
        bl      writeLAT                           //Calls Write_Latch subroutine.

        mov     r0, #1                                //Pass parameter to set clock pin.
        bl      writeCLOCK                           //Calls Write_Clock subroutine.

        mov     r0, #12                               //Pass parameter to wait 12 intervals.
        bl      Wait                                  //Calls Wait subroutine.

        mov     r0, #0                                //Pass parameter to clear latch pin.
        bl      writeLAT                           //Calls Write_Latch subroutine.

        mov     r8, #0                               //Set index of loop to be 0.
        b       pulseLoopCond                         //Branches to pulseLoopCond.

pulseLoopBody:  //Reads the input from the controller at the specific pulse.
        mov     r0, #6                                //Pass parameter to wait 6 intervals.
        bl      Wait                                  //Calls Wait subroutine.

        mov     r0, #0                                //Pass parameter to clear clock pin.
        bl      writeCLOCK                           //Calls Write_Clock subroutine.

        mov     r0, #6                                //Pass parameter to wait 6 intervals.
        bl      Wait                                  //Call Wait subroutine.

        bl      readDATA                             //Call readDATA subroutine.

        mov     r4, r0
        lsl     r4, r8                          //Logical shift left input bits by index.
        orr     r10, r4                           //Mask everything out.

        mov     r0, #1                                //Pass parameter to set clock pin.
        bl      writeCLOCK                           //Calls Write_Clock subroutine.

        add     r8, #1                               //Increment index by 1.

pulseLoopCond:  //Pulses 16 times to from SNES controller.
        cmp     r8, #16                              //Loop 16 times to get SNES controller input data.
        blt     pulseLoopBody                         //Branches to pulseLoopBody if the index is less than 16.

//Checks the specific gamemode for Mario, depending on which gamemode is set, specific controls correspond to the gamemode.
checkGS:
        ldr     r9, =gamemode       //Checks if gamemode is 1, if so branches to startMario (Mario controls).
        ldr     r7, [r9]
        cmp     r7, #1
        beq     startMario

        cmp     r7, #2              //Checks if gamemode is 2, if so branches to pause (pause controls).
        beq     pause

        cmp     r7, #3              //Checks if gamemode is 3, if so branches to returnWinLose (win/lose controls).
        beq     returnWinLose

//Branches to the introControl subroutine which contains all the intro controls of Mario and continually branches until the gamemode is switched.
intro:
        mov     r0, r10             //Passes in the buttons pressed on the SNES controller.
        bl      introControl        //Branches to the intro controller.

        ldr     r9, =gamemode       //Sets the gamemode to be the return value from introControl.
        mov     r8, r0
        str     r8, [r9]

        b       Read_SNES           //Branches to Read_SNES.

//This is where the program branches to when the player chooses to start the game
startMario:
		//Checks if Mario is midjump. If not, it branches to right movement check
        ldr     r8, =midjump
        ldr     r9, [r8]
        cmp     r9, #1
        bne     pressRight

		//Checks if the player is pressing the right directional button while Mario is in his jump animation
        ldr     r7, =0x80       //8-th bit (i.e. bit 7) bitmask that checks for a right button press
        tst     r10, r7
        ldr     r8, =arcRight	//If the right button press was indeed pressed, then we save a 1 (true) in the arcRight label
        mov     r9, #1
        streq   r9, [r8]

		//Checks if the player is pressing the left directional button while Mario is in his jump animation
        ldr     r7, =0x40		//7-th bit (i.e. bit 6) bitmask that checks for a left button press
        tst     r10, r7
        ldr     r5, =arcLeft	//If the right button press was indeed pressed, then we save a 1 (true) in the arcLeft label
        mov     r6, #1
        streq   r6, [r5]

        ldr     r9, [r8]        //Checks if either arcRight OR arcLeft is true
        ldr     r6, [r5]
        orr     r9, r6
        ldr     r8, =arcBool	//The boolean result of the OR operation is saved in the arcBool label
        str     r9, [r8]

        b       jumpBody
        .ltorg

//This checks if the player pressed the right directional button
pressRight:
        ldr     r4, =0xFF7F     //Read_SNES result where the right button is pressed (i.e. bit 7 being the only 0, and the rest 1s)
        cmp     r10, r4
        bne     leftPress		//If the Read_SNES result is not what indicated by the hex value above then check for a left button press

        ldr     r9, =marioRight //If the Read_SNES result is indeed the hex value indicated above, then also set the marioRight label to 1 (true)
        ldr     r8, [r9]		//The marioRight label is a part of the gamestate indicating that Mario is currently looking right
        mov     r8, #1
        str     r8, [r9]

        b       rightCond

//start of the loop body for making Mario move 54 pixels to the right
rightBody:
        ldr     r9, =marioX		//check if Mario's right side touching the rightmost side of the screen, if so go to the next level
        ldr     r8, [r9, #4]
        cmp     r8, #1024
        bge     nextLevel

        ldr     r9, =marioY		//check if Mario's feet are touching the 512 y-coordinate (in pixels), if so branch to rightBodyCont
        ldr     r8, [r9, #4]
        cmp     r8, #512
        ble     rightBodyCont

//Checks if Mario is currently in the first level, if so restrict make sure he properly interacts with the obstacles and the monster
rightWorld0:
        ldr     r9, =worldCounter     //Checks if Mario is in the first world, if so branches to drop subroutine which checks if Mario is in the hole boundary.
        ldr     r8, [r9]
        cmp     r8, #0
        bleq    drop

        ldr     r9, =dropBool         //If Mario has fallen into the hole, branches to dropRestart.
        ldr     r8, [r9]
        cmp     r8, #1
        beq     dropRestart

        ldr     r9, =worldCounter     //Checks if Mario is in the first world, if so branches to hitMonster which check if Mario has hit the goomba.
        ldr     r8, [r9]
        cmp     r8, #0
        bleq    hitMonster

        ldr     r9, =hitGoomba        //If Mario has hit the goomba, branches to unHitMonster.
        ldr     r8, [r9]
        cmp     r8, #1
        beq     unHitMonster

//Checks if Mario is currently in the third level, if so restrict make sure he properly interacts with the obstacles (pipe).
rightWorld2:
        ldr     r9, =worldCounter   //Checks if Mario is in the third level, if not branches to rightWorld3.
        ldr     r8, [r9]
        cmp     r8, #2
        bne     rightWorld3

        ldr     r9, =marioX         //Checks if Mario is walking into the first pipe from the left side of the pipe.
        ldr     r8, [r9, #4]
        cmp     r8, #256
        beq     leftPress

        ldr     r9, =marioX         //Checks if Mario is walking into the second pipe from the left side of the pipe.
        ldr     r8, [r9, #4]
        cmp     r8, #640
        beq     leftPress

//Checks if Mario is currently in the final level, if so restrict make sure he properly interacts with the obstacles and monster.
rightWorld3:
        ldr     r9, =worldCounter    //Checks if Mario is in the third level, if not branches to rightBodyCont.
        ldr     r8, [r9]
        cmp     r8, #3
        bne     rightBodyCont

        bl      hitMonster            //Check if Mario has hit the spiky monster.

        ldr     r9, =hitSpiky         //If Mario has hit the spiky monster, branches to unHitMonster.
        ldr     r8, [r9]
        cmp     r8, #1
        beq     unHitMonster

        ldr     r9, =marioX           //If Mario has reached the castle, branch to the win screen.
        ldr     r8, [r9, #4]
        cmp     r8, #704
        beq     winCond

//Takes care of Mario's right movement animation
rightBodyCont:
        ldr     r8, =marioY			//Clear a portion of Mario's left side equal to the amount of pixels he will move to the right (4 pixels)
        ldr     r9, =marioPECE
        ldr     r0, [r9]
        ldr     r1, [r8]
        ldr     r2, [r9, #4]
        ldr     r3, [r8, #4]
        bl      drawBlue

        ldr     r9, =marioPECE		//Update the coordinates of the marioPECE label responsible for clearing his trail upon movement
        ldr     r6, [r9]
        add     r6, #4
        str     r6, [r9]
        ldr     r6, [r9, #4]
        add     r6, #4
        str     r6, [r9, #4]
        ldr     r6, [r9, #8]
        add     r6, #4
        str     r6, [r9, #8]
        ldr     r6, [r9, #12]
        add     r6, #4
        str     r6, [r9, #12]

        ldr     r9, =marioX			//Add 4 pixels to the Mario's x-position coordinates
        ldr     r6, [r9]
        add     r6, #4
        str     r6, [r9]
        ldr     r6, [r9, #4]
        add     r6, #4
        str     r6, [r9, #4]

//This takes care of Mario's collisions with the life mushroom that is generated every 30 seconds via interrupts
contRight_checkMushrommHit:
        ldr     r4, =mushroomOnScreen			//check if the mushroom is currently on the screen
        ldr     r5, [r4]
        cmp     r5, #0
        beq     contRight_checkedMushroomHit	//if it is not on the screen, then continue with Mario's right movement

        ldr     r4, =marioY						//check if Mario's feet is touching the ground. This makes sure Mario doesn't grab a mushroom on the grounds while walking on the boxes/bricks
        ldr     r5, [r4, #4]
        cmp     r5, #704
        bne     contRight_checkedMushroomHit	//if it is not, then continue with Mario's right movement

        ldr     r4, [r9]						//Mario's left side x-coordinate
        ldr     r5, [r9, #4]					//Mario's right side x-coordinate

        ldr     r9, =mushroom_xPos
        ldr     r6, [r9]						//The mushroom's left side x-coordinate
        ldr     r7, [r9, #4]					//The mushroom's right side x-coordinate

        cmp     r5, r6							//If Mario's right side coordinate is greater than or equal to the mushroom's left side coordinate then set r8 to 1 (true), otherwise 0 (false)
        movge   r8, #1
        movlt   r8, #0

        cmp     r4, r7							//If Mario's left side coordinate is less than or equal to the mushroom's right side coordinate then set r9 to 1 (true), otherwise 0 (false)
        movle   r9, #1
        movgt   r9, #0

        tst     r8, r9							//Do an AND operation between r8 and r9, and set flags
        beq     contRight_checkedMushroomHit	//If the result of the AND was 0, then Mario is not currently touching the mushroom, so branch to the continuation of Mario's right movement

        bl      clearPrevMRPos					//Otherwise if Mario is touching the mushroom then clear the mushroom from the screen

        ldr     r8, =mushroomOnScreen			//And set the mushroomOnScreen label to 0 (false)
        mov     r9, #0
        str     r9, [r8]

        bl      updateLives						//Also increase Mario's lives by 1, and update the life counter on the screen

//continuation of Mario's right movement
contRight_checkedMushroomHit:

        ldr     r9, =marioX						//Draw Mario with his increased x-coordinates, moving his image 4 pixels to the right
        ldr     r7, =marioY
        ldr     r0, [r9]
        ldr     r1, [r7]
        ldr     r2, [r9, #4]
        ldr     r3, [r7, #4]
        bl      drawMarioR

        ldr     r9, =moveCounter				//increment the move counter
        ldr     r8, [r9]
        add     r8, #1
        str     r8, [r9]

//This takes care of the dynamic boundary changes in the 2nd level where there are breakable bricks
rightBodyCont2:
        ldr     r4, =worldCounter		//checks if Mario is currently on level 2
        ldr     r5, [r4]
        cmp     r5, #1
        bne     rightCond				//if not then finish an iteration of the right movement loop and branch to rightCond (i.e. condition of the loop)

        ldr     r8, =marioY				//checks if Mario's feet are currently on the mystery block/brick level
        ldr     r9, [r8, #4]
        cmp     r9, #448
        bne     rightCond				//if not then finish an iteration of the right movement loop and branch to rightCond (i.e. condition of the loop)

        ldr     r6, =marioX
        ldr     r7, [r6]				//Mario's left side x-coordinate
        ldr     r8, [r6, #4]			//Mario's right side x-coordinate

        ldr     r4, =hitBrick			//The following code checks if the first brick has been hit, if so Mario will fall upon standing on that brick
        ldr     r5, [r4]
        cmp     r5, #1
        moveq   r10, #576				//if the brick has been hit then r10 is the left side coordinate of the second mystery block
        movne   r10, #512				//if the brick has not been hit then r10 is the left side coordinate of the first brick

        cmp     r7, #320				//compares Mario's left side with the island mystery block's right side. If greater than or equal to then set r9 to true, otherwise false
        movge   r9, #1
        movlt   r9, #0

        cmp     r8, r10					//compares Mario's right side with the r10. If less than or equal to then set r9 to true, otherwise false
        movle   r10, #1
        movgt   r10, #0

        and     r9, r10					//do an AND between r9 and r10, and save the result back to r9

        ldr     r5, [r4, #4]			//The following code checks if the second brick has been hit, if so Mario will fall upon standing on that brick
        cmp     r5, #1
        bne     checkLastBlockHit		//If it has not been hit yet, then check if the last brick has been hit

        cmp     r7, #640				//compares Mario's left side with second brick's right side. If greater than or equal to then set r5 to true, otherwise false
        movge   r5, #1
        movlt   r5, #0

        cmp     r8, #704				//compares Mario's right side with the second brick's left side. If less than or equal to then set r6 to true, otherwise false
        movle   r6, #1
        movgt   r6, #0

        and     r5, r6					//do an AND between r5 and r6, and save the result back to r5
        orr     r9, r5					//do an OR operation between r9 and r5, and save the result back to r9

checkLastBlockHit:						//The following code checks if the third brick has been hit, if so Mario will fall upon standing on that brick
        ldr     r6, [r4, #8]
        cmp     r6, #1
        moveq   r10, #768				//if the brick has been hit then r10 is right side of third mystery block
        movne   r10, #832				//if the brick has not been hit then r10 is right side of the third brick

        cmp     r7, r10					//compares Mario's left side with r10. If greater than or equal to then set r6 to true, otherwise false
        movge   r6, #1
        movlt   r6, #0

        orr     r9, r6					//do an OR operation between r9 and r6, and save the result back to r9

rightBodyCont3:
        cmp     r9, #0
        beq     rightCond				//if r9 is 0 (false), this means Mario is currently should not should fall to ground

        mov     r0, #16					//otherwise, make Mario fall to the ground by doing a branch and link to dropBlockR
        ldr     r9, =marioY
        ldr     r1, [r9]
        add     r2, r1, #16
        bl      dropBlockR
        b       Read_SNES

rightCond:
        ldr     r9, =moveCounter		//compare the moveCounter value to 16, if less than, branch to the right movement body
        ldr     r8, [r9]
        cmp     r8, #16
        blt     rightBody

        ldr     r9, =moveCounter		//set the moveCounter back to zero
        mov     r8, #0
        str     r8, [r9]

        ldr     r9, =worldCounter   //Checks if Mario is the third level, if so branches to movePipeFall which checks to see if Mario is within the pipe boundary and if not within the boundary he will fall.
        ldr     r8, [r9]
        cmp     r8, #2
        mov     r0, #12
        bleq    movePipeFall

//This checks if the player pressed the left directional button
leftPress:
        ldr     r4, =0xFFBF       //Read_SNES result where the left button is pressed.
        cmp     r10, r4
        bne     jump              //If the Read_SNES result is not what indicated by the hex value above then check for a jump button press.

        ldr     r7, =marioRight   //Sets Mario looking left.
        ldr     r8, [r7]
        mov     r8, #0
        str     r8, [r7]

        b       leftCond

//start of the loop body for making Mario move 54 pixels to the left.
leftBody:
        ldr     r9, =worldCounter //Checks if Mario is in the
        ldr     r8, [r9]
        cmp     r8, #0
        bne     leftBound

        ldr     r9, =marioX     //left boundary restriction for world 0
        ldr     r8, [r9]
        cmp     r8, #0
        beq     pressStart

        ldr     r9, =worldCounter     //Checks if Mario is in the first world, if so branches to drop subroutine which checks if Mario is in the hole boundary.
        ldr     r8, [r9]
        cmp     r8, #0
        bleq    drop

        ldr     r9, =dropBool       //Checks if Mario is in the hole, if he is branch to dropRestart.
        ldr     r8, [r9]
        cmp     r8, #1
        beq     dropRestart

        ldr     r9, =worldCounter   //Checks if Mario is in the first world, if so branches to hitMonster which check if Mario has hit the goomba.
        ldr     r8, [r9]
        cmp     r8, #0
        bleq    hitMonster

        ldr     r9, =hitGoomba      //Checks if Mario hit the goomba, if he hit goomba branch to unHitMonster.
        ldr     r8, [r9]
        cmp     r8, #1
        beq     unHitMonster

leftBound:
        ldr     r9, =marioX     //left boundary restriction
        ldr     r8, [r9]
        cmp     r8, #0
        beq     previousLevel

        ldr     r9, =marioY     //Checks if Mario's bottom is less than or equal 512 Y coordination, if so branches to leftBodyCont.
        ldr     r8, [r9, #4]
        cmp     r8, #512
        ble     leftBodyCont

leftWorld2:
        ldr     r9, =worldCounter   //Checks if Mario is in the third level, if not branches to leftWorld3.
        ldr     r8, [r9]
        cmp     r8, #2
        bne     leftWorld3

        ldr     r9, =marioX         //Checks if Mario is walking into the first pipe from the right side of the pipe.
        ldr     r8, [r9, #4]
        cmp     r8, #448
        beq     jump

        ldr     r9, =marioX         //Checks if Mario is walking into the second pipe from the right side of the pipe.
        ldr     r8, [r9, #4]
        cmp     r8, #832
        beq     jump

//Checks if Mario is currently in the final level, if so restrict make sure he properly interacts with the obstacles and monster.
leftWorld3:
        ldr     r9, =worldCounter     //Checks if Mario is in the final level, if not branches to leftBodyCont
        ldr     r8, [r9]
        cmp     r8, #3
        bne     leftBodyCont

        bl      hitMonster            //Checks if Mario hit the spiky monster.

        ldr     r9, =hitSpiky         //If Mario hit the spiky monster, branch to unHitMonster.
        ldr     r8, [r9]
        cmp     r8, #1
        beq     unHitMonster

//Takes care of Mario's left movement animation
leftBodyCont:
        ldr     r8, =marioY           //Clear a portion of Mario's left side equal to the amount of pixels he will move to the right (4 pixels)
        ldr     r9, =marioPECE
        ldr     r0, [r9, #8]
        ldr     r1, [r8]
        ldr     r2, [r9, #12]
        ldr     r3, [r8, #4]
        bl      drawBlue

        ldr     r9, =marioPECE        //Update the coordinates of the marioPECE label responsible for clearing his trail upon movement
        ldr     r6, [r9]
        sub     r6, #4
        str     r6, [r9]
        ldr     r6, [r9, #4]
        sub     r6, #4
        str     r6, [r9, #4]
        ldr     r6, [r9, #8]
        sub     r6, #4
        str     r6, [r9, #8]
        ldr     r6, [r9, #12]
        sub     r6, #4
        str     r6, [r9, #12]

        ldr     r9, =marioX          //Add 4 pixels to the Mario's x-position coordinates
        ldr     r6, [r9]
        sub     r6, #4
        str     r6, [r9]
        ldr     r6, [r9, #4]
        sub     r6, #4
        str     r6, [r9, #4]

//This takes care of Mario's collisions with the life mushroom that is generated every 30 seconds via interrupts
contLeft_checkMushroomHit:
        ldr     r4, =mushroomOnScreen             //check if the mushroom is currently on the screen
        ldr     r5, [r4]
        cmp     r5, #0
        beq     contLeft_checkedMushroomHit       //if it is not on the screen, then continue with Mario's left movement

        ldr     r4, =marioY                       //check if Mario's feet is touching the ground. This makes sure Mario doesn't grab a mushroom on the grounds while walking on the boxes/bricks
        ldr     r5, [r4, #4]
        cmp     r5, #704
        bne     contLeft_checkedMushroomHit

        ldr     r4, [r9]
        ldr     r5, [r9, #4]

        ldr     r9, =mushroom_xPos              //Load the extra life mushroom X coordinates.
        ldr     r6, [r9]
        ldr     r7, [r9, #4]

        cmp     r5, r6                          //If Mario's right side coordinate is greater than or equal to the mushroom's left side coordinate then set r8 to 1 (true), otherwise 0 (false)
        movge   r8, #1
        movlt   r8, #0

        cmp     r4, r7                          //If Mario's left side coordinate is less than or equal to the mushroom's right side coordinate then set r9 to 1 (true), otherwise 0 (false)
        movle   r9, #1
        movgt   r9, #0

        tst     r8, r9
        beq     contLeft_checkedMushroomHit   //If the result of the AND was 0, then Mario is not currently touching the mushroom, so branch to the continuation of Mario's left movement

        bl      clearPrevMRPos                //Otherwise if Mario is touching the mushroom then clear the mushroom from the screen

        ldr     r8, =mushroomOnScreen         //Set mushroomOnScreen label to be 0 (false).
        mov     r9, #0
        str     r9, [r8]

        bl      updateLives                 //Also increase Mario's lives by 1, and update the life counter on the screen

//continuation of Mario's right movement
contLeft_checkedMushroomHit:

        ldr     r9, =marioX                 //Draw Mario with his increased x-coordinates, moving his image 4 pixels to the left
        ldr     r8, =marioY
        ldr     r0, [r9]
        ldr     r1, [r8]
        ldr     r2, [r9, #4]
        ldr     r3, [r8, #4]
        bl      drawMarioL

        ldr     r7, =moveCounter            //increment the move counter
        ldr     r8, [r7]
        add     r8, #1
        str     r8, [r7]

//This takes care of the dynamic boundary changes in the 2nd level where there are breakable bricks
leftBodyCont2:
        ldr     r4, =worldCounter         //checks if Mario is currently on level 2
        ldr     r5, [r4]
        cmp     r5, #1
        bne     leftCond                  //if not then finish an iteration of the left movement loop and branch to leftCond (i.e. condition of the loop)

        ldr     r8, =marioY               //checks if Mario's feet are currently on the mystery block/brick level.
        ldr     r9, [r8, #4]
        cmp     r9, #448
        bne     leftCond                  //if not then finish an iteration of the left movement loop and branch to leftCond (i.e. condition of the loop)

        ldr     r6, =marioX               //Loads Mario's X coordinates.
        ldr     r7, [r6]
        ldr     r8, [r6, #4]

        ldr     r4, =hitBrick             //The following code checks if the first brick has been hit, if so Mario will fall upon standing on that brick
        ldr     r5, [r4]
        cmp     r5, #1
        moveq   r10, #576
        movne   r10, #512

        cmp     r7, #320                  //compares Mario's left side with the island mystery block's right side. If greater than or equal to then set r9 to true, otherwise false
        movge   r9, #1
        movlt   r9, #0

        cmp     r8, r10                   //compares Mario's right side with the r10. If less than or equal to then set r9 to true, otherwise false
        movle   r10, #1
        movgt   r10, #0

        and     r9, r10                   //do an AND between r9 and r10, and save the result back to r9

        cmp     r8, #256                  //The following code checks if the second brick has been hit, if so Mario will fall upon standing on that brick
        movle   r10, #1
        movgt   r10, #0

        orr     r9, r10                   //do an OR operation between r9 and r10, and save the result back to r9

        ldr     r5, [r4, #4]            //The following code checks if the second brick has been hit, if so Mario will fall upon standing on that brick
        cmp     r5, #1
        bne     leftBodyCont3

        cmp     r7, #640                //compares Mario's left side with second brick's left side. If greater than or equal to then set r5 to true, otherwise false
        movge   r5, #1
        movlt   r5, #0

        cmp     r8, #704                //compares Mario's right side with second brick's right side. If greater than or equal to then set r6 to true, otherwise false
        movle   r6, #1
        movgt   r6, #0

        and     r5, r6
        orr     r9, r5                  //do an OR operation between r5 and r6, and save the result back to r9

leftBodyCont3:
        cmp     r9, #0
        beq     leftCond                  //if r9 is 0 (false), this means Mario is currently should not should fall to ground.

        mov     r0, #16                   //otherwise, make Mario fall to the ground by doing a branch and link to dropBlockL.
        ldr     r9, =marioY
        ldr     r1, [r9]
        add     r2, r1, #16
        bl      dropBlockL
        b       Read_SNES
        .ltorg

leftCond:
        ldr     r9, =moveCounter          //compare the moveCounter value to 16, if less than, branch to the left movement body
        ldr     r8, [r9]
        cmp     r8, #16
        blt     leftBody

        ldr     r7, =moveCounter          //Set the moveCounter back to zero.
        mov     r8, #0
        str     r8, [r7]

        ldr     r9, =worldCounter         //Checks if Mario is the third level, if so branches to movePipeFall which checks to see if Mario is within the pipe boundary and if not within the boundary he will fall.
        ldr     r8, [r9]
        cmp     r8, #2
        mov     r0, #12
        bleq    movePipeFall

//checks if the player has pressed the up-directional button
jump:
        ldr     r4, =0xFFFE      //normal jump
        cmp     r10, r4
        beq     jumping

        ldr     r4, =0xFF7E      //arc-right jump
        cmp     r10, r4
        beq     jumping

        ldr     r4, =0xFFBE      //arc-right left
        cmp     r10, r4
        bne     pressStart

//this block is responsible for resetting any labels related to Mario's jump back to their appropriate values
jumping:
        ldr     r8, =midjump		//set midJump to 1 (true)
        mov     r9, #1
        str     r9, [r8]

        ldr     r5, =marioY
        ldr     r6, [r5, #4]		//r6 is Mario's feet y-coordinates

        ldr     r8, =marioPECEjump	//set Mario's vertical clearing coordinates to their starting values
        mov     r9, r6
        str     r9, [r8, #4]		//clears up to Mario's feet
        sub     r9, #16
        str     r9, [r8]			//clear starts from 16 pixels above his feet

        ldr     r8, =arcRight		//set arcRight to 0 (false)
        mov     r9, #0
        str     r9, [r8]

        ldr     r8, =arcLeft		//set arcLeft to 0 (false)
        mov     r9, #0
        str     r9, [r8]

        ldr     r7, =arcCounter 	//set the arcCounter to 0 (this will act as a counter to the number of iterations Mario is arcing right or left in his jump)
        mov     r8, #0
        str     r8, [r7]

        ldr     r7, =arcBool		//set arcBool to 0 (false)
        mov     r8, #0
        str     r8, [r7]

        ldr     r7, =arcX			//set arcX to 0 (this will be Mario's horizontal movement distance while jump-arcing)
        mov     r8, #0
        str     r8, [r7]

        ldr     r7, =gravityCounter	//set the gravityCounter to 0 (this will act as an index counter for the array of integers contained in gravityValCounter)
        mov     r8, #0
        str     r8, [r7]
        b       jumpCond

//check if the gravityCounter is greater or equal to 9, if so go back to Read_SNES to see if Mario will have an arc to his jump
checkJumpArc:
        ldr     r7, =gravityCounter
        ldr     r8, [r7]
        cmp     r8, #9
        bge     Read_SNES

//start of the jump body loop
jumpBody:
        ldr     r9, =worldCounter	//check if the worldCounter is 0, if not then branch to jumpBodyWorld1, otherwise he is currently at the first level
        ldr     r8, [r9]
        cmp     r8, #0
        bne     jumpBodyWorld1

        ldr     r9, =marioX			//check if Mario's left side coordinate is less than or equal to 4, if so then prevent him from arcing left any further
        ldr     r8, [r9]
        cmp     r8, #4
        ble     contJumpLoop

jumpBodyWorld1:
        ldr     r8, =worldCounter       //Check if Mario is in the second level, if not branches to pipeSideCheckJump
        ldr     r9, [r8]
        cmp     r9, #1
        bne     pipeSideCheckJump

mystery:
        ldr     r8, =marioX
        ldr     r9, [r8, #4]	//compares Mario's right side coordinate with 256 x-coordinate (left side of 1st mystery block).
        cmp     r9, #256		//If greater than then set r5 to true, otherwise false. Also, if equal then set r7 to true, otherwise false
        movgt   r5, #1
        movle   r5, #0
        moveq   r7, #1
        movne   r7, #0

        ldr     r9, [r8]
        cmp     r9, #320		//compares Mario's left side coordinate with 320 x-coordinate (right side of 1st mystery block).
        movlt   r6, #1			//If less than then set r6 to true, otherwise false. Also, if equal then set t10 to true, otherwise false
        movge   r6, #0
        moveq   r10, #1
        movne   r10, #0

        tst     r5, r6			//do an AND operation between r5 and r6, and set flags.
        beq     contMystery		//If the result was 0, this means Mario is currently not inside the x-range of the 1st mystery block so branch to contMystery

        ldr     r8, =marioY		//Otherwise, if he is inside the x-range of the 1st mystery block then compare the top of Mario's head with the 516 y-coordinate (bottom of brick).
        ldr     r9, [r8]
        cmp     r9, #516
        beq     fallMystery		//If the top of his head is hitting the bottom of this mystery block then branch to fallMystery

        b       NEXT			//branch to NEXT
        .ltorg

contMystery:  //the following code is responsible for Mario's collisions with the 1st mystery block's sides
        orr     r4, r7, r10		//do an OR operation between r7 and r10 and save the result in r4
        cmp     r4, #0
        beq     brick			//if the result was 0, then mario is currently not hitting either side of the mystery block while arc-jumping so branch to brick

        ldr     r8, =marioY		//Otherwise, if Mario is hitting one of the sides of the mystery brick while arc-jumping then:
        ldr     r9, [r8]

        cmp     r9, #516		//compare the top of Mario's head with the 516 y-coordinate (top of 1st mystery block).
        movle   r5, #1			//If less than or equal to then set r5 to true, otherwise false
        movgt   r5, #0

        ldr     r9, [r8, #4]	//compare the bottom of Mario's feet with the 448 y-coordinate (bottom of 1st mystery block).
        cmp     r9, #448		//If greater than or equal to then set r6 to true, otherwise false
        movge   r6, #1
        movlt   r6, #0

        and     r5, r6          //do an AND operation between r5 and r6, and save the result back to r5. This checks if Mario is currently inside the y-range of the 1st mystery block.

        ldr     r9, =arcRight
        ldr     r8, [r9]

        and     r7, r8          //is Mario arcing right AND hitting the x-coordinate of the left side of the 1st mystery block? Result is saved back to r7

        ldr     r9, =arcLeft
        ldr     r8, [r9]

        and     r10, r8         //is Mario arcing left AND hitting the x-coordinate of the right side of the 1st mystery block? Result is saved back to r10

        orr     r7, r10			//checks if Mario is currently colliding with one of the x-coordinates of the 1st mystery block walls. The boolean result is saved in r7
        tst     r7, r5			//checks if Mario is currently colliding with one of the x-coordinates of the 1st mystery block walls AND is actually within the y-range of said block.
								//If true then Mario is colliding with one of the 1st mystery block walls, and not if false

        bne     contJumpLoop	//if true then branch to contJumpLoop

brick:
        ldr     r8, =marioX
        ldr     r9, [r8, #4]	//compares Mario's right side coordinate with 512 x-coordinate (left side of 1st brick).
        cmp     r9, #512		//If greater than then set r5 to true, otherwise false. Also, if equal then set r7 to true, otherwise false
        movgt   r5, #1
        movle   r5, #0
        moveq   r7, #1
        movne   r7, #0

        sub     r9, #32         //middle of Mario
        cmp     r9, #576		//compares the middle of Mario with the 575 x-coordinate (right side of 1st brick). If less than or equal to then set r6 to true, otherwise false
        movlt   r6, #1
        movge   r6, #0

        tst     r5, r6			//do an AND operation between r5 and r6, and set flags. This checks if Mario is currently inside the x-range of the 1st brick
        beq     contBrick		//if he is not inside the x-range of the 1st brick then branch to contBrick

        ldr     r9, =hitBrick	//otherwise, if he is inside the x-range of the 1st brick then:
        ldr     r8, [r9]		//check if this brick has already been hit
        cmp     r8, #1
        beq     mystery2		//if brick has already been hit, then branch to mystery2

        ldr     r8, =marioY		//if brick has not yet been hit, then compare the top of Mario's head with the 516 y-coordinate (i.e. bottom of 1st brick)
        ldr     r9, [r8]
        cmp     r9, #516
        beq     fallBrick		//if the top of his head is hitting the bottom of this brick then branch to fallBrick

        b       NEXT			//branch to NEXT
        .ltorg

contBrick:	//the following code is responsible for Mario's collisions with the first brick's sides
        ldr     r9, =hitBrick
        ldr     r8, [r9]

        cmp     r8, #0			//check if the 1st brick has been hit
        moveq   r8, #1			//if it has not been hit, set r8 to true, otherwise false
        movne   r8, #0

        tst     r7, r8          //Checks if the 1st brick still exists AND mario is colliding with the x-coordinate of the left side of the 1st brick
        beq     mystery2		//if not then branch to mystery2

        ldr     r8, =marioY
        ldr     r9, [r8]

        cmp     r9, #516		//compare the top of Mario's head with the 516 y-coordinate (top of 1st brick).
        movle   r5, #1			//If less than or equal to then set r5 to true, otherwise false
        movgt   r5, #0

        ldr     r9, [r8, #4]
        cmp     r9, #448		//compare the bottom of Mario's feet with the 448 y-coordinate (bottom of 1st brick).
        movge   r6, #1			//If greater than or equal to then set r6 to true, otherwise false
        movlt   r6, #0

        and     r5, r6         	//do an AND operation between r5 and r6, and save the result back to r5. This checks if Mario is currently inside the y-range of the 1st brick.

        ldr     r9, =arcRight
        ldr     r8, [r9]

        and     r7, r8          //is mario hitting the left side of the 1st brick AND arcing right? Result is saved in r7

        tst     r5, r7			//checks if Mario is currently colliding with the x-coordinate of the left wall of the 1st brick AND is actually within the y-range of said wall.
								//If true then Mario is colliding with the left side of the 1st brick, and not if false

        bne     contJumpLoop	//if true then branch to contJumpLoop

mystery2:
        ldr     r8, =marioX
        ldr     r9, [r8, #4]	//compares Mario's right side with the 576 x-coordinate (left side of 2nd mystery block).
        cmp     r9, #576		//If greater than then set r4 to true, otherwise false. Also, if equal then set r7 to true, otherwise false
        movgt   r4, #1
        movle   r4, #0

        sub     r9, #32			//middle of Mario
        cmp     r9, #576		//compares the middle of Mario with the 576 x-coordinate (left side of the 2nd mystery block)
        movge   r5, #1			//if greater than or equal to then set r5 to true, otherwise false
        movlt   r5, #0

        cmp     r9, #640		//compares the middle of Mario wit the 640 x-coordinate (right side of the 2nd mystery block)
        movle   r6, #1			//if less than or equal to then set r6 to true, otherwise false
        movgt   r6, #0

        ldr     r9, [r8]
        cmp     r9, #640		//compares Mario's left side with the 640 x-coordinate (right side of 2nd mystery block)
        movlt   r7, #1			//if less than then set r7 to true, otherwise false
        movge   r7, #0

        ldr     r8, =hitBrick
        ldr     r9, [r8]		//r9 is the boolean value of the first brick being hit
        ldr     r10, [r8, #4]	//r10 is the boolean value of the second brick being hit

        cmp     r9, #1			//if the first brick has been hit then move the r4 to r9, otherwise move r5 to r9
        moveq   r9, r4			//this takes care of the dynamic boundaries of Mario's interaction with the 2nd mystery block depending on the existence of the first brick
        movne   r9, r5

        cmp     r10, #1			//if the second brick has been hit then move r7 to r10, otherwise move r6 to r10
        moveq   r10, r7			//this takes care of the dynamic boundaries of Mario's interaction with the 2nd mystery block depending on the existence of the 2nd brick
        movne   r10, r6

        tst     r9, r10			//do an AND operation b/t r9 and r10, and save the result in r9. This checks if Mario is inside the x-range of 2nd mystery block
        beq     contMystery2	//if he is not then branch to contMystery2

        ldr     r8, =marioY		//if he is, then compare the top of Mario's head with the 516 y-coordinate (bottom of 2nd mystery block)
        ldr     r9, [r8]
        cmp     r9, #516
        beq     fallMystery2	//if his head is hitting the bottom of this mystery block then branch to fallMystery2

        b       NEXT			//branch to NEXT

contMystery2: //the following code is responsible for Mario's collisions with the 2nd mystery block's sides
        ldr     r8, =marioX
        ldr     r9, [r8, #4]
        cmp     r9, #576		//compares Mario's right side with the 576 x-coordinate (left side of the 2nd mystery block)
        moveq   r5, #1			//if equal to then set r5 to true, otherwise false
        movne   r5, #0

        ldr     r9, [r8]
        cmp     r9, #640		//compares Mario's left side witrh the 640 x-coordinate (right side of the 2nd mystery block)
        moveq   r6, #1			//if equal to then set r6 to true, otherwise false
        movne   r6, #0

        ldr     r8, =hitBrick
        ldr     r7, [r8]		//r7 is the boolean value for the first brick being hit
        ldr     r10, [r8, #4]	//r10 is the boolean value for the second brick being hit

        and     r7, r5			//is Mario hitting the left side of the 2nd mystery block AND is the first brick non-existent? Result is saved back to r7
        and     r10, r6			//is Mario hitting the right side of the 2nd mystery block AND is the second brick non-existent? Result is saved back to r10
        orrs    r7, r10			//Are either of the 2 situations stated directly above true?
        beq     brick2			//if not then branch to brick2

M2_SideBound:
        ldr     r8, =marioY
        ldr     r9, [r8]

        cmp     r9, #516		//compares the top of Mario's head with the 516 y-coordinate (bottom of 2nd mystery block)
        movle   r7, #1			//if less than or equal to then set r7 to true, otherwise false
        movgt   r7, #0

        ldr     r9, [r8, #4]
        cmp     r9, #448		//compares the bottom of Mario's feet with the 448 y-coordinate (top of 2nd mystery block)
        movge   r8, #1			//if greater than or equal to then set r8 to true, otherwise false
        movlt   r8, #0

        and     r7, r8          //Checks if Mario is within the y-range of the box. Result is saved back to r7

        ldr     r9, =arcRight
        ldr     r8, [r9]

        and     r5, r8          //is Mario arcing right AND hitting the left side of the box? Result is saved back to r5

        ldr     r9, =arcLeft
        ldr     r8, [r9]

        and     r6, r8          //is Mario arcing left AND hitting the right side of the box? Result is saved back to r6

        orr     r5, r6			//Are either of the 2 situations stated directly above true? Result is saved in r5
        tst     r7, r5			//Checks if Mario is currently colliding with one of the x-coordinates of the 2nd mystery block walls AND is actually within the y-range of said block.
								//If true then Mario is colliding with one of the mystery block walls, and not if false

        bne     contJumpLoop	//if true then branch to contJumpLoop

brick2:
        ldr     r8, =marioX
        ldr     r9, [r8, #4]
        sub     r9, #32			//middle of mario
        cmp     r9, #640		//compares the middle of Mario with the 640 x-coordinate (left side of the 2nd brick)
        movgt   r5, #1			//if greater than then set r5 to true, otherwise false
        movle   r5, #0

        cmp     r9, #704		//compares the middle of Mario with the 704 x-coordinate (right side of the 2nd brick)
        movlt   r6, #1			//if less than then set r6 to true, otherwise false
        movge   r6, #0

        tst     r5, r6			//checks if Mario is within the x-range of the 2nd brick using his middle position as a the reference point
        beq     mystery3		//if he is not then branch to mystery3

        ldr     r9, =hitBrick	//checks if this brick has been hit, if so then branch to mystery3
        ldr     r8, [r9, #4]
        cmp     r8, #1
        beq     mystery3

        ldr     r8, =marioY		//otherwise, if this brick has not yet been hit, then compare the top of Mario's head with the 516 y-coordinate.
        ldr     r9, [r8]
        cmp     r9, #516
        beq     fallBrick2		//if the top of his head hits the bottom og this brick then branch to fallBrick2

mystery3:
        ldr     r8, =marioX
        ldr     r9, [r8, #4]

        cmp     r9, #704		//compare Mario's right side with the 704 x-coordinate (left side of 3rd mystery block)
        movgt   r4, #1			//if greater than then set r4 to true, otherwise false
        movle   r4, #0

        sub     r9, #32			//middle of Mario
        cmp     r9, #704		//compare the middle of Mario with the 704 x-coordinate (left side of the 3rd mystery block)
        movge   r5, #1			//if greater than or equal to then set r5 to true, otherwise false
        movlt   r5, #0

        cmp     r9, #768		//compare the middle of Mario with the 768 x-coordinate (right side of the 3rd mystery block)
        movle  	r6, #1			//if less than or equal to then set r6 to true, otherwise false
        movgt   r6, #0

        ldr     r9, [r8]		//compare Mario's left side with the 768 x-coordinate (right side of the 3rd mystery block)
        cmp     r9, #768		//if less than or equal to then set r7 to true, otherwise false
        movlt   r7, #1
        movge   r7, #0

        ldr     r8, =hitBrick
        ldr     r9, [r8, #4]	//r9 is the boolean value for the 2nd brick being hit
        ldr     r10, [r8, #8]	//r10 is the boolean value for the 3rd brick being hit

        cmp     r9, #1			//if the 2nd brick has been hit then move r4 to r9, otherwise move r5 to range
        moveq   r9, r4			//this takes care of the dynamic boundaries of Mario's interaction with the 3rd mystery block depending on the existence of the 2nd brick
        movne   r9, r5

        cmp     r10, #1			//if the 3rd brick has been hit then move r7 to r10, otherwise move r6 to r10
        moveq   r10, r7			//this takes care of the dynamic boundaries of Mario's interaction with the 3rd mystery block depending on the existence of the 3rd brick
        movne   r10, r6

        tst     r9, r10			//do an AND operation b/t r9 and r10, and save the result in r9. This checks if Mario is inside the x-range of 3rd mystery block
        beq     contMystery3	//if he is not then branch to contMystery3

        ldr     r8, =marioY		//otherwise, if he inside the x-range of the 3rd mystery block then compare the top of his head with the 516 y-coordinate (bottom of 3rd mystery block).
        ldr     r9, [r8]
        cmp     r9, #516
        beq     fallMystery3	//if the top of his head hits the bottom of this mystery block then branch to fallMystery3

        b       NEXT			//branch to NEXT

contMystery3: //the following code is responsible for Mario's collisions with the 3rd mystery block's sides
        ldr     r8, =marioX
        ldr     r9, [r8, #4]	//compares Mario's right side with the 704 x-coordinate (left side of the 3rd mystery block)
        cmp     r9, #704		//if equal to then set r5 to true, otherwise false
        moveq   r5, #1
        movne   r5, #0

        ldr     r9, [r8]
        cmp     r9, #768		//compares Mario's left side with the 768 x-coordinate (right side of the 3rd mystery block)
        moveq   r6, #1			//if equal to then set r6 to true, otherwise false
        movne   r6, #0

        ldr     r8, =hitBrick
        ldr     r7, [r8, #4]	//r7 is the boolean value for the second brick being hit
        ldr     r10, [r8, #8]	//r10 is the boolean value for the third brick being hit

        and     r7, r5			//is Mario hitting the left side of the 3rd mystery block AND is the second brick non-existent? Result is saved back to r7
        and     r10, r6			//is Mario hitting the right side of the 3rd mystery block AND is the third brick non-existent? Result is saved back to r10
        orrs    r7, r10			//Are either of the 2 situations stated directly above true?
        beq     brick3			//if not then branch to brick2

M3_SideBound:
        ldr     r8, =marioY
        ldr     r9, [r8]

        cmp     r9, #516		//compares the top of Mario's head with the 516 y-coordinate (bottom of 2nd mystery block)
        movle   r7, #1			//if less than or equal to then set r7 to true, otherwise false
        movgt   r7, #0

        ldr     r9, [r8, #4]
        cmp     r9, #448		//compares the bottom of Mario's feet with the 448 y-coordinate (top of 2nd mystery block)
        movge   r8, #1			//if greater than or equal to then set r8 to true, otherwise false
        movlt   r8, #0

        and     r7, r8			//Checks if Mario is within the y-range of the box. Result is saved back to r7

        ldr     r9, =arcRight
        ldr     r8, [r9]

        and     r5, r8          //is Mario arcing right AND hitting the left side of the box? Result is saved back to r5

        ldr     r9, =arcLeft
        ldr     r8, [r9]

        and     r6, r8          //is Mario arcing left AND hitting the right side of the box? Result is saved back to r6

        orr     r5, r6			//Are either of the 2 situations stated directly above true? Result is saved in r5
        tst     r7, r5			//Checks if Mario is currently colliding with one of the x-coordinates of the 3rd mystery block walls AND is actually within the y-range of said block.
								//If true then Mario is colliding with one of the mystery block walls, and not if false

        bne     contJumpLoop	//if true then branch to contJumpLoop

brick3:
        ldr     r8, =marioX
        ldr     r9, [r8]
        cmp     r9, #832		//compares Mario's left side with the 832 x-coordinate (right side of the 3rd brick)
        movlt   r5, #1			//if less than then set r5 to true, otherwise false. Also, if equal set r7 to true, otherwise false
        movge   r5, #0
        moveq   r7, #1
        movne   r7, #0

        add     r9, #32			//middle of Mario
        cmp     r9, #768		//compares the middle of Mario to the 788 x-coordinate (left side of the 3rd brick)
        movgt   r6, #1			//if greater than then set r6 to true, otherwise false
        movle   r6, #0

        tst     r5, r6			//Checks if Mario is currently inside the x-range of the 1st brick
        beq     contBrick3		//if he is not then branch to contBrick3

        ldr     r9, =hitBrick
        ldr     r8, [r9, #8]
        cmp     r8, #1			//checks if the 3rd brick has been hit
        beq     NEXT			//if it has then branch to NEXT

        ldr     r8, =marioY		//otherwise, if the 3rd brick has not been hit then compare the top of Mario's head with the 516 y-coordinate (bottom of 3rd brick)
        ldr     r9, [r8]
        cmp     r9, #516
        beq     fallBrick3		//if the top of Mario's head hits the bottom of this brick then branch to fallBrick3

        b       NEXT			//branch to NEXT

contBrick3: //the following code is responsible for Mario's collisions with the 3rd brick's sides
        ldr     r9, =hitBrick
        ldr     r8, [r9, #8]

        cmp     r8, #0			//check if the 3rd brick has been hit
        moveq   r8, #1			//if it has not been hit, set r8 to true, otherwise false
        movne   r8, #0

        tst     r7, r8          //Checks if the 3rd brick still exists AND mario is colliding with the x-coordinate of the right side of the 3rd brick
        beq     NEXT			//if not then branch to NEXT

        ldr     r8, =marioY
        ldr     r9, [r8]

        cmp     r9, #516		//compare the top of Mario's head with the 516 y-coordinate (top of 3rd brick).
        movle   r5, #1			//If less than or equal to then set r5 to true, otherwise false
        movgt   r5, #0

        ldr     r9, [r8, #4]
        cmp     r9, #448		//compare the bottom of Mario's feet with the 448 y-coordinate (bottom of 3rd brick).
        movge   r6, #1			//If greater than or equal to then set r6 to true, otherwise false
        movlt   r6, #0

        and     r5, r6			//do an AND operation between r5 and r6, and save the result back to r5. This checks if Mario is currently inside the y-range of the 3rd brick.

        ldr     r9, =arcLeft
        ldr     r8, [r9]

        and     r7, r8          //is mario hitting the right side of the 3rd brick AND arcing left? Result is saved in r7

        tst     r5, r7			//checks if Mario is currently colliding with the x-coordinate of the right wall of the 3rd brick AND is actually within the y-range of said wall.
								//If true then Mario is colliding with the right side of the 3rd brick, and not if false

        bne     contJumpLoop	//if true, then branch to contJumpLoop

        b       NEXT			//branch to NEXT

pipeSideCheckJump:
        ldr     r8, =worldCounter   //Checks if Mario is in the third level, if not branches to NEXT.
        ldr     r9, [r8]
        cmp     r9, #2
        bne     NEXT

        ldr     r9, =marioX         //Checks if Mario's front is touching the 256 X coordinate.
        ldr     r8, [r9, #4]
        cmp     r8, #256
        moveq   r5, #1
        movne   r5, #0

        ldr     r9, =marioY         //Checks if Mario's bottom is greater than or equal the 512 Y coordinate.
        ldr     r8, [r9, #4]
        cmp     r8, #512
        movge   r6, #1
        movlt   r6, #0

        tst     r5, r6              //If both Mario is touching the first pipe and is lower than the pipe, branches to contJumpLoop.
        bne     contJumpLoop

        ldr     r9, =marioX         //Checks if Mario's back is touching the 384 X coordinate.
        ldr     r8, [r9]
        cmp     r8, #384
        moveq   r5, #1
        movne   r5, #0

        ldr     r9, =marioY         //Checks if Mario's bottom is greater than or equal the 512 Y coordinate.
        ldr     r8, [r9, #4]
        cmp     r8, #512
        movge   r6, #1
        movlt   r6, #0

        tst     r5, r6              //If both Mario is touching the first pipe and is lower than the pipe, branches to contJumpLoop.
        bne     contJumpLoop

pipe2SideCheckJump:
        ldr     r9, =marioX         //Checks if Mario's front is touching the 640 X coordinate.
        ldr     r8, [r9, #4]
        cmp     r8, #640
        moveq   r5, #1
        movne   r5, #0

        ldr     r9, =marioY         //Checks if Mario's bottom is greater than or equal the 512 Y coordinate.
        ldr     r8, [r9, #4]
        cmp     r8, #512
        movge   r6, #1
        movlt   r6, #0

        tst     r5, r6              //If both Mario is touching the second pipe and is lower than the pipe, branches to contJumpLoop.
        bne     contJumpLoop

        ldr     r9, =marioX         //Checks if Mario's back is touching the 768 X coordinate.
        ldr     r8, [r9]
        cmp     r8, #768
        moveq   r5, #1
        movne   r5, #0

        ldr     r9, =marioY         //Checks if Mario's bottom is greater than or equal the 512 Y coordinate.
        ldr     r8, [r9, #4]
        cmp     r8, #512
        movge   r6, #1
        movlt   r6, #0

        tst     r5, r6              //If both Mario is touching the second pipe and is lower than the pipe, branches to contJumpLoop.
        bne     contJumpLoop

NEXT:
        ldr     r8, =arcBool
        ldr     r9, [r8]
        cmp     r9, #1				//checks the boolean value saved in the arcBool label
        beq     jumpArc				//if true, then this means that Mario has parabolic arc to his jump so branch to jumpArc
        bne     contJumpLoop		//if false, then this means that Mario does not have a parabolic arc to his jump so branch to contJumpLoop

jumpArc:
        ldr     r7, =arcCounter		//the arcCounter takes count of the number of iterations that Mario is arcing to the right/left while jumping
        ldr     r8, [r7]
        add     r8, #1				//increment arcCounter
        str     r8, [r7]

        ldr     r7, =arcX			//arcX is the horizontal distance (in pixels) that Mario moves to the right or left while arcing
        ldr     r8, [r7]

        ldr     r9, =arcRight
        ldr     r10, [r9]
        cmp     r10, #0				//check if Mario is arcing to the right while jumping
        beq     subX_jumpArc		//if not, this means that he is arcing to the left so branch to subX_jumpArc

        mov     r8, #4
        str     r8, [r7]			//therefore since Mario is arcing right, store 4 to arcX

        ldr     r9, =marioPECE		//clear the leftmost 4 pixels of Mario before he is redrawn
        ldr     r8, =marioY
        ldr     r0, [r9]
        ldr     r1, [r8]
        ldr     r2, [r9, #4]
        ldr     r3, [r8, #4]
        bl      drawBlue

        ldr     r9, =marioPECE		//update the x-coordinates for the marioPECE label responsible for the horizontal clearing of Mario when he moves horizontally
        ldr     r6, [r9]			//they will be added 4 pixels since Mario will be 4 pixels to the right the next time he is drawn on the screen
        add     r6, #4
        str     r6, [r9]
        ldr     r6, [r9, #4]
        add     r6, #4
        str     r6, [r9, #4]
        ldr     r6, [r9, #8]
        add     r6, #4
        str     r6, [r9, #8]
        ldr     r6, [r9, #12]
        add     r6, #4
        str     r6, [r9, #12]

        b       contArc				//branch to contArc

subX_jumpArc:	//the following code is when Mario has a left arc in his jump
        mov     r8, #-4
        str     r8, [r7]			//since Mario is arcing left, store -4 to arcX

        ldr     r9, =marioPECE		//clear the rightmost 4 pixels of Mario before he is redrawn
        ldr     r8, =marioY
        ldr     r0, [r9, #8]
        ldr     r1, [r8]
        ldr     r2, [r9, #12]
        ldr     r3, [r8, #4]
        bl      drawBlue

        ldr     r9, =marioPECE		//update the x-coordinates for the marioPECE label responsible for the horizontal clearing of Mario when he moves horizontally
        ldr     r6, [r9]			//they will be subtracted 4 pixels since Mario will be 4 pixels to the left the next time he is drawn
        sub     r6, #4
        str     r6, [r9]
        ldr     r6, [r9, #4]
        sub     r6, #4
        str     r6, [r9, #4]
        ldr     r6, [r9, #8]
        sub     r6, #4
        str     r6, [r9, #8]
        ldr     r6, [r9, #12]
        sub     r6, #4
        str     r6, [r9, #12]

contArc: //the following code simply updates Mario's x-coordinates depending on whether he is arcing left or right before he is redrawn
        ldr     r7, =arcX
        ldr     r8, [r7]		//r8 is the arcX value, or the horizontal distance in pixels Mario will move while jumping

        ldr     r9, =marioX		//update Mario's x-coordinates based on the value of arcX in r8
        ldr     r6, [r9]
        add     r6, r8
        str     r6, [r9]
        ldr     r6, [r9, #4]
        add     r6, r8
        str     r6, [r9, #4]

jumpTransitionFinal:
        ldr     r9, =worldCounter     //Checks if Mario is in the final level, if not branches to jumpTansition.
        ldr     r8, [r9]
        cmp     r8, #3
        bne     jumpTransition

        ldr     r9, =marioX           //Checks if Mario front is touching the X coordinate 704, if so branches to winCond.
        ldr     r8, [r9, #4]
        cmp     r8, #704
        bge     winCond

jumpTransition:
        ldr     r9, =marioX           //Checks if Mario front is touching the rightmost side of the screen, if so branches to the next level.
        ldr     r8, [r9, #4]
        cmp     r8, #1024
        bge     nextLevel

jumpTransitionCont:
        ldr     r9, =marioX           //Checks if Mario back is touching the leftmost side of the screen, if so brancehs to the previous level.
        ldr     r8, [r9]
        cmp     r8, #0
        ble     previousLevel

contJumpLoop:	//the following code is responsible for redrawing Mario in his jumping animation
        ldr     r4, =gravityCounter
        ldr     r5, [r4]

        ldr     r7, =gravityValCounter
        ldr     r10, [r7, r5, LSL #2]		//r10 is the number of pixels Mario goes up by based on gravityValCounter

        add     r5, #1
        ldr     r4, [r7, r5, LSL #2]		//r4 is the number of pixels Mario will go up by in the next iteration of the loop based on gravityValCounter

        push    {r4}						//clear the bottom-most portion of Mario before he is redrawn
        ldr     r8, =marioX
        ldr     r9, =marioPECEjump
        ldr     r0, [r8]
        ldr     r1, [r9]
        ldr     r2, [r8, #4]
        ldr     r3, [r9, #4]
        bl      drawBlue
        pop     {r4}

        ldr     r9, =marioPECEjump		//update the y-coordinates of marioPECEjump which is responsible for the vertical clearing of Mario when he moves vertically
        ldr     r6, [r9, #4]
        sub     r6, r10
        str     r6, [r9, #4]
        sub     r6, r6, r4
        str     r6, [r9]

        ldr     r9, =marioY				//update Mario's y-coordinates based on how much pixels he went up by, which was r10
        ldr     r6, [r9]
        sub     r6, r10
        str     r6, [r9]
        ldr     r6, [r9, #4]
        sub     r6, r10
        str     r6, [r9, #4]

        ldr     r8, =marioY				//set up the parameters for redrawing Mario
        ldr     r9, =marioX
        ldr     r0, [r9]
        ldr     r1, [r8]
        ldr     r2, [r9, #4]
        ldr     r3, [r8, #4]

        ldr     r7, =marioRight 		//check if Mario was looking right when he jumped
        ldr     r8, [r7]
        cmp     r8, #1
        bleq    drawMarioJumpR			//if he was looking right then draw Mario jumping facing right
        blne    drawMarioJumpL			//if he was not looking right then draw Mario jumping facing left

        ldr     r7, =gravityCounter		//increment gravityCounter
        ldr     r8, [r7]
        add     r8, #1
        str     r8, [r7]

jumpCond:	//jump loop condition
        ldr     r7, =gravityCounter		//check if the value contained in gravityCounter is less than 31, if so branch to checkJumpArc
        ldr     r8, [r7]
        cmp     r8, #31
        blt     checkJumpArc

        ldr     r9, =worldCounter		//check the value contained in worldCounter, if it is not equal to 0 (i.e. first level) then branch to jumpCondCont
        ldr     r8, [r9]
        cmp     r8, #0
        bne     jumpCondCont

        ldr     r9, =marioX				//otherwise, if Mario is currently in the first level then if his left side coordinate is less than or equal to 0 then branch to fall
        ldr     r8, [r9]
        cmp     r8, #0
        ble     fall

jumpCondCont:	//the following code is responsible for Mario's slight movement left or right at the top of his jump
        ldr     r9, =arcRight
        ldr     r8, [r9]
        ldr     r9, =arcLeft
        ldr     r10, [r9]

        orrs    r4, r8, r10			//did Mario arc left OR arc right in his jump? Boolean result is stored in r4
        beq     fall				//if false, then branch to fall

        cmp     r8, #1				//if Mario arced right in his jump, then set r10 to 4 and branch to clearLeft_Climax
        moveq   r10, #4
        beq     clearLeft_Climax

        movne   r10, #-4			//if Mario arced left in his jump, then set r10 to -4 and branch to clearRight_Climax
        bne     clearRight_Climax

clearLeft_Climax:	//the following code simply clears the leftmost portion of Mario before is redrawn to the right of his current position
        ldr     r9, =marioPECE
        ldr     r8, =marioY
        ldr     r0, [r9]
        ldr     r1, [r8]
        ldr     r2, [r9, #4]
        ldr     r3, [r8, #4]
        bl      drawBlue
        b       afterClear_Climax

clearRight_Climax:	//the following code simply clears the rightmost portion of Mario before is redrawn to the left of his current position
        ldr     r9, =marioPECE
        ldr     r8, =marioY
        ldr     r0, [r9, #8]
        ldr     r1, [r8]
        ldr     r2, [r9, #12]
        ldr     r3, [r8, #4]
        bl      drawBlue

afterClear_Climax:	//the following code is responsible for redrawing Mario to the left of right depending on the direction of his arc
        ldr     r9, =marioPECE		//updates the x-coordinates of marioPECE based on r10
        ldr     r6, [r9]
        add     r6, r10
        str     r6, [r9]
        ldr     r6, [r9, #4]
        add     r6, r10
        str     r6, [r9, #4]
        ldr     r6, [r9, #8]
        add     r6, r10
        str     r6, [r9, #8]
        ldr     r6, [r9, #12]
        add     r6, r10
        str     r6, [r9, #12]

        ldr     r9, =marioX			//updates Mario's x-coordinates based on r10
        ldr     r8, [r9]
        add     r8, r10
        str     r8, [r9]
        ldr     r8, [r9, #4]
        add     r8, r10
        str     r8, [r9, #4]

        ldr     r8, =marioY			//sets up the parameters for redrawing Mario
        ldr     r9, =marioX
        ldr     r0, [r9]
        ldr     r1, [r8]
        ldr     r2, [r9, #4]
        ldr     r3, [r8, #4]

        ldr     r7, =marioRight 	//check if Mario was looking right when he jumped
        ldr     r8, [r7]
        cmp     r8, #1
        bleq    drawMarioJumpR		//if he was looking right then draw Mario jumping facing right
        blne    drawMarioJumpL		//if he was not looking right then draw Mario jumping facing left


        ldr     r7, =arcCounter		//increment arcCounter
        ldr     r8, [r7]
        add     r8, #1
        str     r8, [r7]

        ldr     r7, =movedClimax	//store true to the movecClimax label stating that Mario moved at the top of his jump
        mov     r8, #1
        str     r8, [r7]
        

        b       fall				//branch to fall

fallMystery:
        ldr     r9, =mysteryBox
        ldr     r8, [r9]
        cmp     r8, #0				//checks if the 1st mystery block has been hit
        moveq   r8, #1				//if it has not been hit then set r8 to 1 and store this boolean value to 1st element in the mysteryBox array
        streq   r8, [r9]
        bne     fall				//otherwise, if the 1st mystery block has been hit, branch to fall

        mov     r0, #256			//redraw the 1st mystery block with as an already activated mystery box via a branch and link to mysteryHit
        mov     r1, #320
        bl      mysteryHit

        mov     r0, #256			//draw a coin above the 1st mystery block via a branch and link to drawCoin
        mov     r1, #384
        mov     r2, #320
        mov     r3, #448
        bl      drawCoin

        ldr     r4, =coinJustHit	//store a 1 (true) in the coinJustHit label
        mov     r5, #1
        str     r5, [r4]

        bl      updateCoins			//update the coin count on screen via a branch and link to updateCoins

        mov     r0, #3				//the score will increase by 300 points when a mystery block is activated/hit
        bl      updateScore			//update the score on screen via a branch and link to updateScore

        b       fall				//branch to fall

fallMystery2:
        ldr     r9, =mysteryBox		//the following block of code has identical documentation to fallMystery except the mystery block being modified is the 2nd mystery block
        ldr     r8, [r9, #4]
        cmp     r8, #0
        moveq   r8, #1
        streq   r8, [r9, #4]
        bne     fall

        mov     r0, #576
        mov     r1, #640
        bl      mysteryHit

        mov     r0, #576
        mov     r1, #384
        mov     r2, #640
        mov     r3, #448
        bl      drawCoin

        ldr     r4, =coinJustHit
        mov     r5, #1
        str     r5, [r4, #4]

        bl      updateCoins

        mov     r0, #3
        bl      updateScore

        b       fall

fallMystery3:
        ldr     r9, =mysteryBox		//the following block of code has identical documentation to fallMystery except the mystery block being modified is the 3rd mystery block
        ldr     r8, [r9, #8]
        cmp     r8, #0
        moveq   r8, #1
        streq   r8, [r9, #8]
        bne     fall

        mov     r0, #704
        mov     r1, #768
        bl      mysteryHit

        mov     r0, #704
        mov     r1, #384
        mov     r2, #768
        mov     r3, #448
        bl      drawCoin

        ldr     r4, =coinJustHit
        mov     r5, #1
        str     r5, [r4, #8]

        bl      updateCoins

        mov     r0, #3
        bl      updateScore

        b       fall

fallBrick:
        ldr     r9, =hitBrick
        mov     r8, #1				//store 1 (true) to first element in the hitBrick label indicating the 1st brick
        str     r8, [r9]

        mov     r0, #512			//draw blue over the 1st brick via a branch and link to drawBlue
        mov     r1, #448
        mov     r2, #576
        mov     r3, #512
        bl      drawBlue

        b       fall				//branch to fall

fallBrick2:
        ldr     r9, =hitBrick		//store 1 (true) to second element in the hitBrick label indicating the 2nd brick
        mov     r8, #1
        str     r8, [r9, #4]

        mov     r0, #640			//draw blue over the 2nd brick via a branch and link to drawBlue
        mov     r1, #448
        mov     r2, #704
        mov     r3, #512
        bl      drawBlue

        b       fall				//branch to fall

fallBrick3:
        ldr     r9, =hitBrick		//store 1 (true) to third element in the hitBrick label indicating the 3rd brick
        mov     r8, #1
        str     r8, [r9, #8]

        mov     r0, #768			//draw blue over the 3rd brick via a branch and link to drawBlue
        mov     r1, #448
        mov     r2, #832
        mov     r3, #512
        bl      drawBlue

//////

fall:
        ldr     r7, =gravityCounter		//decrements gravityCounter by 1 it is one over the max index limit for the gravityValCounter
        ldr     r8, [r7]
        sub     r8, #1					//r8 is the currently the last index of the gravityValCounter array
        str     r8, [r7]

        ldr     r7, =gravityValCounter
        ldr     r4, [r7, r8, LSL #2]	//r4 is the number of pixels Mario will move vertically down based on gravityValCounter at index r8

        ldr     r5, =marioY
        ldr     r6, [r5]

        ldr     r8, =marioPECEjump		//update the y-coordinates of martioPECEjump
        mov     r9, r6
        str     r9, [r8]
        add     r9, r4
        str     r9, [r8, #4]

        ldr     r7, =gravityCounter
        ldr     r8, [r7]
        b       fallCond

fallBody:
        ldr     r9, =arcCounter       //Decrements the arcCounter by 1.
        ldr     r8, [r9]
        cmp     r8, #0
        sub     r8, #1
        str     r8, [r9]
        ble     contFall

fallTransitionWorld0:
        ldr     r9, =worldCounter         //Checks if Mario is in the first level, if not branches to fallBodyWorld1.
        ldr     r8, [r9]
        cmp     r8, #0
        bne     fallBodyWorld1

        ldr     r9, =marioX               //Stops Mario from going pass the leftmost side of the screen in the first level.
        ldr     r8, [r9]
        cmp     r8, #4
        ble     contFall

fallBodyWorld1:
        ldr     r8, =worldCounter         //Checks if Mario is in the second level, if not branches to fallPipeSideCheck.
        ldr     r9, [r8]
        cmp     r9, #1
        bne     fallPipeSideCheck

fall_myst1_TopBounds:
        ldr     r8, =marioX
        ldr     r9, [r8, #4]
        cmp     r9, #256				//compare Mario's right side with the x-coordinate of the left side of the 1st mystery block
        moveq   r4, #1					//if equal to then set r4 to true, otherwise false
        movne   r4, #0
        movgt   r6, #1					//also if greater than then set r6 to true otherwise false
        movle   r6, #0

        ldr     r9, [r8]
        cmp     r9, #320				//compare Mario's left side with the x-coordinate of the right side of the 1st mystery block
        moveq   r5, #1					//if equal to then set r5 to true, otherwise false
        movne   r5, #0
        movlt   r7, #1					//also if less than then set r7 to true, otherwise false
        movge   r7, #0

        tst     r6, r7					//check is Mario is inside the x-range of 1st mystery block
        beq     fall_myst1_SideBounds	//if not then branch to fall_myst1_SideBounds

        ldr     r8, =marioY				//otherwise if Mario is inside the x-range of the 1st mystery block then:
        ldr     r9, [r8, #4]
        cmp     r9, #448				//compare the bottom of his feet with the top of the 1st mystery block

        ldr     r8, =onBoxes
        mov     r9, #1
        mov     r10, #0
        streq   r9, [r8]				//store a 1 (true) to the onBoxes label is the bottom of his feet are touching the top of the 1st mystery block
        strne   r10, [r8]				//store a 0 (false) to the onBoxes label is the bottom of his feet are touching the top of the 1st mystery block

        beq     fallEnd					//also, if he currently not standing on the 1st mystery box, branch to fallEnd
        b       arcFall					//otherwise, branch to arcFall
        .ltorg

fall_myst1_SideBounds:
        orrs    r4, r5					//is Mario colliding with either wall of the 1st mystery block? Result is saved back in r4
        beq     fall_brick1_TopBounds	//if he is not then branch to fall_brick1_TopBounds

        ldr     r8, =marioY				//otherwise if true, then continue below:
        ldr     r9, [r8]

        cmp     r9, #512				//compare the top of Mario's head with the bottom of the 1st mystery block
        movlt   r6, #1					//if less than then set r6 to true, otherwise false
        movge   r6, #0

        ldr     r9, [r8, #4]
        cmp     r9, #448				//compare the bottom of Mario's feet with the top of the 1st mystery block
        movge   r7, #1					//if greater than or equal to then set r7 to true, otherwise false
        movlt   r7, #0

        tst     r6, r7					//checks if Mario is inside the y-range of the 1st mystery block
        bne     contFall				//if he is, branch to contFall

fall_brick1_TopBounds:
        ldr     r8, =hitBrick
        ldr     r9, [r8]
        mvn     r4, r9					//move the opposite boolean value of the first brick being hit into r4

        ldr     r8, =marioX
        ldr     r9, [r8]
        ldr     r10, [r8, #4]

        cmp     r10, #512				//compare Mario's right side with the x-coordinate of the left side of the 1st brick
        movgt   r5, #1					//if greater than then set r5 to true, otherwise false
        movle   r5, #0

        cmp     r9, #576				//compare Mario'd left side with the x-coordinate of right side of the 1st brick
        movlt   r6, #1					//if less than then set r6 to true, otherwise false
        movge   r6, #0

        and     r5, r6					//checks if Mario is inside the x-range of the 1st brick
        tst     r4, r5					//is the brick still existent AND is Mario inside the x-range of the 1st brick?
        beq     fall_brick1_SideBounds	//if false then branch to fall_brick1_SideBounds

        ldr     r8, =marioY				//otherwise if true, then check if the bottom of Mario's feet is touching the top of the 2nd brick
        ldr     r9, [r8, #4]
        cmp     r9, #448

        ldr     r8, =onBoxes
        mov     r9, #1
        mov     r10, #0
        streq   r9, [r8]				//if they are touching then store 1 (true) to the onBoxes label
        strne   r10, [r8]				//if they are not touching then store 0 (false) to the onBoxes label

        beq     fallEnd					//also, if he currently not standing on the 1st brick, branch to fallEnd
        b       arcFall					//otherwise, branch to arcFall

fall_brick1_SideBounds:
        ldr     r8, =marioX
        ldr     r9, [r8, #4]
        cmp     r9, #512				//compare Mario's right side  with the x-coordinate of the left side of the 1st brick
        moveq   r5, #1					//if equal to then set r5 to true, otherwise false
        movne   r5, #0

        tst    r4, r5					//checks if the brick is still existent and Mario is colliding with x-coordinate of the left side of the 1st brick
        beq    fall_myst2_TopBounds		//if false then branch to fall_myst2_TopBounds

        ldr     r8, =marioY				//otherwise if true, continue below:
        ldr     r9, [r8]

        cmp     r9, #512				//compare the top of Mario's head with the bottom of the 1st brick
        movlt   r6, #1					//if less than then set r6 to true, otherwise false
        movge   r6, #0

        ldr     r9, [r8, #4]
        cmp     r9, #448				//compare the bottom of Mario's feet with the top of the 1st brick
        movge   r7, #1					//if greater than or equal to then set r7 to true, otherwise false
        movlt   r7, #0

        tst     r6, r7					//checks if Mario is inside the y-range of the 1st brick
        bne     contFall				//if he is, branch to contFall

fall_myst2_TopBounds:
        ldr     r8, =marioX
        ldr     r9, [r8, #4]
        cmp     r9, #576				//compare Mario's right side with the x-coordinate of the left side of the 2nd mystery block
        movgt   r6, #1					//if greater than then set r6 to true, otherwise false
        movle   r6, #0

        ldr     r9, [r8]				//compare Mario's left side with the x-coordinate of the right side of the 2nd mystery block
        cmp     r9, #640				//if less than then set r7 to true, otherwise false
        movlt   r7, #1
        movge   r7, #0

        tst     r6, r7					//checks if Mario is inside the x-range of the 2nd mystery block
        beq     fall_myst2_SideBounds	//if false then branch to fall_myst2_SideBounds

        ldr     r8, =marioY				//otherwise if true then continue below:
        ldr     r9, [r8, #4]
        cmp     r9, #448				//check if the bottom of Mario's feet are touching the top of the 2nd mystery block

        ldr     r8, =onBoxes
        mov     r9, #1
        mov     r10, #0
        streq   r9, [r8]				//if they are touching then store 1 (true) to the onBoxes label
        strne   r10, [r8]				//if they are not touching then store 0 (false) to the onBoxes label

        beq     fallEnd					//also, if he currently not standing on the 2nd mystery block, branch to fallEnd
        b       arcFall					//otherwise, branch to arcFall


fall_myst2_SideBounds:
        ldr     r8, =marioX
        ldr     r9, [r8, #4]
        cmp     r9, #576				//compares Mario's right side with the x-coordinate of the left side of the 2nd mystery block
        moveq   r4, #1					//if equal to then set r4 to true, otherwise false
        movne   r4, #0

        ldr     r8, =hitBrick
        ldr     r9, [r8]				//r9 is the boolean value of the first brick being hit

        and     r7, r4, r9				//is Mario hitting the x-coordinate of the left side of the 2nd mystery block AND is the 1st brick non-existent? Result is saved in r7

        ldr     r8, =marioX
        ldr     r9, [r8]
        cmp     r9, #640				//compares Mario's left side with the x-coordinate of the right side of the 2nd mystery block
        moveq   r4, #1					//if equal to then set r4 to true, otherwise false
        movne   r4, #0

        ldr     r8, =hitBrick
        ldr     r9, [r8, #4]

        and     r8, r4, r9				//is Mario hitting the x-coordinate of the right side of the 2nd mystery block AND is the 2nd brick non-existent? Result is saved in r8

        orrs    r7, r8					//checks if Mario can properly hit one of the sides of the 2nd mystery block, unrestricted by the existent of a brick
        beq     fall_brick2_TopBounds	//if not, then branch to fall_brick2_TopBounds

        ldr     r8, =marioY				//otherwise, if so then continue below:
        ldr     r9, [r8]

        cmp     r9, #512				//compares the top of Mario's head with the bottom of the 2nd mystery box
        movlt   r6, #1					//if less than then set r6 to true, otherwise false
        movge   r6, #0

        ldr     r9, [r8, #4]
        cmp     r9, #448				//compares the bottom of Mario's feet with the top of the 2nd mystery box
        movge   r7, #1					//if greater than or equal to then set r7 to true, otherwise false
        movlt   r7, #0

        tst     r6, r7					//checks if Mario is inside the y-range of the 2nd mystery block
        bne     contFall				//if so then branch to contFall

fall_brick2_TopBounds:
        ldr     r8, =hitBrick
        ldr     r9, [r8, #4]
        mvn     r4, r9					//r9 is the opposite boolean value of the second brick being hit

        ldr     r8, =marioX
        ldr     r9, [r8]
        ldr     r10, [r8, #4]

        cmp     r10, #640				//compares Mario's right side with the x-coordinate of the left side of the 2nd brick
        movgt   r5, #1					//if greater than then set r5 to true, otherwise false
        movle   r5, #0

        cmp     r9, #704				//compares Mario's left side with the x-coordinate of the right side of the 2nd brick
        movlt   r6, #1					//if less than then set r6 to true, otherwise false
        movge   r6, #0

        and     r5, r6					//checks if Mario is inside the x-range of 2nd brick
        tst     r4, r5					//is Mario inside the x-range of the 2nd brick AND is this brick still existent?
        beq     fall_myst3_TopBounds	//if false then branch to fall_myst3_TopBounds

        ldr     r8, =marioY				//otherwise if true, then continue below:
        ldr     r9, [r8, #4]
        cmp     r9, #448				//check if the the bottom of Mario's feet is touching the top of the 2nd brick

        ldr     r8, =onBoxes
        mov     r9, #1
        mov     r10, #0
        streq   r9, [r8]				//if they are touching then store a 1 (true) to the onBoxes label
        strne   r10, [r8]				//if they are not touching then store a 0 (false) to the onBoxes label

        beq     fallEnd					//also, if he currently not standing on the 2nd mystery block, branch to fallEnd
        b       arcFall					//otherwise, branch to arcFall

fall_myst3_TopBounds:
        ldr     r8, =marioX
        ldr     r9, [r8, #4]
        cmp     r9, #704				//compares Mario's right side with the x-coordinate of the left side of the 3rd mystery box
        movgt   r6, #1					//if greater than then set r6 to true, otherwise false
        movle   r6, #0

        ldr     r9, [r8]
        cmp     r9, #768				//compares Mario's left side with the x-coordinate of the right side of the 3rd mystery box
        movlt   r7, #1					//if less than then set r7 to true, otherwise false
        movge   r7, #0

        tst     r6, r7					//checks if Mario is inside the x-range of the 2nd mystery block
        beq     fall_myst3_SideBounds	//if false then branch to fall_myst3_SideBounds

        ldr     r8, =marioY				//otherwise if true continue below:
        ldr     r9, [r8, #4]
        cmp     r9, #448				//checks if the bottom of Mario's feet is touching the top of the 3rd mystery block

        ldr     r8, =onBoxes
        mov     r9, #1
        mov     r10, #0
        streq   r9, [r8]				//if they are touching then store a 1 (true) to the onBoxes label
        strne   r10, [r8]				//if they are not touching then store a 0 (false) to the onBoxes label

        beq     fallEnd					//also, if he currently not standing on the 2nd mystery block, branch to fallEnd
        b       arcFall					//otherwise, branch to arcFall

fall_myst3_SideBounds:
        ldr     r8, =marioX
        ldr     r9, [r8, #4]
        cmp     r9, #704				//compares Mario's right side with the x-coordinate of the left side of the 3rd mystery block
        moveq   r4, #1					//if equal to then set r4 to true, otherwise false
        movne   r4, #0

        ldr     r8, =hitBrick
        ldr     r9, [r8, #4]			//r9 is the boolean value of the second brick being hit

        and     r7, r4, r9				//is Mario hitting the x-coordinate of the left side of the 3rd mystery block AND is the 2nd brick non-existent? Result is saved in r7

        ldr     r8, =marioX
        ldr     r9, [r8]
        cmp     r9, #768				//compares Mario's left side with the x-coordinate of the right side of the 3rd mystery block
        moveq   r4, #1					//if equal to then set r4 to true, otherwise false
        movne   r4, #0

        ldr     r8, =hitBrick
        ldr     r9, [r8, #8]			//r9 is the boolean value of the third brick being hit

        and     r8, r4, r9				//is Mario hitting the x-coordinate of the right side of the 3rd mystery block AND is the 3rd brick non-existent? Result is saved in r7

        orrs    r7, r8					//checks if Mario can properly hit one of the sides of the 3rd mystery block, unrestricted by the existent of a brick
        beq     fall_brick3_TopBounds	//if not then branch to fall_brick3_TopBounds

        ldr     r8, =marioY
        ldr     r9, [r8]

        cmp     r9, #512				//compares the top of Mario's head with the bottom of the 3rd mystery box
        movlt   r6, #1					//if less than then set r6 to true, otherwise false
        movge   r6, #0

        ldr     r9, [r8, #4]
        cmp     r9, #448				//compares the bottom of Mario's feet with the top of the 3rd mystery box
        movge   r7, #1					//if greater than or equal to then set r7 to true, otherwise false
        movlt   r7, #0

        tst     r6, r7					//checks if Mario is inside the y-range of the 3rd mystery block
        bne     contFall				//if true then branch to contFall

fall_brick3_TopBounds:
        ldr     r8, =hitBrick
        ldr     r9, [r8, #8]
        mvn     r4, r9					//r4 is the opposite boolean value of the third brick being hit

        ldr     r8, =marioX
        ldr     r9, [r8]
        ldr     r10, [r8, #4]

        cmp     r10, #768				//compares the right side of Mario with the x-coordinate of the left side of the 3rd brick
        movgt   r5, #1					//if greater than then set r5 to true, otherwise false
        movle   r5, #0

        cmp     r9, #832				//compares the left side of Mario with the x-coordinate of the right side of the 3rd brick
        movlt   r6, #1					//if less than then set r6 to true, otherwise false
        movge   r6, #0

        and     r5, r6					//checks if Mario is inside the x-range of the 3rd brick
        tst     r4, r5					//is the brick still existent AND is Mario inside the x-range of the 1st brick?
        beq     fall_brick3_SideBounds	//if false then branch to fall_brick3_SideBounds

        ldr     r8, =marioY				//otherwise if true then continue below:
        ldr     r9, [r8, #4]
        cmp     r9, #448				//checks if the bottom of Mario's feet is touching the top of the 3rd brick

        ldr     r8, =onBoxes
        mov     r9, #1
        mov     r10, #0
        streq   r9, [r8]				//if they are touching then store a 1 (true) to the onBoxes label
        strne   r10, [r8]				//if they are not touching then store a 0 (false) to the onBoxes label

        beq     fallEnd					//also, if he currently not standing on the 3rd brick, branch to fallEnd
        b       arcFall					//otherwise, branch to arcFall

fall_brick3_SideBounds:
        ldr     r8, =marioX
        ldr     r9, [r8]
        cmp     r9, #832				//compares the left side of Mario with the x-coordinate of the right side of the 3rd brick
        moveq   r5, #1					//if less than then set r5 to true, otherwise false
        movne   r5, #0

        tst    r4, r5					//checks if the 3rd brick is still existent and Mario is colliding with x-coordinate of the left side of the 3rd brick
        beq    arcFall					//if false then branch to arcFall

        ldr     r8, =marioY				//otherwise if true then continue below
        ldr     r9, [r8]

        cmp     r9, #512				//compares the top of Mario's head with the bottom of the 3rd brick
        movlt   r6, #1					//if less than then set r6 to true, otherwise false
        movge   r6, #0

        ldr     r9, [r8, #4]
        cmp     r9, #448				//compares the bottom of Mario's feet with the top of the 3rd brick
        movge   r7, #1					//if greater than or equal to then set r7 to true, otherwise false
        movlt   r7, #0

        tst     r6, r7					//checks if Mario is inside the y-range of the 3rd brick
        bne     contFall				//if true then branch to contFall

        b       arcFall					//otherwise Branch to arcFall

fallPipeSideCheck:
        ldr     r8, =worldCounter     //Checks if Mario is in the third level.
        ldr     r9, [r8]
        cmp     r9, #2
        bne     arcFall

        ldr     r9, =marioX           //Check if Mario front is touching the 256 X coordinate.
        ldr     r8, [r9, #4]
        cmp     r8, #256
        moveq   r5, #1
        movne   r5, #0

        ldr     r9, =marioY           //Check if Mario bottom is greater than the 512 Y coordinate.
        ldr     r8, [r9, #4]
        cmp     r8, #512
        movge   r6, #1
        movlt   r6, #0

        tst     r5, r6                //If both Mario is touching the first pipe and is lower than the pipe, then branch to contFall.
        bne     contFall

        ldr     r9, =marioX          //Check if Mario back is touching the 384 X coordinate.
        ldr     r8, [r9]
        cmp     r8, #384
        moveq   r5, #1
        movne   r5, #0

        ldr     r9, =marioY          //Check if Mario bottom is greater than the 512 Y coordinate.
        ldr     r8, [r9, #4]
        cmp     r8, #512
        movge   r6, #1
        movlt   r6, #0

        tst     r5, r6              //If both Mario is touching the first pipe and is lower than the pipe, then branch to contFall.
        bne     contFall

fall2PipeSideCheck:
        ldr     r9, =marioX         //Check if Mario front is touching the 640 X coordinate.
        ldr     r8, [r9, #4]
        cmp     r8, #640
        moveq   r5, #1
        movne   r5, #0

        ldr     r9, =marioY         //Check if Mario bottom is greater than the 512 Y coordinate.
        ldr     r8, [r9, #4]
        cmp     r8, #512
        movge   r6, #1
        movlt   r6, #0

        tst     r5, r6              //If both Mario is touching the second pipe and is lower than the pipe, then branch to contFall.
        bne     contFall

        ldr     r9, =marioX           //Check if Mario back is touching the 768 X coordinate.
        ldr     r8, [r9]
        cmp     r8, #768
        moveq   r5, #1
        movne   r5, #0

        ldr     r9, =marioY         //Check if Mario bottom is greater than the 512 Y coordinate.
        ldr     r8, [r9, #4]
        cmp     r8, #512
        movge   r6, #1
        movlt   r6, #0

        tst     r5, r6              //If both Mario is touching the second pipe and is lower than the pipe, then branch to contFall.
        bne     contFall

arcFall:
	
        ldr     r7, =movedClimax
        ldr     r8, [r7]
        cmp     r8, #1

        ldr     r9, =arcCounter
        ldr     r10, [r9]
        subeq   r10, #1
        streq   r10, [r9]
        moveq   r8, #0
        streq   r8, [r7]


        ldr     r7, =arcX			//r7 is the address of arcX, which will be the horizontal distance (in pixels) Mario will move by when falling
        ldr     r8, [r7]

        ldr     r9, =arcRight
        ldr     r10, [r9]
        cmp     r10, #0				//checks if Mario was arcing right in his jump
        beq     subX_fallArc		//if not then branch to subX_fallArc

        mov     r8, #4				//otherwise, since he was arcing right in his jump, he must continue arcing right upon falling
        str     r8, [r7]			//so store 4 to the arcX label

        ldr     r9, =marioPECE		//clear the leftmost portion of Mario before he is redrawn to the right of his current position
        ldr     r8, =marioY
        ldr     r0, [r9]
        ldr     r1, [r8]
        ldr     r2, [r9, #4]
        ldr     r3, [r8, #4]
        bl      drawBlue

        ldr     r9, =marioPECE		//update the x-coordinates of marioPECE by adding 4 pixels to each since Mario will be moving 4 pixels to the right when redrawn
        ldr     r6, [r9]
        add     r6, #4
        str     r6, [r9]
        ldr     r6, [r9, #4]
        add     r6, #4
        str     r6, [r9, #4]
        ldr     r6, [r9, #8]
        add     r6, #4
        str     r6, [r9, #8]
        ldr     r6, [r9, #12]
        add     r6, #4
        str     r6, [r9, #12]

        b       contArcFall			//branch to contArcFall

subX_fallArc:	//the following code for when Mario is falling to the left
        mov     r8, #-4				//since Mario will be falling to the left, we store -4 to the arcX label
        str     r8, [r7]

        ldr     r9, =marioPECE		//clear the rightmost portion of Mario before he is redrawn to the left of his current position
        ldr     r8, =marioY
        ldr     r0, [r9, #8]
        ldr     r1, [r8]
        ldr     r2, [r9, #12]
        ldr     r3, [r8, #4]
        bl      drawBlue

        ldr     r9, =marioPECE		//update the x-coordinates of marioPECE by subtracting 4 pixels to each since Mario will be moving 4 pixels to the left when redrawn
        ldr     r6, [r9]
        sub     r6, #4
        str     r6, [r9]
        ldr     r6, [r9, #4]
        sub     r6, #4
        str     r6, [r9, #4]
        ldr     r6, [r9, #8]
        sub     r6, #4
        str     r6, [r9, #8]
        ldr     r6, [r9, #12]
        sub     r6, #4
        str     r6, [r9, #12]

contArcFall:	//the following code simply updates Mario's x-coordinates depending on whether he is arcing left or right before he is redrawn
        ldr     r7, =arcX
        ldr     r8, [r7]		//r8 is the arcX value, or the horizontal distance in pixels Mario will move while falling

        ldr     r9, =marioX		//update Mario's x-coordinates based on the value of arcX in r8
        ldr     r6, [r9]
        add     r6, r8
        str     r6, [r9]
        ldr     r6, [r9, #4]
        add     r6, r8
        str     r6, [r9, #4]

//When Mario is falling and touches the castle, Mario wins and branches to the win message.
fallTransitionFinal:
        ldr     r9, =worldCounter       //Checks if Mario is in final level, if not branches to fallTransition.
        ldr     r8, [r9]
        cmp     r8, #3
        bne     fallTransition

        ldr     r9, =marioX             //If Mario's front touches the 704 X coordinate, branches to winCond.
        ldr     r8, [r9, #4]
        cmp     r8, #704
        beq     winCond

//When Mario is falling and touches the rightmost side of the screen, he goes to the next level.
fallTransition:
        ldr     r9, =marioX           //If Mario's front touches the 1024 X coordinate, branches to nextLevel.
        ldr     r8, [r9, #4]
        cmp     r8, #1024
        beq     nextLevel

//When Mario is falling and touches the leftmost side of the screen, he goes to the previous level.
fallTransitionCont:
        ldr     r9, =marioX
        ldr     r8, [r9]
        cmp     r8, #0
        beq     previousLevel

contFall:	//the following code is responsible for redrawing Mario in his falling animation
        ldr     r4, =gravityCounter
        ldr     r5, [r4]

        ldr     r7, =gravityValCounter
        ldr     r10, [r7, r5, LSL #2]		//r10 is the number of pixels Mario goes down by based on gravityValCounter

        sub     r5, #1
        ldr     r4, [r7, r5, LSL #2]		//r4 is the number of pixels Mario will go down by in the next iteration of the loop based on gravityValCounter

        push    {r4}
        ldr     r8, =marioX					//clear the top-most portion of Mario before he is redrawn
        ldr     r9, =marioPECEjump
        ldr     r0, [r8]
        ldr     r1, [r9]
        ldr     r2, [r8, #4]
        ldr     r3, [r9, #4]
        bl      drawBlue
        pop     {r4}

        ldr     r9, =marioPECEjump			//update the y-coordinates of marioPECEjump which is responsible for the vertical clearing of Mario when he moves vertically
        ldr     r6, [r9]
        add     r6, r10
        str     r6, [r9]
        add     r6, r6, r4
        str     r6, [r9, #4]

        ldr     r9, =marioY					//update Mario's y-coordinates based on how much pixels he went down by, which was r10
        ldr     r6, [r9]
        add     r6, r10
        str     r6, [r9]
        ldr     r6, [r9, #4]
        add     r6, r10
        str     r6, [r9, #4]

        ldr     r8, =marioY					//set up the parameters for redrawing Mario
        ldr     r9, =marioX
        ldr     r0, [r9]
        ldr     r1, [r8]
        ldr     r2, [r9, #4]
        ldr     r3, [r8, #4]

        bl      checkMushroomHit_fall		//branch and link to checkMushroomHit_fall

        ldr     r7, =marioRight 			//check if Mario was looking right when he jumped
        ldr     r8, [r7]
        cmp     r8, #1
        bleq    drawMarioJumpR				//if he was looking right then draw Mario jumping facing right
        blne    drawMarioJumpL				//if he was not looking right then draw Mario jumping facing left

        ldr     r7, =gravityCounter			//decrement gravityCounter
        ldr     r8, [r7]
        sub     r8, #1
        str     r8, [r7]

fallCond:
        ldr     r9, =worldCounter       //Checks if Mario is in the first world, if checks if Mario landed on the goomba.
        ldr     r8, [r9]
        cmp     r8, #0
        bleq    jumpMonster

        ldr     r9, =worldCounter       //Checks if Mario is in the final world, if checks if Mario landed on the spiky monster.
        ldr     r8, [r9]
        cmp     r8, #3
        bleq    jumpMonster

        ldr     r9, =hitSpiky           //If Mario hit the spiky monster branches to unHitMonster.
        ldr     r8, [r9]
        cmp     r8, #1
        beq     unHitMonster

        ldr     r9, =worldCounter       //Checks if Mario is in the third world, if not branches to fallCont.
        ldr     r8, [r9]
        cmp     r8, #2
        bne     fallCont

        ldr     r9, =marioY             //If Mario Y position is less than the height of the pipe branch to fallCont.
        ldr     r8, [r9, #4]
        cmp     r8, #512
        bne     fallCont

        ldr     r9, =marioRight         //Check if Mario is facing right, if not branches to leftStayPipe.
        ldr     r8, [r9]
        cmp     r8, #1
        bne     leftStayPipe

        ldr     r9, =marioX             //Checks if Mario front is within the first pipe boundary, when facing right.
        ldr     r8, [r9, #4]
        cmp     r8, #256
        movgt   r5, #1
        movle   r5, #0

        ldr     r9, =marioX             //Checks if Mario back is within the first pipe boundary, when facing right.
        ldr     r8, [r9]
        cmp     r8, #384
        movlt   r6, #1
        movge   r6, #0

        tst     r5, r6                  //If either is on the first pipe boundary Mario stays on the pipe, when facing right.
        bne     pipeS

        ldr     r9, =marioX             //Checks if Mario front is within the second pipe boundary, when facing right.
        ldr     r8, [r9, #4]
        cmp     r8, #640
        movgt   r5, #1
        movle   r5, #0

        ldr     r9, =marioX             //Checks if Mario back is within the second pipe boundary, when facing right.
        ldr     r8, [r9]
        cmp     r8, #768
        movlt   r6, #1
        movge   r6, #0

        tst     r5, r6                  //If either is on the second pipe boundary Mario stays on the pipe, when facing right.
        bne     pipeS

        b       fallCont
        .ltorg

leftStayPipe:
        ldr     r9, =marioX             //Checks if Mario front is within the first pipe boundary, when facing left.
        ldr     r8, [r9, #4]
        cmp     r8, #256
        movgt   r5, #1
        movle   r5, #0

        ldr     r9, =marioX             //Checks if Mario back is within the first pipe boundary, when facing left.
        ldr     r8, [r9]
        cmp     r8, #384
        movlt   r6, #1
        movge   r6, #0

        tst     r5, r6                  //If either is on the first pipe boundary Mario stays on the pipe, when facing left.
        bne     pipeS

        ldr     r9, =marioX             //Checks if Mario front is within the second pipe boundary, when facing left.
        ldr     r8, [r9, #4]
        cmp     r8, #640
        movgt   r5, #1
        movle   r5, #0

        ldr     r9, =marioX             //Checks if Mario back is within the second pipe boundary, when facing left.
        ldr     r8, [r9]
        cmp     r8, #768
        movlt   r6, #1
        movge   r6, #0

        tst     r5, r6                  //If either is on the second pipe boundary Mario stays on the pipe, when facing left.
        bne     pipeS

fallCont:
        ldr     r9, =gravityCounter     //Mario continues to fall to the ground while gravityCounter is greater than or equal to 0 and branches to fallBody.
        ldr     r8, [r9]
        cmp     r8, #0
        bge     fallBody

        ldr     r9, =worldCounter       //Checks if Mario is in the first level, if so branches to drop, which checks if Mario has landed in the hole.
        ldr     r8, [r9]
        cmp     r8, #0
        bleq    drop

        ldr     r9, =dropBool       //Checks if Mario is in the hole, if he is branch to dropRestart.
        ldr     r8, [r9]
        cmp     r8, #1
        beq     dropRestart

        ldr     r9, =worldCounter       //Checks if Mario is in the second level, if so branches to fallEnd.
        ldr     r8, [r9]
        cmp     r8, #1
        bne     fallEnd

        ldr     r9, =marioY             //Checks if Mario is at the height of the blocks.
        ldr     r8, [r9, #4]
        cmp     r8, #448
        bne     fallEnd

        ldr     r7, =marioX
        ldr     r8, [r7]                //r8 is the left side of Mario
        ldr     r9, [r7, #4]            //r9 is the right side of Mario

        cmp     r9, #256                //checks to see if mario is on the outside right boundary of the island mystery block
        movle   r4, #1
        movgt   r4, #0

        cmp     r8, #320            //checks to see if mario is on the outside left boundary of the island mystery block
        movge   r5, #1
        movlt   r5, #0

        ldr     r7, =hitBrick       //handles dynamic boundary changes based on the existence of the first brick
        ldr     r6, [r7]
        cmp     r6, #1
        moveq   r10, #576
        movne   r10, #512

        cmp     r9, r10           //checks to see if mario is on outside left boundary of brick 1
        movle   r6, #1
        movgt   r6, #0

        and     r5, r6            //checks if mario is on the outside boundaries of the block placements(i.e. not going to fall on them)
        orr     r4, r5

        ldr     r6, [r7, #4]      //checks if the last brick has been hit, if not branch to Fall_checkLast
        cmp     r6, #1
        bne     Fall_checkLast

        cmp     r8, #640        //if it has been hit, check is mario's left side is less than or equal to the left side of mystery2
        movge   r5, #1
        movlt   r5, #0

        cmp     r9, #704        //also check if mario's right side is less than or equal to the right side mystery3
        movle   r6, #1
        movgt   r6, #0

        and     r5, r6        //checks if mario is inside the falling boundaries of the middle block when missing
        orr     r4, r5

Fall_checkLast:
        ldr     r6, [r7, #8]     //dynamic boundary changes related to the existence of the 3rd block
        cmp     r6, #1
        moveq   r10, #768
        movne   r10, #832

        cmp     r8, r10         //checks if mario is on the outside right boundary of the 3rd brick
        movge   r7, #1
        movlt   r7, #0

        orrs    r4, r7          //checks is on the outside boundaries of the bricks

        mov     r0, #16
        ldr     r9, =marioY
        ldr     r1, [r9]
        add     r2, r1, #16

        bleq    fallEnd         //if he is, then branch and link to fallEnd

        ldr     r5, =marioRight   //Mario falling from the block
        ldr     r6, [r5]
        cmp     r6, #1
        bleq    dropBlockR
        blne    dropBlockL

        b       fallEnd     //branch and link to fallEnd

//Change Mario's Y position so that he stays on top of the pipe that he has landed on.
pipeS:
        ldr     r9, =marioY           //Sets Mario's Y position to be at the height of the pipe.
        mov     r6, #448
        str     r6, [r9]
        mov     r7, #512
        str     r7, [r9, #4]

        ldr     r8, =marioPECEjump    //Updates Mario's jump clear to accommodate for Mario he Y position.
        mov     r9, r6
        str     r9, [r8]
        add     r9, #16
        str     r9, [r8, #4]

        ldr     r9, =marioOnPipe      //Sets the marioOnPipe label to be 1, meaning that Mario is on a pipe.
        mov     r8, #1
        str     r8, [r9]

fallEnd:
        ldr     r9, =marioX         //Redraw Mario at he new X and Y position after he has landed from his jump.
        ldr     r8, =marioY
        ldr     r0, [r9]
        ldr     r1, [r8]
        ldr     r2, [r9, #4]
        ldr     r3, [r8, #4]

        ldr     r8, =midjump        //Reset midjump back to its initial value.
        mov     r9, #0
        str     r9, [r8]

        ldr     r9, =marioRight     //Check if Mario is looking right, if so draws Mario facing right else draws him facing left.
        ldr     r8, [r9]
        cmp     r8, #1
        bleq    drawMarioR
        blne    drawMarioL

        ldr     r7, =moveCounter      //Sets the moveCounter back to its initial value.
        mov     r8, #0
        str     r8, [r7]

        ldr     r5, =worldCounter     //Check if Mario is in the second level, if not branches to fallPipeCheck.
        ldr     r6, [r5]
        cmp     r6, #1
        bne     fallPipeCheck
        bl      checkCoinHits         //Checks if a coin has appeared from being hit from a coin block.

        b       pressStart

//Chckes to see if Mario on on a pipe in the third level.
fallPipeCheck:
        ldr     r5, =worldCounter   //Checks if Mario is on the third level, if so branches to pressStart
        ldr     r6, [r5]
        cmp     r6, #2
        bne     pressStart

        ldr     r9, =marioOnPipe    //Checks to see if Mario is on either of the pipes.
        ldr     r8, [r9]
        cmp     r8, #1
        bne     pressStart

//Checks if Mario has fallen in the space that are not covered by the first pipe boundary on the left side.
space1:
        ldr     r9, =marioX         //Checks if Mario's (back) X coordinate is within the pipe boundary of the left side.
        ldr     r8, [r9]
        cmp     r8, #256
        movle   r5, #1
        movgt   r5, #0

        ldr     r8, [r9, #4]       //Checks if Mario's (front) X coordinate is within the pipe boundary of the left side.
        cmp     r8, #256
        movle   r6, #1
        movgt   r6, #0

        tst     r5, r6             //If both Mario's front and back X  coordinates are not within the pipe boundary Mario falls off the pipe.
        bne     FallPipe1

//Checks if Mario has fallen in the space that are not covered by the first pipe boundary on the right side.
space2:
        ldr     r9, =marioX       //Checks if Mario is on the second pipe boundary.
        ldr     r8, [r9, #4]
        cmp     r8, #640
        bge     space3

        ldr     r9, =marioX       //Checks if Mario's (back) X coordinate is within the pipe boundary of the right side.
        ldr     r8, [r9]
        cmp     r8, #384
        movge   r5, #1
        movlt   r5, #0

        ldr     r8, [r9, #4]      //Checks if Mario's (front) X coordinate is within the pipe boundary of the right side.
        cmp     r8, #384
        movge   r6, #1
        movlt   r6, #0

        tst     r5, r6            //If both Mario's front and back X  coordinates are not within the pipe boundary Mario falls off the pipe.
        bne     FallPipe1

        b       pressStart

//Checks if Mario has fallen in the space that are not covered by the second pipe boundary.
space3:
        ldr     r9, =marioX       //Checks if Mario's (back) X coordinate is within the pipe boundary of the left side.
        ldr     r8, [r9]
        cmp     r8, #640
        movlt   r5, #1
        movge   r5, #0

        ldr     r8, [r9, #4]      //Checks if Mario's (front) X coordinate is within the pipe boundary of the left side.
        cmp     r8, #640
        movlt   r6, #1
        movge   r6, #0

        tst     r5, r6            //If both Mario's front and back X  coordinates are not within the pipe boundary Mario falls off the pipe.
        bne     FallPipe1

        ldr     r9, =marioX       //Checks if Mario's (back) X coordinate is within the pipe boundary of the right side.
        ldr     r8, [r9]
        cmp     r8, #768
        movgt   r5, #1
        movle   r5, #0

        ldr     r8, [r9, #4]      //Checks if Mario's (front) X coordinate is within the pipe boundary of the right side.
        cmp     r8, #768
        movgt   r6, #1
        movle   r6, #0

        tst     r5, r6            //If both Mario's front and back X  coordinates are not within the pipe boundary Mario falls off the pipe.
        bne     FallPipe1

        b       pressStart

//Mario falling from the pipe when he lands outside the pipe boundaries animation.
FallPipe1:
        ldr     r9, =marioRight   //Checks if Mario is looking right, if so drops Mario facing right, else drops Mario facing left.
        ldr     r8, [r9]
        cmp     r8, #1
        mov     r0, #12
        beq     dropPipeR
        mov     r0, #12
        blne    dropPipeL

        ldr     r9, =marioPECEjump    //Sets Mario's jump clear to its initial values.
        mov     r8, #688
        str     r8, [r9]
        mov     r8, #704
        str     r8, [r9, #4]

        ldr     r9, =marioY         //Sets Mario's Y coordinates back to its initial values.
        mov     r8, #640
        str     r8, [r9]
        mov     r8, #704
        str     r8, [r9, #4]

        ldr     r9, =marioOnPipe      //Sets marioOnPipe label to be 0, meaning that Mario is on the pipe anymore.
        mov     r8, #0
        str     r8, [r9]

//Checks if the start button was pressed, if so branches to the pauseMenu.
pressStart:
        ldr     r4, =0xFFF7     //START
        cmp     r10, r4         //Checks if the start button was pressed if not branches to readSNES.
        bne     readSNES

        ldr     r9, =gamemode   //Changes the gamemode to be 2, which is the pause menu controls.
        mov     r8, #2
        str     r8, [r9]
        b       pauseMenu

//Branches back to Read_SNES, which check if another button press have been made.
readSNES:
        b       Read_SNES

//If Mario is in the first level, resets the hitGoomba label after Mario has already hit the goomba and been brought back to life.
unHitMonster:
        ldr     r9, =worldCounter       //Checks if Mario is in the first level. If not branches to unHitMonsterFinal.
        ldr     r8, [r9]
        cmp     r8, #0
        bne     unHitMonsterFinal

        ldr     r9, =hitGoomba        //Sets hitGoomba label to be 0, meaning that the goomba has not been hit.
        mov     r8, #0
        str     r8, [r9]

        b       end

//If Mario is in the first level, resets the hitSpiky label after Mario has already hit the spiky monster and been brought back to life.
unHitMonsterFinal:
        ldr     r9, =hitSpiky         //Sets hitSpiky label to be 0, meaning that the spiky monster has not been hit.
        mov     r8, #0
        str     r8, [r9]

        ldr     r9, =worldCounter    //Set the worldCounter to 0, meaning going back to the first level.
        mov     r8, #0
        str     r8, [r9]

//Branches to Read_SNES which samples the SNES button press.
end:
        b       Read_SNES

//Resets the dropBool label after Mario has already fallen into the hole and been brought back to life.
dropRestart:
        ldr     r9, =dropBool
        mov     r8, #0
        str     r8, [r9]

        b       Read_SNES

//Checks the worldCounter and draws the next level depending on the current level Mario is in, clearing the previous level that Mario is in. Also clears any extra life mushroom still on screen.
nextLevel:
        ldr     r9, =marioX
        ldr     r8, =marioY
        ldr     r0, [r9]
        ldr     r1, [r8]
        ldr     r2, [r9, #4]
        ldr     r3, [r8, #4]
        bl      drawBlue

        ldr     r9, =mushroomOnScreen
        ldr     r8, [r9]
        cmp     r8, #1
        bleq    clearPrevMRPos

        ldr     r9, =worldCounter
        ldr     r8, [r9]
        add     r8, #1
        str     r8, [r9]

//If the worldCounter is 1 draw the second level and clear the previous level Mario is in.
level2N:
        ldr     r9, =worldCounter
        ldr     r8, [r9]
        cmp     r8, #1
        bne     level3N
        bl      restart
        bl      levelTwo

        b       nextLevelCont

//If the worldCounter is 2 draw the third level and clear the previous level Mario is in.
level3N:
        ldr     r9, =worldCounter
        ldr     r8, [r9]
        cmp     r8, #2
        bne     levelFinalN
        bl      clearLevelTwo
        bl      restart
        bl      levelThree

        b       nextLevelCont

//If the worldCounter is 3 draw the final level and clear the previous level Mario is in.
levelFinalN:
        ldr     r9, =worldCounter
        ldr     r8, [r9]
        cmp     r8, #3
        bne     nextLevelCont
        bl      restart
        bl      clearLevelThreeFinal
        bl      levelFinal

//Redraws Mario facing right when he goes to a next level.
nextLevelCont:
        ldr     r9, =marioRight
        mov     r8, #1
        str     r8, [r9]

        mov     r0, #0
        mov     r1, #640
        mov     r2, #64
        mov     r3, #704
        bleq    drawMarioR

        b       Read_SNES

//Checks the worldCounter and redraws the previous level depending on the current level Mario is in, clearing the current level that Mario is in. Also clears any extra life mushroom still on screen.
previousLevel:
        ldr     r9, =marioX
        ldr     r8, =marioY
        ldr     r0, [r9]
        ldr     r1, [r8]
        ldr     r2, [r9, #4]
        ldr     r3, [r8, #4]
        bl      drawBlue

        ldr     r9, =mushroomOnScreen
        ldr     r8, [r9]
        cmp     r8, #1
        bleq    clearPrevMRPos

        ldr     r9, =worldCounter
        ldr     r8, [r9]
        sub     r8, #1
        str     r8, [r9]

//If the worldCounter is 0 draw the first level and clear the current level Mario is in.
level1P:
        ldr     r9, =worldCounter
        ldr     r8, [r9]
        cmp     r8, #0
        bne     level2P
        bl      restartLeft
        bl      levelOne

        b       previousLevelCont

//If the worldCounter is 1 draw the second level and clear the current level Mario is in.
level2P:
        ldr     r9, =worldCounter
        ldr     r8, [r9]
        cmp     r8, #1
        bne     level3P
        bl      restartLeft
        bl      clearLevelThreeFinal
        bl      levelTwo

        b       previousLevelCont

//If the worldCounter is 2 draw the third level and clear the current level Mario is in.
level3P:
        ldr     r9, =worldCounter
        ldr     r8, [r9]
        cmp     r8, #2
        bne     previousLevelCont
        bl      restartLeft
        bl      clearLevelThreeFinal
        bl      levelThree

//Redraws Mario facing left when he goes back to a previous level.
previousLevelCont:
        ldr     r9, =marioRight     //Sets Mario to be facing left.
        mov     r8, #0
        str     r8, [r9]

        mov     r0, #960            //Draws Mario facing left.
        mov     r1, #640
        mov     r2, #1024
        mov     r3, #704
        bl      drawMarioL

        b       Read_SNES

//Draws the pause menu on screen as well as it the mushroom selector that corresponds with the pause menu.
pauseMenu:
        mov     r0, #320        //Draws the pause menu onto the screen.
        mov     r1, #128
        mov     r2, #704
        mov     r3, #320
        bl      pauseScreen

        mov     r0, #352        //Draws the mushroom selector that corresponds with the pause menu.
        mov     r1, #384
        bl      mushroomPause

        b       pauseRead_SNES

//Passes in the buttons pressed on the SNES controller and branches to the pause controls.
pause:
        mov     r0, r10
        bl      pauseControl

//Branches back to Read_SNES, which check if another button press have been made.
pauseRead_SNES:
        b       Read_SNES

//The win screen that is drawn on screen to indicate that you have won.
winCond:
        ldr     r9, =mushroomOnScreen     //Clears the extra life mushroom if it is on screen.
        ldr     r8, [r9]
        cmp     r8, #1
        bleq    clearPrevMRPos

        mov     r0, #0                    //Clears the entire screen, making it black.
        mov     r1, #0
        mov     r2, #1024
        mov     r3, #768
        bl      clearScreen

        bl      drawWinScreen             //Draws the win messages to the screen.

        ldr     r9, =gamemode             //Changes the gamemode to be 3, which is the win/lose controls.
        ldr     r8, [r9]
        mov     r8, #3
        str     r8, [r9]
        b       Read_SNES

//If no button was pressed branches back to read_SNES but if a button was pressed branches to start game which redraws the intro Mario screen.
returnWinLose:
        ldr     r4, =0xFFFF     //No buttons pressed
        cmp     r10, r4
        beq     readSNES

        b       startGame

//Data section
.section        .data

//The label that contains the current gamemode that corresponds to different controls.
.globl gamemode
gamemode:
        .int 0

//The label that contains the current worldCounter that corresponds to current level Mario is in.
.globl worldCounter
worldCounter:
        .int 0

//The label that contains Mario's X position.
.globl marioX
marioX:
        .int 0, 64

//The label that contains Mario's Y position.
.globl marioY
marioY:
        .int 640, 704

//The label that contains Mario's coordinates to be cleared when he moves.
.globl marioPECE
marioPECE:
        .int 0, 4, 60, 64

//The label that contains if Mario is looking right.
.globl marioRight
marioRight:
        .int 1

//The label that contains the number of times Mario moves when a direction move is pressed.
.globl moveCounter
moveCounter:
        .int 0

//The label that contains Mario's coordinates to be cleared when he jumps.
.globl marioPECEjump
marioPECEjump:
        .int 688, 704

//These are all the labels retaining to Mario's normal and arc jump.

.globl midjump
midjump:
        .int 0

.globl arcRight
arcRight:
        .int 0

.globl arcLeft
arcLeft:
        .int 0

.globl arcCounter
arcCounter:
        .int 0

.globl arcX
arcX:
        .int 0

.globl changeCurve
changeCurve:
        .int 0

gravityValCounter:
        .int 16, 15, 15, 14, 14, 13, 13, 12, 12, 11, 11, 10, 10, 9, 9, 8, 8, 7, 7, 6, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1, 1

.globl gravityCounter
gravityCounter:
        .int 0

.globl arcBool
arcBool:
        .int 0

.globl movedClimax
movedClimax:
        .int 0

//This label contains if Mario is on a pipe or not.
.globl marioOnPipe
marioOnPipe:
        .int 0

//This label contains if Mario is in the pause menu or not.
.globl pauseBool
pauseBool:
        .int 0

//This label contains if Mario is on the blocks or not.
.globl onBoxes
onBoxes:
        .int 0

//This label contains which breakable brick Mario can walk on.
standingOnHitBrick:
        .int 0, 0, 0

//This label contains which coins have appears on the screen.
.globl coinJustHit
coinJustHit:
        .int 0, 0, 0

//This label contians which coin blocks have been hit.
.globl mysteryBox
mysteryBox:
        .int 0, 0, 0

//This label contains which breakable bricks have been hit.
.globl hitBrick
hitBrick:
        .int 0, 0, 0
