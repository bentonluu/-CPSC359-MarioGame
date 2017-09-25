//This function checks if Mario is within the hole boundary, if Mario is within the boundary Mario falling into the hole and if not returns back to main.
//This function takes no parameters.
.globl drop
drop:
        push    {lr}

        ldr     r9, =marioRight      //Checks if Mario is facing right. If not branches to dropLeft.
        ldr     r8, [r9]
        cmp     r8, #1
        bne     dropLeft

//If Mario is facing right and checks if Mario is within the drop boundary, if not returns back to main.
dropRight:
        ldr     r9, =marioX         //Checks if Mario's back is within the hole boundary.
        ldr     r8, [r9]
        cmp     r8, #512
        movge   r6, #1
        movlt   r6, #0

        ldr     r9, =marioX         //Checks if Mario's front is within the hole boundary.
        ldr     r8, [r9, #4]
        cmp     r8, #640
        movle   r5, #1
        movgt   r5, #0

        tst     r5, r6              //If both Mario's front and back are within the hole boundary branches to dropCond.
        bne     dropCond

        b       return

//If Mario is facing left and checks if Mario is within the drop boundary, if not returns back to main.
dropLeft:
        ldr     r9, =marioX         //Checks if Mario's back is within the hole boundary.
        ldr     r8, [r9]
        cmp     r8, #512
        movlt   r6, #0
        movge   r6, #1

        ldr     r9, =marioX         //Checks if Mario's front is within the hole boundary.
        ldr     r8, [r9, #4]
        cmp     r8, #640
        movgt   r5, #0
        movle   r5, #1

        tst     r5, r6              //If both Mario's front and back are within the hole boundary branches to dropCond.
        bne     dropCond

        b       return

//Clears the top of Mario and updates Mario's current position as he is falling into the hole.
dropLoop:
        ldr     r8, =marioX           //Draws a section of blue on the top of Mario
        ldr     r9, =marioDrop
        ldr     r0, [r8]
        ldr     r1, [r9]
        ldr     r2, [r8, #4]
        ldr     r3, [r9, #4]
        bl      drawBlue

        ldr     r9, =marioDrop        //Updates the coordinates of the marioDrop label by 8.
        ldr     r6, [r9]
        add     r6, #8
        str     r6, [r9]
        ldr     r6, [r9, #4]
        add     r6, #8
        str     r6, [r9, #4]

        ldr     r9, =marioY           //Updates Mario's Y coordinates.
        ldr     r6, [r9]
        add     r6, #8
        str     r6, [r9]
        ldr     r6, [r9, #4]
        add     r6, #8
        str     r6, [r9, #4]

//If Mario is falling right, he will be redrawn in the hole facing right.
fallRight:
        ldr     r9, =marioRight       //Checks if Mario is facing right. If not branches to fallLeft.
        ldr     r8, [r9]
        cmp     r8, #1
        bne     fallLeft

        ldr     r8, =marioY           //Redraws Mario facing right.
        ldr     r9, =marioX
        ldr     r0, [r9]
        ldr     r1, [r8]
        ldr     r2, [r9, #4]
        ldr     r3, [r8, #4]
        bl      drawMarioR

        b       dropLoopCont

//If Mario is falling left, he will be redrawn in the hole facing left.
fallLeft:
        ldr     r8, =marioY         //Redraws Mario facing left.
        ldr     r9, =marioX
        ldr     r0, [r9]
        ldr     r1, [r8]
        ldr     r2, [r9, #4]
        ldr     r3, [r8, #4]
        bl      drawMarioL

//Updates the drop counter, which keeps track of how far Mario is in the hole.
dropLoopCont:
        ldr     r9, =marioDropCounter     //Decrement marioDropCounter by 1.
        ldr     r8, [r9]
        sub     r8, #1
        str     r8, [r9]

//The drop animation for Mario, clears the top of Mario and redraws him until he is in the hole.
dropCond:
        ldr     r9, =marioDropCounter      //Loops back to dropLoop if the marioDropCounter is greater than 0.
        ldr     r8, [r9]
        cmp     r8, #0
        bgt     dropLoop

        ldr     r9, =marioDropCounter     //Resets marioDropCounter back to initial value.
        mov     r8, #8
        str     r8, [r9]

        ldr     r9, =marioY
        ldr     r8, [r9, #4]
        cmp     r8, #768
        b       dropCond2

//Clears the top of Mario when he is in the hole.
dropLoop2:
        ldr     r8, =marioX                 //Clears the top of Mario with the blue background.
        ldr     r9, =marioDrop
        ldr     r0, [r8]
        ldr     r1, [r9]
        ldr     r2, [r8, #4]
        ldr     r3, [r9, #4]
        bl      drawBlue

        ldr     r9, =marioDrop              //Updates the coordinates of the marioDrop label by 8.
        ldr     r6, [r9]
        add     r6, #8
        str     r6, [r9]
        ldr     r6, [r9, #4]
        add     r6, #8
        str     r6, [r9, #4]

        ldr     r9, =marioDropCounter       //Decrement marioDropCounter by 1.
        ldr     r8, [r9]
        sub     r8, #1
        str     r8, [r9]

//The animation to clear Mario when he is in the hole, restarts the levels, and calls to redraw the first level.
dropCond2:
        cmp     r8, #0                    //Loops back to dropLoop2 if the marioDropCounter is greater than 0.
        bgt     dropLoop2

        ldr     r9, =marioDropCounter     //Resets marioDropCounter back to initial value.
        mov     r8, #8
        str     r8, [r9]

        ldr     r9, =marioDrop            //Resets marioDrop back to its initial values.
        mov     r8, #640
        str     r8, [r9]
        mov     r8, #648
        str     r8, [r9, #4]

        ldr     r9, =marioX               //Resets Mario's X position.
        mov     r8, #0
        str     r8, [r9]
        mov     r8, #64
        str     r8, [r9, #4]

        ldr     r9, =marioY               //Resets Mario's Y position.
        mov     r8, #640
        str     r8, [r9]
        mov     r8, #704
        str     r8, [r9, #4]

        ldr     r9, =dropBool         //Sets the dropBool label, meaning that Mario has dropped into the hole.
        mov     r8, #1
        str     r8, [r9]

        ldr     r9, =killedGoomba     //Resets the killedGoomba label back to 0, meaning that the goomba is not killed.
        mov     r8, #0
        str     r8, [r9]

        ldr     r9, =coinJustHit      //Reset that the coins have appeared on the screen.
        mov     r8, #0
        str     r8, [r9]
        str     r8, [r9, #4]
        str     r8, [r9, #8]

        ldr     r9, =mysteryBox       //Reset that the coin blocks have been hit.
        str     r8, [r9]
        str     r8, [r9, #4]
        str     r8, [r9, #8]

        ldr     r9, =hitBrick         //Reset that the breakable brick have been hit.
        str     r8, [r9]
        str     r8, [r9, #4]
        str     r8, [r9, #8]

        bl      restart               //Resets the initial position of Mario.
        bl      decreaseLives         //Decrease Mario's lives by 1.

        ldr     r9, =marioLives       //Checks if Mario lives are 0. If so branches to return.
        ldr     r8, [r9]
        cmp     r8, #0
        beq     return
        bl      levelOne              //If Mario's lives are not 0, the first level is drawn.

        ldr     r9, =marioRight       //Set Mario so that he is facing right.
        mov     r8, #1
        str     r8, [r9]

        mov     r0, #0                //Redraws Mario on the ground on the leftmost side of the screen.
        mov     r1, #640
        mov     r2, #64
        mov     r3, #704
        bl      drawMarioR

//Returns back to calling code.
return:
        pop     {lr}
        bx      lr

//This function drops Mario when he is facing right, back to the ground when he is not standing on the pipe anymore.
//This function takes r0 as a parameter which is the number of times Mario needs to be cleared and redrawn in order to reach the ground.
.globl  dropPipeR
dropPipeR:
        push    {r0, lr}

        ldr     r9, =SPipeClear       //Sets the SPipeClear label is the coordinates for Mario to be cleared.
        mov     r8, #448
        str     r8, [r9]
        mov     r8, #464
        str     r8, [r9, #4]

        ldr     r9, =SPipeCounter     //Sets the SPipeCounter label to be the parameter passed into the function.
        mov     r8, r0
        str     r8, [r9]
        b       dropPipeCondR

//Clears the top of Mario and redraws him lower down facing right. Also checks if when he is falling if he touches the extra life mushroom.
dropPipeLoopR:
        ldr     r8, =marioX           //Clears the top of Mario, drawing the blue background.
        ldr     r9, =SPipeClear
        ldr     r0, [r8]
        ldr     r1, [r9]
        ldr     r2, [r8, #4]
        ldr     r3, [r9, #4]
        bl      drawBlue

        ldr     r9, =SPipeClear       //Updates the coordinates of the SPipeClear label by 16.
        ldr     r6, [r9]
        add     r6, #16
        str     r6, [r9]
        ldr     r6, [r9, #4]
        add     r6, #16
        str     r6, [r9, #4]

        ldr     r9, =marioY           //Updates the Y coordinates of Mario by 16.
        ldr     r6, [r9]
        add     r6, #16
        str     r6, [r9]
        ldr     r6, [r9, #4]
        add     r6, #16
        str     r6, [r9, #4]

        bl      checkMushroomHit_fall  //Checks if Mario hits the extra life mushroom when he is dropping.

        ldr     r8, =marioY         //Redraws Mario facing right on the ground.
        ldr     r9, =marioX
        ldr     r0, [r9]
        ldr     r1, [r8]
        ldr     r2, [r9, #4]
        ldr     r3, [r8, #4]
        bl      drawMarioR

        ldr     r9, =SPipeCounter     //Decrement the SPipeCounter by 1.
        ldr     r8, [r9]
        sub     r8, #1
        str     r8, [r9]

//Drops Mario from the height of the pipe down to the ground when he is no longer standing on the pipe.
dropPipeCondR:
        cmp     r8, #0              //Loops back to dropPipeLoopR if the SPipeCounter is greater than 0.
        bgt     dropPipeLoopR

        ldr     r9, =SPipeCounter    //Resets SPipeCounter back to its initial value.
        mov     r8, #12
        str     r8, [r9]

        ldr     r9, =marioOnPipe     //Set marioOnPipe label to be 0, meaning that he is not on the pipe anymore.
        mov     r8, #0
        str     r8, [r9]

        pop     {r0, lr}
        bx      lr                    //Return to calling code.

//This function drops Mario when he is facing left, back to the ground when he is not standing on the pipe anymore.
//This function takes r0 as a parameter which is the number of times Mario needs to be cleared and redrawn in order to reach the ground.
.globl  dropPipeL
dropPipeL:
        push    {r0, lr}

        ldr     r9, =SPipeClear           //Sets the SPipeClear label is the coordinates for Mario to be cleared.
        mov     r8, #448
        str     r8, [r9]
        mov     r8, #464
        str     r8, [r9, #4]

        ldr     r9, =SPipeCounter         //Sets the SPipeCounter label to be the parameter passed into the function.
        mov     r8, r0
        str     r8, [r9]
        b       dropPipeCondL

//Clears the top of Mario and redraws him lower down facing left. Also checks if when he is falling if he touches the extra life mushroom.
dropPipeLoopL:
        ldr     r8, =marioX             //Clears the top of Mario, drawing the blue background.
        ldr     r9, =SPipeClear
        ldr     r0, [r8]
        ldr     r1, [r9]
        ldr     r2, [r8, #4]
        ldr     r3, [r9, #4]
        bl      drawBlue

        ldr     r9, =SPipeClear         //Updates the coordinates of the SPipeClear label by 16.
        ldr     r6, [r9]
        add     r6, #16
        str     r6, [r9]
        ldr     r6, [r9, #4]
        add     r6, #16
        str     r6, [r9, #4]

        ldr     r9, =marioY             //Updates the Y coordinates of Mario by 16.
        ldr     r6, [r9]
        add     r6, #16
        str     r6, [r9]
        ldr     r6, [r9, #4]
        add     r6, #16
        str     r6, [r9, #4]

        bl      checkMushroomHit_fall   //Checks if Mario hits the extra life mushroom when he is dropping.

        ldr     r8, =marioY            //Redraws Mario facing left on the ground.
        ldr     r9, =marioX
        ldr     r0, [r9]
        ldr     r1, [r8]
        ldr     r2, [r9, #4]
        ldr     r3, [r8, #4]
        bl      drawMarioL

        ldr     r9, =SPipeCounter     //Decrement the SPipeCounter by 1.
        ldr     r8, [r9]
        sub     r8, #1
        str     r8, [r9]

//Drops Mario from the height of the pipe down to the ground when he is no longer standing on the pipe.
dropPipeCondL:
        cmp     r8, #0              //Loops back to dropPipeLoopR if the SPipeCounter is greater than 0.
        bgt     dropPipeLoopL

        ldr     r9, =SPipeCounter   //Resets SPipeCounter back to its initial value.
        mov     r8, #12
        str     r8, [r9]

        ldr     r9, =marioOnPipe    //Set marioOnPipe label to be 0, meaning that he is not on the pipe anymore.
        mov     r8, #0
        str     r8, [r9]

        pop     {r0, lr}
        bx      lr                  //Return to calling code.

//This function checks whether Mario is in the pipe boundary when he is walking, if he is off he will fall off the pipe, if he is on the pipe he will stay on.
//This function takes r0 as a parameter which is the number of times Mario needs to be cleared and redrawn in order to reach the ground.
.globl movePipeFall
movePipeFall:
        push    {r0, lr}
        mov     r7, r0                //Check if Mario is at the height of the pipe. If not branches back to returnMovePipe.
        ldr     r9, =marioY
        ldr     r8, [r9, #4]
        cmp     r8, #512
        bne     returnMovePipe

        ldr     r9, =marioRight       //Checks if Mario is looking right. If not branches to leftFallPipe.
        ldr     r8, [r9]
        cmp     r8, #1
        bne     leftFallPipe

        ldr     r9, =marioX           //Checks if Mario is off the pipe boundary of the first pipe, walking right.
        ldr     r8, [r9]
        cmp     r8, #640
        blt     dropAreaR

        cmp     r8, #768              //Checks if Mario is off the pipe boundary of the second pipe, walking right.
        mov     r0, r7
        blge    dropPipeR

        b       returnMovePipe

//If Mario is off the pipe boundary on the right side of the first pipe, he will fall to the ground.
dropAreaR:
        cmp     r8, #384            //Checks if Mario is off the pipe boundary of the first pipe, walking right.
        mov     r0, r7
        blge    dropPipeR

        b       returnMovePipe

//Drops Mario off the pipe to the ground if he is facing left and off the left side pipe boundary.
leftFallPipe:
        ldr     r9, =marioX        //Checks if Mario is off the pipe boundary of the first pipe, walking left.
        ldr     r8, [r9, #4]
        cmp     r8, #384
        blt     dropAreaL

        cmp     r8, #640           //Checks if Mario is off the pipe boundary of the second pipe, walking left.
        mov     r0, r7
        blle    dropPipeL

        b       returnMovePipe

//If Mario is off the pipe boundary on the left side of the first pipe, he will fall to the ground.
dropAreaL:
        cmp     r8, #256          //Checks if Mario is off the pipe boundary of the first pipe, walking left.
        mov     r0, r7
        blle    dropPipeL

//Returns to calling code.
returnMovePipe:
        pop     {r0, lr}
        bx      lr                //Return to calling code.

//Data section
.section        .data

//The clear parameters for Mario to be cleared by when he is standing within the hole boundary.
marioDrop:
        .int 640, 648

//The hole counter to drop Mario into the hole.
marioDropCounter:
        .int 8

//The counter when Mario is falling off the pipe.
SPipeCounter:
        .int 0

//The clear parameters for Mario to be cleared by when is he off the pipe boundary.
SPipeClear:
        .int 448, 464

//If set when Mario is standing within the hole boundary.
.globl dropBool
dropBool:
        .int 0
