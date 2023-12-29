************************************************************
Credits_Init:
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
	lea	TLBplPtrs+2,a1
	moveq	#1-1,d1
	bsr.w	SetBpls

        move.w  #$fff,TLPalette+6

	move.l	#TLCopper,$80(a6)
        rts

************************************************************
Credits_Run:
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

        lea.l   Credits_CubeAngles(pc),a0
        movem.w (a0)+,d0-d2
        bsr     InitRotate

        lea.l   Credits_CubeCoords(pc),a0
        lea.l   Credits_CubePosition(pc),a1
        lea.l   Credits_Balls(pc),a2
        lea.l   Credits_MorphTarget(pc),a3
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

        lea.l   Credits_Text(pc),a0
        lea.l   Font,a1
        lea.l   Credits_MorphTarget(pc),a2
        move.l  DrawBuffer(pc),a3
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

        cmp.w   #250,d0
        bgt.b   .morph1
        bra     .rotate
.morph1:
        cmp.w   #314,d0
        bgt     .text1
        add.w   #1,Credits_MorphStep
        bra     .rotate

.text1: cmp.w   #470,d0
        bgt.s   .morphBack1
        add.w   #1,Credits_PrintText
        bra     .rotate

.morphBack1:
        cmp.w   #534,d0
        bgt.s   .wait
        move.w  #0,Credits_PrintText
        sub.w   #1,Credits_MorphStep
        bra     .rotate
.wait:

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
Credits_LocalFrameCounter:
                        dc.w    0
Credits_PrintText:      dc.w    0
Credits_Text:           dc.b    '-INSANE-'
                        even
Credits_TextCounter:    dc.w    0
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
Credits_MorphTarget:    dc.w    96,124
                        dc.w    112,124
                        dc.w    128,124
                        dc.w    144,124
                        dc.w    160,124
                        dc.w    176,124
                        dc.w    192,124
                        dc.w    208,124

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
