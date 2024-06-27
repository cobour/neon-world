  section    PowerupsCode,code
  
  include    "constants.i"

  xdef       powerups_init
powerups_init:
  ; init values for powerup descriptors
  move.l     a4,a0
  add.l      #ig_om_f003+f003_dat_level1_tmx_powerups,a0
  add.l      #f003_dat_level1_tmx_powerups_size,a0
  move.l     a0,ig_om_end_powerup_desc(a4)
  jsr        level_warp_powerups

  ; init pointers to powerup descriptors
  lea.l      powerups_desc(pc),a0
  lea.l      powerups_desc_prts(pc),a1
  moveq.l    #8,d0
  moveq.l    #PowerupDescCount-1,d7
.pup_desc_loop:
  move.l     a0,(a1)+
  add.l      d0,a0
  dbf        d7,.pup_desc_loop

  ; important when respawning player
  bsr        disable_powerup

  rts

  xdef       powerups_update
powerups_update:
.check_next:
  move.l     ig_om_next_powerup_desc(a4),a0
  cmp.l      ig_om_end_powerup_desc(a4),a0
  beq.s      .no_spawn                                                ; no more powerups

  move.l     ig_om_frame_counter(a4),d0
  cmp.l      pup_spawn_frame(a0),d0
  blt.s      .no_spawn                                                ; next powerup not yet reached

  ; spawn powerup
  move.w     pup_xpos(a0),d0
  add.w      #ScreenStartX,d0
  move.w     d0,act_pup_xpos
  move.w     pup_ypos(a0),d0
  add.w      #ScreenStartY,d0
  move.w     d0,act_pup_ypos
  bsr        calc_and_set_control_words
  move.w     pup_id(a0),d0
  add.w      d0,d0
  add.w      d0,d0
  lea.l      powerups_desc_prts(pc),a1
  move.l     (a1,d0.w),a1
  move.l     a1,act_pup_desc

  ; gfx
  move.l     act_pup_desc(pc),a1
  move.l     (a1),a1
  add.l      a5,a1
  add.l      #ig_cm_f002+f002_dat_tiles_iff,a1
  bsr        copy_animstep

  moveq.l    #0,d0
  move.l     d0,(a2)
  move.l     d0,(a3)

  ; check next
  lea.l      pup_size(a0),a0
  move.l     a0,ig_om_next_powerup_desc(a4)
  bra.s      .check_next
.no_spawn:

  ; position update
  lea.l      act_pup_xpos(pc),a0
  tst.w      (a0)
  beq.s      .exit
  sub.w      #1,(a0)
  bsr.s      calc_and_set_control_words

  ; player cannot collect when explosion is shown or player is invisible
  lea.l      ig_om_player(a4),a0
  cmp.w      #PlNoColDetAfterVisible,pl_no_col_det_frames(a0)
  bgt.s      .no_collect

  ; check if player collected the powerup (execute apply-routine and disable powerup)
  lea.l      ig_om_player(a4),a0

  move.w     pl_xpos(a0),d0
  add.w      #2,d0
  move.w     d0,d1
  add.w      #TilePixelWidth-4,d1

  move.w     act_pup_xpos(pc),d2
  cmp.w      d1,d2
  bgt.s      .no_collect                                              ; is player completely left of powerup? then .no_collect

  add.w      #TilePixelWidth,d2
  cmp.w      d0,d2
  blt.s      .no_collect                                              ; is player completely right of powerup? then .no_collect

  move.w     pl_ypos(a0),d0
  add.w      #3,d0
  move.w     d0,d1
  add.w      #TilePixelHeight-6,d1

  move.w     act_pup_ypos(pc),d2
  cmp.w      d1,d2
  bgt.s      .no_collect                                              ; is player completely above powerup? then .no_collect

  add.w      #TilePixelHeight,d2
  cmp.w      d0,d2
  blt.s      .no_collect                                              ; is player completely under powerup? then .no_collect

  ; player collected powerup

  move.l     act_pup_desc(pc),a0
  move.l     4(a0),a0
  jsr        (a0)
  bsr        disable_powerup
  jsr        sfx_powerup

.no_collect:
  ; disable powerup when moved offscreen
  move.w     act_pup_xpos(pc),d0
  sub.w      #ScreenStartX,d0
  add.w      #TilePixelWidth,d0
  tst.w      d0
  bge.s      .exit
  bsr.s      disable_powerup

.exit:
  rts

; uses d0-d2
; returns a2,a3 - set to gfx part of sprite 2 and 3
calc_and_set_control_words:
; SPRxPOS
  move.w     act_pup_ypos(pc),d0
  move.w     d0,d2
  add.w      #TilePixelHeight,d2                                      ; d2 = VSTOP
  lsl.l      #8,d0
  move.w     act_pup_xpos(pc),d1
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
  move.w     act_pup_ypos(pc),d2
  lsr.w      #8,d2
  btst       #0,d2
  beq.s      .2
  bset       #2,d1
.2:
  move.w     act_pup_xpos(pc),d2
  btst       #0,d2
  beq.s      .3
  bset       #0,d1
.3:
  swap       d0
  move.w     d1,d0

  ; set control words
  move.l     a5,a2
  lea.l      ig_cm_sprite2_powerup-4(a2),a2                           ; -4 because zero long of panel sprite must be overwritten
  move.l     d0,(a2)+
  move.l     a5,a3
  lea.l      ig_cm_sprite3_powerup-4(a3),a3                           ; -4 because zero long of panel sprite must be overwritten
  move.l     d0,(a3)+

  rts

; a1 - src pointer
; a2 - sprite 2 structure (gfx data)
; a3 - sprite 3 structure (gfx data)
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

disable_powerup:
  moveq.l    #0,d0

  ; zero the starting control words
  move.l     a5,a0
  lea.l      ig_cm_sprite2_powerup-4(a0),a0                           ; -4 because zero long of panel sprite must be overwritten
  move.l     d0,(a0)
  move.l     a5,a0
  lea.l      ig_cm_sprite3_powerup-4(a0),a0                           ; -4 because zero long of panel sprite must be overwritten
  move.l     d0,(a0)

  ; zero the vars
  lea.l      act_pup_xpos(pc),a0
  move.l     d0,(a0)+
  move.l     d0,(a0)

  rts

act_pup_xpos:
  dc.w       0
act_pup_ypos:
  dc.w       0
act_pup_desc:
  dc.l       0

PowerupDescCount equ 5
powerups_desc_prts:
  dcb.l      PowerupDescCount
powerups_desc:
  ; 0
  dc.l       (6*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+14
  dc.l       powerup_0_collected
  ; 1
  dc.l       (7*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+14
  dc.l       powerup_1_collected
  ; 2
  dc.l       (5*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+0
  dc.l       powerup_2_collected
  ; 3
  dc.l       (5*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+2
  dc.l       powerup_3_collected
  ; 4
  dc.l       (8*TilePixelHeight*TilesWidthBytes*TilesBitplanes)+14
  dc.l       powerup_4_collected

powerup_0_collected:
  lea.l      ig_om_player(a4),a0
  cmp.w      #1,pl_weapon_strength(a0)
  bgt.s      .exit
  move.w     #1,pl_weapon_strength(a0)
.exit:
  rts

powerup_1_collected:
  lea.l      ig_om_player(a4),a0
  cmp.w      #2,pl_weapon_strength(a0)
  bgt.s      .exit
  move.w     #2,pl_weapon_strength(a0)
.exit:
  rts

powerup_2_collected:
  move.b     g_om_lives(a4),d0
  cmp.b      #$99,d0
  beq.s      .exit
  move       #0,ccr
  moveq.l    #1,d1
  abcd       d1,d0
  move.b     d0,g_om_lives(a4)
  bset       #IgPanelUpdate,ig_om_bools(a4)
.exit:
  rts

powerup_3_collected:
  lea.l      ig_om_player(a4),a0
  move.w     #2,pl_speed(a0)
  rts

powerup_4_collected:
  lea.l      ig_om_player(a4),a0
  move.w     #3,pl_weapon_strength(a0)
  rts
