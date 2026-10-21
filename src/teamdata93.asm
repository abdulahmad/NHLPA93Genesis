;	Team data. TeamList points to one record per team, the All-Star teams included. A record holds the
;	players, colors, name, lines, scouting report and scoring odds. The playoff seeds and the credits follow.
;
;	Record layout (the all-star records come first in the file, then the 24 teams): six word offsets from .0
;	(Playerdata, Palettedata, Teamname, LineSets, ScoutReport, GoalieOdds), then the palettes, scouting
;	ratings, scoring odds, line sets (7 lines of 8 bytes), players, team name and abbreviation.

null								;92 null: a zero long at $310, used as the tile pointer when there is
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
	dc.b	01,17,18,14,04,11,05,00	;line 1
	dc.b	01,19,20,15,05,12,04,00	;line 2
	dc.b	01,21,22,16,06,13,04,00	;line 3
	dc.b	01,17,18,14,04,11,05,00	;line 4, power play 1
	dc.b	01,19,20,16,05,12,04,00	;line 5, power play 2
	dc.b	01,21,22,16,08,15,07,00	;line 6, penalty kill 1
	dc.b	01,20,17,15,07,16,08,00	;line 7, penalty kill 2
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
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Patrick Roy',			335F,AFFF,0100,FFFF
	Player	'Mike Richter',			355D,ADDD,0100,DDDD
	Player	'Don Beaupre',			0137,AAAA,0100,AAAA
	Player	'Mario Lemieux',		668F,CFFC,90FC,C3F9
	Player	'Mark Messier',			118F,DFFA,F3FD,F4F9
	Player	'Rod Brindamour',		177C,9C6C,75CC,F9C9
	Player	'Bryan Trottier',		1969,9936,9199,C996
	Player	'Joe Sakic',			165B,BE88,51B8,E5E3
	Player	'Ray Ferraro',			2056,9CCC,65CF,C698
	Player	'John Cullen',			1558,8B28,32EB,B5BB
	Player	'Jaromir Jagr',			688F,CCC9,A3FC,C9C3
	Player	'Alexnder Mogilny',		896F,FE88,65EB,B8EA
	Player	'Owen Nolan',			126B,BB5B,36BE,B88C
	Player	'Kevin Stevens',		2599,CF99,97CC,C9CC
	Player	'Randy Burridge',		185D,AD7D,73AD,D4D5
	Player	'Kirk Muller',			098D,DDDD,D5DD,FAD8
	Player	'Ray Bourque',			778F,CCCF,F1F6,F3F5
	Player	'Paul Coffey',			077F,FC9C,71F3,F3FA
	Player	'Brian Leetch',			025F,AFDD,83F7,F1F3
	Player	'Kevin Hatcher',		05AA,AADF,E4D7,F7D8
	Player	'Eric Desjardins',		287D,AADA,B2D4,F4A5
	Player	'Scott Stevens',		049D,ADFA,F7AA,F4DB
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,17,16,12,04,09,05,00
	dc.b	01,18,19,13,05,10,04,00
	dc.b	01,20,21,14,06,11,04,00
	dc.b	01,17,16,12,05,09,04,00
	dc.b	01,19,22,13,04,11,05,00
	dc.b	01,17,20,14,07,15,08,00
	dc.b	01,22,18,15,08,14,07,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Ed Belfour',			305F,AFFF,0100,FFFF
	Player	'Kirk McLean',			016D,AFFD,0100,DDFF
	Player	'Tim Cheveldae',		325D,ADDD,0100,DADD
	Player	'Wayne Gretzky',		993F,CF36,61FC,C3F4
	Player	'Jeremy Roenick',		273F,FFDF,84FF,DADA
	Player	'Adam Oates',			126F,CF69,90F9,C3F2
	Player	'Steve Yzerman',		185F,FFDD,50FD,FAF7
	Player	'Sergei Fedorov',		916F,FDDD,A5FA,FAF7
	Player	'Brett Hull',			167C,CF9F,90FC,CC96
	Player	'Trevor Linden',		178D,DDAD,A4DD,DADA
	Player	'Theoren Fleury',		142E,EB8B,C4BB,B88D
	Player	'Luc Robitaille',		206C,CF6C,71FC,C6CA
	Player	'Gary Roberts',			106B,BEEB,CBBF,B88D
	Player	'Brian Bellows',		236B,BB2B,62E8,E8B4
	Player	'Vincent Damphousse',	215C,CCC9,11FC,C9C7
	Player	'Al MacInnis',			0278,8BBF,80B5,E2BA
	Player	'Chris Chelios',		075D,ADDD,E4F4,F4DD
	Player	'Doug Wilson',			245B,880F,81B5,E5B3
	Player	'Phil Housley',			064F,FF6C,61F6,C3F9
	Player	'Mark Tinordi',			2588,5828,B582,E25D
	Player	'Larry Robinson',		19A9,6396,A396,9397
	Player	'Dave Ellett',			047B,B82E,95B5,E5B8
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,19,20,16,05,14,06,00
	dc.b	01,21,22,17,06,11,05,00
	dc.b	01,23,24,15,07,12,05,00
	dc.b	01,19,20,05,06,14,16,00
	dc.b	01,21,22,15,16,11,05,00
	dc.b	01,19,20,11,12,15,07,00
	dc.b	01,21,22,15,07,11,12,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Andy Moog',			353C,9ACC,0100,C9C9
	Player	'Daniel Berthiaume',	3116,9AA6,0100,6966
	Player	'Matt Delguidice',		3333,9AA3,0000,0300
	Player	'Rejean Lemelin',		0139,9AA6,0100,6666
	Player	'Adam Oates',			126F,CF69,90F9,C3F2
	Player	'Vladimir Ruzicka',		389C,CC6C,77CC,CC95
	Player	'Bob Sweeney',			207C,6639,CA96,C99B
	Player	'Ken Hodge',			1079,963C,97C6,6992
	Player	'Barry Pederson',		215C,C639,A499,6960
	Player	'Joe Juneau',			494C,9FF6,6099,6392
	Player	'Stephen Leach',		2759,9C69,AA99,FC9B
	Player	'Peter Douris',			1669,C9C9,6296,CC60
	Player	'Lyndon Byers',			3473,3033,CC06,3C0E
	Player	'Cam Neely',			088C,CFFC,CA9F,CC9B
	Player	'Brent Ashton',			188C,C966,C59C,F995
	Player	'Bob Carpenter',		116F,CC6C,65CC,CCC5
	Player	'Dave Reid',			1786,9699,4366,9C65
	Player	'Andy Brickley',		2576,9FC6,636F,6090
	Player	'Ray Bourque',			778F,CCCF,F1F6,F3F5
	Player	'Glen Wesley',			266F,C96C,ABC3,F3C5
	Player	'Don Sweeney',			323F,F36C,A5C3,F6C8
	Player	'Gordon Murphy',		286F,C39C,CA93,F998
	Player	'Jim Wiemer',			3686,33C3,6B63,966B
	Player	'Bob Beers',			2279,9306,7230,9305
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,20,18,13,06,09,04,00
	dc.b	01,17,21,14,04,10,06,00
	dc.b	01,19,23,15,05,08,06,00
	dc.b	01,18,17,13,06,09,04,00
	dc.b	01,23,21,14,04,10,06,00
	dc.b	01,17,21,06,08,14,05,00
	dc.b	01,23,20,14,05,06,08,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Daren Puppa',			3188,8AA8,0000,5588
	Player	'Clint Malarchuk',		3058,8AA8,0100,8885
	Player	'Tom Draper',			3552,8AA0,0100,2220
	Player	'Dale Hawerchuk',		105E,BE28,51E5,B5E4
	Player	'Christan Ruuttu',		216B,B558,67B2,B8BA
	Player	'Pat LaFontaine',		164E,BFB8,80EE,E5ED
	Player	'Dave Hannan',			1452,2222,5328,582A
	Player	'Tony Tanti',			195B,B858,67B8,BB5A
	Player	'Alexnder Mogilny',		896F,FE88,65EB,B8EA
	Player	'Donald Audette',		2848,8B88,668B,BB5A
	Player	'Wayne Presley',		1858,880B,6655,5B5D
	Player	'Colin Patterson',		176B,B252,9458,5554
	Player	'Dave Andreychuk',		25A5,5E5B,6488,BB87
	Player	'Randy Wood',			1562,E825,9755,EB5A
	Player	'Brad May',				2775,5225,9D58,8E2F
	Player	'Rob Ray',				3288,B222,BD5B,2B2F
	Player	'Doug Bodger',			0885,8885,9752,E28A
	Player	'Petr Svoboda',			074B,B588,95B2,B28D
	Player	'Gord Donnelly',		3472,5022,BC25,285F
	Player	'Mike Ramsey',			0568,22B5,8552,B22A
	Player	'Ken Sutton',			4165,5585,5522,E28A
	Player	'Randy Moller',			2488,5225,9652,555D
	Player	'Grant Ledyard',		037B,885B,8B52,E287
	Player	'Randy Hillier',		2365,2002,5A20,2B5D
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,19,17,14,03,10,06,00
	dc.b	01,18,21,13,06,11,03,00
	dc.b	01,16,20,15,04,09,03,00
	dc.b	01,19,17,14,03,10,05,00
	dc.b	01,18,21,06,05,11,03,00
	dc.b	01,17,16,04,07,13,09,00
	dc.b	01,19,20,13,09,04,07,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Mike Vernon',			3038,8AAB,0100,BB88
	Player	'Jeff Reese',			3535,8AA5,0100,5588
	Player	'Theoren Fleury',		142E,EB8B,C4BB,B88D
	Player	'Joel Otto',			29AB,8855,EA88,B85D
	Player	'Robert Reichel',		265B,BB8B,53B8,88B4
	Player	'Joe Nieuwendyk',		256B,BB8B,85BB,B557
	Player	'Marc Habscheid',		175B,B528,84B8,8887
	Player	'Carey Wilson',			3368,8825,508B,5857
	Player	'Ronnie Stern',			2265,5585,9A58,BB5F
	Player	'Sergei Makarov',		425E,BBB5,21EE,B2E7
	Player	'Gary Leeman',			114B,B828,64B5,BBBA
	Player	'Tomas Forslund',		277B,B522,31B8,5854
	Player	'Paul Ranheim',			286B,B8B8,52BB,BB84
	Player	'Gary Roberts',			106B,BEEB,CBBF,B88D
	Player	'Craig Berube',			1685,8255,9D25,8B2D
	Player	'Frank Musil',			038B,B2B5,9B52,B55A
	Player	'Al MacInnis',			0278,8BBF,80B5,E2BA
	Player	'Michel Petit',			0788,852B,9AB2,B28D
	Player	'Gary Suter',			206E,BB8B,B5B5,E2BD
	Player	'Mark Osiecki',			5575,5252,2252,B524
	Player	'Trent Yawney',			1868,5555,8788,B287
	Player	'Alexnder Godynyuk',	2185,8525,9B55,222D
	Player	'Neil Sheehy',			1595,2225,8A22,282D
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,18,19,14,05,09,07,00
	dc.b	01,20,22,16,07,11,05,00
	dc.b	01,21,23,13,06,10,05,00
	dc.b	01,18,19,14,05,09,10,00
	dc.b	01,21,22,07,10,11,05,00
	dc.b	01,21,22,07,10,06,09,00
	dc.b	01,18,19,06,09,07,10,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Ed Belfour',			305F,AFFF,0100,FFFF
	Player	'Dominik Hasek',		313A,AAA7,0100,7AAA
	Player	'Jim Waite',			295A,AAA7,0100,77AA
	Player	'Ray LeBlanc',			5034,AAA1,0000,1144
	Player	'Jeremy Roenick',		273F,FFDF,84FF,DADA
	Player	'Mike Hudson',			207A,A747,B77D,DDAA
	Player	'Brent Sutter',			125A,7D4A,B4DA,FAA4
	Player	'Tony Hrkac',			1137,77A4,8774,7744
	Player	'Steve Larmer',			286D,ADDD,B5D7,FDD7
	Player	'Dirk Graham',			337D,AA7A,DAA7,FDAA
	Player	'Rob Brown',			225D,DD47,8BDD,D77A
	Player	'Brian Noonan',			106A,AADD,A4AA,7FAA
	Player	'Jocelyn Lemieux',		267A,D4AD,8774,AD4A
	Player	'Michel Goulet',		166D,ADDA,85DA,D7D7
	Player	'Stu Grimson',			23A4,4174,DD17,4D1F
	Player	'Greg Gilbert',			1467,7477,BBAD,AD47
	Player	'Stephane Matteau',		3267,7AD4,A77D,7A4D
	Player	'Chris Chelios',		075D,ADDD,E4F4,F4DD
	Player	'Steve Smith',			059D,D7DD,DBD4,F7DF
	Player	'Frantsek Kucera',		0687,74A4,5274,A774
	Player	'Bryan Marchment',		0274,7477,BB77,F44D
	Player	'Keith Brown',			046D,D7D7,BAA4,FAAA
	Player	'Rod Buskas',			2584,4144,5A41,A44D
	Player	'Igor Kravchuk',		037D,AA4A,81D4,74A4
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,17,20,13,06,08,04,00
	dc.b	01,18,22,14,04,07,06,00
	dc.b	01,19,21,15,05,09,06,00
	dc.b	01,17,20,06,04,08,05,00
	dc.b	01,21,18,15,05,09,06,00
	dc.b	01,20,18,06,07,13,04,00
	dc.b	01,17,19,13,04,06,07,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Tim Cheveldae',		325D,ADDD,0100,DADD
	Player	'Greg Millen',			3447,AAA4,0000,7774
	Player	'Vincent Riendeau',		375A,AAA7,0100,A77A
	Player	'Sergei Fedorov',		916F,FDDD,A5FA,FAF7
	Player	'Jimmy Carson',			1277,DDDD,52DF,D7D4
	Player	'Steve Yzerman',		195F,FFDD,50FD,FAF7
	Player	'Kevin Miller',			236D,DAAA,B6DD,DAA7
	Player	'Ray Sheppard',			2657,7DAA,B2AD,DD74
	Player	'Bob Probert',			249D,ADDA,FF7F,D7AF
	Player	'Brent Fedyk',			1464,747A,8477,7D77
	Player	'Alan Kerr',			186A,A4A7,BA77,4A7D
	Player	'Sheldon Kennedy',		283A,A777,7477,7777
	Player	'Paul Ysebaert',		216D,DDFA,87DD,DAD7
	Player	'Shawn Burr',			1157,7AD7,D77A,A77A
	Player	'Gerard Gallant',		1757,7ADA,DBAA,DAAD
	Player	'Keith Primeau',		55AA,AADA,577F,747D
	Player	'Nicklas Lidstrom',		054D,ADFA,A5D7,F4D4
	Player	'Vladimir Konstantov',	164A,AADA,EAA7,F4AD
	Player	'Brad McCrimmon',		027A,77F7,D747,D4AA
	Player	'Steve Chiasson',		038A,AAFD,BB77,F4AD
	Player	'Yves Racine',			335A,A77D,B5A4,D4AA
	Player	'Brad Marsh',			20A4,74D4,A547,A47A
	Player	'Bobby Dollas',			0897,A4D1,231A,7F17
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,22,17,10,07,08,15,00
	dc.b	01,19,20,11,15,06,07,00
	dc.b	01,18,21,16,05,09,07,00
	dc.b	01,17,21,10,07,08,05,00
	dc.b	01,19,20,16,05,09,07,00
	dc.b	01,22,18,16,05,12,08,00
	dc.b	01,19,20,12,08,16,05,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Bill Ranford',			303C,9CFC,0100,CCFC
	Player	'Ron Tugnutt',			3216,9AA3,0100,3336
	Player	'Peter Ing',			0136,9AA3,0100,6969
	Player	'Norm Foster',			3343,9AA3,0100,3363
	Player	'Craig MacTavish',		146C,9696,C59C,C96A
	Player	'Josef Beranek',		4259,9966,119C,6994
	Player	'Bernie Nicholls',		0959,9C9C,32CC,C6C7
	Player	'Joe Murphy',			086C,CCCC,A19C,F6C7
	Player	'Scott Mellanby',		2783,3999,CA6C,C96D
	Player	'Vincent Damphousse',	215C,CCC9,11FC,C9C7
	Player	'Craig Simpson',		1866,6C99,649C,969A
	Player	'Kelly Buchberger',		1686,6996,DD3F,963D
	Player	'Martin Gelinas',		206C,C9C9,6399,6967
	Player	'David Maley',			1260,09C9,9769,663D
	Player	'Petr Klima',			856F,F93C,32FC,9C97
	Player	'Esa Tikkanen',			107F,FC3C,F5C6,FCCA
	Player	'Dave Manson',			2479,999F,CD96,C69D
	Player	'Luke Richardson',		229C,C663,C793,C39A
	Player	'Geoff Smith',			257C,C363,3393,F394
	Player	'Brian Glynn',			0699,C66C,7363,F364
	Player	'Norm MacIver',			3659,9CF9,9166,C097
	Player	'Kevin Lowe',			046C,9369,A1C3,C39D
	Player	'Craig Muni',			2873,33C3,C533,6667
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,18,22,11,03,08,04,00
	dc.b	01,19,21,12,04,09,03,00
	dc.b	01,20,23,13,05,10,03,00
	dc.b	01,22,19,11,13,03,05,00
	dc.b	01,20,18,12,05,09,11,00
	dc.b	01,18,20,13,12,04,09,00
	dc.b	01,19,23,04,09,12,13,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Kay Whitmore',			3545,8AA5,0100,5858
	Player	'Frank Petrangelo',		4055,8AA8,0100,5555
	Player	'John Cullen',			1158,8B28,32EB,B5BB
	Player	'Andrew Cassels',		2168,8885,3188,B582
	Player	'Geoff Sanderson',		085B,8888,6188,B882
	Player	'James Black',			2355,5555,3555,5B52
	Player	'Paul Gillis',			4478,B225,8B20,255E
	Player	'Bobby Holik',			2488,8885,9285,8B82
	Player	'Mark Hunter',			267B,8555,9458,EB5B
	Player	'Ed Kastelic',			2290,0220,8C0E,800B
	Player	'Pat Verbeek',			1668,5B2B,B6B8,B8BB
	Player	'Mikael Andersson',		3455,B8B5,0188,E880
	Player	'Murray Craven',		125B,BB8B,838B,E885
	Player	'Jim McKenzie',			3382,5255,355B,5F28
	Player	'Randy Cunnyworth',		0755,5855,9558,5B8B
	Player	'Yvon Corriveau',		2065,58B5,872B,5B25
	Player	'Paul Cyr',				1850,0220,0120,5B28
	Player	'Steve Konroyd',		0568,8585,B352,E288
	Player	'Zarley Zalapski',		038E,BB5B,95B5,E588
	Player	'Marc Bergevin',		2555,5528,6355,E255
	Player	'Randy Ladouceur',		29A8,2282,5552,852B
	Player	'Adam Burt',			0668,852B,8385,B288
	Player	'Doug Houda',			2762,2255,0225,852B
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,19,20,11,05,10,04,00
	dc.b	01,18,21,12,04,09,05,00
	dc.b	01,17,22,13,06,08,05,00
	dc.b	01,19,20,11,05,10,04,00
	dc.b	01,17,18,12,04,09,05,00
	dc.b	01,17,18,12,06,13,04,00
	dc.b	01,19,20,13,04,12,06,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Kelly Hrudey',			3259,9AAC,0100,6669
	Player	'Steve Weeks',			0133,9AA3,0100,6633
	Player	'David Goverde',		4380,9AA3,0000,0330
	Player	'Bob Kudelski',			3779,9939,629C,FC94
	Player	'Wayne Gretzky',		993F,CF36,61FC,C3F4
	Player	'John McIntyre',		4456,6696,9369,C36A
	Player	'Corey Millen',			2339,CC96,629C,669A
	Player	'Dave Taylor',			1869,66C9,9299,9667
	Player	'Jari Kurri',			176C,9C3C,6099,C994
	Player	'Tomas Sandstrom',		077C,CC6F,A7C9,CC9A
	Player	'Luc Robitaille',		206C,CF6C,71FC,C6CA
	Player	'Tony Granato',			215C,FC99,949C,FC9D
	Player	'Mike Donnelly',		115C,C996,936C,CC94
	Player	'Jay Miller',			2986,6369,CD69,396D
	Player	'Kyosti Karjalanen',	146C,C6C9,3193,6364
	Player	'Scott Bjugstad',		0853,3669,3166,6C64
	Player	'Peter Ahola',			2686,66C9,9766,F66A
	Player	'Marty McSorley',		33B3,9639,CC93,F39F
	Player	'Paul Coffey',			777F,FC9C,71F3,F3FA
	Player	'Rob Blake',			049C,966C,9293,F99D
	Player	'Larry Robinson',		19A9,6396,A396,9397
	Player	'Charlie Huddy',		2289,6639,9393,9397
	Player	'Tim Watters',			0556,6363,7360,636D
	Player	'Brent Thompson',		5643,3333,6530,633D
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,20,17,13,04,12,03,00
	dc.b	01,18,19,14,03,11,04,00
	dc.b	01,21,23,15,06,10,04,00
	dc.b	01,20,17,15,14,04,06,00
	dc.b	01,23,18,13,06,03,14,00
	dc.b	01,17,19,16,07,08,11,00
	dc.b	01,20,22,08,11,16,07,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Glenn Healy',			3546,9AA6,0100,3636
	Player	'Mark Fitzpatrik',		3063,9AA3,0100,3366
	Player	'Ray Ferraro',			2056,9CCC,65CF,C698
	Player	'Pierre Turgeon',		777C,CF9C,93CC,C6C2
	Player	'Adam Creighton',		1189,6963,656C,6C68
	Player	'Benoit Hogue',			336C,FCF9,65CC,C6C5
	Player	'Claude Loiselle',		1069,6333,9796,6C68
	Player	'Hubie McDonough',		3959,9666,756F,9F62
	Player	'Dan Marois',			2469,9909,3299,6C68
	Player	'Mick Vukota',			1260,9063,7C00,990E
	Player	'Tom Fitzgerald',		1463,0663,1066,CC35
	Player	'Patrick Flatley',		2679,6CF6,A2C9,93C5
	Player	'Steve Thomas',			325C,FC99,A599,C9C8
	Player	'Derek King',			2779,6C6C,33CF,C962
	Player	'Dave Volek',			255C,CC96,31C9,C692
	Player	'Bill Berg',			1769,3633,1106,9C02
	Player	'Tom Kurvers',			2869,9C3C,7396,F092
	Player	'Uwe Krupp',			04B6,69C9,A466,C395
	Player	'Richard Pilon',		4779,9399,AB63,C33B
	Player	'Jeff Finley',			0353,3369,4133,F032
	Player	'Jeff Norton',			0869,9996,7363,9095
	Player	'Wayne McBean',			0663,33F6,6363,6C65
	Player	'Scott Lachance',		0776,66F3,6163,6332
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,18,21,14,04,10,03,00
	dc.b	01,20,22,16,03,11,04,00
	dc.b	01,19,23,15,05,09,04,00
	dc.b	01,21,22,14,03,10,04,00
	dc.b	01,20,18,05,04,09,03,00
	dc.b	01,21,18,15,04,14,07,00
	dc.b	01,20,23,14,07,15,04,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Jon Casey',			301B,8BA8,0100,558B
	Player	'Darcy Wakaluk',		3555,8AA8,0100,5585
	Player	'Dave Gagner',			1555,5B58,8588,B85A
	Player	'Neal Broten',			073B,B828,8185,E8B1
	Player	'Bobby Smith',			1888,8825,6385,B5BD
	Player	'Todd Elik',			1468,BB85,6388,555D
	Player	'Marc Bureau',			1168,8255,6088,8E5A
	Player	'Kip Miller',			2528,8808,5188,5584
	Player	'Ulf Dahlen',			2268,5B58,518B,BB81
	Player	'Mike Modano',			096E,EB58,63E8,B8B4
	Player	'Mike Craig',			2058,8828,96B8,8B5D
	Player	'Shane Churla',			2772,5222,8C55,2F5F
	Player	'Stewart Gavin',		1268,8282,6155,5B27
	Player	'Brian Bellows',		236B,BB2B,62E8,E8B4
	Player	'Gaetan Duchesne',		1078,B585,8555,BB2A
	Player	'Brian Propp',			1668,5B55,6358,8857
	Player	'Derrick Smith',		2195,2222,9125,5B2A
	Player	'Chris Dahlquist',		0478,5255,8552,E287
	Player	'Craig Ludwig',			03A5,5282,9352,8227
	Player	'Jim Johnson',			0665,82B5,9782,B5BA
	Player	'Mark Tinordi',			2488,5828,B582,E25D
	Player	'David Shaw',			2685,5225,8452,555A
	Player	'Derian Hatcher',		2888,55B5,6558,B82D
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,20,18,14,05,13,04,00
	dc.b	01,21,23,16,04,10,05,00
	dc.b	01,19,22,15,06,11,05,00
	dc.b	01,20,19,14,16,04,05,00
	dc.b	01,21,23,17,05,09,14,00
	dc.b	01,19,23,16,08,14,05,00
	dc.b	01,20,18,14,05,16,08,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Patrick Roy',			335F,AFFF,0100,FFFF
	Player	'Roland Melanson',		0157,AAA7,0100,4477
	Player	'Andre Racicot',		4031,AAA1,0100,1111
	Player	'Stephan Lebeau',		474D,DDDA,70AD,DAA0
	Player	'Denis Savard',			184F,DDAA,52FD,F7D5
	Player	'Guy Carbonneau',		215F,DAA7,B0DD,AAD2
	Player	'John Leclair',			179A,D7AA,B17A,7D72
	Player	'Brian Skrudland',		397D,7477,D5A4,AFA5
	Player	'Brent Gilchrist',		415D,AAFA,81DD,AAA5
	Player	'Mike Keane',			124A,DAD7,8277,A7A5
	Player	'Chris Nilan',			3084,4474,DC4A,AD4E
	Player	'Todd Ewen',			36A4,41A4,DA44,4D4B
	Player	'Russ Courtnall',		065F,FDDA,70DA,A7D2
	Player	'Kirk Muller',			118D,DDDD,D5DD,FAD8
	Player	'Mike McPhee',			357A,D7AA,D37A,AD75
	Player	'Shayne Corson',		277D,DDDA,D7DA,FADB
	Player	'Gilbert Dionne',		456A,ADDA,71AF,7D72
	Player	'J.J. Daigneault',		485D,D4DD,73A4,D772
	Player	'Matt Schneider',		086A,77DA,B3A4,F7D5
	Player	'Eric Desjardins',		287D,AADA,B2D4,F4A5
	Player	'Lyle Odelein',			248A,44D7,BB74,D47B
	Player	'Sylvain Lefebvre',		038A,A4D4,8374,A4A8
	Player	'Kevin Haller',			1457,7774,8747,F478
	Player	'Patrice Brisebois',	434A,A7DA,A674,7475
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,22,23,14,03,08,04,00
	dc.b	01,20,21,13,04,09,03,00
	dc.b	01,18,19,12,05,10,03,00
	dc.b	01,23,20,13,03,08,04,00
	dc.b	01,21,22,14,04,09,03,00
	dc.b	01,23,19,12,11,05,10,00
	dc.b	01,21,22,05,10,12,11,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Chris Terreri',		311D,AAAA,0100,AAAA
	Player	'Craig Billington',		013A,AAA4,0100,7777
	Player	'Kevin Todd',			144A,DDA7,B57D,D7A5
	Player	'Peter Stastny',		267D,ADAA,A1DD,D7F5
	Player	'Alexnder Semak',		205A,AADA,A0DA,7DD0
	Player	'Randy McKay',			2154,47A4,AC7D,4D7B
	Player	'John MacLean',			157A,ADAD,A6AD,7D7B
	Player	'Stephane Richer',		447D,DDAF,70DA,DDA2
	Player	'Claude Lemieux',		229D,DDDA,B4AD,DD78
	Player	'Doug Brown',			245A,D7D7,B077,DD72
	Player	'Dave Barr',			116A,AAD4,B24A,A745
	Player	'Tom Chorske',			0987,7AA4,50AA,DDA2
	Player	'Claude Vilgrain',		198A,7AF7,52AF,D7A8
	Player	'Valeri Zelepukin',		255D,DDDA,71DD,DAD5
	Player	'Pat Conacher',			3267,74A4,514D,7F42
	Player	'Troy Mallette',		0881,17D1,874D,774B
	Player	'Zdeno Ciger',			336A,DA7A,41AD,7D72
	Player	'Ken Daneyko',			0387,74A4,DB74,A74B
	Player	'Bruce Driver',			235A,AAA7,A3A4,D4A5
	Player	'Eric Weinrich',		058A,DADA,A3A7,D4A5
	Player	'Alexei Kasatonov',		079D,AADD,B5DA,F4D5
	Player	'Slava Fetisov',		02AD,77DD,B5D4,F1D8
	Player	'Scott Stevens',		049D,ADFA,F7AA,F4DB
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,18,20,15,03,09,05,00
	dc.b	01,21,24,16,05,08,03,00
	dc.b	01,19,22,17,04,12,03,00
	dc.b	01,18,19,03,05,09,04,00
	dc.b	01,21,24,16,04,08,03,00
	dc.b	01,19,21,03,07,04,11,00
	dc.b	01,18,20,04,11,03,07,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'John Vanbiesbrk',		344A,ADAA,0100,ADAD
	Player	'Mike Richter',			355D,ADDD,0100,DDDD
	Player	'Mark Messier',			118F,DFFA,F3FD,F4F9
	Player	'Sergei Nemchinov',		135D,ADDA,A1AF,F7A0
	Player	'Darren Turcotte',		085F,DDDA,73DD,DDA6
	Player	'Doug Weight',			395A,AA77,73AA,7773
	Player	'Adam Graves',			095D,DDD7,A3AA,ADAC
	Player	'Tony Amonte',			335D,DDDA,72AD,DDA6
	Player	'Mike Gartner',			226F,FDDF,84FD,DDF6
	Player	'Paul Broten',			3764,47D4,744A,7D49
	Player	'Randy Gilhen',			1664,47A4,7177,AD43
	Player	'Joey Kocur',			2667,4477,DC77,AF7C
	Player	'Tie Domi',				2871,1471,8E17,4A1F
	Player	'Tim Kerr',				12B7,7A4A,50DA,7A73
	Player	'Kris King',			198D,D4D7,8BAA,ADAC
	Player	'John Ogrodnick',		258A,AAAA,A1AD,DDA3
	Player	'Jan Erixon',			207A,A7D7,71AD,AAA0
	Player	'Brian Leetch',			025F,AFDD,83F7,F1F3
	Player	'James Patrick',		038F,DDFD,B2D7,F1D6
	Player	'Jeff Beukeboom',		2397,74D7,AA74,D17C
	Player	'Joe Cirella',			068A,A4DA,8674,F47C
	Player	'Mark Hardy',			1467,74F4,8574,A479
	Player	'Jay Wells',			2487,74A7,A577,717C
	Player	'Per Djoos',			4447,A7D7,8074,D176
	Player	'Normand Rochefort',	0597,7114,B171,7A49
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,12,13,10,07,02,03,00
	dc.b	01,14,15,08,03,06,10,00
	dc.b	01,16,17,09,04,05,10,00
	dc.b	01,12,13,08,03,06,10,00
	dc.b	01,17,14,07,10,02,03,00
	dc.b	01,12,13,10,02,08,09,00
	dc.b	01,17,16,08,09,10,02,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Peter Sidorkwicz',		3055,8AA5,0100,5555
	Player	'Mark Lamb',			075C,C996,9196,6397
	Player	'Mark Freer',			3756,6393,736C,6963
	Player	'Laurie Boschman',		165D,77D7,A577,D77B
	Player	'Rob Murphy',			1780,0202,2100,280A
	Player	'Jim Thomson',			2586,6093,9A33,3C3D
	Player	'Chris Lindberg',		3368,B5B5,5388,555A
	Player	'Sylvain Turgeon',		207D,D77D,7377,AD75
	Player	'Mike Peluso',			4474,44A4,DD4D,4D4F
	Player	'Jeff Lazaro',			145C,F6C6,9796,6C68
	Player	'Darcy Loewen',			3650,0202,2100,250A
	Player	'Ken Hammond',			0668,8528,5582,B85C
	Player	'Brad Shaw',			326B,2588,5282,8285
	Player	'Kent Paynter',			0550,0020,2100,220A
	Player	'Dominic Lavoie',		3880,0020,2000,220A
	Player	'Darren Rumble',		3470,0020,2100,220A
	Player	'Brad Miller',			44A2,5255,8D22,855F
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,17,18,13,03,09,04,00
	dc.b	01,21,23,15,04,10,03,00
	dc.b	01,19,20,16,05,11,03,00
	dc.b	01,17,23,12,04,10,03,00
	dc.b	01,21,18,13,03,09,04,00
	dc.b	01,17,23,04,09,03,05,00
	dc.b	01,21,20,03,05,04,09,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Ron Hextall',			2769,9AA9,0100,CC99
	Player	'Dominic Roussel',		3353,9AA3,0100,3366
	Player	'Rod Brindamour',		177C,9C6C,75CC,F9C9
	Player	'Mike Ricci',			186C,CC66,9399,F6C9
	Player	'Pelle Eklund',			094F,C999,71C6,C9C0
	Player	'Keith Acton',			2536,6663,A136,6C3C
	Player	'Allan Conroy',			4653,3693,6536,633C
	Player	'Steve Kasper',			1549,9639,A39F,6CC6
	Player	'Kevin Dineen',			206C,FC66,7699,FC9C
	Player	'Mark Recchi',			085F,CF36,73CC,C6C9
	Player	'Dave Brown',			2180,0030,4C06,9F09
	Player	'Dan Quinn',			105C,C936,4199,9693
	Player	'Mark Pederson',		1476,6CC6,716C,C663
	Player	'Claude Boivin',		4070,0660,0309,663C
	Player	'Andrei Lomakin',		236C,9969,319C,99C3
	Player	'Brad Jones',			476C,F666,6569,9C66
	Player	'Steve Duchesne',		286C,CC6C,63C6,F3C9
	Player	'Garry Galley',			0366,6996,9793,C399
	Player	'Brian Benning',		1966,6969,A563,939C
	Player	'Terry Carkner',		2996,6336,9B63,C36C
	Player	'Kerry Huffman',		0579,9999,7399,F666
	Player	'Dan Kordic',			0680,0390,7603,693C
	Player	'Mark Howe',			0259,99FC,71C9,F3C3
	Player	'Corey Foster',			4470,0603,1133,6C36
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,18,17,13,04,09,03,00
	dc.b	01,19,23,14,03,10,04,00
	dc.b	01,20,21,15,05,08,04,00
	dc.b	01,17,20,13,04,08,10,00
	dc.b	01,21,18,03,10,09,04,00
	dc.b	01,17,22,14,03,05,08,00
	dc.b	01,18,20,05,08,14,03,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Tom Barrasso',			358C,9AC9,0000,99C9
	Player	'Ken Wregget',			3166,9AA6,0100,9696
	Player	'Ron Francis',			107C,9C6C,93CC,F6C3
	Player	'Mario Lemieux',		668F,CFFC,90FC,C3F9
	Player	'Bryan Trottier',		1969,9936,9199,C996
	Player	'Jiri Hrdina',			386C,9696,63C3,6693
	Player	'Ken Priestlay',		186C,C393,7596,6360
	Player	'Joe Mullen',			075C,9FC9,70CC,F993
	Player	'Jaromir Jagr',			688F,CCC9,A3FC,C9C3
	Player	'Rick Tocchet',			9286,6CCC,DA9C,C99C
	Player	'Jay Caufield',			16C3,3063,AC30,363C
	Player	'Jamie Leach',			2079,9366,966C,6C60
	Player	'Kevin Stevens',		2599,CF99,97CC,C9CC
	Player	'Bob Errey',			125C,F996,A59C,CC69
	Player	'Troy Loney',			2486,9666,CB69,993C
	Player	'Phil Bourque',			2976,C966,AB9C,3669
	Player	'Larry Murphy',			558C,9CFC,94C6,F3C6
	Player	'Kjell Samuelsson',		23B6,639C,C693,F669
	Player	'Gordie Roberts',		2869,66C3,9566,9069
	Player	'Ulf Samuelsson',		056C,C399,FB93,F39C
	Player	'Paul Stanton',			2269,933C,9463,C6C9
	Player	'Grant Jennings',		0376,6396,A769,663C
	Player	'Jim Paek',				0266,9393,6333,6366
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,20,19,17,05,10,04,00
	dc.b	01,18,24,14,04,08,05,00
	dc.b	01,21,22,16,07,09,05,00
	dc.b	01,20,19,05,10,09,04,00
	dc.b	01,22,24,14,04,08,09,00
	dc.b	01,20,24,16,04,14,05,00
	dc.b	01,21,18,14,05,16,04,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Jacques Cloutier',		3232,8AA2,0100,2225
	Player	'Stephane Fiset',		3142,8AA0,0100,2200
	Player	'John Tanner',			3450,8AA0,0100,0000
	Player	'Claude Lapointe',		4748,8855,5388,E859
	Player	'Joe Sakic',			195B,BE88,51B8,E5E3
	Player	'Jamie Baker',			2860,0552,2155,5B23
	Player	'Marc Fortier',			0968,8522,3058,8856
	Player	'Mats Sundin',			136B,BB2B,32BB,B8B9
	Player	'Greg Paslawski',		2365,5828,508E,BB53
	Player	'Owen Nolan',			116B,BB5B,36BE,B88C
	Player	'Herb Raglan',			1485,B555,2625,582C
	Player	'Mike McNeill',			2068,B222,2155,5553
	Player	'Gino Cavallini',		4492,8555,5355,5B56
	Player	'Mike Hough',			1868,5888,538B,E589
	Player	'John Tonelli',			2178,8555,B355,5559
	Player	'Doug Smail',			4148,8822,232B,B529
	Player	'Valeri Kamensky',		177B,BB5E,60BB,82B3
	Player	'Craig Wolanin',		0685,5222,5722,B529
	Player	'Alexei Gusarov',		0558,8558,6185,B283
	Player	'Mikhail Tatarinov',	0468,88BE,B5B2,E5B9
	Player	'Steven Finn',			2975,5228,9B52,B85C
	Player	'Adam Foote',			5255,5252,8252,B856
	Player	'Tony Twist',			1590,0050,3D00,280C
	Player	'Curtis Leschyshyn',	0788,B505,8355,E289
	Player	'Dan Lambert',			5042,2822,015B,5256
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,24,20,16,09,11,12,00
	dc.b	01,23,21,17,08,12,09,00
	dc.b	01,19,22,15,07,13,09,00
	dc.b	01,24,20,09,08,13,12,00
	dc.b	01,22,23,07,12,11,09,00
	dc.b	01,20,23,07,12,16,09,00
	dc.b	01,24,21,16,09,07,12,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Jeff Hackett',			3042,8AA2,0100,2225
	Player	'Jarmo Myllys',			3525,8AA2,0100,5528
	Player	'Arturs Irbe',			3245,8AA8,0100,8855
	Player	'Brian Hayward',		0155,8AA5,0100,5558
	Player	'Dean Evason',			0852,2525,8458,5859
	Player	'Perry Berezan',		166B,B505,6058,5E83
	Player	'Mike Sullivan',		4755,8525,2158,EB53
	Player	'Brian Lawton',			0965,5805,8358,B856
	Player	'Kelly Kisio',			1155,5B28,628B,E289
	Player	'Dale Craigwell',		3345,5855,8758,5523
	Player	'Pat Falloon',			176B,BB08,50B8,B880
	Player	'Brian Mullen',			1958,5828,5388,E886
	Player	'David Bruce',			1565,5828,225B,BB56
	Player	'Dave Snuggerud',		186B,8525,6582,5886
	Player	'Jeff Odgers',			3672,5225,6B58,8E2C
	Player	'Paul Fenton',			2258,5205,9358,BE53
	Player	'Steve Bozek',			145B,B505,8185,8E53
	Player	'Johan Garpenlov',		1058,8885,218B,5853
	Player	'Rob Zettler',			0265,5225,5582,8889
	Player	'Neil Wilkinson',		0568,8525,9482,E5BC
	Player	'David Williams',		0365,5825,8452,B226
	Player	'Link Gaetz',			2388,8208,BD85,288F
	Player	'Jay More',				0468,550B,8485,E28C
	Player	'Doug Wilson',			245B,880F,81B5,E5B3
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,22,17,14,04,10,06,00
	dc.b	01,18,20,15,06,08,04,00
	dc.b	01,19,21,13,07,09,04,00
	dc.b	01,22,17,06,10,08,04,00
	dc.b	01,21,20,07,04,09,08,00
	dc.b	01,22,20,07,09,13,05,00
	dc.b	01,21,19,13,05,07,09,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Curtis Joseph',		315C,9CCC,0100,99CC
	Player	'Guy Hebert',			4050,9AA0,0100,0000
	Player	'Pat Jablonski',		0143,9AA0,0000,3333
	Player	'Nelson Emerson',		073C,CC69,74CC,C696
	Player	'Bob Bassen',			2839,C6C6,AB96,966C
	Player	'Craig Janney',			156C,9C99,61CC,C3C3
	Player	'Ron Sutter',			2259,99C6,C49C,F6C9
	Player	'Brendan Shanahan',		1989,9C6C,9ACC,C9CC
	Player	'Dave Christian',		2769,6996,309C,F993
	Player	'Brett Hull',			167C,CF9F,90FC,CC96
	Player	'Kelly Chase',			3960,0063,1603,6F0F
	Player	'Darin Kimble',			2980,0360,7A36,360C
	Player	'Rich Sutter',			2363,9693,6466,CC69
	Player	'Dave Lowry',			1066,6636,9366,9C39
	Player	'Ron Wilson',			1859,99C3,6169,9966
	Player	'Dave MacKey',			2673,3033,6336,663C
	Player	'Jeff Brown',			2189,9C9F,62C6,C3C3
	Player	'Stephane Quintal',		3393,3633,9693,9399
	Player	'Garth Butcher',		0576,9696,CA96,C09C
	Player	'Rick Zombo',			0466,6699,7466,F066
	Player	'Murray Baron',			0689,9366,4333,F639
	Player	'Paul Cavallini',		148C,C999,95C3,F699
	Player	'Lee Norwood',			2076,66C3,7763,636C
	Player	'Rob Robinson',			4493,6033,6160,6933
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,13,12,09,02,06,03,00
	dc.b	01,14,15,10,03,07,02,00
	dc.b	01,16,17,11,04,08,02,00
	dc.b	01,12,14,09,02,06,04,00
	dc.b	01,15,13,11,04,07,02,00
	dc.b	01,14,13,10,03,11,05,00
	dc.b	01,16,18,11,05,10,03,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Wendell Young',		0159,9AA9,0100,9699
	Player	'Anatoli Semenov',		196C,9CCC,71CC,C9C4
	Player	'Rob Dimaio',			1846,9303,1269,9F05
	Player	'Brian Bradley',		443B,8858,8488,5585
	Player	'Michel Mongeau',		4163,3960,3139,6360
	Player	'Tim Hunter',			1572,2285,BC22,2B2F
	Player	'Tim Bergland',			1161,4444,1044,7740
	Player	'Shayne Stevenson',		4960,0222,2000,282A
	Player	'Mike Hartman',			2069,9363,CD33,9F3C
	Player	'Dan Vincelette',		1675,5202,2125,5B2A
	Player	'Basil McRae',			1785,5225,9F55,2B2F
	Player	'Peter Taglianeti',		3276,63CC,C593,C669
	Player	'Joe Reekie',			299C,66C9,7596,F36B
	Player	'Rob Ramage',			0578,555B,B685,EBBD
	Player	'Doug Crossman',		2867,77D7,7371,71A4
	Player	'Bob McGill',			0464,411D,B274,7F4A
	Player	'Jeff Bloemberg',		3870,0020,2000,222A
	Player	'Shawn Chambers',		2570,0000,2100,220A
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,17,19,13,03,06,05,00
	dc.b	01,20,21,10,05,08,03,00
	dc.b	01,18,22,14,04,07,03,00
	dc.b	01,17,19,13,10,03,07,00
	dc.b	01,18,22,05,07,06,13,00
	dc.b	01,19,21,12,04,10,03,00
	dc.b	01,18,17,10,03,12,04,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Grant Fuhr',			315E,8EEE,0000,BBEE
	Player	'Rick Wamsley',			3055,8AA5,0100,5555
	Player	'Doug Gilmour',			933E,8BB8,B1BB,E2B8
	Player	'Dave McLlwain',		0768,5552,6388,B882
	Player	'Peter Zezel',			2578,8B28,9188,B5B2
	Player	'Glenn Anderson',		106B,EB28,57B8,B8B8
	Player	'Mike Bullard',			2268,8828,2385,BB85
	Player	'Rob Pearson',			1255,5822,305B,8B58
	Player	'Mike Foligno',			7165,5855,E48B,5858
	Player	'Mike Krushelski',		2678,8555,8385,EB58
	Player	'Ken Baumgarter',		0870,0020,9D00,2E0E
	Player	'Mark Osborne',			2185,5525,5558,8828
	Player	'Wendel Clark',			1768,8B2E,B7B8,BBBB
	Player	'Guy Larose',			1142,5525,532B,8B25
	Player	'Joe Sacco',			2455,88E5,225B,5B52
	Player	'Kent Mandervill',		1875,8585,5350,5520
	Player	'Dave Ellett',			047B,B82E,95B5,E5B8
	Player	'Bob Rouse',			0388,8525,9452,E258
	Player	'Jamie Macoun',			3478,85BB,B582,E2B5
	Player	'Todd Gill',			2358,8225,B552,8258
	Player	'Ric Nattress',			0282,5582,5452,B228
	Player	'Darryl Shannon',		2868,5225,8182,B552
	Player	'Bob Halkidis',			3372,2222,2725,582B
	Player	'Dimitri Mironov',		1568,5208,218B,55B0
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,18,19,13,03,09,05,00
	dc.b	01,17,21,12,05,11,03,00
	dc.b	01,20,22,16,04,10,03,00
	dc.b	01,18,19,13,04,09,05,00
	dc.b	01,22,17,12,05,11,04,00
	dc.b	01,19,22,06,07,12,05,00
	dc.b	01,17,18,12,05,06,07,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Kirk McLean',			016D,AFFD,0100,DDFF
	Player	'Troy Gamble',			3567,AAA7,0100,77AA
	Player	'Cliff Ronning',		074F,FDD7,81DA,AAD4
	Player	'Petr Nedved',			1947,7A77,41AD,DAA4
	Player	'Igor Larionov',		183F,ADA7,71DF,F4F7
	Player	'Ryan Walter',			0977,74A7,83A7,AD77
	Player	'Tom Fergus',			1584,4D44,717D,A774
	Player	'Robert Kron',			5844,7447,21A4,7F71
	Player	'Trevor Linden',		168D,DDAD,A4DD,DADA
	Player	'Jim Sandlak',			2594,7ADA,7A7A,AA7D
	Player	'Pavel Bure',			104F,FDAA,71FA,DDD4
	Player	'Greg Adams',			086A,ADAA,B1AD,FDA4
	Player	'Geoff Courtnall',		146F,FD7A,45D7,DDDD
	Player	'Gino Odjick',			29A4,44A4,AF44,4D4F
	Player	'Garry Valk',			2364,47A4,4377,7A77
	Player	'Sergio Momesso',		279D,ADDA,D77A,AD7D
	Player	'Gerald Diduck',		048A,A77D,DAA4,F4AD
	Player	'Dave Babych',			4497,77AA,85A4,F7A7
	Player	'Jyrki Lumme',			216D,AAD7,83DA,F1D7
	Player	'Robert Dirk',			2297,74A7,A7A4,A77D
	Player	'Dana Murzyn',			0577,A4DD,B774,A77D
	Player	'Doug Lidster',			037A,AADA,B2D7,F4D4
	Player	'Randy Gregg',			2494,4444,5144,744A
	Player	'Adrien Plavsic',		0667,7AD7,A374,7177
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,20,21,17,07,10,04,00
	dc.b	01,18,24,14,04,11,07,00
	dc.b	01,22,23,15,05,09,07,00
	dc.b	01,20,21,07,10,11,04,00
	dc.b	01,22,18,14,04,12,11,00
	dc.b	01,20,23,15,04,14,05,00
	dc.b	01,22,18,14,05,15,04,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Bob Essensa',			352F,9CCF,0100,CCCC
	Player	'Steph Beauregard',		3056,9AA6,0000,3666
	Player	'Rick Tabaracci',		3156,9AA3,0100,3366
	Player	'Troy Murray',			196C,9936,C099,F9C6
	Player	'Mike Eagles',			3659,9636,D599,C96C
	Player	'Stu Barnes',			1446,9666,0069,6C33
	Player	'Thomas Steen',			256F,9CCC,A3FC,C3F6
	Player	'Aaron Broten',			1156,6693,413C,6933
	Player	'Lucien Deblois',		2376,6666,4066,9C66
	Player	'Ed Olczyk',			167C,9CCC,63C9,CCC9
	Player	'Pat Elynuik',			1559,9C6C,429C,C969
	Player	'Luciano Borsato',		3839,9966,609C,9696
	Player	'Danton Cole',			2469,C333,4099,6F36
	Player	'Darrin Shannon',		3476,6999,919C,F693
	Player	'Phil Sykes',			1743,0333,7339,9F39
	Player	'Doug Evans',			3953,3990,633C,693C
	Player	'Evgeny Davydov',		405C,C9FC,42C9,9CC6
	Player	'Teppo Numminen',		276C,99C9,70C3,F393
	Player	'Mike Lalor',			2279,63C6,7566,6669
	Player	'Fredrik Olausson',		047C,9C0C,10C6,F3C3
	Player	'Phil Housley',			064F,FF6C,61F6,C3F9
	Player	'Randy Carlyle',		0876,6396,A360,F966
	Player	'Shawn Cronin',			4480,0030,7D00,C60F
	Player	'Mario Marois',			3363,3333,6463,9969
	dc.b	0,2						; end of the player list (empty name)
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
	dc.b	01,19,20,12,05,08,04,00
	dc.b	01,18,24,15,04,11,05,00
	dc.b	01,21,22,14,06,10,05,00
	dc.b	01,19,18,15,07,04,05,00
	dc.b	01,21,20,06,05,08,04,00
	dc.b	01,21,24,12,05,06,07,00
	dc.b	01,18,19,06,07,12,05,00
.pld								; roster: Player records, then an empty record (length 2)
;									unwl,sodp,chga,eytm
	Player	'Don Beaupre',			3337,AAAA,0100,AAAA
	Player	'Mike Liut',			0167,AAA7,0100,A77A
	Player	'Jim Hrivnak',			3954,AAA4,0100,1144
	Player	'Dimitri Khristich',	085A,ADDD,A0DD,DAD2
	Player	'Mike Ridley',			177D,DDAD,81DF,F4D2
	Player	'Michal Pivonka',		207A,ADDA,A3DA,F7A2
	Player	'Dale Hunter',			3277,7DAA,DB7F,D4DB
	Player	'Dino Ciccarelli',		224F,DD7F,82FA,DDD8
	Player	'Paul MacDermid',		2387,7777,D67A,7A7B
	Player	'Peter Bondra',			125D,DDDA,71DD,AAA2
	Player	'John Druce',			1977,7ADA,A07D,ADA2
	Player	'Kelly Miller',			107D,DADA,71D7,D7D5
	Player	'Alan May',				1674,747A,BA4D,4A4B
	Player	'Todd Krygier',			2157,AAA7,8577,AD4B
	Player	'Randy Burridge',		185D,AD7D,73AD,D4D5
	Player	'Nick Kypreos',			0967,4474,BB7D,4A4B
	Player	'Dave Tippett',			1457,A7A4,4177,7442
	Player	'Calle Johansson',		068D,ADAD,A3DA,F1D2
	Player	'Kevin Hatcher',		04AA,AADF,E4D7,F7D8
	Player	'Sylvain Cote',			035A,AAAA,B0A7,D4A2
	Player	'Al Iafrate',			34AD,AAAD,DBDA,F4AB
	Player	'Rod Langway',			059A,74D4,A1A1,A172
	Player	'Ken Sabourin',			0284,4141,1111,771B
	Player	'Brad Schlegel',		285A,7147,7071,D770
	dc.b	0,2						; end of the player list (empty name)
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
	String	-1
CreditsPages						;the credits pages after the copyright group (printed by the title
									;screen), the first one blank
	String	''						;empty string: a blank first credits page (as at the end of this file)
	String	-1

	String	'Design adapted by'
	String	'Michael Brook'
	String	'Scott Orr'
	String	'Richard Hilleman'
	String	-1

	String	'Programmed by'
	String	'Jim Simmons'
	String	-1

	String	'Graphics by'
	String	'George Simmons'
	String	'Brian O''Hara'
	String	'Curt Toumanian'
	String	-1

	String	'Music and Sound by'
	String	'Jim Simmons'
	String	-1

	String	'Produced by'
	String	'Michael Brook'
	String	-1

	String	'Assistant Producer'
	String	'Steve Matulac'
	String	-1

	String	'Technical Directors'
	String	'Scott Cronce'
	String	'Tom DeBry'
	String	-1

	String	'Testing by'
	String	'Robert Zalot'
	String	'Yun Shin'
	String	'Joel Simmons'
	String	-1

	String	'Player Ratings by'
	String	'Igor Kuperman'
	String	-1

	String	'Special Thanks to'
	String	'Bob Borgen'
	String	'Ted Saskin'
	String	'Ian Pulver'
	String	'Rob Blake'
	String	'John McIntyre'
	String	-1

	
	String	''
	String	-1
	String	-1