        SECTION EndTextCode,CODE_P

************************************************************
EndText_Init:
        move.l  DrawBuffer,a0
        move.l  #((256*2)<<6)+(320>>4),d0
        jsr     BltClr
        jsr     WaitBlitter
        
        move.l  ViewBuffer,a0
        move.l  #((256*2)<<6)+(320>>4),d0
        jsr     BltClr
        jsr     WaitBlitter

        move.l  DrawBuffer,a0
        lea.l   512*40(a0),a0
        move.l  a0,EndText_TextBuffer
        move.l  #((512+24)<<6)+(320>>4),d0
        jsr     BltClr
        jsr     WaitBlitter

        ; Set bpl 0 (background effect)
        move.l  DrawBuffer,a0
        moveq   #0,d0
        lea     EndTextBplPtrs+2,a1
        moveq   #1-1,d1
        jsr     SetBpls

        ; Set bpl 2 (empty)
        move.l  DrawBuffer,a0
        lea.l   256*40(a0),a0
        moveq   #0,d0
        lea     EndTextBplPtrs+16+2,a1
        moveq   #1-1,d1
        jsr     SetBpls

        ; Set bpl 1 (text bpl 1)
        move.l  EndText_TextBuffer,a0
        moveq   #0,d0
        lea     EndTextBplPtrs+8+2,a1
        moveq   #1-1,d1
        jsr     SetBpls

        ; Set bpl 3 (text bpl 2)
        move.l  EndText_TextBuffer,a0
        lea.l   40(a0),a0
        moveq   #0,d0
        lea     EndTextBplPtrs+24+2,a1
        moveq   #1-1,d1
        jsr     SetBpls

        bsr     EndText_CreateBplCon1List

        move.l	#EndTextCopper,$80(a6)
        rts

************************************************************
EndText_Run:
        ; Doublebuffer and clear first bpl
        movem.l DrawBuffer,a2-a3
        exg     a2,a3
        movem.l	a2-a3,DrawBuffer

        move.l	a3,a0
        moveq   #0,d0
        lea     EndTextBplPtrs+2,a1
        moveq	#1-1,d1
        jsr     SetBpls

        move.l	a2,a0
        lea.l   64*40(a0),a0
        move.l  #(128<<6)+(320>>4),d0
        jsr     BltClr

        ; Render background effect
        bsr     EndText_RenderBackgroundEffect

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

        cmp.w   #2440,EndText_LocalFrameCounter
        bge.s   .wave
        
        ; Print text
        move.w  EndText_LocalFrameCounter,d0
        and.w   #1,d0
        beq     .wave

        cmp.w   #12,EndText_PrintCounter
        bne.s   .scroll
        clr.w   EndText_PrintCounter

        lea.l   EndText_Text(pc),a0
        lea.l   Font,a1
        move.l  EndText_TextBuffer,a2
        adda.l  #80*256,a2
        jsr     TextWriter_Line


.scroll:
        ; Scroll upwards
        lea.l   $dff000,a6
        jsr	WaitBlitter

	move.l  #$09f00000,bltcon0(a6)
	move.l  #-1,bltafwm(a6)
	move.w  #0,bltamod(a6)
	move.w  #0,bltdmod(a6)
	move.l  EndText_TextBuffer,d0
	move.l  d0,bltdpt(a6)
	add.l   #80,d0
	move.l  d0,bltapt(a6)
	move.w  #(256+12-1)*2*64+20,bltsize(a6)

        addq.w  #1,EndText_PrintCounter

.wave:
        ;Horizontally sinewaved text planes 
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
        lsl.b   #4,d1
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

        cmp.w   #2440,EndText_LocalFrameCounter
        bge.s   .done

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

        addq.w  #6,EndText_Angles
        add.w   #12,EndText_Angles+2
        add.w   #10,EndText_Angles+4

        movem.l a0-a2/d0,-(sp)
        lea.l   Sintab,a0
        lea.l   EndText_SinMovement(pc),a1
        lea.l   EndText_Offsets(pc),a2

        ; X movement
        move.w  (a1),d0
        add.w   #8,d0
        and.w   #$7fe,d0
        move.w  d0,(a1)+
        move.w  (a0,d0.w),d0
        asr.w   #8,d0
        add.w   #320>>1,d0
        move.w  d0,(a2)+

        ; Y movement
        move.w  (a1),d0
        add.w   #20,d0
        and.w   #$7fe,d0
        move.w  d0,(a1)
        move.w  (a0,d0.w),d0
        asr.w   #8,d0
        asr.w   #2,d0
        add.w   #256>>1,d0
        move.w  d0,(a2)

        movem.l (sp)+,a0-a2/d0

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

EndText_RenderBackgroundEffect:
        lea.l   EndText_Angles(pc),a0
        movem.w (a0),d0-d2
        jsr     InitRotate

        lea.l   EndText_RotatedCoords+8*2*2*1-4,a0
        lea.l   8*2*2(a0),a1
        moveq   #8*1-1,d7
.copy:  move.l  (a0),(a1)
        subq.l  #4,a0
        subq.l  #4,a1
        dbf     d7,.copy

        lea.l   EndText_Coords(pc),a0
        lea.l   EndText_RotatedCoords(pc),a1
        move.w  EndText_Offsets,d4
        move.w  EndText_Offsets+2,d5
        moveq   #8-1,d6
.rotate:
        ; Rotate
        movem.w (a0)+,d0-d2
        jsr     RotatePoint

        add.w   #140,d2
        ; Project
        ext.l   d0
        asl.l   #7,d0
        divs    d2,d0
        add.w   d4,d0
        move.w  d0,(a1)+
        ext.l   d1
        asl.l   #7,d1
        divs    d2,d1
        add.w   d5,d1
        move.w  d1,(a1)+
        dbf     d6,.rotate

        jsr     DL_Init

        lea.l   $dff000,a6
        lea.l   EndText_RotatedCoords(pc),a3
        moveq   #2-1,d6
.loop:  
        lea.l   EndText_Indices(pc),a2
        moveq   #8-1,d7
.drawLine:
        move.w  (a2)+,d1
        move.w  (a3,d1.w),d0
        move.w  2(a3,d1.w),d1
        move.w  (a2),d3
        move.w  (a3,d3.w),d2
        move.w  2(a3,d3.w),d3

        move.l  DrawBuffer,a0
        moveq   #40,d4
        jsr     DrawLine

        dbf     d7,.drawLine

        lea.l   8*2*2(a3),a3
        dbf     d6,.loop
        rts

************************************************************
                                even
EndText_LocalFrameCounter:      dc.w    0
EndText_TextBuffer:             dc.l    0
EndText_PrintCounter:           dc.w    0
EndText_SinOffset:              dc.w    0
EndText_BplPtrBuff:             dc.l    EndTextBplCon1,EndTextBplCon12
EndText_BplPtrListBuff:         dc.l    EndText_BplCon1List,EndText_BplCon1List2
EndText_BplCon1List:            ds.l    512
EndText_BplCon1List2:           ds.l    512

EndText_Angles:         dc.w    0,0,0
EndText_SinMovement:    dc.w    0,0
EndText_Offsets:        dc.w    160,128
EndText_Coords:         dc.w    30,-60,0
                        dc.w    60,-30,0
                        dc.w    60,30,0
                        dc.w    30,60,0
                        dc.w    -30,60,0
                        dc.w    -60,30,0
                        dc.w    -60,-30,0
                        dc.w    -30,-60,0
EndText_RotatedCoords:  ds.w    8*2*2
EndText_Indices:        dc.w    0*4,1*4,2*4,3*4,4*4,5*4,6*4,7*4,0*4


;		         0123456789012345678901234567890123456789
EndText_Text:	dc.b    10
                dc.b    '  AND NOW YOU HAVE REACHED THE ',3,'END',1,' ...  ',10
                dc.b    10
;		         01234567890123456789012345678901234567
                dc.b    '            WE ARE ',3,'INSANE',1,10
                dc.b    10
                dc.b    10
;		         0123456789012345678901234567890123456789
                dc.b    '   ',2,'GRAPHICS / FONT',1,'   COREL ',3,',',1,' VEDDER     ',10
                dc.b    10
                dc.b    '   ',2,'MUSIC',1,'             MYGG ',3,',',1,' VEDDER   ',10
                dc.b    10
                dc.b    '   ',2,'CODE',1,'              PROSPECT           ',10
                dc.b    10
                dc.b    10
                dc.b    10
;		         01234567890123456789012345678901234567
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
                dc.b    1,10
                dc.b    10
                dc.b    10
                dc.b    10
;		         01234567890123456789012345678901234567
                dc.b    '  THE USUAL GREETINGS GO OUT TO THE',10
                dc.b    '   FOLLOWING GROUPS AND PEOPLE ...',10
                dc.b    10
                dc.b    10
                ; TODO
                dc.b    '       ****** GREETINGS  *******',10
                dc.b    10
                dc.b    '3LE ',3,'ABYSS ',1,'ACCESSION ',3,'ALCATRAZ ',1,'ANDROMEDA',10 
                dc.b    3,'APPENDIX ',1,'ARTWAY ',3,'BATMAN GROUP ',1,'BITBENDAZ ',10
                dc.b    '  ',3,'DHS ',1,'BYTERAPERS ',3,'BOMB ',1,'BOOZE DESIGN ',10
                dc.b    '  ',3,'BONZAI ',1,'C-LOUS ',3,'DARKLITE ',1,'DEADLINERS ',10
                dc.b    ' ',3,'DEKADENCE ',1,'DEPTH ',3,'DESIRE ',1,'DREAMDEALERS ',10
                dc.b    '',3,'EPH ',1,'EQUINOX ',3,'FAIRLIGHT ',1,'FFP ',3,'FOCUS DESIGN ',10
                dc.b    '  ',1,'F4CG ',3,'GP ',1,'GHOSTOWN ',3,'HAUJOBB ',1,'HEMOROIDS ',10
                dc.b    ' ',3,'HOAXERS ',1,'HMF ',3,'IMPACT ',1,'ISTARI ',3,'KESO ',1,'LATEX ',10
                dc.b    '    ',3,'LEMON. ',1,'LOONIES ',3,'MELON ',1,'NAH-KOLOR  ',10
                dc.b    '',3,'NATURE ',1,'NEW BEAT ',3,'NUKLEUS ',1,'MOODS PLATEAU',10
                dc.b    '   ',3,'OFFENCE ',1,'ONSLAUGHT ',3,'OXYRON ',1,'PACIF!C  ',10
                dc.b    '    ',3,'PARADISE ',1,'PHENOMENA ',3,'PLANET JAZZ  ',10
                dc.b    ' ',1,'POWERLINE ',3,'RAZOR 1911 ',1,'REALITY ',3,'RELAPSE ',10
                dc.b    '  ',1,'RESISTANCE ',3,'RIFT ',1,'SCARAB ',3,'SCOOPEX ',1,'SMFX ',10
                dc.b    ' ',3,'SPACEBALLS ',1,'SPECTRALS ',3,'STRUTS ',1,'SUBSPACE',10
                dc.b    ' ',3,'TBL ',1,'TEK ',3,'THE CHIPERIA PROJECT ',1,'TALENT ',10
                dc.b    '  ',3,'THE GANG ',1,'TITAN ',3,'TRAKTOR ',1,'TRIAD ',3,'TRSI ',10
                dc.b    '   ',1,'TULOU ',3,'UNIQUE ',1,'VOID ',3,'WANTED TEAM  ',10
                dc.b    '       ',1,'UP ROUGH ',3,'Y-CREW ',1,'ZYMOSIS',10
                dc.b    10
                dc.b    '     AND EVERYONE AT ',2,'GERP 2024',1,10
                dc.b    10
                dc.b    10
                dc.b    'AND LAST BUT NOT LEAST SOME INOFFICIAL',10
                dc.b    'HEADS BEHIND THIS PRODUCTION :)',10
                dc.b    10
                dc.b    '- ',3,'PRB28 (AT GITHUB)',1,' FOR THE EXCELLENT',10
                dc.b    '  ',2,'VS CODE ASSEMBLY EXTENSION',1,' USED FOR',10
                dc.b    '  THIS PROD',10
                dc.b    '- ',3,'PHOTON/SCX',1,' FOR THE SWEET',10
                dc.b    '  ',2,'STARTUP CODE',1,10
                dc.b    '- ',3,'BLUEBERRY',1,' FOR THE GREAT ',2,'SHRINKLER',1,10
                dc.b    '- ',3,'LEONARD/OXYGEN',1,' FOR THE AMAZING',10
                dc.b    '  CONVERTER AND ',2,'LIGHTSPEEDPLAYER',1,10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
;		         01234567890123456789012345678901234567
                dc.b    '      GO ',2,'CRAZY',1,' ... GO ',2,'INSANE',1,10
                dc.b    10
                dc.b    '      THANK YOU FOR WATCHING',10
                dc.b    '        SEE YOU SOON AGAIN',10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    2,'  ********************************',10   
                dc.b    '  ********************************',10
                dc.b    '  **   ***       ******        ***',10
                dc.b    '  ********   ***   ***   *********',10
                dc.b    '  **   ***   ***   ***         ***',10
                dc.b    '  **   ***   ***   **********   **',10
                dc.b    '  **   ***   ***   **********   **',10
                dc.b    '  **   ***   ***   ***   ****   **',10
                dc.b    '  **   ***   ***   ***   ****   **',10
                dc.b    '  **   ***   ***   ***         ***',10
                dc.b    '  ********************************',10
                dc.b    '  ********************************',1,10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    10
                dc.b    0

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
	dc.w	$0108,$0000
	dc.w	$010a,$0028

EndTextPalette:
	dc.w	$0180,$0234
	dc.w	$0182,$0456
	dc.w	$0184,$0fff
	dc.w	$0186,$0456
	dc.w	$0188,$0234
	dc.w	$018a,$0456
	dc.w	$018c,$0fff
	dc.w	$018e,$0fff
        dc.w	$0190,$0777
	dc.w	$0192,$0777
	dc.w	$0194,$0e25
	dc.w	$0196,$0e25
	dc.w	$0198,$0777
	dc.w	$019a,$0777
	dc.w	$019c,$0e25
	dc.w	$019e,$0e25

EndTextBplPtrs:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000
EndTextBplCon:
	dc.w	$0100,$4200

	dc.w	$2c01,$fffe
EndTextCop2Loc:
	dc.w	$0084,$0000,$0086,0000
	dc.w	$008a,$0001

	dc.w	$ffff,$fffe
	dc.w	$ffff,$fffe

        SECTION EndTextBSS,BSS_C

EndTextBplCon1:         ds.w    256*4+2+4
EndTextBplCon12:        ds.w    256*4+2+4

