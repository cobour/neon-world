  section    BossCode,code
              
  include    "constants.i"

  xdef       boss_init
boss_init:
  ; end condition
  bclr       #IgBossDeathAnimOver,ig_om_bools(a4)
  lea.l      next_additional_death_explosion(pc),a0
  lea.l      additional_death_explosions(pc),a1
  move.l     a1,(a0)

  ; enemy struct
  lea.l      ig_om_boss(a4),a0
  moveq.l    #0,d0
  moveq.l    #1,d1
  move.l     d0,b_bools(a0)
  move.b     d0,enemy_bools(a0)
  move.b     d0,b_draw_hit_frames(a0)
  move.l     d0,b_eol_frame(a0)
  move.l     d1,b_b_0+bb_bltptr(a0)
  move.l     d1,b_b_1+bb_bltptr(a0)
  move.w     #TilePixelWidth*2,b_width(a0)
  move.w     #TilePixelHeight*2,b_height(a0)
  lea.l      enemy_descriptors_index,a1
  move.w     #28*4,d0
  move.l     (a1,d0.w),enemy_descriptor(a0)

  ; bob structs
  lea.l      normal_tile_offsets(pc),a2
  lea.l      boss_bob_left_upper(a0),a1
  bsr.s      .init_bob_struct
  lea.l      boss_bob_right_upper(a0),a1
  bsr.s      .init_bob_struct
  lea.l      boss_bob_left_lower(a0),a1
  bsr.s      .init_bob_struct
  lea.l      boss_bob_right_lower(a0),a1
  ; fall-through
.init_bob_struct:
  moveq.l    #0,d0
  moveq.l    #1,d1
  ; reset all flags -> deactivates bob-struct embedded in enemy-struct
  move.b     d0,b_bools(a1)
  move.b     d0,b_draw_hit_frames(a1)
  ; set necessary defaults
  move.w     #TilePixelWidth,b_width(a1)
  move.w     #TilePixelHeight,b_height(a1)
  move.l     d0,b_eol_frame(a1)
  move.l     d1,b_b_0+bb_bltptr(a1)
  move.l     d1,b_b_1+bb_bltptr(a1)
  move.l     (a2)+,b_tiles_offset(a1)
  rts

  xdef       boss_spawn
boss_spawn:
  move.l     ig_om_frame_counter(a4),d0
  cmp.l      #f003_dat_level1_tmx_boss_spawn_frame,d0
  beq.s      .do_spawn
  rts
.do_spawn:
  lea.l      ig_om_boss(a4),a0
  move.l     enemy_descriptor(a0),a1
  move.w     ed_hit_points(a1),enemy_hit_points(a0)
  moveq.l    #0,d2
  move.b     d2,b_bools(a0)
  bset       #BobActive,b_bools(a0)
  bset       #BobCanCollide,b_bools(a0)
  move.b     d2,enemy_bools(a0)
  bset       #EnemyActive,enemy_bools(a0)
  bset       #EnemyIsBoss,enemy_bools(a0)

  move.w     #f003_dat_level1_tmx_boss_xpos,d0
  moveq.l    #f003_dat_level1_tmx_boss_ypos,d1
  move.w     d0,b_xpos(a0)
  move.w     d1,b_ypos(a0)

  lea.l      boss_bob_left_upper(a0),a1
  move.w     d0,b_xpos(a1)
  move.w     d1,b_ypos(a1)
  move.b     d2,b_bools(a1)
  bset       #BobActive,b_bools(a1)
  lea.l      boss_bob_right_upper(a0),a1
  move.w     d0,b_xpos(a1)
  add.w      #16,b_xpos(a1)
  move.w     d1,b_ypos(a1)
  move.b     d2,b_bools(a1)
  bset       #BobActive,b_bools(a1)
  lea.l      boss_bob_left_lower(a0),a1
  move.w     d0,b_xpos(a1)
  move.w     d1,b_ypos(a1)
  add.w      #16,b_ypos(a1)
  move.b     d2,b_bools(a1)
  bset       #BobActive,b_bools(a1)
  lea.l      boss_bob_right_lower(a0),a1
  move.w     d0,b_xpos(a1)
  move.w     d1,b_ypos(a1)
  add.w      #16,b_xpos(a1)
  add.w      #16,b_ypos(a1)
  move.b     d2,b_bools(a1)
  bset       #BobActive,b_bools(a1)

  rts

  xdef       boss_update_pos_and_state
boss_update_pos_and_state:
  lea.l      ig_om_boss(a4),a0
  btst       #EnemyActive,enemy_bools(a0)
  beq        .exit

  btst       #BobCanCollide,b_bools(a0)
  beq        .no_movement                                                                               ; boss has died

  btst       #IgPerformScroll,ig_om_bools(a4)
  beq.s      .no_scroll_pos_update

  moveq.l    #-1,d0
  moveq.l    #0,d1
  bsr        .pos_update

.no_scroll_pos_update:
  move.w     b_xpos(a0),d2
  move.w     b_ypos(a0),d3
  add.w      #TilePixelHeight,d3                                                                        ; middle
  move.w     ig_om_player+pl_ypos(a4),d4
  add.w      #TilePixelHeight/2,d4                                                                      ; middle
  sub.w      #ScreenStartY,d4
  lea.l      .shot_movement(pc),a1
  move.w     d3,d5
  sub.w      d4,d5
  cmp.w      #16,d5
  bgt.s      .boss_shot_up
  cmp.w      #-16,d6
  blt.s      .boss_shot_down
  move.w     #BossShotMovementStrDesc,(a1)
  bra.s      .0
.boss_shot_up:
  move.w     #BossShotMovementUpDesc,(a1)
  bra.s      .0
.boss_shot_down:
  move.w     #BossShotMovementDownDesc,(a1)
.0:
  lea.l      .xadd(pc),a1
  lea.l      .yadd(pc),a2
  lea.l      .stay_back_timer(pc),a3

; xpos
  cmp.w      #6,d2
  bgt.s      .1
  moveq.l    #2,d0
  move.w     d0,(a1)
  move.w     #25,(a3)
  bra.s      .2
.1:
  cmp.w      #268,d2
  blt.s      .2
  tst.w      (a3)
  beq.s      .1a
  move.w     (a3),d0
  sub.w      #1,d0
  move.w     d0,(a3)
  clr.w      (a1)
  bra.s      .2
.1a:
  moveq.l    #-4,d0
  clr.w      (a2)
  move.w     d0,(a1)

; ypos
.2:
  tst.w      (a1)
  blt.s      .3

  move.l     ig_om_frame_counter(a4),d5
  and.l      #$0000000f,d5
  tst.b      d5
  bne.s      .3

  cmp.w      d4,d3
  blt.s      .2a
  move.w     #-1,(a2)
  bra.s      .3
.2a:  
  move.w     #1,(a2)

.3:
  move.w     (a1),d0
  move.w     (a2),d1
  bsr        .pos_update

; check ypos boundaries
  move.w     b_ypos(a0),d0
  move.w     #$3c,d1                                                                                    ; dec = 60
  cmp.w      d1,d0
  bge.s      .4
  move.w     d1,b_ypos(a0)
  clr.w      .yadd
.4:
  move.w     #$be,d1                                                                                    ; dec = 190
  cmp.w      d1,d0
  ble.s      .5
  move.w     d1,b_ypos(a0)
  clr.w      .yadd
.5:

; let boss shoot (if not moving to the left)
  move.w     .xadd(pc),d0
  tst.w      d0
  blt.s      .no_movement
  lea.l      .shot_delay(pc),a2
  tst.w      (a2)
  beq.s      .new_shot
  sub.w      #1,(a2)
  bra.s      .no_movement
.new_shot:
  move.w     #BossShotDelay,(a2)
  move.w     b_xpos(a0),d0
  move.w     b_ypos(a0),d1
  add.w      #TilePixelHeight,d1
  moveq.l    #BossShotEnemyDesc,d2
  move.w     .shot_movement(pc),d3
  moveq.l    #0,d4
  move.l     a0,a3
  jsr        spawn_new_enemy
  move.l     a3,a0

.no_movement:
  move.w     enemy_hit_points(a0),d0
  tst.w      d0
  bgt.s      .exit

  lea.l      ig_om_enemy_explosion(a4),a2
  btst       #BobActive,b_bools(a2)
  bne.s      .exit
  move.l     next_additional_death_explosion(pc),a1
  move.l     (a1)+,d2
  tst.l      d2
  bne.s      .sae1
  bset       #IgBossDeathAnimOver,ig_om_bools(a4)
  bra.s      .exit
.sae1:
  move.l     a1,next_additional_death_explosion
  ; play sample
  move.l     a0,a1
  jsr        sfx_explosion
  move.l     a1,a0
  ; spawn enemy explosion (special bob, no collision detection, only one at a time)
  bset       #BobActive,b_bools(a2)
  moveq.l    #0,d1
  move.l     d1,b_eol_frame(a2)
  move.w     d1,exp_anim_count(a2)                                                                      ; includes exp_anim_count_delay
  ; do NOT reset bb_bltptr's since explosion may be reused while playing anim
  move.w     b_xpos(a0),b_xpos(a2)
  move.w     b_ypos(a0),b_ypos(a2)
  add.w      d2,b_ypos(a2)
  swap       d2
  add.w      d2,b_xpos(a2)

.exit:
  rts

.xadd:  
  dc.w       -4
.yadd:
  dc.w       0
.stay_back_timer:
  dc.w       0
.shot_delay:
  dc.w       0
.shot_movement:
  dc.w       0

; d0 - add xpos
; d1 - add ypos
; a0 - boss struct
.pos_update:
  add.w      d0,b_xpos(a0)
  add.w      d1,b_ypos(a0)
  lea.l      boss_bob_left_upper(a0),a1
  add.w      d0,b_xpos(a1)
  add.w      d1,b_ypos(a1)
  lea.l      boss_bob_right_upper(a0),a1
  add.w      d0,b_xpos(a1)
  add.w      d1,b_ypos(a1)
  lea.l      boss_bob_left_lower(a0),a1
  add.w      d0,b_xpos(a1)
  add.w      d1,b_ypos(a1)
  lea.l      boss_bob_right_lower(a0),a1
  add.w      d0,b_xpos(a1)
  add.w      d1,b_ypos(a1)
  rts

additional_death_explosions:
  dc.w       4,12
  dc.w       20,14
  dc.w       12,16
  dc.l       0

next_additional_death_explosion:
  dc.l       0

  xdef       boss_draw
boss_draw:
  lea.l      ig_om_boss(a4),a0
  btst       #EnemyActive,enemy_bools(a0)
  beq.s      .exit

  ; draw hit frame?
  tst.b      b_draw_hit_frames(a0)
  beq.s      .draw_normal_tiles
  lea.l      hit_tile_offsets(pc),a3
  sub.b      #1,b_draw_hit_frames(a0)
  bra.s      .draw_bobs
.draw_normal_tiles:
  lea.l      normal_tile_offsets(pc),a3
.draw_bobs:
  lea.l      boss_bob_left_upper(a0),a1
  move.l     (a3)+,b_tiles_offset(a1)
  move.l     ig_om_frame_counter(a4),d0
  jsr        bob_draw
  lea.l      ig_om_boss(a4),a0
  lea.l      boss_bob_right_upper(a0),a1
  move.l     (a3)+,b_tiles_offset(a1)
  move.l     ig_om_frame_counter(a4),d0
  jsr        bob_draw
  lea.l      ig_om_boss(a4),a0
  lea.l      boss_bob_left_lower(a0),a1
  move.l     (a3)+,b_tiles_offset(a1)
  move.l     ig_om_frame_counter(a4),d0
  jsr        bob_draw
  lea.l      ig_om_boss(a4),a0
  lea.l      boss_bob_right_lower(a0),a1
  move.l     (a3)+,b_tiles_offset(a1)
  move.l     ig_om_frame_counter(a4),d0
  jsr        bob_draw

.exit:
  rts

normal_tile_offsets:
  dc.l       (10*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+36
  dc.l       (10*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+38
  dc.l       (11*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+36
  dc.l       (11*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+38
hit_tile_offsets: ; FIXME: hit frames are one pixel-line above where they should be, so subtract that line
  dc.l       (12*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+36-(TilesWidthBytes*TilesBitplanes)
  dc.l       (12*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+38-(TilesWidthBytes*TilesBitplanes)
  dc.l       (13*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+36-(TilesWidthBytes*TilesBitplanes)
  dc.l       (13*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+38-(TilesWidthBytes*TilesBitplanes)
