        SECTION EndTextCode,CODE_P

************************************************************
EndText_Init:
        ; lea     Screen,a0
        move.l  DrawBuffer,a0
        move.l  #(((256+12)*2)<<6)+(320>>4),d0
        jsr     BltClr
        ; lea     Screen2,a0
        ; move.l  #(512<<6)+(320>>4),d0
        ; jsr     BltClr
        jsr     WaitBlitter

        move.l  DrawBuffer,a0
        move.l	#40,d0
        lea     EndTextBplPtrs+2,a1
        moveq	#2-1,d1
        jsr     SetBpls

        

        bsr     EndText_CreateBplCon1List

        move.w  #$2200,EndTextBplCon+2
        move.l	#EndTextCopper,$80(a6)

        rts

************************************************************
EndText_Run:
        ; movem.l DrawBuffer,a2-a3
        ; exg     a2,a3
        ; movem.l	a2-a3,DrawBuffer

        ; move.l	a3,a0
        ; move.l	#(320*256)>>3,d0
        ; lea     EndTextBplPtrs+2,a1
        ; moveq	#2-1,d1
        ; jsr     SetBpls

        ; move.l	a2,a0
        ; move.l  #(512<<6)+(320>>4),d0
        ; jsr     BltClr

        ; Dubbelbuffer copper
	movem.l	EndText_BplPtrBuff(PC),a0-a1
	exg	a0,a1
	movem.l	a0-a1,EndText_BplPtrBuff

	movem.l	EndText_BplPtrListBuff(PC),a0-a1
	exg	a0,a1
	movem.l	a0-a1,EndText_BplPtrListBuff

        move.l  EndText_BplPtrBuff+4,d0
        lea.l   EndTextCop2Loc,a0
        move.w  d0,6(a0)
        swap    d0
        move.w  d0,2(a0)

        ; Print and scroll text
        move.w  EndText_LocalFrameCounter,d0
        and.w   #1,d0
        beq     .wave

        cmp.w   #12,EndText_PrintCounter
        bne.s   .scroll
        clr.w   EndText_PrintCounter

        lea.l   EndText_Text(pc),a0
        lea.l   Font,a1
        move.l  DrawBuffer,a2
        adda.l  #80*256,a2
        jsr     TextWriter_Line


.scroll:
        lea.l   $dff000,a6
        jsr	WaitBlitter

	move.l  #$09f00000,bltcon0(a6)
	move.l  #-1,bltafwm(a6)
	move.w  #0,bltamod(a6)
	move.w  #0,bltdmod(a6)
	move.l  DrawBuffer,d0
	move.l  d0,bltdpt(a6)
	add.l   #80,d0
	move.l  d0,bltapt(a6)
	move.w  #(256+12-1)*2*64+20,bltsize(a6)

        addq.w  #1,EndText_PrintCounter

.wave:
        ;**************
        ; lea.l   EndText_BplCon1List(pc),a0
        move.l  EndText_BplPtrListBuff(pc),a0
        lea.l   Sintab,a2
        move.w  .scrollOffset(pc),d0
        move.w  EndText_SinOffset(pc),d3

        and.w   #$7fe,d3
        move.w  (a2,d3.w),d4
        asr.w   #8,d4
        asr.w   #4,d4
        addq.w  #8,d4

        move.w  #256-1,d7
.setScroll:
        move.l  (a0)+,a1
        
        move.w  d4,d1
        and.b   #$f,d1
        move.b  d1,d2
        lsl.b   #4,d2
        or.b    d2,d1
        move.b  d1,3(a1)

        addq.w  #1,d0
        cmp.w   #12,d0
        bne     .next
        moveq   #0,d0

        add.w   #60,d3
        and.w   #$7fe,d3
        move.w  (a2,d3.w),d4
        asr.w   #8,d4
        asr.w   #4,d4
        addq.w  #8,d4


.next:  dbf     d7,.setScroll

        move.w  EndText_LocalFrameCounter,d0
        and.w   #1,d0
        beq     .done

        addq.w  #1,.scrollOffset
        cmp.w   #12,.scrollOffset
        bne.s   .done
        clr.w   .scrollOffset

.done:  rts

                even
.scrollOffset:  dc.w    0

************************************************************
EndText_Interrupt:
        add.w   #1,EndText_LocalFrameCounter
        add.w   #40,EndText_SinOffset

.done:  rts

************************************************************
EndText_CreateBplCon1List:
        lea.l   EndTextBplCon1,a0
        lea.l   EndText_BplCon1List(pc),a1
        lea.l   EndTextBplCon12,a2
        lea.l   EndText_BplCon1List2(pc),a3
        move.l  #$2b01fffe,d0
        move.w  #256-1,d7
.createCopRows:
        add.l   #$01000000,d0
        move.l  d0,(a0)+
        move.l  d0,(a2)+
        move.l  a0,(a1)+
        move.l  a2,(a3)+
        move.l  #$01020000,(a0)+
        move.l  #$01020000,(a2)+

        cmp.l   #$ff01fffe,d0
        bne.s   .notLastRow
        move.l  #$ffdffffe,(a0)+
        move.l  #$ffdffffe,(a2)+
.notLastRow:
        dbf     d7,.createCopRows
        move.l  #$fffffffe,(a0)+
        move.l  #$fffffffe,(a2)+

        rts

************************************************************
                                even
EndText_LocalFrameCounter:      dc.w    0
EndText_TextBuffer:             dc.l    0
EndText_PrintCounter:           dc.w    0
EndText_SinOffset:              dc.w    0
EndText_BplCon1List:            ds.l    256
EndText_BplCon1List2:           ds.l    256
EndText_BplPtrBuff:             dc.l    EndTextBplCon1,EndTextBplCon12
EndText_BplPtrListBuff:         dc.l    EndText_BplCon1List,EndText_BplCon1List2

;		         0123456789012345678901234567890123456789
EndText_Text:	dc.b    10
                dc.b    '01234567890123456789012345678901234567',10
                dc.b    '  AND NOW YOU HAVE REACHED THE ',3,'END',1,' ...  ',10
                dc.b    10
;		         0123456789012345678901234567890123456789
                dc.b    '   ',2,'GRAPHICS / FONT',1,'   COREL ',3,',',1,' VEDDER     ',10
                dc.b    10
                dc.b    '   ',2,'MUSIC',1,'             MR MYGG ',3,',',1,' VEDDER   ',10
                dc.b    10
                dc.b    '   ',2,'CODE',1,'              PROSPECT           ',10
                dc.b    10
                dc.b    10
                dc.b    10
;		         0123456789012345678901234567890123456789
                dc.b    3,'              ***      ***              ',10
                dc.b    '            *******  *******            ',10
                dc.b    '           ******************           ',10
                dc.b    '           ******************           ',10
                dc.b    '            ****************            ',10
                dc.b    '            ****************            ',10
                dc.b    '              ************              ',10
                dc.b    '              ************              ',10
                dc.b    '                ********                ',10
                dc.b    '                ********                ',10
                dc.b    '                  ****                  ',10
                dc.b    '                  ****                  ',10
                dc.b    '                   **                   ',10
                dc.b    0
                ;dc.b	'THIS ',2,'IS ',3,'A TEST!',10
                ;dc.b	1,'LINE 2',5,200,'11!',0
                even

************************************************************
        SECTION EndTextDataC,DATA_C

EndTextCopper:
	dc.w	$01fc,$0000
	dc.w	$008e,$2c81
	dc.w	$0090,$2cc1
	dc.w	$0092,$0038
	dc.w	$0094,$00d0
	dc.w	$0106,$0c00
	dc.w	$0102,$0000
	dc.w	$0104,$0000
	dc.w	$0108,$0028
	dc.w	$010a,$0028

EndTextPalette:
	dc.w	$0180,$0234
	dc.w	$0182,$0fff
	dc.w	$0184,$0777
	dc.w	$0186,$0e25

EndTextBplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
EndTextBplCon:
	dc.w	$0100,$2200

	dc.w	$2c01,$fffe
EndTextCop2Loc:
	dc.w	$0084,$0000,$0086,0000
	dc.w	$008a,$0001

	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe

        SECTION EndTextBSSC,BSS_C

EndTextBplCon1:         ds.w    256*4+2+4
EndTextBplCon12:        ds.w    256*4+2+4

