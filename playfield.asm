                section       PlayfieldCode,code
  
                include       "constants.i"

; initializes playfield before first frame
                xdef          pf_init
pf_init:
                move.l        ig_om_level_warp(a4),d0
                jsr           level_warp_playfield

                bsr.s         .init_scroll_vars
                bsr           pf_set_scroll_vars_in_coplist
                bsr.s         .init_screen_buffer

                rts

; inits scrolling vars
.init_scroll_vars:
; initial absolute x position in level
                bset          #IgPerformScroll,ig_om_bools(a4)
                bset          #IgDrawTiles,ig_om_bools(a4)

; initial bitplane pointer offsets
; -2 bytes, because scroll routine adds 2 bytes when reaching exact word boundary
                moveq.l       #-2,d0

                move.l        a4,a0
                add.l         #ig_om_bpl_offsets,a0
                moveq.l       #ScreenBitPlanes-1,d7
.isv_bpl_loop:
                move.l        d0,(a0)+
                add.l         #LevelScreenBufferWidthBytes,d0
                dbf           d7,.isv_bpl_loop

; stop-conditions for scrolling and tile-drawing
                move.l        #m_om_area+ig_om_f003+f003_dat_level1_tmx+f003_dat_level1_tmx_size,ig_om_max_tile_offset(a4)
                move.l        #(f003_dat_level1_tmx_tiles_width*TilePixelWidth)-ScreenWidth,ig_om_max_scroll_xpos(a4)

                rts

; draw first 21 columns of level to screen buffer
.init_screen_buffer:
                WAIT_BLT
                BLT_AD_CPY    LevelScreenBufferWidthBytes
; a0 = start of tiles in chip mem,  a1 = start of offset table, a2 = start of target buffer in chip mem
                lea.l         m_cm_area+ig_cm_f002+f002_dat_tiles_iff,a0
                move.l        ig_om_next_tile_offset(a4),.local_next_tile_offset
; first buffer
                move.l        .local_next_tile_offset,a1
                lea.l         m_cm_area+ig_cm_screenbuffer0,a2
                bsr.s         .draw_to_buffer
; second buffer
                move.l        .local_next_tile_offset,a1
                lea.l         m_cm_area+ig_cm_screenbuffer1,a2
                bsr.s         .draw_to_buffer
; third buffer
                move.l        .local_next_tile_offset,a1
                lea.l         m_cm_area+ig_cm_screenbuffer2,a2
                bsr.s         .draw_to_buffer

                rts
.local_next_tile_offset:
                dc.l          0
 
.draw_to_buffer
                move.l        a2,d1
                move.l        a2,d5
; draw 21 columns
                move.w        #20,d6
.isb_loop:
; column contains 16 tiles
                move.w        #15,d7
.isb_column_loop:
; calc source pointer
                move.l        a0,a3
                moveq.l       #0,d0
                move.w        (a1)+,d0
                add.l         d0,a3
; wait for blitter to be ready before first write to blitter register in loop
                WAIT_BLT
; set source pointer
                move.l        a3,BLTAPTH(a6)
; set and increment target pointer
                move.l        a2,BLTDPTH(a6)
                add.l         #LevelScreenBufferWidthBytes*ScreenBitPlanes*TilePixelHeight,a2
; copy tile (16 px * 4 bpls as height and 1 word aka 16 px as width)
                move.w        #TileAdCopyBltSize,BLTSIZE(a6)
                dbf           d7,.isb_column_loop
; next column
                addq.l        #2,d5
                move.l        d5,a2
                dbf           d6,.isb_loop

; save pointer to next tile offset and screenbuffer offset where it needs to be drawn
                move.l        a1,ig_om_next_tile_offset(a4)
                sub.l         d1,d5
                move.l        d5,ig_om_next_tile_col_right(a4)
                moveq.l       #-2,d7
                move.l        d7,ig_om_next_tile_col_left(a4)

                rts

                xdef          pf_scroll
; performs scrolling every frame
pf_scroll:
                btst          #IgDrawTiles,ig_om_bools(a4)
                beq.s         .ps_do_scroll
                bsr           pf_draw_next_tiles
.ps_do_scroll:
                btst          #IgPerformScroll,ig_om_bools(a4)
                beq.s         .ps_no_update_xpos
                bsr.s         .ps_update_xpos
                bra.s         pf_set_scroll_vars_in_coplist
.ps_no_update_xpos:
                ; just switch buffers
                lea.l         ig_cop_scroll,a0
                lea.l         ig_om_bpl_offsets(a4),a1
                move.l        ig_om_frame_counter(a4),d1
                bra           pf_update_copperlist
 
; checks, if further scrolling is possible and if so, scrolls playfield by 1 pixel
.ps_update_xpos:
                moveq.l       #1,d1
                ; xpos in framebuffer
                add.w         d1,ig_om_scroll_xpos_frbuf(a4)
                ; absolute xpos in level
                move.l        ig_om_scroll_xpos(a4),d0
                add.l         d1,d0
                move.l        d0,ig_om_scroll_xpos(a4)
                cmp.l         ig_om_max_scroll_xpos(a4),d0
                bne.s         .pux_exit
                bclr          #IgPerformScroll,ig_om_bools(a4)
.pux_exit:
                rts

; Sets registers needed for scrolling in the copperlist
pf_set_scroll_vars_in_coplist:
                move.l        ig_om_scroll_xpos(a4),d0
                lea.l         ig_om_bpl_offsets(a4),a1
; test for word-boundary
                and.l         #$f,d0
                tst.b         d0
                bne.s         .pssv_no_reset

; exact word boundary reached!
; inc all bitplane pointer offsets by 2
                moveq.l       #ScreenBitPlanes-1,d7
.pssv_inc_bplptr:
                move.l        (a1),d1
                addq.l        #2,d1
                move.l        d1,(a1)+
                dbf           d7,.pssv_inc_bplptr

; when right border of screenbuffer is exceeded, reset to beginning of screenbuffer
                lea.l         ig_om_bpl_offsets(a4),a1
                move.l        #LevelScreenBufferWidthBytes-ScreenWidthBytes-2,d2
                move.l        (a1),d3
                cmp.l         d2,d3
                ble.s         .pssv_no_reset
                clr.w         ig_om_scroll_xpos_frbuf(a4)
                moveq.l       #0,d2
                move.l        a1,a2
                moveq.l       #ScreenBitPlanes-1,d7
.pssv_reset_loop:
                move.l        d2,(a2)+
                add.l         #LevelScreenBufferWidthBytes,d2
                dbf           d7,.pssv_reset_loop

; reset col pointers
                move.l        #ScreenWidthBytes,ig_om_next_tile_col_right(a4)                                                 ; not +2, because offset gets incremented by 2 before used
                moveq.l       #-4,d7                                                                                          ; -2 to indicate, it is the part left of the screenbuffer; another -2, because offset gets incremented by 2 before used
                move.l        d7,ig_om_next_tile_col_left(a4)

; set bitplane pointers for playfield
.pssv_no_reset:
                lea.l         ig_cop_scroll,a0
                lea.l         ig_om_bpl_offsets(a4),a1
                move.l        ig_om_frame_counter(a4),d1
                bsr.s         pf_update_copperlist

; again check for word boundary
                tst.b         d0
                bne.s         .pssv_odd

; exact word boundary - inc pointer to next column
                move.l        ig_om_next_tile_col_left(a4),d0
                addq.l        #TileWidthBytes,d0
                move.l        d0,ig_om_next_tile_col_left(a4)

                move.l        ig_om_next_tile_col_right(a4),d0
                addq.l        #TileWidthBytes,d0
                move.l        d0,ig_om_next_tile_col_right(a4)

                rts

; no exact word boundary - just shift by one pixel
.pssv_odd:
                subq.l        #1,d0
                lsl.l         #1,d0
                lea.l         .pssv_bplcon1(pc),a1
                add.l         d0,a1
                move.w        (a1),2(a0)                                                                                      ; BPLCON1
                move.w        #LevelScreenBufferWidthBytes*ScreenBitPlanes-ScreenWidthBytes-2,d1
                move.w        d1,6(a0)                                                                                        ; BPL1MOD
                move.w        d1,10(a0)                                                                                       ; BPL2MOD
                move.w        #((ScreenStartX-16)/2-DdfResolution),14(a0)                                                     ; DDFSTRT

                rts

.pssv_bplcon1:  dc.w          $00ff,$00ee,$00dd,$00cc,$00bb,$00aa,$0099,$0088
                dc.w          $0077,$0066,$0055,$0044,$0033,$0022,$0011

; switches buffers and updates copperlist accordingly
; a0   - copperlist area with setting of scroll registers (BPLCON1...)
; a1   - list of bitplane pointer offsets
; d1   - counter indicating odd or even frame
pf_update_copperlist:
                lea.l         ig_cop_bplpt,a2
                btst          #0,d1
                bne.s         .1
                move.l        #ig_cm_screenbuffer0+m_cm_area,d2
                bra.s         .2
.1:
                move.l        #ig_cm_screenbuffer1+m_cm_area,d2
.2:
                moveq.l       #ScreenBitPlanes-1,d7
.puc_loop:
                move.l        (a1)+,d1
                add.l         d2,d1
                swap          d1
                move.w        d1,2(a2)
                swap          d1
                move.w        d1,6(a2)
                addq.l        #8,a2
                dbf           d7,.puc_loop

                clr.w         2(a0)                                                                                           ; BPLCON1
                move.w        #LevelScreenBufferWidthBytes*ScreenBitPlanes-ScreenWidthBytes,d1
                move.w        d1,6(a0)                                                                                        ; BPL1MOD
                move.w        d1,10(a0)                                                                                       ; BPL1MOD
                move.w        #(ScreenStartX/2-DdfResolution),14(a0)                                                          ; DDFSTRT

                rts

; draws next tiles to screen buffers (called every frame)
pf_draw_next_tiles:
; calc offset of row in screenbuffer-column, where next tile has to be drawn
                move.l        ig_om_scroll_xpos(a4),d0
                and.l         #$f,d0
                lsl.l         #2,d0
                lea.l         .pdnt_row_offsets(pc),a0
                move.l        (a0,d0),d1
; d1 = offset of row in screenbuffer

; calc source pointer of tile
                move.l        ig_om_next_tile_offset(a4),a0
                moveq.l       #0,d2
                move.w        (a0),d2
                add.l         #m_cm_area+ig_cm_f002+f002_dat_tiles_iff,d2
; d2 = pointer to tile (source for blit)

; check if tile right of visible area needs to be drawn
                move.l        ig_om_next_tile_col_right(a4),d3
                cmp.w         #LevelScreenBufferWidthBytes-2,d3
                bgt.s         .pdnt_draw_left_of_visible_area
                bsr.s         .pdnt_blit_tile

.pdnt_draw_left_of_visible_area:
; check if left of visible area needs to be drawn
                move.l        ig_om_next_tile_col_left(a4),d3
                tst.l         d3
                blt.s         .pdnt_done
                bsr.s         .pdnt_blit_tile

.pdnt_done:
; switch to next tile for next upcoming frame
                addq.l        #2,a0
                move.l        a0,ig_om_next_tile_offset(a4)
; test for end of level data
                move.l        ig_om_max_tile_offset(a4),a1
                cmp.l         a0,a1
                bne.s         .pdnt_continue_scrolling
                bclr          #IgDrawTiles,ig_om_bools(a4)

.pdnt_continue_scrolling
                rts

; d1 = offset of row in screenbuffer
; d2 = pointer to tile (source for blit)
; d3 = offset to column in screenbuffer
.pdnt_blit_tile:
                move.l        d3,d4
; first buffer
                add.l         #m_cm_area+ig_cm_screenbuffer0,d3
                bsr.s         .pdnt_blit_tile_sub
; second buffer
                move.l        d4,d3
                add.l         #m_cm_area+ig_cm_screenbuffer1,d3
                bsr.s         .pdnt_blit_tile_sub
; third buffer
                move.l        d4,d3
                add.l         #m_cm_area+ig_cm_screenbuffer2,d3

.pdnt_blit_tile_sub:
                add.l         d1,d3
                WAIT_BLT
                BLT_AD_CPY    LevelScreenBufferWidthBytes
                move.l        d2,BLTAPTH(a6)
                move.l        d3,BLTDPTH(a6)
                move.w        #TileAdCopyBltSize,BLTSIZE(a6)
                rts

.pdnt_row_offsets:
                dc.l          LevelScreenBufferWidthBytes*ScreenBitPlanes*TilePixelHeight*0
                dc.l          LevelScreenBufferWidthBytes*ScreenBitPlanes*TilePixelHeight*1
                dc.l          LevelScreenBufferWidthBytes*ScreenBitPlanes*TilePixelHeight*2
                dc.l          LevelScreenBufferWidthBytes*ScreenBitPlanes*TilePixelHeight*3
                dc.l          LevelScreenBufferWidthBytes*ScreenBitPlanes*TilePixelHeight*4
                dc.l          LevelScreenBufferWidthBytes*ScreenBitPlanes*TilePixelHeight*5
                dc.l          LevelScreenBufferWidthBytes*ScreenBitPlanes*TilePixelHeight*6
                dc.l          LevelScreenBufferWidthBytes*ScreenBitPlanes*TilePixelHeight*7
                dc.l          LevelScreenBufferWidthBytes*ScreenBitPlanes*TilePixelHeight*8
                dc.l          LevelScreenBufferWidthBytes*ScreenBitPlanes*TilePixelHeight*9
                dc.l          LevelScreenBufferWidthBytes*ScreenBitPlanes*TilePixelHeight*10
                dc.l          LevelScreenBufferWidthBytes*ScreenBitPlanes*TilePixelHeight*11
                dc.l          LevelScreenBufferWidthBytes*ScreenBitPlanes*TilePixelHeight*12
                dc.l          LevelScreenBufferWidthBytes*ScreenBitPlanes*TilePixelHeight*13
                dc.l          LevelScreenBufferWidthBytes*ScreenBitPlanes*TilePixelHeight*14
                dc.l          LevelScreenBufferWidthBytes*ScreenBitPlanes*TilePixelHeight*15
