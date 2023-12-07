  section    EnemiesCode,code
              
  include    "constants.i"

  xdef       enemies_init
enemies_init:
  ; just two dummy enemies for now

  lea.l      ig_om_enemies(a4),a0
  clr.b      b_bools(a0)
  bset       #BobActive,b_bools(a0)
  clr.l      b_eol_frame(a0)
  move.l     #(TilesWidthBytes*TilesBitplanes*TilePixelHeight*7),b_tiles_offset(a0)
  move.w     #152,b_xpos(a0)
  move.w     #60,b_ypos(a0)
  move.w     #TilePixelWidth,b_width(a0)
  move.w     #TilePixelHeight,b_height(a0)
  moveq.l    #1,d0
  move.l     d0,b_b_0+bb_bltptr(a0)
  move.l     d0,b_b_1+bb_bltptr(a0)

  lea.l      ig_om_enemies+enemy_size(a4),a0
  clr.b      b_bools(a0)
  bset       #BobActive,b_bools(a0)
  clr.l      b_eol_frame(a0)
  move.l     #(TilesWidthBytes*TilesBitplanes*TilePixelHeight*9),b_tiles_offset(a0)
  move.w     #252,b_xpos(a0)
  move.w     #160,b_ypos(a0)
  move.w     #TilePixelWidth,b_width(a0)
  move.w     #TilePixelHeight,b_height(a0)
  moveq.l    #1,d0
  move.l     d0,b_b_0+bb_bltptr(a0)
  move.l     d0,b_b_1+bb_bltptr(a0)

  rts

  xdef       enemies_update
enemies_update:
  ; no deactivation for now, so no b_eol_frame ever set

  ; update first enemy
  lea.l      ig_om_enemies(a4),a0
  move.w     b_xpos(a0),d0
  sub.w      #2,d0
  cmp.w      #-TilePixelWidth-4,d0
  bge.s      .1
  move.w     #ScreenWidth-1,d0
.1:
  move.w     d0,b_xpos(a0)

.draw_enemies:
  lea.l      ig_om_enemies(a4),a1
  moveq.l    #EnemyMaxCount-1,d7
.loop:
  move.l     ig_om_frame_counter(a4),d0
  jsr        bob_draw
  add.l      #enemy_size,a1
  dbf        d7,.loop

  rts
