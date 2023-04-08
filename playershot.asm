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
; draw shot as bob according to player position  - TODO: move it on screen
  lea.l      ig_om_playershots(a4),a1

  ; find first not active slot
  moveq.l    #PsMaxCount-1,d7
.find_loop:
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
  lea.l      ig_om_playershots(a4),a1
  moveq.l    #PsMaxCount-1,d7
.loop:
  btst       #BobActive,b_bools(a1)
  beq.s      .go_on
  add.w      #PsSpeed,b_xpos(a1)
  move.l     ig_om_frame_counter(a4),d0
  jsr        bob_draw
.go_on:
  add.l      #ps_size,a1
  dbf        d7,.loop
  rts
