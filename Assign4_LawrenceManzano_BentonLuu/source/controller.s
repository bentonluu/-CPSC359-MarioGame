//Text section
.section .text

//This function initializes the the GPIO line to be used for the SNES controller.
//Takes in 1 parameter: r0 is the line number to be initialized.
.globl Init_GPIO
Init_GPIO:
        cmp     r0, #9                          //Compare the value of the argument r0 with the immediate value 9
        bgt     useGPFSEL1                      //If the value of r0 is greater than 9, then branch to "useGPFSEL1"

        ldr     r4, =0x3F200000                 //Address for GPFSEL0
        b       contInit                        //Branch to "contInit"

useGPFSEL1:
        ldr     r4, =0x3F200004                 //Address for GPFSEL1
        sub     r0, #10                         //Subtract the value of r0 by 10, and save the result back to r0

contInit:
        mov     r5, #3                          //Move the immediate value 3 into r5
        mul     r6, r0, r5                      //Grabs proper index for pin by multiplying the pin number by 3.

        ldr     r7, [r4]                        //Load the proper level of GPFSEL into r7
        mov     r8, #7                          //(b0111) into r8
        lsl     r8, r6                          //LOGICAL SHIFT LEFT (0b0111) by the proper index for the pin.
        bic     r7, r8                          //Clear pin bits.
        mov     r9, r1                          //Move the value of the argument register r1 (input/output function code) into r9
        lsl     r9, r6                          //LOGICAL SHIFT LEFT the input/output code by the proper index for the pin
        orr     r7, r9                          //Set the appropriate pin function in r7.
        str     r7, [r4]                        //Write back to approriate level of GPFSEL.

        bx      lr                              //Return to calling code.


//This function writes to the LATCH line.
//Takes in 1 parameter: r0 is either 1 which is to write to the line or 0 which is to clear the line.
.globl writeLAT
writeLAT:                                    //Writes a bit to the GPIO latch line.
        cmp     r0, #1                          //Compares the value of the argument register r0 with 1
        bne     clearLAT                     //If the values are not equal, branch to "Clear_Latch"

        ldr     r4, =0x3F20001C                 //Load the address of 'GPIO Output Set Register 0' into r4
        lsl     r0, #9                          //LOGICAL SHIFT LEFT (0b0001) an amount of times equal to the LATCH pin number
        str     r0, [r4]                        //Store this binary value to 'GPIO Output Set Register 0'
        b       exitL                           //Branch to "exitL"

clearLAT:
        mov     r0, #1                          //Move the immediate value 1 into r0
        ldr     r4, =0x3F200028                 //Load the address of 'GPIO Output Clear Register 0' into r4
        lsl     r0, #9                          //LOGICAL SHIFT LEFT (0b0001) an amount of times equal to the LATCH pin number
        str     r0, [r4]                        //Store this binary value to 'GPIO Output Clear Register 0'

exitL:
        bx      lr                              //Return to calling code.

//This function writes to the CLOCK line.
//Takes in 1 parameter: r0 is either 1 which is to write to the line or 0 which is to clear the line.
.globl writeCLOCK
writeCLOCK:                                    //Writes a value to the GPIO clock line.
        cmp     r0, #1                          //Compares the value of the argument register r0 with 1
        bne     clearCLOCK                     //If the values are not equal, branch to "Clear_Clock"

        ldr     r4, =0x3F20001C                 //Load the address of 'GPIO Output Set Register 0' into r4
        lsl     r0, #11                         //LOGICAL SHIFT LEFT (0b0001) an amount of times equal to the CLOCK pin number
        str     r0, [r4]                        //Store this binary value to 'GPIO Output Set Register 0'
        b       exitC                           //Branch to "exitC"

clearCLOCK:
        mov     r0, #1                          //Move the immediate value 1 into r0
        ldr     r4, =0x3F200028                 //Load the address of 'GPIO Output Clear Register 0' into r4
        lsl     r0, #11                         //LOGICAL SHIFT LEFT (0b0001) an amount of times equal to the CLOCK pin number
        str     r0, [r4]                        //Store this binary value to 'GPIO Output Clear Register 0'

exitC:
        bx      lr                              //Return to calling code.

//This function reads the information for the SNES controller input from the user. 
.globl readDATA
readDATA:                                       //Read data function to read 1 or 0 on pin.
        mov     r0, #10                         //Pin#10 = DATA line.
        ldr     r2, =0x3F200000                 //Base GPIO register.
        ldr     r1, [r2, #52]                   //GPLEV0.
        mov     r3, #1                          //Moves 1 to r3.
        lsl     r3, r0                          //Align pin10 bit.
        and     r1, r3                          //Mask everything else using and operation.
        teq     r1, #0                          //Test if bit read was 0.
        moveq   r4, #0                          //If equal move 0 into r4.
        movne   r4, #1                          //If not equal move 1 into r4
        mov     r0, r4                          //Move returned bit into r0 to return.
        bx      lr                              //Branch and link to calling code.

//This function waits for a specific amount of time.
//Takes in 1 parameter: r0 the time interval to be waited for.
.globl Wait
Wait:   //Waits for a time interval passed in as a parameter.
        ldr     r4, =0x3F003004                       //Address of CL0.
        ldr     r5, [r4]                              //Read CL0.
        add     r5, r0                                //Add time interval.

waitLoop:
        ldr     r6, [r4]                              //Load address of CL0.
        cmp     r5, r6                                //Stops when CLO = r5.
        bhi     waitLoop                              //Branches to waitLoop if r5 is greater than CL0.

        bx      lr                                    //Return to calling code.
