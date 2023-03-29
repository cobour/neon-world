  section    TextCode,code
              
  include    "constants.i"

  xdef       text_init
; a0 - pointer to tiles
; uses a1,d7
text_init:
  lea.l      sign_pointers(pc),a1

	; space
  move.l     a0,(a1)+

	; A - J
  add.l      #(TilesWidthBytes*TilesBitplanes*TilePixelHeight*10)+(TilePixelWidth/8*9),a0    ; offset over 10 rows and 9 columns
  moveq.l    #9,d7
.aj_loop:
  move.l     a0,(a1)+
  addq.l     #1,a0
  dbf        d7,.aj_loop

	; K - T
  add.l      #(TilesWidthBytes*TilesBitplanes*8)-10,a0
  moveq.l    #9,d7
.kt_loop:
  move.l     a0,(a1)+
  addq.l     #1,a0
  dbf        d7,.kt_loop

	; U - Z
  add.l      #(TilesWidthBytes*TilesBitplanes*8)-10,a0
  moveq.l    #5,d7
.uz_loop:
  move.l     a0,(a1)+
  addq.l     #1,a0
  dbf        d7,.uz_loop

  rts

  xdef       text_print
; prints one line of text to screenbuffer, starts at exact word boundary
; a0 - pointer to null-terminated text
; a1 - pointer to screenbuffer (must point to correct x,y position in screenbuffer)
; d0 - width of screenbuffer in bytes
; uses a2-a3,d1-d4,d7
text_print:
  move.l     a1,d4
  lea.l      sign_pointers(pc),a1
  move.l     #TilesWidthBytes,d3
  moveq.l    #0,d1
.tp_loop:
  move.b     (a0)+,d1
  tst.b      d1
  beq.s      .tp_exit

	; get pointer to correct sign
  cmp.b      #32,d1
  bne.s      .tp_loop_letter
  move.l     (a1),a2
  bra.s      .tp_loop_print_sign
.tp_loop_letter:
  sub.b      #64,d1
  move.l     d1,d2
  lsl.l      #2,d2
  move.l     (a1,d2),a2

.tp_loop_print_sign:
  move.l     d4,a3
  move.w     #(ScreenBitPlanes*8)-1,d7
.cs_loop:
  move.b     (a2),(a3)
  add.l      d3,a2
  add.l      d0,a3
  dbf        d7,.cs_loop

  addq.l     #1,d4
  bra.s      .tp_loop

.tp_exit:
  rts

; pointers to space and A-Z (byte-exact - may be odd)
sign_pointers:
  dcb.l      27
