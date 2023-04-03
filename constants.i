                               ifnd       CONSTANTS_I
CONSTANTS_I                 equ 1
                               include    "files_index.i"

; intreq
Level3Handler               equ $6c

; exec.library
ExecBase                    equ $4
OpenLibrary                 equ -$198
CloseLibrary                equ -$19e

; graphics.library
CurrentView                 equ $22
CurrentCopper               equ $26
LoadView                    equ -$de

; dos.library
AccessRead                  equ -2
ModeOldfile                 equ 1005
Open                        equ -$1e
Close                       equ -$24
Read                        equ -$2a
Lock                        equ -$54
UnLock                      equ -$5a
CurrentDir                  equ -$7e

; I/O
CIAAPRA                     equ $bfe001
LeftMouseButton             equ $6                                                         ; Mouse in Port 0
FireButton                  equ $7                                                         ; Joystick in Port 1

; Custom Chips
CustomBase                  equ $dff000
DMACONR                     equ $2
VPOSR                       equ $4
VHPOSR                      equ $6
JOY1DAT                     equ $c
CLXDAT                      equ $e
ADKCONR                     equ $10
INTENAR                     equ $1c
INTREQR                     equ $1e
BLTCON0                     equ $40
BLTCON1                     equ $42
BLTAFWM                     equ $44
BLTALWM                     equ $46
BLTCPTH                     equ $48
BLTCPTL                     equ $4a
BLTBPTH                     equ $4c
BLTBPTL                     equ $4e
BLTAPTH                     equ $50
BLTAPTL                     equ $52
BLTDPTH                     equ $54
BLTDPTL                     equ $56
BLTSIZE                     equ $58
BLTCMOD                     equ $60
BLTBMOD                     equ $62
BLTAMOD                     equ $64
BLTDMOD                     equ $66
COP1LC                      equ $80
COP2LC                      equ $84
DIWSTRT                     equ $8e
DIWSTOP                     equ $90
DDFSTRT                     equ $92
DDFSTOP                     equ $94
DMACON                      equ $96
CLXCON                      equ $98
INTENA                      equ $9a
INTREQ                      equ $9c
ADKCON                      equ $9e
BPL1PTH                     equ $e0
BPL1PTL                     equ $e2
BPL2PTH                     equ $e4
BPL2PTL                     equ $e6
BPL3PTH                     equ $e8
BPL3PTL                     equ $ea
BPL4PTH                     equ $ec
BPL4PTL                     equ $ee
BPL5PTH                     equ $f0
BPL5PTL                     equ $f2
BPL6PTH                     equ $f4
BPL6PTL                     equ $f6
BPLCON0                     equ $100
BPLCON1                     equ $102
BPLCON2                     equ $104
BPL1MOD                     equ $108
BPL2MOD                     equ $10a
SPR0PTH                     equ $120
SPR0PTL                     equ $122
SPR1PTH                     equ $124
SPR1PTL                     equ $126
SPR2PTH                     equ $128
SPR2PTL                     equ $12a
SPR3PTH                     equ $12c
SPR3PTL                     equ $12e
SPR4PTH                     equ $130
SPR4PTL                     equ $132
SPR5PTH                     equ $134
SPR5PTL                     equ $136
SPR6PTH                     equ $138
SPR6PTL                     equ $13a
SPR7PTH                     equ $13c
SPR7PTL                     equ $13e
SPR0POS                     equ $140
SPR0CTL                     equ $142
SPR1POS                     equ $148
SPR1CTL                     equ $14a
SPR2POS                     equ $150
SPR2CTL                     equ $152
SPR3POS                     equ $158
SPR3CTL                     equ $15a
SPR4POS                     equ $160
SPR4CTL                     equ $162
SPR5POS                     equ $168
SPR5CTL                     equ $16a
SPR6POS                     equ $170
SPR6CTL                     equ $172
SPR7POS                     equ $178
SPR7CTL                     equ $17a
COLOR00                     equ $180
COLOR01                     equ $182
COLOR02                     equ $184
COLOR03                     equ $186
COLOR04                     equ $188
COLOR05                     equ $18a
COLOR06                     equ $18c
COLOR07                     equ $18e
COLOR08                     equ $190
COLOR09                     equ $192
COLOR10                     equ $194
COLOR11                     equ $196
COLOR12                     equ $198
COLOR13                     equ $19a
COLOR14                     equ $19c
COLOR15                     equ $19e
COLOR16                     equ $1a0
COLOR17                     equ $1a2
COLOR18                     equ $1a4
COLOR19                     equ $1a6
COLOR20                     equ $1a8
COLOR21                     equ $1aa
COLOR22                     equ $1ac
COLOR23                     equ $1ae
COLOR24                     equ $1b0
COLOR25                     equ $1b2
COLOR26                     equ $1b4
COLOR27                     equ $1b6
COLOR28                     equ $1b8
COLOR29                     equ $1ba
COLOR30                     equ $1bc
COLOR31                     equ $1be

; Custom Chip Bits
BplColorOn                  equ $200
DdfResolution               equ 8                                                          ; 8=narrow, 4=wide

; Screen
ScreenBitPlanes             equ 4
ScreenWidth                 equ 320
ScreenWidthBytes            equ (ScreenWidth/8)
ScreenHeight                equ 256
ScreenStartX                equ $81                                                        ; magic value from hardware manual
ScreenStartY                equ $2c                                                        ; magic value from hardware manual
ScreenStopX                 equ ScreenStartX+ScreenWidth
ScreenStopY                 equ ScreenStartY+ScreenHeight
ScreenRowSize               equ ScreenWidthBytes*ScreenBitPlanes*16                        ; Size in bytes of one tile-row on screen

; Screen buffer
LevelScreenBufferWidth      equ 672
LevelScreenBufferWidthBytes equ (LevelScreenBufferWidth/8)
LevelScreenBufferHeight     equ 256
LevelScreenBufferSize       equ LevelScreenBufferWidthBytes*ScreenBitPlanes*LevelScreenBufferHeight

; Tiles
TilesBitplanes              equ 4
TilesColors                 equ 16
TilesWidth                  equ 320
TilesWidthBytes             equ (TilesWidth/8)
TilesHeight                 equ 256
TilesByteSize               equ (TilesWidthBytes*TilesBitplanes*TilesHeight)
TilePixelWidth              equ 16
TilePixelHeight             equ 16
TileWidthBytes              equ TilePixelWidth/8
TileAdCopyBltSize           equ (TilePixelHeight*ScreenBitPlanes<<6)+1

; Starfield (ingame-background)
NumberOfStars               equ 60                                                         ; was 120
LineOfFirstStar             equ $35
LineAdd                     equ 4                                                          ; was 2

; bits of joystick state (returned by joystick.asm -> js_read)
; 1 = yes, 0 = no
JsUp                        equ 0
JsDown                      equ 1
JsLeft                      equ 2
JsRight                     equ 3
JsFire                      equ 4

; Code in-/Excludes
SHOW_BLUE_TIMING            equ 0
SHOW_FREE_RAM               equ 0
SHOW_COLLISION_RED          equ 0

; Structures

; Player
                               rsreset
pl_xpos:                       rs.w       1                                                ; x-position on screen (hardware coordinates)
pl_ypos:                       rs.w       1                                                ; y-position on screen (hardware coordinates)
pl_anim:                       rs.l       1                                                ; points to tiled-values for animstep offsets
pl_animstep:                   rs.b       1                                                ; actual animstep (0 - ..)
pl_max_animstep:               rs.b       1                                                ; max animstep (1 - ..)
pl_frames_till_next_shot:      rs.b       1                                                ; frames until next shot can be fired (0 - pl_shot_delay)
pl_padding_byte                rs.b       1
pl_size:                       rs.b       0
pl_shot_delay               equ 16                                                         ; minimum frames between two shots fired

; General OtherMem (MUST always be included at the beginning of EVERY OtherMem-structure)
                               rsreset
g_om_bools:                    rs.b       1
g_om_lives:                    rs.b       1
g_om_level:                    rs.b       1                                                ; 0 = mainmenu, 1 = level 1 etc.
g_om_padding_byte:             rs.b       1
g_om_score:                    rs.l       1
g_om_fade_fi_ptr:              rs.l       1                                                ; fade-in pointer
g_om_fade_fo_ptr:              rs.l       1                                                ; fade-out pointer
g_om_fade_counter:             rs.b       1                                                ; valid values 0-15, 0 means fading is done
g_om_fade_interval:            rs.b       1                                                ; update fading every n-th frame
g_om_fade_act_intvl:           rs.b       1                                                ; actual countdown for next interval
g_om_fade_padding_byte:        rs.b       1
g_om_size:                     rs.b       0
; bits for g_om_bools
GExit                       equ 0                                                          ; exit game completely? 0 = nope
GFadeIn                     equ 1                                                          ; should we fade in? 0 = nope
GFadeOut                    equ 2                                                          ; should we fade out? 0 = nope


; InGame ChipMem
                               rsreset
ig_cm_player:                  rs.b       (8*16)+16                                        ; sprites 0 and 1 (attached) display the 16x16 pix player sprite
ig_cm_sprite2_panel:           rs.b       (8*4)+8                                          ; panel sprite data for sprite 2
ig_cm_sprite3_panel:           rs.b       (8*4)+8                                          ; panel sprite data for sprite 3
ig_cm_sprite4_panel:           rs.b       (8*4)+4                                          ; panel sprite data for sprite 4
ig_cm_sprite4_starfield:       rs.b       (NumberOfStars*8)+4                              ; sprites 4 and 5 (attached) displaying the stars in the background (8 because of 1 line with sprite per Star, giving 2 control-words and 2 bitplane-words, plus 4 bytes for end-of-sprite-list)
ig_cm_sprite5_panel:           rs.b       (8*4)+4                                          ; panel sprite data for sprite 5
ig_cm_sprite5_starfield:       rs.b       (NumberOfStars*8)+4                              ; sprites 4 and 5 (attached) displaying the stars in the background (8 because of 1 line with sprite per Star, giving 2 control-words and 2 bitplane-words, plus 4 bytes for end-of-sprite-list)
ig_cm_f002:                    rs.b       f002_size
ig_cm_screenbuffer0:           rs.b       LevelScreenBufferSize
ig_cm_screenbuffer1:           rs.b       LevelScreenBufferSize
ig_cm_screenbuffer2:           rs.b       LevelScreenBufferSize
ig_cm_size:                    rs.b       0

; InGame OtherMem
                               rsreset
ig_om_general:                 rs.b       g_om_size
ig_om_frame_counter            rs.l       1                                                ; counts every ingame frame, can be used for different features
ig_om_scroll_xpos_frbuf:       rs.w       1                                                ; x position in framebuffer
ig_om_scroll_xpos:             rs.l       1                                                ; absolute x position in level
ig_om_max_scroll_xpos:         rs.l       1                                                ; max x position in level due to level width
ig_om_bpl_offsets:             rs.l       ScreenBitPlanes                                  ; bitplane pointer offsets for scrolling
ig_om_next_tile_offset:        rs.l       1                                                ; pointer to next tile offset to be drawn to screenbuffer
ig_om_max_tile_offset:         rs.l       1                                                ; pointer to first not-tile-offset word (behind tile-offset-data)
ig_om_next_tile_col_left:      rs.l       1                                                ; offset-pointer to column of screenbuffer where next tiles have to be drawn to the left of visible area
ig_om_next_tile_col_right:     rs.l       1                                                ; offset-pointer to column of screenbuffer where next tiles have to be drawn to the right of visible area
ig_om_bools:                   rs.b       1
ig_om_padding_byte:            rs.b       1
ig_om_player                   rs.b       pl_size
ig_om_starfield:               rs.l       NumberOfStars                                    ; first word contains x-pos, second word contains value that is subtracted each frame
ig_om_f003:                    rs.b       f003_size
ig_om_size:                    rs.b       0

; bits for ig_om_bools
IgExit                      equ 0                                                          ; shall we exit? 0 = nope
IgPerformScroll             equ 1                                                          ; perform scrolling? 0 = nope
IgDrawTiles                 equ 2                                                          ; draw tiles for scrolling? 0 = nope
IgPlayerDead                equ 3                                                          ; has player died? 0 = nope

; MainMenu ChipMem
                               rsreset
mm_cm_f000:                    rs.b       f000_size
mm_cm_screenbuffer             rs.b       ScreenWidthBytes*ScreenBitPlanes*ScreenHeight
mm_cm_size                     rs.b       0

; MainMenu OtherMem
                               rsreset
mm_om_general:                 rs.b       g_om_size
mm_om_option:                  rs.b       1                                                ; option selected by player
mm_om_lightning_anim_step:     rs.b       1                                                ; actual anim step (0 - (f001_dat_mm_lightning_anim_tmx_tiles_height-1))
mm_om_lightning_anim_delay:    rs.b       1                                                ; delay till next anim step (countdown to zero)
mm_om_displayed_credits:       rs.b       1                                                ; 0-2
mm_om_credits_delay:           rs.w       1                                                ; frames till next credits-switch
mm_om_lightning_anim_offsets:  rs.l       f001_dat_mm_lightning_anim_tmx_tiles_height      ; offset pointers to anim steps for lightning
mm_om_f001:                    rs.b       f001_size
mm_om_size:                    rs.b       0

; values for mm_om_option
MmOptionStart               equ 1
MmOptionExit                equ 2
; delay for lightning anim
MmLightningAnimDelay        equ 2
; delay for switching the credits
MmCreditSwitchDelay         equ 300

; endif for 'ifnd CONSTANTS_I'
                               endif

;
; General purpose macros
;

; Waits vor vertical blank period
; uses d0
WAIT_VB                        macro
.1\@:                          move.l     VPOSR(a6),d0
                               and.l      #$1ff00,d0
                               cmp.l      #303<<8,d0
                               bne.s      .1\@
                               endm
; waits for two vbp's - may be necessary when screen was/is in interlaced mode (then there are two different frames with two different copperlists)
; uses d0
WAIT_VB2                       macro
.1\@:                          move.l     VPOSR(a6),d0
                               and.l      #$1ff00,d0
                               cmp.l      #304<<8,d0
                               bne.s      .1\@
.2\@:                          move.l     VPOSR(a6),d0
                               and.l      #$1ff00,d0
                               cmp.l      #303<<8,d0
                               bne.s      .2\@
                               endm

; Waits for the blitter to be ready
WAIT_BLT                       macro
; tst for compatibility with A1000 with first Agnus revision
                               tst.w      DMACONR(a6)
.1\@:
                               btst       #6,DMACONR(a6)
                               bne.s      .1\@
                               endm

; Set base pointers
; sets a4-a6
SET_PTRS                       macro
                               lea.l      CustomBase,a6
                               lea.l      m_cm_area,a5
                               lea.l      m_om_area,a4
                               endm

; Inits blitter for simple A->D copy of a tile to a buffer
; \1 - width of the target buffer in bytes
; uses d0
BLT_AD_CPY                     macro
; simple A -> D copy, no shifting
                               move.w     #%0000100111110000,BLTCON0(a6)
                               clr.w      BLTCON1(a6)
; no first/last word mask
                               move.w     #$ffff,d0
                               move.w     d0,BLTAFWM(a6)
                               move.w     d0,BLTALWM(a6)
; modulos for source and target
                               move.w     #TilesWidthBytes-2,BLTAMOD(a6)
                               move.w     #\1-2,BLTDMOD(a6)
                               endm

; Inits module, sets music volume to half (so sfx can be heard better) 
; and returns from subroutine (so should be called in a subroutine ;-)
; uses d0
PTP_INIT                       macro
                               moveq.l    #0,d0
                               jsr        _mt_init
                               move.w     #32,d0
                               jmp        _mt_mastervol
                               endm