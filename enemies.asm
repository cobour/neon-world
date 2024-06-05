  section    EnemiesCode,code
              
  include    "constants.i"

  xdef       enemies_init
enemies_init:

  ; init values for object descriptors
  lea.l      ig_om_f003+f003_dat_level1_tmx_objects(a4),a0
  add.l      #f003_dat_level1_tmx_objects_size,a0
  move.l     a0,ig_om_end_object_desc(a4)
  jsr        level_warp_enemies

  ; init enemy descriptor index
  lea.l      enemy_descriptors_index(pc),a0
  lea.l      first_enemy_descriptor(pc),a1
  moveq.l    #EnemyDescCount-1,d7
.ei_enemy_loop:
  move.l     a1,(a0)+
  add.l      #ed_size,a1
  dbf        d7,.ei_enemy_loop

  ; init movement descriptor index
  lea.l      movement_descriptors_index(pc),a0
  lea.l      first_movement_descriptor(pc),a1
  moveq.l    #MovementDescCount-1,d7
.ei_movement_loop:
  move.l     a1,(a0)+
  add.l      #mvd_size,a1
  dbf        d7,.ei_movement_loop

  ; clear all enemy structs
  lea.l      ig_om_enemies(a4),a0
  moveq.l    #0,d0
  moveq.l    #1,d1
  moveq.l    #EnemyMaxCount-1,d7
.ei_struct_loop:
  ; reset all flags -> deactivates enemy and its bob
  move.b     d0,b_bools(a0)
  move.b     d0,b_draw_hit_frames(a0)
  move.b     d0,enemy_bools(a0)
  ; set necessary defaults
  move.l     d0,b_eol_frame(a0)
  move.l     d1,b_b_0+bb_bltptr(a0)
  move.l     d1,b_b_1+bb_bltptr(a0)
  ; next
  add.l      #enemy_size,a0
  dbf        d7,.ei_struct_loop

  ; init enemy explosion
  lea.l      ig_om_enemy_explosion(a4),a0
  moveq.l    #1,d0
  move.l     d0,b_b_0+bb_bltptr(a0)
  move.l     d0,b_b_1+bb_bltptr(a0)
  move.w     #TilePixelWidth,b_width(a0)
  move.w     #TilePixelHeight,b_height(a0)
  move.l     a4,d0
  add.l      #ig_om_f003+f003_dat_explosion_anim_tmx,d0
  move.l     d0,exp_anim_step_ptr(a0)
  moveq.l    #0,d0
  move.b     d0,b_bools(a0)
  move.b     d0,b_draw_hit_frames(a0)
  move.b     d0,exp_anim_count(a0)

  rts

  xdef       enemies_spawn
enemies_spawn:
  move.l     ig_om_next_object_desc(a4),a2
.es_loop:
  ; check if any remaining object descriptors to process
  cmp.l      ig_om_end_object_desc(a4),a2
  beq.s      .es_exit

  ; check if frame count is reached
  move.l     ig_om_frame_counter(a4),d0
  cmp.l      obj_spawn_frame(a2),d0
  blt.s      .es_exit

  ; spawn new enemy
  move.w     obj_xpos(a2),d0
  move.w     obj_ypos(a2),d1
  move.w     obj_enemy_desc(a2),d2
  move.w     obj_enemy_movement_desc(a2),d3
  move.w     obj_start_offset_movement(a2),d4
  move.w     obj_start_offset_anim(a2),d5
  bsr.s      spawn_new_enemy
  
  ; maybe more than one enemy must be spawned in this frame
  add.l      #obj_size,a2
  bra.s      .es_loop
.es_exit:
  ; save pointer (may have been incremented)
  move.l     a2,ig_om_next_object_desc(a4)

  rts

; in:
; d0 - xpos
; d1 - ypos
; d2 - number of enemy descriptor (starting with zero)
; d3 - number of movement descriptor (starting with zero)
; d4 - start offset for movement (steps)
; d5 - start offset for anim
;
; uses:
; d6-d7,a1
;
; out:
; a0 - pointer to enemy struct or zero, if no free enemy slot was available
  xdef       spawn_new_enemy
spawn_new_enemy:
  ; first: search for free slot
  moveq.l    #EnemyMaxCount-1,d7
  lea.l      ig_om_enemies(a4),a0
.find_loop:
  btst       #BobActive,b_bools(a0)
  bne.s      .fl_next
  btst       #EnemyActive,enemy_bools(a0)
  bne.s      .fl_next
  ; empty slot found, a0 is set
  bra.s      .init
.fl_next:
  add.l      #enemy_size,a0
  dbf        d7,.find_loop
  ; no free slot found, clear a0 and exit
  sub.l      a0,a0
  rts

.init:
  ; second: initialize enemy struct
  moveq.l    #1,d6
  move.l     d6,b_b_0+bb_bltptr(a0)
  move.l     d6,b_b_1+bb_bltptr(a0)

  moveq.l    #0,d6
  move.b     d6,b_bools(a0)
  bset       #BobActive,b_bools(a0)
  bset       #BobCanCollide,b_bools(a0)
  move.l     d6,b_eol_frame(a0)
  move.w     d0,b_xpos(a0)
  move.w     d1,b_ypos(a0)
  move.w     #TilePixelWidth,b_width(a0)
  move.w     #TilePixelHeight,b_height(a0)

  move.b     d6,enemy_bools(a0)
  bset       #EnemyActive,enemy_bools(a0)

  lea.l      enemy_descriptors_index(pc),a1
  lsl.w      #2,d2
  move.l     (a1,d2.w),a1

  tst.l      ed_coldet_x2(a1)
  bne.s      .can_die
  ; x2,y2 of bounding box are zero => enemy can not die when shot
  bclr       #BobCanCollide,b_bools(a0)
  bset       #BobAnimatedBackground,b_bools(a0)
  move.b     ed_coldet_x1+1(a1),enemy_drawing_layer(a0)
.can_die:

  move.w     ed_hit_points(a1),enemy_hit_points(a0)
  move.l     a1,enemy_descriptor(a0)
  move.w     d5,enemy_anim_step(a0)
  move.w     d6,enemy_anim_delay(a0)

  lea.l      movement_descriptors_index(pc),a1
  lsl.w      #2,d3
  move.l     (a1,d3.w),a1
  move.l     (a1)+,enemy_movement(a0)
  move.w     (a1)+,enemy_movement_max_step(a0)
  move.w     d4,enemy_movement_actual_step(a0)

  rts

  xdef       enemies_update_pos_and_state
enemies_update_pos_and_state:
  lea.l      ig_om_enemies(a4),a0
  moveq.l    #EnemyMaxCount-1,d7
.ups_loop:
  ; check active
  btst       #EnemyActive,enemy_bools(a0)
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
  ; check still visible (top of screen)
  move.w     b_ypos(a0),d0
  cmp.w      #-TilePixelWidth-4,d0
  blt.s      .ups_deactivate_enemy
  ; check still visible (bottom of screen)
  cmp.w      #ScreenHeight+4,d0
  bgt.s      .ups_deactivate_enemy
  ; check still visible (right of screen)
  move.w     b_xpos(a0),d0
  cmp.w      #ScreenWidth+4,d0
  bgt.s      .ups_deactivate_enemy
  ; check still visible (left of screen)
  cmp.w      #-TilePixelWidth-4,d0
  bge.s      .ups_loop_next
  ; enemy has left visible playarea => deactivate
.ups_deactivate_enemy:
  bclr       #EnemyActive,enemy_bools(a0)
  move.l     ig_om_frame_counter(a4),d0
  addq.l     #2,d0
  move.l     d0,b_eol_frame(a0)
  bclr       #BobCanCollide,b_bools(a0)
.ups_loop_next:  
  add.l      #enemy_size,a0
  dbf        d7,.ups_loop

  rts

  xdef       background_enemies_draw
background_enemies_draw:
  ; first: update anim step
  lea.l      ig_om_enemies(a4),a1
  moveq.l    #EnemyMaxCount-1,d7
.ua_loop:
  btst       #BobAnimatedBackground,b_bools(a1)
  beq.s      .ua_loop_next
  btst       #EnemyActive,enemy_bools(a1)
  beq.s      .ua_loop_next
  bsr        ed_update_anim_step
.ua_loop_next:  
  add.l      #enemy_size,a1
  dbf        d7,.ua_loop

.draw_enemies:
  ; second: draw bobs - lower
  lea.l      ig_om_enemies(a4),a1
  moveq.l    #EnemyMaxCount-1,d7
.del_loop:
  btst       #BobAnimatedBackground,b_bools(a1)
  beq.s      .del_loop_next
  btst       #EnemyActive,enemy_bools(a1)
  beq.s      .del_loop_next
  tst.b      enemy_drawing_layer(a1)
  bne.s      .del_loop_next
  bsr        ed_draw_bob
.del_loop_next:
  add.l      #enemy_size,a1
  dbf        d7,.del_loop
  ; second: draw bobs - upper
  lea.l      ig_om_enemies(a4),a1
  moveq.l    #EnemyMaxCount-1,d7
.deu_loop:
  btst       #BobAnimatedBackground,b_bools(a1)
  beq.s      .deu_loop_next
  btst       #EnemyActive,enemy_bools(a1)
  beq.s      .deu_loop_next
  tst.b      enemy_drawing_layer(a1)
  beq.s      .deu_loop_next
  bsr        ed_draw_bob
.deu_loop_next:
  add.l      #enemy_size,a1
  dbf        d7,.deu_loop
  rts

  xdef       enemies_draw
enemies_draw:
  ; first: update anim step
  lea.l      ig_om_enemies(a4),a1
  moveq.l    #EnemyMaxCount-1,d7
.ua_loop:
  btst       #EnemyActive,enemy_bools(a1)
  beq.s      .ua_loop_next
  btst       #BobAnimatedBackground,b_bools(a1)
  bne.s      .ua_loop_next
  bsr        ed_update_anim_step
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
  btst       #BobAnimatedBackground,b_bools(a1)
  bne.s      .de_loop_next
  bsr        ed_draw_bob
.de_loop_next:
  add.l      #enemy_size,a1
  dbf        d7,.de_loop

  ;
  ; draw enemy-explosion
  ;
  lea.l      ig_om_enemy_explosion(a4),a1
  btst       #BobActive,b_bools(a1)
  beq.s      .exit

  cmp.b      #ExpMaxAnimCount,exp_anim_count(a1)
  bne.s      .ene_update_anim_count

  ; anim ended
  ; check if eol already set
  tst.l      b_eol_frame(a1)
  bne.s      .exit
  ; set eol
  move.l     ig_om_frame_counter(a4),d0
  addq.l     #2,d0
  move.l     d0,b_eol_frame(a1)
  bra.s      .exit

.ene_update_anim_count:
  moveq.l    #0,d0
  moveq.l    #1,d1
  add.b      d1,exp_anim_count_delay(a1)
  cmp.b      #ExpAnimStepChange,exp_anim_count_delay(a1)
  bne.s      .ene_no_anim_frame_update
  add.b      d1,exp_anim_count(a1)
  move.b     d0,exp_anim_count_delay(a1)
.ene_no_anim_frame_update:
  move.b     exp_anim_count(a1),d0
  add.w      d0,d0
  move.l     exp_anim_step_ptr(a1),a0
  move.w     (a0,d0.w),d0
  move.l     d0,b_tiles_offset(a1)
  
  move.l     ig_om_frame_counter(a4),d0
  jsr        bob_draw

.exit:
  rts

ed_update_anim_step:
  ; check anim delay
  move.l     enemy_descriptor(a1),a2
  move.w     enemy_anim_delay(a1),d0
  add.w      #1,d0
  cmp.w      ed_anim_delay(a2),d0
  beq.s      .ua_anim_frame_update
  move.w     d0,enemy_anim_delay(a1)
  rts
.ua_anim_frame_update:
  clr.w      enemy_anim_delay(a1)

  ; check and set next anim step
  move.w     enemy_anim_step(a1),d0
  add.w      #1,d0
  cmp.w      ed_anim_steps(a2),d0
  bne.s      .ua_next_anim_frame
  ; reset to first anim frame
  clr.w      enemy_anim_step(a1)
  rts
.ua_next_anim_frame:
  ; set next anim step
  move.w     d0,enemy_anim_step(a1)
  rts

ed_draw_bob:
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
  jmp        bob_draw

; enemy descriptors and index
EnemyDescCount    equ 30
  xdef       enemy_descriptors_index
enemy_descriptors_index:
  dcb.l      EnemyDescCount
; see constants.i -> ed_*
first_enemy_descriptor:
  ; 0
  dc.l       ig_om_f003+f003_dat_green_face_red_eye_anim_tmx
  dc.w       f003_dat_green_face_red_eye_anim_tmx_tiles_width
  dc.w       3
  dc.w       $0030
  dc.w       1
  dc.w       0,0,15,15
  ; 1
  dc.l       ig_om_f003+f003_dat_orange_face_anim_tmx
  dc.w       f003_dat_orange_face_anim_tmx_tiles_width
  dc.w       2
  dc.w       $0025
  dc.w       1
  dc.w       0,0,15,15
  ; 2
  dc.l       ig_om_f003+f003_dat_green_face_anim_tmx
  dc.w       f003_dat_green_face_anim_tmx_tiles_width
  dc.w       2
  dc.w       $0025
  dc.w       1
  dc.w       0,0,15,15
  ; 3
  dc.l       ig_om_f003+f003_dat_blue_robot_anim_tmx
  dc.w       f003_dat_blue_robot_anim_tmx_tiles_width
  dc.w       5
  dc.w       $0045
  dc.w       2
  dc.w       0,0,15,15
  ; 4
  dc.l       ig_om_f003+f003_dat_green_rocket_anim_tmx
  dc.w       f003_dat_green_rocket_anim_tmx_tiles_width
  dc.w       2
  dc.w       $0020
  dc.w       1
  dc.w       0,0,12,12
  ; 5
  dc.l       ig_om_f003+f003_dat_green_robot_anim_tmx
  dc.w       f003_dat_green_robot_anim_tmx_tiles_width
  dc.w       5
  dc.w       $0025
  dc.w       1
  dc.w       0,0,15,15
  ; 6
  dc.l       ig_om_f003+f003_dat_blue_barrier_upper_anim_tmx
  dc.w       f003_dat_blue_barrier_upper_anim_tmx_tiles_width
  dc.w       60
  dc.w       $0000
  dc.w       0
  dc.w       1,0,0,0
  ; 7
  dc.l       ig_om_f003+f003_dat_blue_barrier_lower_anim_tmx
  dc.w       f003_dat_blue_barrier_lower_anim_tmx_tiles_width
  dc.w       60
  dc.w       $0000
  dc.w       0
  dc.w       1,0,0,0
  ; 8
  dc.l       ig_om_f003+f003_dat_blue_lightning_upper_anim_tmx
  dc.w       f003_dat_blue_lightning_upper_anim_tmx_tiles_width
  dc.w       12
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 9
  dc.l       ig_om_f003+f003_dat_blue_lightning_middle_anim_tmx
  dc.w       f003_dat_blue_lightning_middle_anim_tmx_tiles_width
  dc.w       12
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 10
  dc.l       ig_om_f003+f003_dat_blue_lightning_lower_anim_tmx
  dc.w       f003_dat_blue_lightning_lower_anim_tmx_tiles_width
  dc.w       12
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 11
  dc.l       ig_om_f003+f003_dat_fire_down_upper_anim_tmx
  dc.w       f003_dat_fire_down_upper_anim_tmx_tiles_width
  dc.w       8
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 12
  dc.l       ig_om_f003+f003_dat_fire_down_middle_upper_anim_tmx
  dc.w       f003_dat_fire_down_middle_upper_anim_tmx_tiles_width
  dc.w       8
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 13
  dc.l       ig_om_f003+f003_dat_fire_down_middle_lower_anim_tmx
  dc.w       f003_dat_fire_down_middle_lower_anim_tmx_tiles_width
  dc.w       8
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 14
  dc.l       ig_om_f003+f003_dat_fire_down_lower_anim_tmx
  dc.w       f003_dat_fire_down_lower_anim_tmx_tiles_width
  dc.w       8
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 15
  dc.l       ig_om_f003+f003_dat_fire_right_left_anim_tmx
  dc.w       f003_dat_fire_right_left_anim_tmx_tiles_width
  dc.w       8                                                        ; do not change (or resync with fire right/left anims)
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 16
  dc.l       ig_om_f003+f003_dat_fire_right_middle_left_anim_tmx
  dc.w       f003_dat_fire_right_middle_left_anim_tmx_tiles_width
  dc.w       8                                                        ; do not change (or resync with fire right/left anims)
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 17
  dc.l       ig_om_f003+f003_dat_fire_right_middle_right_anim_tmx
  dc.w       f003_dat_fire_right_middle_right_anim_tmx_tiles_width
  dc.w       8                                                        ; do not change (or resync with fire right/left anims)
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 18
  dc.l       ig_om_f003+f003_dat_fire_right_right_anim_tmx
  dc.w       f003_dat_fire_right_right_anim_tmx_tiles_width
  dc.w       8                                                        ; do not change (or resync with fire right/left anims)
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 19
  dc.l       ig_om_f003+f003_dat_fire_left_left_anim_tmx
  dc.w       f003_dat_fire_left_left_anim_tmx_tiles_width
  dc.w       8                                                        ; do not change (or resync with fire right/left anims)
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 20
  dc.l       ig_om_f003+f003_dat_fire_left_middle_left_anim_tmx
  dc.w       f003_dat_fire_left_middle_left_anim_tmx_tiles_width
  dc.w       8                                                        ; do not change (or resync with fire right/left anims)
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 21
  dc.l       ig_om_f003+f003_dat_fire_left_middle_right_anim_tmx
  dc.w       f003_dat_fire_left_middle_right_anim_tmx_tiles_width
  dc.w       8                                                        ; do not change (or resync with fire right/left anims)
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 22
  dc.l       ig_om_f003+f003_dat_fire_left_right_anim_tmx
  dc.w       f003_dat_fire_left_right_anim_tmx_tiles_width
  dc.w       8                                                        ; do not change (or resync with fire right/left anims)
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 23
  dc.l       ig_om_f003+f003_dat_fire_up_upper_anim_tmx
  dc.w       f003_dat_fire_up_upper_anim_tmx_tiles_width
  dc.w       8
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 24
  dc.l       ig_om_f003+f003_dat_fire_up_middle_upper_anim_tmx
  dc.w       f003_dat_fire_up_middle_upper_anim_tmx_tiles_width
  dc.w       8
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 25
  dc.l       ig_om_f003+f003_dat_fire_up_middle_lower_anim_tmx
  dc.w       f003_dat_fire_up_middle_lower_anim_tmx_tiles_width
  dc.w       8
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 26
  dc.l       ig_om_f003+f003_dat_fire_up_lower_anim_tmx
  dc.w       f003_dat_fire_up_lower_anim_tmx_tiles_width
  dc.w       8
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0
  ; 27
  dc.l       ig_om_f003+f003_dat_red_drop_anim_tmx
  dc.w       f003_dat_red_drop_anim_tmx_tiles_width
  dc.w       4
  dc.w       $0015
  dc.w       1
  dc.w       0,2,15,13
  ; 28 BOSS
  dc.l       0                                                        ; no anim
  dc.w       0                                                        ; no anim
  dc.w       0                                                        ; no anim
  dc.w       $0250
  dc.w       80
  dc.w       4,4,30,29
  ; 29 BOSS SHOTS
  dc.l       ig_om_f003+f003_dat_boss_shot_anim_tmx
  dc.w       f003_dat_boss_shot_anim_tmx_tiles_width
  dc.w       6
  dc.w       $0000
  dc.w       0
  dc.w       0,0,0,0

; movement descriptors and index
MovementDescCount equ 13
movement_descriptors_index:
  dcb.l      MovementDescCount
; see constants.i -> mvd_*
first_movement_descriptor:
  ; 0
  dc.l       ig_om_f003+f003_dat_speed_up_ods
  dc.w       f003_dat_speed_up_ods_steps
  ; 1
  dc.l       ig_om_f003+f003_dat_just_scroll_ods
  dc.w       f003_dat_just_scroll_ods_steps
  ; 2
  dc.l       ig_om_f003+f003_dat_down_then_left_ods
  dc.w       f003_dat_down_then_left_ods_steps
  ; 3
  dc.l       ig_om_f003+f003_dat_left_down_left_ods
  dc.w       f003_dat_left_down_left_ods_steps
  ; 4
  dc.l       ig_om_f003+f003_dat_up_ods
  dc.w       f003_dat_up_ods_steps
  ; 5
  dc.l       ig_om_f003+f003_dat_little_down_little_up_ods
  dc.w       f003_dat_little_down_little_up_ods_steps
  ; 6
  dc.l       ig_om_f003+f003_dat_speed_up_2_ods
  dc.w       f003_dat_speed_up_2_ods_steps
  ; 7
  dc.l       ig_om_f003+f003_dat_wave_ods
  dc.w       f003_dat_wave_ods_steps
  ; 8
  dc.l       ig_om_f003+f003_dat_jellyfish_ods
  dc.w       f003_dat_jellyfish_ods_steps
  ; 9
  dc.l       ig_om_f003+f003_dat_boss_shot_straight_ods
  dc.w       f003_dat_boss_shot_straight_ods_steps
  ; 10
  dc.l       ig_om_f003+f003_dat_boss_shot_up_ods
  dc.w       f003_dat_boss_shot_up_ods_steps
  ; 11
  dc.l       ig_om_f003+f003_dat_boss_shot_down_ods
  dc.w       f003_dat_boss_shot_down_ods_steps
  ; 12
  dc.l       ig_om_f003+f003_dat_left_down_stairs_ods
  dc.w       f003_dat_left_down_left_ods_steps
