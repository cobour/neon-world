  section    PlayerShotCode,code
  
  include    "constants.i"

  xdef       ps_init
ps_init:
  move.w     #ps_size*PsMaxCount,d7
  lea.l      ig_om_playershots(a4),a0
.loop:
  clr.b      (a0)+
  dbf        d7,.loop

  ; init playershot explosion
  lea.l      ig_om_playershot_explosion(a4),a2
  move.b     #0,b_draw_hit_frames(a2)
  moveq.l    #1,d0
  move.l     d0,b_b_0+bb_bltptr(a2)
  move.l     d0,b_b_1+bb_bltptr(a2)
  move.w     #TilePixelWidth/2,b_width(a2)
  move.w     #TilePixelHeight/2,b_height(a2)
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
  bset       #BobCanCollide,b_bools(a1)
  clr.l      b_eol_frame(a1)

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

  move.w     ig_om_player+pl_weapon_strength(a4),d0
  cmp.w      #1,d0
  bne.s      .not_1
  move.l     #(TilesWidthBytes*TilesBitplanes*TilePixelHeight*10)+16,b_tiles_offset(a1)
  bra.s      .play_sfx
.not_1:
  cmp.w      #2,d0
  bne.s      .not_2
  move.l     #(TilesWidthBytes*TilesBitplanes*TilePixelHeight*11)+16,b_tiles_offset(a1)
  bra.s      .play_sfx
.not_2:
  move.l     #(TilesWidthBytes*TilesBitplanes*TilePixelHeight*12)+16,b_tiles_offset(a1)

.play_sfx:
; play shot sample
  jmp        sfx_shot

; updates active playershots each frame
  xdef       ps_update_pos_and_state
ps_update_pos_and_state:
  ; get pointer to target screenbuffer
  move.l     a5,a3
  move.l     ig_om_frame_counter(a4),d0
  btst       #0,d0
  bne.s      .1
  add.l      #ig_cm_screenbuffer0,a3
  bra.s      .2
.1:
  add.l      #ig_cm_screenbuffer1,a3
.2:

  lea.l      ig_om_playershots(a4),a1
  moveq.l    #PsMaxCount-1,d7
.loop:
  tst.l      b_eol_frame(a1)
  bne        .go_on

  btst       #BobActive,b_bools(a1)
  beq        .go_on
  add.w      #PsSpeed,b_xpos(a1)

  ; check for end-of-life
  move.w     b_xpos(a1),d0
  cmp.w      #ScreenWidth,d0
  blt.s      .still_on_screen

  move.l     ig_om_frame_counter(a4),d1
  addq.l     #2,d1
  move.l     d1,b_eol_frame(a1)
  bclr       #BobCanCollide,b_bools(a1)
  bra        .go_on

  ; check for collision with background between old and new position
.still_on_screen:
  ; upper bound of shot
  move.w     b_ypos(a1),d1
  sub.w      ig_om_player+pl_weapon_strength(a4),d1
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
  bne.s      .hit

  ; lower bound of shot
  move.w     b_xpos(a1),d0
  move.w     b_ypos(a1),d1
  add.w      ig_om_player+pl_weapon_strength(a4),d1
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
  beq.s      .go_on

.hit:
  ; shot hit background
  jsr        sfx_explosion_small
  move.l     ig_om_frame_counter(a4),d0
  addq.l     #2,d0
  move.l     d0,b_eol_frame(a1)
  bclr       #BobCanCollide,b_bools(a1)

  ; spawn small explosion (only one at a time is enough)
  lea.l      ig_om_playershot_explosion(a4),a2
  bset       #BobActive,b_bools(a2)
  clr.l      b_eol_frame(a2)
  ; do NOT reset bb_bltptr's since pse may be reused while playing anim

  move.w     b_xpos(a1),b_xpos(a2)
  move.w     b_ypos(a1),b_ypos(a2)
  add.w      #4,b_xpos(a2)
  add.w      #4,b_ypos(a2)

  move.b     #0,exp_anim_count(a2)

.go_on:
  add.l      #ps_size,a1
  dbf        d7,.loop

  rts

  xdef       ps_draw
ps_draw:
  lea.l      ig_om_playershots(a4),a1
  moveq.l    #PsMaxCount-1,d7
.pd_loop:
  tst.l      b_eol_frame(a1)
  bne.s      .pd_loop_next
  btst       #BobActive,b_bools(a1)
  beq.s      .pd_loop_next
  move.l     ig_om_frame_counter(a4),d0
  jsr        bob_draw
.pd_loop_next:
  add.l      #ps_size,a1
  dbf        d7,.pd_loop

  ; draw playershot-explosion
  lea.l      ig_om_playershot_explosion(a4),a1
  btst       #BobActive,b_bools(a1)
  beq.s      .exit

  cmp.b      #ExpMaxAnimCount,exp_anim_count(a1)
  bne.s      .pse_update_anim_count

  ; anim ended
  ; check if eol already set
  tst.l      b_eol_frame(a1)
  bne.s      .exit
  ; set eol
  move.l     ig_om_frame_counter(a4),d0
  addq.l     #2,d0
  move.l     d0,b_eol_frame(a1)
  bra.s      .exit

.pse_update_anim_count:
  btst       #0,ig_om_frame_counter+3(a4)
  bne.s      .pse_no_anim_frame_update
  add.b      #1,exp_anim_count(a1)
.pse_no_anim_frame_update:
  moveq.l    #0,d0
  move.b     exp_anim_count(a1),d0
  lsl.w      #1,d0
  lea.l      pse_tiles_offsets(pc),a0
  move.w     (a0,d0.w),d0
  move.l     d0,b_tiles_offset(a1)
  
  move.l     ig_om_frame_counter(a4),d0
  jsr        bob_draw

  btst       #IgPerformScroll,ig_om_bools(a4)
  beq.s      .exit
  sub.w      #1,b_xpos(a1)

.exit:
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

pse_tiles_offsets: ; done here because tiles are 16x16 mostly and player shots are 8x8
  dc.w       (7*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+36
  dc.w       (7*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+36+2
  dc.w       (7*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+(8*TilesWidthBytes*TilesBitplanes)+36
  dc.w       (7*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+(8*TilesWidthBytes*TilesBitplanes)+36+2
  dc.w       (7*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+(16*TilesWidthBytes*TilesBitplanes)+36
  dc.w       (7*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+(16*TilesWidthBytes*TilesBitplanes)+36+2
  dc.w       (7*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+(24*TilesWidthBytes*TilesBitplanes)+36
  dc.w       (7*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+(24*TilesWidthBytes*TilesBitplanes)+36+2
