# Neon-World (Shoot-em-up hobby-project for the Amiga)

## Motivation

After 30 years of not-assembly-coding I wanted to start a small project for my beloved Amiga 500.  
Because many games did not use the full PAL resolution (320x256), I wanted to try exactly this.  

## Development environment

Visual Studio Code with Amiga Assembly plugin.  
FS-UAE (for running/debugging)  

Additional plugins for the data converting tools:  
Language Support for Java  
Extension Pack for Java  
Debugger for Java  

## Test systems

The game is tested using FS-UAE (v3.1.66) and vAmiga (v2.3) on macOS.  
Also tested on my Amiga 500 (rev. 6a) using Kickstart 1.3 and 2.0 with 1 MB Chip-RAM and 1,5 MB Slow-RAM.  

## Target systems

Should run on any PAL-Amiga with at least 512kb Chip-RAM.  
When using Kickstart v2.x or higher and/or external floppy drives or hard drives are connected, additional 512 kb RAM of any type may be necessary.  
The game uses a DOS disk, so it should be no problem to install the game on a harddisk.  
When running the game in an emulator there could by some slight stuttering. This is a problem because of most modern systems having a framerate higher than 50Hz. The game runs at 50 Hz and on my Amiga 500 the scrolling and sprite movements are totally smooth.  

## Important note

Before program can be assembled and run you must run the Java class "Converter" found in "data/tools".  
It produces necessary asm and binary files from the source files of the various formats.

## Downloadable ADF

The ADF for download can be found [here](https://github.com/cobour/neon-world/releases).

## Music

Since my composing skills are absolutely zero the game uses music created by Krzysztof Odachowski.  
Find out more about him by visiting his [Bandcamp page](https://soundkiller.bandcamp.com).  
Learn more [in the data folder](/data/readme.md).  
What I like most about his music is the great qualitiy with minimal memory usage. Awesome tunes!  

## Graphics

Since my drawing skills are close to zero the game uses the wonderful NeonWorld-Tileset created by Kevin Saunders.  
You can find the graphics online [here](https://www.patreon.com/posts/neonworld-2020-42472876).  
Learn more [in the data folder](/data/readme.md).  
I like this tileset because it has everything you need on only one screen and uses only 16 colors. Amazing!  

## Sourcecode by other authors used in this project

**ptplayer.asm** (downloaded [here](https://aminet.net/package/mus/play/ptplayer) on 2022-11-20)  
The only change by me is that VBLANK_MUSIC is set to 1 and source is reformatted by Amiga Assembly (VSC plugin).

**inflate.asm** (downloaded [here](https://raw.githubusercontent.com/keirf/Amiga-Stuff/master/inflate/inflate.asm) on 2022-11-23)  
The only thing added by me is the "xdef inflate" directive and source is reformatted by Amiga Assembly (VSC plugin).
