        even
DotEffect:
        movem.l d0-d2/a0-a2,-(sp)

        move.l  DrawBuffer,a0
        lea.l   .pixelTable,a1
        lea.l   .mulTab,a2
        lea.l   Sintab,a3
        lea.l   Costab,a4

        move.w  .x,d0
        sub.w   .cx,d0

        move.w  .a,d1
        move.w  (a4,d1.w),d1
        muls    d1,d0
        asr.l   #8,d0
        asr.l   #7,d0
        add.w   .cx,d0

        move.b  d0,d1
        and.w   #$f,d1
        move.b  (a1,d1.w),d1

        lsr.w   #3,d0
        move.w  .y,d2
        add.w   d2,d2
        add.w   (a2,d2),d0
        or.b    d1,(a0,d0.w)




.pDone:
        movem.l (sp)+,d0-d2/a0-a2
        rts

        even
.pixelTable:
        dc.b    %10000000
        dc.b    %01000000
        dc.b    %00100000
        dc.b    %00010000
        dc.b    %00001000
        dc.b    %00000100
        dc.b    %00000010
        dc.b    %00000001

.mulTab:
I       SET     0
        REPT    256
        dc.w    40*I
I       SET     I+1
        ENDR

.cx:     dc.w    320/2
.cy:     dc.w    256/2

.x:     dc.w    (320/2)+16
.y:     dc.w    256/2
.a:     dc.w    0