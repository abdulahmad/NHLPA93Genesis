;	*** ANONYMIZED: the player names in this file are placeholders (P001___ ... P601). ***
;	The real names are NHLPA licensed data and are not stored in this repository. Each Player row holds a
;	placeholder of the same length as the real name (the PLAYER macro writes the length, so it must not change);
;	the ratings after it are unchanged. This file does not assemble into the real game by itself and it is
;	not included directly: it needs the original ROM.
;	  - tools/extractAssets93.js reads the player names from your ROM into Extracted/PlayerNames.txt
;	    (one name per line, in the order of the Player rows below);
;	  - tools/build.js (the 'names' step) copies this file to output/obj/teamdata93.asm with the real
;	    names put back, and hockey93.asm includes that copy.
;	Keep the placeholder lengths when editing a row's name or adding a player.
;
;	Team data. TeamList points to one record per team, the All-Star teams included. A record holds the
;	players, colors, name, lines, scouting report and scoring odds. The playoff seeds and the credits follow.
;
;	Record layout (the all-star records come first in the file, then the 24 teams): six word offsets from .0
;	(Playerdata, Palettedata, Teamname, LineSets, ScoutReport, GoalieOdds), then the palettes, scouting
;	ratings, scoring odds, line sets (7 lines of 8 bytes), players, team name and abbreviation.

null								;92 null: a zero long, used as the tile pointer when there is
									;nothing to draw (no tiles)
	dc.l	$0000

TeamList							;table of long pointers to the team records, indexed by team number
									;(HomeTeam/VisTeam); the 2 all-star teams are last
	dc.l	Boston
	dc.l	Buffalo
	dc.l	Calgary
	dc.l	Chicago
	dc.l	Detroit
	dc.l	Edmonton
	dc.l	Hartford
	dc.l	LongIsland
	dc.l	LosAngeles
	dc.l	Minnesota
	dc.l	Montreal
	dc.l	NewJersey
	dc.l	NewYork
	dc.l	Ottawa
	dc.l	Philadelphia
	dc.l	Pittsburgh
	dc.l	Quebec
	dc.l	SanJose
	dc.l	StLouis
	dc.l	TampaBay
	dc.l	Toronto
	dc.l	Vancouver
	dc.l	Washington
	dc.l	Winnipeg
	dc.l	AllStarsEast
	dc.l	AllStarsWest

NumofTeams	=	(*-TeamList)/4		;number of teams in TeamList (26)
Playerdata	=	0					;record offset of the word offset to the player data (.pld)
Palettedata	=	2					;record offset of the word offset to the palettes (.pad)
Teamname	=	4					;record offset of the word offset to the team name (.tn)
LineSets	=	6					;record offset of the word offset to the line sets (.ls)
ScoutReport	=	8					;record offset of the word offset to the scouting report ratings (.sr)
GoalieOdds	=	10					;record offset of the word offset to the starting goalie weights (.godds)

AllStarsEast						;team record: All Stars East (ASE), team 24
.0									;record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\ASEh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\ASEv.pal	; visitor colors
;------------------------
;q - scoring odds offense row (bits 4-6, SetScore)
;r - scoring odds defense row (bits 0-2)
;e - penalty kill deficit (negated while killing a penalty)
;b - power play bonus

;h - home bonus
;v - visitor bonus (negated)
;x - not read
;x - not read

;s - shooting
;k - skating
;p - passing
;d - defense

;c - checking
;f - fighting
;g - goalkeeping
;o - overall
;------------------------
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	7020,00D6,9999,9099
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	216,160
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,17,18,14,04,11,05,00	;line 1 Sc1
	dc.b	01,19,20,15,05,12,04,00	;line 2 Sc2
	dc.b	01,21,22,16,06,13,04,00	;line 3 Chk
	dc.b	01,17,18,14,04,11,05,00	;line 4 PP1
	dc.b	01,19,20,16,05,12,04,00	;line 5 PP2
	dc.b	01,21,22,16,08,15,07,00	;line 6 PK1
	dc.b	01,20,17,15,07,16,08,00	;line 7 PK2
;------------------------
;u - uniform # x10
;n - uniform # x1
;w - weight
;l - leg power
;s - speed
;o - offensive awareness
;d - defensive awareness
;p - shot power / NA for goalie

;c - checking strength / NA
;h - shooting hand / glove hand
;g - stickhandling / glove left saves
;a - shooting accuracy / glove right saves

;e - endurance / stick right saves
;y - shot/pass decision / stick left saves
;t - passing accuracy / consistency
;m - aggressiveness (PIM) / NA
;------------------------
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P001_______',			335F,AFFF,0100,FFFF
	Player	'P002________',			355D,ADDD,0100,DDDD
	Player	'P003_______',			0137,AAAA,0100,AAAA
	Player	'P004_________',		668F,CFFC,90FC,C3F9
	Player	'P005________',			118F,DFFA,F3FD,F4F9
	Player	'P006__________',		177C,9C6C,75CC,F9C9
	Player	'P007__________',		1969,9936,9199,C996
	Player	'P008_____',			165B,BE88,51B8,E5E3
	Player	'P009_______',			2056,9CCC,65CF,C698
	Player	'P010_______',			1558,8B28,32EB,B5BB
	Player	'P011________',			688F,CCC9,A3FC,C9C3
	Player	'P012____________',		896F,FE88,65EB,B8EA
	Player	'P013______',			126B,BB5B,36BE,B88C
	Player	'P014_________',		2599,CF99,97CC,C9CC
	Player	'P015__________',		185D,AD7D,73AD,D4D5
	Player	'P016_______',			098D,DDDD,D5DD,FAD8
	Player	'P017_______',			778F,CCCF,F1F6,F3F5
	Player	'P018_______',			077F,FC9C,71F3,F3FA
	Player	'P019________',			025F,AFDD,83F7,F1F3
	Player	'P020_________',		05AA,AADF,E4D7,F7D8
	Player	'P021___________',		287D,AADA,B2D4,F4A5
	Player	'P022_________',		049D,ADFA,F7AA,F4DB
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'All Stars East'
.ta									; team abbreviation string
	StringB	'ASE'

AllStarsWest						;team record: All Stars West (ASW), team 25
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\ASWh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\ASWv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	7020,00C7,9999,9099
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	173,224
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,17,16,12,04,09,05,00	;line 1 Sc1
	dc.b	01,18,19,13,05,10,04,00	;line 2 Sc2
	dc.b	01,20,21,14,06,11,04,00	;line 3 Chk
	dc.b	01,17,16,12,05,09,04,00	;line 4 PP1
	dc.b	01,19,22,13,04,11,05,00	;line 5 PP2
	dc.b	01,17,20,14,07,15,08,00	;line 6 PK1
	dc.b	01,22,18,15,08,14,07,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P023______',			305F,AFFF,0100,FFFF
	Player	'P024_______',			016D,AFFD,0100,DDFF
	Player	'P025_________',		325D,ADDD,0100,DADD
	Player	'P026_________',		993F,CF36,61FC,C3F4
	Player	'P027__________',		273F,FFDF,84FF,DADA
	Player	'P028______',			126F,CF69,90F9,C3F2
	Player	'P029_________',		185F,FFDD,50FD,FAF7
	Player	'P030__________',		916F,FDDD,A5FA,FAF7
	Player	'P031______',			167C,CF9F,90FC,CC96
	Player	'P032_________',		178D,DDAD,A4DD,DADA
	Player	'P033__________',		142E,EB8B,C4BB,B88D
	Player	'P034__________',		206C,CF6C,71FC,C6CA
	Player	'P035________',			106B,BEEB,CBBF,B88D
	Player	'P036_________',		236B,BB2B,62E8,E8B4
	Player	'P037______________',	215C,CCC9,11FC,C9C7
	Player	'P038_______',			0278,8BBF,80B5,E2BA
	Player	'P039_________',		075D,ADDD,E4F4,F4DD
	Player	'P040_______',			245B,880F,81B5,E5B3
	Player	'P041________',			064F,FF6C,61F6,C3F9
	Player	'P042________',			2588,5828,B582,E25D
	Player	'P043__________',		19A9,6396,A396,9397
	Player	'P044_______',			047B,B82E,95B5,E5B8
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'All Stars West'
.ta									; team abbreviation string
	StringB	'ASW'

Boston								;team record: Boston (BOS), team 0
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\BOSh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\BOSv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	3311,21E6,6766,6756
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	197,34
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,19,20,16,05,14,06,00	;line 1 Sc1
	dc.b	01,21,22,17,06,11,05,00	;line 2 Sc2
	dc.b	01,23,24,15,07,12,05,00	;line 3 Chk
	dc.b	01,19,20,05,06,14,16,00	;line 4 PP1
	dc.b	01,21,22,15,16,11,05,00	;line 5 PP2
	dc.b	01,19,20,11,12,15,07,00	;line 6 PK1
	dc.b	01,21,22,15,07,11,12,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P045_____',			353C,9ACC,0100,C9C9
	Player	'P046_____________',	3116,9AA6,0100,6966
	Player	'P047___________',		3333,9AA3,0000,0300
	Player	'P048__________',		0139,9AA6,0100,6666
	Player	'P049______',			126F,CF69,90F9,C3F2
	Player	'P050____________',		389C,CC6C,77CC,CC95
	Player	'P051_______',			207C,6639,CA96,C99B
	Player	'P052_____',			1079,963C,97C6,6992
	Player	'P053__________',		215C,C639,A499,6960
	Player	'P054______',			494C,9FF6,6099,6392
	Player	'P055_________',		2759,9C69,AA99,FC9B
	Player	'P056________',			1669,C9C9,6296,CC60
	Player	'P057________',			3473,3033,CC06,3C0E
	Player	'P058_____',			088C,CFFC,CA9F,CC9B
	Player	'P059________',			188C,C966,C59C,F995
	Player	'P060_________',		116F,CC6C,65CC,CCC5
	Player	'P061_____',			1786,9699,4366,9C65
	Player	'P062_________',		2576,9FC6,636F,6090
	Player	'P063_______',			778F,CCCF,F1F6,F3F5
	Player	'P064_______',			266F,C96C,ABC3,F3C5
	Player	'P065_______',			323F,F36C,A5C3,F6C8
	Player	'P066_________',		286F,C39C,CA93,F998
	Player	'P067______',			3686,33C3,6B63,966B
	Player	'P068_____',			2279,9306,7230,9305
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Boston'
.ta									; team abbreviation string
	StringB	'BOS'

Buffalo								;team record: Buffalo (BUF), team 1
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\BUFh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\BUFv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	5522,22D8,2442,3933
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	101,80
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,20,18,13,06,09,04,00	;line 1 Sc1
	dc.b	01,17,21,14,04,10,06,00	;line 2 Sc2
	dc.b	01,19,23,15,05,08,06,00	;line 3 Chk
	dc.b	01,18,17,13,06,09,04,00	;line 4 PP1
	dc.b	01,23,21,14,04,10,06,00	;line 5 PP2
	dc.b	01,17,21,06,08,14,05,00	;line 6 PK1
	dc.b	01,23,20,14,05,06,08,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P069_______',			3188,8AA8,0000,5588
	Player	'P070___________',		3058,8AA8,0100,8885
	Player	'P071______',			3552,8AA0,0100,2220
	Player	'P072__________',		105E,BE28,51E5,B5E4
	Player	'P073___________',		216B,B558,67B2,B8BA
	Player	'P074__________',		164E,BFB8,80EE,E5ED
	Player	'P075_______',			1452,2222,5328,582A
	Player	'P076______',			195B,B858,67B8,BB5A
	Player	'P077____________',		896F,FE88,65EB,B8EA
	Player	'P078__________',		2848,8B88,668B,BB5A
	Player	'P079_________',		1858,880B,6655,5B5D
	Player	'P080___________',		176B,B252,9458,5554
	Player	'P081___________',		25A5,5E5B,6488,BB87
	Player	'P082______',			1562,E825,9755,EB5A
	Player	'P083____',				2775,5225,9D58,8E2F
	Player	'P084___',				3288,B222,BD5B,2B2F
	Player	'P085_______',			0885,8885,9752,E28A
	Player	'P086________',			074B,B588,95B2,B28D
	Player	'P087_________',		3472,5022,BC25,285F
	Player	'P088_______',			0568,22B5,8552,B22A
	Player	'P089______',			4165,5585,5522,E28A
	Player	'P090________',			2488,5225,9652,555D
	Player	'P091_________',		037B,885B,8B52,E287
	Player	'P092_________',		2365,2002,5A20,2B5D
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Buffalo'
.ta									; team abbreviation string
	StringB	'BUF'

Calgary								;team record: Calgary (CGY), team 2
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\CGYh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\CGYv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	6622,11D8,4334,4823
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	196,00
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,19,17,14,03,10,06,00	;line 1 Sc1
	dc.b	01,18,21,13,06,11,03,00	;line 2 Sc2
	dc.b	01,16,20,15,04,09,03,00	;line 3 Chk
	dc.b	01,19,17,14,03,10,05,00	;line 4 PP1
	dc.b	01,18,21,06,05,11,03,00	;line 5 PP2
	dc.b	01,17,16,04,07,13,09,00	;line 6 PK1
	dc.b	01,19,20,13,09,04,07,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P093_______',			3038,8AAB,0100,BB88
	Player	'P094______',			3535,8AA5,0100,5588
	Player	'P095__________',		142E,EB8B,C4BB,B88D
	Player	'P096_____',			29AB,8855,EA88,B85D
	Player	'P097__________',		265B,BB8B,53B8,88B4
	Player	'P098__________',		256B,BB8B,85BB,B557
	Player	'P099__________',		175B,B528,84B8,8887
	Player	'P100________',			3368,8825,508B,5857
	Player	'P101________',			2265,5585,9A58,BB5F
	Player	'P102__________',		425E,BBB5,21EE,B2E7
	Player	'P103_______',			114B,B828,64B5,BBBA
	Player	'P104__________',		277B,B522,31B8,5854
	Player	'P105________',			286B,B8B8,52BB,BB84
	Player	'P106________',			106B,BEEB,CBBF,B88D
	Player	'P107________',			1685,8255,9D25,8B2D
	Player	'P108_______',			038B,B2B5,9B52,B55A
	Player	'P109_______',			0278,8BBF,80B5,E2BA
	Player	'P110________',			0788,852B,9AB2,B28D
	Player	'P111______',			206E,BB8B,B5B5,E2BD
	Player	'P112________',			5575,5252,2252,B524
	Player	'P113________',			1868,5555,8788,B287
	Player	'P114_____________',	2185,8525,9B55,222D
	Player	'P115_______',			1595,2225,8A22,282D
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Calgary'
.ta									; team abbreviation string
	StringB	'CGY'

Chicago								;team record: Chicago (CHI), team 3
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\CHIh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\CHIv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	3000,21D7,7777,9888
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	164,49
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,18,19,14,05,09,07,00	;line 1 Sc1
	dc.b	01,20,22,16,07,11,05,00	;line 2 Sc2
	dc.b	01,21,23,13,06,10,05,00	;line 3 Chk
	dc.b	01,18,19,14,05,09,10,00	;line 4 PP1
	dc.b	01,21,22,07,10,11,05,00	;line 5 PP2
	dc.b	01,21,22,07,10,06,09,00	;line 6 PK1
	dc.b	01,18,19,06,09,07,10,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P116______',			305F,AFFF,0100,FFFF
	Player	'P117_________',		313A,AAA7,0100,7AAA
	Player	'P118_____',			295A,AAA7,0100,77AA
	Player	'P119_______',			5034,AAA1,0000,1144
	Player	'P120__________',		273F,FFDF,84FF,DADA
	Player	'P121_______',			207A,A747,B77D,DDAA
	Player	'P122________',			125A,7D4A,B4DA,FAA4
	Player	'P123______',			1137,77A4,8774,7744
	Player	'P124________',			286D,ADDD,B5D7,FDD7
	Player	'P125_______',			337D,AA7A,DAA7,FDAA
	Player	'P126_____',			225D,DD47,8BDD,D77A
	Player	'P127________',			106A,AADD,A4AA,7FAA
	Player	'P128___________',		267A,D4AD,8774,AD4A
	Player	'P129_________',		166D,ADDA,85DA,D7D7
	Player	'P130_______',			23A4,4174,DD17,4D1F
	Player	'P131________',			1467,7477,BBAD,AD47
	Player	'P132____________',		3267,7AD4,A77D,7A4D
	Player	'P133_________',		075D,ADDD,E4F4,F4DD
	Player	'P134_______',			059D,D7DD,DBD4,F7DF
	Player	'P135___________',		0687,74A4,5274,A774
	Player	'P136___________',		0274,7477,BB77,F44D
	Player	'P137_______',			046D,D7D7,BAA4,FAAA
	Player	'P138______',			2584,4144,5A41,A44D
	Player	'P139_________',		037D,AA4A,81D4,74A4
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Chicago'
.ta									; team abbreviation string
	StringB	'CHI'

Detroit								;team record: Detroit (DET), team 4
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\DETh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\DETv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	6111,00D7,8879,7878
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	226,16
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,17,20,13,06,08,04,00	;line 1 Sc1
	dc.b	01,18,22,14,04,07,06,00	;line 2 Sc2
	dc.b	01,19,21,15,05,09,06,00	;line 3 Chk
	dc.b	01,17,20,06,04,08,05,00	;line 4 PP1
	dc.b	01,21,18,15,05,09,06,00	;line 5 PP2
	dc.b	01,20,18,06,07,13,04,00	;line 6 PK1
	dc.b	01,17,19,13,04,06,07,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P140_________',		325D,ADDD,0100,DADD
	Player	'P141_______',			3447,AAA4,0000,7774
	Player	'P142____________',		375A,AAA7,0100,A77A
	Player	'P143__________',		916F,FDDD,A5FA,FAF7
	Player	'P144________',			1277,DDDD,52DF,D7D4
	Player	'P145_________',		195F,FFDD,50FD,FAF7
	Player	'P146________',			236D,DAAA,B6DD,DAA7
	Player	'P147________',			2657,7DAA,B2AD,DD74
	Player	'P148_______',			249D,ADDA,FF7F,D7AF
	Player	'P149_______',			1464,747A,8477,7D77
	Player	'P150_____',			186A,A4A7,BA77,4A7D
	Player	'P151___________',		283A,A777,7477,7777
	Player	'P152_________',		216D,DDFA,87DD,DAD7
	Player	'P153______',			1157,7AD7,D77A,A77A
	Player	'P154__________',		1757,7ADA,DBAA,DAAD
	Player	'P155_________',		55AA,AADA,577F,747D
	Player	'P156____________',		054D,ADFA,A5D7,F4D4
	Player	'P157_______________',	164A,AADA,EAA7,F4AD
	Player	'P158__________',		027A,77F7,D747,D4AA
	Player	'P159__________',		038A,AAFD,BB77,F4AD
	Player	'P160_______',			335A,A77D,B5A4,D4AA
	Player	'P161______',			20A4,74D4,A547,A47A
	Player	'P162________',			0897,A4D1,231A,7F17
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Detroit'
.ta									; team abbreviation string
	StringB	'DET'

Edmonton							;team record: Edmonton (EDM), team 5
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\EDMh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\EDMv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	6512,11C7,6535,4534
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	214,34
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,22,17,10,07,08,15,00	;line 1 Sc1
	dc.b	01,19,20,11,15,06,07,00	;line 2 Sc2
	dc.b	01,18,21,16,05,09,07,00	;line 3 Chk
	dc.b	01,17,21,10,07,08,05,00	;line 4 PP1
	dc.b	01,19,20,16,05,09,07,00	;line 5 PP2
	dc.b	01,22,18,16,05,12,08,00	;line 6 PK1
	dc.b	01,19,20,12,08,16,05,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P163________',			303C,9CFC,0100,CCFC
	Player	'P164_______',			3216,9AA3,0100,3336
	Player	'P165_____',			0136,9AA3,0100,6969
	Player	'P166_______',			3343,9AA3,0100,3363
	Player	'P167___________',		146C,9696,C59C,C96A
	Player	'P168_________',		4259,9966,119C,6994
	Player	'P169___________',		0959,9C9C,32CC,C6C7
	Player	'P170______',			086C,CCCC,A19C,F6C7
	Player	'P171__________',		2783,3999,CA6C,C96D
	Player	'P172______________',	215C,CCC9,11FC,C9C7
	Player	'P173_________',		1866,6C99,649C,969A
	Player	'P174____________',		1686,6996,DD3F,963D
	Player	'P175__________',		206C,C9C9,6399,6967
	Player	'P176_______',			1260,09C9,9769,663D
	Player	'P177______',			856F,F93C,32FC,9C97
	Player	'P178________',			107F,FC3C,F5C6,FCCA
	Player	'P179_______',			2479,999F,CD96,C69D
	Player	'P180___________',		229C,C663,C793,C39A
	Player	'P181_______',			257C,C363,3393,F394
	Player	'P182_______',			0699,C66C,7363,F364
	Player	'P183________',			3659,9CF9,9166,C097
	Player	'P184______',			046C,9369,A1C3,C39D
	Player	'P185______',			2873,33C3,C533,6667
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Edmonton'
.ta									; team abbreviation string
	StringB	'EDM'

Hartford							;team record: Hartford (HFD), team 6
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\HFDh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\HFDv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	1402,00F6,2222,1342
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	146,00
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,18,22,11,03,08,04,00	;line 1 Sc1
	dc.b	01,19,21,12,04,09,03,00	;line 2 Sc2
	dc.b	01,20,23,13,05,10,03,00	;line 3 Chk
	dc.b	01,22,19,11,13,03,05,00	;line 4 PP1
	dc.b	01,20,18,12,05,09,11,00	;line 5 PP2
	dc.b	01,18,20,13,12,04,09,00	;line 6 PK1
	dc.b	01,19,23,04,09,12,13,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P186________',			3545,8AA5,0100,5858
	Player	'P187____________',		4055,8AA8,0100,5555
	Player	'P188_______',			1158,8B28,32EB,B5BB
	Player	'P189__________',		2168,8885,3188,B582
	Player	'P190___________',		085B,8888,6188,B882
	Player	'P191_______',			2355,5555,3555,5B52
	Player	'P192_______',			4478,B225,8B20,255E
	Player	'P193_______',			2488,8885,9285,8B82
	Player	'P194_______',			267B,8555,9458,EB5B
	Player	'P195_______',			2290,0220,8C0E,800B
	Player	'P196_______',			1668,5B2B,B6B8,B8BB
	Player	'P197____________',		3455,B8B5,0188,E880
	Player	'P198_________',		125B,BB8B,838B,E885
	Player	'P199________',			3382,5255,355B,5F28
	Player	'P200____________',		0755,5855,9558,5B8B
	Player	'P201__________',		2065,58B5,872B,5B25
	Player	'P202____',				1850,0220,0120,5B28
	Player	'P203_________',		0568,8585,B352,E288
	Player	'P204___________',		038E,BB5B,95B5,E588
	Player	'P205_________',		2555,5528,6355,E255
	Player	'P206___________',		29A8,2282,5552,852B
	Player	'P207_____',			0668,852B,8385,B288
	Player	'P208______',			2762,2255,0225,852B
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Hartford'
.ta									; team abbreviation string
	StringB	'HFD'

LosAngeles							;team record: Los Angeles (LA), team 8
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\LAh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\LAv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	4410,10D8,5664,6535
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	198,16
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,19,20,11,05,10,04,00	;line 1 Sc1
	dc.b	01,18,21,12,04,09,05,00	;line 2 Sc2
	dc.b	01,17,22,13,06,08,05,00	;line 3 Chk
	dc.b	01,19,20,11,05,10,04,00	;line 4 PP1
	dc.b	01,17,18,12,04,09,05,00	;line 5 PP2
	dc.b	01,17,18,12,06,13,04,00	;line 6 PK1
	dc.b	01,19,20,13,04,12,06,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P209________',			3259,9AAC,0100,6669
	Player	'P210_______',			0133,9AA3,0100,6633
	Player	'P211_________',		4380,9AA3,0000,0330
	Player	'P212________',			3779,9939,629C,FC94
	Player	'P213_________',		993F,CF36,61FC,C3F4
	Player	'P214_________',		4456,6696,9369,C36A
	Player	'P215________',			2339,CC96,629C,669A
	Player	'P216_______',			1869,66C9,9299,9667
	Player	'P217______',			176C,9C3C,6099,C994
	Player	'P218___________',		077C,CC6F,A7C9,CC9A
	Player	'P219__________',		206C,CF6C,71FC,C6CA
	Player	'P220________',			215C,FC99,949C,FC9D
	Player	'P221_________',		115C,C996,936C,CC94
	Player	'P222______',			2986,6369,CD69,396D
	Player	'P223_____________',	146C,C6C9,3193,6364
	Player	'P224__________',		0853,3669,3166,6C64
	Player	'P225_______',			2686,66C9,9766,F66A
	Player	'P226__________',		33B3,9639,CC93,F39F
	Player	'P227_______',			777F,FC9C,71F3,F3FA
	Player	'P228_____',			049C,966C,9293,F99D
	Player	'P229__________',		19A9,6396,A396,9397
	Player	'P230_________',		2289,6639,9393,9397
	Player	'P231_______',			0556,6363,7360,636D
	Player	'P232__________',		5643,3333,6530,633D
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Los Angeles'
.ta									; team abbreviation string
	StringB	'LA'

LongIsland							;team record: Long Island (LI), team 7
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\LIh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\LIv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	5522,01E7,5455,5234
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	102,00
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,20,17,13,04,12,03,00	;line 1 Sc1
	dc.b	01,18,19,14,03,11,04,00	;line 2 Sc2
	dc.b	01,21,23,15,06,10,04,00	;line 3 Chk
	dc.b	01,20,17,15,14,04,06,00	;line 4 PP1
	dc.b	01,23,18,13,06,03,14,00	;line 5 PP2
	dc.b	01,17,19,16,07,08,11,00	;line 6 PK1
	dc.b	01,20,22,08,11,16,07,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P233_______',			3546,9AA6,0100,3636
	Player	'P234___________',		3063,9AA3,0100,3366
	Player	'P235_______',			2056,9CCC,65CF,C698
	Player	'P236__________',		777C,CF9C,93CC,C6C2
	Player	'P237__________',		1189,6963,656C,6C68
	Player	'P238________',			336C,FCF9,65CC,C6C5
	Player	'P239___________',		1069,6333,9796,6C68
	Player	'P240___________',		3959,9666,756F,9F62
	Player	'P241______',			2469,9909,3299,6C68
	Player	'P242_______',			1260,9063,7C00,990E
	Player	'P243__________',		1463,0663,1066,CC35
	Player	'P244___________',		2679,6CF6,A2C9,93C5
	Player	'P245________',			325C,FC99,A599,C9C8
	Player	'P246______',			2779,6C6C,33CF,C962
	Player	'P247______',			255C,CC96,31C9,C692
	Player	'P248_____',			1769,3633,1106,9C02
	Player	'P249_______',			2869,9C3C,7396,F092
	Player	'P250_____',			04B6,69C9,A466,C395
	Player	'P251_________',		4779,9399,AB63,C33B
	Player	'P252_______',			0353,3369,4133,F032
	Player	'P253_______',			0869,9996,7363,9095
	Player	'P254________',			0663,33F6,6363,6C65
	Player	'P255__________',		0776,66F3,6163,6332
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Long Island'
.ta									; team abbreviation string
	StringB	'LI'

Minnesota							;team record: Minnesota (MIN), team 9
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\MINh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\MINv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	1301,11F6,1232,1652
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	166,00
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,18,21,14,04,10,03,00	;line 1 Sc1
	dc.b	01,20,22,16,03,11,04,00	;line 2 Sc2
	dc.b	01,19,23,15,05,09,04,00	;line 3 Chk
	dc.b	01,21,22,14,03,10,04,00	;line 4 PP1
	dc.b	01,20,18,05,04,09,03,00	;line 5 PP2
	dc.b	01,21,18,15,04,14,07,00	;line 6 PK1
	dc.b	01,20,23,14,07,15,04,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P256_____',			301B,8BA8,0100,558B
	Player	'P257_________',		3555,8AA8,0100,5585
	Player	'P258_______',			1555,5B58,8588,B85A
	Player	'P259_______',			073B,B828,8185,E8B1
	Player	'P260_______',			1888,8825,6385,B5BD
	Player	'P261_____',			1468,BB85,6388,555D
	Player	'P262_______',			1168,8255,6088,8E5A
	Player	'P263______',			2528,8808,5188,5584
	Player	'P264______',			2268,5B58,518B,BB81
	Player	'P265_______',			096E,EB58,63E8,B8B4
	Player	'P266______',			2058,8828,96B8,8B5D
	Player	'P267________',			2772,5222,8C55,2F5F
	Player	'P268_________',		1268,8282,6155,5B27
	Player	'P269_________',		236B,BB2B,62E8,E8B4
	Player	'P270___________',		1078,B585,8555,BB2A
	Player	'P271_______',			1668,5B55,6358,8857
	Player	'P272_________',		2195,2222,9125,5B2A
	Player	'P273___________',		0478,5255,8552,E287
	Player	'P274________',			03A5,5282,9352,8227
	Player	'P275_______',			0665,82B5,9782,B5BA
	Player	'P276________',			2488,5828,B582,E25D
	Player	'P277______',			2685,5225,8452,555A
	Player	'P278__________',		2888,55B5,6558,B82D
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Minnesota'
.ta									; team abbreviation string
	StringB	'MIN'

Montreal							;team record: Montreal (MTL), team 10
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\MTLh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\MTLv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	3011,22E7,7888,8499
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	210,32
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,20,18,14,05,13,04,00	;line 1 Sc1
	dc.b	01,21,23,16,04,10,05,00	;line 2 Sc2
	dc.b	01,19,22,15,06,11,05,00	;line 3 Chk
	dc.b	01,20,19,14,16,04,05,00	;line 4 PP1
	dc.b	01,21,23,17,05,09,14,00	;line 5 PP2
	dc.b	01,19,23,16,08,14,05,00	;line 6 PK1
	dc.b	01,20,18,14,05,16,08,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P279_______',			335F,AFFF,0100,FFFF
	Player	'P280___________',		0157,AAA7,0100,4477
	Player	'P281_________',		4031,AAA1,0100,1111
	Player	'P282__________',		474D,DDDA,70AD,DAA0
	Player	'P283________',			184F,DDAA,52FD,F7D5
	Player	'P284__________',		215F,DAA7,B0DD,AAD2
	Player	'P285________',			179A,D7AA,B17A,7D72
	Player	'P286___________',		397D,7477,D5A4,AFA5
	Player	'P287___________',		415D,AAFA,81DD,AAA5
	Player	'P288______',			124A,DAD7,8277,A7A5
	Player	'P289_______',			3084,4474,DC4A,AD4E
	Player	'P290_____',			36A4,41A4,DA44,4D4B
	Player	'P291__________',		065F,FDDA,70DA,A7D2
	Player	'P292_______',			118D,DDDD,D5DD,FAD8
	Player	'P293_______',			357A,D7AA,D37A,AD75
	Player	'P294_________',		277D,DDDA,D7DA,FADB
	Player	'P295__________',		456A,ADDA,71AF,7D72
	Player	'P296___________',		485D,D4DD,73A4,D772
	Player	'P297__________',		086A,77DA,B3A4,F7D5
	Player	'P298___________',		287D,AADA,B2D4,F4A5
	Player	'P299________',			248A,44D7,BB74,D47B
	Player	'P300____________',		038A,A4D4,8374,A4A8
	Player	'P301________',			1457,7774,8747,F478
	Player	'P302_____________',	434A,A7DA,A674,7475
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Montreal'
.ta									; team abbreviation string
	StringB	'MTL'

NewJersey							;team record: New Jersey (NJ), team 11
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\NJh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\NJv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	5200,11F6,8668,6467
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	165,00
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,22,23,14,03,08,04,00	;line 1 Sc1
	dc.b	01,20,21,13,04,09,03,00	;line 2 Sc2
	dc.b	01,18,19,12,05,10,03,00	;line 3 Chk
	dc.b	01,23,20,13,03,08,04,00	;line 4 PP1
	dc.b	01,21,22,14,04,09,03,00	;line 5 PP2
	dc.b	01,23,19,12,11,05,10,00	;line 6 PK1
	dc.b	01,21,22,05,10,12,11,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P303_________',		311D,AAAA,0100,AAAA
	Player	'P304____________',		013A,AAA4,0100,7777
	Player	'P305______',			144A,DDA7,B57D,D7A5
	Player	'P306_________',		267D,ADAA,A1DD,D7F5
	Player	'P307__________',		205A,AADA,A0DA,7DD0
	Player	'P308_______',			2154,47A4,AC7D,4D7B
	Player	'P309________',			157A,ADAD,A6AD,7D7B
	Player	'P310___________',		447D,DDAF,70DA,DDA2
	Player	'P311__________',		229D,DDDA,B4AD,DD78
	Player	'P312______',			245A,D7D7,B077,DD72
	Player	'P313_____',			116A,AAD4,B24A,A745
	Player	'P314_______',			0987,7AA4,50AA,DDA2
	Player	'P315___________',		198A,7AF7,52AF,D7A8
	Player	'P316____________',		255D,DDDA,71DD,DAD5
	Player	'P317________',			3267,74A4,514D,7F42
	Player	'P318_________',		0881,17D1,874D,774B
	Player	'P319_______',			336A,DA7A,41AD,7D72
	Player	'P320_______',			0387,74A4,DB74,A74B
	Player	'P321________',			235A,AAA7,A3A4,D4A5
	Player	'P322_________',		058A,DADA,A3A7,D4A5
	Player	'P323____________',		079D,AADD,B5DA,F4D5
	Player	'P324_________',		02AD,77DD,B5D4,F1D8
	Player	'P325_________',		049D,ADFA,F7AA,F4DB
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'New Jersey'
.ta									; team abbreviation string
	StringB	'NJ'

NewYork								;team record: New York (NY), team 12
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\NYh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\NYv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	7120,20F8,7989,7789
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	152,00
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,18,20,15,03,09,05,00	;line 1 Sc1
	dc.b	01,21,24,16,05,08,03,00	;line 2 Sc2
	dc.b	01,19,22,17,04,12,03,00	;line 3 Chk
	dc.b	01,18,19,03,05,09,04,00	;line 4 PP1
	dc.b	01,21,24,16,04,08,03,00	;line 5 PP2
	dc.b	01,19,21,03,07,04,11,00	;line 6 PK1
	dc.b	01,18,20,04,11,03,07,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P326___________',		344A,ADAA,0100,ADAD
	Player	'P327________',			355D,ADDD,0100,DDDD
	Player	'P328________',			118F,DFFA,F3FD,F4F9
	Player	'P329____________',		135D,ADDA,A1AF,F7A0
	Player	'P330___________',		085F,DDDA,73DD,DDA6
	Player	'P331_______',			395A,AA77,73AA,7773
	Player	'P332_______',			095D,DDD7,A3AA,ADAC
	Player	'P333_______',			335D,DDDA,72AD,DDA6
	Player	'P334________',			226F,FDDF,84FD,DDF6
	Player	'P335_______',			3764,47D4,744A,7D49
	Player	'P336________',			1664,47A4,7177,AD43
	Player	'P337______',			2667,4477,DC77,AF7C
	Player	'P338____',				2871,1471,8E17,4A1F
	Player	'P339____',				12B7,7A4A,50DA,7A73
	Player	'P340_____',			198D,D4D7,8BAA,ADAC
	Player	'P341__________',		258A,AAAA,A1AD,DDA3
	Player	'P342______',			207A,A7D7,71AD,AAA0
	Player	'P343________',			025F,AFDD,83F7,F1F3
	Player	'P344_________',		038F,DDFD,B2D7,F1D6
	Player	'P345__________',		2397,74D7,AA74,D17C
	Player	'P346_______',			068A,A4DA,8674,F47C
	Player	'P347______',			1467,74F4,8574,A479
	Player	'P348_____',			2487,74A7,A577,717C
	Player	'P349_____',			4447,A7D7,8074,D176
	Player	'P350_____________',	0597,7114,B171,7A49
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'New York'
.ta									; team abbreviation string
	StringB	'NY'

Ottawa								;team record: Ottawa (OTW), team 13
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\OTWh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\OTWv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	0702,02A6,1111,1411
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	96,00
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,12,13,10,07,02,03,00	;line 1 Sc1
	dc.b	01,14,15,08,03,06,10,00	;line 2 Sc2
	dc.b	01,16,17,09,04,05,10,00	;line 3 Chk
	dc.b	01,12,13,08,03,06,10,00	;line 4 PP1
	dc.b	01,17,14,07,10,02,03,00	;line 5 PP2
	dc.b	01,12,13,10,02,08,09,00	;line 6 PK1
	dc.b	01,17,16,08,09,10,02,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P351____________',		3055,8AA5,0100,5555
	Player	'P352_____',			075C,C996,9196,6397
	Player	'P353______',			3756,6393,736C,6963
	Player	'P354___________',		165D,77D7,A577,D77B
	Player	'P355______',			1780,0202,2100,280A
	Player	'P356_______',			2586,6093,9A33,3C3D
	Player	'P357__________',		3368,B5B5,5388,555A
	Player	'P358___________',		207D,D77D,7377,AD75
	Player	'P359_______',			4474,44A4,DD4D,4D4F
	Player	'P360_______',			145C,F6C6,9796,6C68
	Player	'P361________',			3650,0202,2100,250A
	Player	'P362_______',			0668,8528,5582,B85C
	Player	'P363_____',			326B,2588,5282,8285
	Player	'P364________',			0550,0020,2100,220A
	Player	'P365__________',		3880,0020,2000,220A
	Player	'P366_________',		3470,0020,2100,220A
	Player	'P367_______',			44A2,5255,8D22,855F
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Ottawa'
.ta									; team abbreviation string
	StringB	'OTW'

Philadelphia						;team record: Philadelphia (PHI), team 14
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\PHIh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\PHIv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	2201,22E8,3443,2353
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	147,00
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,17,18,13,03,09,04,00	;line 1 Sc1
	dc.b	01,21,23,15,04,10,03,00	;line 2 Sc2
	dc.b	01,19,20,16,05,11,03,00	;line 3 Chk
	dc.b	01,17,23,12,04,10,03,00	;line 4 PP1
	dc.b	01,21,18,13,03,09,04,00	;line 5 PP2
	dc.b	01,17,23,04,09,03,05,00	;line 6 PK1
	dc.b	01,21,20,03,05,04,09,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P368_______',			2769,9AA9,0100,CC99
	Player	'P369___________',		3353,9AA3,0100,3366
	Player	'P370__________',		177C,9C6C,75CC,F9C9
	Player	'P371______',			186C,CC66,9399,F6C9
	Player	'P372________',			094F,C999,71C6,C9C0
	Player	'P373_______',			2536,6663,A136,6C3C
	Player	'P374________',			4653,3693,6536,633C
	Player	'P375________',			1549,9639,A39F,6CC6
	Player	'P376________',			206C,FC66,7699,FC9C
	Player	'P377_______',			085F,CF36,73CC,C6C9
	Player	'P378______',			2180,0030,4C06,9F09
	Player	'P379_____',			105C,C936,4199,9693
	Player	'P380_________',		1476,6CC6,716C,C663
	Player	'P381_________',		4070,0660,0309,663C
	Player	'P382__________',		236C,9969,319C,99C3
	Player	'P383______',			476C,F666,6569,9C66
	Player	'P384__________',		286C,CC6C,63C6,F3C9
	Player	'P385________',			0366,6996,9793,C399
	Player	'P386_________',		1966,6969,A563,939C
	Player	'P387_________',		2996,6336,9B63,C36C
	Player	'P388_________',		0579,9999,7399,F666
	Player	'P389______',			0680,0390,7603,693C
	Player	'P390_____',			0259,99FC,71C9,F3C3
	Player	'P391________',			4470,0603,1133,6C36
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Philadelphia'
.ta									; team abbreviation string
	StringB	'PHI'

Pittsburgh							;team record: Pittsburgh (PIT), team 15
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\PITh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\PITv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	7621,10E7,5566,5725
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	182,00
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,18,17,13,04,09,03,00	;line 1 Sc1
	dc.b	01,19,23,14,03,10,04,00	;line 2 Sc2
	dc.b	01,20,21,15,05,08,04,00	;line 3 Chk
	dc.b	01,17,20,13,04,08,10,00	;line 4 PP1
	dc.b	01,21,18,03,10,09,04,00	;line 5 PP2
	dc.b	01,17,22,14,03,05,08,00	;line 6 PK1
	dc.b	01,18,20,05,08,14,03,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P392________',			358C,9AC9,0000,99C9
	Player	'P393_______',			3166,9AA6,0100,9696
	Player	'P394_______',			107C,9C6C,93CC,F6C3
	Player	'P395_________',		668F,CFFC,90FC,C3F9
	Player	'P396__________',		1969,9936,9199,C996
	Player	'P397_______',			386C,9696,63C3,6693
	Player	'P398_________',		186C,C393,7596,6360
	Player	'P399______',			075C,9FC9,70CC,F993
	Player	'P400________',			688F,CCC9,A3FC,C9C3
	Player	'P401________',			9286,6CCC,DA9C,C99C
	Player	'P402________',			16C3,3063,AC30,363C
	Player	'P403_______',			2079,9366,966C,6C60
	Player	'P404_________',		2599,CF99,97CC,C9CC
	Player	'P405_____',			125C,F996,A59C,CC69
	Player	'P406______',			2486,9666,CB69,993C
	Player	'P407________',			2976,C966,AB9C,3669
	Player	'P408________',			558C,9CFC,94C6,F3C6
	Player	'P409____________',		23B6,639C,C693,F669
	Player	'P410__________',		2869,66C3,9566,9069
	Player	'P411__________',		056C,C399,FB93,F39C
	Player	'P412________',			2269,933C,9463,C6C9
	Player	'P413__________',		0376,6396,A769,663C
	Player	'P414____',				0266,9393,6333,6366
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Pittsburgh'
.ta									; team abbreviation string
	StringB	'PIT'

Quebec								;team record: Quebec (QUE), team 16
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\QUEh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\QUEv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	2602,22E8,3212,1321
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	84,32
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,20,19,17,05,10,04,00	;line 1 Sc1
	dc.b	01,18,24,14,04,08,05,00	;line 2 Sc2
	dc.b	01,21,22,16,07,09,05,00	;line 3 Chk
	dc.b	01,20,19,05,10,09,04,00	;line 4 PP1
	dc.b	01,22,24,14,04,08,09,00	;line 5 PP2
	dc.b	01,20,24,16,04,14,05,00	;line 6 PK1
	dc.b	01,21,18,14,05,16,04,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P415____________',		3232,8AA2,0100,2225
	Player	'P416__________',		3142,8AA0,0100,2200
	Player	'P417_______',			3450,8AA0,0100,0000
	Player	'P418___________',		4748,8855,5388,E859
	Player	'P419_____',			195B,BE88,51B8,E5E3
	Player	'P420_______',			2860,0552,2155,5B23
	Player	'P421________',			0968,8522,3058,8856
	Player	'P422_______',			136B,BB2B,32BB,B8B9
	Player	'P423__________',		2365,5828,508E,BB53
	Player	'P424______',			116B,BB5B,36BE,B88C
	Player	'P425_______',			1485,B555,2625,582C
	Player	'P426________',			2068,B222,2155,5553
	Player	'P427__________',		4492,8555,5355,5B56
	Player	'P428______',			1868,5888,538B,E589
	Player	'P429________',			2178,8555,B355,5559
	Player	'P430______',			4148,8822,232B,B529
	Player	'P431___________',		177B,BB5E,60BB,82B3
	Player	'P432_________',		0685,5222,5722,B529
	Player	'P433__________',		0558,8558,6185,B283
	Player	'P434_____________',	0468,88BE,B5B2,E5B9
	Player	'P435_______',			2975,5228,9B52,B85C
	Player	'P436______',			5255,5252,8252,B856
	Player	'P437______',			1590,0050,3D00,280C
	Player	'P438_____________',	0788,B505,8355,E289
	Player	'P439_______',			5042,2822,015B,5256
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Quebec'
.ta									; team abbreviation string
	StringB	'QUE'

SanJose								;team record: San Jose (SJ), team 17
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\SJh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\SJv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	0702,12E6,2111,3211
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	133,34
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,24,20,16,09,11,12,00	;line 1 Sc1
	dc.b	01,23,21,17,08,12,09,00	;line 2 Sc2
	dc.b	01,19,22,15,07,13,09,00	;line 3 Chk
	dc.b	01,24,20,09,08,13,12,00	;line 4 PP1
	dc.b	01,22,23,07,12,11,09,00	;line 5 PP2
	dc.b	01,20,23,07,12,16,09,00	;line 6 PK1
	dc.b	01,24,21,16,09,07,12,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P440________',			3042,8AA2,0100,2225
	Player	'P441________',			3525,8AA2,0100,5528
	Player	'P442_______',			3245,8AA8,0100,8855
	Player	'P443_________',		0155,8AA5,0100,5558
	Player	'P444_______',			0852,2525,8458,5859
	Player	'P445_________',		166B,B505,6058,5E83
	Player	'P446_________',		4755,8525,2158,EB53
	Player	'P447________',			0965,5805,8358,B856
	Player	'P448_______',			1155,5B28,628B,E289
	Player	'P449__________',		3345,5855,8758,5523
	Player	'P450_______',			176B,BB08,50B8,B880
	Player	'P451________',			1958,5828,5388,E886
	Player	'P452_______',			1565,5828,225B,BB56
	Player	'P453__________',		186B,8525,6582,5886
	Player	'P454_______',			3672,5225,6B58,8E2C
	Player	'P455_______',			2258,5205,9358,BE53
	Player	'P456_______',			145B,B505,8185,8E53
	Player	'P457___________',		1058,8885,218B,5853
	Player	'P458_______',			0265,5225,5582,8889
	Player	'P459__________',		0568,8525,9482,E5BC
	Player	'P460__________',		0365,5825,8452,B226
	Player	'P461______',			2388,8208,BD85,288F
	Player	'P462____',				0468,550B,8485,E28C
	Player	'P463_______',			245B,880F,81B5,E5B3
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'San Jose'
.ta									; team abbreviation string
	StringB	'SJ'

StLouis								;team record: St
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\STLh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\STLv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	4210,21D8,4364,4564
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	194,32
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,22,17,14,04,10,06,00	;line 1 Sc1
	dc.b	01,18,20,15,06,08,04,00	;line 2 Sc2
	dc.b	01,19,21,13,07,09,04,00	;line 3 Chk
	dc.b	01,22,17,06,10,08,04,00	;line 4 PP1
	dc.b	01,21,20,07,04,09,08,00	;line 5 PP2
	dc.b	01,22,20,07,09,13,05,00	;line 6 PK1
	dc.b	01,21,19,13,05,07,09,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P464_________',		315C,9CCC,0100,99CC
	Player	'P465______',			4050,9AA0,0100,0000
	Player	'P466_________',		0143,9AA0,0000,3333
	Player	'P467__________',		073C,CC69,74CC,C696
	Player	'P468______',			2839,C6C6,AB96,966C
	Player	'P469________',			156C,9C99,61CC,C3C3
	Player	'P470______',			2259,99C6,C49C,F6C9
	Player	'P471____________',		1989,9C6C,9ACC,C9CC
	Player	'P472__________',		2769,6996,309C,F993
	Player	'P473______',			167C,CF9F,90FC,CC96
	Player	'P474_______',			3960,0063,1603,6F0F
	Player	'P475________',			2980,0360,7A36,360C
	Player	'P476_______',			2363,9693,6466,CC69
	Player	'P477______',			1066,6636,9366,9C39
	Player	'P478______',			1859,99C3,6169,9966
	Player	'P479_______',			2673,3033,6336,663C
	Player	'P480______',			2189,9C9F,62C6,C3C3
	Player	'P481____________',		3393,3633,9693,9399
	Player	'P482_________',		0576,9696,CA96,C09C
	Player	'P483______',			0466,6699,7466,F066
	Player	'P484________',			0689,9366,4333,F639
	Player	'P485__________',		148C,C999,95C3,F699
	Player	'P486_______',			2076,66C3,7763,636C
	Player	'P487________',			4493,6033,6160,6933
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'St. Louis'
.ta									; team abbreviation string
	StringB	'STL'

TampaBay							;team record: Tampa Bay (TBY), team 19
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\TBYh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\TBYv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	0702,02A7,2111,1411
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	48,00
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,13,12,09,02,06,03,00	;line 1 Sc1
	dc.b	01,14,15,10,03,07,02,00	;line 2 Sc2
	dc.b	01,16,17,11,04,08,02,00	;line 3 Chk
	dc.b	01,12,14,09,02,06,04,00	;line 4 PP1
	dc.b	01,15,13,11,04,07,02,00	;line 5 PP2
	dc.b	01,14,13,10,03,11,05,00	;line 6 PK1
	dc.b	01,16,18,11,05,10,03,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P488_________',		0159,9AA9,0100,9699
	Player	'P489___________',		196C,9CCC,71CC,C9C4
	Player	'P490______',			1846,9303,1269,9F05
	Player	'P491_________',		443B,8858,8488,5585
	Player	'P492__________',		4163,3960,3139,6360
	Player	'P493______',			1572,2285,BC22,2B2F
	Player	'P494________',			1161,4444,1044,7740
	Player	'P495____________',		4960,0222,2000,282A
	Player	'P496________',			2069,9363,CD33,9F3C
	Player	'P497__________',		1675,5202,2125,5B2A
	Player	'P498_______',			1785,5225,9F55,2B2F
	Player	'P499____________',		3276,63CC,C593,C669
	Player	'P500______',			299C,66C9,7596,F36B
	Player	'P501______',			0578,555B,B685,EBBD
	Player	'P502_________',		2867,77D7,7371,71A4
	Player	'P503______',			0464,411D,B274,7F4A
	Player	'P504__________',		3870,0020,2000,222A
	Player	'P505__________',		2570,0000,2100,220A
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Tampa Bay'
.ta									; team abbreviation string
	StringB	'TBY'

Toronto								;team record: Toronto (TOR), team 20
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\TORh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\TORv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	1411,12E8,2123,3232
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	211,00
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,17,19,13,03,06,05,00	;line 1 Sc1
	dc.b	01,20,21,10,05,08,03,00	;line 2 Sc2
	dc.b	01,18,22,14,04,07,03,00	;line 3 Chk
	dc.b	01,17,19,13,10,03,07,00	;line 4 PP1
	dc.b	01,18,22,05,07,06,13,00	;line 5 PP2
	dc.b	01,19,21,12,04,10,03,00	;line 6 PK1
	dc.b	01,18,17,10,03,12,04,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P506______',			315E,8EEE,0000,BBEE
	Player	'P507________',			3055,8AA5,0100,5555
	Player	'P508________',			933E,8BB8,B1BB,E2B8
	Player	'P509_________',		0768,5552,6388,B882
	Player	'P510_______',			2578,8B28,9188,B5B2
	Player	'P511__________',		106B,EB28,57B8,B8B8
	Player	'P512________',			2268,8828,2385,BB85
	Player	'P513_______',			1255,5822,305B,8B58
	Player	'P514________',			7165,5855,E48B,5858
	Player	'P515___________',		2678,8555,8385,EB58
	Player	'P516__________',		0870,0020,9D00,2E0E
	Player	'P517________',			2185,5525,5558,8828
	Player	'P518________',			1768,8B2E,B7B8,BBBB
	Player	'P519______',			1142,5525,532B,8B25
	Player	'P520_____',			2455,88E5,225B,5B52
	Player	'P521___________',		1875,8585,5350,5520
	Player	'P522_______',			047B,B82E,95B5,E5B8
	Player	'P523_____',			0388,8525,9452,E258
	Player	'P524________',			3478,85BB,B582,E2B5
	Player	'P525_____',			2358,8225,B552,8258
	Player	'P526________',			0282,5582,5452,B228
	Player	'P527__________',		2868,5225,8182,B552
	Player	'P528________',			3372,2222,2725,582B
	Player	'P529___________',		1568,5208,218B,55B0
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Toronto'
.ta									; team abbreviation string
	StringB	'TOR'

Vancouver							;team record: Vancouver (VAN), team 21
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\VANh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\VANv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	4111,10E8,6877,7577
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	211,00
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,18,19,13,03,09,05,00	;line 1 Sc1
	dc.b	01,17,21,12,05,11,03,00	;line 2 Sc2
	dc.b	01,20,22,16,04,10,03,00	;line 3 Chk
	dc.b	01,18,19,13,04,09,05,00	;line 4 PP1
	dc.b	01,22,17,12,05,11,04,00	;line 5 PP2
	dc.b	01,19,22,06,07,12,05,00	;line 6 PK1
	dc.b	01,17,18,12,05,06,07,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P530_______',			016D,AFFD,0100,DDFF
	Player	'P531_______',			3567,AAA7,0100,77AA
	Player	'P532_________',		074F,FDD7,81DA,AAD4
	Player	'P533_______',			1947,7A77,41AD,DAA4
	Player	'P534_________',		183F,ADA7,71DF,F4F7
	Player	'P535_______',			0977,74A7,83A7,AD77
	Player	'P536______',			1584,4D44,717D,A774
	Player	'P537_______',			5844,7447,21A4,7F71
	Player	'P538_________',		168D,DDAD,A4DD,DADA
	Player	'P539_______',			2594,7ADA,7A7A,AA7D
	Player	'P540______',			104F,FDAA,71FA,DDD4
	Player	'P541______',			086A,ADAA,B1AD,FDA4
	Player	'P542___________',		146F,FD7A,45D7,DDDD
	Player	'P543_______',			29A4,44A4,AF44,4D4F
	Player	'P544______',			2364,47A4,4377,7A77
	Player	'P545__________',		279D,ADDA,D77A,AD7D
	Player	'P546_________',		048A,A77D,DAA4,F4AD
	Player	'P547_______',			4497,77AA,85A4,F7A7
	Player	'P548_______',			216D,AAD7,83DA,F1D7
	Player	'P549_______',			2297,74A7,A7A4,A77D
	Player	'P550_______',			0577,A4DD,B774,A77D
	Player	'P551________',			037A,AADA,B2D7,F4D4
	Player	'P552_______',			2494,4444,5144,744A
	Player	'P553__________',		0667,7AD7,A374,7177
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Vancouver'
.ta									; team abbreviation string
	StringB	'VAN'

Winnipeg							;team record: Winnipeg (WPG), team 23
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\WPGh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\WPGv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	2020,10E7,4555,2185
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	149,48
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,20,21,17,07,10,04,00	;line 1 Sc1
	dc.b	01,18,24,14,04,11,07,00	;line 2 Sc2
	dc.b	01,22,23,15,05,09,07,00	;line 3 Chk
	dc.b	01,20,21,07,10,11,04,00	;line 4 PP1
	dc.b	01,22,18,14,04,12,11,00	;line 5 PP2
	dc.b	01,20,23,15,04,14,05,00	;line 6 PK1
	dc.b	01,22,18,14,05,15,04,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P554_______',			352F,9CCF,0100,CCCC
	Player	'P555____________',		3056,9AA6,0000,3666
	Player	'P556__________',		3156,9AA3,0100,3366
	Player	'P557_______',			196C,9936,C099,F9C6
	Player	'P558_______',			3659,9636,D599,C96C
	Player	'P559______',			1446,9666,0069,6C33
	Player	'P560________',			256F,9CCC,A3FC,C3F6
	Player	'P561________',			1156,6693,413C,6933
	Player	'P562__________',		2376,6666,4066,9C66
	Player	'P563_____',			167C,9CCC,63C9,CCC9
	Player	'P564_______',			1559,9C6C,429C,C969
	Player	'P565___________',		3839,9966,609C,9696
	Player	'P566_______',			2469,C333,4099,6F36
	Player	'P567__________',		3476,6999,919C,F693
	Player	'P568______',			1743,0333,7339,9F39
	Player	'P569______',			3953,3990,633C,693C
	Player	'P570__________',		405C,C9FC,42C9,9CC6
	Player	'P571__________',		276C,99C9,70C3,F393
	Player	'P572______',			2279,63C6,7566,6669
	Player	'P573____________',		047C,9C0C,10C6,F3C3
	Player	'P574________',			064F,FF6C,61F6,C3F9
	Player	'P575_________',		0876,6396,A360,F966
	Player	'P576________',			4480,0030,7D00,C60F
	Player	'P577________',			3363,3333,6463,9969
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Winnipeg'
.ta									; team abbreviation string
	StringB	'WPG'

Washington							;team record: Washington (WSH), team 22
.0									; record base: six word offsets (Playerdata ... GoalieOdds) from here
	dc.w	.pld-.0					; Playerdata
	dc.w	.pad-.0					; Palettedata
	dc.w	.tn-.0					; Teamname
	dc.w	.ls-.0					; LineSets
	dc.w	.sr-.0					; ScoutReport
	dc.w	.godds-.0				; GoalieOdds
.pad								; team palettes (home and visitor)
	incbin	..\Extracted\Graphics\Pals\WSHh.pal	; home colors
	incbin	..\Extracted\Graphics\Pals\WSHv.pal	; visitor colors
.sr									; scouting report ratings
;			qreb,hvxx,skpd,cfgo
	hex2	7320,00E7,9697,8458
.godds								; starting goalie weights, 4 nibbles (PickStartingGoalie)
	dc.b	164,32
.ls									; line sets: 7 lines of 8 roster numbers, by position
;			-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,19,20,12,05,08,04,00	;line 1 Sc1
	dc.b	01,18,24,15,04,11,05,00	;line 2 Sc2
	dc.b	01,21,22,14,06,10,05,00	;line 3 Chk
	dc.b	01,19,18,15,07,04,05,00	;line 4 PP1
	dc.b	01,21,20,06,05,08,04,00	;line 5 PP2
	dc.b	01,21,24,12,05,06,07,00	;line 6 PK1
	dc.b	01,18,19,06,07,12,05,00	;line 7 PK2
.pld								;player data: one player per row, ended by an empty String
;									unwl,sodp,chga,eytm
	Player	'P578_______',			3337,AAAA,0100,AAAA
	Player	'P579_____',			0167,AAA7,0100,A77A
	Player	'P580_______',			3954,AAA4,0100,1144
	Player	'P581_____________',	085A,ADDD,A0DD,DAD2
	Player	'P582_______',			177D,DDAD,81DF,F4D2
	Player	'P583__________',		207A,ADDA,A3DA,F7A2
	Player	'P584_______',			3277,7DAA,DB7F,D4DB
	Player	'P585___________',		224F,DD7F,82FA,DDD8
	Player	'P586__________',		2387,7777,D67A,7A7B
	Player	'P587________',			125D,DDDA,71DD,AAA2
	Player	'P588______',			1977,7ADA,A07D,ADA2
	Player	'P589________',			107D,DADA,71D7,D7D5
	Player	'P590____',				1674,747A,BA4D,4A4B
	Player	'P591________',			2157,AAA7,8577,AD4B
	Player	'P592__________',		185D,AD7D,73AD,D4D5
	Player	'P593________',			0967,4474,BB7D,4A4B
	Player	'P594________',			1457,A7A4,4177,7442
	Player	'P595___________',		068D,ADAD,A3DA,F1D2
	Player	'P596_________',		04AA,AADF,E4D7,F7D8
	Player	'P597________',			035A,AAAA,B0A7,D4A2
	Player	'P598______',			34AD,AAAD,DBDA,F4AB
	Player	'P599_______',			059A,74D4,A1A1,A172
	Player	'P600________',			0284,4141,1111,771B
	Player	'P601_________',		285A,7147,7071,D770
	dc.b	0,2						;end of player data: empty String
.tn									; team name string (Teamname)
	StringB	'Washington'
.ta									; team abbreviation string
	StringB	'WSH'


playoffseats						;34 playoff trees x 16 bytes: team numbers in first round tree order
									;(adjacent pairs meet); used by NewPO and MakeTree
	dc.b	15,22,11,12, 1,0,6,10, 5,8,23,21, 9,4,18,3
	dc.b	11,22,15,12, 6,0,1,10, 23,8,5,21, 18,4,9,3
	dc.b	15,22,7,12, 6,0,16,10, 5,8,2,21, 9,4,20,3
	dc.b	7,22,15,12, 16,0,1,10, 2,8,5,21, 20,4,9,3
	dc.b	11,22,7,12, 1,0,16,10, 23,8,2,21, 18,4,20,3
	dc.b	7,22,11,12, 16,0,6,10, 2,8,23,21, 20,4,18,3
	dc.b	11,22,14,12, 1,0,6,10, 5,8,17,21, 9,4,18,3
	dc.b	14,22,15,12, 6,0,1,10, 17,8,5,21, 18,4,9,3

	dc.b	15,22,14,12, 6,0,16,10, 23,8,17,21, 9,4,20,3
	dc.b	14,22,11,12, 16,0,1,10, 17,8,23,21, 20,4,9,3
	dc.b	7,22,14,12, 1,0,16,10, 17,8,2,21, 18,4,20,3
	dc.b	14,22,7,12, 16,0,6,10, 2,8,17,21, 20,4,18,3
	dc.b	15,22,11,12, 1,0,6,10, 5,8,23,21, 9,4,18,3
	dc.b	11,22,15,12, 6,0,1,10, 23,8,5,21, 18,4,9,3
	dc.b	15,22,11,12, 1,0,13,10, 5,8,23,21, 9,4,19,3
	dc.b	15,22,11,12, 13,0,6,10, 5,8,23,21, 19,4,18,3

	dc.b	3,18,4,9, 21,23,8,5, 10,6,0,1, 12,11,22,15
	dc.b	3,9,4,18, 21,5,8,23, 10,1,0,6, 12,15,22,11
	dc.b	3,20,4,9, 21,2,8,5, 10,16,0,6, 12,7,22,15
	dc.b	3,9,4,20, 21,5,8,2, 10,1,0,16, 12,15,22,7
	dc.b	3,20,4,18, 21,2,8,23, 10,16,0,1, 12,7,22,11
	dc.b	3,18,4,20, 21,23,8,2, 10,6,0,16, 12,11,22,7
	dc.b	3,18,4,9, 21,17,8,5, 10,6,0,1, 12,14,22,11
	dc.b	3,9,4,18, 21,5,8,17, 10,1,0,6, 12,15,22,14

	dc.b	3,20,4,9, 21,17,8,23, 10,16,0,6, 12,14,22,15
	dc.b	3,9,4,20, 21,23,8,17, 10,1,0,16, 12,11,22,14
	dc.b	3,20,4,18, 21,2,8,17, 10,16,0,1, 12,14,22,7
	dc.b	3,18,4,20, 21,17,8,2, 10,6,0,16, 12,7,22,14
	dc.b	3,18,4,9, 21,23,8,5, 10,6,0,1, 12,11,22,15
	dc.b	3,9,4,18, 21,5,8,23, 10,1,0,6, 12,15,22,11
	dc.b	3,18,4,9, 21,23,8,5, 10,6,0,1, 12,11,22,15
	dc.b	3,9,4,18, 21,5,8,23, 10,1,0,6, 12,15,22,11

	dc.b	3,19,4,9, 21,23,8,5, 10,13,0,1, 12,11,22,15
	dc.b	3,18,4,19, 21,23,8,5, 10,6,0,13, 12,11,22,15


Credits								;copyright and credits text: groups of String lines, each group ended by
									;String -1 (printed from hockey93.asm)
	String	'$ 1992 Electronic Arts'
	String	'Licensed by'
	String	'Sega Enterprises Ltd.'
	String	CC_PageEnd
CreditsPages						;the credits pages after the copyright group (printed by the title
									;screen), the first one blank
	String	''						;empty string: a blank first credits page (as at the end of this file)
	String	CC_PageEnd

	String	'Design adapted by'
	String	'Michael Brook'
	String	'Scott Orr'
	String	'Richard Hilleman'
	String	CC_PageEnd

	String	'Programmed by'
	String	'Jim Simmons'
	String	CC_PageEnd

	String	'Graphics by'
	String	'George Simmons'
	String	'Brian O''Hara'
	String	'Curt Toumanian'
	String	CC_PageEnd

	String	'Music and Sound by'
	String	'Jim Simmons'
	String	CC_PageEnd

	String	'Produced by'
	String	'Michael Brook'
	String	CC_PageEnd

	String	'Assistant Producer'
	String	'Steve Matulac'
	String	CC_PageEnd

	String	'Technical Directors'
	String	'Scott Cronce'
	String	'Tom DeBry'
	String	CC_PageEnd

	String	'Testing by'
	String	'Robert Zalot'
	String	'Yun Shin'
	String	'Joel Simmons'
	String	CC_PageEnd

	String	'Player Ratings by'
	String	'Igor Kuperman'
	String	CC_PageEnd

	String	'Special Thanks to'
	String	'Bob Borgen'
	String	'Ted Saskin'
	String	'Ian Pulver'
	String	'Rob Blake'
	String	'John McIntyre'
	String	CC_PageEnd

	
	String	''
	String	CC_PageEnd
	String	CC_PageEnd