                  section    DosCode,code
              
                  include    "constants.i"

                  xdef       dos_init
dos_init:
                  movem.l    d0-d7/a0-a6,-(sp)
; open dos.library
                  move.l     ExecBase,a6
                  lea.l      dos_name(pc),a1
                  moveq.l    #0,d0
                  jsr        OpenLibrary(a6)
                  move.l     d0,dos_base
                  move.l     d0,a6

; output info about available memory to cli (DOS-Write does NOT work in debug mode, because DOS-Output returns zero)
                  ifne       SHOW_FREE_RAM
                  bra        .1

MEMF_CHIP    equ 1<<1
MEMF_FAST    equ 1<<2
MEMF_LARGEST equ 1<<17
Output       equ -$3c
Write        equ -$30
AvailMem     equ -$d8

.s1:              dc.b       10,10,"Available Chip:  ",0
.e1:              even
.s2:              dc.b       10,"Largest Chip:    ",0
.e2:              even
.s3:              dc.b       10,"Available Other: ",0
.e3:              even
.s4:              dc.b       10,"Largest Other:   ",0
.e4:              even
.s5:              dc.b       10,10,0
.e5:              even
.s6:              dc.b       0,0,0,0,0,0,0,0,10,0
.e6:              even

; d1 - ram type
.print_ram:
                  move.l     ExecBase,a6
                  jsr        AvailMem(a6)
                  move.l     #$f0000000,d6                  ; mask
                  move.l     #28,d5                         ; shift bits
                  lea.l      .s6(pc),a0                     ; target buffer
                  moveq.l    #7,d7                          ; 8 nibbles
.convert_loop:    move.l     d0,d1
                  and.l      d6,d1
                  lsr.l      d5,d1
                  add.b      #$30,d1
                  cmp.b      #$3a,d1                        ; was it a digit?
                  bcs.s      .cl1
                  add.b      #$07,d1                        ; was a letter (a-f), so add another $07
.cl1:
                  move.b     d1,(a0)+
                  subq.l     #4,d5
                  lsr.l      #4,d6
                  dbf        d7,.convert_loop

                  move.l     #.s6,d2
                  move.l     #.e6-.s6,d3

; d2 - begin of string
; d3 - length of string
.print:
                  move.l     dos_base(pc),a6
                  jsr        Output(a6)
                  move.l     d0,d1
                  jsr        Write(a6)
                  rts
 
.1:
                  move.l     #.s1,d2
                  move.l     #.e1-.s1,d3
                  bsr.s      .print

                  move.l     #MEMF_CHIP,d1
                  bsr.s      .print_ram
                  
                  move.l     #.s2,d2
                  move.l     #.e2-.s2,d3
                  bsr.s      .print
                  
                  move.l     #MEMF_CHIP|MEMF_LARGEST,d1
                  bsr.s      .print_ram
                  
                  move.l     #.s3,d2
                  move.l     #.e3-.s3,d3
                  bsr.s      .print
                  
                  move.l     #MEMF_FAST,d1
                  bsr.s      .print_ram
                  
                  move.l     #.s4,d2
                  move.l     #.e4-.s4,d3
                  bsr.s      .print
                  
                  move.l     #MEMF_FAST|MEMF_LARGEST,d1
                  bsr        .print_ram
                  
                  move.l     #.s5,d2
                  move.l     #.e5-.s5,d3
                  bsr.s      .print
                  
                  endif  

                  ifd        DEBUG
; debug-launcher uses dh0: for executable, so we need to set current directory
; lock dh0:
                  move.l     #dos_dh0_name,d1
                  move.l     #AccessRead,d2
                  jsr        Lock(a6)
                  move.l     d0,dos_dh0_lock

; set current directory to dh0:
                  move.l     d0,d1
                  jsr        CurrentDir(a6)
                  move.l     d0,dos_old_curdir
                  endif

                  movem.l    (sp)+,d0-d7/a0-a6
                  rts

; Reads file from disk
; d5 = filename
; d6 = target location
; d7 = no. of bytes
                  xdef       dos_readfile
dos_readfile: 
                  movem.l    d0-d7/a0-a6,-(sp)
; open file for read
                  move.l     d5,d1
                  move.l     #ModeOldfile,d2
                  move.l     dos_base(pc),a6
                  jsr        Open(a6)
                  move.l     d0,dos_file_handle

; read data from file
                  move.l     dos_file_handle(pc),d1
                  move.l     d6,d2
                  move.l     d7,d3
                  jsr        Read(a6)

; close file
                  move.l     dos_file_handle(pc),d1
                  jsr        Close(a6)

                  movem.l    (sp)+,d0-d7/a0-a6
                  rts

                  xdef       dos_cleanup
dos_cleanup:
                  movem.l    d0-d7/a0-a6,-(sp)
                  ifd        DEBUG
; reset current directory
                  move.l     dos_base(pc),a6
                  move.l     dos_old_curdir(pc),d1
                  jsr        CurrentDir(a6)

; unlock DH0:
                  move.l     dos_dh0_lock(pc),d1
                  jsr        UnLock(a6)
                  endif

; close dos.library
                  move.l     ExecBase,a6
                  move.l     dos_base(pc),a1
                  jsr        CloseLibrary(a6)

                  movem.l    (sp)+,d0-d7/a0-a6
                  rts

dos_name:         dc.b       "dos.library",0
                  even
dos_base:         dc.l       0
dos_file_handle:  dc.l       0

                  ifd        DEBUG
dos_dh0_name:     dc.b       "dh0:",0
                  even
dos_dh0_lock:     dc.l       0
dos_old_curdir:   dc.l       0
                  endif
