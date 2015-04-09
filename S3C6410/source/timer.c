#include "typedef1.h"
#include "config1.h"
#include "s3c64x0.h"

S3C64XX_TIMERS * S3C64XX_GetBase_TIMERS(void);

int timer_load_val = 0;


S3C64XX_TIMERS * S3C64XX_GetBase_TIMERS(void)
{
	return (S3C64XX_TIMERS *)ELFIN_TIMER_BASE;
}

unsigned long REG_LR_VALUE;
void  Timer4_ISR(void)
{
	unsigned long *p;
	unsigned long addr;
	
	S3C64XX_TIMERS *const timers = S3C64XX_GetBase_TIMERS();

	p = (unsigned long *)0x71200f00;;
	addr = *p;
	
	//Uart_Printf("..............Enter Timer4_ISR....................\n");
	//you can do something here.
	
	
	// 清除TIMER4中断标志
	timers->CSTAT |= 0x200;
	
	*p = 0;
	OSTimeTick();
}

int timer_init(void)
{
	S3C64XX_TIMERS *const timers = S3C64XX_GetBase_TIMERS();

	/* use PWM Timer 4 because it has no output */
	/* prescaler for Timer 4 is 16 */
	timers->TCFG0 = 0x0f00;
	if (timer_load_val == 0) {
		/*
		 * for 10 ms clock period @ PCLK with 4 bit divider = 1/2
		 * (default) and prescaler = 16. Should be 10390
		 * @33.25MHz and 15625 @ 50 MHz
		 */
		timer_load_val = get_PCLK() / (2 * 16 * 100);
	}
	
	Uart_Printf("timer_init timer_load_val= %x \n",timer_load_val);
	
	/* load value for 10 ms timeout */
	timers->TCNTB4 = timer_load_val;//timer_load_val;
	
	
	/* auto load, manual update of Timer 4 */
	timers->TCON = (timers->TCON & ~0x00700000) | TCON_4_AUTO | TCON_4_UPDATE;
	/* auto load, start Timer 4 */
	timers->TCON = (timers->TCON & ~0x00700000) | TCON_4_AUTO | COUNT_4_ON;





	pISR_TIMER4 = Timer4_ISR;

	return (0);
}


S3C64XX_INTERRUPT * S3C64XX_GetBase_INTC0(void)
{
	return (S3C64XX_TIMERS *)ELFIN_VIC0_BASE;
}
S3C64XX_INTERRUPT * S3C64XX_GetBase_INTC1(void)
{
	return (S3C64XX_TIMERS *)ELFIN_VIC1_BASE;
}

extern char __ENTRY[];
void ISRInit(void)
{
	int i;
	unsigned long *p;
	
	S3C64XX_INTERRUPT *const interrupt0 = S3C64XX_GetBase_INTC0();
	S3C64XX_INTERRUPT *const interrupt1 = S3C64XX_GetBase_INTC1();
	S3C64XX_TIMERS *const timers = S3C64XX_GetBase_TIMERS();
	
	
	p = (unsigned long *)0x71200100;;
	for(i=0;i<32;i++)	
	{
		*p = __ENTRY+0x18;
		p ++ ;
	}
	p = (unsigned long *)0x71200100;;
	Uart_Printf("VIC0 ISR  = %x\n",*p);
		
	p = 	(unsigned long *)0x71300100;
	Uart_Printf("p = %x \n",p);
	for(i=0;i<32;i++)	
	{
		*p = __ENTRY+0x18;	
		p ++;
	}
		
	p = (unsigned long *)0x71300100;;
	Uart_Printf("VIC1 ISR  = %x\n",*p);
	
	// 所有中断均为IRQ中断
	interrupt0->INTSELECT = 0x00000000;		
	interrupt1->INTSELECT = 0x00000000;

	// 打开TIMER4中断允许
	timers->CSTAT |= 0x10;
	
	interrupt0->INTENABLE |= (1<<28);	
	
 }
 