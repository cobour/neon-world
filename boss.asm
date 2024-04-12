  section    BossCode,code
              
  include    "constants.i"

; DONE boss has one enemy structure (with embedded bob structure) which is only used for collision detection
; DONE      enemy struct is not added to normal enemies list => no accidental restore or draw operations
; DONE      collision detection performed against normal enemies list OR boss => if boss is active against boss, otherwise against enemies list
; DONE      change gfx when hit (not using mask like for normal enemies)
; DONE      when boss dies, set IgBossDeathAnimOver so level can end
; DONE boss has four bob structures (used for drawing/restoring)
; DONE get spawn position from level file
; DONE boss does not have predefined movement, but moves with small assembler routine (can react to position of player)
;      better boss movement (react to position of player)
;      boss does shoot, shots are normal enemies with predefined movement
;      when boss dies, play multiple explosions and sounds => halt fade out of level for the time (IgBossDeathAnimOver)

  xdef       boss_init
boss_init:
  ; end condition
  bclr       #IgBossDeathAnimOver,ig_om_bools(a4)

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

  move.w     #322,d0
  moveq.l    #100,d1
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
  beq.s      .exit

  btst       #BobCanCollide,b_bools(a0)
  beq.s      .no_movement                                                                               ; boss has died

  btst       #IgPerformScroll,ig_om_bools(a4)
  beq.s      .no_scroll_pos_update

  moveq.l    #-1,d0
  moveq.l    #0,d1
  bsr.s      .pos_update

.no_scroll_pos_update:
  move.w     b_xpos(a0),d2
  cmp.w      #200,d2
  bgt.s      .check_right
  move.w     #1,.dummy_x_add
  move.w     #0,.dummy_y_add
.check_right:
  cmp.w      #270,d2
  blt.s      .apply_movement
  move.w     #-1,.dummy_x_add
  move.w     #0,.dummy_y_add
.apply_movement:
  move.w     .dummy_x_add,d0
  move.w     .dummy_y_add,d1
  bsr.s      .pos_update

.no_movement:
  move.w     enemy_hit_points(a0),d0
  tst.w      d0
  bgt.s      .exit
  bset       #IgBossDeathAnimOver,ig_om_bools(a4)
.exit:
  rts

.dummy_x_add:
  dc.w       -1
.dummy_y_add:
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
