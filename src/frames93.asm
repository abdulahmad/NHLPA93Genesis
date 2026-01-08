; NHLPA Hockey '93 (Sega Genesis) - Auto-generated Frames.asm
; Generated on 2026-01-05
; Matches ROM binary exactly

;This is a data table for animating the graphics in Sprites.anim
;This list equates the sections of the alice animation file Sprites.anim

; Sprite Frame (SPF) base indices
SPFskatewp	=	1
SPFskate	=	SPFskatewp+40; 41
SPFturnl	=	SPFskate+40; 81
SPFturnr	=	SPFturnl+8; 89
SPFswing	=	SPFturnr+8; 97
SPFstop	=	SPFswing+48; 145
SPFskateb	=	SPFstop+16; 161
SPFcelebrate	=	SPFskateb+24; 185
SPFpump	=	SPFcelebrate+16; 201
SPFcup	=	SPFpump+16; 217
SPFhipl	=	SPFcup+8; 225
SPFhipr	=	SPFhipl+8; 233
SPFshoulderl	=	SPFhipr+8; 241
SPFshoulderr	=	SPFshoulderl+8; 249
SPFsweep	=	SPFshoulderr+8; 257

SPFfallback	=	SPFsweep+16; 273
SPFfallfwd	=	SPFfallback+32; 305
SPFduck	=	SPFfallfwd+32; 337
SPFhold	=	SPFduck+8; 345
SPFgloves	=	SPFhold+8; 353
SPFfight	=	SPFgloves+1; 354
SPFfinjury	=	SPFfight+17; 371 - New in NHLPA93
SPFPen	=	SPFfinjury+6; 377

SPFarrow	=	SPFPen+7; 384
SPFpad	=	SPFarrow+6; 390
SPFreplay	=	SPFpad+3; 393 - New in NHLPA93
SPFpuck	=	SPFreplay+1; 394
SPFgoal	=	SPFpuck+11; 405
SPFGoalie	=	SPFgoal+2; 407
SPFgdive	=	SPFGoalie+112; 519 - New in NHLPA93
SPFglovel2	=	SPFgdive+16; 535 - New in NHLPA93
SPFgready	=	SPFglovel2+4; 539 - New in NHLPA93
SPFSiren	=	SPFgready+16; 555

SPFcatch	=	SPFSiren+14; 569 - New in NHLPA93
SPFhook	=	SPFcatch+16; 585 - New in NHLPA93
SPFstumble	=	SPFhook+16; 601 - New in NHLPA93
SPFflip	=	SPFstumble+24; 625 - New in NHLPA93
SPFinjury1	=	SPFflip+8; 633 - New in NHLPA93
SPFbglass	=	SPFinjury1+12; 645 - New in NHLPA93

SPAlist
	dc.w	0

SPAgready	=	*-SPAlist	; 100 match to NHL '92
SPAgready_table: ; 0x004d90
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0036
	dc.w	.2-.t ; 0x005a
	dc.w	.3-.t ; 0x007e
	dc.w	.4-.t ; 0x00a2
	dc.w	.5-.t ; 0x00c6
	dc.w	.6-.t ; 0x00ea
	dc.w	.7-.t ; 0x010e
	dc.w	1

.a	=	SPFGoalie
.aoff	=	3
.b	=	SPFgready
.boff	=	2

.0	dc.w	.a,180,.b,10,.b+1,10,.b,10,.b+1,10,.a,240,.b,10,.b+1,10,.b,-10
.a	set	.a+.aoff
.b	set	.b+.boff
.1	dc.w	.a,130,.b,10,.b+1,10,.b,10,.b+1,10,.a,300,.b,10,.b+1,10,.b,-10
.a	set	.a+.aoff
.b	set	.b+.boff
.2	dc.w	.a,210,.b,10,.b+1,10,.b,10,.b+1,10,.a,120,.b,10,.b+1,10,.b,-10
.a	set	.a+.aoff
.b	set	.b+.boff
.3	dc.w	.a,100,.b,10,.b+1,10,.b,10,.b+1,10,.a,200,.b,10,.b+1,10,.b,-10
.a	set	.a+.aoff
.b	set	.b+.boff
.4	dc.w	.a,240,.b,10,.b+1,10,.b,10,.b+1,10,.a,60,.b,10,.b+1,10,.b,-10
.a	set	.a+.aoff
.b	set	.b+.boff
.5	dc.w	.a,180,.b,10,.b+1,10,.b,10,.b+1,10,.a,240,.b,10,.b+1,10,.b,-10
.a	set	.a+.aoff
.b	set	.b+.boff
.6	dc.w	.a,120,.b,10,.b+1,10,.b,10,.b+1,10,.a,120,.b,10,.b+1,10,.b,-10
.a	set	.a+.aoff
.b	set	.b+.boff
.7	dc.w	.a,180,.b,10,.b+1,10,.b,10,.b+1,10,.a,180,.b,10,.b+1,10,.b,-10

SPAgready2	=	*-SPAlist	; 100 match to NHL '92
SPAgready2_table: ; 0x004ec2
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFGoalie
.aoff	=	3

.0	dc.w	.a,-30
.a	set	.a+.aoff
.1	dc.w	.a,-30
.a	set	.a+.aoff
.2	dc.w	.a,-30
.a	set	.a+.aoff
.3	dc.w	.a,-30
.a	set	.a+.aoff
.4	dc.w	.a,-30
.a	set	.a+.aoff
.5	dc.w	.a,-30
.a	set	.a+.aoff
.6	dc.w	.a,-30
.a	set	.a+.aoff
.7	dc.w	.a,-30

SPAgglover	=	*-SPAlist	; 100 match to NHL '92
SPAgglover_table: ; 0x004ef4
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFGoalie+1
.aoff	=	3

.0	dc.w	.a,-32
.a	set	.a+.aoff
.1	dc.w	.a,-32
.a	set	.a+.aoff
.2	dc.w	.a,-32
.a	set	.a+.aoff
.3	dc.w	.a,-32
.a	set	.a+.aoff
.4	dc.w	.a,-32
.a	set	.a+.aoff
.5	dc.w	.a,-32
.a	set	.a+.aoff
.6	dc.w	.a,-32
.a	set	.a+.aoff
.7	dc.w	.a,-32

SPAgglovel	=	*-SPAlist	; 100 match to NHL '92
SPAgglovel_table: ; 0x004f26
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFGoalie+2
.aoff	=	3

.0	dc.w	.a,-32
.a	set	.a+.aoff
.1	dc.w	.a,-32
.a	set	.a+.aoff
.2	dc.w	.a,-32
.a	set	.a+.aoff
.3	dc.w	.a,-32
.a	set	.a+.aoff
.4	dc.w	.a,-32
.a	set	.a+.aoff
.5	dc.w	.a,-32
.a	set	.a+.aoff
.6	dc.w	.a,-32
.a	set	.a+.aoff
.7	dc.w	.a,-32

SPAgglovel2	=	*-SPAlist	; 100 match to NHL '92
SPAgglovel2_table: ; 0x004f58
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x001e
	dc.w	.2-.t ; 0x0022
	dc.w	.3-.t ; 0x0026
	dc.w	.4-.t ; 0x002a
	dc.w	.5-.t ; 0x0036
	dc.w	.6-.t ; 0x003a
	dc.w	.7-.t ; 0x003e
	dc.w	0

.a	=	SPFglovel2
.b	=	SPFGoalie+5

.0	dc.w	.a,4,.a+1,8,.a,-4
.1	dc.w	.b,-32
.2	dc.w	.b+3,-32
.3	dc.w	.b+6,-32
.4	dc.w	.a+2,4,.a+3,8,.a+2,-4
.5	dc.w	.b+12,-32
.6	dc.w	.b+15,-32
.7	dc.w	.b+18,-32

SPAgstickr	=	*-SPAlist	; 100 match to NHL '92
SPAgstickr_table: ; 0x004f9a
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFGoalie+64
.aoff	=	2

.0	dc.w	.a,-32
.a	set	.a+.aoff
.1	dc.w	.a,-32
.a	set	.a+.aoff
.2	dc.w	.a,-32
.a	set	.a+.aoff
.3	dc.w	.a,-32
.a	set	.a+.aoff
.4	dc.w	.a,-32
.a	set	.a+.aoff
.5	dc.w	.a,-32
.a	set	.a+.aoff
.6	dc.w	.a,-32
.a	set	.a+.aoff
.7	dc.w	.a,-32

SPAgstickl	=	*-SPAlist	; 100 match to NHL '92
SPAgstickl_table: ; 0x004fcc
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFGoalie+65
.aoff	=	2

.0	dc.w	.a,-32
.a	set	.a+.aoff
.1	dc.w	.a,-32
.a	set	.a+.aoff
.2	dc.w	.a,-32
.a	set	.a+.aoff
.3	dc.w	.a,-32
.a	set	.a+.aoff
.4	dc.w	.a,-32
.a	set	.a+.aoff
.5	dc.w	.a,-32
.a	set	.a+.aoff
.6	dc.w	.a,-32
.a	set	.a+.aoff
.7	dc.w	.a,-32

SPAgstackr	=	*-SPAlist	; 100 match to NHL '92
SPAgstackr_table: ; 0x004ffe
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x001a
	dc.w	.2-.t ; 0x0022
	dc.w	.3-.t ; 0x002a
	dc.w	.4-.t ; 0x0032
	dc.w	.5-.t ; 0x003a
	dc.w	.6-.t ; 0x0042
	dc.w	.7-.t ; 0x004a
	dc.w	0

.a	=	SPFGoalie+40

.0	dc.w	.a,8,.a+1,-32
.1	dc.w	.a+2,8,.a+3,-32
.2	dc.w	.a+2,8,.a+3,-32
.3	dc.w	.a+4,8,.a+5,-32
.4	dc.w	.a+6,8,.a+7,-32
.5	dc.w	.a+8,8,.a+9,-32
.6	dc.w	.a+8,8,.a+9,-32
.7	dc.w	.a+10,8,.a+11,-32

SPAgstackl	=	*-SPAlist	; 100 match to NHL '92
SPAgstackl_table: ; 0x005050
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x001a
	dc.w	.2-.t ; 0x0022
	dc.w	.3-.t ; 0x002a
	dc.w	.4-.t ; 0x0032
	dc.w	.5-.t ; 0x003a
	dc.w	.6-.t ; 0x0042
	dc.w	.7-.t ; 0x004a
	dc.w	0

.a	=	SPFGoalie+52

.0	dc.w	.a,8,.a+1,-32
.1	dc.w	.a+2,8,.a+3,-32
.2	dc.w	.a+2,8,.a+3,-32
.3	dc.w	.a+4,8,.a+5,-32
.4	dc.w	.a+6,8,.a+7,-32
.5	dc.w	.a+8,8,.a+9,-32
.6	dc.w	.a+8,8,.a+9,-32
.7	dc.w	.a+10,8,.a+11,-32

SPAgdive	=	*-SPAlist	; 100 match to NHL '92
SPAgdive_table: ; 0x0050a2
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x001e
	dc.w	.2-.t ; 0x002a
	dc.w	.3-.t ; 0x0036
	dc.w	.4-.t ; 0x0042
	dc.w	.5-.t ; 0x004e
	dc.w	.6-.t ; 0x005a
	dc.w	.7-.t ; 0x0066
	dc.w	0

.a	=	SPFgdive
.aoff	=	2

.0	dc.w	.a,8,.a+1,48,.a,-8
.a	set	.a+.aoff
.1	dc.w	.a,8,.a+1,48,.a,-8
.a	set	.a+.aoff
.2	dc.w	.a,8,.a+1,48,.a,-8
.a	set	.a+.aoff
.3	dc.w	.a,8,.a+1,48,.a,-8
.a	set	.a+.aoff
.4	dc.w	.a,8,.a+1,48,.a,-8
.a	set	.a+.aoff
.5	dc.w	.a,8,.a+1,48,.a,-8
.a	set	.a+.aoff
.6	dc.w	.a,8,.a+1,48,.a,-8
.a	set	.a+.aoff
.7	dc.w	.a,8,.a+1,48,.a,-8

SPAgswing	=	*-SPAlist	; 100 match to NHL '92
SPAgswing_table: ; 0x005114
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x001e
	dc.w	.2-.t ; 0x002a
	dc.w	.3-.t ; 0x0036
	dc.w	.4-.t ; 0x0042
	dc.w	.5-.t ; 0x004e
	dc.w	.6-.t ; 0x005a
	dc.w	.7-.t ; 0x0066
	dc.w	0

.a	=	SPFGoalie+24
.aoff	=	2

.0	dc.w	.a,5,.a+1,8,.a,-16
.a	set	.a+.aoff
.1	dc.w	.a,5,.a+1,8,.a,-16
.a	set	.a+.aoff
.2	dc.w	.a,5,.a+1,8,.a,-16
.a	set	.a+.aoff
.3	dc.w	.a,5,.a+1,8,.a,-16
.a	set	.a+.aoff
.4	dc.w	.a,5,.a+1,8,.a,-16
.a	set	.a+.aoff
.5	dc.w	.a,5,.a+1,8,.a,-16
.a	set	.a+.aoff
.6	dc.w	.a,5,.a+1,8,.a,-16
.a	set	.a+.aoff
.7	dc.w	.a,5,.a+1,8,.a,-16

SPAgskate	=	*-SPAlist	; 100 match to NHL '92
SPAgskate_table: ; 0x005186
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0022
	dc.w	.2-.t ; 0x0032
	dc.w	.3-.t ; 0x0042
	dc.w	.4-.t ; 0x0052
	dc.w	.5-.t ; 0x0062
	dc.w	.6-.t ; 0x0072
	dc.w	.7-.t ; 0x0082
	dc.w	0

.a	=	SPFGoalie+80
.aoff	=	4

.0	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-15
.a	set	.a+.aoff
.1	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-15
.a	set	.a+.aoff
.2	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-15
.a	set	.a+.aoff
.3	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-15
.a	set	.a+.aoff
.4	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-15
.a	set	.a+.aoff
.5	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-15
.a	set	.a+.aoff
.6	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-15
.a	set	.a+.aoff
.7	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-15

SPApflip	=	*-SPAlist	; 100 match to NHL '92
SPApflip_table: ; 0x005218
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0032
	dc.w	.2-.t ; 0x0052
	dc.w	.3-.t ; 0x0072
	dc.w	.4-.t ; 0x0092
	dc.w	.5-.t ; 0x0096
	dc.w	.6-.t ; 0x009a
	dc.w	.7-.t ; 0x009e
	dc.w	1

.a	=	SPFpuck+1

.0	dc.w	.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,4,.a+2,4,.a+6,4,.a,-4
.1	dc.w	.a+8,2,.a,2,.a+7,2,.a+4,2,.a+9,2,.a+4,2,.a+7,2,.a,-2
.2	dc.w	.a+3,2,.a+2,2,.a+1,2,.a,2,.a+6,2,.a+2,2,.a+5,2,.a+4,-2
.3	dc.w	.a+7,4,.a,4,.a+8,4,.a,4,.a+7,4,.a+4,4,.a+9,4,.a+4,-4
.4	dc.w	.a,-4096
.5	dc.w	.a,-4096
.6	dc.w	.a+4,-4096
.7	dc.w	.a+4,-4096

SPAglide	=	*-SPAlist	; 100 match to NHL '92
SPAglide_table: ; 0x0052ba
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFskatewp
.aoff	=	5

.0	dc.w	.a,-8
.a	set	.a+.aoff
.1	dc.w	.a,-8
.a	set	.a+.aoff
.2	dc.w	.a,-8
.a	set	.a+.aoff
.3	dc.w	.a,-8
.a	set	.a+.aoff
.4	dc.w	.a,-8
.a	set	.a+.aoff
.5	dc.w	.a,-8
.a	set	.a+.aoff
.6	dc.w	.a,-8
.a	set	.a+.aoff
.7	dc.w	.a,-8

SPAskatewp	=	*-SPAlist	; 100 match to NHL '92
SPAskatewp_table: ; 0x0052ec
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0022
	dc.w	.2-.t ; 0x0032
	dc.w	.3-.t ; 0x0042
	dc.w	.4-.t ; 0x0052
	dc.w	.5-.t ; 0x0062
	dc.w	.6-.t ; 0x0072
	dc.w	.7-.t ; 0x0082
	dc.w	0

.a	=	SPFskatewp+1
.aoff	=	5

.0	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-10
.a	set	.a+.aoff
.1	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-10
.a	set	.a+.aoff
.2	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-10
.a	set	.a+.aoff
.3	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-10
.a	set	.a+.aoff
.4	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-10
.a	set	.a+.aoff
.5	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-10
.a	set	.a+.aoff
.6	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-10
.a	set	.a+.aoff
.7	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-10

SPAskate	=	*-SPAlist	; 100 match to NHL '92
SPAskate_table: ; 0x00537e
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0022
	dc.w	.2-.t ; 0x0032
	dc.w	.3-.t ; 0x0042
	dc.w	.4-.t ; 0x0052
	dc.w	.5-.t ; 0x0062
	dc.w	.6-.t ; 0x0072
	dc.w	.7-.t ; 0x0082
	dc.w	0

.a	=	SPFskate+1
.aoff	=	5

.0	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-10
.a	set	.a+.aoff
.1	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-10
.a	set	.a+.aoff
.2	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-10
.a	set	.a+.aoff
.3	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-10
.a	set	.a+.aoff
.4	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-10
.a	set	.a+.aoff
.5	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-10
.a	set	.a+.aoff
.6	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-10
.a	set	.a+.aoff
.7	dc.w	.a,10,.a+1,10,.a+2,10,.a+3,-10

SPAturnl	=	*-SPAlist	; 100 match to NHL '92
SPAturnl_table: ; 0x005410
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFturnl
.aoff	=	1

.0	dc.w	.a,-8
.a	set	.a+.aoff
.1	dc.w	.a,-8
.a	set	.a+.aoff
.2	dc.w	.a,-8
.a	set	.a+.aoff
.3	dc.w	.a,-8
.a	set	.a+.aoff
.4	dc.w	.a,-8
.a	set	.a+.aoff
.5	dc.w	.a,-8
.a	set	.a+.aoff
.6	dc.w	.a,-8
.a	set	.a+.aoff
.7	dc.w	.a,-8

SPAturnr	=	*-SPAlist	; 100 match to NHL '92
SPAturnr_table: ; 0x005442
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFturnr
.aoff	=	1

.0	dc.w	.a,-8
.a	set	.a+.aoff
.1	dc.w	.a,-8
.a	set	.a+.aoff
.2	dc.w	.a,-8
.a	set	.a+.aoff
.3	dc.w	.a,-8
.a	set	.a+.aoff
.4	dc.w	.a,-8
.a	set	.a+.aoff
.5	dc.w	.a,-8
.a	set	.a+.aoff
.6	dc.w	.a,-8
.a	set	.a+.aoff
.7	dc.w	.a,-8

SPAstop	=	*-SPAlist	; 100 match to NHL '92
SPAstop_table: ; 0x005474
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x001a
	dc.w	.2-.t ; 0x0022
	dc.w	.3-.t ; 0x002a
	dc.w	.4-.t ; 0x0032
	dc.w	.5-.t ; 0x003a
	dc.w	.6-.t ; 0x0042
	dc.w	.7-.t ; 0x004a
	dc.w	1

.a	=	SPFstop
.aoff	=	2

.0	dc.w	.a,4,.a+1,-4
.a	set	.a+.aoff
.1	dc.w	.a,4,.a+1,-4
.a	set	.a+.aoff
.2	dc.w	.a,4,.a+1,-4
.a	set	.a+.aoff
.3	dc.w	.a,4,.a+1,-4
.a	set	.a+.aoff
.4	dc.w	.a,4,.a+1,-4
.a	set	.a+.aoff
.5	dc.w	.a,4,.a+1,-4
.a	set	.a+.aoff
.6	dc.w	.a,4,.a+1,-4
.a	set	.a+.aoff
.7	dc.w	.a,4,.a+1,-4

SPApassf	=	*-SPAlist	; 100 match to NHL '92
SPApassf_table: ; 0x0054c6
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x001e
	dc.w	.2-.t ; 0x002a
	dc.w	.3-.t ; 0x0036
	dc.w	.4-.t ; 0x0042
	dc.w	.5-.t ; 0x004e
	dc.w	.6-.t ; 0x005a
	dc.w	.7-.t ; 0x0066
	dc.w	0

.a	=	SPFswing+3
.aoff	=	6

.0	dc.w	.a,4,.a+1,4,.a+2,-20
.a	set	.a+.aoff
.1	dc.w	.a,4,.a+1,4,.a+2,-20
.a	set	.a+.aoff
.2	dc.w	.a,4,.a+1,4,.a+2,-20
.a	set	.a+.aoff
.3	dc.w	.a,4,.a+1,4,.a+2,-20
.a	set	.a+.aoff
.4	dc.w	.a,4,.a+1,4,.a+2,-20
.a	set	.a+.aoff
.5	dc.w	.a,4,.a+1,4,.a+2,-20
.a	set	.a+.aoff
.6	dc.w	.a,4,.a+1,4,.a+2,-20
.a	set	.a+.aoff
.7	dc.w	.a,4,.a+1,4,.a+2,-20

SPApassb	=	*-SPAlist	; 100 match to NHL '92
SPApassb_table: ; 0x005538
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x001e
	dc.w	.2-.t ; 0x002a
	dc.w	.3-.t ; 0x0036
	dc.w	.4-.t ; 0x0042
	dc.w	.5-.t ; 0x004e
	dc.w	.6-.t ; 0x005a
	dc.w	.7-.t ; 0x0066
	dc.w	0

.a	=	SPFswing+1
.aoff	=	6

.0	dc.w	.a+2,4,.a+1,4,.a,-20
.a	set	.a+.aoff
.1	dc.w	.a+2,4,.a+1,4,.a,-20
.a	set	.a+.aoff
.2	dc.w	.a+2,4,.a+1,4,.a,-20
.a	set	.a+.aoff
.3	dc.w	.a+2,4,.a+1,4,.a,-20
.a	set	.a+.aoff
.4	dc.w	.a+2,4,.a+1,4,.a,-20
.a	set	.a+.aoff
.5	dc.w	.a+2,4,.a+1,4,.a,-20
.a	set	.a+.aoff
.6	dc.w	.a+2,4,.a+1,4,.a,-20
.a	set	.a+.aoff
.7	dc.w	.a+2,4,.a+1,4,.a,-20

SPAshotf	=	*-SPAlist	; 100 match to NHL '92
SPAshotf_table: ; 0x0055aa
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0036
	dc.w	.2-.t ; 0x005a
	dc.w	.3-.t ; 0x007e
	dc.w	.4-.t ; 0x00a2
	dc.w	.5-.t ; 0x00c6
	dc.w	.6-.t ; 0x00ea
	dc.w	.7-.t ; 0x010e
	dc.w	0

.a	=	SPFswing
.aoff	=	6

.0	dc.w	.a+3,4,.a+2,4,.a+1,4,.a,4,.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.aoff
.1	dc.w	.a+3,4,.a+2,4,.a+1,4,.a,4,.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.aoff
.2	dc.w	.a+3,4,.a+2,4,.a+1,4,.a,4,.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.aoff
.3	dc.w	.a+3,4,.a+2,4,.a+1,4,.a,4,.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.aoff
.4	dc.w	.a+3,4,.a+2,4,.a+1,4,.a,4,.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.aoff
.5	dc.w	.a+3,4,.a+2,4,.a+1,4,.a,4,.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.aoff
.6	dc.w	.a+3,4,.a+2,4,.a+1,4,.a,4,.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,-20
.a	set	.a+.aoff
.7	dc.w	.a+3,4,.a+2,4,.a+1,4,.a,4,.a+1,4,.a+2,4,.a+3,4,.a+4,4,.a+5,-20

SPAshotb	=	*-SPAlist	; 100 match to NHL '92
SPAshotb_table: ; 0x0056dc
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0036
	dc.w	.2-.t ; 0x005a
	dc.w	.3-.t ; 0x007e
	dc.w	.4-.t ; 0x00a2
	dc.w	.5-.t ; 0x00c6
	dc.w	.6-.t ; 0x00ea
	dc.w	.7-.t ; 0x010e
	dc.w	0

.a	=	SPFswing+1
.aoff	=	6

.0	dc.w	.a+2,4,.a+3,4,.a+4,4,.a+4,4,.a+4,4,.a+3,4,.a+2,4,.a+1,4,.a,-20
.a	set	.a+.aoff
.1	dc.w	.a+2,4,.a+3,4,.a+4,4,.a+4,4,.a+4,4,.a+3,4,.a+2,4,.a+1,4,.a,-20
.a	set	.a+.aoff
.2	dc.w	.a+2,4,.a+3,4,.a+4,4,.a+4,4,.a+4,4,.a+3,4,.a+2,4,.a+1,4,.a,-20
.a	set	.a+.aoff
.3	dc.w	.a+2,4,.a+3,4,.a+4,4,.a+4,4,.a+4,4,.a+3,4,.a+2,4,.a+1,4,.a,-20
.a	set	.a+.aoff
.4	dc.w	.a+2,4,.a+3,4,.a+4,4,.a+4,4,.a+4,4,.a+3,4,.a+2,4,.a+1,4,.a,-20
.a	set	.a+.aoff
.5	dc.w	.a+2,4,.a+3,4,.a+4,4,.a+4,4,.a+4,4,.a+3,4,.a+2,4,.a+1,4,.a,-20
.a	set	.a+.aoff
.6	dc.w	.a+2,4,.a+3,4,.a+4,4,.a+4,4,.a+4,4,.a+3,4,.a+2,4,.a+1,4,.a,-20
.a	set	.a+.aoff
.7	dc.w	.a+2,4,.a+3,4,.a+4,4,.a+4,4,.a+4,4,.a+3,4,.a+2,4,.a+1,4,.a,-20

SPAglideback	=	*-SPAlist	; 100 match to NHL '92
SPAglideback_table: ; 0x00580e
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFskateb
.aoff	=	3

.0	dc.w	.a,-8
.a	set	.a+.aoff
.1	dc.w	.a,-8
.a	set	.a+.aoff
.2	dc.w	.a,-8
.a	set	.a+.aoff
.3	dc.w	.a,-8
.a	set	.a+.aoff
.4	dc.w	.a,-8
.a	set	.a+.aoff
.5	dc.w	.a,-8
.a	set	.a+.aoff
.6	dc.w	.a,-8
.a	set	.a+.aoff
.7	dc.w	.a,-8

SPAskateback	=	*-SPAlist	; 100 match to NHL '92
SPAskateback_table: ; 0x005840
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0022
	dc.w	.2-.t ; 0x0032
	dc.w	.3-.t ; 0x0042
	dc.w	.4-.t ; 0x0052
	dc.w	.5-.t ; 0x0062
	dc.w	.6-.t ; 0x0072
	dc.w	.7-.t ; 0x0082
	dc.w	0

.a	=	SPFskateb
.aoff	=	3

.0	dc.w	.a,10,.a+1,10,.a,10,.a+2,-10
.a	set	.a+.aoff
.1	dc.w	.a,10,.a+1,10,.a,10,.a+2,-10
.a	set	.a+.aoff
.2	dc.w	.a,10,.a+1,10,.a,10,.a+2,-10
.a	set	.a+.aoff
.3	dc.w	.a,10,.a+1,10,.a,10,.a+2,-10
.a	set	.a+.aoff
.4	dc.w	.a,10,.a+1,10,.a,10,.a+2,-10
.a	set	.a+.aoff
.5	dc.w	.a,10,.a+1,10,.a,10,.a+2,-10
.a	set	.a+.aoff
.6	dc.w	.a,10,.a+1,10,.a,10,.a+2,-10
.a	set	.a+.aoff
.7	dc.w	.a,10,.a+1,10,.a,10,.a+2,-10

SPAsweepchk	=	*-SPAlist	; 100 match to NHL '92
SPAsweepchk_table: ; 0x0058d2
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x001e
	dc.w	.2-.t ; 0x002a
	dc.w	.3-.t ; 0x0036
	dc.w	.4-.t ; 0x0042
	dc.w	.5-.t ; 0x004e
	dc.w	.6-.t ; 0x005a
	dc.w	.7-.t ; 0x0066
	dc.w	0

.a	=	SPFsweep
.aoff	=	2

.0	dc.w	.a,4,.a+1,8,.a,-4
.a	set	.a+.aoff
.1	dc.w	.a,4,.a+1,8,.a,-4
.a	set	.a+.aoff
.2	dc.w	.a,4,.a+1,8,.a,-4
.a	set	.a+.aoff
.3	dc.w	.a,4,.a+1,8,.a,-4
.a	set	.a+.aoff
.4	dc.w	.a,4,.a+1,8,.a,-4
.a	set	.a+.aoff
.5	dc.w	.a,4,.a+1,8,.a,-4
.a	set	.a+.aoff
.6	dc.w	.a,4,.a+1,8,.a,-4
.a	set	.a+.aoff
.7	dc.w	.a,4,.a+1,8,.a,-4

SPAshoulderchkl	=	*-SPAlist	; 100 match to NHL '92
SPAshoulderchkl_table: ; 0x005944
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFshoulderl
.aoff	=	1

.0	dc.w	.a,-24
.a	set	.a+.aoff
.1	dc.w	.a,-24
.a	set	.a+.aoff
.2	dc.w	.a,-24
.a	set	.a+.aoff
.3	dc.w	.a,-24
.a	set	.a+.aoff
.4	dc.w	.a,-24
.a	set	.a+.aoff
.5	dc.w	.a,-24
.a	set	.a+.aoff
.6	dc.w	.a,-24
.a	set	.a+.aoff
.7	dc.w	.a,-24

SPAshoulderchkr	=	*-SPAlist	; 100 match to NHL '92
SPAshoulderchkr_table: ; 0x005976
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFshoulderr
.aoff	=	1

.0	dc.w	.a,-24
.a	set	.a+.aoff
.1	dc.w	.a,-24
.a	set	.a+.aoff
.2	dc.w	.a,-24
.a	set	.a+.aoff
.3	dc.w	.a,-24
.a	set	.a+.aoff
.4	dc.w	.a,-24
.a	set	.a+.aoff
.5	dc.w	.a,-24
.a	set	.a+.aoff
.6	dc.w	.a,-24
.a	set	.a+.aoff
.7	dc.w	.a,-24

SPAhipchkl	=	*-SPAlist	; 100 match to NHL '92
SPAhipchkl_table: ; 0x0059a8
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFhipl
.aoff	=	1

.0	dc.w	.a,-24
.a	set	.a+.aoff
.1	dc.w	.a,-24
.a	set	.a+.aoff
.2	dc.w	.a,-24
.a	set	.a+.aoff
.3	dc.w	.a,-24
.a	set	.a+.aoff
.4	dc.w	.a,-24
.a	set	.a+.aoff
.5	dc.w	.a,-24
.a	set	.a+.aoff
.6	dc.w	.a,-24
.a	set	.a+.aoff
.7	dc.w	.a,-24

SPAhipchkr	=	*-SPAlist	; 100 match to NHL '92
SPAhipchkr_table: ; 0x0059da
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFhipr
.aoff	=	1

.0	dc.w	.a,-24
.a	set	.a+.aoff
.1	dc.w	.a,-24
.a	set	.a+.aoff
.2	dc.w	.a,-24
.a	set	.a+.aoff
.3	dc.w	.a,-24
.a	set	.a+.aoff
.4	dc.w	.a,-24
.a	set	.a+.aoff
.5	dc.w	.a,-24
.a	set	.a+.aoff
.6	dc.w	.a,-24
.a	set	.a+.aoff
.7	dc.w	.a,-24

SPAburst	=	*-SPAlist	; 100 match to NHL '92
SPAburst_table: ; 0x005a0c
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFskate
.aoff	=	5

.0	dc.w	.a,-24
.a	set	.a+.aoff
.1	dc.w	.a,-24
.a	set	.a+.aoff
.2	dc.w	.a,-24
.a	set	.a+.aoff
.3	dc.w	.a,-24
.a	set	.a+.aoff
.4	dc.w	.a,-24
.a	set	.a+.aoff
.5	dc.w	.a,-24
.a	set	.a+.aoff
.6	dc.w	.a,-24
.a	set	.a+.aoff
.7	dc.w	.a,-24

SPAHold	=	*-SPAlist	; 100 match to NHL '92
SPAHold_table: ; 0x005a3e
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFhold
.aoff	=	1

.0	dc.w	.a,-30
.a	set	.a+.aoff
.1	dc.w	.a,-30
.a	set	.a+.aoff
.2	dc.w	.a,-30
.a	set	.a+.aoff
.3	dc.w	.a,-30
.a	set	.a+.aoff
.4	dc.w	.a,-30
.a	set	.a+.aoff
.5	dc.w	.a,-30
.a	set	.a+.aoff
.6	dc.w	.a,-30
.a	set	.a+.aoff
.7	dc.w	.a,-30

SPAHold2	=	*-SPAlist	; 100 match to NHL '92
SPAHold2_table: ; 0x005a70
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFhold
.aoff	=	1

.0	dc.w	.a,-30
.a	set	.a+.aoff
.1	dc.w	.a,-30
.a	set	.a+.aoff
.2	dc.w	.a,-30
.a	set	.a+.aoff
.3	dc.w	.a,-30
.a	set	.a+.aoff
.4	dc.w	.a,-30
.a	set	.a+.aoff
.5	dc.w	.a,-30
.a	set	.a+.aoff
.6	dc.w	.a,-30
.a	set	.a+.aoff
.7	dc.w	.a,-30

SPAflail	=	*-SPAlist	; 100 match to NHL '92
SPAflail_table: ; 0x005aa2
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFskate
.aoff	=	5

.0	dc.w	.a,-30
.a	set	.a+.aoff
.1	dc.w	.a,-30
.a	set	.a+.aoff
.2	dc.w	.a,-30
.a	set	.a+.aoff
.3	dc.w	.a,-30
.a	set	.a+.aoff
.4	dc.w	.a,-30
.a	set	.a+.aoff
.5	dc.w	.a,-30
.a	set	.a+.aoff
.6	dc.w	.a,-30
.a	set	.a+.aoff
.7	dc.w	.a,-30

SPAfallfwd	=	*-SPAlist	; 100 match to NHL '92
SPAfallfwd_table: ; 0x005ad4
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0026
	dc.w	.2-.t ; 0x003a
	dc.w	.3-.t ; 0x004e
	dc.w	.4-.t ; 0x0062
	dc.w	.5-.t ; 0x0076
	dc.w	.6-.t ; 0x008a
	dc.w	.7-.t ; 0x009e
	dc.w	0

.a	=	SPFfallfwd
.aoff	=	4
.b	=	SPFduck
.boff	=	1

.0	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.aoff
.b	set	.b+.boff
.1	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.aoff
.b	set	.b+.boff
.2	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.aoff
.b	set	.b+.boff
.3	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.aoff
.b	set	.b+.boff
.4	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.aoff
.b	set	.b+.boff
.5	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.aoff
.b	set	.b+.boff
.6	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.aoff
.b	set	.b+.boff
.7	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8

SPAfallback	=	*-SPAlist	; 100 match to NHL '92
SPAfallback_table: ; 0x005b86
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0026
	dc.w	.2-.t ; 0x003a
	dc.w	.3-.t ; 0x004e
	dc.w	.4-.t ; 0x0062
	dc.w	.5-.t ; 0x0076
	dc.w	.6-.t ; 0x008a
	dc.w	.7-.t ; 0x009e
	dc.w	0

.a	=	SPFfallback
.aoff	=	4
.b	=	SPFduck
.boff	=	1

.0	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.aoff
.b	set	.b+.boff
.1	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.aoff
.b	set	.b+.boff
.2	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.aoff
.b	set	.b+.boff
.3	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.aoff
.b	set	.b+.boff
.4	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.aoff
.b	set	.b+.boff
.5	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.aoff
.b	set	.b+.boff
.6	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8
.a	set	.a+.aoff
.b	set	.b+.boff
.7	dc.w	.a,6,.a+1,6,.a+2,100,.a+3,8,.b,-8

SPAcelebrate	=	*-SPAlist	; 100 match to NHL '92
SPAcelebrate_table: ; 0x005c38
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x001e
	dc.w	.2-.t ; 0x002a
	dc.w	.3-.t ; 0x0036
	dc.w	.4-.t ; 0x0042
	dc.w	.5-.t ; 0x004e
	dc.w	.6-.t ; 0x005a
	dc.w	.7-.t ; 0x0066
	dc.w	0

.a	=	SPFcelebrate
.aoff	=	2

.0	dc.w	.a,12,.a+1,40,.a,-5
.a	set	.a+.aoff
.1	dc.w	.a,12,.a+1,40,.a,-5
.a	set	.a+.aoff
.2	dc.w	.a,12,.a+1,40,.a,-5
.a	set	.a+.aoff
.3	dc.w	.a,12,.a+1,40,.a,-5
.a	set	.a+.aoff
.4	dc.w	.a,12,.a+1,40,.a,-5
.a	set	.a+.aoff
.5	dc.w	.a,12,.a+1,40,.a,-5
.a	set	.a+.aoff
.6	dc.w	.a,12,.a+1,40,.a,-5
.a	set	.a+.aoff
.7	dc.w	.a,12,.a+1,40,.a,-5

SPApump	=	*-SPAlist	; 100 match to NHL '92
SPApump_table: ; 0x005caa
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x001e
	dc.w	.2-.t ; 0x002a
	dc.w	.3-.t ; 0x0036
	dc.w	.4-.t ; 0x0042
	dc.w	.5-.t ; 0x004e
	dc.w	.6-.t ; 0x005a
	dc.w	.7-.t ; 0x0066
	dc.w	0

.a	=	SPFpump
.aoff	=	2

.0	dc.w	.a,8,.a+1,8,.a,-8
.a	set	.a+.aoff
.1	dc.w	.a,8,.a+1,8,.a,-8
.a	set	.a+.aoff
.2	dc.w	.a,8,.a+1,8,.a,-8
.a	set	.a+.aoff
.3	dc.w	.a,8,.a+1,8,.a,-8
.a	set	.a+.aoff
.4	dc.w	.a,8,.a+1,8,.a,-8
.a	set	.a+.aoff
.5	dc.w	.a,8,.a+1,8,.a,-8
.a	set	.a+.aoff
.6	dc.w	.a,8,.a+1,8,.a,-8
.a	set	.a+.aoff
.7	dc.w	.a,8,.a+1,8,.a,-8

SPAfight	=	*-SPAlist	; 100 match to NHL '92
SPAfight_table: ; 0x005d1c
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0012
	dc.w	.2-.t ; 0x0012
	dc.w	.3-.t ; 0x0022
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0022
	dc.w	.6-.t ; 0x0022
	dc.w	.7-.t ; 0x0022
	dc.w	0

.a	=	SPFfight

.0
.1
.2	dc.w	.a,8,.a+1,8,.a+2,8,.a+3,-6
.3
.4
.5
.6
.7	dc.w	.a,8,.a+1,8,.a+2,8,.a+8,-6

SPAfgrab	=	*-SPAlist	; 100 match to NHL '92
SPAfgrab_table: ; 0x005d4e
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0012
	dc.w	.2-.t ; 0x0012
	dc.w	.3-.t ; 0x001a
	dc.w	.4-.t ; 0x001a
	dc.w	.5-.t ; 0x001a
	dc.w	.6-.t ; 0x001a
	dc.w	.7-.t ; 0x001a
	dc.w	0

.a	=	SPFfight+3

.0
.1
.2	dc.w	.a+1,28,.a,-4
.3
.4
.5
.6
.7	dc.w	.a+6,28,.a+5,-4

SPAfheld	=	*-SPAlist	; 100 match to NHL '92
SPAfheld_table: ; 0x005d70
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0012
	dc.w	.2-.t ; 0x0012
	dc.w	.3-.t ; 0x001a
	dc.w	.4-.t ; 0x001a
	dc.w	.5-.t ; 0x001a
	dc.w	.6-.t ; 0x001a
	dc.w	.7-.t ; 0x001a
	dc.w	0

.a	=	SPFfight+3

.0
.1
.2	dc.w	.a+1,30,.a,-4
.3
.4
.5
.6
.7	dc.w	.a+6,30,.a+5,-4

SPAfhigh	=	*-SPAlist	; 100 match to NHL '92
SPAfhigh_table: ; 0x005d92
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0012
	dc.w	.2-.t ; 0x0012
	dc.w	.3-.t ; 0x0022
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0022
	dc.w	.6-.t ; 0x0022
	dc.w	.7-.t ; 0x0022
	dc.w	0

.a	=	SPFfight+3

.0
.1
.2	dc.w	.a+2,6,.a+3,16,.a+2,4,.a,-16
.3
.4
.5
.6
.7	dc.w	.a+7,6,.a+8,16,.a+7,4,.a+5,-16

SPAflow	=	*-SPAlist	; 100 match to NHL '92
SPAflow_table: ; 0x005dc4
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0012
	dc.w	.2-.t ; 0x0012
	dc.w	.3-.t ; 0x0022
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0022
	dc.w	.6-.t ; 0x0022
	dc.w	.7-.t ; 0x0022
	dc.w	0

.a	=	SPFfight+3

.0
.1
.2	dc.w	.a+2,6,.a+4,16,.a+2,4,.a,-16
.3
.4
.5
.6
.7	dc.w	.a+7,6,.a+9,16,.a+7,4,.a+5,-16

SPAfhith	=	*-SPAlist	; 100 match to NHL '92
SPAfhith_table: ; 0x005df6
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0012
	dc.w	.2-.t ; 0x0012
	dc.w	.3-.t ; 0x001a
	dc.w	.4-.t ; 0x001a
	dc.w	.5-.t ; 0x001a
	dc.w	.6-.t ; 0x001a
	dc.w	.7-.t ; 0x001a
	dc.w	0

.a	=	SPFfight+3

.0
.1
.2	dc.w	.a+11,16,.a,-8
.3
.4
.5
.6
.7	dc.w	.a+11,16,.a+5,-8

SPAfhitl	=	*-SPAlist	; 100 match to NHL '92
SPAfhitl_table: ; 0x005e18
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0012
	dc.w	.2-.t ; 0x0012
	dc.w	.3-.t ; 0x001a
	dc.w	.4-.t ; 0x001a
	dc.w	.5-.t ; 0x001a
	dc.w	.6-.t ; 0x001a
	dc.w	.7-.t ; 0x001a
	dc.w	0

.a	=	SPFfight+3

.0
.1
.2	dc.w	.a+10,16,.a,-8
.3
.4
.5
.6
.7	dc.w	.a+10,16,.a+5,-8

SPAffall	=	*-SPAlist	; 100 match to NHL '92
SPAffall_table: ; 0x005e3a
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0012
	dc.w	.2-.t ; 0x0012
	dc.w	.3-.t ; 0x0012
	dc.w	.4-.t ; 0x0012
	dc.w	.5-.t ; 0x0012
	dc.w	.6-.t ; 0x0012
	dc.w	.7-.t ; 0x0012
	dc.w	0

.a	=	SPFfight+14

.0
.1
.2
.3
.4
.5
.6
.7	dc.w	.a,8,.a+1,8,.a+2,200,.a+2,-2

SPAfinjury	=	*-SPAlist	; 100 match to NHL '92
SPAfinjury_table: ; 0x005e5c
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0012
	dc.w	.2-.t ; 0x0012
	dc.w	.3-.t ; 0x0012
	dc.w	.4-.t ; 0x0012
	dc.w	.5-.t ; 0x0012
	dc.w	.6-.t ; 0x0012
	dc.w	.7-.t ; 0x0012
	dc.w	0

.a	=	SPFfight+14
.b	=	SPFfinjury

.0
.1
.2
.3
.4
.5
.6
.7	dc.w	.a,8,.a+1,8,.a+2,20,.b,8,.b+1,8,.b+2,8,.b+3,10,.b+4,10,.b+5,10,.b+3,10,.b+4,10,.b+5,10,.b+3,10,.b+4,10,.b+5,10,.b+3,10,.b+4,10,.b+5,-400

SPAwallright	=	*-SPAlist	; 100 match to NHL '92
SPAwallright_table: ; 0x005eb6
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x001e
	dc.w	.2-.t ; 0x001e
	dc.w	.3-.t ; 0x002e
	dc.w	.4-.t ; 0x002e
	dc.w	.5-.t ; 0x002e
	dc.w	.6-.t ; 0x002e
	dc.w	.7-.t ; 0x003e
	dc.w	0

.a	=	SPFPen

.0	dc.w	.a+4,8,.a+5,8,.a+6,-8
.1
.2	dc.w	.a,8,.a+1,8,.a+2,8,.a+3,-8
.3
.4
.5
.6	dc.w	.a+3,8,.a+2,8,.a+1,8,.a,-8
.7	; (skipped)

SPAwallleft	=	*-SPAlist	; 100 match to NHL '92
SPAwallleft_table: ; 0x005ef4
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x001e
	dc.w	.2-.t ; 0x001e
	dc.w	.3-.t ; 0x002e
	dc.w	.4-.t ; 0x002e
	dc.w	.5-.t ; 0x002e
	dc.w	.6-.t ; 0x002e
	dc.w	.7-.t ; 0x003e
	dc.w	0

.a	=	SPFPen

.0	dc.w	.a+6,8,.a+5,8,.a+4,-8
.1
.2	dc.w	.a+3,8,.a+2,8,.a+1,8,.a,-8
.3
.4
.5
.6	dc.w	.a,8,.a+1,8,.a+2,8,.a+3,-8
.7	; (skipped)

SPAfaceoff	=	*-SPAlist	; 100 match to NHL '92
SPAfaceoff_table: ; 0x005f32
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x001e
	dc.w	.2-.t ; 0x001e
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x001e
	dc.w	.5-.t ; 0x001e
	dc.w	.6-.t ; 0x001e
	dc.w	.7-.t ; 0x001e
	dc.w	0

.a	=	SPFskatewp
.b	=	SPFsweep

.0	dc.w	.a,2,.b+1,10,.b,-6
.1
.2
.3
.4
.5
.6
.7	dc.w	.a+20,2,.b+9,10,.b+8,-6

SPAfaceoffr	=	*-SPAlist	; 100 match to NHL '92
SPAfaceoffr_table: ; 0x005f5c
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x0016
	dc.w	.3-.t ; 0x0016
	dc.w	.4-.t ; 0x0016
	dc.w	.5-.t ; 0x0016
	dc.w	.6-.t ; 0x0016
	dc.w	.7-.t ; 0x0016
	dc.w	0

.a	=	SPFskatewp

.0	dc.w	.a,-5
.1
.2
.3
.4
.5
.6
.7	dc.w	.a+20,-5

SPAsiren	=	*-SPAlist	; 100 match to NHL '92
SPAsiren_table: ; 0x005f76
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0012
	dc.w	.2-.t ; 0x0012
	dc.w	.3-.t ; 0x0012
	dc.w	.4-.t ; 0x0012
	dc.w	.5-.t ; 0x0012
	dc.w	.6-.t ; 0x0012
	dc.w	.7-.t ; 0x0012
	dc.w	1

.a	=	SPFSiren

.0
.1
.2
.3
.4
.5
.6
.7	dc.w	.a,3,.a+1,3,.a+2,3,.a+3,3,.a+4,3,.a+5,3,.a+6,3,.a+7,3,.a+8,3,.a+9,3,.a+10,3,.a+11,3,.a+12,3,.a+13,-3

SPAbglass	=	*-SPAlist	; 100 match to NHL '92
SPAbglass_table: ; 0x005fc0
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0012
	dc.w	.2-.t ; 0x0012
	dc.w	.3-.t ; 0x0012
	dc.w	.4-.t ; 0x0012
	dc.w	.5-.t ; 0x0012
	dc.w	.6-.t ; 0x0012
	dc.w	.7-.t ; 0x0012
	dc.w	0

.a	=	SPFbglass

.0
.1
.2
.3
.4
.5
.6
.7	dc.w	.a,8,.a+1,8,.a+2,8,.a+3,8,.a+4,-1000

SPAstanley	=	*-SPAlist	; 100 match to NHL '92
SPAstanley_table: ; 0x005fe6
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	1

.a	=	SPFcup
.aoff	=	1

.0	dc.w	.a,-30
.a	set	.a+.aoff
.1	dc.w	.a,-30
.a	set	.a+.aoff
.2	dc.w	.a,-30
.a	set	.a+.aoff
.3	dc.w	.a,-30
.a	set	.a+.aoff
.4	dc.w	.a,-30
.a	set	.a+.aoff
.5	dc.w	.a,-30
.a	set	.a+.aoff
.6	dc.w	.a,-30
.a	set	.a+.aoff
.7	dc.w	.a,-30

SPAcatch	=	*-SPAlist	; 100 match to NHL '92
SPAcatch_table: ; 0x006018
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x001a
	dc.w	.2-.t ; 0x0022
	dc.w	.3-.t ; 0x002a
	dc.w	.4-.t ; 0x0032
	dc.w	.5-.t ; 0x003a
	dc.w	.6-.t ; 0x0042
	dc.w	.7-.t ; 0x004a
	dc.w	0

.a	=	SPFcatch
.aoff	=	2

.0	dc.w	.a,6,.a+1,-6
.a	set	.a+.aoff
.1	dc.w	.a,6,.a+1,-6
.a	set	.a+.aoff
.2	dc.w	.a,6,.a+1,-6
.a	set	.a+.aoff
.3	dc.w	.a,6,.a+1,-6
.a	set	.a+.aoff
.4	dc.w	.a,6,.a+1,-6
.a	set	.a+.aoff
.5	dc.w	.a,6,.a+1,-6
.a	set	.a+.aoff
.6	dc.w	.a,6,.a+1,-6
.a	set	.a+.aoff
.7	dc.w	.a,6,.a+1,-6

SPAhook	=	*-SPAlist	; 100 match to NHL '92
SPAhook_table: ; 0x00606a
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0016
	dc.w	.2-.t ; 0x001a
	dc.w	.3-.t ; 0x001e
	dc.w	.4-.t ; 0x0022
	dc.w	.5-.t ; 0x0026
	dc.w	.6-.t ; 0x002a
	dc.w	.7-.t ; 0x002e
	dc.w	0

.a	=	SPFhook
.aoff	=	2

.0	dc.w	.a,-30
.a	set	.a+.aoff
.1	dc.w	.a,-30
.a	set	.a+.aoff
.2	dc.w	.a,-30
.a	set	.a+.aoff
.3	dc.w	.a,-30
.a	set	.a+.aoff
.4	dc.w	.a,-30
.a	set	.a+.aoff
.5	dc.w	.a,-30
.a	set	.a+.aoff
.6	dc.w	.a,-30
.a	set	.a+.aoff
.7	dc.w	.a,-30

SPAhook2	=	*-SPAlist	; 100 match to NHL '92
SPAhook2_table: ; 0x00609c
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0022
	dc.w	.2-.t ; 0x0032
	dc.w	.3-.t ; 0x0042
	dc.w	.4-.t ; 0x0052
	dc.w	.5-.t ; 0x0062
	dc.w	.6-.t ; 0x0072
	dc.w	.7-.t ; 0x0082
	dc.w	0

.a	=	SPFhook
.aoff	=	2

.0	dc.w	.a,9,.a+1,9,.a,9,.a+1,-9
.a	set	.a+.aoff
.1	dc.w	.a,9,.a+1,9,.a,9,.a+1,-9
.a	set	.a+.aoff
.2	dc.w	.a,9,.a+1,9,.a,9,.a+1,-9
.a	set	.a+.aoff
.3	dc.w	.a,9,.a+1,9,.a,9,.a+1,-9
.a	set	.a+.aoff
.4	dc.w	.a,9,.a+1,9,.a,9,.a+1,-9
.a	set	.a+.aoff
.5	dc.w	.a,9,.a+1,9,.a,9,.a+1,-9
.a	set	.a+.aoff
.6	dc.w	.a,9,.a+1,9,.a,9,.a+1,-9
.a	set	.a+.aoff
.7	dc.w	.a,9,.a+1,9,.a,9,.a+1,-9

SPAstumble	=	*-SPAlist	; 100 match to NHL '92
SPAstumble_table: ; 0x00612e
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0026
	dc.w	.2-.t ; 0x003a
	dc.w	.3-.t ; 0x004e
	dc.w	.4-.t ; 0x0062
	dc.w	.5-.t ; 0x0076
	dc.w	.6-.t ; 0x008a
	dc.w	.7-.t ; 0x009e
	dc.w	0

.a	=	SPFstumble
.aoff	=	3

.0	dc.w	.a,6,.a+1,6,.a+2,8,.a+1,6,.a,-6
.a	set	.a+.aoff
.1	dc.w	.a,6,.a+1,6,.a+2,8,.a+1,6,.a,-6
.a	set	.a+.aoff
.2	dc.w	.a,6,.a+1,6,.a+2,8,.a+1,6,.a,-6
.a	set	.a+.aoff
.3	dc.w	.a,6,.a+1,6,.a+2,8,.a+1,6,.a,-6
.a	set	.a+.aoff
.4	dc.w	.a,6,.a+1,6,.a+2,8,.a+1,6,.a,-6
.a	set	.a+.aoff
.5	dc.w	.a,6,.a+1,6,.a+2,8,.a+1,6,.a,-6
.a	set	.a+.aoff
.6	dc.w	.a,6,.a+1,6,.a+2,8,.a+1,6,.a,-6
.a	set	.a+.aoff
.7	dc.w	.a,6,.a+1,6,.a+2,8,.a+1,6,.a,-6

SPAfake	=	*-SPAlist	; 100 match to NHL '92
SPAfake_table: ; 0x0061e0
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x002a
	dc.w	.2-.t ; 0x0042
	dc.w	.3-.t ; 0x005a
	dc.w	.4-.t ; 0x0072
	dc.w	.5-.t ; 0x008a
	dc.w	.6-.t ; 0x00a2
	dc.w	.7-.t ; 0x00ba
	dc.w	0

.a	=	SPFturnl
.b	=	SPFsweep
.c	=	SPFturnr

.0	dc.w	.a,4,.a+7,4,.b+12,20,.c+7,4,.c,4,.c+1,-4
.1	dc.w	.a+1,4,.a,4,.b+14,20,.c,4,.c+1,4,.c+2,-4
.2	dc.w	.a+2,4,.a+1,4,.b,20,.c+1,4,.c+2,4,.c+3,-4
.3	dc.w	.a+3,4,.a+2,4,.b+2,20,.c+2,4,.c+3,4,.c+4,-4
.4	dc.w	.a+4,4,.a+3,4,.b+4,20,.c+3,4,.c+4,4,.c+5,-4
.5	dc.w	.a+5,4,.a+4,4,.b+6,20,.c+4,4,.c+5,4,.c+6,-4
.6	dc.w	.a+6,4,.a+5,4,.b+8,20,.c+5,4,.c+6,4,.c+7,-4
.7	dc.w	.a+7,4,.a+6,4,.b+10,20,.c+6,4,.c+7,4,.c,-4

SPAflip	=	*-SPAlist	; 100 match to NHL '92
SPAflip_table: ; 0x0062b2
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x002e
	dc.w	.2-.t ; 0x004a
	dc.w	.3-.t ; 0x0066
	dc.w	.4-.t ; 0x0082
	dc.w	.5-.t ; 0x009e
	dc.w	.6-.t ; 0x00ba
	dc.w	.7-.t ; 0x00d6
	dc.w	0

.a	=	SPFflip
.b	=	SPFfallback+2
.boff	=	4
.c	=	SPFduck
.coff	=	1

.0	dc.w	.a,6,.a+1,6,.a+2,6,.a+3,6,.b,100,.b+1,8,.c,-8
.b	set	.b+.boff
.c	set	.c+.coff
.1	dc.w	.a,6,.a+1,6,.a+2,6,.a+3,6,.b,100,.b+1,8,.c,-8
.b	set	.b+.boff
.c	set	.c+.coff
.2	dc.w	.a,6,.a+1,6,.a+2,6,.a+3,6,.b,100,.b+1,8,.c,-8
.b	set	.b+.boff
.c	set	.c+.coff
.3	dc.w	.a+4,6,.a+5,6,.a+6,6,.a+7,6,.b,100,.b+1,8,.c,-8
.b	set	.b+.boff
.c	set	.c+.coff
.4	dc.w	.a+4,6,.a+5,6,.a+6,6,.a+7,6,.b,100,.b+1,8,.c,-8
.b	set	.b+.boff
.c	set	.c+.coff
.5	dc.w	.a+4,6,.a+5,6,.a+6,6,.a+7,6,.b,100,.b+1,8,.c,-8
.b	set	.b+.boff
.c	set	.c+.coff
.6	dc.w	.a+4,6,.a+5,6,.a+6,6,.a+7,6,.b,100,.b+1,8,.c,-8
.b	set	.b+.boff
.c	set	.c+.coff
.7	dc.w	.a,6,.a+1,6,.a+2,6,.a+3,6,.b,100,.b+1,8,.c,-8

SPAinjury1	=	*-SPAlist	; 100 match to NHL '92
SPAinjury1_table: ; 0x0063a4
.t	;offset to each direction of animation (0-7)
	dc.w	.0-.t ; 0x0012
	dc.w	.1-.t ; 0x0012
	dc.w	.2-.t ; 0x0012
	dc.w	.3-.t ; 0x005a
	dc.w	.4-.t ; 0x005a
	dc.w	.5-.t ; 0x005a
	dc.w	.6-.t ; 0x005a
	dc.w	.7-.t ; 0x0012
	dc.w	0

.a	=	SPFfallback
.b	=	SPFinjury1

.7
.0
.1
.2	dc.w	.a,6,.a+1,6,.a+2,30,.b,10,.b+1,10,.b+2,10,.b+3,8,.b+4,8,.b+5,8,.b+3,8,.b+4,8,.b+5,8,.b+3,8,.b+4,8,.b+5,8,.b+3,8,.b+4,8,.b+5,-900
.3
.4
.5
.6	dc.w	.a+16,6,.a+17,6,.a+18,30,.b+6,10,.b+7,10,.b+8,10,.b+9,8,.b+10,8,.b+11,8,.b+9,8,.b+10,8,.b+11,8,.b+9,8,.b+10,8,.b+11,8,.b+9,8,.b+10,8,.b+11,-900

; End of animation list