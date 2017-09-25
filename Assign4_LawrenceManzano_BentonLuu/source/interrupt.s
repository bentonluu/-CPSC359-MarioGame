.globl InstallIntTable
InstallIntTable:
        push		{r0-r12, lr}
	ldr		r0, =IntTable
	mov		r1, #0x00000000

	// load the first 8 words and store at the 0 address
	ldmia	r0!, {r2-r9}
	stmia	r1!, {r2-r9}

	// load the second 8 words and store at the next address
	ldmia	r0!, {r2-r9}
	stmia	r1!, {r2-r9}

	// switch to IRQ mode and set stack pointer
	mov		r0, #0xD2
	msr		cpsr_c, r0
	mov		sp, #0x8000

	// switch back to Supervisor mode, set the stack pointer
	mov		r0, #0xD3
	msr		cpsr_c, r0
	mov		sp, #0x8000000

      //  pop		{r0-r12, lr}
	bx		lr


.globl Interrupt
Interrupt:
        ldr     r4, =0x3F003004			//this block of code essentially: 
        ldr     r5, [r4]				//(1)grabs the current time from CLO
        ldr     r6, =0x1C9C380
        add     r5, r6					//(2)adds 30 seconds to the current time
        ldr     r7, =0x3F003010
        str     r5, [r7]				//(3)and stores this added time value into C1

        ldr     r4, =0x3F00B210			// Enable IRQs 1
		ldr		r5, =0xA				// bits 1 and 3 set (IRQs 49 to 52)
		str		r5, [r4]

        ldr     r0, =0x3F00B214			//disables all other interrupts
        mov     r1, #0
        str     r1, [r0]

		mrs	r4, cpsr					// Enable IRQ
		bic	r4, #0x80
		msr	cpsr_c, r4

        bx      lr

.globl irq
irq:
        push	{r0-r12, lr}  
        
        ldr     r0, =0x3F00B204			//tests if timer1 did the interrupt
        ldr     r1, [r0]
        ldr     r2, =0x2  				
        tst     r1, r2					//if the first bit was not set then the interrupt was not brought up so branch to EnableCS
        beq     EnableCS

        ldr     r0, =gamemode			//if the gamemode is anything but startgame, branch to EnableCS
        ldr     r1, [r0]
        cmp     r1, #1
        bne     EnableCS

DrawShroom:
        push    {r0-r8, lr}				//push registers r0 to r8 and link register to stack
        ldr     r4, =mushroomOnScreen
        ldr     r5, [r4]					//r5 holds the boolean value of a life mushroom currently visible on screen
        cmp     r5, #1
        bne     contRandomGeneration		//if one is not drawn on the screen then branch to contRandomGeneration

        bl      clearPrevMRPos				//otherwise, branch and link to clearPrevMRPos

contRandomGeneration:	//the following code below is responsible for the random number creation of the interrupts
        ldr     r0, =w					
        ldr     r4, [r0]			//r4 holds the value of w

        ldr     r1, =x
        ldr     r5, [r1]			//r5 holds the value of x

        ldr     r2, =y
        ldr     r6, [r2]			//r6 holds the value of y

        ldr     r3, =z
        ldr     r7, [r3]			//r7 holds the value of z
        
        mov     r8, r6                  //move the value of r6 into r8
        eor     r8, r8, r8, LSL #11		//XOR operation between r8 and (r8 logical shift left 11 bits); save the result back to r8
        eor     r8, r8, r8, LSR #8		//XOR operation between r8 and (r8 logical shift right 8 bits); save the result back to r8
        
        mov     r7, r6				//move the value of r6 into r7
        mov     r6, r5				//move the value of r6 into r5
        mov     r5, r4				//move the value of r5 into r4
        
        eor     r8, r8, r4				//XOR operation between r8 and r4l save the result back to r8
        eor     r4, r8, r4, LSR #19     //XOR operation between r8 and (r4 logical shift right 19 bits)

        str     r4, [r0]			//store the new values of r4, r5, r6, r7
        str     r5, [r1]
        str     r6, [r2]
        str     r7, [r3]

        mov     r6, #1024			//move 1024 into r6
        sub     r6, #42				//subtract 42 from r6
        udiv    r5, r4, r6			//do an unsigned division of the random number and r6
        cmp     r5, #1				//if the obtained quotient is less than or equal to 1, branch to spawnBounds
        ble     spawnBounds

        mul     r5, r6				//otherwise, multiply r5 by r6; save the result back to r5
        sub     r4, r5				//subtract r4 (the random number) by r5; save the result back to r4

spawnBounds:
        add     r5, r4, #42         //right side of the mushroom
        
        ldr     r7, =marioX
        ldr     r8, [r7]			//r8 is the left side of Mario
        
        cmp     r5, r8				//compare the right side of the mushroom with the left side of Mario
        movgt   r6, #1				//if greater than then set r6 to true, otherwise false
        movle   r6, #0

        ldr     r8, [r7, #4]		//r8 is the right side of Mario
        
        cmp     r4, r8				//compare the right side of Mario with the left side of the mushroom
        movlt   r7, #1				//if less than then set r7 to true, otherwise false
        movge   r7, #0

        tst     r6, r7					//checks if Mario and mushroom will collide, if so branch to contRandomGeneration
        bne     contRandomGeneration

        cmp     r4, #0					//compares the left side of the mushroom with 0
        blt     contRandomGeneration	//if less than then branch to contRandomGeneration

        cmp     r5, #1024				//compare the right side of the mushroom with 1024
        bgt     contRandomGeneration	//if greater than then branch to contRandomGeneration

        ldr     r7, =worldCounter		
        ldr     r8, [r7]				//r8 holds the value of worldCounter
        cmp     r8, #0					//if greater than zero then branch to checkIfLevel2
        bgt     checkIfLevel2

        cmp     r5, #272				//The following code below checks if Mario will hit any obstacles located in the first level.
        movgt   r6, #1					//These obstacles are the gumba and the pit.
        movle   r6, #0					//Given that the generated random number is left side of the mushroom, if the mushroom collides with any of these
										//obstacles, a new random number will be generated until no collisions occur

        cmp     r4, #320
        movlt   r7, #1
        movge   r7, #0

        tst     r6, r7
        bne     contRandomGeneration

        cmp     r5, #512
        movgt   r6, #1
        movle   r6, #0

        cmp     r4, #640
        movlt   r7, #1
        movge   r7, #0  

        tst     r6, r7
        bne     contRandomGeneration

        b       drawUsingRandom    		//when no collisions are found, branch to drawUsingRandom

checkIfLevel2:
        cmp     r8, #2					//The following code below checks if Mario will hit any obstacles located in the third level.
        bgt     checkIfLevel3			//These obstacles are the two pipes.
										//Given that the generated random number is left side of the mushroom, if the mushroom collides with any of these
										//obstacles, a new random number will be generated until no collisions occur
        cmp     r5, #256
        movgt   r6, #1
        movle   r6, #0

        cmp     r4, #384
        movlt   r7, #1
        movge   r7, #0  

        tst     r6, r7
        bne     contRandomGeneration

        cmp     r5, #640
        movgt   r6, #1
        movle   r6, #0

        cmp     r4, #768
        movlt   r7, #1
        movge   r7, #0
        
        tst     r6, r7
        bne     contRandomGeneration
        
        b       drawUsingRandom			//when no collisions are found, branch to drawUsingRandom
        
checkIfLevel3:
        cmp     r5, #272				//The following code below checks if Mario will hit any obstacles located in the fourth level.
        movgt   r6, #1					//These obstacles are the spiky turtle and castle
        movle   r6, #0					//Given that the generated random number is left side of the mushroom, if the mushroom collides with any of these
										//obstacles, a new random number will be generated until no collisions occur
		
        cmp     r4, #320
        movlt   r7, #1
        movge   r7, #0  

        tst     r6, r7
        bne     contRandomGeneration

        cmp     r5, #704
        bgt     contRandomGeneration

drawUsingRandom:
        //r4 is the final random number at this point
        mov     r0, r4
        mov     r2, r5
        mov     r3, #704
        sub     r1, r3, #42
        bl      drawLifeMushroom	//draws a life mushroom given the random number being the starting x position and y-coordinates making it so the mushroom is on the ground

        ldr     r6, =mushroom_xPos	//stores the x-coordinates of the mushroom into mushroom_xPos
        str     r4, [r6]
        str     r5, [r6, #4]

        ldr     r4, =mushroomOnScreen	//store a 1 (true) the mushroomOnScreen label indicating a mushroom is currently visible on screen
        mov     r5, #1
        str     r5, [r4]
        
        pop     {r0-r8, lr}			//pop registers r0 to r8 and link register from stack

EnableCS:
        ldr     r4, =0x3F003000		//address of CS
        ldr     r6, =0x2			
        str     r6, [r4]			//places a 1 in bit 1 of the CS timer control

        bl      Interrupt			//branch and link to the Interrupt subroutine

        pop	{r0-r12, lr}			//pop registers r0 to r12 and link register from the stack
        subs    pc, lr, #4			//return from this subroutine call
        

.section        .data
IntTable:
	// Interrupt Vector Table (16 words)
	ldr		pc, reset_handler
	ldr		pc, undefined_handler
	ldr		pc, swi_handler
	ldr		pc, prefetch_handler
	ldr		pc, data_handler
	ldr		pc, unused_handler
	ldr		pc, irq_handler
	ldr		pc, fiq_handler


reset_handler:		.word InstallIntTable
undefined_handler:	.word haltLoop$
swi_handler:		.word haltLoop$
prefetch_handler:	.word haltLoop$
data_handler:		.word haltLoop$
unused_handler:		.word haltLoop$
irq_handler:		.word irq
fiq_handler:		.word haltLoop$

.globl  w
w:      .int 4
x:      .int 8
y:      .int 12
z:      .int 16

.globl  mushroom_xPos
mushroom_xPos:
        .int 0, 0

.globl  mushroomOnScreen
mushroomOnScreen:
        .int 0

