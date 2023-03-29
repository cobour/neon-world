  section       MainmenuCode,code

  include       "constants.i"

;
; called before system control is taken over
; additional files can be loaded here
;
  xdef          mm_init
mm_init:
  movem.l       d0-d7/a0-a6,-(sp)

; read othermem dat
  move.l        #f001_filename,d5
  move.l        #m_cm_area+mm_cm_screenbuffer,d6
  move.l        #f001_filesize,d7
  jsr           dos_readfile
; inflate othermem dat
  lea.l         m_cm_area+mm_cm_screenbuffer,a5
  lea.l         m_om_area+mm_om_f001,a4
  jsr           inflate
                
; read chipmem dat
  move.l        #f000_filename,d5
  move.l        #m_cm_area+mm_cm_screenbuffer,d6
  move.l        #f000_filesize,d7
  jsr           dos_readfile
; inflate chipmem dat
  lea.l         m_cm_area+mm_cm_screenbuffer,a5
  lea.l         m_cm_area+mm_cm_f000,a4
  jsr           inflate

  movem.l       (sp)+,d0-d7/a0-a6
  rts

;
; called when system is under control
;
  xdef          mm_start
mm_start:
  SET_PTRS

  move.b        #MmOptionStart,mm_om_option(a4)

  moveq.l       #1,d0
  jsr           fade_in_init

  lea.l         mm_cm_f000+f000_dat_tiles_iff(a5),a0
  jsr           text_init

  bsr           init_lightning_anim
  bsr           init_screenbuffer
  bsr           init_copper_list_and_irq_handler
  bsr           init_music
  move.b        #1,_mt_Enable

  move.w        #MmCreditSwitchDelay,mm_om_credits_delay(a4)
  clr.b         mm_om_displayed_credits(a4)
  bsr.s         mm_draw_credits

.fade_in_wait_loop:
  btst          #GFadeIn,g_om_bools(a4)
  bne.s         .fade_in_wait_loop

.main_loop:
  btst          #FireButton,CIAAPRA
  bne.s         .main_loop

  jsr           sfx_enter
  moveq.l       #1,d0
  jsr           fade_out_init

.fade_out_wait_loop:
  btst          #GFadeOut,g_om_bools(a4)
  bne.s         .fade_out_wait_loop
 
  jsr           _mt_end
 
  cmp.b         #MmOptionStart,mm_om_option(a4)
  bne.s         .exit_program
  move.b        #1,g_om_level(a4)
  rts
.exit_program:
  bset          #GExit,g_om_bools(a4)
  rts

mm_draw_credits:
  tst.b         mm_om_displayed_credits(a4)
  bne.s         .1
  lea.l         credits_0(pc),a0
  bra.s         .draw
.1:
  cmp.b         #1,mm_om_displayed_credits(a4)
  bne.s         .2
  lea.l         credits_1(pc),a0
  bra.s         .draw
.2:
  lea.l         credits_2(pc),a0
.draw:
  move.l        a5,a1
  add.l         #mm_cm_screenbuffer+(ScreenWidthBytes*ScreenBitPlanes*TilePixelHeight*15),a1
  move.l        #ScreenWidthBytes,d0
  jmp           text_print

init_copper_list_and_irq_handler:
; set bitplane pointers in copperlist
  move.l        #m_cm_area+mm_cm_screenbuffer,d0
  lea.l         mm_cop_list_bitplane_pointer,a0
  moveq.l       #ScreenBitPlanes-1,d7
.bpl_loop:
  move.w        d0,6(a0)
  swap          d0
  move.w        d0,2(a0)
  swap          d0
  add.l         #ScreenWidthBytes,d0
  addq.l        #8,a0
  dbf           d7,.bpl_loop

  WAIT_VB

  lea.l         mm_lvl3_handler(pc),a0
  jsr           osc_set_irq_handler
  move.l        #mm_cop_list,COP1LC(a6)
  rts

init_lightning_anim:
  lea.l         mm_om_f001+f001_dat_mm_lightning_anim_tmx(a4),a0
  lea.l         mm_om_lightning_anim_offsets(a4),a1
  move.l        #f001_dat_mm_lightning_anim_tmx_tiles_width*2,d0
  moveq.l       #f001_dat_mm_lightning_anim_tmx_tiles_height-1,d7
.ila_loop:
  move.l        a0,(a1)+
  add.l         d0,a0
  dbf           d7,.ila_loop
  clr.b         mm_om_lightning_anim_step(a4)
  move.b        #MmLightningAnimDelay,mm_om_lightning_anim_delay(a4)
  rts

init_music:
  lea.l         m_om_area+mm_om_f001+f001_dat_vision_mod_data,a0
  lea.l         m_cm_area+mm_cm_f000+f000_dat_vision_mod_samples,a1
  PTP_INIT

init_screenbuffer:
  WAIT_BLT
  BLT_AD_CPY    ScreenWidthBytes

  lea.l         mm_cm_f000+f000_dat_tiles_iff(a5),a0
  lea.l         mm_om_f001+f001_dat_mainmenu_tmx(a4),a1
  lea.l         m_cm_area+mm_cm_screenbuffer,a2
  move.l        a2,d5

  move.w        #(ScreenHeight/TilePixelHeight)-1,d7                                                         ; rows-1
.isb_loop:
  move.w        #(ScreenWidth/TilePixelWidth)-1,d6                                                           ; columns-1
.isb_row_loop:
; calc source pointer
  move.l        a0,a3
  moveq.l       #0,d0
  move.w        (a1)+,d0
  add.l         d0,a3
; wait for blitter to be ready before first write to blitter register in loop
  WAIT_BLT
; set source pointer
  move.l        a3,BLTAPTH(a6)
; set and increment target pointer
  move.l        a2,BLTDPTH(a6)
  move.w        #TileAdCopyBltSize,BLTSIZE(a6)
  addq.l        #2,a2
  dbf           d6,.isb_row_loop
; next row
  add.l         #ScreenWidthBytes*ScreenBitPlanes*TilePixelHeight,d5
  move.l        d5,a2
  dbf           d7,.isb_loop

  rts

mm_handle_credits:
  sub.w         #1,mm_om_credits_delay(a4)
  tst.w         mm_om_credits_delay(a4)
  beq.s         .switch
  rts
.switch:
  move.w        #MmCreditSwitchDelay,mm_om_credits_delay(a4)
  add.b         #1,mm_om_displayed_credits(a4)
  cmp.b         #3,mm_om_displayed_credits(a4)
  bne.s         .update
  clr.b         mm_om_displayed_credits(a4)
.update:
  bra           mm_draw_credits

mm_lvl3_handler:
  movem.l       d0-d7/a0-a6,-(sp)

  SET_PTRS

    ; clear Copper-IRQ-Bit
  move.w        #%0000000000010000,INTREQ(a6)

  bsr           mm_update_lightning_anim
  bsr           mm_handle_credits

    ; do fade in and out
  lea.l         mm_cop_list_colors,a0
  jsr           do_fade

    ; check if the player selects other option
  bsr.s         mm_option_selection

    ; call ptplayer for music and sfx
  jsr           _mt_music
 
  movem.l       (sp)+,d0-d7/a0-a6
  rte

mm_option_selection:
  jsr           js_read

  btst          #JsDown,d0
  beq.s         .check_up
  ; down
  cmp.b         #MmOptionExit,mm_om_option(a4)
  beq           .end_check
  move.b        #MmOptionExit,mm_om_option(a4)
  jsr           sfx_select
  bra.s         .repaint
.check_up:  
  btst          #JsUp,d0
  beq           .end_check
  ; up
  cmp.b         #MmOptionStart,mm_om_option(a4)
  beq           .end_check
  move.b        #MmOptionStart,mm_om_option(a4)
  jsr           sfx_select

.repaint:
  move.l        #m_cm_area+mm_cm_screenbuffer+(ScreenWidthBytes*ScreenBitPlanes*TilePixelHeight*10)+16,d1    ; target buffer - 11th row and 9th column
  move.l        #m_cm_area+mm_cm_f000+f000_dat_tiles_iff,d2                                                  ; copy source base
; start option
  lea.l         mm_om_f001+f001_dat_start_on_off_tmx(a4),a0                                                  ; pointer to offsets
  cmp.b         #MmOptionStart,mm_om_option(a4)
  bne.s         .rp_not_start
  bra.s         .rp_paint_start
.rp_not_start:
  add.l         #f001_dat_start_on_off_tmx_tiles_width,a0                                                    ; /2 because of only half of the offsets must be drawn and *2 because of word width of the tile
.rp_paint_start:
  move.l        d1,d4

  moveq.l       #(f001_dat_start_on_off_tmx_tiles_width/2)-1,d7
  WAIT_BLT
  BLT_AD_CPY    ScreenWidthBytes
.rp_ps_loop:
  moveq.l       #0,d3
  move.w        (a0)+,d3
  add.l         d2,d3
  WAIT_BLT
  move.l        d3,BLTAPTH(a6)
  move.l        d4,BLTDPTH(a6)
  move.w        #TileAdCopyBltSize,BLTSIZE(a6)
  addq.l        #2,d4
  dbf           d7,.rp_ps_loop

; exit option
  lea.l         mm_om_f001+f001_dat_exit_on_off_tmx(a4),a0                                                   ; pointer to offsets
  cmp.b         #MmOptionExit,mm_om_option(a4)
  bne.s         .rp_not_exit
  bra.s         .rp_paint_exit
.rp_not_exit:
  add.l         #f001_dat_exit_on_off_tmx_tiles_width,a0                                                     ; /2 because of only half of the offsets must be drawn and *2 because of word width of the tile
.rp_paint_exit:
  add.l         #(ScreenWidthBytes*ScreenBitPlanes*TilePixelHeight*2),d1
  moveq.l       #(f001_dat_exit_on_off_tmx_tiles_width/2)-1,d7
  WAIT_BLT
  BLT_AD_CPY    ScreenWidthBytes
.rp_pe_loop:
  moveq.l       #0,d3
  move.w        (a0)+,d3
  add.l         d2,d3
  WAIT_BLT
  move.l        d3,BLTAPTH(a6)
  move.l        d1,BLTDPTH(a6)
  move.w        #TileAdCopyBltSize,BLTSIZE(a6)
  addq.l        #2,d1
  dbf           d7,.rp_pe_loop

.end_check:
  rts

mm_update_lightning_anim:
  tst.b         mm_om_lightning_anim_delay(a4)
  beq.s         .go_on
  sub.b         #1,mm_om_lightning_anim_delay(a4)
  rts
.go_on:
  move.b        #MmLightningAnimDelay,mm_om_lightning_anim_delay(a4)
  moveq.l       #0,d1
  move.b        mm_om_lightning_anim_step(a4),d1
  cmp.b         #f001_dat_mm_lightning_anim_tmx_tiles_height,d1
  bne.s         .draw_anim_step
  moveq.l       #0,d1
.draw_anim_step:
; pointer to tile-offsets for anim step
  move.l        d1,d2
  lsl.l         #2,d2
  lea.l         mm_om_lightning_anim_offsets(a4),a0
  add.l         d2,a0
  move.l        (a0),a0

; pointer to tiles
  lea.l         mm_cm_f000+f000_dat_tiles_iff(a5),a1

; target pointer in screenbuffer
  move.l        #m_cm_area+mm_cm_screenbuffer,a2
  add.l         #ScreenWidthBytes*ScreenBitPlanes*TilePixelHeight*14,a2
  moveq.l       #0,d7
  move.b        #f001_dat_mm_lightning_anim_tmx_tiles_width-1,d7
  WAIT_BLT
  BLT_AD_CPY    ScreenWidthBytes
.draw_anim_step_loop:
  move.l        a1,d3
  moveq.l       #0,d4
  move.w        (a0)+,d4
  add.l         d4,d3
  WAIT_BLT
  move.l        d3,BLTAPTH(a6)
  move.l        a2,BLTDPTH(a6)
  move.w        #TileAdCopyBltSize,BLTSIZE(a6)
  addq.l        #2,a2
  dbf           d7,.draw_anim_step_loop
 
  addq.l        #1,d1
  move.b        d1,mm_om_lightning_anim_step(a4)
  rts

credits_0:
  dc.b          "  MUSIC AND SFX BY KRZYSZTOF ODACHOWSKI ",0
  even
credits_1:
  dc.b          "       GRAPHICS BY KEVIN SAUNDERS       ",0
  even
credits_2:
  dc.b          "          CODE BY FRANK NEUMANN         ",0
  even

  section       MainmenuChipData,data_c

mm_cop_list:
  dc.w          SPR0PTH,$0000
  dc.w          SPR0PTL,$0000
  dc.w          SPR1PTH,$0000
  dc.w          SPR1PTL,$0000
  dc.w          SPR2PTH,$0000
  dc.w          SPR2PTL,$0000
  dc.w          SPR3PTH,$0000
  dc.w          SPR3PTL,$0000
  dc.w          SPR4PTH,$0000
  dc.w          SPR4PTL,$0000
  dc.w          SPR5PTH,$0000
  dc.w          SPR5PTL,$0000
  dc.w          SPR6PTH,$0000
  dc.w          SPR6PTL,$0000
  dc.w          SPR7PTH,$0000
  dc.w          SPR7PTL,$0000
mm_cop_list_bitplane_pointer:
  dc.w          BPL1PTH,$0000
  dc.w          BPL1PTL,$0000
  dc.w          BPL2PTH,$0000
  dc.w          BPL2PTL,$0000
  dc.w          BPL3PTH,$0000
  dc.w          BPL3PTL,$0000
  dc.w          BPL4PTH,$0000
  dc.w          BPL4PTL,$0000
  dc.w          BPL5PTH,$0000
  dc.w          BPL5PTL,$0000
  dc.w          BPL6PTH,$0000
  dc.w          BPL6PTL,$0000
  dc.w          BPLCON0,(ScreenBitPlanes<<12)|BplColorOn
  dc.w          BPLCON1,$0000
  dc.w          BPLCON2,$0000
  dc.w          BPL1MOD,ScreenWidthBytes*(ScreenBitPlanes-1)
  dc.w          BPL2MOD,ScreenWidthBytes*(ScreenBitPlanes-1)
  dc.w          DDFSTRT,(ScreenStartX/2-DdfResolution)
  dc.w          DDFSTOP,(ScreenStartX/2-DdfResolution)+(8*((ScreenWidth/16)-1))
  dc.w          DIWSTRT,(ScreenStartY<<8)|ScreenStartX
  dc.w          DIWSTOP,((ScreenStopY-256)<<8)|(ScreenStopX-256)
mm_cop_list_colors:
  dc.w          COLOR00,$0000
  dc.w          COLOR01,$0000
  dc.w          COLOR02,$0000
  dc.w          COLOR03,$0000
  dc.w          COLOR04,$0000
  dc.w          COLOR05,$0000
  dc.w          COLOR06,$0000
  dc.w          COLOR07,$0000
  dc.w          COLOR08,$0000
  dc.w          COLOR09,$0000
  dc.w          COLOR10,$0000
  dc.w          COLOR11,$0000
  dc.w          COLOR12,$0000
  dc.w          COLOR13,$0000
  dc.w          COLOR14,$0000
  dc.w          COLOR15,$0000
  dc.w          COLOR16,$0000
  dc.w          COLOR17,$0000
  dc.w          COLOR18,$0000
  dc.w          COLOR19,$0000
  dc.w          COLOR20,$0000
  dc.w          COLOR21,$0000
  dc.w          COLOR22,$0000
  dc.w          COLOR23,$0000
  dc.w          COLOR24,$0000
  dc.w          COLOR25,$0000
  dc.w          COLOR26,$0000
  dc.w          COLOR27,$0000
  dc.w          COLOR28,$0000
  dc.w          COLOR29,$0000
  dc.w          COLOR30,$0000
  dc.w          COLOR31,$0000

; trigger Copper-IRQ after all bitplane and sprite registers are set => irq routine can safely modify copperlist for next frame
  dc.w          INTREQ,%1000000000010000

  dc.w          $ffff,$fffe
