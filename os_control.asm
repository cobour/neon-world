
                  section     OsControlCode,code
              
                  include     "constants.i"

                  xdef        osc_save_orig_system_state
osc_save_orig_system_state:
                  movem.l     d0-d7/a0-a6,-(sp)

                  move.l      ExecBase,a6
                  lea         osc_gfx_name(pc),a1
                  moveq.l     #0,d0
                  jsr         OpenLibrary(a6)
                  move.l      d0,osc_gfx_base

                  lea.l       CustomBase,a6
                  WAIT_VB2

                  move.l      osc_gfx_base(pc),a6
                  move.l      CurrentView(a6),osc_cur_view
                  move.l      CurrentCopper(a6),osc_cur_copper
                  sub.l       a1,a1
                  jsr         LoadView(a6)

                  move.l      Level3Handler,osc_cur_lvl3hdl

                  movem.l     (sp)+,d0-d7/a0-a6
                  rts

                  xdef        osc_black_screen
osc_black_screen:
                  movem.l     d0-d7/a0-a6,-(sp)

                  lea.l       CustomBase,a6

                  moveq.l     #31,d7
                  move.l      a6,a0
                  add.w       #COLOR00,a0
.set_colors_loop:
                  clr.w       (a0)+
                  dbf         d7,.set_colors_loop

                  move.l      #osc_cop_list_all_black,COP1LC(a6)
                  WAIT_VB2

                  movem.l     (sp)+,d0-d7/a0-a6
                  rts

                  xdef        osc_restore_screen
osc_restore_screen:
                  movem.l     d0-d7/a0-a6,-(sp)
                  lea.l       CustomBase,a6
                  move.l      osc_cur_copper(pc),COP1LC(a6)

                  move.l      osc_gfx_base(pc),a6
                  move.l      osc_cur_view(pc),a1
                  jsr         LoadView(a6)

                  lea.l       CustomBase,a6
                  WAIT_VB2

                  move.l      ExecBase,a6
                  move.l      osc_gfx_base(pc),a1
                  jsr         CloseLibrary(a6)

                  movem.l     (sp)+,d0-d7/a0-a6
                  rts
     
                  xdef        osc_take_system
osc_take_system:
                  movem.l     d0-d7/a0-a6,-(sp)
                  lea.l       CustomBase,a6

                  WAIT_VB2

; stop drive motors
; found here: http://eab.abime.net/showthread.php?t=84507
                  lea.l       $bfd100,a0
                  or.b        #$f8,(a0)
                  nop
                  and.b       #$87,(a0)
                  nop
                  or.b        #$78,(a0)
                  nop

                  WAIT_VB2

; save dma and irq settings
                  move.w      DMACONR(a6),d0
                  or.w        #$8000,d0
                  move.w      d0,osc_cur_dmacon
                  move.w      INTENAR(a6),d0
                  or.w        #$8000,d0
                  move.w      d0,osc_cur_intena
                  move.w      INTREQR(a6),d0
                  or.w        #$8000,d0
                  move.w      d0,osc_cur_intreq
; set our dma and irq settings
                  move.w      #%1000010111100000,DMACON(a6)
                  move.w      #%0000000000011111,DMACON(a6)
                  move.w      #%0111111111111111,INTENA(a6)

                  WAIT_VB2

                  movem.l     (sp)+,d0-d7/a0-a6
                  rts

; a0 = irq handler code
                  xdef        osc_set_irq_handler
osc_set_irq_handler:
                  movem.l     d0-d7/a0-a6,-(sp)
                  lea.l       CustomBase,a6

                  move.w      #%0111111111111111,INTENA(a6)                                      ; disable ALL IRQ's
                  move.l      a0,Level3Handler
                  move.w      #%1110000000010000,INTENA(a6)                                      ; Copper-IRQ (for our code) and External-IRQ (for ptplayer) only

                  movem.l     (sp)+,d0-d7/a0-a6
                  rts

                  xdef        osc_free_system
osc_free_system:
                  movem.l     d0-d7/a0-a6,-(sp)
                  lea.l       CustomBase,a6

                  move.w      #$7fff,DMACON(a6)
                  move.w      osc_cur_dmacon(pc),DMACON(a6)
                  move.w      #$7fff,INTENA(a6)
                  move.l      osc_cur_lvl3hdl(pc),Level3Handler
                  move.w      osc_cur_intena(pc),INTENA(a6)
                  move.w      #$7fff,INTREQ(a6)
                  move.w      osc_cur_intreq(pc),INTREQ(a6)

                  movem.l     (sp)+,d0-d7/a0-a6
                  rts

osc_gfx_name:     dc.b        "graphics.library",0
                  even

osc_gfx_base:     dc.l        0

osc_cur_view:     dc.l        0
osc_cur_copper:   dc.l        0

osc_cur_dmacon:   dc.w        0
osc_cur_intena:   dc.w        0
osc_cur_intreq:   dc.w        0
osc_cur_lvl3hdl:  dc.l        0

                  section     OsControlChipData,data_c

osc_cop_list_all_black:
                  dc.w        SPR0PTH,$0000
                  dc.w        SPR0PTL,$0000
                  dc.w        SPR1PTH,$0000
                  dc.w        SPR1PTL,$0000
                  dc.w        SPR2PTH,$0000
                  dc.w        SPR2PTL,$0000
                  dc.w        SPR3PTH,$0000
                  dc.w        SPR3PTL,$0000
                  dc.w        SPR4PTH,$0000
                  dc.w        SPR4PTL,$0000
                  dc.w        SPR5PTH,$0000
                  dc.w        SPR5PTL,$0000
                  dc.w        SPR6PTH,$0000
                  dc.w        SPR6PTL,$0000
                  dc.w        SPR7PTH,$0000
                  dc.w        SPR7PTL,$0000
                  dc.w        BPL1PTH,$0000
                  dc.w        BPL1PTL,$0000
                  dc.w        BPL2PTH,$0000
                  dc.w        BPL2PTL,$0000
                  dc.w        BPL3PTH,$0000
                  dc.w        BPL3PTL,$0000
                  dc.w        BPL4PTH,$0000
                  dc.w        BPL4PTL,$0000
                  dc.w        BPL5PTH,$0000
                  dc.w        BPL5PTL,$0000
                  dc.w        BPL6PTH,$0000
                  dc.w        BPL6PTL,$0000
                  dc.w        BPLCON0,(1<<12)|BplColorOn
                  dc.w        BPLCON1,$0000
                  dc.w        BPLCON2,$0000
                  dc.w        BPL1MOD,$0000
                  dc.w        BPL2MOD,$0000
                  dc.w        DDFSTRT,(ScreenStartX/2-DdfResolution)
                  dc.w        DDFSTOP,(ScreenStartX/2-DdfResolution)+(8*((ScreenWidth/16)-1))
                  dc.w        DIWSTRT,(ScreenStartY<<8)|ScreenStartX
                  dc.w        DIWSTOP,((ScreenStopY-256)<<8)|(ScreenStopX-256)
                  dc.w        COLOR00,$0000
                  dc.w        COLOR01,$0000
                  dc.w        COLOR02,$0000
                  dc.w        COLOR03,$0000
                  dc.w        COLOR04,$0000
                  dc.w        COLOR05,$0000
                  dc.w        COLOR06,$0000
                  dc.w        COLOR07,$0000
                  dc.w        COLOR08,$0000
                  dc.w        COLOR09,$0000
                  dc.w        COLOR10,$0000
                  dc.w        COLOR11,$0000
                  dc.w        COLOR12,$0000
                  dc.w        COLOR13,$0000
                  dc.w        COLOR14,$0000
                  dc.w        COLOR15,$0000
                  dc.w        COLOR16,$0000
                  dc.w        COLOR17,$0000
                  dc.w        COLOR18,$0000
                  dc.w        COLOR19,$0000
                  dc.w        COLOR20,$0000
                  dc.w        COLOR21,$0000
                  dc.w        COLOR22,$0000
                  dc.w        COLOR23,$0000
                  dc.w        COLOR24,$0000
                  dc.w        COLOR25,$0000
                  dc.w        COLOR26,$0000
                  dc.w        COLOR27,$0000
                  dc.w        COLOR28,$0000
                  dc.w        COLOR29,$0000
                  dc.w        COLOR30,$0000
                  dc.w        COLOR31,$0000
                  dc.w        $ffff,$fffe
