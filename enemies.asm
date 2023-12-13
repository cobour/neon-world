  section    EnemiesCode,code
              
  include    "constants.i"

  xdef       enemies_init
enemies_init:
  ; just two dummy enemies for now

  lea.l      ig_om_enemies(a4),a0
  clr.b      b_bools(a0)
  bset       #BobActive,b_bools(a0)
  clr.l      b_eol_frame(a0)
  move.w     #152,b_xpos(a0)
  move.w     #60,b_ypos(a0)
  move.w     #TilePixelWidth,b_width(a0)
  move.w     #TilePixelHeight,b_height(a0)
  moveq.l    #1,d0
  move.l     d0,b_b_0+bb_bltptr(a0)
  move.l     d0,b_b_1+bb_bltptr(a0)

  lea.l      green_face_red_eye_descriptor(pc),a1
  move.l     a1,enemy_descriptor(a0)
  clr.w      enemy_anim_step(a0)
  clr.w      enemy_anim_delay(a0)

  lea.l      ig_om_enemies+enemy_size(a4),a0
  clr.b      b_bools(a0)
  bset       #BobActive,b_bools(a0)
  clr.l      b_eol_frame(a0)
  move.w     #252,b_xpos(a0)
  move.w     #160,b_ypos(a0)
  move.w     #TilePixelWidth,b_width(a0)
  move.w     #TilePixelHeight,b_height(a0)
  moveq.l    #1,d0
  move.l     d0,b_b_0+bb_bltptr(a0)
  move.l     d0,b_b_1+bb_bltptr(a0)

  lea.l      orange_face_descriptor(pc),a1
  move.l     a1,enemy_descriptor(a0)
  clr.w      enemy_anim_step(a0)
  clr.w      enemy_anim_delay(a0)

  rts

  xdef       enemies_update_pos_and_state
enemies_update_pos_and_state:
  ; no deactivation for now, so no b_eol_frame ever set

  ; update first enemy position
  lea.l      ig_om_enemies(a4),a0
  move.w     b_xpos(a0),d0
  sub.w      #2,d0
  cmp.w      #-TilePixelWidth-4,d0
  bge.s      .1
  move.w     #ScreenWidth-1,d0
.1:
  move.w     d0,b_xpos(a0)
  rts

  xdef       enemies_draw
enemies_draw:
  lea.l      ig_om_enemies(a4),a1
  moveq.l    #EnemyMaxCount-1,d7
.ua_loop:
  ; check anim delay
  move.l     enemy_descriptor(a1),a2
  move.w     enemy_anim_delay(a1),d0
  add.w      #1,d0
  cmp.w      ed_anim_delay(a2),d0
  beq.s      .ua_anim_frame_update
  move.w     d0,enemy_anim_delay(a1)
  bra.s      .ua_loop_next
.ua_anim_frame_update:
  clr.w      enemy_anim_delay(a1)

  ; check and set next anim step
  move.w     enemy_anim_step(a1),d0
  add.w      #1,d0
  cmp.w      ed_anim_steps(a2),d0
  bne.s      .ua_next_anim_frame
  ; reset to first anim frame
  clr.w      enemy_anim_step(a1)
  bra.s      .ua_loop_next
.ua_next_anim_frame:
  ; set next anim step
  move.w     d0,enemy_anim_step(a1)

.ua_loop_next:  
  add.l      #enemy_size,a1
  dbf        d7,.ua_loop

.draw_enemies:
  lea.l      ig_om_enemies(a4),a1
  moveq.l    #EnemyMaxCount-1,d7
.de_loop:
  ; set anim frame
  moveq.l    #0,d0
  move.l     enemy_descriptor(a1),a0
  move.l     ed_anim(a0),a0
  add.l      a4,a0
  move.w     enemy_anim_step(a1),d0
  lsl.w      #1,d0
  move.w     (a0,d0.w),d0
  move.l     d0,b_tiles_offset(a1)

  ; draw bob
  move.l     ig_om_frame_counter(a4),d0
  jsr        bob_draw
  add.l      #enemy_size,a1
  dbf        d7,.de_loop

  rts

; see constants.i -> ed_*
green_face_red_eye_descriptor:
  dc.l       ig_om_f003+f003_dat_green_face_red_eye_anim_tmx
  dc.w       f003_dat_green_face_red_eye_anim_tmx_tiles_width
  dc.w       3

orange_face_descriptor:
  dc.l       ig_om_f003+f003_dat_orange_face_anim_tmx
  dc.w       f003_dat_orange_face_anim_tmx_tiles_width
  dc.w       2
