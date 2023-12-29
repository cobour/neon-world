  section    BcdCode,code
              
  include    "constants.i"

; adds two bdc values
; in:
; d0 - 32-bit bcd value
; d1 - 32-bit bcd value
; out:
; d0 - sum as 32-bit bcd value
  xdef       bcd_add
bcd_add:
  abcd       d1,d0
  ror.l      #8,d0
  ror.l      #8,d1
  abcd       d1,d0
  ror.l      #8,d0
  ror.l      #8,d1
  abcd       d1,d0
  ror.l      #8,d0
  ror.l      #8,d1
  abcd       d1,d0
  ror.l      #8,d0
  ror.l      #8,d1
  rts

; converts bcd value to string (length 6 chars, null-terminated)
; in:
; d0 - 24- or 32-bit bcd value
; out:
; a0 - points to null-terminated string
; uses:
; d1-d2,a1
  xdef       bcd_to_string_of_6
bcd_to_string_of_6:
  lea.l      bcd_string+7(pc),a0
  move.b     #0,-(a0)
  lea.l      bcd_to_string_chars(pc),a1
  move.l     d0,d2
  moveq.l    #$f,d1

  and.l      d1,d0
  move.b     (a1,d0.w),-(a0)
  lsr.l      #4,d2
  move.l     d2,d0

  and.l      d1,d0
  move.b     (a1,d0.w),-(a0)
  lsr.l      #4,d2
  move.l     d2,d0

  and.l      d1,d0
  move.b     (a1,d0.w),-(a0)
  lsr.l      #4,d2
  move.l     d2,d0

  and.l      d1,d0
  move.b     (a1,d0.w),-(a0)
  lsr.l      #4,d2
  move.l     d2,d0

  and.l      d1,d0
  move.b     (a1,d0.w),-(a0)
  lsr.l      #4,d2
  move.l     d2,d0

  and.l      d1,d0
  move.b     (a1,d0.w),-(a0)

  rts

; converts bcd value to string (length 2 chars, null-terminated)
; in:
; d0 - 8-bit bcd value
; out:
; a0 - points to null-terminated string
; uses:
; d1-d2,a1
  xdef       bcd_to_string_of_2
bcd_to_string_of_2:
  lea.l      bcd_string+3(pc),a0
  move.b     #0,-(a0)
  lea.l      bcd_to_string_chars(pc),a1
  move.l     d0,d2
  moveq.l    #$f,d1

  and.l      d1,d0
  move.b     (a1,d0.w),-(a0)
  lsr.l      #4,d2
  move.l     d2,d0

  and.l      d1,d0
  move.b     (a1,d0.w),-(a0)

  rts

bcd_to_string_chars:
  dc.b       "0123456789"
bcd_string:  
  dcb.b      8
