
    *** MiniStartup by Photon ***

	INCLUDE "common/startup.s"

********** Constants **********

;	INCLUDE "Blitter-Register-List.S"	;use if you like ;)

w	= 320				;screen width, height, depth
h	= 256
bpls	= 1				;handy values:
bpl	= w/16*2				;byte-width of 1 bitplane line
bwid	= bpls*bpl			;byte-width of 1 pixel line (all bpls)

********** Macros **********

WAITBLIT:macro
	tst.w	(a6)			;for compatibility with A1000
.wb\@:	btst	#6,2(a6)
	bne.s	.wb\@
	endm

********** Demo **********		;Demo-specific non-startup code below.

Demo:					;a4=VBR, a6=Custom Registers Base addr
    *--- init ---*
	move.l	#VBint,$6c(a4)
	move.w	#$c020,$9a(a6)
	move.w	#$87c0,$96(a6)
    
	bsr	TextLogo_Precalc

********************  main loop  ********************
MainLoop:
	move.w	#$12c,d0			;No buffering, so wait until raster
	bsr.w	WaitRaster			;is below the Display Window.

	move.l	EffectsInitPointer,a0
	cmp.l	#-1,a0
	beq.s	.runEffect
	move.l	(a0),a0
	cmp.l	#-1,a0
	beq.s	.runEffect
	jsr	(a0)
	move.l	#-1,EffectsInitPointer
	bra	.mouse

.runEffect:
	move.l	EffectsPointer,a0
	cmp.l	#-1,(a0)
	beq.s	.end
	move.l	8(a0),a0
	jsr	(a0)

.mouse:
	; move.w	#$323,$180(a6)		;show rastertime left down to $12c
	btst	#6,$bfe001			;Left mouse button not pressed?
	bne.w	MainLoop			;then loop
    *--- exit ---*
.end:
	rts

FromPalette:	dc.w	$000,$000
ToPalette:	dc.w	$158,$fff

;		0123456789012345678901234567890123456789
Text:	dc.b	'THIS ',2,'IS ',3,'A TEST!',10
	dc.b	1,'LINE 2',5,200,'11!',0
	even

********** Demo Routines **********

PokePtrs:				;Generic, poke ptrs into copper list
.bpll:	move.l	a0,d2
	swap 	d2
	move.w	d2,(a1)			;high word of address
	move.w	a0,4(a1)			;low word of address
	addq.w	#8,a1			;skip two copper instructions
	add.l	d0,a0			;next ptr
	dbf	d1,.bpll
	rts

ClearScreen:				;a1=screen destination address to clear
	bsr	WaitBlitter
	clr.w	$66(a6)			;destination modulo
	move.l	#$01000000,$40(a6)	;set operation type in BLTCON0/1
	move.l	a1,$54(a6)		;destination address
	move.w	#h*bpls*64+bpl/2,$58(a6)	;blitter operation size
	rts

VBint:					;Blank template VERTB interrupt
	movem.l	d0/a0/a6,-(sp)		;Save used registers
	lea	$dff000,a6
	btst	#5,$1f(a6)			;check if it's our vertb int.
	beq.s	.notvb

.do:	move.l	EffectsPointer,a0
	cmp.l	#-1,(a0)
	beq.s	.done

	add.l	#1,FrameCounter
	move.l	(a0),d0
	cmp.l	FrameCounter,d0
	bne.s	.run
	add.l	#16,EffectsPointer
	move.l	EffectsPointer,EffectsInitPointer
	add.l	#4,EffectsInitPointer
	bra	.do

.run:	move.l	12(a0),a0
	jsr	(a0)

.done:
	moveq	#$20,d0			;poll irq bit
	move.w	d0,$9c(a6)
	move.w	d0,$9c(a6)
.notvb:	movem.l	(sp)+,d0/a0/a6		;restore
	rte

	include	"common/textwriter.s"
	; include	"common/doteffect.s"
	include	"common/textlogo.s"
	include	"common/textlogo_part2.s"

********** Fastmem Data **********

		even
DrawBuffer:	dc.l Screen2		;pointers to buffers to be swapped
ViewBuffer:	dc.l Screen

EffectsTable:		dc.l	16*50, TextLogo_Init, TextLogo_Run, TextLogo_Interrupt
			dc.l	19*50, TextLogoPart2_Init, TextLogoPart2_Run, TextLogoPart2_Interrupt
			dc.l	-1,-1
EffectsPointer:		dc.l	EffectsTable
EffectsInitPointer:	dc.l	EffectsTable+4
FrameCounter:		dc.l	0

	include	"include/sintab.i"

*******************************************************************************
	SECTION ChipData,DATA_C		;declared data that must be in chipmem
*******************************************************************************

Copper:
	dc.w	$1fc,0			;Slow fetch mode, remove if AGA demo.
	dc.w	$8e,$2c81			;238h display window top, left
	dc.w	$90,$2cc1			;and bottom, right.
	dc.w	$92,$38			;Standard bitplane dma fetch start
	dc.w	$94,$d0			;and stop for standard screen.

	dc.w	$106,$0c00			;(AGA compat. if any Dual Playf. mode)
	dc.w	$108,0	;bwid-bpl		;modulos
	dc.w	$10a,0  ;bwid-bpl

	dc.w	$102,0			;Scroll register (and playfield pri)

Palette:				;Some kind of palette (3 bpls=8 colors)
	dc.w	$180,$012			;black
	dc.w	$182,$012			;white
	; dc.w	$182,$356			;green
	dc.w	$184,$689			;red
	dc.w	$186,$8bd			;yellow
	dc.w	$188,$234			;blue
	dc.w	$18a,$467			;cyan
	dc.w	$18c,$79b			;magenta
	dc.w	$18e,$9ce			;white

BplPtrs:
	dc.w	$e0,0
	dc.w	$e2,0
	dc.w	$e4,0
	dc.w	$e6,0
	dc.w	$e8,0
	dc.w	$ea,0
	dc.w	$ec,0
	dc.w	$ee,0
	dc.w	$f0,0
	dc.w	$f2,0
	dc.w	$f4,0
	dc.w	$f6,0			;full 6 ptrs, in case you increase bpls
	dc.w	$100,bpls*$1000+$200	;enable bitplanes

	dc.w	$ffdf,$fffe		;allow VPOS>$ff
	dc.w	$ffff,$fffe		;magic value to end copperlist
CopperE:

Font:	incbin	"data/vedderfont5.8x520.1.raw"

*******************************************************************************
	SECTION ChipBuffers,BSS_C	;BSS doesn't count toward exe size
*******************************************************************************

Screen:	ds.b	h*bwid			;Define storage for buffer 1
Screen2:ds.b	h*bwid			;two buffers

TextLogoFont:
	ds.w	520*8
	END