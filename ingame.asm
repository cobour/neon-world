                section     IngameCode,code
  
                include     "constants.i"

;
; called before system control is taken over
; additional files can be loaded here
;
                xdef        ig_init
ig_init:
                movem.l     d0-d7/a0-a6,-(sp)

; read othermem dat
                move.l      #f003_filename,d5
                move.l      #m_cm_area+ig_cm_screenbuffer0,d6
                move.l      #f003_filesize,d7
                jsr         dos_readfile
; inflate othermem dat
                lea.l       m_cm_area+ig_cm_screenbuffer0,a5
                lea.l       m_om_area+ig_om_f003,a4
                jsr         inflate
                
; read chipmem dat
                move.l      #f002_filename,d5
                move.l      #m_cm_area+ig_cm_screenbuffer0,d6
                move.l      #f002_filesize,d7
                jsr         dos_readfile
; inflate chipmem dat
                lea.l       m_cm_area+ig_cm_screenbuffer0,a5
                lea.l       m_cm_area+ig_cm_f002,a4
                jsr         inflate

                movem.l     (sp)+,d0-d7/a0-a6
                rts

;
; called when system is under control
;
                xdef        ig_start
ig_start:
                SET_PTRS

                moveq.l     #1,d0
                jsr         fade_in_init
 
                clr.l       ig_om_frame_counter(a4)
                jsr         pf_init

                bsr         .init_sprites
                lea.l       ig_cop_sprpt,a0
                jsr         player_init
                lea.l       ig_cop_spr2pt,a0
                jsr         panel_init
                jsr         sf_init

                bsr.s       .init_copper_list_and_irq_handler

                bsr.s       .init_music
                move.b      #1,_mt_Enable
.mainloop:
                btst        #IgExit,ig_om_bools(a4)
                beq.s       .mainloop
.fade_out_wait_loop:
                btst        #GFadeOut,g_om_bools(a4)
                bne.s       .fade_out_wait_loop
                
                bsr.s       .cleanup_music

                ; for now lways return to mainmenu
                clr.b       g_om_level(a4)

                rts

.init_copper_list_and_irq_handler:
; set irq handler
                WAIT_VB
                lea.l       ig_lvl3_handler(pc),a0
                jsr         osc_set_irq_handler
; activate copper list
                move.l      #ig_cop_start,COP1LC(a6)
                rts

.init_music:
                lea.l       m_om_area+ig_om_f003+f003_dat_universe_mod_data,a0
                lea.l       m_cm_area+ig_cm_f002+f002_dat_universe_mod_samples,a1
                moveq.l     #0,d0
                jmp         _mt_init

.cleanup_music:
                jmp         _mt_end

.init_sprites:
                lea.l       ig_cop_sprpt,a0
                move.l      #ig_empty_sprite,d1
                move.l      d1,d0
                swap        d0
                moveq.l     #7,d7
.is_loop:
                move.w      d0,2(a0)
                move.w      d1,6(a0)
                addq.l      #8,a0
                dbf         d7,.is_loop

                rts

ig_lvl3_handler:
                movem.l     d0-d7/a0-a6,-(sp)

                SET_PTRS

                ifne        SHOW_BLUE_TIMING
                move.w      #$000f,COLOR00(a6)
                endif
                
                ; clear Copper-IRQ-Bit
                move.w      #%0000000000010000,INTREQ(a6)

                ; update player sprite
                jsr         player_update
 
                ; before the rest -> update starfield (because copperlist is updated at a point that has not been already executed)
                jsr         sf_scroll

                ; do fade-in or -out
                lea.l       ig_cop_colors,a0
                jsr         do_fade

                ; scroll playfield
                jsr         pf_scroll

                ; increment frame counter
                add.l       #1,ig_om_frame_counter(a4)

                ; call ptplayer for music and sfx
                jsr         _mt_music
 
                ifne        SHOW_BLUE_TIMING
                clr.w       COLOR00(a6)
                endif

                movem.l     (sp)+,d0-d7/a0-a6
                rte

                section     IngameChipData,data_c

ig_empty_sprite:
                dc.l        0

ig_cop_start:
                xdef        ig_cop_bplpt
ig_cop_bplpt:   dc.w        BPL1PTH,$0000
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

                dc.w        BPLCON0,(ScreenBitPlanes<<12)|BplColorOn 
                dc.w        BPLCON2,%0000000000011000                                          ; Sprite 0-5 in front of playfield, Sprite 6-7 behind playfield -> lives/score-panel (2-5) in front of playfield, player (0+1) can not move up here, 6+7 unusable due to DIWSTRT and DDFSTRT
                
; the following 4 values are modified by scroll routine
                xdef        ig_cop_scroll
ig_cop_scroll:  dc.w        BPLCON1,$0000
                dc.w        BPL1MOD,$0000
                dc.w        BPL2MOD,$0000
                dc.w        DDFSTRT,$0000
; the following values are constant
                dc.w        DDFSTOP,(ScreenStartX/2-DdfResolution)+(8*((ScreenWidth/16)-1))
                dc.w        DIWSTRT,(ScreenStartY<<8)|ScreenStartX
                dc.w        DIWSTOP,((ScreenStopY-256)<<8)|(ScreenStopX-256)

; Sprites
ig_cop_sprpt:   dc.w        SPR0PTH,$0000
                dc.w        SPR0PTL,$0000
                dc.w        SPR1PTH,$0000
                dc.w        SPR1PTL,$0000
ig_cop_spr2pt:  dc.w        SPR2PTH,$0000
                dc.w        SPR2PTL,$0000
                dc.w        SPR3PTH,$0000
                dc.w        SPR3PTL,$0000
ig_cop_spr4pt:  dc.w        SPR4PTH,$0000
                dc.w        SPR4PTL,$0000
                dc.w        SPR5PTH,$0000
                dc.w        SPR5PTL,$0000
                dc.w        SPR6PTH,$0000
                dc.w        SPR6PTL,$0000
                dc.w        SPR7PTH,$0000
                dc.w        SPR7PTL,$0000

; trigger Copper-IRQ after all bitplane and sprite registers are set => irq routine can safely modify copperlist for next frame
                dc.w        INTREQ,%1000000000010000

; colors
ig_cop_colors:  dc.w        COLOR00,$0000
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
; colors for panel
                dc.w        (ScreenStartY<<8)+1,$ff00
                dc.w        COLOR23,$00ff
                dc.w        COLOR27,$00ff
                dc.w        ((ScreenStartY+1)<<8)+1,$ff00
                dc.w        COLOR23,$00ee
                dc.w        COLOR27,$00ee
                dc.w        ((ScreenStartY+2)<<8)+1,$ff00
                dc.w        COLOR23,$00dd
                dc.w        COLOR27,$00dd
                dc.w        ((ScreenStartY+3)<<8)+1,$ff00
                dc.w        COLOR23,$00cc
                dc.w        COLOR27,$00cc
                dc.w        ((ScreenStartY+4)<<8)+1,$ff00
                dc.w        COLOR23,$00bb
                dc.w        COLOR27,$00bb
                dc.w        ((ScreenStartY+5)<<8)+1,$ff00
                dc.w        COLOR23,$00aa
                dc.w        COLOR27,$00aa
                dc.w        ((ScreenStartY+6)<<8)+1,$ff00
                dc.w        COLOR23,$0099
                dc.w        COLOR27,$0099
                dc.w        ((ScreenStartY+7)<<8)+1,$ff00
                dc.w        COLOR23,$0088
                dc.w        COLOR27,$0088

; reset COLOR23 and COLOR27 for the rest of the screen
                dc.w        ((ScreenStartY+8)<<8)+1,$ff00
                xdef        fade_color23
fade_color23:
                dc.w        COLOR23,$0d00
                dc.w        COLOR27,$0555

                dc.w        (LineOfFirstStar<<8)+1,$ff00
                dc.w        BPLCON2,%0000000000010000                                          ; Sprite 0-3 in front of playfield, Sprite 4-7 behind playfield -> stars (4+5) behind playfield, player (0+1) and collectible items (2+3) in front of playfield, 6+7 unusable due to DIWSTRT and DDFSTRT

; end of copper list
                dc.w        $ffff,$fffe
