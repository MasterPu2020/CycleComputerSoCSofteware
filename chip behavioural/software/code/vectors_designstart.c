/****************************************************************************
*  Copyright (c) 2011 by Michael Fischer. All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without 
*  modification, are permitted provided that the following conditions 
*  are met:
*  
*  1. Redistributions of source code must retain the above copyright 
*     notice, this list of conditions and the following disclaimer.
*  2. Redistributions in binary form must reproduce the above copyright
*     notice, this list of conditions and the following disclaimer in the 
*     documentation and/or other materials provided with the distribution.
*  3. Neither the name of the author nor the names of its contributors may 
*     be used to endorse or promote products derived from this software 
*     without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
*  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
*  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
*  THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
*  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
*  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
*  OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED 
*  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
*  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
*  SUCH DAMAGE.
*
****************************************************************************
*  History:
*
*  10.04.2011  mifi  First Version for the LPC1114
****************************************************************************/
#define __VECTORS_LPC1114_C__

/*=========================================================================*/
/*  DEFINE: All extern Data                                                */
/*=========================================================================*/
extern unsigned long _estack;

/*=========================================================================*/
/*  DEFINE: Prototypes                                                     */
/*=========================================================================*/
void ResetHandler(void);

void NMI_Handler (void) __attribute__((weak));
void HardFault_Handler (void) __attribute__((weak));
void MemManage_Handler (void) __attribute__((weak));
void BusFault_Handler (void) __attribute__((weak));
void UsageFault_Handler (void) __attribute__((weak));
void SVC_Handler (void) __attribute__((weak));
void DebugMon_Handler (void) __attribute__((weak));
void PendSV_Handler (void) __attribute__((weak));
void SysTick_Handler (void) __attribute__((weak));

void WAKEUP_IRQHandler (void) __attribute__((weak));
void C_CAN_IRQHandler (void) __attribute__((weak));
void SSP1_IRQHandler (void) __attribute__((weak));
void I2C_IRQHandler (void) __attribute__((weak));
void CT16B0_IRQHandler (void) __attribute__((weak));
void CT16B1_IRQHandler (void) __attribute__((weak));
void CT32B0_IRQHandler (void) __attribute__((weak));
void CT32B1_IRQHandler (void) __attribute__((weak));
void SSP0_IRQHandler (void) __attribute__((weak));
void UART_IRQHandler (void) __attribute__((weak));
void ADC_IRQHandler (void) __attribute__((weak));
void WDT_IRQHandler (void) __attribute__((weak));
void BOD_IRQHandler (void) __attribute__((weak));
void PIO_3_IRQHandler (void) __attribute__((weak));
void PIO_2_IRQHandler (void) __attribute__((weak));
void PIO_1_IRQHandler (void) __attribute__((weak));
void PIO_0_IRQHandler (void) __attribute__((weak));

/*=========================================================================*/
/*  DEFINE: All code exported                                              */
/*=========================================================================*/
/*
 * This is our vector table.
 */
__attribute__ ((section(".vectors"), used))
void (* const gVectors[])(void) = 
{
   (void (*)(void))((unsigned long)&_estack),
   ResetHandler,
   NMI_Handler,
   HardFault_Handler,
   MemManage_Handler,
   BusFault_Handler,
   UsageFault_Handler,
   0, 0, 0, 0,
   SVC_Handler,
   DebugMon_Handler,
   0,
   PendSV_Handler,
   SysTick_Handler,

   WAKEUP_IRQHandler,
   WAKEUP_IRQHandler,
   WAKEUP_IRQHandler,
   WAKEUP_IRQHandler,
   WAKEUP_IRQHandler,
   WAKEUP_IRQHandler,
   WAKEUP_IRQHandler,
   WAKEUP_IRQHandler,
   WAKEUP_IRQHandler,
   WAKEUP_IRQHandler,
   WAKEUP_IRQHandler,
   WAKEUP_IRQHandler,
   WAKEUP_IRQHandler,
   C_CAN_IRQHandler,
   SSP1_IRQHandler,
   I2C_IRQHandler,
   CT16B0_IRQHandler,
   CT16B1_IRQHandler,
   CT32B0_IRQHandler,
   CT32B1_IRQHandler,
   SSP0_IRQHandler,
   UART_IRQHandler,
   0, 0,
   ADC_IRQHandler,
   WDT_IRQHandler,
   BOD_IRQHandler,
   0,
   PIO_3_IRQHandler,
   PIO_2_IRQHandler,
   PIO_1_IRQHandler,
   PIO_0_IRQHandler
}; /* gVectors */

/*
 * And here are the weak interrupt handlers.
 */
void NMI_Handler (void) { while(1); }
void HardFault_Handler (void) { while(1); }
void MemManage_Handler (void) { while(1); }
void BusFault_Handler (void) { while(1); }
void UsageFault_Handler (void) { while(1); }
void SVC_Handler (void) { while(1); }
void DebugMon_Handler (void) { while(1); }
void PendSV_Handler (void) { while(1); }
void SysTick_Handler (void) { while(1); }

void WAKEUP_IRQHandler (void) { while(1); }
void C_CAN_IRQHandler (void) { while(1); }
void SSP1_IRQHandler (void) { while(1); }
void I2C_IRQHandler (void) { while(1); }
void CT16B0_IRQHandler (void) { while(1); }
void CT16B1_IRQHandler (void) { while(1); }
void CT32B0_IRQHandler (void) { while(1); }
void CT32B1_IRQHandler (void) { while(1); }
void SSP0_IRQHandler (void) { while(1); }
void UART_IRQHandler (void) { while(1); }
void ADC_IRQHandler (void) { while(1); }
void WDT_IRQHandler (void) { while(1); }
void BOD_IRQHandler (void) { while(1); }
void PIO_3_IRQHandler (void) { while(1); }
void PIO_2_IRQHandler (void) { while(1); }
void PIO_1_IRQHandler (void) { while(1); }
void PIO_0_IRQHandler (void) { while(1); }

/*** EOF ***/
