  section    EnemiesCode,code
              
  include    "constants.i"

  xdef       enemies_init
enemies_init:

  ; init values for object descriptors
  lea.l      ig_om_f003+f003_dat_level1_tmx_objects(a4),a0
  move.l     a0,ig_om_next_object_desc(a4)
  add.l      #f003_dat_level1_tmx_objects_size,a0
  move.l     a0,ig_om_end_object_desc(a4)

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
;
; uses:
; d4-d5,d7,a1
;
; out:
; a0 - pointer to enemy struct or zero, if no free enemy slot was available
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
  moveq.l    #0,d4
  moveq.l    #1,d5

  move.b     d4,b_bools(a0)
  bset       #BobActive,b_bools(a0)
  bset       #BobCanCollide,b_bools(a0)
  move.l     d4,b_eol_frame(a0)
  move.w     d0,b_xpos(a0)
  move.w     d1,b_ypos(a0)
  move.w     #TilePixelWidth,b_width(a0)
  move.w     #TilePixelHeight,b_height(a0)
  move.l     d5,b_b_0+bb_bltptr(a0)
  move.l     d5,b_b_1+bb_bltptr(a0)

  move.b     d4,enemy_bools(a0)
  bset       #EnemyActive,enemy_bools(a0)

  lea.l      enemy_descriptors_index(pc),a1
  lsl.w      #2,d2
  move.l     (a1,d2.w),a1
  move.l     a1,enemy_descriptor(a0)
  move.w     d4,enemy_anim_step(a0)
  move.w     d4,enemy_anim_delay(a0)

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
  ; check still visible
  move.w     b_xpos(a0),d0
  cmp.w      #-TilePixelWidth-4,d0
  bge.s      .ups_loop_next
  bclr       #EnemyActive,enemy_bools(a0)
  move.l     ig_om_frame_counter(a4),d0
  addq.l     #2,d0
  move.l     d0,b_eol_frame(a0)
  bclr       #BobCanCollide,b_bools(a0)
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

  btst       #IgPerformScroll,ig_om_bools(a4)
  beq.s      .exit
  sub.w      #1,b_xpos(a1)

.exit:
  rts

; enemy descriptors and index
EnemyDescCount    equ 3
enemy_descriptors_index:
  dcb.l      EnemyDescCount
; see constants.i -> ed_*
first_enemy_descriptor:
  ; 0
  dc.l       ig_om_f003+f003_dat_green_face_red_eye_anim_tmx
  dc.w       f003_dat_green_face_red_eye_anim_tmx_tiles_width
  dc.w       3
  dc.w       $0030
  dc.w       0,0,15,15
  ; 1
  dc.l       ig_om_f003+f003_dat_orange_face_anim_tmx
  dc.w       f003_dat_orange_face_anim_tmx_tiles_width
  dc.w       2
  dc.w       $0025
  dc.w       0,0,15,15
  ; 2
  dc.l       ig_om_f003+f003_dat_green_face_anim_tmx
  dc.w       f003_dat_green_face_anim_tmx_tiles_width
  dc.w       2
  dc.w       $0025
  dc.w       0,0,15,15

; movement descriptors and index
MovementDescCount equ 3
movement_descriptors_index:
  dcb.l      MovementDescCount
; see constants.i -> mvd_*
first_movement_descriptor:
  ; 0
  dc.l       ig_om_f003+f003_dat_wave_ods
  dc.w       f003_dat_wave_ods_steps
  ; 1
  dc.l       ig_om_f003+f003_dat_just_scroll_ods
  dc.w       f003_dat_just_scroll_ods_steps
  ; 2
  dc.l       ig_om_f003+f003_dat_down_then_left_ods
  dc.w       f003_dat_down_then_left_ods_steps
