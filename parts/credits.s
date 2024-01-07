************************************************************
Credits_Init:
	lea	Screen,a0
        move.l  #(256<<6)+(320>>4)*2,d0
	bsr.w	BltClr
	lea	Screen2,a0
        move.l  #(256<<6)+(320>>4)*2,d0
	bsr.w	BltClr
	bsr	WaitBlitter

	lea	Screen,a0
	move.l	#(320>>3)*256,d0
        ; moveq   #0,d0
	lea	MainBplPtrs+2,a1
	moveq	#2-1,d1
	bsr.w	SetBpls

        lea.l   Screen,a0
        add.l   #(320>>3)*256,a0
        move.l  a0,Credits_TextScr

        move.w  #$0b54,MainPalette+2
        move.w  #$0b54,MainPalette+6
        move.w  #$0b54,MainPalette+10
        move.w  #$0b54,MainPalette+14
        move.w  #$2200,MainBplCon+2

        bsr     InitFade

	move.l	#MainCopper,$80(a6)
        rts

************************************************************
Credits_Run:
	movem.l	DrawBuffer(PC),a2-a3
	exg	a2,a3
	movem.l	a2-a3,DrawBuffer

	move.l	a3,a0
        moveq   #0,d0
	lea	MainBplPtrs+2,a1
	moveq	#1-1,d1
	bsr.w	SetBpls

	move.l	a2,a0
        move.l  #(256<<6)+(320>>4),d0
	bsr	BltClr

        lea.l   Credits_FromPalette,a0
        lea.l   Credits_ToPalette,a1
        lea.l   MainPalette,a2
        moveq   #32,d0
        moveq   #4-1,d1
        bsr     Fade
.fadeDone:

	bsr	WaitBlitter
 
        lea.l   Credits_CubeAngles(pc),a0
        movem.w (a0)+,d0-d2
        bsr     InitRotate

        lea.l   Credits_CubeCoords(pc),a0
        lea.l   Credits_CubePosition(pc),a1
        lea.l   Credits_Balls(pc),a2
        movea.l Credits_MorphTargetPtr(pc),a3
        move.l  DrawBuffer(pc),a4

        moveq   #8-1,d7
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

        move.w  Credits_MorphStep(pc),d6
        beq.s   .calcScreenOffset
        move.w  (a3)+,d3
        sub.w   d0,d3
        muls    d6,d3
        asr.w   #6,d3
        add.w   d3,d0
        move.w  (a3)+,d3
        sub.w   d1,d3
        muls    d6,d3
        asr.w   #6,d3
        add.w   d3,d1

.calcScreenOffset:
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

.next:  dbf     d7,.rotate

        move.w  Credits_PrintText(pc),d7
        beq.s   .done
        lsr.w   #4,d7
        subq.w  #1,d7
        bmi     .done

        movea.l Credits_TextPtr(pc),a0
        lea.l   Font,a1
        movea.l Credits_MorphTargetPtr(pc),a2
        move.l  Credits_TextScr(pc),a3
.print:
        move.w  (a2)+,d0
        move.w  (a2)+,d1
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
        bne     .printText
        ; Use 64 for morphing to straight line
        cmp.w   #72,Credits_MorphStep
        beq.s   .rotate
        add.w   #1,Credits_MorphStep
        bra     .rotate

.printText:
        cmp.w   #2,d1
        bne.s   .morphOut
        cmp.w   #128,Credits_PrintText
        beq.s   .rotate
        add.w   #1,Credits_PrintText
        bra     .rotate

.morphOut:
        cmp.w   #3,d1
        bne.s   .rotate
        cmp.w   #0,Credits_PrintText
        beq.s   .mo2
        add.l   #8,Credits_TextPtr
.mo2:   move.w  #0,Credits_PrintText
        cmp.w   #0,Credits_MorphStep
        beq.s   .rotate
        sub.w   #1,Credits_MorphStep
        tst.w   Credits_MorphStep
        bne.s   .rotate
        add.l   #8*2*2,Credits_MorphTargetPtr

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
        bgt     .skipMove
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
                        even
                        ; Effect types
                        ; 0 = Rotate
                        ; 1 = Morph in
                        ; 2 = Print text
                        ; 3 = Morph out
Credits_TimingTable:    dc.w    150,0
                        dc.w    250,1
                        dc.w    450,2
                        dc.w    550,3
                        dc.w    100+550,0
                        dc.w    200+550,1
                        dc.w    400+550,2
                        dc.w    500+550,3
                        dc.w    100+550+500,0
                        dc.w    200+550+500,1
                        dc.w    400+550+500,2
                        dc.w    500+550+500,3
Credits_TimingPointer:  dc.l    Credits_TimingTable
Credits_LocalFrameCounter:
                        dc.w    0
Credits_PrintText:      dc.w    0
Credits_Text:           dc.b    'GERP  24'
                        dc.b    'PROSPECT'
                        dc.b    ' VEDDER '
                        even
Credits_TextPtr:        dc.l    Credits_Text
Credits_TextScr:        dc.l    0
Credits_CubeCoords:     dc.w    -128,-128,-128
                        dc.w     128,-128,-128
                        dc.w     128, 128,-128
                        dc.w    -128, 128,-128
                        dc.w    -128,-128, 128
                        dc.w     128,-128, 128
                        dc.w     128, 128, 128
                        dc.w    -128, 128, 128
Credits_CubeRotatedCoords:
                        ds.w    3*8
Credits_CubeAngles:     dc.w    0,0,0
Credits_CubePosition:   dc.w    0,0,600
Credits_PosMove:        dc.w    0
Credits_CubeXCenter:    dc.w    320/2
Credits_CubeYCenter:    dc.w    256/2
Credits_MorphStep:      dc.w    0
Credits_MorphTarget:
X                       SET     96
                        REPT    8
                        dc.w    X,124
X                       SET     X+16
                        ENDR

X                       SET     168
                        REPT    8
                        dc.w    X,72
X                       SET     X+16
                        ENDR

X                       SET     48
                        REPT    8
                        dc.w    X,146
X                       SET     X+16
                        ENDR

Credits_MorphTargetPtr: dc.l    Credits_MorphTarget

Credits_FromPalette:    dc.w    $0b54,$0b54,$0b54,$0b54
Credits_ToPalette:      dc.w    $0045,$0f78,$0fbc,$0fff

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
