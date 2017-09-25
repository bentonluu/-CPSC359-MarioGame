//This function deal with all the controls for the intro of the Mario game.
//Takes in 1 parameter: r0 is the SNES controller buttons that have been pressed.
.globl introControl
introControl:
        push    {lr}
        mov     r10, r0         //Buttons from Read_SNES

//Pressing right will move the mushroom selector from the left side (START) to the right side (QUIT).
introRight:
        ldr     r4, =0xFF7F     //RIGHT
        cmp     r10, r4
        bne     introLeft       //Checks if the right D-PAD was pressed if not branches to introLeft.

        mov     r0, #160        //Clears the intro mushroom selector at its current position the left side (START) of the intro menu.
        mov     r1, #480
        mov     r2, #224
        mov     r3, #544
        bleq    drawBlue

        mov     r0, #544        //Redraws the intro mushroom selector on the right side (QUIT) of the intro menu.
        ldr     r9, =selector
        str     r0, [r9]
        mov     r1, #608
        bleq    mushroomSelector

//Pressing left will move the mushroom selector from the right side (QUIT) to the left side (START).
introLeft:
        ldr     r4, =0xFFBF     //LEFT
        cmp     r10, r4
        bne     introA          //Checks if the right D-PAD was pressed if not branches to introA.

        mov     r0, #544        //Clears the intro mushroom selector at its current position the right side (QUIT) of the intro menu.
        mov     r1, #480
        mov     r2, #608
        mov     r3, #544
        bleq    drawBlue

        mov     r0, #160        //Redraws the intro mushroom selector on the left side (START) of the intro menu.
        ldr     r9, =selector
        str     r0, [r9]
        mov     r1, #224
        bleq    mushroomSelector

//Pressing A depending on the position of the mushroom selection will either start the Mario game or quit the game and clear the screen.
introA:
        ldr     r4, =0xFEFF         //A
        ldr     r9, =selector
        ldr     r7, [r9]            //r7 has the coord of the current mushroom location.
        cmp     r10, r4
        bne     returnIntro         //If pressed A and the mushroom is not at 176, then continue.
        cmp     r7, #160
        bne     quitGame

//If the button A was pressed when the mushroom selector is on START, then the first level will be drawn with Mario and the gamemode will be switch to the Mario controls for the game.
changeGS:
        bl      restart             //Resets the initial position of Mario.
        bl      levelOne            //Redraws the first level.

        mov     r0, #0              //Redraws Mario on the ground on the leftmost side of the screen.
        mov     r1, #640
        mov     r2, #64
        mov     r3, #704
        bleq    drawMarioR

        mov     r0, #1              //Return 1 so that the gamemode changes to the Mario controls.
        b       return

//If the button A was not pressed the gamemode does not change and 0 (gamestate for intro controls) is returned.
returnIntro:
        mov     r0, #0

//Return to calling code.
return:
        pop     {lr}
        bx      lr                  //Return to calling code.

//This clears the screen when the button A was pressed when the mushroom selector is on QUIT.
.globl quitGame
quitGame:
        mov     r0, #0              //Clears the screen with black.
        mov     r1, #0
        mov     r2, #1024
        mov     r3, #768
        bl      clearScreen

//This is an infinite loop that halts interaction with the program.
.globl haltLoop$
haltLoop$:
	     b	      haltLoop$

//Data section
.section .data

//The current position of the mushroom selector.
.globl selector
selector:
        .int 160
