  section    PanelCode,code
  
  include    "constants.i"

  xdef       panel_init
; a0 - pointer to copper list where sprite4-pointer is set
;
; FIXME: refactor me
;
; uses a1-a3,d0-d1,d5-d7
panel_init:
; calc source pointer and modulo
  move.l     a5,a2
  add.l      #ig_cm_f002+f002_dat_tiles_iff_mask,a2                                                ; yes, the mask, so all bits are set, thus leading to COLOR23 and COLOR27 for sprites 2-5
  add.l      #(TilesWidthBytes*TilesBitplanes)*((TilePixelHeight*11)+(TilePixelHeight/2))+18,a2    ; Points to zero in font
  move.l     #TilesWidthBytes*2,d1                                                                 ; modulo (*2 because 4 bitplanes in mask data and only 2 bitplanes in sprite data)

; set sprite 2 pointer in copperlist
  lea.l      ig_cm_sprite2_panel(a5),a1
  move.l     a1,d0
  move.w     d0,6(a0)
  swap       d0
  move.w     d0,2(a0)
; write sprite 2 control words
  move.w     #ScreenStartY<<8,d0
  add.w      #ScreenStartX>>1,d0
  move.w     d0,(a1)+
  move.w     #(ScreenStartY+16)<<8,d0
  move.w     d0,(a1)+

  move.l     a5,d5
  add.l      #ig_cm_f002+f002_dat_tiles_iff_mask,d5
  move.l     d5,d6
  add.l      #(TilesWidthBytes*TilesBitplanes)*((TilePixelHeight*10)+(TilePixelHeight/2))+19,d5    ; points to L
  add.l      #(TilesWidthBytes*TilesBitplanes)*((TilePixelHeight*11))+19,d6                        ; points to V
; write sprite 2 data words => LV
  moveq.l    #15,d7
.spr2_lv_loop:
  move.l     d5,a3
  move.b     (a3),(a1)+
  move.l     d6,a3
  move.b     (a3),(a1)+
  add.l      d1,d5
  add.l      d1,d6
  dbf        d7,.spr2_lv_loop

; write sprite 2 data words => 01
  moveq.l    #7,d7
  move.l     a2,a3
  move.l     a1,lives
.spr2_loop:
  move.b     (a3),(a1)+
  move.b     (a3),(a1)+
  add.l      d1,a3
  move.b     (a3),(a1)+
  move.b     (a3),(a1)+
  add.l      d1,a3
  dbf        d7,.spr2_loop
; write sprite 2 end-of-struct
  moveq.l    #0,d0
  move.l     d0,(a1)+

; set sprite 3 pointer in copperlist
  lea.l      ig_cm_sprite3_panel(a5),a1
  move.l     a1,d0
  move.w     d0,14(a0)
  swap       d0
  move.w     d0,10(a0)
; write sprite 3 control words
  move.w     #ScreenStartY<<8,d0
  add.w      #(ScreenStartX+ScreenWidth-48)>>1,d0
  move.w     d0,(a1)+
  move.w     #(ScreenStartY+16)<<8,d0
  move.w     d0,(a1)+

  move.l     a5,d5
  add.l      #ig_cm_f002+f002_dat_tiles_iff_mask,d5
  move.l     d5,d6
  add.l      #(TilesWidthBytes*TilesBitplanes)*((TilePixelHeight*10)+(TilePixelHeight/2))+26,d5    ; points to S
  add.l      #(TilesWidthBytes*TilesBitplanes)*((TilePixelHeight*10))+20,d6                        ; points to C
; write sprite 3 data words => SC
  moveq.l    #15,d7
.spr3_sc_loop:
  move.l     d5,a3
  move.b     (a3),(a1)+
  move.l     d6,a3
  move.b     (a3),(a1)+
  add.l      d1,d5
  add.l      d1,d6
  dbf        d7,.spr3_sc_loop

; write sprite 3 data words => 01
  moveq.l    #7,d7
  move.l     a2,a3
  move.l     a1,score
.spr3_loop:
  move.b     (a3),(a1)+
  move.b     (a3),(a1)+
  add.l      d1,a3
  move.b     (a3),(a1)+
  move.b     (a3),(a1)+
  add.l      d1,a3
  dbf        d7,.spr3_loop
; write sprite 3 end-of-struct
  moveq.l    #0,d0
  move.l     d0,(a1)+

; set sprite 4 pointer in copperlist
  lea.l      ig_cm_sprite4_panel(a5),a1
  move.l     a1,d0
  move.w     d0,22(a0)
  swap       d0
  move.w     d0,18(a0)
; write sprite 4 control words
  move.w     #ScreenStartY<<8,d0
  add.w      #(ScreenStartX+ScreenWidth-32)>>1,d0
  move.w     d0,(a1)+
  move.w     #(ScreenStartY+16)<<8,d0
  move.w     d0,(a1)+

  move.l     a5,d5
  add.l      #ig_cm_f002+f002_dat_tiles_iff_mask,d5
  move.l     d5,d6
  add.l      #(TilesWidthBytes*TilesBitplanes)*((TilePixelHeight*10)+(TilePixelHeight/2))+22,d5    ; points to O
  add.l      #(TilesWidthBytes*TilesBitplanes)*((TilePixelHeight*10)+(TilePixelHeight/2))+25,d6    ; points to R
; write sprite 4 data words => OR
  moveq.l    #15,d7
.spr4_or_loop:
  move.l     d5,a3
  move.b     (a3),(a1)+
  move.l     d6,a3
  move.b     (a3),(a1)+
  add.l      d1,d5
  add.l      d1,d6
  dbf        d7,.spr4_or_loop

; write sprite 4 data words => 23
  moveq.l    #7,d7
  move.l     a2,a3
  move.l     a1,score+4
.spr4_loop:
  move.b     (a3),(a1)+
  move.b     (a3),(a1)+
  add.l      d1,a3
  move.b     (a3),(a1)+
  move.b     (a3),(a1)+
  add.l      d1,a3
  dbf        d7,.spr4_loop
; NO end-of-struct, because sprite is reused for starfield

; set sprite 5 pointer in copperlist
  lea.l      ig_cm_sprite5_panel(a5),a1
  move.l     a1,d0
  move.w     d0,30(a0)
  swap       d0
  move.w     d0,26(a0)
; write sprite 5 control words
  move.w     #ScreenStartY<<8,d0
  add.w      #(ScreenStartX+ScreenWidth-16)>>1,d0
  move.w     d0,(a1)+
  move.w     #(ScreenStartY+16)<<8,d0
  move.w     d0,(a1)+

  move.l     a5,a3
  add.l      #ig_cm_f002+f002_dat_tiles_iff_mask,a3
  add.l      #(TilesWidthBytes*TilesBitplanes)*((TilePixelHeight*10))+22,a3                        ; points to E
; write sprite 5 data words => E_
  moveq.l    #15,d7
.spr5_e__loop:
  move.b     (a3),(a1)+
  clr.b      (a1)+
  add.l      d1,a3
  dbf        d7,.spr5_e__loop

; write sprite 5 data words => 45
  moveq.l    #7,d7
  move.l     a2,a3
  move.l     a1,score+8
.spr5_loop:
  move.b     (a3),(a1)+
  move.b     (a3),(a1)+
  add.l      d1,a3
  move.b     (a3),(a1)+
  move.b     (a3),(a1)+
  add.l      d1,a3
  dbf        d7,.spr5_loop
; NO end-of-struct, because sprite is reused for starfield

  bset       #IgPanelUpdate,ig_om_bools(a4)
  bra.s      panel_update

lives:
  ; points to begin of bitmap data of lives in sprite-struct
  dc.l       0
score:
  ; points to begin of bitmap data of score in sprite-struct (one pointer for 2 numbers)
  dcb.l      3

; updates lives- and score-counter
; uses d0-d4,d7,a0-a3
  xdef       panel_update
panel_update:
  btst       #IgPanelUpdate,ig_om_bools(a4)
  beq        .exit

  move.l     a5,d3
  add.l      #ig_cm_f002+f002_dat_tiles_iff_mask,d3                                                ; yes, the mask, so all bits are set, thus leading to COLOR23 and COLOR27 for sprites 2-5
  add.l      #(TilesWidthBytes*TilesBitplanes)*((TilePixelHeight*11)+(TilePixelHeight/2))+18,d3    ; Points to zero in font
  move.l     #TilesWidthBytes*2,d4                                                                 ; modulo (*2 because 4 bitplanes in mask data and only 2 bitplanes in sprite data)

  ; update lives
  moveq.l    #0,d0
  move.b     g_om_lives(a4),d0
  jsr        bcd_to_string_of_2

  moveq.l    #0,d2
  move.l     lives(pc),a3

  move.b     (a0)+,d2
  sub.b      #$30,d2
  bsr.s      .draw_single_number
  addq.l     #1,a3

  move.b     (a0)+,d2
  sub.b      #$30,d2
  bsr.s      .draw_single_number

  ; update score
  move.l     g_om_score(a4),d0
  jsr        bcd_to_string_of_6

  moveq.l    #0,d2
  move.l     score(pc),a3

  move.b     (a0)+,d2
  sub.b      #$30,d2
  bsr.s      .draw_single_number
  addq.l     #1,a3

  move.b     (a0)+,d2
  sub.b      #$30,d2
  bsr.s      .draw_single_number
  addq.l     #1,a3

  move.l     score+4(pc),a3

  move.b     (a0)+,d2
  sub.b      #$30,d2
  bsr.s      .draw_single_number
  addq.l     #1,a3

  move.b     (a0)+,d2
  sub.b      #$30,d2
  bsr.s      .draw_single_number
  addq.l     #1,a3

  move.l     score+8(pc),a3

  move.b     (a0)+,d2
  sub.b      #$30,d2
  bsr.s      .draw_single_number
  addq.l     #1,a3

  move.b     (a0)+,d2
  sub.b      #$30,d2
  bsr.s      .draw_single_number

  bclr       #IgPanelUpdate,ig_om_bools(a4)

.exit:
  rts

.draw_single_number:
  moveq.l    #7,d7
  move.l     d3,a2
  add.l      d2,a2
  move.l     a3,a1
.dss_loop:  
  move.b     (a2),(a1)
  addq.l     #2,a1
  add.l      d4,a2
  move.b     (a2),(a1)
  addq.l     #2,a1
  add.l      d4,a2
  dbf        d7,.dss_loop
  rts