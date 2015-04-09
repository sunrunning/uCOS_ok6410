#include <stdarg.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>

#include "config1.h"
#include "typedef1.h"
#include "s3c64x0.h"



#ifdef CONFIG_SERIAL1
#define UART_NR	S3C64XX_UART0

#elif defined(CONFIG_SERIAL2)
#define UART_NR	S3C64XX_UART1

#elif defined(CONFIG_SERIAL3)
#define UART_NR	S3C64XX_UART2

#elif defined(CONFIG_SERIAL4)
#define UART_NR	S3C64XX_UART3

#else
#error "Bad: you didn't configure serial ..."
#endif



//static int be_quiet = 0;

static S3C64XX_UART * S3C64XX_GetBase_UART(S3C64XX_UARTS_NR nr)
{
//	return (S3C64XX_UART *)(ELFIN_UART_BASE + (nr * 0x4000));
	return (S3C64XX_UART *)(ELFIN_UART_BASE + (nr*0x400));
}


void serial_putc(const char c)
{
	S3C64XX_UART *const uart = S3C64XX_GetBase_UART(UART_NR);

#ifdef CONFIG_MODEM_SUPPORT
	if (be_quiet)
		return;
#endif

	/* wait for room in the tx FIFO */
	while (!(uart->UTRSTAT & 0x2));

#ifdef CONFIG_HWFLOW
	/* Wait for CTS up */
	while (hwflow && !(uart->UMSTAT & 0x1));
#endif

	uart->UTXH = c;

	/* If \n, also do \r */
	if (c == '\n')
		serial_putc('\r');
}   

void Uart_SendString(char *s)
{
	while (*s) {
		serial_putc (*s++);
	}
}
void Uart_SendHex(unsigned long dat)
{
	char str[30];
	sprintf(str,"0x%08x ",dat);
	Uart_SendString(str);

}
void Uart_Printf(const char *fmt,...)
{
    va_list ap;
    char string[50];

    va_start(ap,fmt);
    vsprintf(string,fmt,ap);
    va_end(ap);
    Uart_SendString(string);
}
