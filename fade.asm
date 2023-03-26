              section    FadeCode,code
              
              include    "constants.i"

ColorStepSize equ TilesColors*2

; initializes the value tabs used for fading
; must be called before other fade-routines. must only be called once
; uses a0-a1, d0-d2, d6-d7
              xdef       fade_tab_init
fade_tab_init:
              moveq.l    #14,d7
              lea.l      color_steps(pc),a1
.outer_step_loop:
              lea.l      colors(pc),a0
              moveq.l    #15,d6
.inner_colors_loop
              move.w     (a0)+,d0                                          ; target color
              ; red
              move.w     d0,d1
              and.w      #$0f00,d1
              lsr.w      #8,d1
              mulu       d7,d1
              lsr.w      #4,d1                                             ; get rid of fraction
              lsl.w      #8,d1
              move.w     d1,d2                                             ; step
              ; green
              move.w     d0,d1
              and.w      #$00f0,d1
              lsr.w      #4,d1
              mulu       d7,d1
              lsr.w      #4,d1                                             ; get rid of fraction
              lsl.w      #4,d1
              add.w      d1,d2                                             ; step
              ; blue
              move.w     d0,d1
              and.w      #$000f,d1
              mulu       d7,d1
              lsr.w      #4,d1                                             ; get rid of fraction
              add.w      d1,d2                                             ; step

              move.w     d2,(a1)+
              dbf        d6,.inner_colors_loop

              dbf        d7,.outer_step_loop
 
              rts

; does the fade job (called each frame)
; a0 - pointer to copperlist with color moves
              xdef       do_fade
do_fade:
              btst       #GFadeIn,g_om_bools(a4)
              beq.s      .check_fade_out
              bsr.s      fade_in
              tst.b      d0
              bne.s      .check_fade_out
              bclr       #GFadeIn,g_om_bools(a4)
.check_fade_out:
              btst       #GFadeOut,g_om_bools(a4)
              beq.s      .exit
              bsr.s      fade_out
              tst.b      d0
              bne.s      .exit
              bclr       #GFadeOut,g_om_bools(a4)
.exit:
              rts

; inits for fade in
; d0.b delay
              xdef       fade_in_init
fade_in_init:
              bset       #GFadeIn,g_om_bools(a4)
              bclr       #GFadeOut,g_om_bools(a4)
              bra.s      fade_init

; inits for fade out
; d0.b delay
              xdef       fade_out_init
fade_out_init:
              bclr       #GFadeIn,g_om_bools(a4)
              bset       #GFadeOut,g_om_bools(a4)

; initializes the values used for fading
; d0.b       fade interval
fade_init:
              move.b     #16,g_om_fade_counter(a4)
              move.b     d0,g_om_fade_interval(a4)
              move.b     #0,g_om_fade_act_intvl(a4)                        ; so on first call of fade_to_xxx actual fading is done
              move.l     #color_steps_end,g_om_fade_fi_ptr(a4)
              move.l     #colors-ColorStepSize,g_om_fade_fo_ptr(a4)
              rts

; fades colors to target colors (must be called once per frame)
; a0 - points to section of copperlist containing the color definitions
; uses a1-a3,d0,d3-d7
; return: d0.b  how many fade steps are left
fade_out:
              moveq.l    #0,d3                                             ; means fade out
              bra.s      inner_fade
fade_in:
              moveq.l    #1,d3                                             ; means fade in
inner_fade:
              move.b     g_om_fade_counter(a4),d0
              tst.b      d0
              beq        .exit

              move.b     g_om_fade_act_intvl(a4),d4
              tst.b      d4
              beq.s      .set_color_pointer
              subq.b     #1,d4
              move.b     d4,g_om_fade_act_intvl(a4)
              bra        .exit

.set_color_pointer:
              ; set pointer for next step
              tst.b      d3
              bne.s      .do_fade_in
              move.l     g_om_fade_fo_ptr(a4),d3
              add.l      #ColorStepSize,d3
              move.l     d3,a2
              move.l     d3,g_om_fade_fo_ptr(a4)
              bra.s      .do_fade
.do_fade_in:
              move.l     g_om_fade_fi_ptr(a4),d3
              sub.l      #ColorStepSize,d3
              move.l     d3,a2
              move.l     d3,g_om_fade_fi_ptr(a4)
.do_fade:
              move.b     g_om_fade_interval(a4),g_om_fade_act_intvl(a4)

              move.l     a2,a3
              moveq.l    #15,d7
.color_loop_0_15:
              move.w     (a3)+,2(a0)                                       ; save to copperlist
              addq.l     #4,a0
              dbf        d7,.color_loop_0_15

              move.l     a2,a3
              moveq.l    #15,d7
              lea.l      fade_color23,a1
.color_loop_16_31:
              move.w     (a3)+,2(a0)                                       ; save to copperlist
              cmp.w      #COLOR23,(a0)
              bne.s      .1
              move.w     2(a0),2(a1)                                       ; copy to position after panel-color-effect
.1:
              cmp.w      #COLOR27,(a0)
              bne.s      .2
              move.w     2(a0),6(a1)                                       ; copy to position after panel-color-effect
.2:
              addq.l     #4,a0
              dbf        d7,.color_loop_16_31

              subq.b     #1,d0
              move.b     d0,g_om_fade_counter(a4)
.exit:
              rts

colors:       dc.w       $0000
              dc.w       $0044
              dc.w       $0230
              dc.w       $0570
              dc.w       $08a0
              dc.w       $09d0
              dc.w       $0f82
              dc.w       $0d00
              dc.w       $0900
              dc.w       $0700
              dc.w       $0222
              dc.w       $0555
              dc.w       $0888
              dc.w       $0ddd
              dc.w       $0056
              dc.w       $01df
color_steps:  dcb.b      ColorStepSize*15
color_steps_end:                                    ; used as starting pointer for fade-in

              even
