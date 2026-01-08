I'm trying to reverse engineer NHLPA93 for Sega Genesis.

I'm going to give you:
- The NHL92 Genesis Frames.asm
- what I've reversed so far from NHLPA93 Genesis's Frames.asm (which is based off of an animation list I was able to pull from the PC version of NHL95)
- The NHL92 Genesis Frames.asm binary from the ROM
- The NHLPA93 Genesis Frames.asm binary from the ROM

I'd like you to reverse engineer NHLPA93's frames.asm and give me something that when compiled matches with the NHLPA93 Frames.asm binary from the ROM. I believe some names for animations may be missing-- try your best guess as to what they are (and maybe put in a comment that its a guess)

NHL92 Frames.asm:

;This is a data table for animating the graphics in Sprites.anim
;This list equates the sections of the alice animation file Sprites.anim

SPFskatewp	=	1
SPFskate	=	SPFskatewp+40
SPFturnl	=	SPFskate+40
SPFturnr	=	SPFturnl+8
SPFswing	=	SPFturnr+8
SPFstop	=	SPFswing+48
SPFskateb	=	SPFstop+16
SPFcelebrate	=	SPFskateb+24
SPFpump	=	SPFcelebrate+16
SPFcup	=	SPFpump+16
SPFhipl	=	SPFcup+8
SPFhipr	=	SPFhipl+8
SPFshoulderl	=	SPFhipr+8
SPFshoulderr	=	SPFshoulderl+8
SPFsweep	=	SPFshoulderr+8

SPFfallback	=	SPFsweep+16
SPFfallfwd	=	SPFfallback+32
SPFduck	=	SPFfallfwd+32
SPFHold	=	SPFduck+8

SPFgloves	=	SPFHold+8
SPFfight	=	SPFgloves+1
SPFPen	=	SPFfight+17

SPFarrow	=	SPFpen+7
SPFpad	=	SPFarrow+6
SPFpuck	=	SPFpad+3
SPFgoal	=	SPFpuck+11
SPFGoalie	=	SPFgoal+2
SPFLogos	=	SPFGoalie+80+32
SPFSiren	=	SPFLogos+24	

SPAlist
	dc.w	0

SPAgready	=	*-SPAlist	;goalie in ready position
SPAgready_table:
.t
	dc.w	.0-.t	;offset to each direction of animation (0-7)
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0	;flags for this animation

.a	=	SPFGoalie
.off	=	3
.0	dc.w	.a,-8	;frame,time  (last entry indicated by neg. time)
.a	set	.a+.off
.1	dc.w	.a,-8
.a	set	.a+.off
.2	dc.w	.a,-8
.a	set	.a+.off
.3	dc.w	.a,-8
.a	set	.a+.off
.4	dc.w	.a,-8
.a	set	.a+.off
.5	dc.w	.a,-8
.a	set	.a+.off
.6	dc.w	.a,-8
.a	set	.a+.off
.7	dc.w	.a,-8

SPAgglover	=	*-SPAlist	;goalie does glove save right
SPAgglover_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFGoalie+1
.off	=	3
.0	dc.w	.a,-32
.a	set	.a+.off
.1	dc.w	.a,-32
.a	set	.a+.off
.2	dc.w	.a,-32
.a	set	.a+.off
.3	dc.w	.a,-32
.a	set	.a+.off
.4	dc.w	.a,-32
.a	set	.a+.off
.5	dc.w	.a,-32
.a	set	.a+.off
.6	dc.w	.a,-32
.a	set	.a+.off
.7	dc.w	.a,-32

SPAgglovel	=	*-SPAlist	;goalie does glove save left
SPAgglovel_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFGoalie+2
.off	=	3
.0	dc.w	.a,-32
.a	set	.a+.off
.1	dc.w	.a,-32
.a	set	.a+.off
.2	dc.w	.a,-32
.a	set	.a+.off
.3	dc.w	.a,-32
.a	set	.a+.off
.4	dc.w	.a,-32
.a	set	.a+.off
.5	dc.w	.a,-32
.a	set	.a+.off
.6	dc.w	.a,-32
.a	set	.a+.off
.7	dc.w	.a,-32

SPAgstickr	=	*-SPAlist	;goalie stick save right
SPAgstickr_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFGoalie+64
.off	=	2
.0	dc.w	.a,-32
.a	set	.a+.off
.1	dc.w	.a,-32
.a	set	.a+.off
.2	dc.w	.a,-32
.a	set	.a+.off
.3	dc.w	.a,-32
.a	set	.a+.off
.4	dc.w	.a,-32
.a	set	.a+.off
.5	dc.w	.a,-32
.a	set	.a+.off
.6	dc.w	.a,-32
.a	set	.a+.off
.7	dc.w	.a,-32

SPAgstickl	=	*-SPAlist	;goalie stick save left
SPAgstickl_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFGoalie+65
.off	=	2
.0	dc.w	.a,-32
.a	set	.a+.off
.1	dc.w	.a,-32
.a	set	.a+.off
.2	dc.w	.a,-32
.a	set	.a+.off
.3	dc.w	.a,-32
.a	set	.a+.off
.4	dc.w	.a,-32
.a	set	.a+.off
.5	dc.w	.a,-32
.a	set	.a+.off
.6	dc.w	.a,-32
.a	set	.a+.off
.7	dc.w	.a,-32

SPAgstackr	=	*-SPAlist	;goalie stack right
SPAgstackr_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFGoalie+40
.off	=	2
.0	dc.w	.a,8,.a+1,-32
.a	set	.a+.off
.1	dc.w	.a,8,.a+1,-32
.2	dc.w	.a,8,.a+1,-32
.a	set	.a+.off
.3	dc.w	.a,8,.a+1,-32
.a	set	.a+.off
.4	dc.w	.a,8,.a+1,-32
.a	set	.a+.off
.5	dc.w	.a,8,.a+1,-32
.6	dc.w	.a,8,.a+1,-32
.a	set	.a+.off
.7	dc.w	.a,8,.a+1,-32

SPAgstackl	=	*-SPAlist	;goalie stack left
SPAgstackl_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFGoalie+52
.off	=	2
.0	dc.w	.a,8,.a+1,-32
.a	set	.a+.off
.1	dc.w	.a,8,.a+1,-32
.2	dc.w	.a,8,.a+1,-32
.a	set	.a+.off
.3	dc.w	.a,8,.a+1,-32
.a	set	.a+.off
.4	dc.w	.a,8,.a+1,-32
.a	set	.a+.off
.5	dc.w	.a,8,.a+1,-32
.6	dc.w	.a,8,.a+1,-32
.a	set	.a+.off
.7	dc.w	.a,8,.a+1,-32

SPAgswing	=	*-SPAlist	;goalie passes puck
SPAgswing_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFGoalie+24
.off	=	2
.0	dc.w	.a,5,.a+1,8,.a,-16
.a	set	.a+.off
.1	dc.w	.a,5,.a+1,8,.a,-16
.a	set	.a+.off
.2	dc.w	.a,5,.a+1,8,.a,-16
.a	set	.a+.off
.3	dc.w	.a,5,.a+1,8,.a,-16
.a	set	.a+.off
.4	dc.w	.a,5,.a+1,8,.a,-16
.a	set	.a+.off
.5	dc.w	.a,5,.a+1,8,.a,-16
.a	set	.a+.off
.6	dc.w	.a,5,.a+1,8,.a,-16
.a	set	.a+.off
.7	dc.w	.a,5,.a+1,8,.a,-16
	
SPAgskate	=	*-SPAlist	;goalie skates
SPAgskate_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	1<<0

.a	=	SPFGoalie+80
.off	=	4
.0	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-15
.a	set	.a+.off
.1	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-15
.a	set	.a+.off
.2	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-15
.a	set	.a+.off
.3	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-15
.a	set	.a+.off
.4	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-15
.a	set	.a+.off
.5	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-15
.a	set	.a+.off
.6	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-15
.a	set	.a+.off
.7	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-15

SPApflip	=	*-SPAlist	;puck animation
SPApflip_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	1<<0	;flag for repeat animation

.a	=	SPFpuck+1

.0	dc.w	.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,4,.a+2,4,.a+6,4,.a+0,-4
.1	dc.w	.a+8,2,.a+0,2,.a+7,2,.a+4,2,.a+9,2,.a+4,2,.a+7,2,.a+0,-2
.2	dc.w	.a+3,2,.a+2,2,.a+1,2,.a+0,2,.a+6,2,.a+2,2,.a+5,2,.a+4,-2
.3	dc.w	.a+7,4,.a+0,4,.a+8,4,.a+0,4,.a+7,4,.a+4,4,.a+9,4,.a+4,-4
.4	dc.w	.a+0,-$1000
.5	dc.w	.a+0,-$1000
.6	dc.w	.a+4,-$1000
.7	dc.w	.a+4,-$1000

SPAglide	=	*-SPAlist	;player gliding with stick down
SPAglide_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFskatewp
.off	=	5
.0	dc.w	.a,-8
.a	set	.a+.off
.1	dc.w	.a,-8
.a	set	.a+.off
.2	dc.w	.a,-8
.a	set	.a+.off
.3	dc.w	.a,-8
.a	set	.a+.off
.4	dc.w	.a,-8
.a	set	.a+.off
.5	dc.w	.a,-8
.a	set	.a+.off
.6	dc.w	.a,-8
.a	set	.a+.off
.7	dc.w	.a,-8

SPAskatewp	=	*-SPAlist	;player skating with stick down
SPAskatewp_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFskatewp
.off	=	5
.0	dc.w	.a+1,10,.a+2,10,.a+3,10,.a+4,10,.a,-15
.a	set	.a+.off
.1	dc.w	.a+1,10,.a+2,10,.a+3,10,.a+4,10,.a,-15
.a	set	.a+.off
.2	dc.w	.a+1,10,.a+2,10,.a+3,10,.a+4,10,.a,-15
.a	set	.a+.off
.3	dc.w	.a+1,10,.a+2,10,.a+3,10,.a+4,10,.a,-15
.a	set	.a+.off
.4	dc.w	.a+1,10,.a+2,10,.a+3,10,.a+4,10,.a,-15
.a	set	.a+.off
.5	dc.w	.a+1,10,.a+2,10,.a+3,10,.a+4,10,.a,-15
.a	set	.a+.off
.6	dc.w	.a+1,10,.a+2,10,.a+3,10,.a+4,10,.a,-15
.a	set	.a+.off
.7	dc.w	.a+1,10,.a+2,10,.a+3,10,.a+4,10,.a,-15

SPAskate	=	*-SPAlist	;player skating with stick up
SPAskate_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFskate
.off	=	5
.0	dc.w	.a+1,10,.a+2,10,.a+3,10,.a+4,10,.a+0,-15
.a	set	.a+.off
.1	dc.w	.a+1,10,.a+2,10,.a+3,10,.a+4,10,.a+0,-15
.a	set	.a+.off
.2	dc.w	.a+1,10,.a+2,10,.a+3,10,.a+4,10,.a+0,-15
.a	set	.a+.off
.3	dc.w	.a+1,10,.a+2,10,.a+3,10,.a+4,10,.a+0,-15
.a	set	.a+.off
.4	dc.w	.a+1,10,.a+2,10,.a+3,10,.a+4,10,.a+0,-15
.a	set	.a+.off
.5	dc.w	.a+1,10,.a+2,10,.a+3,10,.a+4,10,.a+0,-15
.a	set	.a+.off
.6	dc.w	.a+1,10,.a+2,10,.a+3,10,.a+4,10,.a+0,-15
.a	set	.a+.off
.7	dc.w	.a+1,10,.a+2,10,.a+3,10,.a+4,10,.a+0,-15

SPAturnl	=	*-SPAlist	;player turning left
SPAturnl_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFturnl
.0	dc.w	.a+0,-18
.1	dc.w	.a+1,-18
.2	dc.w	.a+2,-18
.3	dc.w	.a+3,-18
.4	dc.w	.a+4,-18
.5	dc.w	.a+5,-18
.6	dc.w	.a+6,-18
.7	dc.w	.a+7,-18

SPAturnr	=	*-SPAlist	;player turning right
SPAturnr_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFturnr
.0	dc.w	.a+0,-18
.1	dc.w	.a+1,-18
.2	dc.w	.a+2,-18
.3	dc.w	.a+3,-18
.4	dc.w	.a+4,-18
.5	dc.w	.a+5,-18
.6	dc.w	.a+6,-18
.7	dc.w	.a+7,-18

SPAstop	=	*-SPAlist	;player scrape stopping
SPAstop_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	1<<0	;repeating animation

.a	=	SPFstop
.off	=	2
.0	dc.w	.a+0,4,.a+1,-4
.a	set	.a+.off
.1	dc.w	.a+0,4,.a+1,-4
.a	set	.a+.off
.2	dc.w	.a+0,4,.a+1,-4
.a	set	.a+.off
.3	dc.w	.a+0,4,.a+1,-4
.a	set	.a+.off
.4	dc.w	.a+0,4,.a+1,-4
.a	set	.a+.off
.5	dc.w	.a+0,4,.a+1,-4
.a	set	.a+.off
.6	dc.w	.a+0,4,.a+1,-4
.a	set	.a+.off
.7	dc.w	.a+0,4,.a+1,-4

SPApassf	=	*-SPAlist	;forward pass swing
SPApassf_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFswing
.off	=	6
.0	dc.w	.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.off
.1	dc.w	.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.off
.2	dc.w	.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.off
.3	dc.w	.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.off
.4	dc.w	.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.off
.5	dc.w	.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.off
.6	dc.w	.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.off
.7	dc.w	.a+3,4,.a+4,4,.a+5,-20

SPApassb	=	*-SPAlist	;back hand pass swing
SPApassb_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFswing
.off	=	6
.0	dc.w	.a+3,4,.a+2,4,.a+1,-20
.a	set	.a+.off
.1	dc.w	.a+3,4,.a+2,4,.a+1,-20
.a	set	.a+.off
.2	dc.w	.a+3,4,.a+2,4,.a+1,-20
.a	set	.a+.off
.3	dc.w	.a+3,4,.a+2,4,.a+1,-20
.a	set	.a+.off
.4	dc.w	.a+3,4,.a+2,4,.a+1,-20
.a	set	.a+.off
.5	dc.w	.a+3,4,.a+2,4,.a+1,-20
.a	set	.a+.off
.6	dc.w	.a+3,4,.a+2,4,.a+1,-20
.a	set	.a+.off
.7	dc.w	.a+3,4,.a+2,4,.a+1,-20

SPAshotf	=	*-SPAlist	;player shoots forhand
SPAshotf_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFswing
.off	=	6
.0	dc.w	.a+3,4,.a+2,4,.a+1,4,.a+0,4,.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.off
.1	dc.w	.a+3,4,.a+2,4,.a+1,4,.a+0,4,.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.off
.2	dc.w	.a+3,4,.a+2,4,.a+1,4,.a+0,4,.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.off
.3	dc.w	.a+3,4,.a+2,4,.a+1,4,.a+0,4,.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.off
.4	dc.w	.a+3,4,.a+2,4,.a+1,4,.a+0,4,.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.off
.5	dc.w	.a+3,4,.a+2,4,.a+1,4,.a+0,4,.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.off
.6	dc.w	.a+3,4,.a+2,4,.a+1,4,.a+0,4,.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.off
.7	dc.w	.a+3,4,.a+2,4,.a+1,4,.a+0,4,.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,-20

SPAshotb	=	*-SPAlist	;player shoots backhand
SPAshotb_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFswing
.off	=	6
.0	dc.w	.a+3,4,.a+4,4,.a+5,4,.a+5,4,.a+5,4,.a+4,4,.a+3,4,.a+2,4,.a+1,-20
.a	set	.a+.off
.1	dc.w	.a+3,4,.a+4,4,.a+5,4,.a+5,4,.a+5,4,.a+4,4,.a+3,4,.a+2,4,.a+1,-20
.a	set	.a+.off
.2	dc.w	.a+3,4,.a+4,4,.a+5,4,.a+5,4,.a+5,4,.a+4,4,.a+3,4,.a+2,4,.a+1,-20
.a	set	.a+.off
.3	dc.w	.a+3,4,.a+4,4,.a+5,4,.a+5,4,.a+5,4,.a+4,4,.a+3,4,.a+2,4,.a+1,-20
.a	set	.a+.off
.4	dc.w	.a+3,4,.a+4,4,.a+5,4,.a+5,4,.a+5,4,.a+4,4,.a+3,4,.a+2,4,.a+1,-20
.a	set	.a+.off
.5	dc.w	.a+3,4,.a+4,4,.a+5,4,.a+5,4,.a+5,4,.a+4,4,.a+3,4,.a+2,4,.a+1,-20
.a	set	.a+.off
.6	dc.w	.a+3,4,.a+4,4,.a+5,4,.a+5,4,.a+5,4,.a+4,4,.a+3,4,.a+2,4,.a+1,-20
.a	set	.a+.off
.7	dc.w	.a+3,4,.a+4,4,.a+5,4,.a+5,4,.a+5,4,.a+4,4,.a+3,4,.a+2,4,.a+1,-20

SPAglideback	=	*-SPAlist	;player gliding backwards
SPAglideback_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFskateb
.off	=	3
.0	dc.w	.a,-8
.a	set	.a+.off
.1	dc.w	.a,-8
.a	set	.a+.off
.2	dc.w	.a,-8
.a	set	.a+.off
.3	dc.w	.a,-8
.a	set	.a+.off
.4	dc.w	.a,-8
.a	set	.a+.off
.5	dc.w	.a,-8
.a	set	.a+.off
.6	dc.w	.a,-8
.a	set	.a+.off
.7	dc.w	.a,-8

SPAskateback	=	*-SPAlist	;player skating backwards
SPAskateback_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFskateb
.off	=	3
.0	dc.w	.a,10,.a+1,10,.a,10,.a+2,-10
.a	set	.a+.off
.1	dc.w	.a,10,.a+1,10,.a,10,.a+2,-10
.a	set	.a+.off
.2	dc.w	.a,10,.a+1,10,.a,10,.a+2,-10
.a	set	.a+.off
.3	dc.w	.a,10,.a+1,10,.a,10,.a+2,-10
.a	set	.a+.off
.4	dc.w	.a,10,.a+1,10,.a,10,.a+2,-10
.a	set	.a+.off
.5	dc.w	.a,10,.a+1,10,.a,10,.a+2,-10
.a	set	.a+.off
.6	dc.w	.a,10,.a+1,10,.a,10,.a+2,-10
.a	set	.a+.off
.7	dc.w	.a,10,.a+1,10,.a,10,.a+2,-10

SPAsweepchk	=	*-SPAlist	;player stick (sweep) checking
SPAsweepchk_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFsweep
.off	=	2
.0	dc.w	.a,4,.a+1,8,.a,-4
.a	set	.a+.off
.1	dc.w	.a,4,.a+1,8,.a,-4
.a	set	.a+.off
.2	dc.w	.a,4,.a+1,8,.a,-4
.a	set	.a+.off
.3	dc.w	.a,4,.a+1,8,.a,-4
.a	set	.a+.off
.4	dc.w	.a,4,.a+1,8,.a,-4
.a	set	.a+.off
.5	dc.w	.a,4,.a+1,8,.a,-4
.a	set	.a+.off
.6	dc.w	.a,4,.a+1,8,.a,-4
.a	set	.a+.off
.7	dc.w	.a,4,.a+1,8,.a,-4

SPAshoulderchkl	=	*-SPAlist	;player shoulder checking left
SPAshoulderchkl_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFshoulderl
.off	=	1
.0	dc.w	.a,-24
.a	set	.a+.off
.1	dc.w	.a,-24
.a	set	.a+.off
.2	dc.w	.a,-24
.a	set	.a+.off
.3	dc.w	.a,-24
.a	set	.a+.off
.4	dc.w	.a,-24
.a	set	.a+.off
.5	dc.w	.a,-24
.a	set	.a+.off
.6	dc.w	.a,-24
.a	set	.a+.off
.7	dc.w	.a,-24

SPAshoulderchkr	=	*-SPAlist	;player shoulder checking right
SPAshoulderchkr_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFshoulderr
.off	=	1
.0	dc.w	.a,-24
.a	set	.a+.off
.1	dc.w	.a,-24
.a	set	.a+.off
.2	dc.w	.a,-24
.a	set	.a+.off
.3	dc.w	.a,-24
.a	set	.a+.off
.4	dc.w	.a,-24
.a	set	.a+.off
.5	dc.w	.a,-24
.a	set	.a+.off
.6	dc.w	.a,-24
.a	set	.a+.off
.7	dc.w	.a,-24

SPAhipchkl	=	*-SPAlist	;player hip checking left
SPAhipchkl_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFhipl
.off	=	1
.0	dc.w	.a,-24
.a	set	.a+.off
.1	dc.w	.a,-24
.a	set	.a+.off
.2	dc.w	.a,-24
.a	set	.a+.off
.3	dc.w	.a,-24
.a	set	.a+.off
.4	dc.w	.a,-24
.a	set	.a+.off
.5	dc.w	.a,-24
.a	set	.a+.off
.6	dc.w	.a,-24
.a	set	.a+.off
.7	dc.w	.a,-24

SPAhipchkr	=	*-SPAlist	;player hip checking right
SPAhipchkr_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFhipr
.off	=	1
.0	dc.w	.a,-24
.a	set	.a+.off
.1	dc.w	.a,-24
.a	set	.a+.off
.2	dc.w	.a,-24
.a	set	.a+.off
.3	dc.w	.a,-24
.a	set	.a+.off
.4	dc.w	.a,-24
.a	set	.a+.off
.5	dc.w	.a,-24
.a	set	.a+.off
.6	dc.w	.a,-24
.a	set	.a+.off
.7	dc.w	.a,-24

SPAburst	=	*-SPAlist	;player doing c button (speed/no check)
SPAburst_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFskate
.off	=	5
.0	dc.w	.a,-24
.a	set	.a+.off
.1	dc.w	.a,-24
.a	set	.a+.off
.2	dc.w	.a,-24
.a	set	.a+.off
.3	dc.w	.a,-24
.a	set	.a+.off
.4	dc.w	.a,-24
.a	set	.a+.off
.5	dc.w	.a,-24
.a	set	.a+.off
.6	dc.w	.a,-24
.a	set	.a+.off
.7	dc.w	.a,-24

SPAHold	=	*-SPAlist	;player trying to hold
SPAHold_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFhold
.off	=	1
.0	dc.w	.a,-30
.a	set	.a+.off
.1	dc.w	.a,-30
.a	set	.a+.off
.2	dc.w	.a,-30
.a	set	.a+.off
.3	dc.w	.a,-30
.a	set	.a+.off
.4	dc.w	.a,-30
.a	set	.a+.off
.5	dc.w	.a,-30
.a	set	.a+.off
.6	dc.w	.a,-30
.a	set	.a+.off
.7	dc.w	.a,-30

SPAHold2	=	*-SPAlist	;player holding opponent
SPAHold2_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFhold
.off	=	1
.0	dc.w	.a,-30
.a	set	.a+.off
.1	dc.w	.a,-30
.a	set	.a+.off
.2	dc.w	.a,-30
.a	set	.a+.off
.3	dc.w	.a,-30
.a	set	.a+.off
.4	dc.w	.a,-30
.a	set	.a+.off
.5	dc.w	.a,-30
.a	set	.a+.off
.6	dc.w	.a,-30
.a	set	.a+.off
.7	dc.w	.a,-30

SPAflail	=	*-SPAlist	;player being held by opponent
SPAflail_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFskate
.off	=	5
.0	dc.w	.a,-30
.a	set	.a+.off
.1	dc.w	.a,-30
.a	set	.a+.off
.2	dc.w	.a,-30
.a	set	.a+.off
.3	dc.w	.a,-30
.a	set	.a+.off
.4	dc.w	.a,-30
.a	set	.a+.off
.5	dc.w	.a,-30
.a	set	.a+.off
.6	dc.w	.a,-30
.a	set	.a+.off
.7	dc.w	.a,-30

SPAfallfwd	=	*-SPAlist	;player falling forward
SPAfallfwd_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFfallfwd
.b	=	SPFduck
.off	=	4
.0	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.off
.b	set	.b+1
.1	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.off
.b	set	.b+1
.2	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.off
.b	set	.b+1
.3	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.off
.b	set	.b+1
.4	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.off
.b	set	.b+1
.5	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.off
.b	set	.b+1
.6	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.off
.b	set	.b+1
.7	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8

SPAfallback	=	*-SPAlist	;player falling backward
SPAfallback_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFfallback
.b	=	SPFduck
.off	=	4
.0	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.off
.b	set	.b+1
.1	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.off
.b	set	.b+1
.2	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.off
.b	set	.b+1
.3	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.off
.b	set	.b+1
.4	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.off
.b	set	.b+1
.5	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.off
.b	set	.b+1
.6	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.off
.b	set	.b+1
.7	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8

SPAcelebrate	=	*-SPAlist	;player raising stick/arms up
SPAcelebrate_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFcelebrate
.off	=	2
.0	dc.w	.a,12,.a+1,40,.a,-5
.a	set	.a+.off
.1	dc.w	.a,12,.a+1,40,.a,-5
.a	set	.a+.off
.2	dc.w	.a,12,.a+1,40,.a,-5
.a	set	.a+.off
.3	dc.w	.a,12,.a+1,40,.a,-5
.a	set	.a+.off
.4	dc.w	.a,12,.a+1,40,.a,-5
.a	set	.a+.off
.5	dc.w	.a,12,.a+1,40,.a,-5
.a	set	.a+.off
.6	dc.w	.a,12,.a+1,40,.a,-5
.a	set	.a+.off
.7	dc.w	.a,12,.a+1,40,.a,-5

SPApump	=	*-SPAlist	;player doing pump animation
SPApump_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFpump
.off	=	2
.0	dc.w	.a,8,.a+1,8,.a,-8
.a	set	.a+.off
.1	dc.w	.a,8,.a+1,8,.a,-8
.a	set	.a+.off
.2	dc.w	.a,8,.a+1,8,.a,-8
.a	set	.a+.off
.3	dc.w	.a,8,.a+1,8,.a,-8
.a	set	.a+.off
.4	dc.w	.a,8,.a+1,8,.a,-8
.a	set	.a+.off
.5	dc.w	.a,8,.a+1,8,.a,-8
.a	set	.a+.off
.6	dc.w	.a,8,.a+1,8,.a,-8
.a	set	.a+.off
.7	dc.w	.a,8,.a+1,8,.a,-8

SPAfight	=	*-SPAlist	;player throwing off gloves
SPAfight_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFfight
.0
.1
.2	dc.w	.a,8,.a+1,8,.a+2,8,.a+3,-6
.3
.4
.5
.6
.7	dc.w	.a,8,.a+1,8,.a+2,8,.a+3+5,-6

SPAfgrab	=	*-SPAlist	;fighter grabbing
SPAfgrab_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFfight+3
.0
.1
.2	dc.w	.a+1,28,.a,-4
.a	set	.a+5
.3
.4
.5
.6
.7	dc.w	.a+1,28,.a,-4

SPAfheld	=	*-SPAlist	;fighter holding
SPAfheld_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFfight+3
.0
.1
.2	dc.w	.a+1,30,.a,-4
.a	set	.a+5
.3
.4
.5
.6
.7	dc.w	.a+1,30,.a,-4

SPAfhigh	=	*-SPAlist	;fighter throws high punch
SPAfhigh_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFfight+3
.0
.1
.2	dc.w	.a+2,6,.a+3,16,.a+2,4,.a,-16
.a	set	.a+5
.3
.4
.5
.6
.7	dc.w	.a+2,6,.a+3,16,.a+2,4,.a,-16

SPAflow	=	*-SPAlist	;fighter throws low punch
SPAflow_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFfight+3
.0
.1
.2	dc.w	.a+2,6,.a+4,16,.a+2,4,.a,-16
.a	set	.a+5
.3
.4
.5
.6
.7	dc.w	.a+2,6,.a+4,16,.a+2,4,.a,-16

SPAfhith	=	*-SPAlist	;fighter hit by high punch
SPAfhith_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFfight+3
.0
.1
.2	dc.w	SPFfight+14,16,.a,-8
.a	set	.a+5
.3
.4
.5
.6
.7	dc.w	SPFfight+14,16,.a,-8

SPAfhitl	=	*-SPAlist	;fighter hit by low punch
SPAfhitl_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFfight+3
.0
.1
.2	dc.w	SPFfight+13,16,.a,-8
.a	set	.a+5
.3
.4
.5
.6
.7	dc.w	SPFfight+13,16,.a,-8

SPAffall	=	*-SPAlist	;fighter falls down
SPAffall_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFfight+3+11
.0
.1
.2
.3
.4
.5
.6
.7	dc.w	.a,8,.a+1,8,.a+2,200,.a+2,-2

SPAwallright	=	*-SPAlist	;player jumps wall with legs to the right
SPAwallright_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFpen
.0	dc.w	.a+4,8,.a+5,8,.a+6,-8
.1
.2	dc.w	.a,8,.a+1,8,.a+2,8,.a+3,-8
.3
.4
.5
.6	dc.w	.a+3,8,.a+2,8,.a+1,8,.a,-8
.7

SPAwallleft	=	*-SPAlist	;player jumps wall with legs to the left
SPAwallleft_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFpen
.0	dc.w	.a+6,8,.a+5,8,.a+4,-8
.1
.2	dc.w	.a+3,8,.a+2,8,.a+1,8,.a,-8
.3
.4
.5
.6	dc.w	.a,8,.a+1,8,.a+2,8,.a+3,-8
.7

SPAfaceoff	=	*-SPAlist	;player does faceoff stick check
SPAfaceoff_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.0	dc.w	SPFskatewp,2,SPFsweep+1,10,SPFsweep,-6
.1
.2
.3
.4
.5
.6
.7	dc.w	SPFskatewp+20,2,SPFsweep+9,10,SPFsweep+8,-6

SPAfaceoffr	=	*-SPAlist	;ready position for faceoff
SPAfaceoffr_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.0	dc.w	SPFskatewp,-5
.1
.2
.3
.4
.5
.6
.7	dc.w	SPFskatewp+20,-5

SPAsiren	=	*-SPAlist	;siren animation
SPAsiren_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	1

.0
.1
.2
.3
.4
.5
.6
.7	dc.w	SPFsiren,3
	dc.w	SPFsiren+1,3
	dc.w	SPFsiren+2,3
	dc.w	SPFsiren+3,3
	dc.w	SPFsiren+4,3
	dc.w	SPFsiren+5,3
	dc.w	SPFsiren+6,3
	dc.w	SPFsiren+7,3
	dc.w	SPFsiren+8,3
	dc.w	SPFsiren+9,3
	dc.w	SPFsiren+10,3
	dc.w	SPFsiren+11,3
	dc.w	SPFsiren+12,3
	dc.w	SPFsiren+13,-3

SPAstanley	=	*-SPAlist	;player skates with stanley cup over head
SPAstanley_table:
.t
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	1

.a	=	SPFcup
.off	=	1
.0	dc.w	.a,-30
.a	set	.a+.off
.1	dc.w	.a,-30
.a	set	.a+.off
.2	dc.w	.a,-30
.a	set	.a+.off
.3	dc.w	.a,-30
.a	set	.a+.off
.4	dc.w	.a,-30
.a	set	.a+.off
.5	dc.w	.a,-30
.a	set	.a+.off
.6	dc.w	.a,-30
.a	set	.a+.off
.7	dc.w	.a,-30

NHLPA93 Frames.asm that I have reversed so far:

;This is a data table for animating the graphics in Sprites.anim
;This list equates the sections of the alice animation file Sprites.anim

SPFskatewp	=	1
SPFskate	=	SPFskatewp+40 ; 41
SPFturnl	=	SPFskate+40 ; 81
SPFturnr	=	SPFturnl+8 ; 89
SPFswing	=	SPFturnr+8 ; 97
SPFstop	=	SPFswing+48 ; 145
SPFskateb	=	SPFstop+16 ; 161
SPFcelebrate	=	SPFskateb+24 ; 185
SPFpump	=	SPFcelebrate+16 ; 201
SPFcup	=	SPFpump+16 ; 217
SPFhipl	=	SPFcup+8 ; 225
SPFhipr	=	SPFhipl+8 ; 233
SPFshoulderl	=	SPFhipr+8 ;	241
SPFshoulderr	=	SPFshoulderl+8 ; 249
SPFsweep	=	SPFshoulderr+8 ; 257

SPFfallback	=	SPFsweep+16 ; 273
SPFfallfwd	=	SPFfallback+32 ; 305
SPFduck	=	SPFfallfwd+32 ; 337
SPFHold	=	SPFduck+8 ; 345

SPFgloves	=	SPFHold+8 ; 353
SPFfight	=	SPFgloves+1 ; 354
SPFfinjury	=	SPFfight+17 ; 371 - NEW for 93
SPFPen	=	SPFfinjury+6 ; 377

SPFarrow	=	SPFpen+7 ; 384
SPFpad	=	SPFarrow+6 ; 390
SPFreplay	=	SPFpad+3 ; 393 - NEW for 93
SPFpuck	=	SPFreplay+1 ; 394
SPFgoal	=	SPFpuck+11 ; 405
SPFGoalie	=	SPFgoal+2 ; 407
SPFgdive	=	SPFGoalie+80+32 ; 519 - NEW for 93
SPFglovel2	=	SPFgdive+16 ; 535 - NEW for 93
SPFgready2	=	SPFglovel2+4 ; 539 - NEW for 93
SPFSiren	=	SPFgready2+16 ; 555

SPFcatch = SPFSiren+14 ; 569 - NEW for 93
SPFhook = SPFcatch+16 ; 585 - NEW for 93
SPFstumble = SPFhook+16 ; 601 - NEW for 93
SPFflip = SPFstumble+24 ; 625 - NEW for 93
SPFinjury1 = SPFflip+8 ; 633 - NEW for 93
SPFbglass = SPFinjury1+12 ; 645 - NEW for 93


SPAlist
	dc.w	0


----
NHL92 Frames.asm binary from ROM 0x35B5-0x4619:
00 00 00 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 01 90 FF F8 01 93 FF F8 01 96 FF F8 01 99 FF F8 01 9C FF F8 01 9F FF F8 01 A2 FF F8 01 A5 FF F8 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 01 91 FF E0 01 94 FF E0 01 97 FF E0 01 9A FF E0 01 9D FF E0 01 A0 FF E0 01 A3 FF E0 01 A6 FF E0 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 01 92 FF E0 01 95 FF E0 01 98 FF E0 01 9B FF E0 01 9E FF E0 01 A1 FF E0 01 A4 FF E0 01 A7 FF E0 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 01 D0 FF E0 01 D2 FF E0 01 D4 FF E0 01 D6 FF E0 01 D8 FF E0 01 DA FF E0 01 DC FF E0 01 DE FF E0 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 01 D1 FF E0 01 D3 FF E0 01 D5 FF E0 01 D7 FF E0 01 D9 FF E0 01 DB FF E0 01 DD FF E0 01 DF FF E0 00 12 00 1A 00 22 00 2A 00 32 00 3A 00 42 00 4A 00 00 01 B8 00 08 01 B9 FF E0 01 BA 00 08 01 BB FF E0 01 BA 00 08 01 BB FF E0 01 BC 00 08 01 BD FF E0 01 BE 00 08 01 BF FF E0 01 C0 00 08 01 C1 FF E0 01 C0 00 08 01 C1 FF E0 01 C2 00 08 01 C3 FF E0 00 12 00 1A 00 22 00 2A 00 32 00 3A 00 42 00 4A 00 00 01 C4 00 08 01 C5 FF E0 01 C6 00 08 01 C7 FF E0 01 C6 00 08 01 C7 FF E0 01 C8 00 08 01 C9 FF E0 01 CA 00 08 01 CB FF E0 01 CC 00 08 01 CD FF E0 01 CC 00 08 01 CD FF E0 01 CE 00 08 01 CF FF E0 00 12 00 1E 00 2A 00 36 00 42 00 4E 00 5A 00 66 00 00 01 A8 00 05 01 A9 00 08 01 A8 FF F0 01 AA 00 05 01 AB 00 08 01 AA FF F0 01 AC 00 05 01 AD 00 08 01 AC FF F0 01 AE 00 05 01 AF 00 08 01 AE FF F0 01 B0 00 05 01 B1 00 08 01 B0 FF F0 01 B2 00 05 01 B3 00 08 01 B2 FF F0 01 B4 00 05 01 B5 00 08 01 B4 FF F0 01 B6 00 05 01 B7 00 08 01 B6 FF F0 00 12 00 22 00 32 00 42 00 52 00 62 00 72 00 82 00 01 01 E0 00 0A 01 E1 00 0A 01 E2 00 0A 01 E3 FF F1 01 E4 00 0A 01 E5 00 0A 01 E6 00 0A 01 E7 FF F1 01 E8 00 0A 01 E9 00 0A 01 EA 00 0A 01 EB FF F1 01 EC 00 0A 01 ED 00 0A 01 EE 00 0A 01 EF FF F1 01 F0 00 0A 01 F1 00 0A 01 F2 00 0A 01 F3 FF F1 01 F4 00 0A 01 F5 00 0A 01 F6 00 0A 01 F7 FF F1 01 F8 00 0A 01 F9 00 0A 01 FA 00 0A 01 FB FF F1 01 FC 00 0A 01 FD 00 0A 01 FE 00 0A 01 FF FF F1 00 12 00 32 00 52 00 72 00 92 00 96 00 9A 00 9E 00 01 01 85 00 04 01 86 00 04 01 87 00 04 01 88 00 04 01 89 00 04 01 86 00 04 01 8A 00 04 01 84 FF FC 01 8C 00 02 01 84 00 02 01 8B 00 02 01 88 00 02 01 8D 00 02 01 88 00 02 01 8B 00 02 01 84 FF FE 01 87 00 02 01 86 00 02 01 85 00 02 01 84 00 02 01 8A 00 02 01 86 00 02 01 89 00 02 01 88 FF FE 01 8B 00 04 01 84 00 04 01 8C 00 04 01 84 00 04 01 8B 00 04 01 88 00 04 01 8D 00 04 01 88 FF FC 01 84 F0 00 01 84 F0 00 01 88 F0 00 01 88 F0 00 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 01 FF F8 00 06 FF F8 00 0B FF F8 00 10 FF F8 00 15 FF F8 00 1A FF F8 00 1F FF F8 00 24 FF F8 00 12 00 26 00 3A 00 4E 00 62 00 76 00 8A 00 9E 00 00 00 02 00 0A 00 03 00 0A 00 04 00 0A 00 05 00 0A 00 01 FF F1 00 07 00 0A 00 08 00 0A 00 09 00 0A 00 0A 00 0A 00 06 FF F1 00 0C 00 0A 00 0D 00 0A 00 0E 00 0A 00 0F 00 0A 00 0B FF F1 00 11 00 0A 00 12 00 0A 00 13 00 0A 00 14 00 0A 00 10 FF F1 00 16 00 0A 00 17 00 0A 00 18 00 0A 00 19 00 0A 00 15 FF F1 00 1B 00 0A 00 1C 00 0A 00 1D 00 0A 00 1E 00 0A 00 1A FF F1 00 20 00 0A 00 21 00 0A 00 22 00 0A 00 23 00 0A 00 1F FF F1 00 25 00 0A 00 26 00 0A 00 27 00 0A 00 28 00 0A 00 24 FF F1 00 12 00 26 00 3A 00 4E 00 62 00 76 00 8A 00 9E 00 00 00 2A 00 0A 00 2B 00 0A 00 2C 00 0A 00 2D 00 0A 00 29 FF F1 00 2F 00 0A 00 30 00 0A 00 31 00 0A 00 32 00 0A 00 2E FF F1 00 34 00 0A 00 35 00 0A 00 36 00 0A 00 37 00 0A 00 33 FF F1 00 39 00 0A 00 3A 00 0A 00 3B 00 0A 00 3C 00 0A 00 38 FF F1 00 3E 00 0A 00 3F 00 0A 00 40 00 0A 00 41 00 0A 00 3D FF F1 00 43 00 0A 00 44 00 0A 00 45 00 0A 00 46 00 0A 00 42 FF F1 00 48 00 0A 00 49 00 0A 00 4A 00 0A 00 4B 00 0A 00 47 FF F1 00 4D 00 0A 00 4E 00 0A 00 4F 00 0A 00 50 00 0A 00 4C FF F1 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 51 FF EE 00 52 FF EE 00 53 FF EE 00 54 FF EE 00 55 FF EE 00 56 FF EE 00 57 FF EE 00 58 FF EE 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 59 FF EE 00 5A FF EE 00 5B FF EE 00 5C FF EE 00 5D FF EE 00 5E FF EE 00 5F FF EE 00 60 FF EE 00 12 00 1A 00 22 00 2A 00 32 00 3A 00 42 00 4A 00 01 00 91 00 04 00 92 FF FC 00 93 00 04 00 94 FF FC 00 95 00 04 00 96 FF FC 00 97 00 04 00 98 FF FC 00 99 00 04 00 9A FF FC 00 9B 00 04 00 9C FF FC 00 9D 00 04 00 9E FF FC 00 9F 00 04 00 A0 FF FC 00 12 00 1E 00 2A 00 36 00 42 00 4E 00 5A 00 66 00 00 00 64 00 04 00 65 00 04 00 66 FF EC 00 6A 00 04 00 6B 00 04 00 6C FF EC 00 70 00 04 00 71 00 04 00 72 FF EC 00 76 00 04 00 77 00 04 00 78 FF EC 00 7C 00 04 00 7D 00 04 00 7E FF EC 00 82 00 04 00 83 00 04 00 84 FF EC 00 88 00 04 00 89 00 04 00 8A FF EC 00 8E 00 04 00 8F 00 04 00 90 FF EC 00 12 00 1E 00 2A 00 36 00 42 00 4E 00 5A 00 66 00 00 00 64 00 04 00 63 00 04 00 62 FF EC 00 6A 00 04 00 69 00 04 00 68 FF EC 00 70 00 04 00 6F 00 04 00 6E FF EC 00 76 00 04 00 75 00 04 00 74 FF EC 00 7C 00 04 00 7B 00 04 00 7A FF EC 00 82 00 04 00 81 00 04 00 80 FF EC 00 88 00 04 00 87 00 04 00 86 FF EC 00 8E 00 04 00 8D 00 04 00 8C FF EC 00 12 00 36 00 5A 00 7E 00 A2 00 C6 00 EA 01 0E 00 00 00 64 00 04 00 63 00 04 00 62 00 04 00 61 00 04 00 62 00 04 00 63 00 04 00 64 00 04 00 65 00 04 00 66 FF EC 00 6A 00 04 00 69 00 04 00 68 00 04 00 67 00 04 00 68 00 04 00 69 00 04 00 6A 00 04 00 6B 00 04 00 6C FF EC 00 70 00 04 00 6F 00 04 00 6E 00 04 00 6D 00 04 00 6E 00 04 00 6F 00 04 00 70 00 04 00 71 00 04 00 72 FF EC 00 76 00 04 00 75 00 04 00 74 00 04 00 73 00 04 00 74 00 04 00 75 00 04 00 76 00 04 00 77 00 04 00 78 FF EC 00 7C 00 04 00 7B 00 04 00 7A 00 04 00 79 00 04 00 7A 00 04 00 7B 00 04 00 7C 00 04 00 7D 00 04 00 7E FF EC 00 82 00 04 00 81 00 04 00 80 00 04 00 7F 00 04 00 80 00 04 00 81 00 04 00 82 00 04 00 83 00 04 00 84 FF EC 00 88 00 04 00 87 00 04 00 86 00 04 00 85 00 04 00 86 00 04 00 87 00 04 00 88 00 04 00 89 00 04 00 8A FF EC 00 8E 00 04 00 8D 00 04 00 8C 00 04 00 8B 00 04 00 8C 00 04 00 8D 00 04 00 8E 00 04 00 8F 00 04 00 90 FF EC 00 12 00 36 00 5A 00 7E 00 A2 00 C6 00 EA 01 0E 00 00 00 64 00 04 00 65 00 04 00 66 00 04 00 66 00 04 00 66 00 04 00 65 00 04 00 64 00 04 00 63 00 04 00 62 FF EC 00 6A 00 04 00 6B 00 04 00 6C 00 04 00 6C 00 04 00 6C 00 04 00 6B 00 04 00 6A 00 04 00 69 00 04 00 68 FF EC 00 70 00 04 00 71 00 04 00 72 00 04 00 72 00 04 00 72 00 04 00 71 00 04 00 70 00 04 00 6F 00 04 00 6E FF EC 00 76 00 04 00 77 00 04 00 78 00 04 00 78 00 04 00 78 00 04 00 77 00 04 00 76 00 04 00 75 00 04 00 74 FF EC 00 7C 00 04 00 7D 00 04 00 7E 00 04 00 7E 00 04 00 7E 00 04 00 7D 00 04 00 7C 00 04 00 7B 00 04 00 7A FF EC 00 82 00 04 00 83 00 04 00 84 00 04 00 84 00 04 00 84 00 04 00 83 00 04 00 82 00 04 00 81 00 04 00 80 FF EC 00 88 00 04 00 89 00 04 00 8A 00 04 00 8A 00 04 00 8A 00 04 00 89 00 04 00 88 00 04 00 87 00 04 00 86 FF EC 00 8E 00 04 00 8F 00 04 00 90 00 04 00 90 00 04 00 90 00 04 00 8F 00 04 00 8E 00 04 00 8D 00 04 00 8C FF EC 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 A1 FF F8 00 A4 FF F8 00 A7 FF F8 00 AA FF F8 00 AD FF F8 00 B0 FF F8 00 B3 FF F8 00 B6 FF F8 00 12 00 22 00 32 00 42 00 52 00 62 00 72 00 82 00 00 00 A1 00 0A 00 A2 00 0A 00 A1 00 0A 00 A3 FF F6 00 A4 00 0A 00 A5 00 0A 00 A4 00 0A 00 A6 FF F6 00 A7 00 0A 00 A8 00 0A 00 A7 00 0A 00 A9 FF F6 00 AA 00 0A 00 AB 00 0A 00 AA 00 0A 00 AC FF F6 00 AD 00 0A 00 AE 00 0A 00 AD 00 0A 00 AF FF F6 00 B0 00 0A 00 B1 00 0A 00 B0 00 0A 00 B2 FF F6 00 B3 00 0A 00 B4 00 0A 00 B3 00 0A 00 B5 FF F6 00 B6 00 0A 00 B7 00 0A 00 B6 00 0A 00 B8 FF F6 00 12 00 1E 00 2A 00 36 00 42 00 4E 00 5A 00 66 00 00 01 01 00 04 01 02 00 08 01 01 FF FC 01 03 00 04 01 04 00 08 01 03 FF FC 01 05 00 04 01 06 00 08 01 05 FF FC 01 07 00 04 01 08 00 08 01 07 FF FC 01 09 00 04 01 0A 00 08 01 09 FF FC 01 0B 00 04 01 0C 00 08 01 0B FF FC 01 0D 00 04 01 0E 00 08 01 0D FF FC 01 0F 00 04 01 10 00 08 01 0F FF FC 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 F1 FF E8 00 F2 FF E8 00 F3 FF E8 00 F4 FF E8 00 F5 FF E8 00 F6 FF E8 00 F7 FF E8 00 F8 FF E8 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 F9 FF E8 00 FA FF E8 00 FB FF E8 00 FC FF E8 00 FD FF E8 00 FE FF E8 00 FF FF E8 01 00 FF E8 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 E1 FF E8 00 E2 FF E8 00 E3 FF E8 00 E4 FF E8 00 E5 FF E8 00 E6 FF E8 00 E7 FF E8 00 E8 FF E8 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 E9 FF E8 00 EA FF E8 00 EB FF E8 00 EC FF E8 00 ED FF E8 00 EE FF E8 00 EF FF E8 00 F0 FF E8 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 29 FF E8 00 2E FF E8 00 33 FF E8 00 38 FF E8 00 3D FF E8 00 42 FF E8 00 47 FF E8 00 4C FF E8 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 01 59 FF E2 01 5A FF E2 01 5B FF E2 01 5C FF E2 01 5D FF E2 01 5E FF E2 01 5F FF E2 01 60 FF E2 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 01 59 FF E2 01 5A FF E2 01 5B FF E2 01 5C FF E2 01 5D FF E2 01 5E FF E2 01 5F FF E2 01 60 FF E2 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 29 FF E2 00 2E FF E2 00 33 FF E2 00 38 FF E2 00 3D FF E2 00 42 FF E2 00 47 FF E2 00 4C FF E2 00 12 00 26 00 3A 00 4E 00 62 00 76 00 8A 00 9E 00 00 01 31 00 06 01 32 00 06 01 33 00 64 01 34 00 08 01 51 FF F8 01 35 00 06 01 36 00 06 01 37 00 64 01 38 00 08 01 52 FF F8 01 39 00 06 01 3A 00 06 01 3B 00 64 01 3C 00 08 01 53 FF F8 01 3D 00 06 01 3E 00 06 01 3F 00 64 01 40 00 08 01 54 FF F8 01 41 00 06 01 42 00 06 01 43 00 64 01 44 00 08 01 55 FF F8 01 45 00 06 01 46 00 06 01 47 00 64 01 48 00 08 01 56 FF F8 01 49 00 06 01 4A 00 06 01 4B 00 64 01 4C 00 08 01 57 FF F8 01 4D 00 06 01 4E 00 06 01 4F 00 64 01 50 00 08 01 58 FF F8 00 12 00 26 00 3A 00 4E 00 62 00 76 00 8A 00 9E 00 00 01 11 00 06 01 12 00 06 01 13 00 64 01 14 00 08 01 51 FF F8 01 15 00 06 01 16 00 06 01 17 00 64 01 18 00 08 01 52 FF F8 01 19 00 06 01 1A 00 06 01 1B 00 64 01 1C 00 08 01 53 FF F8 01 1D 00 06 01 1E 00 06 01 1F 00 64 01 20 00 08 01 54 FF F8 01 21 00 06 01 22 00 06 01 23 00 64 01 24 00 08 01 55 FF F8 01 25 00 06 01 26 00 06 01 27 00 64 01 28 00 08 01 56 FF F8 01 29 00 06 01 2A 00 06 01 2B 00 64 01 2C 00 08 01 57 FF F8 01 2D 00 06 01 2E 00 06 01 2F 00 64 01 30 00 08 01 58 FF F8 00 12 00 1E 00 2A 00 36 00 42 00 4E 00 5A 00 66 00 00 00 B9 00 0C 00 BA 00 28 00 B9 FF FB 00 BB 00 0C 00 BC 00 28 00 BB FF FB 00 BD 00 0C 00 BE 00 28 00 BD FF FB 00 BF 00 0C 00 C0 00 28 00 BF FF FB 00 C1 00 0C 00 C2 00 28 00 C1 FF FB 00 C3 00 0C 00 C4 00 28 00 C3 FF FB 00 C5 00 0C 00 C6 00 28 00 C5 FF FB 00 C7 00 0C 00 C8 00 28 00 C7 FF FB 00 12 00 1E 00 2A 00 36 00 42 00 4E 00 5A 00 66 00 00 00 C9 00 08 00 CA 00 08 00 C9 FF F8 00 CB 00 08 00 CC 00 08 00 CB FF F8 00 CD 00 08 00 CE 00 08 00 CD FF F8 00 CF 00 08 00 D0 00 08 00 CF FF F8 00 D1 00 08 00 D2 00 08 00 D1 FF F8 00 D3 00 08 00 D4 00 08 00 D3 FF F8 00 D5 00 08 00 D6 00 08 00 D5 FF F8 00 D7 00 08 00 D8 00 08 00 D7 FF F8 00 12 00 12 00 12 00 22 00 22 00 22 00 22 00 22 00 00 01 62 00 08 01 63 00 08 01 64 00 08 01 65 FF FA 01 62 00 08 01 63 00 08 01 64 00 08 01 6A FF FA 00 12 00 12 00 12 00 1A 00 1A 00 1A 00 1A 00 1A 00 00 01 66 00 1C 01 65 FF FC 01 6B 00 1C 01 6A FF FC 00 12 00 12 00 12 00 1A 00 1A 00 1A 00 1A 00 1A 00 00 01 66 00 1E 01 65 FF FC 01 6B 00 1E 01 6A FF FC 00 12 00 12 00 12 00 22 00 22 00 22 00 22 00 22 00 00 01 67 00 06 01 68 00 10 01 67 00 04 01 65 FF F0 01 6C 00 06 01 6D 00 10 01 6C 00 04 01 6A FF F0 00 12 00 12 00 12 00 22 00 22 00 22 00 22 00 22 00 00 01 67 00 06 01 69 00 10 01 67 00 04 01 65 FF F0 01 6C 00 06 01 6E 00 10 01 6C 00 04 01 6A FF F0 00 12 00 12 00 12 00 1A 00 1A 00 1A 00 1A 00 1A 00 00 01 70 00 10 01 65 FF F8 01 70 00 10 01 6A FF F8 00 12 00 12 00 12 00 1A 00 1A 00 1A 00 1A 00 1A 00 00 01 6F 00 10 01 65 FF F8 01 6F 00 10 01 6A FF F8 00 12 00 12 00 12 00 12 00 12 00 12 00 12 00 12 00 00 01 70 00 08 01 71 00 08 01 72 00 C8 01 72 FF FE 00 12 00 1E 00 1E 00 2E 00 2E 00 2E 00 2E 00 3E 00 00 01 77 00 08 01 78 00 08 01 79 FF F8 01 73 00 08 01 74 00 08 01 75 00 08 01 76 FF F8 01 76 00 08 01 75 00 08 01 74 00 08 01 73 FF F8 00 12 00 1E 00 1E 00 2E 00 2E 00 2E 00 2E 00 3E 00 00 01 79 00 08 01 78 00 08 01 77 FF F8 01 76 00 08 01 75 00 08 01 74 00 08 01 73 FF F8 01 73 00 08 01 74 00 08 01 75 00 08 01 76 FF F8 00 12 00 1E 00 1E 00 1E 00 1E 00 1E 00 1E 00 1E 00 00 00 01 00 02 01 02 00 0A 01 01 FF FA 00 15 00 02 01 0A 00 0A 01 09 FF FA 00 12 00 16 00 16 00 16 00 16 00 16 00 16 00 16 00 00 00 01 FF FB 00 15 FF FB 00 12 00 12 00 12 00 12 00 12 00 12 00 12 00 12 00 01 02 18 00 03 02 19 00 03 02 1A 00 03 02 1B 00 03 02 1C 00 03 02 1D 00 03 02 1E 00 03 02 1F 00 03 02 20 00 03 02 21 00 03 02 22 00 03 02 23 00 03 02 24 00 03 02 25 FF FD 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 01 00 D9 FF E2 00 DA FF E2 00 DB FF E2 00 DC FF E2 00 DD FF E2 00 DE FF E2 00 DF FF E2 00 E0 FF E2

NHLPA93 Frames.asm binary from ROM 0x4D8D-0x6445:
00 00 00 00 12 00 36 00 5A 00 7E 00 A2 00 C6 00 EA 01 0E 00 01 01 97 00 B4 02 1B 00 0A 02 1C 00 0A 02 1B 00 0A 02 1C 00 0A 01 97 00 F0 02 1B 00 0A 02 1C 00 0A 02 1B FF F6 01 9A 00 82 02 1D 00 0A 02 1E 00 0A 02 1D 00 0A 02 1E 00 0A 01 9A 01 2C 02 1D 00 0A 02 1E 00 0A 02 1D FF F6 01 9D 00 D2 02 1F 00 0A 02 20 00 0A 02 1F 00 0A 02 20 00 0A 01 9D 00 78 02 1F 00 0A 02 20 00 0A 02 1F FF F6 01 A0 00 64 02 21 00 0A 02 22 00 0A 02 21 00 0A 02 22 00 0A 01 A0 00 C8 02 21 00 0A 02 22 00 0A 02 21 FF F6 01 A3 00 F0 02 23 00 0A 02 24 00 0A 02 23 00 0A 02 24 00 0A 01 A3 00 3C 02 23 00 0A 02 24 00 0A 02 23 FF F6 01 A6 00 B4 02 25 00 0A 02 26 00 0A 02 25 00 0A 02 26 00 0A 01 A6 00 F0 02 25 00 0A 02 26 00 0A 02 25 FF F6 01 A9 00 78 02 27 00 0A 02 28 00 0A 02 27 00 0A 02 28 00 0A 01 A9 00 78 02 27 00 0A 02 28 00 0A 02 27 FF F6 01 AC 00 B4 02 29 00 0A 02 2A 00 0A 02 29 00 0A 02 2A 00 0A 01 AC 00 B4 02 29 00 0A 02 2A 00 0A 02 29 FF F6 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 01 97 FF E2 01 9A FF E2 01 9D FF E2 01 A0 FF E2 01 A3 FF E2 01 A6 FF E2 01 A9 FF E2 01 AC FF E2 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 01 98 FF E0 01 9B FF E0 01 9E FF E0 01 A1 FF E0 01 A4 FF E0 01 A7 FF E0 01 AA FF E0 01 AD FF E0 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 01 99 FF E0 01 9C FF E0 01 9F FF E0 01 A2 FF E0 01 A5 FF E0 01 A8 FF E0 01 AB FF E0 01 AE FF E0 00 12 00 1E 00 22 00 26 00 2A 00 36 00 3A 00 3E 00 00 02 17 00 04 02 18 00 08 02 17 FF FC 01 9C FF E0 01 9F FF E0 01 A2 FF E0 02 19 00 04 02 1A 00 08 02 19 FF FC 01 A8 FF E0 01 AB FF E0 01 AE FF E0 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 01 D7 FF E0 01 D9 FF E0 01 DB FF E0 01 DD FF E0 01 DF FF E0 01 E1 FF E0 01 E3 FF E0 01 E5 FF E0 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 01 D8 FF E0 01 DA FF E0 01 DC FF E0 01 DE FF E0 01 E0 FF E0 01 E2 FF E0 01 E4 FF E0 01 E6 FF E0 00 12 00 1A 00 22 00 2A 00 32 00 3A 00 42 00 4A 00 00 01 BF 00 08 01 C0 FF E0 01 C1 00 08 01 C2 FF E0 01 C1 00 08 01 C2 FF E0 01 C3 00 08 01 C4 FF E0 01 C5 00 08 01 C6 FF E0 01 C7 00 08 01 C8 FF E0 01 C7 00 08 01 C8 FF E0 01 C9 00 08 01 CA FF E0 00 12 00 1A 00 22 00 2A 00 32 00 3A 00 42 00 4A 00 00 01 CB 00 08 01 CC FF E0 01 CD 00 08 01 CE FF E0 01 CD 00 08 01 CE FF E0 01 CF 00 08 01 D0 FF E0 01 D1 00 08 01 D2 FF E0 01 D3 00 08 01 D4 FF E0 01 D3 00 08 01 D4 FF E0 01 D5 00 08 01 D6 FF E0 00 12 00 1E 00 2A 00 36 00 42 00 4E 00 5A 00 66 00 00 02 07 00 08 02 08 00 30 02 07 FF F8 02 09 00 08 02 0A 00 30 02 09 FF F8 02 0B 00 08 02 0C 00 30 02 0B FF F8 02 0D 00 08 02 0E 00 30 02 0D FF F8 02 0F 00 08 02 10 00 30 02 0F FF F8 02 11 00 08 02 12 00 30 02 11 FF F8 02 13 00 08 02 14 00 30 02 13 FF F8 02 15 00 08 02 16 00 30 02 15 FF F8 00 12 00 1E 00 2A 00 36 00 42 00 4E 00 5A 00 66 00 00 01 AF 00 05 01 B0 00 08 01 AF FF F0 01 B1 00 05 01 B2 00 08 01 B1 FF F0 01 B3 00 05 01 B4 00 08 01 B3 FF F0 01 B5 00 05 01 B6 00 08 01 B5 FF F0 01 B7 00 05 01 B8 00 08 01 B7 FF F0 01 B9 00 05 01 BA 00 08 01 B9 FF F0 01 BB 00 05 01 BC 00 08 01 BB FF F0 01 BD 00 05 01 BE 00 08 01 BD FF F0 00 12 00 22 00 32 00 42 00 52 00 62 00 72 00 82 00 00 01 E7 00 0A 01 E8 00 0A 01 E9 00 0A 01 EA FF F1 01 EB 00 0A 01 EC 00 0A 01 ED 00 0A 01 EE FF F1 01 EF 00 0A 01 F0 00 0A 01 F1 00 0A 01 F2 FF F1 01 F3 00 0A 01 F4 00 0A 01 F5 00 0A 01 F6 FF F1 01 F7 00 0A 01 F8 00 0A 01 F9 00 0A 01 FA FF F1 01 FB 00 0A 01 FC 00 0A 01 FD 00 0A 01 FE FF F1 01 FF 00 0A 02 00 00 0A 02 01 00 0A 02 02 FF F1 02 03 00 0A 02 04 00 0A 02 05 00 0A 02 06 FF F1 00 12 00 32 00 52 00 72 00 92 00 96 00 9A 00 9E 00 01 01 8C 00 04 01 8D 00 04 01 8E 00 04 01 8F 00 04 01 90 00 04 01 8D 00 04 01 91 00 04 01 8B FF FC 01 93 00 02 01 8B 00 02 01 92 00 02 01 8F 00 02 01 94 00 02 01 8F 00 02 01 92 00 02 01 8B FF FE 01 8E 00 02 01 8D 00 02 01 8C 00 02 01 8B 00 02 01 91 00 02 01 8D 00 02 01 90 00 02 01 8F FF FE 01 92 00 04 01 8B 00 04 01 93 00 04 01 8B 00 04 01 92 00 04 01 8F 00 04 01 94 00 04 01 8F FF FC 01 8B F0 00 01 8B F0 00 01 8F F0 00 01 8F F0 00 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 01 FF F8 00 06 FF F8 00 0B FF F8 00 10 FF F8 00 15 FF F8 00 1A FF F8 00 1F FF F8 00 24 FF F8 00 12 00 22 00 32 00 42 00 52 00 62 00 72 00 82 00 00 00 02 00 0A 00 03 00 0A 00 04 00 0A 00 05 FF F6 00 07 00 0A 00 08 00 0A 00 09 00 0A 00 0A FF F6 00 0C 00 0A 00 0D 00 0A 00 0E 00 0A 00 0F FF F6 00 11 00 0A 00 12 00 0A 00 13 00 0A 00 14 FF F6 00 16 00 0A 00 17 00 0A 00 18 00 0A 00 19 FF F6 00 1B 00 0A 00 1C 00 0A 00 1D 00 0A 00 1E FF F6 00 20 00 0A 00 21 00 0A 00 22 00 0A 00 23 FF F6 00 25 00 0A 00 26 00 0A 00 27 00 0A 00 28 FF F6 00 12 00 22 00 32 00 42 00 52 00 62 00 72 00 82 00 00 00 2A 00 0A 00 2B 00 0A 00 2C 00 0A 00 2D FF F6 00 2F 00 0A 00 30 00 0A 00 31 00 0A 00 32 FF F6 00 34 00 0A 00 35 00 0A 00 36 00 0A 00 37 FF F6 00 39 00 0A 00 3A 00 0A 00 3B 00 0A 00 3C FF F6 00 3E 00 0A 00 3F 00 0A 00 40 00 0A 00 41 FF F6 00 43 00 0A 00 44 00 0A 00 45 00 0A 00 46 FF F6 00 48 00 0A 00 49 00 0A 00 4A 00 0A 00 4B FF F6 00 4D 00 0A 00 4E 00 0A 00 4F 00 0A 00 50 FF F6 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 51 FF F8 00 52 FF F8 00 53 FF F8 00 54 FF F8 00 55 FF F8 00 56 FF F8 00 57 FF F8 00 58 FF F8 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 59 FF F8 00 5A FF F8 00 5B FF F8 00 5C FF F8 00 5D FF F8 00 5E FF F8 00 5F FF F8 00 60 FF F8 00 12 00 1A 00 22 00 2A 00 32 00 3A 00 42 00 4A 00 01 00 91 00 04 00 92 FF FC 00 93 00 04 00 94 FF FC 00 95 00 04 00 96 FF FC 00 97 00 04 00 98 FF FC 00 99 00 04 00 9A FF FC 00 9B 00 04 00 9C FF FC 00 9D 00 04 00 9E FF FC 00 9F 00 04 00 A0 FF FC 00 12 00 1E 00 2A 00 36 00 42 00 4E 00 5A 00 66 00 00 00 64 00 04 00 65 00 04 00 66 FF EC 00 6A 00 04 00 6B 00 04 00 6C FF EC 00 70 00 04 00 71 00 04 00 72 FF EC 00 76 00 04 00 77 00 04 00 78 FF EC 00 7C 00 04 00 7D 00 04 00 7E FF EC 00 82 00 04 00 83 00 04 00 84 FF EC 00 88 00 04 00 89 00 04 00 8A FF EC 00 8E 00 04 00 8F 00 04 00 90 FF EC 00 12 00 1E 00 2A 00 36 00 42 00 4E 00 5A 00 66 00 00 00 64 00 04 00 63 00 04 00 62 FF EC 00 6A 00 04 00 69 00 04 00 68 FF EC 00 70 00 04 00 6F 00 04 00 6E FF EC 00 76 00 04 00 75 00 04 00 74 FF EC 00 7C 00 04 00 7B 00 04 00 7A FF EC 00 82 00 04 00 81 00 04 00 80 FF EC 00 88 00 04 00 87 00 04 00 86 FF EC 00 8E 00 04 00 8D 00 04 00 8C FF EC 00 12 00 36 00 5A 00 7E 00 A2 00 C6 00 EA 01 0E 00 00 00 64 00 04 00 63 00 04 00 62 00 04 00 61 00 04 00 62 00 04 00 63 00 04 00 64 00 04 00 65 00 04 00 66 FF EC 00 6A 00 04 00 69 00 04 00 68 00 04 00 67 00 04 00 68 00 04 00 69 00 04 00 6A 00 04 00 6B 00 04 00 6C FF EC 00 70 00 04 00 6F 00 04 00 6E 00 04 00 6D 00 04 00 6E 00 04 00 6F 00 04 00 70 00 04 00 71 00 04 00 72 FF EC 00 76 00 04 00 75 00 04 00 74 00 04 00 73 00 04 00 74 00 04 00 75 00 04 00 76 00 04 00 77 00 04 00 78 FF EC 00 7C 00 04 00 7B 00 04 00 7A 00 04 00 79 00 04 00 7A 00 04 00 7B 00 04 00 7C 00 04 00 7D 00 04 00 7E FF EC 00 82 00 04 00 81 00 04 00 80 00 04 00 7F 00 04 00 80 00 04 00 81 00 04 00 82 00 04 00 83 00 04 00 84 FF EC 00 88 00 04 00 87 00 04 00 86 00 04 00 85 00 04 00 86 00 04 00 87 00 04 00 88 00 04 00 89 00 04 00 8A FF EC 00 8E 00 04 00 8D 00 04 00 8C 00 04 00 8B 00 04 00 8C 00 04 00 8D 00 04 00 8E 00 04 00 8F 00 04 00 90 FF EC 00 12 00 36 00 5A 00 7E 00 A2 00 C6 00 EA 01 0E 00 00 00 64 00 04 00 65 00 04 00 66 00 04 00 66 00 04 00 66 00 04 00 65 00 04 00 64 00 04 00 63 00 04 00 62 FF EC 00 6A 00 04 00 6B 00 04 00 6C 00 04 00 6C 00 04 00 6C 00 04 00 6B 00 04 00 6A 00 04 00 69 00 04 00 68 FF EC 00 70 00 04 00 71 00 04 00 72 00 04 00 72 00 04 00 72 00 04 00 71 00 04 00 70 00 04 00 6F 00 04 00 6E FF EC 00 76 00 04 00 77 00 04 00 78 00 04 00 78 00 04 00 78 00 04 00 77 00 04 00 76 00 04 00 75 00 04 00 74 FF EC 00 7C 00 04 00 7D 00 04 00 7E 00 04 00 7E 00 04 00 7E 00 04 00 7D 00 04 00 7C 00 04 00 7B 00 04 00 7A FF EC 00 82 00 04 00 83 00 04 00 84 00 04 00 84 00 04 00 84 00 04 00 83 00 04 00 82 00 04 00 81 00 04 00 80 FF EC 00 88 00 04 00 89 00 04 00 8A 00 04 00 8A 00 04 00 8A 00 04 00 89 00 04 00 88 00 04 00 87 00 04 00 86 FF EC 00 8E 00 04 00 8F 00 04 00 90 00 04 00 90 00 04 00 90 00 04 00 8F 00 04 00 8E 00 04 00 8D 00 04 00 8C FF EC 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 A1 FF F8 00 A4 FF F8 00 A7 FF F8 00 AA FF F8 00 AD FF F8 00 B0 FF F8 00 B3 FF F8 00 B6 FF F8 00 12 00 22 00 32 00 42 00 52 00 62 00 72 00 82 00 00 00 A1 00 0A 00 A2 00 0A 00 A1 00 0A 00 A3 FF F6 00 A4 00 0A 00 A5 00 0A 00 A4 00 0A 00 A6 FF F6 00 A7 00 0A 00 A8 00 0A 00 A7 00 0A 00 A9 FF F6 00 AA 00 0A 00 AB 00 0A 00 AA 00 0A 00 AC FF F6 00 AD 00 0A 00 AE 00 0A 00 AD 00 0A 00 AF FF F6 00 B0 00 0A 00 B1 00 0A 00 B0 00 0A 00 B2 FF F6 00 B3 00 0A 00 B4 00 0A 00 B3 00 0A 00 B5 FF F6 00 B6 00 0A 00 B7 00 0A 00 B6 00 0A 00 B8 FF F6 00 12 00 1E 00 2A 00 36 00 42 00 4E 00 5A 00 66 00 00 01 01 00 04 01 02 00 08 01 01 FF FC 01 03 00 04 01 04 00 08 01 03 FF FC 01 05 00 04 01 06 00 08 01 05 FF FC 01 07 00 04 01 08 00 08 01 07 FF FC 01 09 00 04 01 0A 00 08 01 09 FF FC 01 0B 00 04 01 0C 00 08 01 0B FF FC 01 0D 00 04 01 0E 00 08 01 0D FF FC 01 0F 00 04 01 10 00 08 01 0F FF FC 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 F1 FF E8 00 F2 FF E8 00 F3 FF E8 00 F4 FF E8 00 F5 FF E8 00 F6 FF E8 00 F7 FF E8 00 F8 FF E8 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 F9 FF E8 00 FA FF E8 00 FB FF E8 00 FC FF E8 00 FD FF E8 00 FE FF E8 00 FF FF E8 01 00 FF E8 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 E1 FF E8 00 E2 FF E8 00 E3 FF E8 00 E4 FF E8 00 E5 FF E8 00 E6 FF E8 00 E7 FF E8 00 E8 FF E8 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 E9 FF E8 00 EA FF E8 00 EB FF E8 00 EC FF E8 00 ED FF E8 00 EE FF E8 00 EF FF E8 00 F0 FF E8 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 29 FF E8 00 2E FF E8 00 33 FF E8 00 38 FF E8 00 3D FF E8 00 42 FF E8 00 47 FF E8 00 4C FF E8 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 01 59 FF E2 01 5A FF E2 01 5B FF E2 01 5C FF E2 01 5D FF E2 01 5E FF E2 01 5F FF E2 01 60 FF E2 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 01 59 FF E2 01 5A FF E2 01 5B FF E2 01 5C FF E2 01 5D FF E2 01 5E FF E2 01 5F FF E2 01 60 FF E2 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 00 29 FF E2 00 2E FF E2 00 33 FF E2 00 38 FF E2 00 3D FF E2 00 42 FF E2 00 47 FF E2 00 4C FF E2 00 12 00 26 00 3A 00 4E 00 62 00 76 00 8A 00 9E 00 00 01 31 00 06 01 32 00 06 01 33 00 64 01 34 00 08 01 51 FF F8 01 35 00 06 01 36 00 06 01 37 00 64 01 38 00 08 01 52 FF F8 01 39 00 06 01 3A 00 06 01 3B 00 64 01 3C 00 08 01 53 FF F8 01 3D 00 06 01 3E 00 06 01 3F 00 64 01 40 00 08 01 54 FF F8 01 41 00 06 01 42 00 06 01 43 00 64 01 44 00 08 01 55 FF F8 01 45 00 06 01 46 00 06 01 47 00 64 01 48 00 08 01 56 FF F8 01 49 00 06 01 4A 00 06 01 4B 00 64 01 4C 00 08 01 57 FF F8 01 4D 00 06 01 4E 00 06 01 4F 00 64 01 50 00 08 01 58 FF F8 00 12 00 26 00 3A 00 4E 00 62 00 76 00 8A 00 9E 00 00 01 11 00 06 01 12 00 06 01 13 00 64 01 14 00 08 01 51 FF F8 01 15 00 06 01 16 00 06 01 17 00 64 01 18 00 08 01 52 FF F8 01 19 00 06 01 1A 00 06 01 1B 00 64 01 1C 00 08 01 53 FF F8 01 1D 00 06 01 1E 00 06 01 1F 00 64 01 20 00 08 01 54 FF F8 01 21 00 06 01 22 00 06 01 23 00 64 01 24 00 08 01 55 FF F8 01 25 00 06 01 26 00 06 01 27 00 64 01 28 00 08 01 56 FF F8 01 29 00 06 01 2A 00 06 01 2B 00 64 01 2C 00 08 01 57 FF F8 01 2D 00 06 01 2E 00 06 01 2F 00 64 01 30 00 08 01 58 FF F8 00 12 00 1E 00 2A 00 36 00 42 00 4E 00 5A 00 66 00 00 00 B9 00 0C 00 BA 00 28 00 B9 FF FB 00 BB 00 0C 00 BC 00 28 00 BB FF FB 00 BD 00 0C 00 BE 00 28 00 BD FF FB 00 BF 00 0C 00 C0 00 28 00 BF FF FB 00 C1 00 0C 00 C2 00 28 00 C1 FF FB 00 C3 00 0C 00 C4 00 28 00 C3 FF FB 00 C5 00 0C 00 C6 00 28 00 C5 FF FB 00 C7 00 0C 00 C8 00 28 00 C7 FF FB 00 12 00 1E 00 2A 00 36 00 42 00 4E 00 5A 00 66 00 00 00 C9 00 08 00 CA 00 08 00 C9 FF F8 00 CB 00 08 00 CC 00 08 00 CB FF F8 00 CD 00 08 00 CE 00 08 00 CD FF F8 00 CF 00 08 00 D0 00 08 00 CF FF F8 00 D1 00 08 00 D2 00 08 00 D1 FF F8 00 D3 00 08 00 D4 00 08 00 D3 FF F8 00 D5 00 08 00 D6 00 08 00 D5 FF F8 00 D7 00 08 00 D8 00 08 00 D7 FF F8 00 12 00 12 00 12 00 22 00 22 00 22 00 22 00 22 00 00 01 62 00 08 01 63 00 08 01 64 00 08 01 65 FF FA 01 62 00 08 01 63 00 08 01 64 00 08 01 6A FF FA 00 12 00 12 00 12 00 1A 00 1A 00 1A 00 1A 00 1A 00 00 01 66 00 1C 01 65 FF FC 01 6B 00 1C 01 6A FF FC 00 12 00 12 00 12 00 1A 00 1A 00 1A 00 1A 00 1A 00 00 01 66 00 1E 01 65 FF FC 01 6B 00 1E 01 6A FF FC 00 12 00 12 00 12 00 22 00 22 00 22 00 22 00 22 00 00 01 67 00 06 01 68 00 10 01 67 00 04 01 65 FF F0 01 6C 00 06 01 6D 00 10 01 6C 00 04 01 6A FF F0 00 12 00 12 00 12 00 22 00 22 00 22 00 22 00 22 00 00 01 67 00 06 01 69 00 10 01 67 00 04 01 65 FF F0 01 6C 00 06 01 6E 00 10 01 6C 00 04 01 6A FF F0 00 12 00 12 00 12 00 1A 00 1A 00 1A 00 1A 00 1A 00 00 01 70 00 10 01 65 FF F8 01 70 00 10 01 6A FF F8 00 12 00 12 00 12 00 1A 00 1A 00 1A 00 1A 00 1A 00 00 01 6F 00 10 01 65 FF F8 01 6F 00 10 01 6A FF F8 00 12 00 12 00 12 00 12 00 12 00 12 00 12 00 12 00 00 01 70 00 08 01 71 00 08 01 72 00 C8 01 72 FF FE 00 12 00 12 00 12 00 12 00 12 00 12 00 12 00 12 00 00 01 70 00 08 01 71 00 08 01 72 00 14 01 73 00 08 01 74 00 08 01 75 00 08 01 76 00 0A 01 77 00 0A 01 78 00 0A 01 76 00 0A 01 77 00 0A 01 78 00 0A 01 76 00 0A 01 77 00 0A 01 78 00 0A 01 76 00 0A 01 77 00 0A 01 78 FE 70 00 12 00 1E 00 1E 00 2E 00 2E 00 2E 00 2E 00 3E 00 00 01 7D 00 08 01 7E 00 08 01 7F FF F8 01 79 00 08 01 7A 00 08 01 7B 00 08 01 7C FF F8 01 7C 00 08 01 7B 00 08 01 7A 00 08 01 79 FF F8 00 12 00 1E 00 1E 00 2E 00 2E 00 2E 00 2E 00 3E 00 00 01 7F 00 08 01 7E 00 08 01 7D FF F8 01 7C 00 08 01 7B 00 08 01 7A 00 08 01 79 FF F8 01 79 00 08 01 7A 00 08 01 7B 00 08 01 7C FF F8 00 12 00 1E 00 1E 00 1E 00 1E 00 1E 00 1E 00 1E 00 00 00 01 00 02 01 02 00 0A 01 01 FF FA 00 15 00 02 01 0A 00 0A 01 09 FF FA 00 12 00 16 00 16 00 16 00 16 00 16 00 16 00 16 00 00 00 01 FF FB 00 15 FF FB 00 12 00 12 00 12 00 12 00 12 00 12 00 12 00 12 00 01 02 2B 00 03 02 2C 00 03 02 2D 00 03 02 2E 00 03 02 2F 00 03 02 30 00 03 02 31 00 03 02 32 00 03 02 33 00 03 02 34 00 03 02 35 00 03 02 36 00 03 02 37 00 03 02 38 FF FD 00 12 00 12 00 12 00 12 00 12 00 12 00 12 00 12 00 00 02 85 00 08 02 86 00 08 02 87 00 08 02 88 00 08 02 89 FC 18 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 01 00 D9 FF E2 00 DA FF E2 00 DB FF E2 00 DC FF E2 00 DD FF E2 00 DE FF E2 00 DF FF E2 00 E0 FF E2 00 12 00 1A 00 22 00 2A 00 32 00 3A 00 42 00 4A 00 00 02 39 00 06 02 3A FF FA 02 3B 00 06 02 3C FF FA 02 3D 00 06 02 3E FF FA 02 3F 00 06 02 40 FF FA 02 41 00 06 02 42 FF FA 02 43 00 06 02 44 FF FA 02 45 00 06 02 46 FF FA 02 47 00 06 02 48 FF FA 00 12 00 16 00 1A 00 1E 00 22 00 26 00 2A 00 2E 00 00 02 49 FF E2 02 4B FF E2 02 4D FF E2 02 4F FF E2 02 51 FF E2 02 53 FF E2 02 55 FF E2 02 57 FF E2 00 12 00 22 00 32 00 42 00 52 00 62 00 72 00 82 00 00 02 49 00 09 02 4A 00 09 02 49 00 09 02 4A FF F7 02 4B 00 09 02 4C 00 09 02 4B 00 09 02 4C FF F7 02 4D 00 09 02 4E 00 09 02 4D 00 09 02 4E FF F7 02 4F 00 09 02 50 00 09 02 4F 00 09 02 50 FF F7 02 51 00 09 02 52 00 09 02 51 00 09 02 52 FF F7 02 53 00 09 02 54 00 09 02 53 00 09 02 54 FF F7 02 55 00 09 02 56 00 09 02 55 00 09 02 56 FF F7 02 57 00 09 02 58 00 09 02 57 00 09 02 58 FF F7 00 12 00 26 00 3A 00 4E 00 62 00 76 00 8A 00 9E 00 00 02 59 00 06 02 5A 00 06 02 5B 00 08 02 5A 00 06 02 59 FF FA 02 5C 00 06 02 5D 00 06 02 5E 00 08 02 5D 00 06 02 5C FF FA 02 5F 00 06 02 60 00 06 02 61 00 08 02 60 00 06 02 5F FF FA 02 62 00 06 02 63 00 06 02 64 00 08 02 63 00 06 02 62 FF FA 02 65 00 06 02 66 00 06 02 67 00 08 02 66 00 06 02 65 FF FA 02 68 00 06 02 69 00 06 02 6A 00 08 02 69 00 06 02 68 FF FA 02 6B 00 06 02 6C 00 06 02 6D 00 08 02 6C 00 06 02 6B FF FA 02 6E 00 06 02 6F 00 06 02 70 00 08 02 6F 00 06 02 6E FF FA 00 12 00 2A 00 42 00 5A 00 72 00 8A 00 A2 00 BA 00 00 00 51 00 04 00 58 00 04 01 0D 00 14 00 60 00 04 00 59 00 04 00 5A FF FC 00 52 00 04 00 51 00 04 01 0F 00 14 00 59 00 04 00 5A 00 04 00 5B FF FC 00 53 00 04 00 52 00 04 01 01 00 14 00 5A 00 04 00 5B 00 04 00 5C FF FC 00 54 00 04 00 53 00 04 01 03 00 14 00 5B 00 04 00 5C 00 04 00 5D FF FC 00 55 00 04 00 54 00 04 01 05 00 14 00 5C 00 04 00 5D 00 04 00 5E FF FC 00 56 00 04 00 55 00 04 01 07 00 14 00 5D 00 04 00 5E 00 04 00 5F FF FC 00 57 00 04 00 56 00 04 01 09 00 14 00 5E 00 04 00 5F 00 04 00 60 FF FC 00 58 00 04 00 57 00 04 01 0B 00 14 00 5F 00 04 00 60 00 04 00 59 FF FC 00 12 00 2E 00 4A 00 66 00 82 00 9E 00 BA 00 D6 00 00 02 71 00 06 02 72 00 06 02 73 00 06 02 74 00 06 01 13 00 64 01 14 00 08 01 51 FF F8 02 71 00 06 02 72 00 06 02 73 00 06 02 74 00 06 01 17 00 64 01 18 00 08 01 52 FF F8 02 71 00 06 02 72 00 06 02 73 00 06 02 74 00 06 01 1B 00 64 01 1C 00 08 01 53 FF F8 02 75 00 06 02 76 00 06 02 77 00 06 02 78 00 06 01 1F 00 64 01 20 00 08 01 54 FF F8 02 75 00 06 02 76 00 06 02 77 00 06 02 78 00 06 01 23 00 64 01 24 00 08 01 55 FF F8 02 75 00 06 02 76 00 06 02 77 00 06 02 78 00 06 01 27 00 64 01 28 00 08 01 56 FF F8 02 75 00 06 02 76 00 06 02 77 00 06 02 78 00 06 01 2B 00 64 01 2C 00 08 01 57 FF F8 02 71 00 06 02 72 00 06 02 73 00 06 02 74 00 06 01 2F 00 64 01 30 00 08 01 58 FF F8 00 12 00 12 00 12 00 5A 00 5A 00 5A 00 5A 00 12 00 00 01 11 00 06 01 12 00 06 01 13 00 1E 02 79 00 0A 02 7A 00 0A 02 7B 00 0A 02 7C 00 08 02 7D 00 08 02 7E 00 08 02 7C 00 08 02 7D 00 08 02 7E 00 08 02 7C 00 08 02 7D 00 08 02 7E 00 08 02 7C 00 08 02 7D 00 08 02 7E FC 7C 01 21 00 06 01 22 00 06 01 23 00 1E 02 7F 00 0A 02 80 00 0A 02 81 00 0A 02 82 00 08 02 83 00 08 02 84 00 08 02 82 00 08 02 83 00 08 02 84 00 08 02 82 00 08 02 83 00 08 02 84 00 08 02 82 00 08 02 83 00 08 02 84 FC 7C

