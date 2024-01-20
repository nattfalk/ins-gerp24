WAITBLIT:macro
	tst.w	(a6)
.wb\@:	btst	#6,2(a6)
	bne.s	.wb\@
	endm

************************************************************
Logo_Init:
        clr.w   FCnt

	lea.l	$dff000,a6

	move.l	DrawBuffer,a0
        move.l  #((256<<6)+(320>>4)),d0
        moveq   #4-1,d7
.clear: jsr	BltClr
        adda.l  #320*256>>3,a0
        dbf     d7,.clear
	jsr	WaitBlitter

        ; lea.l   Logo,a0
        move.l  DrawBuffer,a0
        lea     LogoBplPtrs+2,a1
        move.l  #(320*256)>>3,d0
        moveq	#4-1,d1
        jsr     SetBpls

    	move.l	#LogoCopper,$80(a6)
        rts

************************************************************
Logo_Run:
        cmp.w   #32,Logo_LocalFrameCounter
        bge.s   .fadeInDone
        lea.l   Logo_WhitePal,a0
        lea.l   LogoPal,a1
        lea.l   LogoPalette,a2
        moveq   #16,d0
        moveq   #16-1,d1
        bsr     Fade
        bra     .done

.fadeInDone:
        cmp.w   #400,Logo_LocalFrameCounter
        bge     .revealDone
        clr.w   FCnt

        lea.l   Logo_RevealPattern(pc),a5
        move.w  Logo_MaskIndex(pc),d7
        beq.s   .done
        subq.w  #1,d7
.loop:  cmp.w   #10,4(a5)
        beq.s   .next

        move.w  (a5),d0
        move.w  2(a5),d1
        move.w  4(a5),d2
        lsl.w   #5,d2
        addq.w  #1,4(a5)

        lea.l   Logo,a0
        lea.l   CircleMask,a1
        lea.l   (a1,d2.w),a1
        move.l  DrawBuffer,a2
        move.w  d7,-(sp)
        bsr     Logo_BltCopyBlock        
        move.w  (sp)+,d7

.next:
        adda.l  #6,a5
        dbf     d7,.loop
        bra.s   .done

.revealDone:
        lea.l   LogoPal,a0
        lea.l   Logo_WhitePal,a1
        lea.l   LogoPalette,a2
        moveq   #16,d0
        moveq   #16-1,d1
        bsr     Fade

.done:
        rts

************************************************************
Logo_Interrupt:
        add.w   #1,Logo_LocalFrameCounter

        cmp.w   #32,Logo_LocalFrameCounter
        bmi.s   .skip

        cmp.w   #20*16,Logo_MaskIndex
        bge     .skip
        add.w   #1,Logo_MaskIndex

.skip:
        rts

************************************************************

****************************************
* Copy masked block with blitter
*
* a0 = Source image
* a1 = Mask
* a2 = Destination
* d0 = X position. Even 16 pixels. Same pos in src and dest
* d1 = Y position. Even 16 pixels. Same pos in src and dest
Logo_BltCopyBlock:
	lea.l	$dff000,a6

        mulu    #40,d1
        lsr.w   #3,d0
        add.w   d0,d1

        adda.l  d1,a0
        adda.l  d1,a2

        WAITBLIT
	move.w	#38,bltamod(a6)
        move.w  #-1,bltafwm(a6)
        move.w  #-1,bltalwm(a6)
	move.w	#0,bltbmod(a6)
	move.w	#38,bltdmod(a6)
	move.w	#$0dc0,bltcon0(a6)
	move.w	#0,bltcon1(a6)

        moveq   #4-1,d7
.copy:  WAITBLIT
	move.l	a0,bltapt(a6)
	move.l	a1,bltbpt(a6)
	move.l	a2,bltdpt(a6)
	move.w	#16<<6+1,bltsize(a6)

        adda.l  #(320*256)>>3,a0
        adda.l  #(320*256)>>3,a2

        dbf     d7,.copy

        rts
************************************************************
        even

Logo_LocalFrameCounter:         dc.w    0
Logo_MaskIndex:                 dc.w    0
Logo_WhitePal:                  dcb.w   16,$0fff
        
        include "data/image_reveal_pattern.s"
