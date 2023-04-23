  section    PlayerShotCode,code
  
  include    "constants.i"

  xdef       ps_init
ps_init:
  move.w     #ps_size*PsMaxCount,d7
  lea.l      ig_om_playershots(a4),a0
.loop:
  clr.b      (a0)+
  dbf        d7,.loop
  rts

  xdef       ps_new_shot
ps_new_shot:
  ; draw shot as bob according to player position
  lea.l      ig_om_playershots(a4),a1

  ; find first not active slot
  moveq.l    #PsMaxCount-1,d7
.find_loop:
  tst.l      b_eol_frame(a1)
  bne.s      .go_on
  btst       #BobActive,b_bools(a1)
  beq.s      .go_on
  add.l      #ps_size,a1
  dbf        d7,.find_loop
  ; no additional shot possible, just exit
  rts

.go_on:
  bset       #BobActive,b_bools(a1)

  move.w     ig_om_player+pl_xpos(a4),d0
  sub.w      #ScreenStartX-16,d0
  move.w     d0,b_xpos(a1)

  move.w     ig_om_player+pl_ypos(a4),d0
  sub.w      #ScreenStartY,d0
  move.w     d0,b_ypos(a1)

  moveq.l    #1,d0
  move.l     d0,b_b_0+bb_bltptr(a1)
  move.l     d0,b_b_1+bb_bltptr(a1)

  move.w     #TilePixelWidth,b_width(a1)
  move.w     #TilePixelHeight,b_height(a1)

  move.l     #(TilesWidthBytes*TilesBitplanes*TilePixelHeight*10)+16,b_tiles_offset(a1)

; play shot sample
  jmp        sfx_shot

; updates active playershots each frame
  xdef       ps_update
ps_update:
  ; get pointer to target screenbuffer
  move.l     a5,a3
  move.l     ig_om_frame_counter(a4),d0
  btst       #0,d0
  beq.s      .1
  add.l      #ig_cm_screenbuffer0,a3
  bra.s      .2
.1:
  add.l      #ig_cm_screenbuffer1,a3
.2:

  lea.l      ig_om_playershots(a4),a1
  moveq.l    #PsMaxCount-1,d7
.loop:
  tst.l      b_eol_frame(a1)
  bne.s      .go_on

  btst       #BobActive,b_bools(a1)
  beq.s      .go_on
  add.w      #PsSpeed,b_xpos(a1)

  ; check for collision with background between old and new position
  move.w     b_xpos(a1),d0
  move.w     b_ypos(a1),d1
  move.w     ig_om_scroll_xpos_frbuf(a4),d2
  jsr        cc_scr_to_bplptr
  move.l     a3,a0
  add.l      d1,a0

  ; check for any pixel in masked range
  add.l      #LevelScreenBufferWidthBytes*ScreenBitPlanes*7,a0
  move.l     (a0),d3
  add.l      #LevelScreenBufferWidthBytes,a0
  or.l       (a0),d3
  add.l      #LevelScreenBufferWidthBytes,a0
  or.l       (a0),d3
  add.l      #LevelScreenBufferWidthBytes,a0
  or.l       (a0),d3
  lea.l      mask_background(pc),a0
  lsl.w      #2,d0
  move.l     (a0,d0.w),d2
  and.l      d2,d3
  tst.l      d3
  beq.s      .draw_shot

  ; shot hit background
  move.l     ig_om_frame_counter(a4),d0
  addq.l     #2,d0
  move.l     d0,b_eol_frame(a1)

  ;
  ; TODO: spawn small explosion (only one at a time is enough?!)
  ;

  bra.s      .go_on

.draw_shot:
  move.l     ig_om_frame_counter(a4),d0
  jsr        bob_draw
.go_on:
  add.l      #ps_size,a1
  dbf        d7,.loop
  rts

mask_background:
  dc.l       %11111111111100000000000000000000
  dc.l       %01111111111110000000000000000000
  dc.l       %00111111111111000000000000000000
  dc.l       %00011111111111100000000000000000
  dc.l       %00001111111111110000000000000000
  dc.l       %00000111111111111000000000000000
  dc.l       %00000011111111111100000000000000
  dc.l       %00000001111111111110000000000000
  dc.l       %00000000111111111111000000000000
  dc.l       %00000000011111111111100000000000
  dc.l       %00000000001111111111110000000000
  dc.l       %00000000000111111111111000000000
  dc.l       %00000000000011111111111100000000
  dc.l       %00000000000001111111111110000000
  dc.l       %00000000000000111111111111000000
  dc.l       %00000000000000011111111111100000
