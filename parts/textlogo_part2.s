TextLogoPart2_Init:
        rts

TextLogoPart2_Run:
        lea.l   Palette,a0
        move.w  #$ff0,6(a0)
        rts

TextLogoPart2_Interrupt:
        rts
