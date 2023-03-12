/*=========================================================================*/
/*  C Run-Time for bare metal DesignStart M0                               */
/*  - assumes all memory is equal so we can run code from the text segment */
/*=========================================================================*/

#include <stdint.h>

/*=========================================================================*/
/*  DEFINE: All extern Data                                                */
/*=========================================================================*/
/* these are defined by the linker script */
extern unsigned long _sbss;
extern unsigned long _ebss;

/* This is the main */
extern int main (void);

/***************************************************************************/
/*  ResetHandler                                                           */
/*                                                                         */
/*  This is called before main and never returns                           */
/***************************************************************************/
void ResetHandler (void)
{
   uint32_t *pDest;
   
   /* BSS segment (if it exists) must be cleared before calling main */
   pDest = &_sbss;
   while(pDest < &_ebss)
   {
      *pDest++ = 0;
   }
   
   /* call main */       
   main();    
   
   /* This is an embedded program so won't terminate even if main returns */
   while(1) {};    

}
