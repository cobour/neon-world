  section     BobCode,code
              
  include     "constants.i"

; restores all BOBs
; uses a0-a1,d0-d4,d7
  xdef        bob_restore
bob_restore:
  move.l      a5,d2
  move.l      ig_om_frame_counter(a4),d4
  btst        #0,d4
  bne.s       .1
  add.l       #ig_cm_screenbuffer0,d2
  move.w      #b_b_0,d3
  bra.s       .2
.1:
  add.l       #ig_cm_screenbuffer1,d2
  move.w      #b_b_1,d3
.2:

  ; restore playershots

  lea.l       ig_om_playershots(a4),a0
  moveq.l     #PsMaxCount-1,d7
.ps_loop:
  move.b      b_bools(a0),d0

  tst.l       b_eol_frame(a0)
  beq.s       .ps_go_on
  cmp.l       b_eol_frame(a0),d4
  ble.s       .ps_go_on
  bclr        #BobActive,d0
  move.b      d0,b_bools(a0)
  clr.l       b_eol_frame(a0)
  bra.s       .ps_loop_next

.ps_go_on:
  btst        #BobActive,d0
  beq.s       .ps_loop_next
  lea.l       (a0,d3.w),a1
  bsr         .restore_one_bob

.ps_loop_next:
  add.l       #ps_size,a0
  dbf         d7,.ps_loop

  ; restore playershot-explosion

  lea.l       ig_om_playershot_explosion(a4),a0
  move.b      b_bools(a0),d0

  tst.l       b_eol_frame(a0)
  beq.s       .pse_go_on
  cmp.l       b_eol_frame(a0),d4
  ble.s       .pse_go_on
  bclr        #BobActive,d0
  move.b      d0,b_bools(a0)
  clr.l       b_eol_frame(a0)
  bra.s       .pse_end

.pse_go_on:
  btst        #BobActive,d0
  beq.s       .pse_end
  lea.l       (a0,d3.w),a1
  bsr.s       .restore_one_bob

.pse_end:

  ; restore enemies

  lea.l       ig_om_enemies(a4),a0
  moveq.l     #EnemyMaxCount-1,d7
.enemy_loop:
  move.b      b_bools(a0),d0

  tst.l       b_eol_frame(a0)
  beq.s       .enemy_go_on
  cmp.l       b_eol_frame(a0),d4
  ble.s       .enemy_go_on
  
  bclr        #BobActive,d0
  move.b      d0,b_bools(a0)
  clr.l       b_eol_frame(a0)
  bra.s       .enemy_loop_next

.enemy_go_on:
  lea.l       (a0,d3.w),a1
  bsr.s       .restore_one_bob

.enemy_loop_next:
  add.l       #enemy_size,a0
  dbf         d7,.enemy_loop

  ; restore enemy explosion

  lea.l       ig_om_enemy_explosion(a4),a0
  move.b      b_bools(a0),d0

  tst.l       b_eol_frame(a0)
  beq.s       .ene_go_on
  cmp.l       b_eol_frame(a0),d4
  ble.s       .ene_go_on
  bclr        #BobActive,d0
  move.b      d0,b_bools(a0)
  moveq.l     #0,d0
  move.l      d0,b_eol_frame(a0)
  bra.s       .ene_end

.ene_go_on:
  btst        #BobActive,d0
  beq.s       .ene_end
  lea.l       (a0,d3.w),a1
  bsr.s       .restore_one_bob

.ene_end:

  rts

.restore_one_bob
  ; check if restore is necessary
  move.l      bb_bltptr(a1),d0
  cmp.b       #1,d0
  beq.s       .do_not_restore

  ; restore
  sub.l       bb_screenbuffer_base(a1),d0
  move.l      d0,d1
  add.l       #m_cm_area+ig_cm_screenbuffer2,d1
  WAIT_BLT
  move.l      d1,BLTAPTH(a6)
  move.l      d2,d1
  add.l       d0,d1
  move.l      d1,BLTDPTH(a6)

  move.w      #$ffff,d1
  move.w      d1,BLTAFWM(a6)
  move.w      d1,BLTALWM(a6)

  move.w      #%0000100111110000,BLTCON0(a6)
  clr.w       BLTCON1(a6)

  move.w      bb_bltmod(a1),d1
  move.w      d1,BLTAMOD(a6)
  move.w      d1,BLTDMOD(a6)

  move.w      bb_bltsize(a1),BLTSIZE(a6)

.do_not_restore
  rts

; a1 - pointer to bob-structure (see constant.i)
; d0 - odd/even-counter indicating which framebuffer must be drawn to (only bit 0 is used, register is overwritten)
; uses a0,a2,d1-d6
;
; assumptions:
;    all BOBs are 16 pixel wide
;    all BOBs are 16 pixel high
;    all BOBs are drawn to ingame screenbuffers (LevelScreenBufferWidthBytes wide)
  xdef        bob_draw
bob_draw:
  move.l      d7,-(sp)                                   ; often used for loops calling this code

  ; first check if bob is (at least partly) visible

  move.w      b_xpos(a1),d1
  cmp.w       #ScreenWidth,d1
  bgt         .exit
  add.w       b_width(a1),d1
  tst.w       d1
  blt         .exit
  move.w      b_ypos(a1),d1
  cmp.w       #ScreenHeight,d1
  bgt         .exit
  add.w       b_height(a1),d1
  tst.w       d1
  blt         .exit

  ; check for need of masking left or right (both at the same time is not possible)
  ; result:
  ;  d4.w - BLTAFWM and BLTALWM ( same because all bobs are 16 pixel wide )

  move.w      b_xpos(a1),d1
  move.w      #ScreenWidth,d5
  sub.w       b_width(a1),d5                             ; max x-pos without need for using a mask
  move.w      #$ffff,d4

  ; check for right mask
  cmp.w       d5,d1
  blt.s       .no_mask_right

  lea         .mask_right(pc),a0
  move.w      d1,d2
  sub.w       d5,d2
  lsl.w       #1,d2
  move.w      (a0,d2.w),d4

.no_mask_right:

  ; check for left mask
  tst.w       d1
  bge.s       .no_mask_left

  lea         .mask_left(pc),a0
  move.w      d1,d2
  add.w       #TilePixelWidth-1,d2
  lsl.w       #1,d2
  move.w      (a0,d2.w),d4
    
.no_mask_left:

  ; check for need of clipping top or bottom (both at the same time is not possible)
  ; results:
  ;  d5.w - adjusted height
  ;  d6.w - diff to ypos ( +0 - +15 )
  ;  d7.l - add to source pointer

  ; check for top clip
  move.w      b_ypos(a1),d1
  tst.w       d1
  bge.s       .no_top_clip
  move.w      d1,d5
  add.w       #1,d5
  add.w       b_height(a1),d5                            ; d5 = adjusted height of bob
  move.w      d1,d6
  neg.w       d6                                         ; d6 = add to ypos of bob
  move.w      d6,d7
  sub.w       #1,d7
  lsl.w       #2,d7
  lea.l       .source_offsets(pc),a0
  move.l      (a0,d7.w),d7                               ; d7 = add to source pointer
  bra         .is_visible                                ; bottom clip not possible

.source_offsets:
  dc.l        TilesWidthBytes*TilesBitplanes*0
  dc.l        TilesWidthBytes*TilesBitplanes*1
  dc.l        TilesWidthBytes*TilesBitplanes*2
  dc.l        TilesWidthBytes*TilesBitplanes*3
  dc.l        TilesWidthBytes*TilesBitplanes*4
  dc.l        TilesWidthBytes*TilesBitplanes*5
  dc.l        TilesWidthBytes*TilesBitplanes*6
  dc.l        TilesWidthBytes*TilesBitplanes*7
  dc.l        TilesWidthBytes*TilesBitplanes*8
  dc.l        TilesWidthBytes*TilesBitplanes*9
  dc.l        TilesWidthBytes*TilesBitplanes*10
  dc.l        TilesWidthBytes*TilesBitplanes*11
  dc.l        TilesWidthBytes*TilesBitplanes*12
  dc.l        TilesWidthBytes*TilesBitplanes*13
  dc.l        TilesWidthBytes*TilesBitplanes*14
  dc.l        TilesWidthBytes*TilesBitplanes*15

.no_top_clip:

  ; check for bottom clip
  add.w       b_height(a1),d1
  cmp.w       #ScreenHeight,d1
  blt.s       .no_bottom_clip
  move.w      d1,d5
  sub.w       #ScreenHeight,d5
  neg.w       d5
  add.w       b_height(a1),d5                            ; d5 = adjusted height of bob
  moveq.l     #0,d6                                      ; d6 = no add to ypos of bob
  moveq.l     #0,d7                                      ; d7 = no add to source pointer
  bra.s       .is_visible

.no_bottom_clip:
  move.w      b_height(a1),d5                            ; d5 = height of bob
  moveq.l     #0,d6                                      ; d6 = no add to ypos of bob
  moveq.l     #0,d7                                      ; d7 = no add to source pointer
  bra.s       .is_visible

.mask_right:
  dc.w        %1111111111111110
  dc.w        %1111111111111100
  dc.w        %1111111111111000
  dc.w        %1111111111110000
  dc.w        %1111111111100000
  dc.w        %1111111111000000
  dc.w        %1111111110000000
  dc.w        %1111111100000000
  dc.w        %1111111000000000
  dc.w        %1111110000000000
  dc.w        %1111100000000000
  dc.w        %1111000000000000
  dc.w        %1110000000000000
  dc.w        %1100000000000000
  dc.w        %1000000000000000

.mask_left:
  dc.w        %0000000000000001
  dc.w        %0000000000000011
  dc.w        %0000000000000111
  dc.w        %0000000000001111
  dc.w        %0000000000011111
  dc.w        %0000000000111111
  dc.w        %0000000001111111
  dc.w        %0000000011111111
  dc.w        %0000000111111111
  dc.w        %0000001111111111
  dc.w        %0000011111111111
  dc.w        %0000111111111111
  dc.w        %0001111111111111
  dc.w        %0011111111111111
  dc.w        %0111111111111111

.is_visible:

; at this point the scroll routine has altered the bitplane pointers in the copperlist for
; the next frame, so we must draw to the same buffer that is pointed to in the copperlist,
; because that is the buffer that is currently NOT displayed, but prepared for the next frame
; to be displayed.
  move.l      a5,d3
  btst        #0,d0
  bne.s       .1
  add.l       #ig_cm_screenbuffer0,d3
  lea.l       b_b_0(a1),a2
  bra.s       .2
.1:
  add.l       #ig_cm_screenbuffer1,d3
  lea.l       b_b_1(a1),a2
.2:

  move.l      d3,bb_screenbuffer_base(a2)

  move.w      b_xpos(a1),d0
  move.w      b_ypos(a1),d1
  add.w       d6,d1                                      ; add to ypos ( because of vertical clipping )
  move.w      ig_om_scroll_xpos_frbuf(a4),d2
  jsr         cc_scr_to_bplptr

  ; target pointer (word boundary)
  add.l       d1,d3
  move.l      d3,bb_bltptr(a2)
  WAIT_BLT
  move.l      d3,BLTCPTH(a6)
  move.l      d3,BLTDPTH(a6)

  ; source pointers (does not matter if shifted or not)
  ; a-ptr (mask)
  move.l      a5,d3
  add.l       #ig_cm_f002+f002_dat_tiles_iff_mask,d3
  add.l       b_tiles_offset(a1),d3
  add.l       d7,d3                                      ; add offset due to clipping
  move.l      d3,BLTAPTH(a6)
  ; b-ptr (gfx)
  move.l      a5,d3
  add.l       #ig_cm_f002+f002_dat_tiles_iff,d3
  add.l       b_tiles_offset(a1),d3
  add.l       d7,d3                                      ; add offset due to clipping
  move.l      d3,BLTBPTH(a6)

  ; check for pixel shift
  tst.b       d0
  bne.s       .3  

  move.w      d4,BLTAFWM(a6)
  move.w      d4,BLTALWM(a6)
  move.w      #%0000111111001010,BLTCON0(a6)
  clr.w       BLTCON1(a6)

  ; source modulos
  move.w      #TilesWidthBytes-2,d1
  move.w      d1,BLTAMOD(a6)
  move.w      d1,BLTBMOD(a6)

  ; target modulos
  move.w      #LevelScreenBufferWidthBytes-2,d0
  move.w      d0,BLTCMOD(a6)
  move.w      d0,BLTDMOD(a6)
  move.w      d0,bb_bltmod(a2)

  cmp.w       #TilePixelHeight,b_height(a1)
  beq.s       .2a
  lea.l       .bltsizes_half_height_no_shift(pc),a0
  bra.s       .2b
.2a:
  lea.l       .bltsizes_full_height_no_shift(pc),a0
.2b:  
  sub.w       #1,d5
  lsl.w       #1,d5
  move.w      (a0,d5.w),d1
  move.w      d1,bb_bltsize(a2)
  move.w      d1,BLTSIZE(a6)

  bra.s       .exit

.3:
  ; d0 = bits to be shifted
  ror.w       #4,d0
  move.w      d0,BLTCON1(a6)
  or.w        #%0000111111001010,d0
  move.w      d0,BLTCON0(a6)

  move.w      d4,BLTAFWM(a6)
  clr.w       BLTALWM(a6)

  ; source modulos
  move.w      #TilesWidthBytes-4,d1
  move.w      d1,BLTAMOD(a6)
  move.w      d1,BLTBMOD(a6)

  ; target modulos
  move.w      #LevelScreenBufferWidthBytes-4,d0
  move.w      d0,BLTCMOD(a6)
  move.w      d0,BLTDMOD(a6)
  move.w      d0,bb_bltmod(a2)

  cmp.w       #TilePixelHeight,b_height(a1)
  beq.s       .3a
  lea.l       .bltsizes_half_height_with_shift(pc),a0
  bra.s       .3b
.3a:
  lea.l       .bltsizes_full_height_with_shift(pc),a0
.3b:
  sub.w       #1,d5
  lsl.w       #1,d5
  move.w      (a0,d5.w),d1
  move.w      d1,bb_bltsize(a2)
  move.w      d1,BLTSIZE(a6)

.exit:
  move.l      (sp)+,d7
  rts

.bltsizes_full_height_no_shift:
  dc.w        (1*ScreenBitPlanes<<6)+1
  dc.w        (2*ScreenBitPlanes<<6)+1
  dc.w        (3*ScreenBitPlanes<<6)+1
  dc.w        (4*ScreenBitPlanes<<6)+1
  dc.w        (5*ScreenBitPlanes<<6)+1
  dc.w        (6*ScreenBitPlanes<<6)+1
  dc.w        (7*ScreenBitPlanes<<6)+1
  dc.w        (8*ScreenBitPlanes<<6)+1
  dc.w        (9*ScreenBitPlanes<<6)+1
  dc.w        (10*ScreenBitPlanes<<6)+1
  dc.w        (11*ScreenBitPlanes<<6)+1
  dc.w        (12*ScreenBitPlanes<<6)+1
  dc.w        (13*ScreenBitPlanes<<6)+1
  dc.w        (14*ScreenBitPlanes<<6)+1
  dc.w        (15*ScreenBitPlanes<<6)+1
  dc.w        (16*ScreenBitPlanes<<6)+1

.bltsizes_half_height_no_shift:
  dc.w        (1*ScreenBitPlanes<<6)+1
  dc.w        (2*ScreenBitPlanes<<6)+1
  dc.w        (3*ScreenBitPlanes<<6)+1
  dc.w        (4*ScreenBitPlanes<<6)+1
  dc.w        (5*ScreenBitPlanes<<6)+1
  dc.w        (6*ScreenBitPlanes<<6)+1
  dc.w        (7*ScreenBitPlanes<<6)+1
  dc.w        (8*ScreenBitPlanes<<6)+1

.bltsizes_full_height_with_shift:
  dc.w        (1*ScreenBitPlanes<<6)+2
  dc.w        (2*ScreenBitPlanes<<6)+2
  dc.w        (3*ScreenBitPlanes<<6)+2
  dc.w        (4*ScreenBitPlanes<<6)+2
  dc.w        (5*ScreenBitPlanes<<6)+2
  dc.w        (6*ScreenBitPlanes<<6)+2
  dc.w        (7*ScreenBitPlanes<<6)+2
  dc.w        (8*ScreenBitPlanes<<6)+2
  dc.w        (9*ScreenBitPlanes<<6)+2
  dc.w        (10*ScreenBitPlanes<<6)+2
  dc.w        (11*ScreenBitPlanes<<6)+2
  dc.w        (12*ScreenBitPlanes<<6)+2
  dc.w        (13*ScreenBitPlanes<<6)+2
  dc.w        (14*ScreenBitPlanes<<6)+2
  dc.w        (15*ScreenBitPlanes<<6)+2
  dc.w        (16*ScreenBitPlanes<<6)+2

.bltsizes_half_height_with_shift:
  dc.w        (1*ScreenBitPlanes<<6)+2
  dc.w        (2*ScreenBitPlanes<<6)+2
  dc.w        (3*ScreenBitPlanes<<6)+2
  dc.w        (4*ScreenBitPlanes<<6)+2
  dc.w        (5*ScreenBitPlanes<<6)+2
  dc.w        (6*ScreenBitPlanes<<6)+2
  dc.w        (7*ScreenBitPlanes<<6)+2
  dc.w        (8*ScreenBitPlanes<<6)+2
