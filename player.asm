  section    PlayerCode,code
  
  include    "constants.i"

  xdef       player_init
; a0 - pointer to copperlist where sprite pointers are set
; uses a1-a3,d0,d1,d7
player_init:
; init player-struct
  lea.l      ig_om_f003+f003_dat_player_anim_horizontal_tmx(a4),a1
  lea.l      ig_om_player(a4),a3
  move.w     #$00a0,d0
  move.w     d0,pl_xpos(a3)
  move.w     d0,pl_ypos(a3)
  move.l     a1,pl_anim(a3)
  moveq.l    #0,d0
  move.b     d0,pl_animstep(a3)
  move.w     d0,pl_no_col_det_frames(a3)
  move.b     #f003_dat_player_anim_horizontal_tmx_tiles_width,pl_max_animstep(a3)
  moveq.l    #1,d0
  move.w     d0,pl_weapon_strength(a3)
; calc gfx source pointer
  moveq.l    #0,d1
  move.w     (a1),d1
  lea.l      ig_cm_f002+f002_dat_tiles_iff(a5),a1
  add.l      d1,a1

; init chip-data
; sprite control words
  bsr.s      calc_control_words
  lea.l      ig_cm_player(a5),a2
  lea.l      ig_cm_player+72(a5),a3
  move.l     d0,(a2)+
  move.l     d0,(a3)+
; gfx data
  bsr.s      copy_animstep

; endstruct
  moveq.l    #0,d0
  move.l     d0,(a2)+
  move.l     d0,(a3)+

; write pointers to copperlist
  lea.l      ig_cm_player(a5),a1
  move.l     a1,d0
  move.w     d0,6(a0)
  swap       d0
  move.w     d0,2(a0)
  move.l     a1,d0
  add.l      #64+8,d0
  move.w     d0,14(a0)
  swap       d0
  move.w     d0,10(a0)

; set CLXCON and read CLXDAT once, so everything is cleared for first "real" collision detection
  move.w     #%0001111111111111,CLXCON(a6)
  move.w     CLXDAT(a6),d0

  rts

; a3 - pointer to player structure
; uses d1-d2
; returns d0 - SPRxPOS <<16 & SPRxCTL
calc_control_words:
; SPRxPOS
  move.w     pl_ypos(a3),d0
  move.w     d0,d2
  add.w      #TilePixelHeight,d2                                                      ; d2 = VSTOP
  lsl.l      #8,d0
  move.w     pl_xpos(a3),d1
  lsr.w      #1,d1
  add.w      d1,d0
; SPRxCTL
  move.w     d2,d1
  lsl.w      #8,d1
  bset       #7,d1
  lsr.w      #8,d2
  btst       #0,d2
  beq.s      .1
  bset       #1,d1
.1:
  move.w     pl_ypos(a3),d2
  lsr.w      #8,d2
  btst       #0,d2
  beq.s      .2
  bset       #2,d1
.2:
  move.w     pl_xpos(a3),d2
  btst       #0,d2
  beq.s      .3
  bset       #0,d1
.3:
  swap       d0
  move.w     d1,d0
  rts

; a1 - src pointer
; a2 - sprite 0 structure (gfx data)
; a3 - sprite 1 structure (gfx data)
; uses d0,d7
copy_animstep:
  move.l     #TilesWidthBytes,d0
  moveq.l    #TilePixelHeight-1,d7
.loop:
  move.w     (a1),(a2)+
  add.l      d0,a1
  move.w     (a1),(a2)+
  add.l      d0,a1
  move.w     (a1),(a3)+
  add.l      d0,a1
  move.w     (a1),(a3)+
  add.l      d0,a1
  dbf        d7,.loop
  rts

; a2 - sprite 0 structure (gfx data)
; a3 - sprite 1 structure (gfx data)
; uses d0,d7
empty_animstep:
  moveq.l    #0,d0
  moveq.l    #TilePixelHeight-1,d7
.loop:
  move.w     d0,(a2)+
  move.w     d0,(a2)+
  move.w     d0,(a3)+
  move.w     d0,(a3)+
  dbf        d7,.loop
  rts

; updates player position and animation
; uses d0-d2,a1-a3
  xdef       player_update
player_update:
  lea.l      ig_om_player(a4),a3

; when player has died, only anim must be updated 
  btst       #IgPlayerDead,ig_om_bools(a4)
  bne        .update_anim

; check pl_no_col_det_frames and decrement if necessary
  tst.w      pl_no_col_det_frames(a3)
  beq.s      .do_sprite_coldet
  sub.w      #1,pl_no_col_det_frames(a3)

.do_sprite_coldet:
; first of all - check for collision
; sprite 0+1 collide with first bitplane?
  move.w     #%0001000001000001,CLXCON(a6)
  move.w     CLXDAT(a6),d0
  and.b      #%00000010,d0
  tst.b      d0
  beq.s      .no_collision_bpl1
  bra.s      .collision_detected
.no_collision_bpl1:
; no collision detected
  ifne       SHOW_COLLISION_RED
  clr.w      COLOR00(a6)
  endif
  bra.s      .coll_check_end
.collision_detected:
  ifne       SHOW_COLLISION_RED
  move.w     #$0f00,COLOR00(a6)
  else
  ; indestructable after being hit
  tst.w      pl_no_col_det_frames(a3)
  bne.s      .coll_check_end
  ; being hit and decrement lives-counter
  jsr        sfx_explosion

  move.l     #ig_om_f003+f003_dat_explosion_anim_tmx+m_om_area,pl_anim(a3)
  clr.b      pl_animstep(a3)
  move.b     #f003_dat_explosion_anim_tmx_tiles_width,pl_max_animstep(a3)

  bset       #IgPanelUpdate,ig_om_bools(a4)

  move.b     g_om_lives(a4),d1
  moveq.l    #1,d0
  move       #0,ccr
  sbcd       d0,d1
  move.b     d1,g_om_lives(a4)

  tst.b      g_om_lives(a4)
  beq.s      .coll_check_play_dead
  move.w     #PlNoColDetFramesTotal,pl_no_col_det_frames(a3)
  bra.s      .coll_check_end
.coll_check_play_dead:
  ; last life lost => player dead
  bset       #IgPlayerDead,ig_om_bools(a4)

  moveq.l    #1,d0
  jsr        fade_out_init
  bset       #IgExit,ig_om_bools(a4)

  bra        .update_anim
  endif
.coll_check_end:

; set player position after explosion is shown
  cmp.w      #PlNoColDetFramesWoExpl,pl_no_col_det_frames(a3)
  bne.s      .read_joystick
  move.w     #ScreenStartX,pl_xpos(a3)
  move.l     a4,a2
  add.l      #ig_om_f003+f003_dat_level1_tmx_respawn_info,a2
  move.l     ig_om_scroll_xpos(a4),d0
  lsr.l      #4,d0                                                                    ; xpos of level / 16
  add.l      d0,d0                                                                    ; * 2 because the ypos are WORD values
  move.w     (a2,d0.w),pl_ypos(a3)

.read_joystick:
; do not read joystick when not visible
  cmp.w      #PlNoColDetAfterVisible,pl_no_col_det_frames(a3)
  bgt        .update_anim

; check joystick
  jsr        js_read
  move.w     d0,pl_joystick(a3)
 
; update position according to joystick movement and switch between animations
.check_directions:
  btst       #JsLeft,d0
  beq.s      .check_right
  ; left
  sub.w      #1,pl_xpos(a3)
  bra.s      .check_vertical
.check_right:
  btst       #JsRight,d0
  beq.s      .check_vertical
  ; right
  add.w      #1,pl_xpos(a3)
.check_vertical:
  move.l     #ig_om_f003+f003_dat_player_anim_horizontal_tmx+m_om_area,pl_anim(a3)
  move.b     #f003_dat_player_anim_horizontal_tmx_tiles_width,pl_max_animstep(a3)

  btst       #JsDown,d0
  beq.s      .check_up
  ; down
  add.w      #1,pl_ypos(a3)
  move.l     #ig_om_f003+f003_dat_player_anim_down_tmx+m_om_area,pl_anim(a3)
  move.b     #f003_dat_player_anim_down_tmx_tiles_width,pl_max_animstep(a3)
  bra.s      .end_check
.check_up:  
  btst       #JsUp,d0
  beq.s      .end_check
  ; up
  sub.w      #1,pl_ypos(a3)
  move.l     #ig_om_f003+f003_dat_player_anim_up_tmx+m_om_area,pl_anim(a3)
  move.b     #f003_dat_player_anim_up_tmx_tiles_width,pl_max_animstep(a3)
.end_check:

; validate xpos and ypos against bounding box
  cmp.w      #ScreenStartY,pl_ypos(a3)
  bgt.s      .bb_left
  move.w     #ScreenStartY,pl_ypos(a3)
.bb_left:
  cmp.w      #ScreenStartX,pl_xpos(a3)
  bgt.s      .bb_right
  move.w     #ScreenStartX,pl_xpos(a3)
.bb_right:
  cmp.w      #ScreenStartX+ScreenWidth-TilePixelWidth-2,pl_xpos(a3)                   ; -2 as adjustement
  blt.s      .bb_bottom
  move.w     #ScreenStartX+ScreenWidth-TilePixelWidth-2,pl_xpos(a3)
.bb_bottom:
  cmp.w      #ScreenStartY+ScreenHeight-TilePixelHeight,pl_ypos(a3)
  blt.s      .bb_done
  move.w     #ScreenStartY+ScreenHeight-TilePixelHeight,pl_ypos(a3)
.bb_done:

; update animstep every second frame
.update_anim:
  btst       #0,ig_om_frame_counter+3(a4)
  beq.s      .1 
  moveq.l    #0,d0
  move.b     pl_animstep(a3),d0
  bra.s      .draw_anim
.1:
; inc and wrap animstep
  moveq.l    #0,d0
  move.b     pl_animstep(a3),d0
  addq.l     #1,d0
  cmp.b      pl_max_animstep(a3),d0
  bne.s      .3
  btst       #IgPlayerDead,ig_om_bools(a4)
  beq.s      .2
  subq.l     #1,d0
  bra.s      .3
.2:
  moveq.l    #0,d0
.3:
  move.b     d0,pl_animstep(a3)

.draw_anim:
; calc animstep pointer
  lea.l      ig_cm_f002+f002_dat_tiles_iff(a5),a1
  move.l     pl_anim(a3),a2
  moveq.l    #0,d1
  lsl.l      #1,d0
  add.l      d0,a2
  move.w     (a2),d1
  add.l      d1,a1

; calc and set control words
  bsr        calc_control_words
  move.w     pl_no_col_det_frames(a3),d1

  lea.l      ig_cm_player(a5),a2
  lea.l      ig_cm_player+72(a5),a3

  move.l     d0,(a2)+
  move.l     d0,(a3)+

; draw animstep
; 1 - draw explosion
  cmp.b      #PlNoColDetFramesWoExpl,d1
  bgt        copy_animstep                                                            ; implicit rts
; 2 - player not visible
  cmp.b      #PlNoColDetAfterVisible,d1
  bgt        empty_animstep                                                           ; implicit rts
; 3 - player visible but eventually indestructible
  btst       #0,d1
  bne        empty_animstep                                                           ; implicit rts
  bra        copy_animstep                                                            ; implicit rts


; checks if player has pressed firebutton and spawns playershot
; uses a3,d0 
  xdef       player_firebutton
player_firebutton:
  ; player cannot shoot when he is dead
  btst       #IgPlayerDead,ig_om_bools(a4)
  bne.s      .2

  ; player cannot shoot when explosion is shown or player is invisible
  lea.l      ig_om_player(a4),a3
  cmp.w      #PlNoColDetAfterVisible,pl_no_col_det_frames(a3)
  bgt.s      .2

  move.w     pl_joystick(a3),d0

; update shot delay if necessary
  tst.b      pl_frames_till_next_shot(a3)
  beq.s      .1
  sub.b      #1,pl_frames_till_next_shot(a3)
  bra.s      .2

; fire shot when button is pressed
.1:
  btst       #JsFire,d0
  ble.s      .2
  jsr        ps_new_shot
  move.b     #PlShotDelay,pl_frames_till_next_shot(a3)

.2:
  rts
