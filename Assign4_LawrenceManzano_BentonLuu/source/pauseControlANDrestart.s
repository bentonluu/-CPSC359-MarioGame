//This function deal with all the controls for the pause menu of the Mario game.
//Takes in 1 parameter: r0 is the SNES controller buttons that have been pressed.
.globl  pauseControl
pauseControl:
        push    {lr}
        mov     r10, r0         //Buttons from Read_SNES

//Pressing right will move the pause mushroom selector from the left side (RESTART) to the right side (QUIT).
pauseRight:
        ldr     r4, =0xFF7F     //RIGHT
        cmp     r10, r4         //Checks if the right D-PAD was pressed if not branches to pauseLeft.
        bne     pauseLeft

        mov     r0, #352        //Clears the pause mushroom selector at its current position the left side (RESTART) of the pause menu.
        mov     r1, #224
        mov     r2, #384
        mov     r3, #256
        bl      clearPause

        mov     r0, #544        //Redraws the pause mushroom selector on the right side (QUIT) of the pause menu.
        ldr     r9, =pauseSel
        str     r0, [r9]
        mov     r1, #576
        bl      mushroomPause

//Pressing left will move the pause mushroom selector from the right side (QUIT) to the left side (RESTART).
pauseLeft:
        ldr     r4, =0xFFBF     //LEFT
        cmp     r10, r4
        bne     pauseStart      //Checks if the left D-PAD was pressed if not branches to pauseStart.

        mov     r0, #544        //Clears the pause mushroom selector at its current position the right side (QUIT) of the pause menu.
        mov     r1, #224
        mov     r2, #576
        mov     r3, #256
        bleq    clearPause

        mov     r0, #352        //Redraws the pause mushroom selector on the left side (RESTART) of the pause menu.
        ldr     r9, =pauseSel
        str     r0, [r9]
        mov     r1, #384
        bleq    mushroomPause

//Pressing start will clear the pause menu from the screen and change the gamemode back to the Mario controls.
pauseStart:
        ldr     r4, =0xFFF7
        cmp     r10, r4               //Checks if the start button was pressed if not branches to pauseA.
        bne     pauseA

        ldr     r9, =gamemode         //Changes the gamemode back to the Mario controls.
        ldr     r8, [r9]              //r8 has the value of gamemode
        mov     r8, #1
        str     r8, [r9]

        b       clearLineCond

//This will draw a blue square and increment the clear area of the pause menu.
pauseClearBody:
        ldr     r9, =clearArea         //Draw the blue square.
        ldr     r0, [r9]
        ldr     r1, [r9, #4]
        ldr     r2, [r9, #8]
        ldr     r3, [r9, #12]
        bl      drawBlue

        ldr     r9, =clearArea         //Increment the clearArea label by 64 (X coordinates).
        ldr     r8, [r9]
        add     r8, #64
        str     r8, [r9]
        ldr     r8, [r9, #8]
        add     r8, #64
        str     r8, [r9, #8]

        ldr     r9, =clearCounter     //Increment the clearCounter.
        ldr     r8, [r9]
        add     r8, #1
        str     r8, [r9]

//Loops to draw a line of blue squares to clear the pause menu from the screen.
pauseClearBodyCond:
        ldr     r9, =clearCounter     //Loops back to pauseClearBody if the clearCounter is less than 6.
        ldr     r8, [r9]
        cmp     r8, #6
        blt     pauseClearBody

        ldr     r9, =clearArea        //Increment the clearArea by 64 (Y coordinates) and resets the X coordinates.
        mov     r8, #320
        str     r8, [r9]
        ldr     r8, [r9, #4]
        add     r8, #64
        str     r8, [r9, #4]
        mov     r8, #384
        str     r8, [r9, #8]
        ldr     r8, [r9, #12]
        add     r8, #64
        str     r8, [r9, #12]

        ldr     r9, =clearCounter     //Resets clearCounter back to its initial value.
        mov     r8, #0
        str     r8, [r9]

        ldr     r9, =clearLine        //Increments clearLine by 1.
        ldr     r8, [r9]
        add     r8, #1
        str     r8, [r9]

//Loops to draw multiple lines of blue squares in order to clear the entire pause menu from the screen.
clearLineCond:
        ldr     r9, =clearLine         //Loops back to pauseClearBodyCond if the clearLine is less than 3.
        ldr     r8, [r9]
        cmp     r8, #3
        blt     pauseClearBodyCond

        ldr     r9, =clearLine         //Resets clearLine back to its initial value.
        mov     r8, #0
        str     r8, [r9]

        ldr     r9, =clearArea         //Resets clearArea back to its initial values.
        mov     r8, #320
        str     r8, [r9]
        mov     r8, #128
        str     r8, [r9, #4]
        mov     r8, #384
        str     r8, [r9, #8]
        mov     r8, #192
        str     r8, [r9, #12]

//Pressing the button A will either restart the game back to level one with initial starting values also reset or will return back to the intro menu.
pauseA:
        ldr     r4, =0xFEFF         //A
        cmp     r10, r4
        bne     return              //if pressed A and the mushroom is not at 176, then cont...

        ldr     r9, =pauseSel
        ldr     r8, [r9]            //r7 has the coord of the current mushroom location
        cmp     r8, #352
        bne     startGame

        ldr     r9, =gamemode
        ldr     r8, [r9]            //r8 has the value of gamemode
        mov     r8, #1
        str     r8, [r9]

        ldr     r9, =coinCount      //Resets the coin score counter.
        mov     r8, #0
        str     r8, [r9]

        ldr     r9, =scoreCount     //Resets the score counter.
        str     r8, [r9]

        ldr     r9, =killedGoomba   //Resets that the goomba was not killed.
        mov     r8, #0
        str     r8, [r9]

        ldr     r9, =coinJustHit    //Resets the coins that have been hit from the coin blocks.
        mov     r8, #0
        str     r8, [r9]
        str     r8, [r9, #4]
        str     r8, [r9, #8]

        ldr     r9, =mysteryBox     //Resets the coin blocks that have been hit by Mario.
        mov     r8, #0
        str     r8, [r9]
        str     r8, [r9, #4]
        str     r8, [r9, #8]

        ldr     r9, =hitBrick       //Resets the breakable bricks that have been hit by Mario.
        mov     r8, #0
        str     r8, [r9]
        str     r8, [r9, #4]
        str     r8, [r9, #8]

        ldr     r9, =marioLives     //Resets the number of lives back to 3 for Mario.
        mov     r8, #3
        str     r8, [r9]

        bl      restart             //Resets the initial position of Mario.
        bl      startNumbers        //Redraws the initial score, coin score and lives.
        bl      levelOne            //Redraws level one.

        ldr     r9, =worldCounter   //Sets the worldCounter back to level one.
        mov     r8, #0
        str     r8, [r9]

        mov     r0, #0              //Redraws Mario on the ground on the leftmost side of the screen.
        mov     r1, #640
        mov     r2, #64
        mov     r3, #704
        bl      drawMarioR

//Return to calling code.
return:
        pop     {lr}
        bx      lr

//This function restarts the position of Mario which include his movement and jumping. Also resets the position of where the mushroom selector are.
.globl restart
restart:
        push    {lr}

        ldr     r9, =marioX         //Resets Mario current X position facing right.
        mov     r8, #0
        str     r8, [r9]
        mov     r8, #64
        str     r8, [r9, #4]

        ldr     r9, =marioY         //Resets Mario current Y position facing right.
        mov     r8, #640
        str     r8, [r9]
        mov     r8, #704
        str     r8, [r9, #4]

        ldr     r9, =marioPECE      //Resets Mario's clear values as he is walking facing right.
        mov     r8, #0
        str     r8, [r9]
        mov     r8, #4
        str     r8, [r9, #4]
        mov     r8, #60
        str     r8, [r9, #8]
        mov     r8, #64
        str     r8, [r9, #12]

        b       restartCont

//The restart when Mario is transition back to a previous level, he will appear on the right side of the screen facing left, instead of the left side facing right like normal.
.globl restartLeft
restartLeft:
        push    {lr}

        ldr     r9, =marioX           //Resets Mario current X position facing left.
        mov     r8, #960
        str     r8, [r9]
        mov     r8, #1024
        str     r8, [r9, #4]

        ldr     r9, =marioY           //Resets Mario current Y position facing left.
        mov     r8, #640
        str     r8, [r9]
        mov     r8, #704
        str     r8, [r9, #4]

        ldr     r9, =marioPECE        //Resets Mario's clear values as he is walking facing left.
        mov     r8, #960
        str     r8, [r9]
        mov     r8, #964
        str     r8, [r9, #4]
        mov     r8, #1020
        str     r8, [r9, #8]
        mov     r8, #1024
        str     r8, [r9, #12]

        ldr     r9, =marioRight
        mov     r8, #0
        str     r8, [r9]

//Resetting Mario's jump values and the position of the mushroom selectors back to their initial values.
restartCont:
        ldr     r9, =marioPECEjump      //Resets Mario's clear values as he is jumping.
        mov     r8, #688
        str     r8, [r9]
        mov     r8, #704
        str     r8, [r9, #4]

        ldr     r9, =moveCounter
        mov     r8, #0
        str     r8, [r9]

        ldr     r9, =pauseSel           //Resets the position of the pause mushroom selector.
        mov     r8, #352
        str     r8, [r9]

        ldr     r9, =selector           //Resets the position of the intro mushroom selector.
        mov     r8, #160
        str     r8, [r9]

        ldr     r9, =marioOnPipe        //Resets that Mario is not on the pipe anymore.
        mov     r8, #0
        str     r8, [r9]

        //Resets all the arc/normal jump values back to its initial values.

        ldr     r9, =midjump
        str     r8, [r9]

        ldr     r9, =arcRight
        str     r8, [r9]

        ldr     r9, =arcLeft
        str     r8, [r9]

        ldr     r9, =arcCounter
        str     r8, [r9]

        ldr     r9, =arcX
        str     r8, [r9]

        ldr     r9, =changeCurve
        str     r8, [r9]

        ldr     r9, =gravityCounter
        str     r8, [r9]

        ldr     r9, =arcBool
        str     r8, [r9]

        ldr     r9, =movedClimax
        str     r8, [r9]

        ldr     r9, =mushroomOnScreen       //Resets if the extra life mushroom is not on screen.
        mov     r8, #0
        str     r8, [r9]

        pop     {lr}
        bx      lr                          //Return to calling code.

//Data section
.section        .data

//The label that contains position of the pause mushroom selector.
.globl pauseSel
pauseSel:
        .int 352

//The label that has the number of lines needed to clear the pause menu from the screen.
clearLine:
        .int 0

//The label that has the number of blue squares in a line to clear a section of the pause menu from the screen.
clearCounter:
        .int 0

//The label that contains the initial position of the first blue square that will clear the pause menu from the screen.
clearArea:
        .int 320, 128, 384, 192
