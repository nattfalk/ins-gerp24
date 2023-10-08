TextLogoPart2_Init:
        move.w  #0,FCnt
        rts

TextLogoPart2_Run:
	movem.l	DrawBuffer(PC),a2-a3
	exg	a2,a3
	movem.l	a2-a3,DrawBuffer

	move.l	a3,a0
        moveq   #0,d0
	lea	TLBplPtrs+2,a1
	moveq	#1-1,d1
	bsr.w	SetBpls

	move.l	a2,a0
        move.l  #(256<<6)+(320>>4),d0
	bsr	BltClr
	bsr	WaitBlitter

        ; Calculate sin y value
        lea.l   TL2Movements,a0
        move.w  TL2MovementCount,d7
        moveq   #11,d6
        sub.w   d7,d6
        add.w   d6,d6
        lea.l   (a0,d6.w),a0
        move.w  (a0),d0
        add.w   #22,d0
        subq.w  #1,d7
.calcMovement:
        move.w  d0,(a0)+
        add.w   #80,d0
        dbf     d7,.calcMovement
        cmp.w   #11,TL2MovementCount
        beq.s   .allIncluded
        add.w   #1,TL2MovementCount
.allIncluded:

        ; Calulate new text y positions
        lea.l   TLCharPositions,a0
        lea.l   TL2CharPositions,a1
        lea.l   TL2Movements,a2
        lea.l   Sintab,a3
        moveq   #11-1,d7
.calcNewY:
        move.w  (a0)+,(a1)+
        move.w  (a0)+,d0        ; y
        move.w  (a2)+,d1
        and.w   #$7fe,d1
        move.w  (a3,d1.w),d1
        asr.w   #7,d1
        muls    #40,d1
        asr.w   #8,d1
        add.w   d1,d0
        move.w  d0,(a1)+
        dbf     d7,.calcNewY

        ; Render text
        lea.l   TLText(pc),a0
        lea.l   TL2CharPositions,a1
        move.l  DrawBuffer,a2
        lea.l   TLFont,a4

        moveq   #11-1,d7
.loop:  
        move.w  (a1)+,d4
        move.b  d4,d5
        ; Get index to shifted font
        lsr.w   #3,d4
        and.w   #%111,d5

        ; Caculate offset in screen
        move.w  (a1)+,d6
        mulu    #40,d6
        add.w   d6,d4

        ; Get current char
        move.b  (a0)+,d6
        sub.b   #' ',d6
        and.w   #$ff,d6
        lsl.w   #4,d6

        ; Get shifted font
        mulu    #520*2,d5
        add.w   d6,d5
        lea.l   (a4,d5.l),a5
        lea.l   (a2,d4.w),a3

        ; Render char
I       SET     0
        REPT    8
        move.w  (a5)+,d5
        or.b    d5,(a3)+
        ror.w   #8,d5
        or.b    d5,(a3)+
        add.l   #38,a3
I       SET     I+1
        ENDR

        dbf     d7,.loop

        ; Fade 
        cmp.w   #0,TL2DoFade
        beq.s   .skipFade
        lea.l   TL2FromPalette,a0
        lea.l   TL2ToPalette,a1
        lea.l   TLPalette,a2
        moveq   #50,d0
        moveq   #2-1,d1
        bsr     Fade

.skipFade:
        rts

TextLogoPart2_Interrupt:
        cmp.l   #21*50,FrameCounter
        bmi     .skipFade
        move.w  #1,TL2DoFade

.skipFade:
        rts

TL2CharPositions:
        ds.w    11*2
TL2Movements:
        dc.w    0,0,0,0,0,0,0,0,0,0,0
TL2MovementCount:
        dc.w    1
TL2DoFade:
        dc.w    0
TL2FromPalette:
        dc.w    $0012,$0dff
TL2ToPalette:
        dc.w    $0fff,$0fff
;*************************************************************