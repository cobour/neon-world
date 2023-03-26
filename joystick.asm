  section    JoystickCode,code
  
  include    "constants.i"

  xdef       js_read
; returns state of joystick in port 1
; heavily inspired by http://eab.abime.net/showpost.php?p=986196&postcount=2
; uses d0.w
; returns d0.b - state of joystick (see JsXxxx constants)
js_read:
  move.w     JOY1DAT(a6),d0
  ror.b      #2,d0
  lsr.w      #6,d0
  and.w      #%1111,d0
  move.b     (.conversion_tab,pc,d0.w),d0

  btst       #FireButton,CIAAPRA
  bne.s      .exit
  bset       #JsFire,d0

.exit
  rts

.conversion_tab:
  dc.b       0,1<<JsDown,1<<JsDown|1<<JsRight,1<<JsRight
  dc.b       1<<JsUp,0,0,1<<JsUp|1<<JsRight
  dc.b       1<<JsUp|1<<JsLeft,0,0,0
  dc.b       1<<JsLeft,1<<JsDown|1<<JsLeft,0,0
