************************************************************
TextLogo_Precalc:
        lea.l   TLFont,a1
        moveq   #8-1,d7
.xLoop: lea.l   Font,a0
        move.w  #520-1,d6
.yLoop: move.b  (a0)+,d0
        and.w   #$ff,d0
        lsl.w   #1,d0
        lsl.w   d7,d0
        ror.w   #8,d0
        move.w  d0,(a1)+
        dbf     d6,.yLoop
        dbf     d7,.xLoop
        rts

************************************************************
TextLogo_Init:
	lea	Screen,a0
        move.l  #(256<<6)+(320>>4),d0
	bsr.w	BltClr
	lea	Screen2,a0
        move.l  #(256<<6)+(320>>4),d0
	bsr.w	BltClr
	bsr	WaitBlitter

	lea	Screen,a0
	; move.l	#(320>>3)*256,d0
        moveq   #0,d0
	lea	MainBplPtrs+2,a1
	moveq	#1-1,d1
	bsr.w	SetBpls

	move.l	#MainCopper,$80(a6)
        rts

************************************************************
MAX_RADIUS      = 120
TextLogo_Run:
	movem.l	DrawBuffer(PC),a2-a3
	exg	a2,a3
	movem.l	a2-a3,DrawBuffer

	move.l	a3,a0
	; move.l	#(320>>3)*256,d0
        moveq   #0,d0
	lea	MainBplPtrs+2,a1
	moveq	#1-1,d1
	bsr.w	SetBpls

	move.l	a2,a0
        move.l  #(256<<6)+(320>>4),d0
	bsr	BltClr
	bsr	WaitBlitter

        move.l  a6,-(sp)
        lea.l   TLText(pc),a0
        lea.l   Sintab,a1
        lea.l   Costab,a2
        move.l  DrawBuffer,a3
        lea.l   TLFont,a4

        ; Ease in
        move.w  .width,d2
        lsr.w   #7,d2
        cmp.w   #MAX_RADIUS,d2
        bmi     .easeIn
        moveq   #MAX_RADIUS,d2
        bra     .calculateAngle
.easeIn:
        move.w  TLWidthStep,d3
        lsr.w   #4,d3
        add.w   d3,.width

.calculateAngle:
        ; Max radius from center to avoid text outside viewport
        move.w  #MAX_RADIUS,d0
        sub.w   d2,d0           

        ; Calculate new center X
        move.w  TLMoveX,d1
        and.w   #$7fe,d1
        move.w  (a1,d1.w),d1
        asr.w   #8,d1
        muls    d0,d1
        asr.w   #7,d1
        add.w   #320/2,d1
        move.w  d1,.centerX

        ; Calculate new center Y
        move.w  TLMoveY,d1
        and.w   #$7fe,d1
        move.w  (a2,d1.w),d1
        asr.w   #8,d1
        muls    d0,d1
        asr.w   #7,d1
        add.w   #256/2,d1
        move.w  d1,.centerY

        ; Get rotated x,y for text position
        move.w  TLAngle(pc),d0
        and.w   #$7fe,d0
        move.w  (a2,d0.w),d1    ; y
        move.w  (a1,d0.w),d0    ; x

        ; Scale up X by current text width
        asr.w   #7,d0
        muls    d2,d0
        asr.w   #8,d0

        ; Scale up Y by current text width
        asr.w   #7,d1
        muls    d2,d1
        asr.w   #8,d1

        ; Create x2 (opposite of x1)
        move.w  d0,d2
        neg     d2      
        ; Create y2 (opposite of y1)
        move.w  d1,d3
        neg     d3      

        ; Calculate step X
        sub.w   d0,d2
        add.w   .centerX,d0
        lsl.w   #7,d0
        asl.w   #7,d2
        ext.l   d2
        divs.w  #10,d2

        ; Calculate step Y
        sub.w   d1,d3
        add.w   .centerY,d1
        lsl.w   #7,d1
        asl.w   #7,d3
        ext.l   d3
        divs.w  #10,d3

        lea.l   TLCharPositions,a1

        moveq   #11-1,d7
.loop:  move.w  d0,d4
        lsr.w   #7,d4
        move.w  d4,(a1)+
        move.b  d4,d5
        ; Get index to shifted font
        lsr.w   #3,d4
        and.w   #%111,d5

        ; Caculate offset in screen
        move.w  d1,d6
        lsr.w   #7,d6
        move.w  d6,(a1)+
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

        move.l  a3,-(sp)
        lea.l   (a3,d4.w),a3

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

        move.l  (sp)+,a3

        add.w   d2,d0
        add.w   d3,d1

        dbf     d7,.loop

        ; Set text color
        lea.l   .palette(pc),a0
        move.w  TLColorIndex(pc),d0
        add.w   d0,d0
        move.w  (a0,d0.w),MainPalette+6

.done:  move.l  (sp)+,a6
        rts

                even
.width:         dc.w    1
.centerX:       dc.w    0
.centerY:       dc.w    0
.palette:       dc.w    $023,$134,$245,$356,$367,$477,$578,$699
                dc.w    $7aa,$8ab,$9bc,$9cd,$add,$bee,$cff,$dff

************************************************************
TextLogo_Interrupt:
        add.w   #-8,TLMoveX
        add.w   #12,TLMoveY
        
        add.w   #1,TLWidthStep

        add.w   #12,TLAngle
        cmp.w   #7680,TLAngle
        bmi.s   .fade
        move.w  #7680,TLAngle

.fade:  cmp.w   #15,TLColorIndex
        beq.s   .done
        cmp.w   #40,.colorTimer
        beq.s   .addFade
        add.w   #1,.colorTimer
        bra.s   .done
.addFade:
        add.w   #1,TLColorIndex
        clr.w   .colorTimer
.done:  rts

                even
.colorTimer:    dc.w    0

************************************************************
TLAngle:        dc.w    0
TLWidthStep:    dc.w    0
TLColorIndex:   dc.w    0
TLMoveX:        dc.w    0
TLMoveY:        dc.w    0
TLCharPositions:ds.w    11*2
TLText:         dc.b    'INSANE 2024'   ; 11 chars
                even
