  section    LevelWarpCode,code
              
  include    "constants.i"

  xdef       level_warp_playfield
; sets all playfield-variables for the level to start at specific screen (where screen means every ScreenWidth chunk)
; MUST be called before pf_init
;
; is called before running level, so mulu is okay here
;
; in:
;   d0 - Number of screen of level (starting from zero) to warp to
level_warp_playfield:
; ig_om_frame_counter + ig_om_scroll_xpos
  move.l     d0,d1
  mulu       #ScreenWidth,d1
  move.l     d1,ig_om_frame_counter(a4)
  move.l     d1,ig_om_scroll_xpos(a4)

; ig_om_scroll_xpos_frbuf
  clr.w      ig_om_scroll_xpos_frbuf(a4)

; ig_om_bpl_offsets - set by pf_init.init_scroll_vars

; ig_om_next_tile_offset
  move.l     d0,d1
  mulu       #(20*16*2),d1                                    ; 20 columns per screen, 16 rows per column, one offset is 2 bytes wide
  add.l      #m_om_area+ig_om_f003+f003_dat_level1_tmx,d1     ; add base address of tile-offsets
  move.l     d1,ig_om_next_tile_offset(a4)

; ig_om_next_tile_col_left - set by pf_init.init_screen_buffer, dependant on ig_om_next_tile_offset

; ig_om_next_tile_col_right - set by pf_init.init_screen_buffer, dependant on ig_om_next_tile_offset

  rts

  xdef       level_warp_enemies
; sets all enemy-variables for the level to start at specific screen (where screen means every ScreenWidth chunk)
; MUST be called before enemies_init
level_warp_enemies:

; ig_om_next_object_desc
  lea.l      ig_om_f003+f003_dat_level1_tmx_objects(a4),a0
  move.l     ig_om_frame_counter(a4),d0
.next_object_desc_loop:
  cmp.l      obj_spawn_frame(a0),d0
  blt.s      .set_next_object_desc
  add.l      #obj_size,a0
  cmp.l      ig_om_end_object_desc(a4),a0
  bne.s      .next_object_desc_loop
.set_next_object_desc:
  move.l     a0,ig_om_next_object_desc(a4)

  rts
