//This function drops Mario when he is facing right, back to the ground when he is not standing on the block anymore.
//This function takes in 3 parameters:
//r0 the number of times Mario needs to be cleared and redrawn in order to reach the ground.
//r1 the Y position of Mario (top).
//r2 the Y position of Mario to be clear from the top of Mario.
.globl  dropBlockR
dropBlockR:
        push    {r0-r2, lr}

        ldr     r9, =BlockClear         //Sets the BlockClear label is the coordinates for Mario to be cleared, with the parameters passed in.
        mov     r8, r1
        str     r8, [r9]
        mov     r8, r2
        str     r8, [r9, #4]

        ldr     r9, =BlockCounter        //Sets the BlockCounter label to be the parameter passed into the function.
        mov     r8, r0
        str     r8, [r9]
        b       dropBlockCondR

//Clears the top of Mario and redraws him lower down facing right. Also checks if when he is falling if he touches the extra life mushroom.
dropBlockLoopR:
        ldr     r8, =marioX             //Clears the top of Mario, drawing the blue background.
        ldr     r9, =BlockClear
        ldr     r0, [r8]
        ldr     r1, [r9]
        ldr     r2, [r8, #4]
        ldr     r3, [r9, #4]
        bl      drawBlue

        ldr     r9, =BlockClear         //Updates the coordinates of the BlockClear label by 16.
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

        bl      checkMushroomHit_fall     //Checks if Mario hits the extra life mushroom when he is dropping.

        ldr     r8, =marioY             //Redraws Mario facing right on the ground.
        ldr     r9, =marioX
        ldr     r0, [r9]
        ldr     r1, [r8]
        ldr     r2, [r9, #4]
        ldr     r3, [r8, #4]
        bl      drawMarioR

        ldr     r9, =BlockCounter       //Decrement the BlockCounter by 1.
        ldr     r8, [r9]
        sub     r8, #1
        str     r8, [r9]

//Drops Mario from the height of the block down to the ground when he is no longer standing on the block.
dropBlockCondR:
        cmp     r8, #0                //Loops back to dropBlockLoopR if the BlockCounter is greater than 0.
        bgt     dropBlockLoopR

        ldr     r9, =onBoxes          //Set onBoxes label to be 0, meaning that he is not on the blocks anymore.
        mov     r8, #0
        str     r8, [r9]

        pop     {r0-r2, lr}
        bx      lr                    //Return to calling code.

//This function drops Mario when he is facing left, back to the ground when he is not standing on the block anymore.
//This function takes in 3 parameters:
//r0 the number of times Mario needs to be cleared and redrawn in order to reach the ground.
//r1 the Y position of Mario (top).
//r2 the Y position of Mario to be clear from the top of Mario.
.globl  dropBlockL
dropBlockL:
        push    {r0-r2, lr}

        ldr     r9, =BlockClear       //Sets the BlockClear label is the coordinates for Mario to be cleared, with the parameters passed in.
        mov     r8, r1
        str     r8, [r9]
        mov     r8, r2
        str     r8, [r9, #4]

        ldr     r9, =BlockCounter     //Sets the BlockCounter label to be the parameter passed into the function.
        mov     r8, r0
        str     r8, [r9]
        b       dropBlockCondL

//Clears the top of Mario and redraws him lower down facing left. Also checks if when he is falling if he touches the extra life mushroom.
dropBlockLoopL:
        ldr     r8, =marioX           //Clears the top of Mario, drawing the blue background.
        ldr     r9, =BlockClear
        ldr     r0, [r8]
        ldr     r1, [r9]
        ldr     r2, [r8, #4]
        ldr     r3, [r9, #4]
        bl      drawBlue

        ldr     r9, =BlockClear       //Updates the coordinates of the BlockClear label by 16.
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

        bl      checkMushroomHit_fall   //Checks if Mario hits the extra life mushroom when he is dropping.

        ldr     r8, =marioY           //Redraws Mario facing left on the ground.
        ldr     r9, =marioX
        ldr     r0, [r9]
        ldr     r1, [r8]
        ldr     r2, [r9, #4]
        ldr     r3, [r8, #4]
        bl      drawMarioL

        ldr     r9, =BlockCounter    //Decrement the BlockCounter by 1.
        ldr     r8, [r9]
        sub     r8, #1
        str     r8, [r9]

//Drops Mario from the height of the block down to the ground when he is no longer standing on the block.
dropBlockCondL:
        cmp     r8, #0              //Loops back to dropBlockLoopR if the BlockCounter is greater than 0.
        bgt     dropBlockLoopL

        ldr     r9, =onBoxes        //Set onBoxes label to be 0, meaning that he is not on the blocks anymore.
        mov     r8, #0
        str     r8, [r9]

        pop     {r0-r2, lr}
        bx      lr                  //Return to calling code.

//Data section
.section        .data

//The label to be set by the parameter passed in used to clear and redraw Mario from the blocks to the ground.
BlockCounter:
        .int 0

//The label to be set by the parameters passed in used to clear Mario when he is falling from the blocks.
BlockClear:
        .int 0, 0
