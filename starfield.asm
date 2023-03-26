  section    StarfieldCode,code
  
  include    "constants.i"

  xdef       sf_init
; initializes starfield before first frame
; uses d0-d2,d4-d7,a0-a1
sf_init:
; generate data structure

; generate two "random" seed numbers in d5 and d6
  move.l     #$deadbeef,d5
  move.l     #$12345678,d6
  move.w     VHPOSR(a6),d7
.gen_seeds_loop:
  swap       d5
  add.l      d6,d5
  add.l      d5,d6
  dbf        d7,.gen_seeds_loop

  lea.l      ig_om_starfield(a4),a0
  moveq.l    #4,d1
  move.w     #NumberOfStars-1,d7

.gen_datastructure_loop:

; get new "random" number in d0
  swap       d5
  add.l      d6,d5
  add.l      d5,d6
  move.w     d5,d0
; adjust to screen as valid x-pos     
  and.w      #%0000000111111111,d0
.gdl_xpos_adjust_loop:
  cmp.w      #ScreenStopX,d0
  ble.s      .gdl_xpos_is_fine
  sub.w      #42,d0
  bra.s      .gdl_xpos_adjust_loop
.gdl_xpos_is_fine:
  move.w     d0,(a0)+                          ; x-position
  move.w     d1,(a0)+                          ; depth value => value means moving pixels per frame and color (4 means bright, 3 means medium bright and 2 means dark grey)

  subq.l     #1,d1
  cmp.b      #1,d1
  bne.s      .gdl_no_reset
  moveq.l    #4,d1
.gdl_no_reset:
  dbf        d7,.gen_datastructure_loop

; generate sprite data
  lea.l      ig_cm_sprite4_starfield(a5),a0    ; sprite 4 data structure
  lea.l      ig_cm_sprite5_starfield(a5),a1    ; sprite 5 data structure
  lea.l      ig_om_starfield(a4),a2            ; value data structure

  moveq.l    #0,d0
  move.l     d0,d1
  move.w     #LineOfFirstStar,d0
  move.w     #LineOfFirstStar+1,d1
  
  move.w     #NumberOfStars-1,d7
.gen_spritedata_loop:
  move.w     (a2)+,d2                          ; HSTART
  move.w     d0,d4                             ; VSTART
  move.w     d2,d5                             ; VSTOP
  lsr.w      #1,d5
  lsl.w      #8,d4
  add.b      d5,d4
  move.w     d4,(a0)+                          ; SPR4POS
  move.w     d4,(a1)+                          ; SPR5POS

  move.w     d1,d4
  lsl.w      #8,d4
  bset       #7,d4

; SV8
  btst       #8,d0
  beq.s      .gsl_no_sv8
  bset       #2,d4
.gsl_no_sv8:

; EV8
  btst       #8,d1
  beq.s      .gsl_no_ev8
  bset       #1,d4
.gsl_no_ev8:

; SH0  
  btst       #0,d2
  beq.s      .gsl_no_sh0
  bset       #0,d4
.gsl_no_sh0:

  move.w     d4,(a0)+                          ; SPR4CTL
  move.w     d4,(a1)+                          ; SPR5CTL

  move.w     (a2)+,d5                          ; depth value
  cmp.b      #4,d5
  bne.s      .gsl_check3
  move.w     #$8000,(a0)+                      ; SPR4DATA
  move.w     #$0000,(a0)+                      ; SPR4DATB
  move.w     #$8000,(a1)+                      ; SPR5DATA
  move.w     #$8000,(a1)+                      ; SPR5DATB
  bra.s      .gsl_iterate
.gsl_check3:
  cmp.b      #3,d5
  bne.s      .gsl_is2
  move.w     #$0000,(a0)+                      ; SPR4DATA
  move.w     #$0000,(a0)+                      ; SPR4DATB
  move.w     #$8000,(a1)+                      ; SPR5DATA
  move.w     #$8000,(a1)+                      ; SPR5DATB
  bra.s      .gsl_iterate
.gsl_is2:
  move.w     #$8000,(a0)+                      ; SPR4DATA
  move.w     #$8000,(a0)+                      ; SPR4DATB
  move.w     #$0000,(a1)+                      ; SPR5DATA
  move.w     #$8000,(a1)+                      ; SPR5DATB

.gsl_iterate:
  addq.l     #LineAdd,d0
  addq.l     #LineAdd,d1
  dbf        d7,.gen_spritedata_loop
  
  moveq.l    #0,d0
  move.l     d0,(a0)                           ; end of sprite data
  move.l     d0,(a1)
   
  rts

; scrolls the starfield
  xdef       sf_scroll
sf_scroll:
  lea.l      ig_cm_sprite4_starfield(a5),a0    ; sprite 4 data structure
  lea.l      ig_cm_sprite5_starfield(a5),a1    ; sprite 5 data structure
  lea.l      ig_om_starfield(a4),a2            ; value data structure

  move.w     #NumberOfStars-1,d7
.loop:
  move.w     (a2),d0                           ; x-pos
  move.w     2(a2),d1                          ; speed
  sub.w      d1,d0
  cmp.w      #$80,d0
  bge.s      .l_xpos_is_fine
  add.w      #$140,d0
.l_xpos_is_fine:
  move.w     d0,(a2)                           ; update x-pos in data structure

; update sprite data structure
  move.w     (a0),d1                           ; SPRxPOS
  move.w     2(a0),d2                          ; SPRxCTL
  and.w      #$ff00,d1
  btst       #0,d0
  beq.s      .l_clear_sh0
  bset       #0,d2
  bra.s      .l_update_sprite_control_words
.l_clear_sh0:
  bclr       #0,d2
.l_update_sprite_control_words:
  lsr.w      #1,d0
  add.w      d0,d1
  move.w     d1,(a0)                           ; SPR4POS
  move.w     d1,(a1)                           ; SPR5POS
  move.w     d2,2(a0)                          ; SPR4CTL
  move.w     d2,2(a1)                          ; SPR5CTL

  addq.l     #4,a2
  addq.l     #8,a0
  addq.l     #8,a1
  dbf        d7,.loop
  rts
