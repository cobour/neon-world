  section    PanelCode,code
  
  include    "constants.i"

  xdef       panel_init
; a0 - pointer to copper list where sprite4-pointer is set
;
; FIXME: This part is quick-and-dirty because the lives- and score-panel 
;        does not show correct data right now.
;        Refactoring is done, when real data are displayed.
;
; uses a1-a3,d0-d1,d7
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
  move.w     #(ScreenStartY+8)<<8,d0
  move.w     d0,(a1)+
; write sprite 2 data words
  moveq.l    #7,d7
  move.l     a2,a3
.spr2_loop:
  move.w     (a3),(a1)+
  add.l      d1,a3
  move.w     (a3),(a1)+
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
  move.w     #(ScreenStartY+8)<<8,d0
  move.w     d0,(a1)+
; write sprite 3 data words
  moveq.l    #7,d7
  move.l     a2,a3
.spr3_loop:
  move.w     (a3),(a1)+
  add.l      d1,a3
  move.w     (a3),(a1)+
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
  move.w     #(ScreenStartY+8)<<8,d0
  move.w     d0,(a1)+
; write sprite 4 data words
  moveq.l    #7,d7
  addq.l     #2,a2
  move.l     a2,a3
.spr4_loop:
  move.w     (a3),(a1)+
  add.l      d1,a3
  move.w     (a3),(a1)+
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
  move.w     #(ScreenStartY+8)<<8,d0
  move.w     d0,(a1)+
; write sprite 5 data words
  moveq.l    #7,d7
  addq.l     #2,a2
  move.l     a2,a3
.spr5_loop:
  move.w     (a3),(a1)+
  add.l      d1,a3
  move.w     (a3),(a1)+
  add.l      d1,a3
  dbf        d7,.spr5_loop
; NO end-of-struct, because sprite is reused for starfield

  rts
