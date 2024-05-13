  section       GameoverCode,code

  include       "constants.i"

;
; called before system control is taken over
; additional files can be loaded here
;
  xdef          go_init
go_init:
  movem.l       d0-d7/a0-a6,-(sp)

; read othermem dat
  move.l        #f005_filename,d5
  move.l        #m_cm_area+go_cm_screenbuffer,d6
  move.l        #f005_filesize,d7
  jsr           dos_readfile
; inflate othermem dat
  lea.l         m_cm_area+go_cm_screenbuffer,a5
  lea.l         m_om_area+go_om_f005,a4
  jsr           inflate
                
; read chipmem dat
  move.l        #f004_filename,d5
  move.l        #m_cm_area+go_cm_screenbuffer,d6
  move.l        #f004_filesize,d7
  jsr           dos_readfile
; inflate chipmem dat
  lea.l         m_cm_area+go_cm_screenbuffer,a5
  lea.l         m_cm_area+go_cm_f004,a4
  jsr           inflate

  movem.l       (sp)+,d0-d7/a0-a6
  rts

;
; called when system is under control
;
  xdef          go_start
go_start:
  SET_PTRS

  moveq.l       #1,d0
  jsr           fade_in_init

  jsr           sfx_init

  bsr           init_screenbuffer
  bsr           init_copper_list_and_irq_handler
  bsr           init_music
  move.b        #1,_mt_Enable

.fade_in_wait_loop:
  btst          #GFadeIn,g_om_bools(a4)
  bne.s         .fade_in_wait_loop

.main_loop:
  btst          #FireButton,CIAAPRA
  bne.s         .main_loop

  jsr           sfx_enter_go
  moveq.l       #1,d0
  jsr           fade_out_init

.fade_out_wait_loop:
  btst          #GFadeOut,g_om_bools(a4)
  bne.s         .fade_out_wait_loop
 
  jsr           _mt_end

  clr.b         g_om_level(a4)
  rts

init_screenbuffer:
  WAIT_BLT
  BLT_AD_CPY    ScreenWidthBytes

  lea.l         go_cm_f004+f004_dat_tiles_iff(a5),a0
  lea.l         go_om_f005+f005_dat_gameover_tmx(a4),a1
  lea.l         m_cm_area+go_cm_screenbuffer,a2
  move.l        a2,d5

  move.w        #(ScreenHeight/TilePixelHeight)-1,d7                                    ; rows-1
.isb_loop:
  move.w        #(ScreenWidth/TilePixelWidth)-1,d6                                      ; columns-1
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

; print text elements
  lea.l         m_cm_area+go_cm_f004+f004_dat_tiles_iff,a0
  jsr           text_init

  move.l        g_om_score(a4),d0
  jsr           bcd_to_string_of_6

  move.l        #ScreenWidthBytes,d0

  lea.l         m_cm_area+go_cm_screenbuffer,a1
  add.l         #((ScreenWidthBytes*ScreenBitPlanes)*((TilePixelHeight*12)-4))+17,a1
  jsr           text_print

  lea.l         text_0(pc),a0
  lea.l         m_cm_area+go_cm_screenbuffer,a1
  add.l         #((ScreenWidthBytes*ScreenBitPlanes)*((TilePixelHeight*11)-4))+13,a1
  jsr           text_print

  lea.l         text_1(pc),a0
  lea.l         m_cm_area+go_cm_screenbuffer,a1
  add.l         #((ScreenWidthBytes*ScreenBitPlanes)*((TilePixelHeight*13)-4))+13,a1
  jsr           text_print

  rts

text_0:
  dc.b          "YOUR SCORE WAS",0
  even
text_1:
  dc.b          "  PRESS FIRE  ",0
  even

init_copper_list_and_irq_handler:
; set bitplane pointers in copperlist
  move.l        #m_cm_area+go_cm_screenbuffer,d0
  lea.l         go_cop_list_bitplane_pointer,a0
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

  lea.l         go_lvl3_handler(pc),a0
  jsr           osc_set_irq_handler
  move.l        #go_cop_list,COP1LC(a6)
  rts

go_lvl3_handler:
  movem.l       d0-d7/a0-a6,-(sp)

  SET_PTRS

  ; clear Copper-IRQ-Bit
  move.w        #%0000000000010000,INTREQ(a6)

  ; do fade in and out
  lea.l         go_cop_list_colors,a0
  jsr           do_fade

  ; call ptplayer for music and sfx
  jsr           _mt_music
 
  movem.l       (sp)+,d0-d7/a0-a6
  rte

init_music:
  lea.l         m_om_area+go_om_f005+f005_dat_revenge_of_earth_mod_data,a0
  lea.l         m_cm_area+go_cm_f004+f004_dat_revenge_of_earth_mod_samples,a1
  PTP_INIT

  section       GameoverChipData,data_c

go_cop_list:
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
go_cop_list_bitplane_pointer:
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
go_cop_list_colors:
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
