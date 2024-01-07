STRIPEWALL_ROWS         = 256
STRIPEWALL_ROWSIZE      = 2+2+(1*4)+(2*1)

SW_BPLCON1              = 2
SW_BPL1PTH              = 6
SW_BPL1PTL              = 10
SW_COL01                = 14

************************************************************
StripeWall_Init:
        lea.l   StripeWallBplPtrs,a0
        lea.l   StripeWallBplPtrList(pc),a1
        move.l  #$2b01fffe,d0
        move.w  #STRIPEWALL_ROWS-1,d7
.createCopRows:
        add.l   #$01000000,d0
        move.l  d0,(a0)+
        move.l  a0,(a1)+
        move.l  #$01020000,(a0)+
        move.l  #$00e00000,(a0)+
        move.l  #$00e20000,(a0)+
        ; move.l  #$01800000,(a0)+
        move.l  #$01820000,(a0)+

        cmp.l   #$ff01fffe,d0
        bne.s   .notLastRow
        move.l  #$ffdffffe,(a0)+
.notLastRow:
        dbf     d7,.createCopRows

	move.l	#StripeWallCopper,$80(a6)
        rts

************************************************************
Dummy:  dc.w    0
StripeWall_Run:
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

        add.w   #1,Dummy
        move.w  Dummy,d0
        and.w   #1,d0
        beq.s   .render
        rts
.render:
        move.w  StripeWallScroll,d4
        add.w   #1,StripeWallScroll
        and.w   #31,d4

        lea.l   StripeWallBplPtrList,a0
        lea.l   StripesPattern,a1
        lea.l   20(a1),a1
        lea.l   StripeWallZPositions(pc),a3
        lea.l   StripeWallMovements(pc),a4
        move.w  #STRIPEWALL_ROWS-1,d7
.setBpls:
        move.l  (a0)+,a2

        move.l  a1,d0
        move.w  (a3)+,d1

        move.w  d1,d2
        mulu    #80,d1
        add.l   d1,d0

        add.w   d2,d2
        move.w  (a4,d2.w),d1
        move.w  (a3),d2

        add.w   d1,d2
        tst.b   d4
        bne.s   .move
        move.w  #0,d2
.move:  move.w  d2,(a3)+

        lsr.w   #6,d2
        move.w  d2,d3
        not.w   d2
        and.w   #15,d2
        move.w  d2,SW_BPLCON1(a2)

        lsr.w   #4,d3
        and.w   #63,d3
        add.w   d3,d3
        add.w   d3,d0

        move.w  d0,SW_BPL1PTL(a2) 
        swap    d0
        move.w  d0,SW_BPL1PTH(a2)
        swap    d0
        move.w  #$0fff,SW_COL01(a2)

.skip:  dbf     d7,.setBpls
        rts

************************************************************
StripeWall_Interrupt:
        rts

************************************************************
                        even
StripeWallBplPtrList:   ds.l    STRIPEWALL_ROWS
StripeWallScroll:       dc.w    0
StripeWallZPositions:   
                        REPT    32
                        dc.w    63,0
                        ENDR
Z                       SET     63
                        REPT    32
                        dc.w    Z,0
Z                       SET     Z-2
                        ENDR
                        REPT    128
                        dc.w    0,0
                        ENDR
Z                       SET     0
                        REPT    32
                        dc.w    Z,0
Z                       SET     Z+2
                        ENDR
                        REPT    32
                        dc.w    63,0
                        ENDR

StripeWallMovements:
X                       SET     64
                        REPT    64
                        dc.w    X
X                       SET     X+3
                        ENDR