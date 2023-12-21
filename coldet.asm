  section    ColDetCode,code
              
  include    "constants.i"

  xdef       cd_check
cd_check:

  move.l     #ps_size,d7                     ; added for each iteration on playershots
  move.l     #enemy_size,d6                  ; added for each iteration on enemies

  lea.l      ig_om_playershots_end(a4),a0
  move.l     a0,d5                           ; points behind end of all playershot-structs
  lea.l      ig_om_enemies_end(a4),a1
  move.l     a1,d4                           ; points behind end of all enemy-Structs

  lea.l      ig_om_playershots(a4),a0
.ps_outer_loop:
  btst       #BobCanCollide,b_bools(a0)
  beq.s      .next_ps

  lea.l      ig_om_enemies(a4),a1
.en_inner_loop:
  btst       #BobCanCollide,b_bools(a1)
  beq.s      .next_en

  ; check for collision between playershot (a0) and enemy (a1)
  move.l     enemy_descriptor(a1),a2

  ; is shot right of enemy? then .next_en
  move.w     b_xpos(a0),d0
  sub.w      #PsSpeed-2,d0                   ; PsSpeed to the left, because shot traveled through this area; reduced by 2 because shot-gfx is less than 16 pixels wide
  move.w     b_xpos(a1),d1
  add.w      ed_coldet_x2(a2),d1
  cmp.w      d0,d1
  blt.s      .next_en

  ; is shot left of enemy? then .next_en
  add.w      #14+(PsSpeed-2),d0              ; add subtraction from above and additonal 14 and not 16 because shot-gfx is is less than 16 pixels wide
  move.w     b_xpos(a1),d1
  add.w      ed_coldet_x1(a2),d1
  cmp.w      d0,d1
  bgt.s      .next_en

  ; is shot above enemy? then .next_en
  move.w     b_ypos(a0),d0
  add.w      #9,d0                           ; add 6 because shot-gfx is less than 16 pixels tall
  move.w     b_ypos(a1),d1
  add.w      ed_coldet_y1(a2),d1
  cmp.w      d0,d1
  bgt.s      .next_en

  ; is show below enemy? then .next_en
  sub.w      #3,d0                           ; shot-gfx is 3 pixels tall
  move.w     b_ypos(a1),d1
  add.w      ed_coldet_y2(a2),d1
  cmp.w      d0,d1
  blt.s      .next_en

  ; playershot dies, enemy dies
  bclr       #BobCanCollide,b_bools(a0)
  bclr       #BobCanCollide,b_bools(a1)
  bclr       #EnemyActive,enemy_bools(a1)
  move.l     ig_om_frame_counter(a4),d0
  addq.l     #2,d0
  move.l     d0,b_eol_frame(a0)
  move.l     d0,b_eol_frame(a1)
  ; play sample
  move.l     a0,a2
  jsr        sfx_explosion
  move.l     a2,a0
  ; TODO - spawn enemy explosion (special bob, no collision detection)

.next_en:
  add.l      d6,a1
  cmp.l      d4,a1
  bne.s      .en_inner_loop
.next_ps:
  add.l      d7,a0
  cmp.l      d5,a0
  bne        .ps_outer_loop

  rts
