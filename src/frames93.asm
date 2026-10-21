;	Sprite frame tables. They tell the animation code where each group of frames starts in the sprite graphics
;	and where each animation's list begins.
;
;	First the SPF equates: the first frame number of each group of frames in Sprites.anim ("New" marks groups
;	added in 93). Then SPAlist and one table per animation, in the order of the SPA numbers.

; Sprite Frame (SPF) base indices
SPFskatewp	=	1					;skating, stick down
SPFskate	=	SPFskatewp+40		; 41 (skating, stick up)
SPFturnl	=	SPFskate+40			; 81 (turning left)
SPFturnr	=	SPFturnl+8			; 89 (turning right)
SPFswing	=	SPFturnr+8			; 97 (pass and shot swings)
SPFstop	=	SPFswing+48				; 145 (scrape stop)
SPFskateb	=	SPFstop+16			; 161 (skating backwards)
SPFcelebrate	=	SPFskateb+24	; 185 (celebrating)
SPFpump	=	SPFcelebrate+16			; 201 (arm pump)
SPFcup	=	SPFpump+16				; 217 (skating with the cup)
SPFhipl	=	SPFcup+8				; 225 (hip check left)
SPFhipr	=	SPFhipl+8				; 233 (hip check right)
SPFshoulderl	=	SPFhipr+8		; 241 (shoulder check left)
SPFshoulderr	=	SPFshoulderl+8	; 249 (shoulder check right)
SPFsweep	=	SPFshoulderr+8		; 257 (sweep check)

SPFfallback	=	SPFsweep+16			; 273 (falling backward)
SPFfallfwd	=	SPFfallback+32		; 305 (falling forward)
SPFduck	=	SPFfallfwd+32			; 337 (ducking)
SPFHold	=	SPFduck+8				; 345 (holding)
SPFgloves	=	SPFHold+8			; 353 (gloves on the ice (fights))
SPFfight	=	SPFgloves+1			; 354 (fighting)
SPFfinjury	=	SPFfight+17			; 371 - New (fight injury)
SPFPen	=	SPFfinjury+6			; 377 (frames used by the wall jump animations)

SPFarrow	=	SPFPen+7			; 384 (arrows for off screen players)
SPFpad	=	SPFarrow+6				; 390 (face off pads)
SPFreplay	=	SPFpad+3			; 393 - New (replay marker)
SPFpuck	=	SPFreplay+1				; 394 (puck)
SPFgoal	=	SPFpuck+11				; 405 (goal)
SPFGoalie	=	SPFgoal+2			; 407 (goalie)
SPFgdive	=	SPFGoalie+112		; 519 - New (goalie dive)
SPFglovel2	=	SPFgdive+16			; 535 - New (goalie second glove save)
SPFgready	=	SPFglovel2+4		; 539 - New (goalie ready)
SPFSiren	=	SPFgready+16		; 555 (siren)

SPFcatch	=	SPFSiren+14			; 569 - New (catching a puck hit)
SPFhook	=	SPFcatch+16				; 585 - New (hooking)
SPFstumble	=	SPFhook+16			; 601 - New (stumbling)
SPFflip	=	SPFstumble+24			; 625 - New (flipping over)
SPFinjury1	=	SPFflip+8			; 633 - New (injured on the ice)
SPFbglass	=	SPFinjury1+12		; 645 - New (glass bang)

;	Each animation table is: 8 word offsets (one per facing direction 0-7, relative to .t), a flags word
;	(0 or 1), then per direction a list of frame,time word pairs; a negative time ends the list. A SPA value,
;	as kept in SPA(a3), is the offset of its table from SPAlist; SetSPA in logic93.asm switches animation.
;
;	Only the animation equate and table lines are commented. The .0-.7 direction labels and the .a/.b/.c/.aoff
;	helper symbols are assembler temporaries that step through the SPF frame numbers.

SPAlist								;base of the animation tables; a SPA value is the offset of a table from
									;here
	dc.w	0

SPAgready	=	*-SPAlist			;goalie in ready position
SPAgready_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAgready2	=	*-SPAlist			;goalie ready position, held frame (used by the goalie scripts)
SPAgready2_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAgglover	=	*-SPAlist			;goalie does glove save right
SPAgglover_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAgglovel	=	*-SPAlist			;goalie does glove save left
SPAgglovel_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAgglovel2	=	*-SPAlist			;goalie second glove save (SPFglovel2 frames, from the other glove)
SPAgglovel2_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAgstickr	=	*-SPAlist			;goalie stick save right
SPAgstickr_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAgstickl	=	*-SPAlist			;goalie stick save left
SPAgstickl_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAgstackr	=	*-SPAlist			;goalie stack (pad save) right
SPAgstackr_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

.0	dc.w	.a,8,.a+1,-32
.1	dc.w	.a+2,8,.a+3,-32
.2	dc.w	.a+2,8,.a+3,-32
.3	dc.w	.a+4,8,.a+5,-32
.4	dc.w	.a+6,8,.a+7,-32
.5	dc.w	.a+8,8,.a+9,-32
.6	dc.w	.a+8,8,.a+9,-32
.7	dc.w	.a+10,8,.a+11,-32

SPAgstackl	=	*-SPAlist			;goalie stack (pad save) left
SPAgstackl_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

.0	dc.w	.a,8,.a+1,-32
.1	dc.w	.a+2,8,.a+3,-32
.2	dc.w	.a+2,8,.a+3,-32
.3	dc.w	.a+4,8,.a+5,-32
.4	dc.w	.a+6,8,.a+7,-32
.5	dc.w	.a+8,8,.a+9,-32
.6	dc.w	.a+8,8,.a+9,-32
.7	dc.w	.a+10,8,.a+11,-32

SPAgdive	=	*-SPAlist			;goalie diving save (SPFgdive frames)
SPAgdive_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAgswing	=	*-SPAlist			;goalie passes puck
SPAgswing_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAgskate	=	*-SPAlist			;goalie skates
SPAgskate_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPApflip	=	*-SPAlist			;puck animation (flipping puck)
SPApflip_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAglide	=	*-SPAlist			;player gliding with stick down
SPAglide_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAskatewp	=	*-SPAlist			;player skating with stick down (SPFskatewp frames)
SPAskatewp_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAskate	=	*-SPAlist			;player skating with stick up (SPFskate frames)
SPAskate_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAturnl	=	*-SPAlist			;player turning left
SPAturnl_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAturnr	=	*-SPAlist			;player turning right
SPAturnr_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAstop	=	*-SPAlist				;player scrape stopping
SPAstop_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPApassf	=	*-SPAlist			;forward pass swing
SPApassf_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPApassb	=	*-SPAlist			;back hand pass swing
SPApassb_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAshotf	=	*-SPAlist			;player shoots forehand
SPAshotf_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAshotb	=	*-SPAlist			;player shoots backhand
SPAshotb_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAglideback	=	*-SPAlist		;player gliding backwards
SPAglideback_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAskateback	=	*-SPAlist		;player skating backwards
SPAskateback_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAsweepchk	=	*-SPAlist			;player stick (sweep) checking
SPAsweepchk_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAshoulderchkl	=	*-SPAlist		;player shoulder checking left
SPAshoulderchkl_table:				;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAshoulderchkr	=	*-SPAlist		;player shoulder checking right
SPAshoulderchkr_table:				;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAhipchkl	=	*-SPAlist			;player hip checking left
SPAhipchkl_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAhipchkr	=	*-SPAlist			;player hip checking right
SPAhipchkr_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAburst	=	*-SPAlist			;player doing c button (speed/no check)
SPAburst_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAHold	=	*-SPAlist				;player trying to hold
SPAHold_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFHold
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

SPAHold2	=	*-SPAlist			;player holding opponent
SPAHold2_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFHold
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

SPAflail	=	*-SPAlist			;player being held by opponent
SPAflail_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAfallfwd	=	*-SPAlist			;player falling forward
SPAfallfwd_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAfallback	=	*-SPAlist			;player falling backward
SPAfallback_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAcelebrate	=	*-SPAlist		;player raising stick/arms up
SPAcelebrate_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPApump	=	*-SPAlist				;player doing pump (arm pump) animation
SPApump_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAfight	=	*-SPAlist			;player throwing off gloves
SPAfight_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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
.7	dc.w	.a,8,.a+1,8,.a+2,8,.a+8,-6

SPAfgrab	=	*-SPAlist			;fighter grabbing
SPAfgrab_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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
.3
.4
.5
.6
.7	dc.w	.a+6,28,.a+5,-4

SPAfheld	=	*-SPAlist			;fighter holding
SPAfheld_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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
.3
.4
.5
.6
.7	dc.w	.a+6,30,.a+5,-4

SPAfhigh	=	*-SPAlist			;fighter throws high punch
SPAfhigh_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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
.3
.4
.5
.6
.7	dc.w	.a+7,6,.a+8,16,.a+7,4,.a+5,-16

SPAflow	=	*-SPAlist				;fighter throws low punch
SPAflow_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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
.3
.4
.5
.6
.7	dc.w	.a+7,6,.a+9,16,.a+7,4,.a+5,-16

SPAfhith	=	*-SPAlist			;fighter hit by high punch
SPAfhith_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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
.2	dc.w	.a+11,16,.a,-8
.3
.4
.5
.6
.7	dc.w	.a+11,16,.a+5,-8

SPAfhitl	=	*-SPAlist			;fighter hit by low punch
SPAfhitl_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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
.2	dc.w	.a+10,16,.a,-8
.3
.4
.5
.6
.7	dc.w	.a+10,16,.a+5,-8

SPAffall	=	*-SPAlist			;fighter falls down
SPAffall_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAfinjury	=	*-SPAlist			;player injured (pf2inj; 93 only)
SPAfinjury_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAwallright	=	*-SPAlist		;player jumps wall with legs to the right
SPAwallright_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFPen

.0	dc.w	.a+4,8,.a+5,8,.a+6,-8
.1
.2	dc.w	.a,8,.a+1,8,.a+2,8,.a+3,-8
.3
.4
.5
.6	dc.w	.a+3,8,.a+2,8,.a+1,8,.a,-8
.7									; (skipped)

SPAwallleft	=	*-SPAlist			;player jumps wall with legs to the left
SPAwallleft_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
	dc.w	0

.a	=	SPFPen

.0	dc.w	.a+6,8,.a+5,8,.a+4,-8
.1
.2	dc.w	.a+3,8,.a+2,8,.a+1,8,.a,-8
.3
.4
.5
.6	dc.w	.a,8,.a+1,8,.a+2,8,.a+3,-8
.7									; (skipped)

SPAfaceoff	=	*-SPAlist			;player does faceoff stick check
SPAfaceoff_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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
.b	=	SPFsweep

.0	dc.w	.a,2,.b+1,10,.b,-6
.1
.2
.3
.4
.5
.6
.7	dc.w	.a+20,2,.b+9,10,.b+8,-6

SPAfaceoffr	=	*-SPAlist			;ready position for faceoff
SPAfaceoffr_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

.0	dc.w	.a,-5
.1
.2
.3
.4
.5
.6
.7	dc.w	.a+20,-5

SPAsiren	=	*-SPAlist			;siren animation
SPAsiren_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAbglass	=	*-SPAlist			;puck hits the glass: glass bang animation (93 only; SPFbglass frames)
SPAbglass_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAstanley	=	*-SPAlist			;player skates with stanley cup over head
SPAstanley_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAcatch	=	*-SPAlist			;player hit by a slower puck (93 only; puckbody)
SPAcatch_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAhook	=	*-SPAlist				;player hooking, also a hold animation (93 only)
SPAhook_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAhook2	=	*-SPAlist			;holding animation after SPAhook (93 only)
SPAhook2_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAstumble	=	*-SPAlist			;player stumbles instead of falling (93 only)
SPAstumble_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAfake	=	*-SPAlist				;skater fake: turn left, sweep, turn right frames (93 only)
SPAfake_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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

SPAflip	=	*-SPAlist				;player flips over, third fall animation (93 only)
SPAflip_table:						;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
	dc.w	.0-.t
	dc.w	.1-.t
	dc.w	.2-.t
	dc.w	.3-.t
	dc.w	.4-.t
	dc.w	.5-.t
	dc.w	.6-.t
	dc.w	.7-.t
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

SPAinjury1	=	*-SPAlist			;player falls and lies injured (93 only)
SPAinjury1_table:					;table of the animation above: direction offsets, flags, frame/time lists
.t									;offset to each direction of animation (0-7)
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