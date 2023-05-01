  section     BobCode,code
              
  include     "constants.i"

; restores all BOBs
; uses a0-a1,d0-d4,d7
  xdef        bob_restore
bob_restore:
  move.l      a5,d2
  move.l      ig_om_frame_counter(a4),d4
  btst        #0,d4
  beq.s       .1
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
  bne.s       .ps_go_on
  bclr        #BobActive,d0
  move.b      d0,b_bools(a0)
  clr.l       b_eol_frame(a0)
  bra.s       .ps_loop_next

.ps_go_on:
  btst        #BobActive,d0
  beq.s       .ps_loop_next
  lea.l       (a0,d3.w),a1
  bsr.s       .restore_one_bob

.ps_loop_next:
  add.l       #ps_size,a0
  dbf         d7,.ps_loop

  ; restore playershot-explosion

  lea.l       ig_om_playershot_explosion(a4),a0
  move.b      b_bools(a0),d0
  tst.l       b_eol_frame(a0)
  beq.s       .pse_check_active
  cmp.l       b_eol_frame(a0),d4
  bne.s       .pse_check_active
  bclr        #BobActive,d0
  move.b      d0,b_bools(a0)
  clr.l       b_eol_frame(a0)
  bra.s       .pse_restore
.pse_check_active:
  btst        #BobActive,d0
  beq.s       .pse_end
.pse_restore:
  lea.l       (a0,d3.w),a1
  bsr.s       .restore_one_bob

.pse_end:

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
; uses a0,a2,d1-d3
;
; TODO: Because right now the only bobs are playershots, clipping is only done for the right border of the screen.
;
; assumptions:
;    all BOBs are 16 pixel wide
;    all BOBs are 16 pixel high
;    all BOBs are drawn to ingame screenbuffers (LevelScreenBufferWidthBytes wide)
  xdef        bob_draw
bob_draw:

  move.w      b_xpos(a1),d1

  move.w      #$ffff,d4                                       ; BLTAFWM and BLTALWM
  cmp.w       #ScreenWidth-15,d1
  blt.s       .full_fwm_lwm
  lea         .mask_right(pc),a0
  move.w      d1,d2
  sub.w       #ScreenWidth-15,d2
  lsl.w       #1,d2
  move.w      (a0,d2.w),d4
.full_fwm_lwm:
  cmp.w       #ScreenWidth,d1
  blt.s       .still_visible
  tst.l       b_eol_frame(a1)
  bne.s       .exit
  move.l      d0,d1
  addq.l      #2,d1
  move.l      d1,b_eol_frame(a1)
.exit:
  rts

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

.still_visible:

; at this point the scroll routine has altered the bitplane pointers in the copperlist for
; the next frame, so we must draw to the same buffer that is pointed to in the copperlist,
; because that is the buffer that is currently NOT displayed, but prepared for the next frame
; to be displayed.
; since the framecounter is incremented at the very end of the lvl3-irq routine, we choose
; the buffer zero for the odd counts and vice versa.
  move.l      a5,d3
  btst        #0,d0
  beq.s       .1
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
  move.l      d3,BLTAPTH(a6)
  ; b-ptr (gfx)
  move.l      a5,d3
  add.l       #ig_cm_f002+f002_dat_tiles_iff,d3
  add.l       b_tiles_offset(a1),d3
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

  cmp.w       #TilePixelHeight,b_width(a1)
  beq.s       .2a
  move.w      #(TilePixelHeight/2*ScreenBitPlanes<<6)+1,d0
  bra.s       .2b
.2a:
  move.w      #(TilePixelHeight*ScreenBitPlanes<<6)+1,d0
.2b:  
  move.w      d0,bb_bltsize(a2)
  move.w      d0,BLTSIZE(a6)

  rts
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

  cmp.w       #TilePixelHeight,b_width(a1)
  beq.s       .3a
  move.w      #(TilePixelHeight/2*ScreenBitPlanes<<6)+2,d0
  bra.s       .3b
.3a:
  move.w      #(TilePixelHeight*ScreenBitPlanes<<6)+2,d0
.3b:  
  move.w      d0,bb_bltsize(a2)
  move.w      d0,BLTSIZE(a6)

  rts
