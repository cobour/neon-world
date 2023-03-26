  section    PlayerShotCode,code
  
  include    "constants.i"

  xdef       ps_new_shot
ps_new_shot:
; TODO: draw shot as bob according to player position and move it on screen
; for now, just play sample
  jmp        sfx_shot
