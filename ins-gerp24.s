	include "include/hardware/custom.i"
	INCLUDE "common/startup.s"
	
********** Flags **************
PLAY_MUSIC = 1
SHOW_RASTER = 0

********** Constants **********
w	= 320
h	= 256
bpls	= 1
bpl	= w/16*2
bwid	= bpls*bpl

********** Macros **********
WAITBLIT:macro
	tst.w	(a6)
.wb\@:	btst	#6,2(a6)
	bne.s	.wb\@
	endm

********** Demo **********
Demo:
	move.l	#VBint,$6c(a4)
	move.w	#$c020,$9a(a6)
	move.w	#$87c0,$96(a6)
    
	bsr		TextLogo_Precalc
	bsr		StripeWall_Precalc

	IFEQ	PLAY_MUSIC-1
	lea		LSPMusic,a0
	lea		LSPBank,a1
	suba.l	a2,a2			; suppose VBR=0 ( A500 )
	moveq	#0,d0			; suppose PAL machine
	bsr		LSP_MusicDriver_CIA_Start
	ENDIF

********** Main loop **********
MainLoop:
	move.w	#$12c,d0
	bsr.w	WaitRaster

.initEffect:
	move.l	EffectsInitPointer,a0
	cmp.l	#-1,a0
	beq.s	.runEffect
	move.l	(a0),a0
	cmp.l	#-1,a0
	beq.s	.runEffect
	jsr		(a0)
	move.l	#-1,EffectsInitPointer
	bra		.mouse

.runEffect:
	move.l	EffectsPointer,a0
	cmp.l	#-1,(a0)
	beq.s	.end
	move.l	8(a0),a0
	jsr		(a0)

.mouse:
	IFEQ	SHOW_RASTER-1
	move.w	#$323,$180(a6)
	ENDIF
	btst	#6,$bfe001
	bne.w	MainLoop

.end:	
	IFEQ	PLAY_MUSIC-1
	bsr		LSP_MusicDriver_CIA_Stop
	ENDIF
	rts

********** Common **********

; Set bitplane pointers
; a0 = Screen buffer
; a1 = Bitplane pointers in copper
; d0 = Bitplane size
; d1 = Number of bitplanes
SetBpls:
.bpll:	
	move.l	a0,d2
	swap 	d2
	move.w	d2,(a1)
	move.w	a0,4(a1)
	addq.w	#8,a1
	add.l	d0,a0
	dbf		d1,.bpll
	rts

; Clear buffer with blitter
; a0 = Buffer to clear
; d0 = Size to clear in words
BltClr:	
	bsr		WaitBlitter
	clr.w	$66(a6)
	move.l	#$01000000,$40(a6)
	move.l	a0,$54(a6)
	move.w	d0,$58(a6)
	rts

; Vertical blank interrupt
VBint:	
	movem.l	d0/a0/a6,-(sp)
	lea		$dff000,a6
	btst	#5,$1f(a6)
	beq.s	.notvb

.do:
	move.l	EffectsPointer,a0
	cmp.l	#-1,(a0)
	beq.s	.done

	add.l	#1,FrameCounter
	move.l	(a0),d0
	cmp.l	FrameCounter,d0
	bne.s	.run
	add.l	#16,EffectsPointer
	move.l	EffectsPointer,EffectsInitPointer
	add.l	#4,EffectsInitPointer
	bra		.do

.run:	
	move.l	12(a0),a0
	jsr		(a0)

.done:
	moveq	#$20,d0
	move.w	d0,$9c(a6)
	move.w	d0,$9c(a6)
.notvb:	
	movem.l	(sp)+,d0/a0/a6
	rte

	; include	"common/textwriter.s"
	include	"common/fade.s"
	include "common/clippoly.s"
	include "common/drawline.s"
	include "common/rotate.s"
	include	"common/shadetable.s"
	include	"common/math.s"
	include	"common/textwriter_line.s"

	include "common/LightSpeedPlayer_cia.s"
	include "common/LightSpeedPlayer.s"

	include	"parts/textlogo.s"
	include "parts/logo.s"
	include "parts/credits.s"
	include "parts/quads.s"
	include "parts/stripe_wall.s"

	even
********** Fastmem Data **********
DrawBuffer:		dc.l	Screen2
ViewBuffer:		dc.l	Screen

EffectsTable:		
			dc.l	19*50, TextLogo_Init, TextLogo_Run, TextLogo_Interrupt
			dc.l	28*50, Logo_Init, Logo_Run, Logo_Interrupt
			dc.l	34*50, Quads_Init, Quads_Run, Quads_Interrupt
			dc.l	72*50, Credits_Init, Credits_Run, Credits_Interrupt
			dc.l	100*50, StripeWall_Init, StripeWall_Run, StripeWall_Interrupt
			dc.l	160*50, EndText_Init, EndText_Run, EndText_Interrupt
			dc.l	-1,-1
EffectsPointer:		dc.l	EffectsTable
EffectsInitPointer:	dc.l	EffectsTable+4
FrameCounter:		dc.l	0

FromPalette:		dc.w	$000,$000,$000,$000
ToPalette:			dc.w	$158,$fff,$fff,$158

	include	"include/sintab.i"

	include	"parts/endtext.s"

*******************************************************************************
	SECTION ChipData,DATA_C
*******************************************************************************

MainCopper:
	dc.w	$01fc,$0000
	dc.w	$008e,$2c81
	dc.w	$0090,$2cc1
	dc.w	$0092,$0038
	dc.w	$0094,$00d0
	dc.w	$0106,$0c00
	dc.w	$0102,$0000
	dc.w	$0104,$0000
	dc.w	$0108,$0000
	dc.w	$010a,$0000

MainPalette:
	dc.w	$0180,$0222
	dc.w	$0182,$0222
	dc.w	$0184,$0222
	dc.w	$0186,$0222

MainBplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
MainBplCon:
	dc.w	$0100,$1200

	dc.w	$ffdf,$fffe
	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe

******************************************************
LogoCopper:
	dc.w	$01fc,$0000
	dc.w	$008e,$2c81
	dc.w	$0090,$2cc1
	dc.w	$0092,$0038
	dc.w	$0094,$00d0
	dc.w	$0106,$0000
	dc.w	$0102,$0000
	dc.w	$0104,$0000
	dc.w	$0108,$0000
	dc.w	$010a,$0000

LogoPalette:
	dc.w	$0180,$0fff,$0182,$0fff,$0184,$0fff,$0186,$0fff
	dc.w	$0188,$0fff,$018a,$0fff,$018c,$0fff,$018e,$0fff
	dc.w	$0190,$0fff,$0192,$0fff,$0194,$0fff,$0196,$0fff
	dc.w	$0198,$0fff,$019a,$0fff,$019c,$0fff,$019e,$0fff
	; dc.w	$01a0,$0fff,$01a2,$0fff,$01a4,$0fff,$01a6,$0fff
	; dc.w	$01a8,$0fff,$01aa,$0fff,$01ac,$0fff,$01ae,$0fff
	; dc.w	$01b0,$0fff,$01b2,$0fff,$01b4,$0fff,$01b6,$0fff
	; dc.w	$01b8,$0fff,$01ba,$0fff,$01bc,$0fff,$01be,$0fff

LogoBplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000
	; dc.w	$00f0,$0000,$00f2,$0000
LogoBplCon:
	dc.w	$0100,$4200

	; dc.w	$ffdf,$fffe
	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe

******************************************************
QuadsCopper:
	dc.w	$01fc,$0000
	dc.w	$008e,$2c81
	dc.w	$0090,$2cc1
	dc.w	$0092,$0038
	dc.w	$0094,$00d0
	dc.w	$0106,$0c00
	dc.w	$0108,$0000
	dc.w	$010a,$0000
	dc.w	$0102,$0000

QuadsBplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	; dc.w	$00e8,$0000,$00ea,$0000
	; dc.w	$00ec,$0000,$00ee,$0000
	; dc.w	$00f0,$0000,$00f2,$0000
QuadsBplCon:
	dc.w	$0100,$3200

QuadsPalette:
	dc.w	$0180,$0fff
	dc.w	$0182,$0678
	dc.w	$0184,$0fff
	dc.w	$0186,$0fff
	dc.w	$0188,$0fff	; bg
	dc.w	$018a,$0678
	dc.w	$018c,$0fff
	dc.w	$018e,$0fff

	dc.w	$ac01,$fffe
	dc.w	$0182,$0678	; bottom-left
	dc.w	$0184,$0fff
	dc.w	$0186,$0fff	; bottom-right !!!
	dc.w	$0188,$0fff
	dc.w	$018a,$0678	; top-left
	dc.w	$018c,$0fff
	dc.w	$018e,$0fff	; top-right

	; dc.w	$0180,$0fff,$0182,$0fff,$0184,$0fff,$0186,$0fff
	; dc.w	$0188,$0fff,$018a,$0fff,$018c,$0fff,$018e,$0fff

	; dc.w	$0190,$0fff,$0192,$0fff,$0194,$0fff,$0196,$0fff
	; dc.w	$0198,$0fff,$019a,$0fff,$019c,$0fff,$019e,$0fff
	; dc.w	$01a0,$0fff,$01a2,$0fff,$01a4,$0fff,$01a6,$0fff
	; dc.w	$01a8,$0fff,$01aa,$0fff,$01ac,$0fff,$01ae,$0fff
	; dc.w	$01b0,$0fff,$01b2,$0fff,$01b4,$0fff,$01b6,$0fff
	; dc.w	$01b8,$0fff,$01ba,$0fff,$01bc,$0fff,$01be,$0fff

	; dc.w	$ac01,$fffe
	; dc.w	$01a0,$0fff,$01a2,$0fff,$01a4,$0fff,$01a6,$0fff
	; dc.w	$01a8,$0fff,$01aa,$0fff,$01ac,$0fff,$01ae,$0fff
	; dc.w	$01b0,$0fff,$01b2,$0fff,$01b4,$0fff,$01b6,$0fff
	; dc.w	$01b8,$0fff,$01ba,$0fff,$01bc,$0fff,$01be,$0fff

	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe

CreditsCopper:
	dc.w	$01fc,$0000
	dc.w	$008e,$2c81
	dc.w	$0090,$2cc1
	dc.w	$0092,$0038
	dc.w	$0094,$00d0
	dc.w	$0106,$0c00
	dc.w	$0104,$0000
	dc.w	$0108,$0000
	dc.w	$010a,$0000
	dc.w	$0102
CreditsBplCon1:
	dc.w	$00f0

CreditsBplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
CreditsBplCon:
	dc.w	$0100,$1200

CreditsPalette:
	dc.w	$0180,$0222
	dc.w	$0182,$0222
CreditsPaletteLine1:
	dc.w	$0184,$00f0
	dc.w	$0186,$00f0
	dc.w	$0188,$0222
	dc.w	$018a,$0222
	dc.w	$018c,$0222
	dc.w	$018e,$0222

CreditsPalette2Y:
	dc.w	$8001,$fffe
CreditsPaletteBg2:
	dc.w	$0180,$0222
CreditsPaletteLine2:
	dc.w	$0184,$0555
	dc.w	$0186,$0555
	dc.w	$0188,$0acc
	dc.w	$018a,$0acc
	dc.w	$018c,$0acc
	dc.w	$018e,$0acc

CreditsPalette3Y:
	dc.w	$d001,$fffe
CreditsPaletteBg3:
	dc.w	$0180,$0222
CreditsPaletteLine3:
	dc.w	$0184,$0555
	dc.w	$0186,$0555
	dc.w	$0188,$0acc
	dc.w	$018a,$0acc
	dc.w	$018c,$0acc
	dc.w	$018e,$0acc

	dc.w	$ffdf,$fffe
	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe


StripeWallCopper:
	dc.w	$01fc,$0000
	dc.w	$008e,$2c81
	dc.w	$0090,$2cc1
	dc.w	$0092,$0030
	dc.w	$0094,$00d0
	dc.w	$0106,$0c00
	dc.w	$0108,$0000
	dc.w	$010a,$0000
	dc.w	$0102,$0000
	dc.w	$0100,$2200

; StripeWallBplPtrs:
; StripeWallPalette:
	dc.w	$0180,$012

	dc.w	$2c01,$fffe
StripeWallCop2Loc:
	dc.w	$0084,$0000,$0086,0000
	dc.w	$008a,$0001

	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe

StripeWallBplPtrs:
	ds.w	STRIPEWALL_ROWS*STRIPEWALL_ROWSIZE+2
StripeWallBplPtrs2:
	ds.w	STRIPEWALL_ROWS*STRIPEWALL_ROWSIZE+2

Font:			incbin	"data/graphics/vedderfont5.8x520.1.raw"
StripesPattern:	incbin	"data/graphics/stripes_pattern.raw"
Triangle:		incbin	"data/graphics/triangle.raw"
Logo:			incbin	"data/graphics/logo2.raw"
LogoPal:		incbin	"data/graphics/logo2.pal"
CircleMask:		incbin	"data/graphics/circle_mask_16x160x1.raw"
WeAreBack:		incbin	"data/graphics/weareback.raw"

LSPBank:		incbin	"data/music/we are back timefix.lsbank"

BlankLine:      dcb.b   40,0

	SECTION	VariousData,DATA
LSPMusic:
	incbin	"data/music/we are back timefix.lsmusic"

*******************************************************************************
	SECTION ChipBuffers,BSS_C
*******************************************************************************

Screen:		ds.b	h*bwid*5
Screen2:	ds.b	h*bwid*5

QuadsMask:	ds.b	h*bwid

TLFont:		ds.w	520*8

; Triangle:	ds.b	320*160/8
	END