#include "typedef1.h"
#include "config1.h"
#include "s3c64x0.h"


#define APLL 0
#define MPLL 1
#define EPLL 2



static unsigned long get_PLLCLK(int pllreg)
{
	unsigned long r, m, p, s;

	if (pllreg == APLL)
		r = APLL_CON_REG;
	else if (pllreg == MPLL)
		r = MPLL_CON_REG;
	else if (pllreg == EPLL)
		r = EPLL_CON0_REG;
	else
		;

	m = (r>>16) & 0x3ff;
	p = (r>>8) & 0x3f;
	s = r & 0x7;

	return (m * (CONFIG_SYS_CLK_FREQ / (p * (1 << s))));
}

/* return FCLK frequency */
unsigned long get_FCLK(void)
{
	return (get_PLLCLK(APLL));
}

/* return PCLK frequency */
unsigned long get_PCLK(void)
{
	unsigned long fclk;
	unsigned int hclkx2_div = ((CLK_DIV0_REG>>9) & 0x7) + 1;
	unsigned int pre_div = ((CLK_DIV0_REG>>12) & 0xf) + 1;

	if(OTHERS_REG & 0x80)
		fclk = get_FCLK();		// SYNC Mode
	else
		fclk = get_PLLCLK(MPLL);	// ASYNC Mode

	return fclk/(hclkx2_div * pre_div);
}