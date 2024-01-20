Credits_NumPoints = 32

************************************************************
Credits_Init:
	lea	Screen,a0
        move.l  #(256<<6)+(320>>4)*3,d0
	bsr.w	BltClr
	lea	Screen2,a0
        move.l  #(256<<6)+(320>>4)*3,d0
	bsr.w	BltClr
	bsr	WaitBlitter

        lea.l   Screen,a0
        adda.l  #(320>>3)*256,a0
        move.l  a0,Credits_TextScr

	; Balls - bpl 0
        lea	Screen,a0
	lea	CreditsBplPtrs+2,a1
	moveq	#1-1,d1
	bsr.w	SetBpls

        ; Text shadow - bpl 1
	move.l  Credits_TextScr,a0
        adda.l  #40*3,a0
	lea	CreditsBplPtrs+2+8,a1
	moveq   #0,d0
	moveq	#1-1,d1
	bsr.w	SetBpls

        ; Text - bpl 2
	move.l  Credits_TextScr,a0
	lea	CreditsBplPtrs+2+16,a1
	moveq   #0,d0
	moveq	#1-1,d1
	bsr.w	SetBpls

        move.w  #$048b,CreditsPalette+2
        move.w  #$048b,CreditsPalette+6
        move.w  #$048b,CreditsPalette+10
        move.w  #$048b,CreditsPalette+14
        move.w  #$3200,CreditsBplCon+2

        bsr     InitFade

	move.l	#CreditsCopper,$80(a6)
        rts

************************************************************
Credits_Run:
	movem.l	DrawBuffer(PC),a2-a3
	exg	a2,a3
	movem.l	a2-a3,DrawBuffer

	move.l	a3,a0
        moveq   #0,d0
	lea	CreditsBplPtrs+2,a1
	moveq	#1-1,d1
	bsr.w	SetBpls

	move.l	a2,a0
        move.l  #(256<<6)+(320>>4),d0
	bsr	BltClr

        bsr     Credits_MoveShadowLayer
        bsr     Credits_MoveBackgroundLines

        tst.b   Credits_DoExplode
        beq     .noExplode
	
        bsr	WaitBlitter

        lea.l   Credits_CubeRotatedCoords(pc),a0
        lea.l   Credits_Balls(pc),a1
        move.l  DrawBuffer(pc),a3
        lea.l   Credits_ExplodeVelocities,a4
        moveq   #Credits_NumPoints-1,d7
.drawExplode:
        movem.w (a0),d0-d1/d5

        move.w  (a4)+,d2
        add.w   d2,(a0)
        move.w  (a4)+,d2
        add.w   d2,2(a0)
        addq.l  #6,a0

        cmp.w   #0,d0
        bmi.s   .nextBall
        cmp.w   #0,d1
        bmi.s   .nextBall
        cmp.w   #320-8,d0
        bge     .nextBall
        cmp.w   #256-8,d1
        bge     .nextBall

        ; Calculate screen offset
        move.w  d0,d2
        lsr.w   #3,d0
        mulu    #40,d1
        add.w   d0,d1

        ; Get current ball index
        asr.w   #5,d5
        add.w   #4,d5
        bge     .ok11
        moveq   #0,d5
.ok11:  cmp.w   #7,d5
        ble     .ok22
        move    #7,d5
.ok22:  lsl.w   #4,d5
        lea.l   (a1,d5.w),a2

        ; Render ball
        moveq   #8-1,d6
.drawBall1:
        move.w  (a2)+,d3
        and.w   #7,d2
        addq.w  #8,d2
        ror.w   d2,d3
        or.b    d3,(a3,d1.l)
        ror.w   #8,d3
        or.b    d3,1(a3,d1.l)
        add.l   #40,d1
        dbf     d6,.drawBall1
.nextBall:
        dbf     d7,.drawExplode

        bra     .done

.noExplode:
        tst.b   Credits_FadeIn
        bne.s   .fadeDone
        lea.l   Credits_FromPalette,a0
        lea.l   Credits_ToPalette,a1
        lea.l   CreditsPalette,a2
        moveq   #32,d0
        moveq   #8-1,d1
        bsr     Fade
        move.w  CreditsPalette+2,d1
        move.w  d1,CreditsPaletteBg2+2
        move.w  d1,CreditsPaletteBg3+2
        cmp.w   #33,d0
        bmi.s   .fadeDone
        move.w  #$0156,CreditsPaletteBg2+2
        move.w  #$0267,CreditsPaletteBg3+2
        st.b    Credits_FadeIn
        clr.w   FCnt
.fadeDone:
        tst.b   Credits_FlashText
        beq.s   .noFlash
        lea.l   Credits_FlashPaletteFrom,a0
        lea.l   Credits_FlashPaletteTo,a1
        move.l  Credits_FlashPalettePtr,a2
        moveq   #8,d0
        moveq   #6-1,d1
        bsr     Fade
        ; cmp.w   #9,d0
        ; bmi.s   .noFlash
        ; lea.l   Credits_FlashPaletteTo,a0
        ; add.w   #$111,(a0)
        ; add.w   #$111,4(a0)
        ; add.w   #$111,8(a0)

.noFlash:

	bsr	WaitBlitter
 
        lea.l   Credits_CubeAngles(pc),a0
        movem.w (a0)+,d0-d2
        bsr     InitRotate

        lea.l   Credits_CubeCoords(pc),a0
        lea.l   Credits_CubePosition(pc),a1
        lea.l   Credits_Balls(pc),a2
        movea.l Credits_MorphTargetPtr(pc),a3
        move.l  DrawBuffer(pc),a4
        lea.l   Credits_CubeRotatedCoords(pc),a5

        moveq   #0,d4
        moveq   #Credits_NumPoints-1,d7
.rotate:movem.w (a0)+,d0-d2
        bsr     RotatePoint
        move.w  d2,d5
        
        ; Add object offset
        add.w   (a1),d0
        add.w   2(a1),d1
        add.w   4(a1),d2

        ; Project x
        ext.l   d0
        asl.l   #7,d0
        divs    d2,d0
        add.w   Credits_CubeXCenter(pc),d0
        bmi     .next

        ; Project y
        ext.l   d1
        asl.l   #7,d1
        divs    d2,d1
        add.w   Credits_CubeYCenter(pc),d1
        
        movem.w d0-d1/d5,(a5)
        addq.l  #6,a5

        move.w  Credits_MorphStep(pc),d6
        beq.s   .calcScreenOffset
        move.w  (a3),d3
        add.w   d4,d3
        addq.w  #2,d4
        sub.w   d0,d3
        muls    d6,d3
        asr.w   #5,d3
        add.w   d3,d0
        move.w  2(a3),d3
        sub.w   d1,d3
        muls    d6,d3
        asr.w   #5,d3
        add.w   d3,d1

.calcScreenOffset:
        move.l  a5,-(sp)
        ; Calculate screen offset
        move.w  d0,d2
        lsr.w   #3,d0
        mulu    #40,d1
        add.w   d0,d1

        ; Get current ball index
        asr.w   #5,d5
        add.w   #4,d5
        bge     .ok1
        moveq   #0,d5
.ok1:   cmp.w   #7,d5
        ble     .ok2
        move    #7,d5
.ok2:   lsl.w   #4,d5
        lea.l   (a2,d5.w),a5

        ; Render ball
        moveq   #8-1,d6
.drawBall:
        move.w  (a5)+,d3
        and.w   #7,d2
        addq.w  #8,d2
        ror.w   d2,d3
        or.b    d3,(a4,d1.l)
        ror.w   #8,d3
        or.b    d3,1(a4,d1.l)
        add.l   #40,d1
        dbf     d6,.drawBall

        move.l  (sp)+,a5

.next:  dbf     d7,.rotate

        move.w  Credits_PrintText(pc),d7
        beq.s   .done
        lsr.w   #2,d7
        cmp.w   #8,d7
        bhi.s   .done
        subq.w  #1,d7
        bmi     .done

        movea.l Credits_TextPtr(pc),a0
        lea.l   Font,a1
        movea.l Credits_PositionPtr(pc),a2
        move.l  Credits_TextScr(pc),a3
        moveq   #0,d3
.print:
        move.w  (a2),d0
        add.w   d3,d0
        addq.w  #8,d3
        move.w  2(a2),d1
        asr.w   #3,d0
        mulu    #40,d1
        add.w   d0,d1

        move.b  (a0)+,d2
        sub.b   #' ',d2
        and.w   #255,d2
        asl.w   #3,d2
        lea.l   (a1,d2.w),a4
        lea.l   (a3,d1.l),a5

        REPT    8
        move.b  (a4)+,(a5)
        lea.l   40(a5),a5
        ENDR

        dbf     d7,.print
.done:
        rts
 
************************************************************
Credits_Interrupt:
        movem.l d0-d1/a0-a2,-(sp)

        add.w   #1,Credits_LocalFrameCounter
        move.w  Credits_LocalFrameCounter,d0

        add.w   #32,Credits_ShadowMoveX
        add.w   #24,Credits_ShadowMoveY

.runFx:
        movea.l Credits_TimingPointer(pc),a0
        move.w  (a0)+,d1
        cmp.w   d1,d0
        blo.s   .run
        add.l   #4,Credits_TimingPointer
        bra     .runFx
.run:   move.w  (a0)+,d1
        cmp.w   #0,d1
        beq     .rotate

.morphIn:
        cmp.w   #1,d1
        bne.s   .printText

        cmp.w   #40,Credits_MorphStep
        beq     .rotate
        add.w   #1,Credits_MorphStep
        bra     .rotate

.printText:
        cmp.w   #2,d1
        bne.s   .morphOut
        cmp.w   #128,Credits_PrintText
        beq     .rotate
        add.w   #1,Credits_PrintText
        bra    .rotate

.morphOut:
        cmp.w   #3,d1
        bne.s   .initFlash
        cmp.w   #0,Credits_PrintText
        beq.s   .mo2
        add.l   #8,Credits_TextPtr
.mo2:   move.w  #0,Credits_PrintText
        cmp.w   #0,Credits_MorphStep
        beq.s   .rotate
        sub.w   #1,Credits_MorphStep
        tst.w   Credits_MorphStep
        bne.s   .rotate
        addq.l  #4,Credits_MorphTargetPtr
        addq.l  #4,Credits_PositionPtr
        bra.s   .rotate

.initFlash: 
        cmp.w   #4,d1
        bne.s   .flash
        clr.b   Credits_FlashText
        clr.w   FCnt
        add.l   #16*2,Credits_FlashPalettePtr

        cmp.l   #CreditsPaletteLine1,Credits_FlashPalettePtr
        beq     .rotate

        lea.l   Credits_FlashPaletteTo,a0
        add.w   #$111,(a0)
        add.w   #$111,4(a0)
        add.w   #$111,8(a0)
        bra.s   .rotate

.flash: cmp.w   #5,d1
        bne.s   .explode
        move.b  #1,Credits_FlashText
        bra.s   .rotate

.explode:
        cmp.w   #6,d1
        bne.s   .rotate
        move.b  #1,Credits_DoExplode
        bra.s   .exit

.rotate:
        lea.l   Credits_CubeAngles(pc),a0
        add.w   #2,(a0)
        add.w   #6,2(a0)
        sub.w   #-2,4(a0)

        lea.l   Sintab(pc),a0
        lea.l   Costab(pc),a1
        lea.l   Credits_CubePosition(pc),a2
        move.w  Credits_PosMove(pc),d0
        cmp.w   #512,d0
        bgt.s   .skipMove
        move.w  (a1,d0.w),d1
        lsr.w   #6,d1
        add.w   #200,d1
        move.w  d1,4(a2)

        move.w  (a0,d0.w),d1
        lsr.w   #7,d1
        sub.w   #256-160,d1
        move.w  d1,Credits_CubeXCenter

        add.w   #4,Credits_PosMove
.skipMove:

.exit:
        movem.l (sp)+,d0-d1/a0-a2
        rts

************************************************************

Credits_MoveShadowLayer:
        lea.l   Sintab,a0

        move.w  Credits_ShadowMoveX(pc),d0
        and.w   #$7fe,d0
        move.w  (a0,d0.w),d0
        asr.w   #8,d0
        asr.w   #3,d0

        move.w  Credits_ShadowMoveY(pc),d1
        and.w   #$7fe,d1
        move.w  (a0,d1.w),d1
        asr.w   #8,d1
        asr.w   #2,d1

        add.w   d0,d1
        asr.w   #1,d1
        muls    #40,d1

        add.l   Credits_TextScr(pc),d1

        lea.l   CreditsBplPtrs+10,a0

        cmp.w   #0,d0
        bge.s   .pos
        addq.l  #2,d1
        add.w   #16,d0
.pos:
        lsl.b   #4,d0
        and.b   #$f0,d0
        move.b  d0,CreditsBplCon1+1
        move.w  d1,4(a0)
        swap    d1
        move.w  d1,(a0)

        rts

Credits_MoveBackgroundLines:
        lea.l   Sintab,a0
        move.w  Credits_ShadowMoveX,d0
        neg.w   d0
        and.w   #$7fe,d0
        move.w  (a0,d0.w),d0
        asr.w   #8,d0
        asr.w   #3,d0
        add.w   #$80,d0
        move.b  d0,CreditsPalette2Y

        move.w  Credits_ShadowMoveX,d0
        neg.w   d0
        sub.w   Credits_ShadowMoveY,d0
        asr.w   #1,d0
        and.w   #$7fe,d0
        move.w  (a0,d0.w),d0
        asr.w   #8,d0
        asr.w   #3,d0
        add.w   #$d0,d0
        move.b  d0,CreditsPalette3Y
        rts

************************************************************
                        even
                        ; Effect types
                        ; 0 = Rotate
                        ; 1 = Morph in
                        ; 2 = Print text
                        ; 3 = Morph out
                        ; 4 = Flash text
T_OFFS                  = 180
BEAT                    = 48
Credits_TimingTable:    dc.w    T_OFFS+(BEAT*0),0
                        dc.w    T_OFFS+(BEAT*1),1
                        dc.w    T_OFFS+(BEAT*2),2
                        dc.w    T_OFFS+(BEAT*3),3

                        dc.w    T_OFFS+(BEAT*4),0
                        dc.w    T_OFFS+(BEAT*5),1
                        dc.w    T_OFFS+(BEAT*6),2
                        dc.w    T_OFFS+(BEAT*7),3
                        dc.w    T_OFFS+(BEAT*8),0
                        dc.w    T_OFFS+(BEAT*9),1
                        dc.w    T_OFFS+(BEAT*10),2
                        dc.w    T_OFFS+(BEAT*11),3
                        dc.w    T_OFFS+(BEAT*12),0
                        dc.w    T_OFFS+(BEAT*13),1
                        dc.w    T_OFFS+(BEAT*14),2
                        dc.w    T_OFFS+(BEAT*15),3
                        dc.w    T_OFFS+(BEAT*16),0
                        dc.w    T_OFFS+(BEAT*17),1
                        dc.w    T_OFFS+(BEAT*18),2
                        dc.w    T_OFFS+(BEAT*19),3
                        dc.w    T_OFFS+(BEAT*20),0
                        dc.w    T_OFFS+(BEAT*21),1
                        dc.w    T_OFFS+(BEAT*22),2
                        dc.w    T_OFFS+(BEAT*23),3
                        dc.w    T_OFFS+(BEAT*24),0
                        dc.w    T_OFFS+(BEAT*25),1
                        dc.w    T_OFFS+(BEAT*26),2
                        dc.w    T_OFFS+(BEAT*27),3
                        dc.w    T_OFFS+(BEAT*28),0
                        dc.w    T_OFFS+(BEAT*29),1
                        dc.w    T_OFFS+(BEAT*30),2
                        dc.w    T_OFFS+(BEAT*31),3

                        dc.w    1749,0
                        dc.w    1750,4
                        dc.w    1774,5
                        dc.w    1775,4
                        dc.w    1799,5
                        dc.w    1800,4
                        dc.w    1824,5

                        dc.w    1900,6


Credits_TimingPointer:  dc.l    Credits_TimingTable
Credits_LocalFrameCounter:
                        dc.w    0
Credits_PrintText:      dc.w    0
Credits_Text:
                        dc.b    'MUSIC   '
                        dc.b    '  MYGG  '
                        dc.b    'VEDDER  '
                        dc.b    'GRAPHICS'
                        dc.b    'COREL   '
                        dc.b    'VEDDER  '
                        dc.b    'CODE    '
                        dc.b    'PROSPECT'
                        even
Credits_TextPtr:        dc.l    Credits_Text

Credits_FadeIn:         dc.b    0,0

;0123456789012345678901234567890123456789
;****************************************
;
;0123456789012345678901234567890123456789
;    MUSIC       VEDDER       MYGG
;
;0123456789012345678901234567890123456789
;          CODE        PROSPECT
;
;0123456789012345678901234567890123456789
;   GRAPHICS      COREL       VEDDER
CRED_LINE_1             = 28
CRED_LINE_2             = 118
CRED_LINE_3             = 204
Credits_Positions:      dc.w    4*8,CRED_LINE_1
                        dc.w    16*8,CRED_LINE_1
                        dc.w    29*8,CRED_LINE_1
                        dc.w    3*8,CRED_LINE_3
                        dc.w    17*8,CRED_LINE_3
                        dc.w    29*8,CRED_LINE_3
                        dc.w    10*8,CRED_LINE_2
                        dc.w    22*8,CRED_LINE_2
Credits_PositionPtr:    dc.l    Credits_Positions

Credits_TextScr:        dc.l    0
Credits_CubeCoords:
                        dc.w     -64,  64, -64
                        dc.w      64,  64, -64
                        dc.w      64, -64, -64
                        dc.w     128, 128, 128
                        dc.w    -128,-128, 128
                        dc.w     -64,  64, -64
                        dc.w      64, -64,  64
                        dc.w     -64,  64,  64
                        dc.w    -128, 128,-128
                        dc.w     -64, -64, -64
                        dc.w     -64, -64, -64
                        dc.w     -64,  64,  64
                        dc.w    -128, 128, 128
                        dc.w     -64, -64,  64
                        dc.w     -64,  64, -64
                        dc.w     -64, -64,  64
                        dc.w      64,  64,  64
                        dc.w      64, -64,  64
                        dc.w     -64, -64,  64
                        dc.w     128, 128,-128
                        dc.w      64, -64, -64
                        dc.w      64, -64, -64
                        dc.w      64,  64, -64
                        dc.w     -64,  64,  64
                        dc.w    -128,-128,-128
                        dc.w      64, -64,  64
                        dc.w      64,  64,  64
                        dc.w     -64, -64, -64
                        dc.w     128,-128, 128
                        dc.w      64,  64, -64
                        dc.w      64,  64,  64
                        dc.w     128,-128,-128
        
Credits_CubeRotatedCoords:
                        ds.w    3*Credits_NumPoints
Credits_CubeAngles:     dc.w    0,0,0
Credits_CubePosition:   dc.w    0,0,600
Credits_PosMove:        dc.w    0
Credits_CubeXCenter:    dc.w    320/2
Credits_CubeYCenter:    dc.w    256/2
Credits_MorphStep:      dc.w    0
Credits_MorphTarget:    dc.w    48,48
                        dc.w    120,48
                        dc.w    200,48
                        dc.w    48,190
                        dc.w    120,190
                        dc.w    200,190
                        dc.w    70,118
                        dc.w    162,118
Credits_MorphTargetPtr: dc.l    Credits_MorphTarget

Credits_ExplodeVelocities:
                        dc.w    -5,-6, -3,-1, -3,2, 0,-4, -4,-3, -3,3, 1,3, -2,0
                        dc.w    3,5, -2,-4, 0,-2, 2,4, -5,4, 2,-4, -1,-2, -2,-3
                        dc.w    -2,-2, -6,3, 1,-4, -3,4, 2,5, 2,1, 5,-6, -1,1
                        dc.w    3,1, -1,3, -3,-6, -4,-1, -3,2, -2,-1, 4,5, -2,-2
Credits_DoExplode:      dc.b    0,0

Credits_FromPalette:    dc.w    $048b,$048b,$048b,$048b,$048b,$048b,$048b,$048b
Credits_ToPalette:      dc.w    $0045,$0f78,$0555,$0555,$0acc,$0acc,$0acc,$0acc
Credits_FlashPaletteFrom:
                        dc.w    $0555,$0555,$0fff,$0fff,$0fff,$0fff
Credits_FlashPaletteTo: dc.w    $0045,$0f78,$0045,$0f78,$0045,$0f78
Credits_FlashPalettePtr:dc.l    CreditsPaletteLine1-(16*2)

Credits_FlashText:      dc.w    0

Credits_ShadowMoveX:    dc.w    0
Credits_ShadowMoveY:    dc.w    0

Credits_Balls:          dc.b    %00111100,0
                        dc.b    %01111110,0
                        dc.b    %11111111,0
                        dc.b    %11111111,0
                        dc.b    %11111111,0
                        dc.b    %11111111,0
                        dc.b    %01111110,0
                        dc.b    %00111100,0

                        dc.b    %00111000,0
                        dc.b    %01111100,0
                        dc.b    %11111110,0
                        dc.b    %11111110,0
                        dc.b    %11111110,0
                        dc.b    %01111100,0
                        dc.b    %00111000,0
                        dc.b    %00000000,0

                        dc.b    %00000000,0
                        dc.b    %00011000,0
                        dc.b    %00111100,0
                        dc.b    %01111110,0
                        dc.b    %01111110,0
                        dc.b    %00111100,0
                        dc.b    %00011000,0
                        dc.b    %00000000,0

                        dc.b    %00000000,0
                        dc.b    %00010000,0
                        dc.b    %00111000,0
                        dc.b    %01111100,0
                        dc.b    %01111100,0
                        dc.b    %00111000,0
                        dc.b    %00010000,0
                        dc.b    %00000000,0

                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00011000,0
                        dc.b    %00111100,0
                        dc.b    %00111100,0
                        dc.b    %00011000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0

                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00010000,0
                        dc.b    %00111000,0
                        dc.b    %00010000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0

                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00011000,0
                        dc.b    %00011000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0

                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00010000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0
                        dc.b    %00000000,0
