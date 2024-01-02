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
	move.w	#$e020,$9a(a6)
	move.w	#$87c0,$96(a6)
    
	bsr	TextLogo_Precalc

	IFEQ	PLAY_MUSIC-1
	lea	LSPMusic,a0
	lea	LSPBank,a1
	suba.l	a2,a2			; suppose VBR=0 ( A500 )
	moveq	#0,d0			; suppose PAL machine
	bsr	LSP_MusicDriver_CIA_Start
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
	IFEQ	SHOW_RASTER-1
	move.w	#$323,$180(a6)
	ENDIF
	btst	#6,$bfe001
	bne.w	MainLoop

.end:	IFEQ	PLAY_MUSIC-1
	bsr	LSP_MusicDriver_CIA_Stop
	ENDIF
	rts

********** Common **********

; Set bitplane pointers
; a0 = Screen buffer
; a1 = Bitplane pointers in copper
; d0 = Bitplane size
; d1 = Number of bitplanes
SetBpls:
.bpll:	move.l	a0,d2
	swap 	d2
	move.w	d2,(a1)
	move.w	a0,4(a1)
	addq.w	#8,a1
	add.l	d0,a0
	dbf	d1,.bpll
	rts

; Clear buffer with blitter
; a0 = Buffer to clear
; d0 = Size to clear in words
BltClr:	bsr	WaitBlitter
	clr.w	$66(a6)
	move.l	#$01000000,$40(a6)
	move.l	a0,$54(a6)
	move.w	d0,$58(a6)
	rts

; Vertical blank interrupt
VBint:	movem.l	d0/a0/a6,-(sp)
	lea	$dff000,a6
	btst	#5,$1f(a6)
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
	moveq	#$20,d0
	move.w	d0,$9c(a6)
	move.w	d0,$9c(a6)
.notvb:	movem.l	(sp)+,d0/a0/a6
	rte

	; include	"common/textwriter.s"
	; include	"common/doteffect.s"
	include	"common/fade.s"
	include "common/drawline.s"
	include "common/rotate.s"

	include	"parts/textlogo.s"
	include	"parts/textlogo_part2.s"
	include "parts/quads.s"
	include "parts/credits.s"

	include "common/LightSpeedPlayer_cia.s"
	include "common/LightSpeedPlayer.s"

********** Fastmem Data **********
			even
DrawBuffer:		dc.l	Screen2
ViewBuffer:		dc.l	Screen

EffectsTable:		dc.l	16*50, TextLogo_Init, TextLogo_Run, TextLogo_Interrupt
			dc.l	23*50, TextLogoPart2_Init, TextLogoPart2_Run, TextLogoPart2_Interrupt
			dc.l	32*50, Quads_Init, Quads_Run, Quads_Interrupt
			dc.l	90*50, Credits_Init, Credits_Run, Credits_Interrupt
			dc.l	-1,-1
EffectsPointer:		dc.l	EffectsTable
EffectsInitPointer:	dc.l	EffectsTable+4
FrameCounter:		dc.l	0

FromPalette:		dc.w	$000,$000
ToPalette:		dc.w	$158,$fff


;		0123456789012345678901234567890123456789
Text:			dc.b	'THIS ',2,'IS ',3,'A TEST!',10
			dc.b	1,'LINE 2',5,200,'11!',0
			even

	include	"include/sintab.i"

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
	dc.w	$0108,$0000
	dc.w	$010a,$0000
	dc.w	$0102,$0000

MainPalette:
	dc.w	$0180,$0012
	dc.w	$0182,$0012
	dc.w	$0184,$0012
	dc.w	$0186,$0012

MainBplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
MainBplCon:
	dc.w	$0100,$1200

	dc.w	$ffdf,$fffe
	dc.w	$ffff,$fffe

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
	dc.w	$0100,$2200

QuadsPalette:
	dc.w	$0180,$0012
	dc.w	$0182,$0fff	; top-left
	dc.w	$0184,$0012
	dc.w	$0186,$0fff	; top-right

	dc.w	$ac01,$fffe
	dc.w	$0182,$0fff	; bottom-left
	dc.w	$0184,$0012
	dc.w	$0186,$0fff	; bottom-right

	dc.w	$ffff,$fffe

; TL2Copper:
; 	dc.w	$01fc,$0000
; 	dc.w	$008e,$2c81
; 	dc.w	$0090,$2cc1
; 	dc.w	$0092,$0038
; 	dc.w	$0094,$00d0
; 	dc.w	$0106,$0c00
; 	dc.w	$0108,$0000
; 	dc.w	$010a,$0000
; 	dc.w	$0102,$0000

; TL2Palette:
; 	dc.w	$0180,$0012
; 	dc.w	$0182,$0dff

; TL2BplPtrs:
; 	dc.w	$ac01,$fffe,$00e0,$0000,$00e2,$0000,$0100,$1200
	
; 	; dc.w	$ad01,$fffe,$00e0,$0000,$00e2,$0000
; 	; dc.w	$ae01,$fffe,$00e0,$0000,$00e2,$0000
; 	; dc.w	$af01,$fffe,$00e0,$0000,$00e2,$0000
; 	; dc.w	$b001,$fffe,$00e0,$0000,$00e2,$0000
; 	; dc.w	$b101,$fffe,$00e0,$0000,$00e2,$0000
; 	; dc.w	$b201,$fffe,$00e0,$0000,$00e2,$0000
; 	; dc.w	$b301,$fffe,$00e0,$0000,$00e2,$0000
; 	; dc.w	$b401,$fffe,$00e0,$0000,$00e2,$0000
	
; 	dc.w	$b501,$fffe,$0100,$0200

; 	; dc.w	$ffdf,$fffe
; 	dc.w	$ffff,$fffe


Font:	incbin	"data/vedderfont5.8x520.1.raw"
LSPBank:incbin	"data/scenic balls.v3.lsbank"

	SECTION	VariousData,DATA
LSPMusic:
	incbin	"data/scenic balls.v3.lsmusic"

*******************************************************************************
	SECTION ChipBuffers,BSS_C
*******************************************************************************

Screen:		ds.b	h*bwid*5
Screen2:	ds.b	h*bwid*5

QuadsMask:	ds.b	h*bwid

TLFont:		ds.w	520*8
	END