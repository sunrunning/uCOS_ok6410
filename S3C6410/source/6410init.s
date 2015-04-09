;=========================================
; NAME: 2440INIT.S
; DESC: C start up codes
;       Configure memory, ISR ,stacks
;	Initialize C-variables
; HISTORY:
; 2002.02.25:kwtark: ver 0.0
; 2002.03.20:purnnamu: Add some functions for testing STOP,Sleep mode
; 2003.03.14:DonGo: Modified for 2440.
;=========================================

	GET option.inc
;	GET memcfg.inc
;	GET 2440addr.inc

BIT_SELFREFRESH EQU	(1<<22)

;Pre-defined constants
USERMODE    EQU 	0x10
FIQMODE     EQU 	0x11
IRQMODE     EQU 	0x12
SVCMODE     EQU 	0x13
ABORTMODE   EQU 	0x17
UNDEFMODE   EQU 	0x1b
MODEMASK    EQU 	0x1f
NOINT       EQU 	0xc0

;The location of stacks
UserStack	EQU	(_STACK_BASEADDRESS-0x3800)	;0x33ff4800 ~
SVCStack	EQU	(_STACK_BASEADDRESS-0x2800)	;0x33ff5800 ~
UndefStack	EQU	(_STACK_BASEADDRESS-0x2400)	;0x33ff5c00 ~
AbortStack	EQU	(_STACK_BASEADDRESS-0x2000)	;0x33ff6000 ~
IRQStack	EQU	(_STACK_BASEADDRESS-0x1000)	;0x33ff7000 ~
FIQStack	EQU	(_STACK_BASEADDRESS-0x0)	;0x33ff8000 ~


INTOFFSET	EQU  0x4a000014    ;Interruot request source offset




; :::::::::::::::::::::::::::::::::::::::::::::
;           BEGIN: Power Management 
; - - - - - - - - - - - - - - - - - - - - - - -
Mode_USR            EQU     0x10
Mode_FIQ            EQU     0x11
Mode_IRQ            EQU     0x12
Mode_SVC            EQU     0x13
Mode_ABT            EQU     0x17
Mode_UND            EQU     0x1B
Mode_SYS            EQU     0x1F

I_Bit               EQU     0x80
F_Bit               EQU     0x40
; - - - - - - - - - - - - - - - - - - - - - - -
;Check if tasm.exe(armasm -16 ...@ADS 1.0) is used.
	GBLL    THUMBCODE
	[ {CONFIG} = 16
THUMBCODE SETL  {TRUE}
	    CODE32
 		|
THUMBCODE SETL  {FALSE}
    ]

 		MACRO
	MOV_PC_LR
 		[ THUMBCODE
	    bx lr
 		|
	    mov	pc,lr
 		]
	MEND

 		MACRO
	MOVEQ_PC_LR
 		[ THUMBCODE
        bxeq lr
 		|
	    moveq pc,lr
 		]
	MEND
	
 		MACRO
$HandlerLabel HANDLER $HandleLabel

$HandlerLabel
	sub	sp,sp,#4	;decrement sp(to store jump address)
	stmfd	sp!,{r0}	;PUSH the work register to stack(lr does''t push because it return to original address)
	ldr     r0,=$HandleLabel;load the address of HandleXXX to r0
	ldr     r0,[r0]	 ;load the contents(service routine start address) of HandleXXX
	str     r0,[sp,#4]      ;store the contents(ISR) of HandleXXX to stack
	ldmfd   sp!,{r0,pc}     ;POP the work register and pc(jump to ISR)
	MEND



	IMPORT  Main    ; The main entry of mon program
	IMPORT  OS_CPU_IRQ_ISR ;uCOS_II IrqISR
	EXPORT  HandleEINT0	 ;for os_cpu_a.s
	
	EXPORT	HandleIRQ	;jkeqiang
	
	
	
	EXPORT  __ENTRY
	PRESERVE8;jkeqiang
	AREA    Init,CODE,READONLY

	ENTRY
__ENTRY

	;1)The code, which converts to Big-endian, should be in little endian code.
	;2)The following little endian code will be compiled in Big-Endian mode.
	;  The code byte order should be changed as the memory bus width.
	;3)The pseudo instruction,DCD can not be used here because the linker generates error.
	ASSERT	:DEF:ENDIAN_CHANGE
	[ ENDIAN_CHANGE
	    ASSERT  :DEF:ENTRY_BUS_WIDTH
	    [ ENTRY_BUS_WIDTH=32
		b	ChangeBigEndian	    ;DCD 0xea000007
	    ]

	    [ ENTRY_BUS_WIDTH=16
		andeq	r14,r7,r0,lsl #20   ;DCD 0x0007ea00
	    ]

	    [ ENTRY_BUS_WIDTH=8
		streq	r0,[r0,-r10,ror #1] ;DCD 0x070000ea
	    ]
	|
	    b	ResetHandler
    ]
	b	HandlerUndef	;handler for Undefined mode
	b	HandlerSWI	    ;handler for SWI interrupt
	b	HandlerPabort	;handler for PAbort
	b	HandlerDabort	;handler for DAbort
	b	.		        ;reserved
	b	HandlerIRQ	;handler for IRQ interrupt
	b	HandlerFIQ	;handler for FIQ interrupt

;@0x20
	b	HandlerUndef	; Must be @0x20.
ChangeBigEndian
;@0x24
	[ ENTRY_BUS_WIDTH=32
	    DCD	0xee110f10	;0xee110f10 => mrc p15,0,r0,c1,c0,0
	    DCD	0xe3800080	;0xe3800080 => orr r0,r0,#0x80;  //Big-endian
	    DCD	0xee010f10	;0xee010f10 => mcr p15,0,r0,c1,c0,0
	]
	[ ENTRY_BUS_WIDTH=16
	    DCD 0x0f10ee11
	    DCD 0x0080e380
	    DCD 0x0f10ee01
	]
	[ ENTRY_BUS_WIDTH=8
	    DCD 0x100f11ee
	    DCD 0x800080e3
	    DCD 0x100f01ee
    ]
	DCD 0xffffffff  ;swinv 0xffffff is similar with NOP and run well in both endian mode.
	DCD 0xffffffff
	DCD 0xffffffff
	DCD 0xffffffff
	DCD 0xffffffff
	b ResetHandler
HandlerFIQ      HANDLER HandleFIQ
HandlerIRQ      HANDLER HandleIRQ
HandlerUndef    HANDLER HandleUndef
HandlerSWI      HANDLER HandleSWI
HandlerDabort   HANDLER HandleDabort
HandlerPabort   HANDLER HandlePabort




IsrIRQ
	sub	sp,sp,#4       ;reserved for PC
	stmfd	sp!,{r8-r9}

	ldr	r9,=INTOFFSET
	ldr	r9,[r9]
	ldr	r8,=HandleEINT0
	add	r8,r8,r9,lsl #2
	ldr	r8,[r8]
	str	r8,[sp,#8]
	ldmfd	sp!,{r8-r9,pc}

;=======
; ENTRY
;=======
ResetHandler

 		;Initialize stacks
	bl	InitStacks


  	; Setup IRQ handler
	ldr	r0,=HandleIRQ       ;This routine is needed
	
	;ldr	r1,=IsrIRQ	  ;if there isn''t 'subs pc,lr,#4' at 0x18, 0x1c
	ldr	r1, =OS_CPU_IRQ_ISR ;modify by txf, for ucos 
	str	r1,[r0]


	;MOV	r1,#0x02
	;MCR p15, 0, r1, c1, c1, 0

	
	
    [ :LNOT:THUMBCODE
 		bl	Main	;Don''t use main() because ......
 		b	.
    ]

    [ THUMBCODE	 ;for start-up code for Thumb mode
 		orr	lr,pc,#1
 		bx	lr
 		CODE16
 		bl	Main	;Don''t use main() because ......
 		b	.
		CODE32
    ]




;function initializing stacks
InitStacks
	;Don''t use DRAM,such as stmfd,ldmfd......
	;SVCstack is initialized before
	;Under toolkit ver 2.5, 'msr cpsr,r1' can be used instead of 'msr cpsr_cxsf,r1'
	mrs	r0,cpsr
	bic	r0,r0,#MODEMASK
	orr	r1,r0,#UNDEFMODE|NOINT
	msr	cpsr_cxsf,r1		;UndefMode
	ldr	sp,=UndefStack		; UndefStack=0x33FF_5C00

	orr	r1,r0,#ABORTMODE|NOINT
	msr	cpsr_cxsf,r1		;AbortMode
	ldr	sp,=AbortStack		; AbortStack=0x33FF_6000

	orr	r1,r0,#IRQMODE|NOINT
	msr	cpsr_cxsf,r1		;IRQMode
	ldr	sp,=IRQStack		; IRQStack=0x33FF_7000

	orr	r1,r0,#FIQMODE|NOINT
	msr	cpsr_cxsf,r1		;FIQMode
	ldr	sp,=FIQStack		; FIQStack=0x33FF_8000

	bic	r0,r0,#MODEMASK|NOINT
	orr	r1,r0,#SVCMODE
	msr	cpsr_cxsf,r1		;SVCMode
	ldr	sp,=SVCStack		; SVCStack=0x33FF_5800

	;USER mode has not be initialized.

	mov	pc,lr
	;The LR register won''t be valid if the current mode is not SVC mode.
	



	ALIGN

	AREA RamData, DATA, READWRITE

	^   _ISR_STARTADDRESS		; _ISR_STARTADDRESS=0x33FF_Fe00
HandleReset 	#   4
HandleUndef 	#   4
HandleSWI		#   4
HandlePabort    #   4
HandleDabort    #   4
HandleReserved  #   4
HandleIRQ		#   4
HandleFIQ		#   4

;Don''t use the label 'IntVectorTable',
;The value of IntVectorTable is different with the address you think it may be.
;IntVectorTable
;@0x33FF_Fe20
HandleEINT0		#   4
HandleEINT1		#   4
HandleRTC_TIC		#   4
HandleCAMIF_C		#   4
HandleCAMIF_P		#   4

HandleI2C1		#   4
HandleI2S		#   4
HandleReserved1		#   4
Handle3D		#   4
HandlePost0		#   4

HandleROTATOR		#   4
Handle2D		#   4
HandleTVENC		#   4
HandleSCALER		#   4
HandleBATF		#   4
HandleJPEG		#   4


;@0x33FF_Fe60

HandleMFC		#   4
HandleSDMA0		#   4
HandleSDMA1		#   4
HandleARM_DMAERR		#   4
HandleARM_DMA		#   4
HandleARM_DMAS		#   4
HandleKEYPAD		#   4
HandleTIMER0		#   4
HandleTIMER1		#   4
HandleTIMER2		#   4
HandleWDT		#   4
HandleTIMER3		#   4
HandleTIMER4		#   4
HandleLCD0		#   4
HandleLCD1		#   4
HandleLCD2		#   4

;@0x33FF_Fea0

HandleEINT2		#   4
HandleEINT3		#   4
HandlePCM0		#   4
HandlePCM1		#   4
HandleAC97		#   4
HandleUART0		#   4
HandleUART1		#   4
HandleUART2		#   4
HandleUART3		#   4
HandleDMA0		#   4
HandleDMA1		#   4
HandleONENAND0		#   4
HandleONENAND1		#   4
HandleNFC		#   4
HandleCFC		#   4
HandleUHOST		#   4

;@0x33FF_Fee0

HandleSPI0		#   4
HandleSPI1_HSMMC2		#   4
HandleI2C0		#   4
HandleHSItx		#   4
HandleHSIrx		#   4
HandleEINT4		#   4
HandleMSM		#   4
HandleHOSTIF		#   4
HandleHSMMC0		#   4
HandleHSMMC1		#   4
HandleOTG		#   4
HandleIrDA		#   4
HandleRTC_ALARM		#   4
HandleSEC		#   4
HandlePENDNUP		#   4
HandleADC		#   4

;@0x33FF_FF30
	END
