  section    CoordsConvCode,code
              
  include    "constants.i"

; inits offset table for y-pos
; d0.l width of screenbuffer in bytes
; uses a0,d1-d2
  xdef       cc_init
cc_init:
  lea.l      cc_ypos_offsets(pc),a0
  lsl.l      #2,d0                     ; * ScreenBitPlanes
  moveq.l    #0,d1
  move.w     #ScreenHeight-1,d2
.cci_loop:
  move.l     d1,(a0)+
  add.l      d0,d1
  dbf        d2,.cci_loop
  rts

; converts screen coordinates to bitplane pointer offset in framebuffer
; d0.w screen x-pos (0 - ScreenWidth-1)
; d1.w screen y-pos (0 - ScreenHeight-1)
; d2.w x-offset of framebuffer (used when framebuffer scrolls)
; uses a0
; return:
; d1.l offset (word boundary)
; d0.w pixelshift (0-15)
  xdef       cc_scr_to_bplptr
cc_scr_to_bplptr:
  add.w      d2,d0
  lea.l      cc_ypos_offsets(pc),a0
  lsl.w      #2,d1
  move.l     (a0,d1.w),d1
  moveq.l    #0,d2
  move.w     d0,d2
  lsr.l      #4,d2
  lsl.l      #1,d2
  add.l      d2,d1
  and.w      #$000f,d0
  rts

cc_ypos_offsets:
  dcb.l      ScreenHeight
