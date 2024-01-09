STRIPEWALL_ROWS         = 256
STRIPEWALL_ROWSIZE      = 2+2+(4*2)+(2*3)

SW_BPLCON1              = 2
SW_BPL1PTH              = 6
SW_BPL1PTL              = 10
SW_BPL2PTH              = 14
SW_BPL2PTL              = 18
SW_COL01                = 22
SW_COL02                = 26
SW_COL03                = 30

************************************************************
StripeWall_Init:
        movem.l d0-d7/a0-a6,-(sp)
        bsr     StripeWall_CreateCopper
        bsr     StripeWall_CreateShadeTable

	move.l	#StripeWallCopper,$80(a6)
        movem.l (sp)+,d0-d7/a0-a6
        rts

************************************************************
; Dummy:  dc.w    0
StripeWall_Run:
        movem.l d0-d7/a0-a6,-(sp)
	; movem.l	DrawBuffer(PC),a2-a3
	; exg	a2,a3
	; movem.l	a2-a3,DrawBuffer

	; move.l	a3,a0
        ; moveq   #0,d0
	; lea	MainBplPtrs+2,a1
	; moveq	#1-1,d1
	; bsr.w	SetBpls

	; move.l	a2,a0
        ; move.l  #(256<<6)+(320>>4),d0
	; bsr	BltClr
	; bsr	WaitBlitter

;         add.w   #1,Dummy
;         move.w  Dummy,d0
;         and.w   #1,d0
;         beq.s   .render
;         rts
; .render:

        bsr     StripeWall_RenderWall

        bsr     StripeWall_RotateBars
        bsr     StripeWall_RenderBars

        move.b  $bfec01,d0
        not.b   d0
        ror.b   #1,d0
        cmp.b   #$4c,d0         ; Up key
        bne.s   .down
        add.w   #1,StripeWallBarZ
        bra.s   .done
.down:  cmp.b   #$4d,d0         ; Down key
        bne.s   .done
        sub.w   #1,StripeWallBarZ
.done:

        movem.l (sp)+,d0-d7/a0-a6
        rts

************************************************************
StripeWall_Interrupt:
        add.w	#6,StripeWallBarAngles

        cmp.w   #70,StripeWallBarZ
        ble.s   .done
        sub.w   #1,StripeWallBarZ
.done:
        rts

************************************************************
StripeWall_CreateCopper:
        lea.l   StripeWallBplPtrs,a0
        lea.l   StripeWallBplPtrList(pc),a1
        move.l  #$2b01fffe,d0
        move.w  #STRIPEWALL_ROWS-1,d7
.createCopRows:
        add.l   #$01000000,d0
        move.l  d0,(a0)+
        move.l  a0,(a1)+
        move.l  #$010200f0,(a0)+
        move.l  #$00e00000,(a0)+
        move.l  #$00e20000,(a0)+
        move.l  #$00e40000,(a0)+
        move.l  #$00e60000,(a0)+
        ; move.l  #$01800000,(a0)+
        move.l  #$01820000,(a0)+
        move.l  #$01840fff,(a0)+
        move.l  #$01860fff,(a0)+

        cmp.l   #$ff01fffe,d0
        bne.s   .notLastRow
        move.l  #$ffdffffe,(a0)+
.notLastRow:
        dbf     d7,.createCopRows
        rts

StripeWall_CreateShadeTable:
        lea.l   StripeWallShadeList(pc),a1
        lea.l   StripeWallShadeTable(pc),a0
        move.w  (a1)+,d0
        move.w  (a1)+,d1
        move.w  #64,d2
        jsr     CreateShadeTable
        lea.l   StripeWallShadeTable2(pc),a0
        move.w  (a1)+,d0
        move.w  (a1)+,d1
        move.w  #64,d2
        jsr     CreateShadeTable
        rts

StripeWall_RenderWall:
        move.w  StripeWallScroll,d4
        sub.w   #8,StripeWallScroll
        and.w   #$7fe,d4
        lea.l   Sintab,a0
        move.w  (a0,d4.w),d4
        asr.w   #8,d4
        and.w   #31,d4

        lea.l   StripeWallBplPtrList,a0
        lea.l   StripesPattern,a1
        lea.l   20(a1),a1
        lea.l   StripeWallZPositions(pc),a3
        lea.l   StripeWallMovements(pc),a4
        lea.l   StripeWallShadeTable(pc),a5
        move.w  #STRIPEWALL_ROWS-1,d7
.setBpls:
        move.l  (a0)+,a2

        move.l  a1,d0
        move.w  (a3)+,d1

        move.w  d1,d2
        add.w   d2,d2
        move.w  (a5,d2.w),SW_COL01(a2)
        
        move.w  d1,d2

        ; mulu    #80,d1
        ; Below optimization saves 6 rasterlines
        lsl.w   #4,d1
        move.w  d1,d3
        lsl.w   #2,d3
        add.w   d3,d1

        add.l   d1,d0

        add.w   d2,d2
        move.w  (a4,d2.w),d1

        move.w  d4,d2
        mulu    d1,d2

        lsr.w   #6,d2
        move.w  d2,d3
        not.w   d2
        and.w   #15,d2
        or.w    #$f0,d2
        move.w  d2,SW_BPLCON1(a2)

        lsr.w   #4,d3
        and.w   #63,d3
        add.w   d3,d3
        add.w   d3,d0

        move.w  d0,SW_BPL1PTL(a2) 
        swap    d0
        move.w  d0,SW_BPL1PTH(a2)
        swap    d0

.skip:  dbf     d7,.setBpls
        rts

StripeWall_RotateBars:
        lea.l	StripeWallBarAngles(pc),a0
        movem.w (a0),d0-d2
        jsr     InitRotate

        lea.l 	StripeWallBarCoords(pc),a0
        lea.l	StripeWallBarRotatedCoords(pc),a1
        lea.l	StripeWallBarProjectedCoords(pc),a2
        moveq	#4-1,d7
.rotate:
        movem.w	(a0)+,d0-d2
        jsr     RotatePoint

        movem.w	d0-d2,(a1)
        addq.l	#6,a1

        ; add.w	#110,d2
        add.w   StripeWallBarZ,d2
        ; Project x
        ext.l   d0
        asl.l   #7,d0
        divs    d2,d0

        ; Project y
        ext.l   d1
        asl.l   #7,d1
        divs    d2,d1

        add.w 	#320>>1,d0
        add.w	#256>>1,d1
        move.w 	d0,(a2)+
        move.w	d1,(a2)+

        dbf	d7,.rotate
        rts

StripeWall_RenderBars:
        lea.l	StripeWallBarProjectedCoords(pc),a0
        lea.l	StripeWallBarProjectedCoords+4(pc),a1
        lea.l	StripeWallBplPtrList,a2
        lea.l   Triangle,a3
        lea.l   StripeWallShadeTable2(pc),a5
        moveq	#4-1,d7

        move.w  #256,StripeWall_MinY
        move.w  #0,StripeWall_MaxY
.draw:

        movem.w	(a0)+,d0-d1
        movem.w	(a1)+,d2-d3

        cmp.w   StripeWall_MinY,d1
        bgt.s   .testMinY2
        move.w  d1,StripeWall_MinY
.testMinY2:
        cmp.w   StripeWall_MinY,d3
        bgt.s   .testMaxY
        move.w  d3,StripeWall_MinY
.testMaxY:
        cmp.w   StripeWall_MaxY,d1
        bmi.s   .testMaxY2
        move.w  d1,StripeWall_MaxY
.testMaxY2:
        cmp.w   StripeWall_MaxY,d3
        bmi.s   .testDone
        move.w  d3,StripeWall_MaxY
.testDone:

        cmp.w	d1,d3
        blo	.backside

        sub.w	d1,d3
        beq.s   .backside

        lsl.w	#7,d0
        lsl.w	#7,d2

        sub.w	d0,d2
        ext.l	d2
        divs.w	d3,d2

.render:
        move.w	d0,d4
        lsr.w	#8,d4
        move.w  d4,d6
        ; lsr.w   #1,d6
        add.w   d6,d6
        move.w  (a5,d6.w),d6

        mulu	#40,d4

        move.l	a3,d5
        add.l	d4,d5

        move.w  d1,d4
        lsl.w   #2,d4
        move.l  (a2,d4.w),a4
        move.w  d6,SW_COL02(a4)
        move.w  d6,SW_COL03(a4)
        move.w	d5,SW_BPL2PTL(a4) ;,d1.w)
        swap	d5
        move.w	d5,SW_BPL2PTH(a4) ;,d1.w)

        ; ; add.w	#STRIPEWALL_ROWSIZE*2,d1
        addq.w  #1,d1
        add.w	d2,d0
        dbf	d3,.render

.backside:
        cmp.l	#StripeWallBarProjectedCoords+(4*2*2),a1
        bne.s	.ok
        lea.l	StripeWallBarProjectedCoords(pc),a1
.ok:
        dbf	d7,.draw

        move.l  #BlankLine,d0
        lea.l   StripeWallBplPtrList(pc),a0
        move.w  StripeWall_MinY(pc),d7
        subq.w  #1,d7
.clear1:
        move.l  (a0)+,a1
        move.w  d0,SW_BPL2PTL(a1)
        swap    d0
        move.w  d0,SW_BPL2PTH(a1)
        swap    d0
        dbf     d7,.clear1

        lea.l   StripeWallBplPtrList(pc),a0
        move.w  StripeWall_MaxY(pc),d6
        move.w  #256,d7
        sub.w   d6,d7
        lsl.w   #2,d6
        lea.l   (a0,d6.w),a0
        subq.w  #1,d7
.clear2:
        move.l  (a0)+,a1
        move.w  d0,SW_BPL2PTL(a1)
        swap    d0
        move.w  d0,SW_BPL2PTH(a1)
        swap    d0
        dbf     d7,.clear2

        rts

************************************************************
                        even
StripeWallBplPtrList:   ds.l    STRIPEWALL_ROWS
StripeWallScroll:       dc.w    0
StripeWallZPositions:   
                        ; REPT    256
                        ; dc.w    31
                        ; ENDR
                        REPT    32
                        dc.w    63
                        ENDR
Z                       SET     63
                        REPT    32
                        dc.w    Z 
Z                       SET     Z-2
                        ENDR
                        REPT    128
                        dc.w    0 
                        ENDR
Z                       SET     0
                        REPT    32
                        dc.w    Z 
Z                       SET     Z+2
                        ENDR
                        REPT    32
                        dc.w    63
                        ENDR

StripeWallMovements:
X                       SET     64
                        REPT    64
                        dc.w    X
X                       SET     X+3
                        ENDR

StripeWallShadeList:    dc.w    $245,$adf
                        dc.w    $afd,$254
                        ; dc.w    $fff,$000
StripeWallShadeTable:   ds.w    64
StripeWallShadeTable2:  ds.w    160

** Horizontal rotating bar
StripeWallBarAngles:    dc.w	$10e,0,0
StripeWallBarCoords:    dc.w	-100,-30, 30
			dc.w 	-100,-30,-30
			dc.w 	-100, 30,-30
			dc.w 	-100, 30, 30
StripeWallBarRotatedCoords:	
                        ds.w	4*3
StripeWallBarProjectedCoords:
                        ds.w	4*2
StripeWallBarZ:         dc.w    200

StripeWall_MinY:        dc.w    0
StripeWall_MaxY:        dc.w    0

************************************************************
