Quads_Init:
        lea.l   TLPalette,a0
        move.w  #$fff,6(a0)

        rts

Quads_Run:
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

        bsr     DL_Init

        lea.l   Quads_Origins(pc),a2
        lea.l   Quads_Z(pc),a4
        lea.l   Quads_Angles(pc),a5
        moveq   #4-1,d7
.quadLoop:
        tst.w   (a4)
        bne.s   .doRotate
        
        ; Just copy if not movement is started for the quad
        lea.l   Quads_Coords(pc),a0
        lea.l   Quads_RotatedCoords(pc),a1
        move.w  (a0),16(a1)
        move.w  2(a0),18(a1)
        move.w  #15,20(a1)      ; Front facing normal
        moveq   #4-1,d6
.copy:  move.w  (a0)+,(a1)+
        move.w  (a0)+,(a1)+
        adda.l  #2,a0
        dbf     d6,.copy
        bra     .drawPoly

.doRotate:
        ; Rotate the quad
        move.w  (a5)+,d0
        move.w  d0,d1
        move.w  d0,d2
        bsr     InitRotate

        lea.l   Quads_Coords(pc),a0
        lea.l   Quads_RotatedCoords(pc),a1
        moveq   #4-1,d6
.rotate:
        ; Rotate
        movem.w (a0)+,d0-d2
        bsr     RotatePoint
        ; Project
        move.w  (a4),d4
        add.w   #64,d4
        ext.l   d0
        asl.l   #7,d0
        divs    d4,d0
        move.w  d0,(a1)+
        ext.l   d1
        asl.l   #7,d1
        divs    d4,d1
        move.w  d1,(a1)+
        dbf     d6,.rotate
        
        ; Rotate normal
        movem.w (a0)+,d0-d2
        bsr     RotatePoint
        asr.w   #1,d2           ; Scale down to 1-15
        and.w   #$7fff,d2       ; Keep only absolute (positive) value
        move.w  d2,Quads_RotatedCoords+20

.drawPoly:
        lea.l   Quads_RotatedCoords(pc),a3
        move.w  (a3),16(a3)
        move.w  2(a3),18(a3)
        moveq   #4-1,d6
.lineLoop:
        move.l  DrawBuffer(pc),a0
        move.w  (a3)+,d0
        move.w  (a3)+,d1
        move.w  (a3),d2
        move.w  2(a3),d3

        ; Add origins (x,y)
        move.w  (a2),d4
        add.w   d4,d0
        add.w   d4,d2
        move.w  2(a2),d4
        add.w   d4,d1
        add.w   d4,d3

        moveq   #40,d4
        bsr     DrawLineFilledPoly

        dbf     d6,.lineLoop
        addq.l  #4,a2
        addq.l  #2,a4

        lea.l   Quads_RotatedCoords,a0
        ; move.w  Quads_ZAngle,d0
        move.w  20(a0),d0
        and.w   #$f,d0
        move.w  d0,d1
        lsl.w   #4,d1
        or.w    d1,d0
        lsl.w   #4,d1
        or.w    d1,d0
        lea.l   TLPalette,a0
        move.w  d0,6(a0)

        dbf     d7,.quadLoop

        ; Fill poly
        movea.l	DrawBuffer(pc),a0
        lea.l	255*40+38(a0),a0
        bsr     WaitBlitter
        move.w	#$09f0,$40(a6)
        move.w	#$0012,$42(a6)	; Descending and fill
        move.l	#0,$64(a6)	; Clear A & D modulo
        move.l	a0,$50(a6)	; Src A
        move.l	a0,$54(a6)	; Dest (D)
        move.w	#256*64+20,$58(a6)	; BltSize
        bsr     WaitBlitter

        rts

Quads_Interrupt:
        movem.l a0-a2,-(sp)
        lea.l   Quads_FrameCounter(pc),a1
        lea.l   Quads_Angles(pc),a2
        add.w   #1,(a1)

        lea.l   Quads_Z,a0
        add.w   #2,(a0)

        cmp.w   #25,(a1)
        bmi.s   .exit
        add.w   #4,(a2)

        cmp.w   #50,(a1)
        bmi.s   .exit
        add.w   #2,2(a0)

        cmp.w   #50+25,(a1)
        bmi.s   .exit
        add.w   #-6,2(a2)

        cmp.w   #50*2,(a1)
        bmi.s   .exit
        add.w   #2,4(a0)

        cmp.w   #(50*2)+25,(a1)
        bmi.s   .exit
        add.w   #6,4(a2)

        cmp.w   #50*3,(a1)
        bmi.s   .exit
        add.w   #2,6(a0)

        cmp.w   #(50*3)+25,(a1)
        bmi.s   .exit
        add.w   #-4,6(a2)
.exit:
        movem.l (sp)+,a0-a2
        rts
                        even
Quads_Coords:           dc.w    -80,-64, 0      ; top-left
                        dc.w     79,-64, 0      ; top-right
                        dc.w     79, 63, 0      ; bottom-right
                        dc.w    -80, 63, 0      ; bottom-left
                        dc.w      0,  0, 64     ; normal
Quads_RotatedCoords:    ds.w    10+1
Quads_Origins:          dc.w    160-80, 128-64
                        dc.w    160+79, 128+63
                        dc.w    160+79, 128-64
                        dc.w    160-80, 128+63
Quads_Z:                dc.w    0, 0, 0, 0
Quads_Angles:           dc.w    0, 0, 0, 0
Quads_FrameCounter:     dc.w    0