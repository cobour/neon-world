  section    EnemiesCode,code
              
  include    "constants.i"

  xdef       enemies_init
enemies_init:
  ; just two dummy enemies for now

  ; moving enemy
  lea.l      ig_om_enemies(a4),a0
  clr.b      b_bools(a0)
  bset       #BobActive,b_bools(a0)
  clr.l      b_eol_frame(a0)
  move.w     #320,b_xpos(a0)
  move.w     #60,b_ypos(a0)
  move.w     #TilePixelWidth,b_width(a0)
  move.w     #TilePixelHeight,b_height(a0)
  moveq.l    #1,d0
  move.l     d0,b_b_0+bb_bltptr(a0)
  move.l     d0,b_b_1+bb_bltptr(a0)

  clr.b      enemy_bools(a0)
  bset       #EnemyActive,enemy_bools(a0)
  lea.l      green_face_red_eye_descriptor(pc),a1
  move.l     a1,enemy_descriptor(a0)
  clr.w      enemy_anim_step(a0)
  clr.w      enemy_anim_delay(a0)

  move.l     #ig_om_f003+f003_dat_wave_ods,enemy_movement(a0)
  move.w     #f003_dat_wave_ods_steps,enemy_movement_max_step(a0)
  clr.w      enemy_movement_actual_step(a0)

  ; not-moving enemy
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

  clr.b      enemy_bools(a0)
  bset       #EnemyActive,enemy_bools(a0)
  lea.l      orange_face_descriptor(pc),a1
  move.l     a1,enemy_descriptor(a0)
  clr.w      enemy_anim_step(a0)
  clr.w      enemy_anim_delay(a0)

  clr.l      enemy_movement(a0)
  clr.w      enemy_movement_max_step(a0)
  clr.w      enemy_movement_actual_step(a0)

  rts

  xdef       enemies_update_pos_and_state
enemies_update_pos_and_state:
  lea.l      ig_om_enemies(a4),a0
  moveq.l    #EnemyMaxCount-1,d7
.ups_loop:
  ; check active
  btst       #EnemyActive,enemy_bools(a0)
  beq.s      .ups_loop_next
  ; check movement
  tst.l      enemy_movement(a0)
  beq.s      .ups_loop_next
  ; move enemy
  move.w     enemy_movement_actual_step(a0),d0
  cmp.w      enemy_movement_max_step(a0),d0
  bne.s      .ups_loop_no_reset
  moveq.l    #0,d0
  move.w     d0,enemy_movement_actual_step(a0)
.ups_loop_no_reset:
  move.l     enemy_movement(a0),a1
  add.l      a4,a1
  lsl.w      #2,d0
  move.w     (a1,d0.w),d1
  move.w     2(a1,d0.w),d2
  add.w      d1,b_xpos(a0)
  add.w      d2,b_ypos(a0)
  add.w      #1,enemy_movement_actual_step(a0)
  ; check still visible
  move.w     b_xpos(a0),d0
  cmp.w      #-TilePixelWidth-4,d0
  bge.s      .ups_loop_next
  bclr       #EnemyActive,enemy_bools(a0)
.ups_loop_next:  
  add.l      #enemy_size,a0
  dbf        d7,.ups_loop

  rts

  xdef       enemies_draw
enemies_draw:
  ; first: update anim step
  lea.l      ig_om_enemies(a4),a1
  moveq.l    #EnemyMaxCount-1,d7
.ua_loop:
  btst       #EnemyActive,enemy_bools(a1)
  beq.s      .ua_loop_next
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
  ; second: draw bobs
  lea.l      ig_om_enemies(a4),a1
  moveq.l    #EnemyMaxCount-1,d7
.de_loop:
  btst       #EnemyActive,enemy_bools(a1)
  beq.s      .de_loop_next
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
.de_loop_next:
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
