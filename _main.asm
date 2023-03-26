  section     MainCode,code

  include     "constants.i"

main:
  SET_PTRS
  bsr         m_init_g_structure
  bsr         m_init_ptplayer
  jsr         fade_tab_init
  jsr         dos_init
  jsr         osc_save_orig_system_state

.1:
  jsr         osc_black_screen
  bsr         m_init_next
  jsr         osc_take_system
  WAIT_VB                                   ; wait one vbl, so irqs can not be active any more

  bsr.s       m_start_next

  btst        #GExit,g_om_bools(a4)
  bne.s       .2
  jsr         osc_free_system
  WAIT_VB                                   ; wait one vbl, so irqs are active again
  bra.s       .1
.2:
  bsr.s       m_cleanup_ptplayer
  jsr         osc_free_system
  jsr         dos_cleanup
  jsr         osc_restore_screen

  moveq.l     #0,d0
  rts

m_init_g_structure:
  clr.b       g_om_bools(a4)
  clr.b       g_om_lives(a4)
  clr.b       g_om_level(a4)
  clr.l       g_om_score(a4)
  rts

m_init_ptplayer:
  sub.l       a0,a0
  moveq.l     #1,d0
  jsr         _mt_install_cia
  rts

m_cleanup_ptplayer:
  jsr         _mt_remove_cia
  rts

m_init_next:
  tst.b       g_om_level(a4)
  beq.s       .1
  jmp         ig_init
.1:
  jmp         mm_init

m_start_next:
  tst.b       g_om_level(a4)
  beq.s       .1
  jmp         ig_start
.1:
  jmp         mm_start
 
  include     "files_descriptor.i"


  section     MainOtherData,bss

; OtherMem dynamic area (see structure-definitions in constants.i)
  xdef        m_om_area
m_om_area:
  ifgt        ig_om_size-mm_om_size
  dcb.b       ig_om_size,0
  else
  dcb.b       mm_om_size,0
  endif
  even


  section     MainChipData,bss_c

; ChipMem dynamic area (see structure-definitions in constants.i)
  xdef        m_cm_area
m_cm_area:
  ifgt        ig_cm_size-mm_cm_size
  dcb.b       ig_cm_size,0
  else
  dcb.b       mm_cm_size,0
  endif
  even