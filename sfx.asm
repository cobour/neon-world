  section    SfxCode,code
              
  include    "constants.i"

  xdef       sfx_select
sfx_select:
  lea.l      select_sfx(pc),a0
  bra.s      sfx_play_sample

  xdef       sfx_enter
sfx_enter:
  lea.l      enter_sfx(pc),a0
  bra.s      sfx_play_sample

  xdef       sfx_enter_go
sfx_enter_go:
  lea.l      enter_go_sfx(pc),a0
  bra.s      sfx_play_sample

  xdef       sfx_explosion
sfx_explosion:
  lea.l      explosion_sfx(pc),a0
  bra.s      sfx_play_sample

  xdef       sfx_explosion_small
sfx_explosion_small:
  lea.l      explosion_small_sfx(pc),a0
  bra.s      sfx_play_sample

  xdef       sfx_powerup
sfx_powerup:
  lea.l      powerup_sfx(pc),a0
  bra.s      sfx_play_sample

  xdef       sfx_shot
sfx_shot:
  lea.l      shot_sfx(pc),a0

sfx_play_sample:
  jmp        _mt_playfx

select_sfx:
  dc.l       m_cm_area+mm_cm_f000+f000_dat_select_wav
  dc.w       f000_dat_select_wav_length_in_words
  dc.w       f000_dat_select_wav_period_pal
  dc.w       64
  dc.b       -1
  dc.b       64
enter_sfx:
  dc.l       m_cm_area+mm_cm_f000+f000_dat_enter_wav
  dc.w       f000_dat_enter_wav_length_in_words
  dc.w       f000_dat_enter_wav_period_pal
  dc.w       64
  dc.b       -1
  dc.b       64
shot_sfx:
  dc.l       m_cm_area+ig_cm_f002+f002_dat_shot_wav
  dc.w       f002_dat_shot_wav_length_in_words
  dc.w       f002_dat_shot_wav_period_pal
  dc.w       64
  dc.b       -1
  dc.b       64
explosion_sfx:
  dc.l       m_cm_area+ig_cm_f002+f002_dat_explosion_wav
  dc.w       f002_dat_explosion_wav_length_in_words
  dc.w       f002_dat_explosion_wav_period_pal
  dc.w       64
  dc.b       -1
  dc.b       64
explosion_small_sfx:
  dc.l       m_cm_area+ig_cm_f002+f002_dat_explosion_small_wav
  dc.w       f002_dat_explosion_small_wav_length_in_words
  dc.w       f002_dat_explosion_small_wav_period_pal
  dc.w       64
  dc.b       -1
  dc.b       64
enter_go_sfx:
  dc.l       m_cm_area+go_cm_f004+f004_dat_enter_wav
  dc.w       f004_dat_enter_wav_length_in_words
  dc.w       f004_dat_enter_wav_period_pal
  dc.w       64
  dc.b       -1
  dc.b       64
powerup_sfx:
  dc.l       m_cm_area+ig_cm_f002+f002_dat_powerup_wav
  dc.w       f002_dat_powerup_wav_length_in_words
  dc.w       f002_dat_powerup_wav_period_pal
  dc.w       64
  dc.b       -1
  dc.b       64
