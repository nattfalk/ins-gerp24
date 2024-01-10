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
        move.l  #(512<<6)+(320>>4),d0
	bsr.w	BltClr
	lea	Screen2,a0
        move.l  #(512<<6)+(320>>4),d0
	bsr.w	BltClr
	bsr	WaitBlitter

	lea	Screen,a0
	move.l	#(320>>3)*256,d0
        ; moveq   #0,d0
	lea	MainBplPtrs+2,a1
	moveq	#2-1,d1
	bsr.w	SetBpls

        move.w  #$2200,MainBplCon+2
	move.l	#MainCopper,$80(a6)
        rts

************************************************************
MAX_RADIUS      = 120
TextLogo_Run:
	movem.l	DrawBuffer(PC),a2-a3
	exg	a2,a3
	movem.l	a2-a3,DrawBuffer

	move.l	a3,a0
	move.l	#(320>>3)*256,d0
        ; moveq   #0,d0
	lea	MainBplPtrs+2,a1
	moveq	#2-1,d1
	bsr.w	SetBpls

	move.l	a2,a0
        move.l  #(512<<6)+(320>>4),d0
	bsr	BltClr

        bsr     TextLogo_RenderRotatingBackground

        cmp.w   #16*50-25,TL_LocalFrameCounter
        bge.s   .sineWave
        bsr     TextLogo_RenderRotatingText
        bra.s   .done

.sineWave:
        cmp.w   #18*50,TL_LocalFrameCounter
        bge.s   .fadeOut
        bsr     TextLogo_RenderSinewaveText
        clr.w   FCnt
        bra.s   .done

.fadeOut:
        bsr     TextLogo_FadeOut

.done:  
        rts


************************************************************
TextLogo_Interrupt:
        add.w   #1,TL_LocalFrameCounter

        cmp.w   #97,TLRotatingBg_AngleCounter
        bne.s   .addCounter
        clr.w   TLRotatingBg_AngleCounter

        neg.w   TLRotatingBg_AngleAdd
.addCounter:
        add.w   #1,TLRotatingBg_AngleCounter
        move.w  TLRotatingBg_AngleAdd,d0
        add.w   d0,TLRotatingBg_Angle

        add.w   #-8,TLRotatingText_MoveX
        add.w   #12,TLRotatingText_MoveY
        
        add.w   #1,TLRotatingText_WidthStep

        add.w   #12,TLRotatingText_Angle
        cmp.w   #7680,TLRotatingText_Angle
        bmi.s   .fade
        move.w  #7680,TLRotatingText_Angle

.fade:  cmp.w   #15,TLRotatingText_ColorIndex
        beq.s   .done
        cmp.w   #40,.colorTimer
        beq.s   .addFade
        add.w   #1,.colorTimer
        bra.s   .done
.addFade:
        add.w   #1,TLRotatingText_ColorIndex
        clr.w   .colorTimer
.done:  rts

                even
.colorTimer:    dc.w    0

************************************************************
TextLogo_RenderRotatingBackground:
        moveq   #0,d0
        moveq   #0,d1
        move.w  TLRotatingBg_Angle(pc),d2
        bsr     InitRotate

        lea.l   TLRotatingBg_Coords(pc),a0
        lea.l   TLRotatingBg_RotatedCoords(pc),a1
        moveq   #4-1,d7
.rotate:movem.w (a0)+,d0-d1
        moveq   #0,d2
        bsr     RotatePoint
        add.w   #320/2,d0
        move.w  d0,(a1)+
        add.w   #256/2,d1
        move.w  d1,(a1)+
        dbf     d7,.rotate

        lea.l   clip_crds_in,a0
        lea.l   TLRotatingBg_RotatedCoords(pc),a1
        ; lea.l   TLRotatingBg_RotatedCoords2(pc),a1
        move.w  (a1),16(a0)
        move.w  2(a1),18(a0)
        move.l  a0,a3
        moveq   #4-1,d7
.setupClip:
        move.w  (a1),(a0)+
        move.w  2(a1),(a0)+
        adda.l  #4,a1
        dbf     d7,.setupClip
        move.w  #4,clip_no_in
        ; move.w  #50,clip_xmin
        ; move.w  #50,clip_ymin
        ; move.w  #270,clip_xmax
        ; move.w  #206,clip_ymax
        move.w  #16,clip_xmin
        move.w  #0,clip_ymin
        move.w  #303,clip_xmax
        move.w  #255,clip_ymax
        bsr     clippoly

        bsr     DL_Init
        lea.l   $dff000,a6
        lea.l   clip_crds_in,a2
        move.w  clip_no_in,d7
        subq.w  #1,d7
.poly:  
        movea.l DrawBuffer(pc),a0
        adda.l  #256*40,a0
        movem.w (a2)+,d0-d1
        movem.w (a2),d2-d3
        moveq   #40,d4
        bsr     DrawLineFilledPoly
        dbf     d7,.poly

        ; Fill poly
        lea.l   $dff000,a6
        movea.l	DrawBuffer(pc),a0
        lea.l	((256+256)*40)-2(a0),a0
        bsr     WaitBlitter
        move.w	#$09f0,$40(a6)
        move.w	#$0012,$42(a6)	; Descending and fill
        move.l	#0,$64(a6)	; Clear A & D modulo
        move.l	a0,$50(a6)	; Src A
        move.l	a0,$54(a6)	; Dest (D)
        move.w	#256<<6+20,$58(a6)	; BltSize

        rts

TextLogo_RenderRotatingText:
        move.l  a6,-(sp)
        lea.l   TL_Text(pc),a0
        lea.l   Sintab,a1
        lea.l   Costab,a2
        move.l  DrawBuffer,a3
        lea.l   TLFont,a4

        ; Ease in
        move.w  TLRotatingText_Width,d2
        lsr.w   #7,d2
        cmp.w   #MAX_RADIUS,d2
        bmi     .easeIn
        moveq   #MAX_RADIUS,d2
        bra     .calculateAngle
.easeIn:
        move.w  TLRotatingText_WidthStep,d3
        lsr.w   #4,d3
        add.w   d3,TLRotatingText_Width

.calculateAngle:
        ; Max radius from center to avoid text outside viewport
        move.w  #MAX_RADIUS,d0
        sub.w   d2,d0           

        ; Calculate new center X
        move.w  TLRotatingText_MoveX,d1
        and.w   #$7fe,d1
        move.w  (a1,d1.w),d1
        asr.w   #8,d1
        muls    d0,d1
        asr.w   #7,d1
        add.w   #320/2,d1
        move.w  d1,TLRotatingText_CenterX

        ; Calculate new center Y
        move.w  TLRotatingText_MoveY,d1
        and.w   #$7fe,d1
        move.w  (a2,d1.w),d1
        asr.w   #8,d1
        muls    d0,d1
        asr.w   #7,d1
        add.w   #256/2,d1
        move.w  d1,TLRotatingText_CenterY

        ; Get rotated x,y for text position
        move.w  TLRotatingText_Angle(pc),d0
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
        add.w   TLRotatingText_CenterX,d0
        lsl.w   #7,d0
        asl.w   #7,d2
        ext.l   d2
        divs.w  #10,d2

        ; Calculate step Y
        sub.w   d1,d3
        add.w   TLRotatingText_CenterY,d1
        lsl.w   #7,d1
        asl.w   #7,d3
        ext.l   d3
        divs.w  #10,d3

        lea.l   TL_CharPositions,a1

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
        lea.l   TLRotatingText_Palette(pc),a0
        move.w  TLRotatingText_ColorIndex(pc),d0
        add.w   d0,d0
        move.w  (a0,d0.w),MainPalette+6
        move.w  (a0,d0.w),MainPalette+10

        move.l  (sp)+,a6
        rts

TextLogo_RenderSinewaveText:
        ; Calculate sin y value
        lea.l   TLSine_Movements,a0
        move.w  TLSine_MovementCount,d7
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
        cmp.w   #11,TLSine_MovementCount
        beq.s   .allIncluded
        add.w   #1,TLSine_MovementCount
.allIncluded:

        ; Calulate new text y positions
        lea.l   TL_CharPositions,a0
        lea.l   TLSine_CharPositions,a1
        lea.l   TLSine_Movements,a2
        lea.l   Sintab,a3
        moveq   #11-1,d7
.calcNewY:
        move.w  (a0)+,(a1)+
        move.w  (a0)+,d0        ; y
        cmp.w   #3,d7
        ble.s   .wave
        move.w  d0,(a1)+
        bra     .loopWave
.wave:  move.w  (a2)+,d1
        and.w   #$7fe,d1
        move.w  (a3,d1.w),d1
        asr.w   #7,d1
        muls    #40,d1
        asr.w   #8,d1
        add.w   d1,d0
        move.w  d0,(a1)+
.loopWave:
        dbf     d7,.calcNewY

        ; Render text
        lea.l   TL_Text(pc),a0
        lea.l   TLSine_CharPositions,a1
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

        rts

TextLogo_FadeOut:
        lea.l   TLSine_FromPalette,a0
        lea.l   TLSine_ToPalette,a1
        lea.l   MainPalette,a2
        moveq   #50,d0
        moveq   #4-1,d1
        bsr     Fade
.done:
        rts

************************************************************
TL_Text:                        dc.b    'INSANE 2024'   ; 11 chars
                                even
TL_LocalFrameCounter:           dc.w    0
TL_CharPositions:               ds.w    11*2

TLRotatingBg_AngleCounter:      dc.w    0
TLRotatingBg_AngleAdd:          dc.w    6
TLRotatingBg_Coords:            dc.w    -500,   0
                                dc.w     500,   0
                                dc.w     500, 500
                                dc.w    -500, 500
TLRotatingBg_Angle:             dc.w    -2*16*50+4
TLRotatingBg_RotatedCoords:     ds.w    5*2

TLRotatingText_Angle:           dc.w    0
TLRotatingText_WidthStep:       dc.w    0
TLRotatingText_ColorIndex:      dc.w    0
TLRotatingText_MoveX:           dc.w    0
TLRotatingText_MoveY:           dc.w    0

TLRotatingText_Width:           dc.w    1
TLRotatingText_CenterX:         dc.w    0
TLRotatingText_CenterY:         dc.w    0
TLRotatingText_Palette:
                                ;dc.w    $023,$134,$245,$356,$367,$477,$578,$699
                                ;dc.w    $7aa,$8ab,$9bc,$9cd,$add,$bee,$cff,$dff
                                dc.w    $222,$323,$333,$444,$544,$655,$756,$866
                                dc.w    $877,$977,$a88,$b98,$ca9,$cb9,$dba,$eca

TLSine_CharPositions:           ds.w    11*2
TLSine_Movements:               dc.w    0,0,0,0,0,0,0,0,0,0,0
TLSine_MovementCount:           dc.w    1
TLSine_FromPalette:             dc.w    $0222,$0eca,$0eca,$0222
TLSine_ToPalette:               dc.w    $0fff,$0fff,$0fff,$0fff
