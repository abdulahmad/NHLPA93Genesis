	dc.l	$0000

TeamList
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

NumofTeams	=	(*-TeamList)/4
Playerdata	=	0
Palettedata	=	2
Teamname	=	4
LineSets	=	6
ScoutReport	=	8
ScoreOdds	=	10

AllStarsEast
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\ASEh.pal
	incbin	..\Extracted\Graphics\Pals\ASEv.pal
;------------------------
;u - unknown
;u - unknown
;p - power play advantage
;u - unknown

;u - unknown
;u - unknown
;u - unknown
;u - unknown

;s - shooting
;k - skating
;p - passing
;d - defense

;c - checking
;f - fighting
;g - goalkeeping
;o - overall
;------------------------
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	7020,00D6,9999,9099
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	216,160
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,17,18,14,04,11,05,00	;line 1
	dc.b	01,19,20,15,05,12,04,00	;line 2
	dc.b	01,21,22,16,06,13,04,00	;line 3
	dc.b	01,17,18,14,04,11,05,00	;line 4
	dc.b	01,19,20,16,05,12,04,00	;line 5
	dc.b	01,21,22,16,08,15,07,00	;line 6
	dc.b	01,20,17,15,07,16,08,00	;line 7
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
.pld	;							unwl,sodp,chga,eytm
	Player	'Patrick Roy',			335F,AFFF,0100,FFFF	;1
	Player	'Mike Richter',			355D,ADDD,0100,DDDD	;2
	Player	'Don Beaupre',			0137,AAAA,0100,AAAA	;3
	Player	'Mario Lemieux',		668F,CFFC,90FC,C3F9	;4
	Player	'Mark Messier',			118F,DFFA,F3FD,F4F9	;5
	Player	'Rod Brindamour',		177C,9C6C,75CC,F9C9	;6
	Player	'Bryan Trottier',		1969,9936,9199,C996	;7
	Player	'Joe Sakic',			165B,BE88,51B8,E5E3	;8
	Player	'Ray Ferraro',			2056,9CCC,65CF,C698	;9
	Player	'John Cullen',			1558,8B28,32EB,B5BB	;10
	Player	'Jaromir Jagr',			688F,CCC9,A3FC,C9C3	;11
	Player	'Alexnder Mogilny',		896F,FE88,65EB,B8EA	;12
	Player	'Owen Nolan',			126B,BB5B,36BE,B88C	;13
	Player	'Kevin Stevens',		2599,CF99,97CC,C9CC	;14
	Player	'Randy Burridge',		185D,AD7D,73AD,D4D5	;15
	Player	'Kirk Muller',			098D,DDDD,D5DD,FAD8	;16
	Player	'Ray Bourque',			778F,CCCF,F1F6,F3F5	;17
	Player	'Paul Coffey',			077F,FC9C,71F3,F3FA	;18
	Player	'Brian Leetch',			025F,AFDD,83F7,F1F3	;19
	Player	'Kevin Hatcher',		05AA,AADF,E4D7,F7D8	;20
	Player	'Eric Desjardins',		287D,AADA,B2D4,F4A5	;21
	Player	'Scott Stevens',		049D,ADFA,F7AA,F4DB	;22
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'All Stars East'
.ta
	StringB	'ASE'

AllStarsWest
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\ASWh.pal
	incbin	..\Extracted\Graphics\Pals\ASWv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	7020,00C7,9999,9099
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	173,224
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,17,16,12,04,09,05,00	;line 1
	dc.b	01,18,19,13,05,10,04,00	;line 2
	dc.b	01,20,21,14,06,11,04,00	;line 3
	dc.b	01,17,16,12,05,09,04,00	;line 4
	dc.b	01,19,22,13,04,11,05,00	;line 5
	dc.b	01,17,20,14,07,15,08,00	;line 6
	dc.b	01,22,18,15,08,14,07,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Ed Belfour',			305F,AFFF,0100,FFFF	;1
	Player	'Kirk McLean',			016D,AFFD,0100,DDFF	;2
	Player	'Tim Cheveldae',		325D,ADDD,0100,DADD	;3
	Player	'Wayne Gretzky',		993F,CF36,61FC,C3F4	;4
	Player	'Jeremy Roenick',		273F,FFDF,84FF,DADA	;5
	Player	'Adam Oates',			126F,CF69,90F9,C3F2	;6
	Player	'Steve Yzerman',		185F,FFDD,50FD,FAF7	;7
	Player	'Sergei Fedorov',		916F,FDDD,A5FA,FAF7	;8
	Player	'Brett Hull',			167C,CF9F,90FC,CC96	;9
	Player	'Trevor Linden',		178D,DDAD,A4DD,DADA	;10
	Player	'Theoren Fleury',		142E,EB8B,C4BB,B88D	;11
	Player	'Luc Robitaille',		206C,CF6C,71FC,C6CA	;12
	Player	'Gary Roberts',			106B,BEEB,CBBF,B88D	;13
	Player	'Brian Bellows',		236B,BB2B,62E8,E8B4	;14
	Player	'Vincent Damphousse',	215C,CCC9,11FC,C9C7	;15
	Player	'Al MacInnis',			0278,8BBF,80B5,E2BA	;16
	Player	'Chris Chelios',		075D,ADDD,E4F4,F4DD	;17
	Player	'Doug Wilson',			245B,880F,81B5,E5B3	;18
	Player	'Phil Housley',			064F,FF6C,61F6,C3F9	;19
	Player	'Mark Tinordi',			2588,5828,B582,E25D	;20
	Player	'Larry Robinson',		19A9,6396,A396,9397	;21
	Player	'Dave Ellett',			047B,B82E,95B5,E5B8	;22
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'All Stars West'
.ta
	StringB	'ASW'

Boston
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\BOSh.pal
	incbin	..\Extracted\Graphics\Pals\BOSv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	3311,21E6,6766,6756
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	197,34
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,19,20,16,05,14,06,00	;line 1
	dc.b	01,21,22,17,06,11,05,00	;line 2
	dc.b	01,23,24,15,07,12,05,00	;line 3
	dc.b	01,19,20,05,06,14,16,00	;line 4
	dc.b	01,21,22,15,16,11,05,00	;line 5
	dc.b	01,19,20,11,12,15,07,00	;line 6
	dc.b	01,21,22,15,07,11,12,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Andy Moog',			353C,9ACC,0100,C9C9	;1
	Player	'Daniel Berthiaume',	3116,9AA6,0100,6966	;2
	Player	'Matt Delguidice',		3333,9AA3,0000,0300	;3
	Player	'Rejean Lemelin',		0139,9AA6,0100,6666	;4
	Player	'Adam Oates',			126F,CF69,90F9,C3F2	;5
	Player	'Vladimir Ruzicka',		389C,CC6C,77CC,CC95	;6
	Player	'Bob Sweeney',			207C,6639,CA96,C99B	;7
	Player	'Ken Hodge',			1079,963C,97C6,6992	;8
	Player	'Barry Pederson',		215C,C639,A499,6960	;9
	Player	'Joe Juneau',			494C,9FF6,6099,6392	;10
	Player	'Stephen Leach',		2759,9C69,AA99,FC9B	;11
	Player	'Peter Douris',			1669,C9C9,6296,CC60	;12
	Player	'Lyndon Byers',			3473,3033,CC06,3C0E	;13
	Player	'Cam Neely',			088C,CFFC,CA9F,CC9B	;14
	Player	'Brent Ashton',			188C,C966,C59C,F995	;15
	Player	'Bob Carpenter',		116F,CC6C,65CC,CCC5	;16
	Player	'Dave Reid',			1786,9699,4366,9C65	;17
	Player	'Andy Brickley',		2576,9FC6,636F,6090	;18
	Player	'Ray Bourque',			778F,CCCF,F1F6,F3F5	;19
	Player	'Glen Wesley',			266F,C96C,ABC3,F3C5	;20
	Player	'Don Sweeney',			323F,F36C,A5C3,F6C8	;21
	Player	'Gordon Murphy',		286F,C39C,CA93,F998	;22
	Player	'Jim Wiemer',			3686,33C3,6B63,966B	;23
	Player	'Bob Beers',			2279,9306,7230,9305	;24
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Boston'
.ta
	StringB	'BOS'

Buffalo
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\BUFh.pal
	incbin	..\Extracted\Graphics\Pals\BUFv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	5522,22D8,2442,3933
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	101,80
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,20,18,13,06,09,04,00	;line 1
	dc.b	01,17,21,14,04,10,06,00	;line 2
	dc.b	01,19,23,15,05,08,06,00	;line 3
	dc.b	01,18,17,13,06,09,04,00	;line 4
	dc.b	01,23,21,14,04,10,06,00	;line 5
	dc.b	01,17,21,06,08,14,05,00	;line 6
	dc.b	01,23,20,14,05,06,08,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Daren Puppa',			3188,8AA8,0000,5588	;1
	Player	'Clint Malarchuk',		3058,8AA8,0100,8885	;2
	Player	'Tom Draper',			3552,8AA0,0100,2220	;3
	Player	'Dale Hawerchuk',		105E,BE28,51E5,B5E4	;4
	Player	'Christan Ruuttu',		216B,B558,67B2,B8BA	;5
	Player	'Pat LaFontaine',		164E,BFB8,80EE,E5ED	;6
	Player	'Dave Hannan',			1452,2222,5328,582A	;7
	Player	'Tony Tanti',			195B,B858,67B8,BB5A	;8
	Player	'Alexnder Mogilny',		896F,FE88,65EB,B8EA	;9
	Player	'Donald Audette',		2848,8B88,668B,BB5A	;10
	Player	'Wayne Presley',		1858,880B,6655,5B5D	;11
	Player	'Colin Patterson',		176B,B252,9458,5554	;12
	Player	'Dave Andreychuk',		25A5,5E5B,6488,BB87	;13
	Player	'Randy Wood',			1562,E825,9755,EB5A	;14
	Player	'Brad May',				2775,5225,9D58,8E2F	;15
	Player	'Rob Ray',				3288,B222,BD5B,2B2F	;16
	Player	'Doug Bodger',			0885,8885,9752,E28A	;17
	Player	'Petr Svoboda',			074B,B588,95B2,B28D	;18
	Player	'Gord Donnelly',		3472,5022,BC25,285F	;19
	Player	'Mike Ramsey',			0568,22B5,8552,B22A	;20
	Player	'Ken Sutton',			4165,5585,5522,E28A	;21
	Player	'Randy Moller',			2488,5225,9652,555D	;22
	Player	'Grant Ledyard',		037B,885B,8B52,E287	;23
	Player	'Randy Hillier',		2365,2002,5A20,2B5D	;24
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Buffalo'
.ta
	StringB	'BUF'

Calgary
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\CGYh.pal
	incbin	..\Extracted\Graphics\Pals\CGYv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	6622,11D8,4334,4823
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	196,00
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,19,17,14,03,10,06,00	;line 1
	dc.b	01,18,21,13,06,11,03,00	;line 2
	dc.b	01,16,20,15,04,09,03,00	;line 3
	dc.b	01,19,17,14,03,10,05,00	;line 4
	dc.b	01,18,21,06,05,11,03,00	;line 5
	dc.b	01,17,16,04,07,13,09,00	;line 6
	dc.b	01,19,20,13,09,04,07,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Mike Vernon',			3038,8AAB,0100,BB88	;1
	Player	'Jeff Reese',			3535,8AA5,0100,5588	;2
	Player	'Theoren Fleury',		142E,EB8B,C4BB,B88D	;3
	Player	'Joel Otto',			29AB,8855,EA88,B85D	;4
	Player	'Robert Reichel',		265B,BB8B,53B8,88B4	;5
	Player	'Joe Nieuwendyk',		256B,BB8B,85BB,B557	;6
	Player	'Marc Habscheid',		175B,B528,84B8,8887	;7
	Player	'Carey Wilson',			3368,8825,508B,5857	;8
	Player	'Ronnie Stern',			2265,5585,9A58,BB5F	;9
	Player	'Sergei Makarov',		425E,BBB5,21EE,B2E7	;10
	Player	'Gary Leeman',			114B,B828,64B5,BBBA	;11
	Player	'Tomas Forslund',		277B,B522,31B8,5854	;12
	Player	'Paul Ranheim',			286B,B8B8,52BB,BB84	;13
	Player	'Gary Roberts',			106B,BEEB,CBBF,B88D	;14
	Player	'Craig Berube',			1685,8255,9D25,8B2D	;15
	Player	'Frank Musil',			038B,B2B5,9B52,B55A	;16
	Player	'Al MacInnis',			0278,8BBF,80B5,E2BA	;17
	Player	'Michel Petit',			0788,852B,9AB2,B28D	;18
	Player	'Gary Suter',			206E,BB8B,B5B5,E2BD	;19
	Player	'Mark Osiecki',			5575,5252,2252,B524	;20
	Player	'Trent Yawney',			1868,5555,8788,B287	;21
	Player	'Alexnder Godynyuk',	2185,8525,9B55,222D	;22
	Player	'Neil Sheehy',			1595,2225,8A22,282D	;23
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Calgary'
.ta
	StringB	'CGY'

Chicago
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\CHIh.pal
	incbin	..\Extracted\Graphics\Pals\CHIv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	3000,21D7,7777,9888
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	164,49
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,18,19,14,05,09,07,00	;line 1
	dc.b	01,20,22,16,07,11,05,00	;line 2
	dc.b	01,21,23,13,06,10,05,00	;line 3
	dc.b	01,18,19,14,05,09,10,00	;line 4
	dc.b	01,21,22,07,10,11,05,00	;line 5
	dc.b	01,21,22,07,10,06,09,00	;line 6
	dc.b	01,18,19,06,09,07,10,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Ed Belfour',			305F,AFFF,0100,FFFF	;1
	Player	'Dominik Hasek',		313A,AAA7,0100,7AAA	;2
	Player	'Jim Waite',			295A,AAA7,0100,77AA	;3
	Player	'Ray LeBlanc',			5034,AAA1,0000,1144	;4
	Player	'Jeremy Roenick',		273F,FFDF,84FF,DADA	;5
	Player	'Mike Hudson',			207A,A747,B77D,DDAA	;6
	Player	'Brent Sutter',			125A,7D4A,B4DA,FAA4	;7
	Player	'Tony Hrkac',			1137,77A4,8774,7744	;8
	Player	'Steve Larmer',			286D,ADDD,B5D7,FDD7	;9
	Player	'Dirk Graham',			337D,AA7A,DAA7,FDAA	;10
	Player	'Rob Brown',			225D,DD47,8BDD,D77A	;11
	Player	'Brian Noonan',			106A,AADD,A4AA,7FAA	;12
	Player	'Jocelyn Lemieux',		267A,D4AD,8774,AD4A	;13
	Player	'Michel Goulet',		166D,ADDA,85DA,D7D7	;14
	Player	'Stu Grimson',			23A4,4174,DD17,4D1F	;15
	Player	'Greg Gilbert',			1467,7477,BBAD,AD47	;16
	Player	'Stephane Matteau',		3267,7AD4,A77D,7A4D	;17
	Player	'Chris Chelios',		075D,ADDD,E4F4,F4DD	;18
	Player	'Steve Smith',			059D,D7DD,DBD4,F7DF	;19
	Player	'Frantsek Kucera',		0687,74A4,5274,A774	;20
	Player	'Bryan Marchment',		0274,7477,BB77,F44D	;21
	Player	'Keith Brown',			046D,D7D7,BAA4,FAAA	;22
	Player	'Rod Buskas',			2584,4144,5A41,A44D	;23
	Player	'Igor Kravchuk',		037D,AA4A,81D4,74A4	;24
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Chicago'
.ta
	StringB	'CHI'

Detroit
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\DETh.pal
	incbin	..\Extracted\Graphics\Pals\DETv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	6111,00D7,8879,7878
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	226,16
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,17,20,13,06,08,04,00	;line 1
	dc.b	01,18,22,14,04,07,06,00	;line 2
	dc.b	01,19,21,15,05,09,06,00	;line 3
	dc.b	01,17,20,06,04,08,05,00	;line 4
	dc.b	01,21,18,15,05,09,06,00	;line 5
	dc.b	01,20,18,06,07,13,04,00	;line 6
	dc.b	01,17,19,13,04,06,07,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Tim Cheveldae',		325D,ADDD,0100,DADD	;1
	Player	'Greg Millen',			3447,AAA4,0000,7774	;2
	Player	'Vincent Riendeau',		375A,AAA7,0100,A77A	;3
	Player	'Sergei Fedorov',		916F,FDDD,A5FA,FAF7	;4
	Player	'Jimmy Carson',			1277,DDDD,52DF,D7D4	;5
	Player	'Steve Yzerman',		195F,FFDD,50FD,FAF7	;6
	Player	'Kevin Miller',			236D,DAAA,B6DD,DAA7	;7
	Player	'Ray Sheppard',			2657,7DAA,B2AD,DD74	;8
	Player	'Bob Probert',			249D,ADDA,FF7F,D7AF	;9
	Player	'Brent Fedyk',			1464,747A,8477,7D77	;10
	Player	'Alan Kerr',			186A,A4A7,BA77,4A7D	;11
	Player	'Sheldon Kennedy',		283A,A777,7477,7777	;12
	Player	'Paul Ysebaert',		216D,DDFA,87DD,DAD7	;13
	Player	'Shawn Burr',			1157,7AD7,D77A,A77A	;14
	Player	'Gerard Gallant',		1757,7ADA,DBAA,DAAD	;15
	Player	'Keith Primeau',		55AA,AADA,577F,747D	;16
	Player	'Nicklas Lidstrom',		054D,ADFA,A5D7,F4D4	;17
	Player	'Vladimir Konstantov',	164A,AADA,EAA7,F4AD	;18
	Player	'Brad McCrimmon',		027A,77F7,D747,D4AA	;19
	Player	'Steve Chiasson',		038A,AAFD,BB77,F4AD	;20
	Player	'Yves Racine',			335A,A77D,B5A4,D4AA	;21
	Player	'Brad Marsh',			20A4,74D4,A547,A47A	;22
	Player	'Bobby Dollas',			0897,A4D1,231A,7F17	;23
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Detroit'
.ta
	StringB	'DET'

Edmonton
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\EDMh.pal
	incbin	..\Extracted\Graphics\Pals\EDMv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	6512,11C7,6535,4534
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	214,34
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,22,17,10,07,08,15,00	;line 1
	dc.b	01,19,20,11,15,06,07,00	;line 2
	dc.b	01,18,21,16,05,09,07,00	;line 3
	dc.b	01,17,21,10,07,08,05,00	;line 4
	dc.b	01,19,20,16,05,09,07,00	;line 5
	dc.b	01,22,18,16,05,12,08,00	;line 6
	dc.b	01,19,20,12,08,16,05,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Bill Ranford',			303C,9CFC,0100,CCFC	;1
	Player	'Ron Tugnutt',			3216,9AA3,0100,3336	;2
	Player	'Peter Ing',			0136,9AA3,0100,6969	;3
	Player	'Norm Foster',			3343,9AA3,0100,3363	;4
	Player	'Craig MacTavish',		146C,9696,C59C,C96A	;5
	Player	'Josef Beranek',		4259,9966,119C,6994	;6
	Player	'Bernie Nicholls',		0959,9C9C,32CC,C6C7	;7
	Player	'Joe Murphy',			086C,CCCC,A19C,F6C7	;8
	Player	'Scott Mellanby',		2783,3999,CA6C,C96D	;9
	Player	'Vincent Damphousse',	215C,CCC9,11FC,C9C7	;10
	Player	'Craig Simpson',		1866,6C99,649C,969A	;11
	Player	'Kelly Buchberger',		1686,6996,DD3F,963D	;12
	Player	'Martin Gelinas',		206C,C9C9,6399,6967	;13
	Player	'David Maley',			1260,09C9,9769,663D	;14
	Player	'Petr Klima',			856F,F93C,32FC,9C97	;15
	Player	'Esa Tikkanen',			107F,FC3C,F5C6,FCCA	;16
	Player	'Dave Manson',			2479,999F,CD96,C69D	;17
	Player	'Luke Richardson',		229C,C663,C793,C39A	;18
	Player	'Geoff Smith',			257C,C363,3393,F394	;19
	Player	'Brian Glynn',			0699,C66C,7363,F364	;20
	Player	'Norm MacIver',			3659,9CF9,9166,C097	;21
	Player	'Kevin Lowe',			046C,9369,A1C3,C39D	;22
	Player	'Craig Muni',			2873,33C3,C533,6667	;23
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Edmonton'
.ta
	StringB	'EDM'

Hartford
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\HFDh.pal
	incbin	..\Extracted\Graphics\Pals\HFDv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	1402,00F6,2222,1342
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	146,00
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,18,22,11,03,08,04,00	;line 1
	dc.b	01,19,21,12,04,09,03,00	;line 2
	dc.b	01,20,23,13,05,10,03,00	;line 3
	dc.b	01,22,19,11,13,03,05,00	;line 4
	dc.b	01,20,18,12,05,09,11,00	;line 5
	dc.b	01,18,20,13,12,04,09,00	;line 6
	dc.b	01,19,23,04,09,12,13,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Kay Whitmore',			3545,8AA5,0100,5858	;1
	Player	'Frank Petrangelo',		4055,8AA8,0100,5555	;2
	Player	'John Cullen',			1158,8B28,32EB,B5BB	;3
	Player	'Andrew Cassels',		2168,8885,3188,B582	;4
	Player	'Geoff Sanderson',		085B,8888,6188,B882	;5
	Player	'James Black',			2355,5555,3555,5B52	;6
	Player	'Paul Gillis',			4478,B225,8B20,255E	;7
	Player	'Bobby Holik',			2488,8885,9285,8B82	;8
	Player	'Mark Hunter',			267B,8555,9458,EB5B	;9
	Player	'Ed Kastelic',			2290,0220,8C0E,800B	;10
	Player	'Pat Verbeek',			1668,5B2B,B6B8,B8BB	;11
	Player	'Mikael Andersson',		3455,B8B5,0188,E880	;12
	Player	'Murray Craven',		125B,BB8B,838B,E885	;13
	Player	'Jim McKenzie',			3382,5255,355B,5F28	;14
	Player	'Randy Cunnyworth',		0755,5855,9558,5B8B	;15
	Player	'Yvon Corriveau',		2065,58B5,872B,5B25	;16
	Player	'Paul Cyr',				1850,0220,0120,5B28	;17
	Player	'Steve Konroyd',		0568,8585,B352,E288	;18
	Player	'Zarley Zalapski',		038E,BB5B,95B5,E588	;19
	Player	'Marc Bergevin',		2555,5528,6355,E255	;20
	Player	'Randy Ladouceur',		29A8,2282,5552,852B	;21
	Player	'Adam Burt',			0668,852B,8385,B288	;22
	Player	'Doug Houda',			2762,2255,0225,852B	;23
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Hartford'
.ta
	StringB	'HFD'

LosAngeles
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\LAh.pal
	incbin	..\Extracted\Graphics\Pals\LAv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	4410,10D8,5664,6535
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	198,16
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,19,20,11,05,10,04,00	;line 1
	dc.b	01,18,21,12,04,09,05,00	;line 2
	dc.b	01,17,22,13,06,08,05,00	;line 3
	dc.b	01,19,20,11,05,10,04,00	;line 4
	dc.b	01,17,18,12,04,09,05,00	;line 5
	dc.b	01,17,18,12,06,13,04,00	;line 6
	dc.b	01,19,20,13,04,12,06,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Kelly Hrudey',			3259,9AAC,0100,6669	;1
	Player	'Steve Weeks',			0133,9AA3,0100,6633	;2
	Player	'David Goverde',		4380,9AA3,0000,0330	;3
	Player	'Bob Kudelski',			3779,9939,629C,FC94	;4
	Player	'Wayne Gretzky',		993F,CF36,61FC,C3F4	;5
	Player	'John McIntyre',		4456,6696,9369,C36A	;6
	Player	'Corey Millen',			2339,CC96,629C,669A	;7
	Player	'Dave Taylor',			1869,66C9,9299,9667	;8
	Player	'Jari Kurri',			176C,9C3C,6099,C994	;9
	Player	'Tomas Sandstrom',		077C,CC6F,A7C9,CC9A	;10
	Player	'Luc Robitaille',		206C,CF6C,71FC,C6CA	;11
	Player	'Tony Granato',			215C,FC99,949C,FC9D	;12
	Player	'Mike Donnelly',		115C,C996,936C,CC94	;13
	Player	'Jay Miller',			2986,6369,CD69,396D	;14
	Player	'Kyosti Karjalanen',	146C,C6C9,3193,6364	;15
	Player	'Scott Bjugstad',		0853,3669,3166,6C64	;16
	Player	'Peter Ahola',			2686,66C9,9766,F66A	;17
	Player	'Marty McSorley',		33B3,9639,CC93,F39F	;18
	Player	'Paul Coffey',			777F,FC9C,71F3,F3FA	;19
	Player	'Rob Blake',			049C,966C,9293,F99D	;20
	Player	'Larry Robinson',		19A9,6396,A396,9397	;21
	Player	'Charlie Huddy',		2289,6639,9393,9397	;22
	Player	'Tim Watters',			0556,6363,7360,636D	;23
	Player	'Brent Thompson',		5643,3333,6530,633D	;24
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Los Angeles'
.ta
	StringB	'LA'

LongIsland
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\LIh.pal
	incbin	..\Extracted\Graphics\Pals\LIv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	5522,01E7,5455,5234
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	102,00
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,20,17,13,04,12,03,00	;line 1
	dc.b	01,18,19,14,03,11,04,00	;line 2
	dc.b	01,21,23,15,06,10,04,00	;line 3
	dc.b	01,20,17,15,14,04,06,00	;line 4
	dc.b	01,23,18,13,06,03,14,00	;line 5
	dc.b	01,17,19,16,07,08,11,00	;line 6
	dc.b	01,20,22,08,11,16,07,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Glenn Healy',			3546,9AA6,0100,3636	;1
	Player	'Mark Fitzpatrik',		3063,9AA3,0100,3366	;2
	Player	'Ray Ferraro',			2056,9CCC,65CF,C698	;3
	Player	'Pierre Turgeon',		777C,CF9C,93CC,C6C2	;4
	Player	'Adam Creighton',		1189,6963,656C,6C68	;5
	Player	'Benoit Hogue',			336C,FCF9,65CC,C6C5	;6
	Player	'Claude Loiselle',		1069,6333,9796,6C68	;7
	Player	'Hubie McDonough',		3959,9666,756F,9F62	;8
	Player	'Dan Marois',			2469,9909,3299,6C68	;9
	Player	'Mick Vukota',			1260,9063,7C00,990E	;10
	Player	'Tom Fitzgerald',		1463,0663,1066,CC35	;11
	Player	'Patrick Flatley',		2679,6CF6,A2C9,93C5	;12
	Player	'Steve Thomas',			325C,FC99,A599,C9C8	;13
	Player	'Derek King',			2779,6C6C,33CF,C962	;14
	Player	'Dave Volek',			255C,CC96,31C9,C692	;15
	Player	'Bill Berg',			1769,3633,1106,9C02	;16
	Player	'Tom Kurvers',			2869,9C3C,7396,F092	;17
	Player	'Uwe Krupp',			04B6,69C9,A466,C395	;18
	Player	'Richard Pilon',		4779,9399,AB63,C33B	;19
	Player	'Jeff Finley',			0353,3369,4133,F032	;20
	Player	'Jeff Norton',			0869,9996,7363,9095	;21
	Player	'Wayne McBean',			0663,33F6,6363,6C65	;22
	Player	'Scott Lachance',		0776,66F3,6163,6332	;23
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Long Island'
.ta
	StringB	'LI'

Minnesota
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\MINh.pal
	incbin	..\Extracted\Graphics\Pals\MINv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	1301,11F6,1232,1652
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	166,00
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,18,21,14,04,10,03,00	;line 1
	dc.b	01,20,22,16,03,11,04,00	;line 2
	dc.b	01,19,23,15,05,09,04,00	;line 3
	dc.b	01,21,22,14,03,10,04,00	;line 4
	dc.b	01,20,18,05,04,09,03,00	;line 5
	dc.b	01,21,18,15,04,14,07,00	;line 6
	dc.b	01,20,23,14,07,15,04,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Jon Casey',			301B,8BA8,0100,558B	;1
	Player	'Darcy Wakaluk',		3555,8AA8,0100,5585	;2
	Player	'Dave Gagner',			1555,5B58,8588,B85A	;3
	Player	'Neal Broten',			073B,B828,8185,E8B1	;4
	Player	'Bobby Smith',			1888,8825,6385,B5BD	;5
	Player	'Todd Elik',			1468,BB85,6388,555D	;6
	Player	'Marc Bureau',			1168,8255,6088,8E5A	;7
	Player	'Kip Miller',			2528,8808,5188,5584	;8
	Player	'Ulf Dahlen',			2268,5B58,518B,BB81	;9
	Player	'Mike Modano',			096E,EB58,63E8,B8B4	;10
	Player	'Mike Craig',			2058,8828,96B8,8B5D	;11
	Player	'Shane Churla',			2772,5222,8C55,2F5F	;12
	Player	'Stewart Gavin',		1268,8282,6155,5B27	;13
	Player	'Brian Bellows',		236B,BB2B,62E8,E8B4	;14
	Player	'Gaetan Duchesne',		1078,B585,8555,BB2A	;15
	Player	'Brian Propp',			1668,5B55,6358,8857	;16
	Player	'Derrick Smith',		2195,2222,9125,5B2A	;17
	Player	'Chris Dahlquist',		0478,5255,8552,E287	;18
	Player	'Craig Ludwig',			03A5,5282,9352,8227	;19
	Player	'Jim Johnson',			0665,82B5,9782,B5BA	;20
	Player	'Mark Tinordi',			2488,5828,B582,E25D	;21
	Player	'David Shaw',			2685,5225,8452,555A	;22
	Player	'Derian Hatcher',		2888,55B5,6558,B82D	;23
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Minnesota'
.ta
	StringB	'MIN'

Montreal
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\MTLh.pal
	incbin	..\Extracted\Graphics\Pals\MTLv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	3011,22E7,7888,8499
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	210,32
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,20,18,14,05,13,04,00	;line 1
	dc.b	01,21,23,16,04,10,05,00	;line 2
	dc.b	01,19,22,15,06,11,05,00	;line 3
	dc.b	01,20,19,14,16,04,05,00	;line 4
	dc.b	01,21,23,17,05,09,14,00	;line 5
	dc.b	01,19,23,16,08,14,05,00	;line 6
	dc.b	01,20,18,14,05,16,08,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Patrick Roy',			335F,AFFF,0100,FFFF	;1
	Player	'Roland Melanson',		0157,AAA7,0100,4477	;2
	Player	'Andre Racicot',		4031,AAA1,0100,1111	;3
	Player	'Stephan Lebeau',		474D,DDDA,70AD,DAA0	;4
	Player	'Denis Savard',			184F,DDAA,52FD,F7D5	;5
	Player	'Guy Carbonneau',		215F,DAA7,B0DD,AAD2	;6
	Player	'John Leclair',			179A,D7AA,B17A,7D72	;7
	Player	'Brian Skrudland',		397D,7477,D5A4,AFA5	;8
	Player	'Brent Gilchrist',		415D,AAFA,81DD,AAA5	;9
	Player	'Mike Keane',			124A,DAD7,8277,A7A5	;10
	Player	'Chris Nilan',			3084,4474,DC4A,AD4E	;11
	Player	'Todd Ewen',			36A4,41A4,DA44,4D4B	;12
	Player	'Russ Courtnall',		065F,FDDA,70DA,A7D2	;13
	Player	'Kirk Muller',			118D,DDDD,D5DD,FAD8	;14
	Player	'Mike McPhee',			357A,D7AA,D37A,AD75	;15
	Player	'Shayne Corson',		277D,DDDA,D7DA,FADB	;16
	Player	'Gilbert Dionne',		456A,ADDA,71AF,7D72	;17
	Player	'J.J. Daigneault',		485D,D4DD,73A4,D772	;18
	Player	'Matt Schneider',		086A,77DA,B3A4,F7D5	;19
	Player	'Eric Desjardins',		287D,AADA,B2D4,F4A5	;20
	Player	'Lyle Odelein',			248A,44D7,BB74,D47B	;21
	Player	'Sylvain Lefebvre',		038A,A4D4,8374,A4A8	;22
	Player	'Kevin Haller',			1457,7774,8747,F478	;23
	Player	'Patrice Brisebois',	434A,A7DA,A674,7475	;24
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Montreal'
.ta
	StringB	'MTL'

NewJersey
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\NJh.pal
	incbin	..\Extracted\Graphics\Pals\NJv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	5200,11F6,8668,6467
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	165,00
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,22,23,14,03,08,04,00	;line 1
	dc.b	01,20,21,13,04,09,03,00	;line 2
	dc.b	01,18,19,12,05,10,03,00	;line 3
	dc.b	01,23,20,13,03,08,04,00	;line 4
	dc.b	01,21,22,14,04,09,03,00	;line 5
	dc.b	01,23,19,12,11,05,10,00	;line 6
	dc.b	01,21,22,05,10,12,11,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Chris Terreri',		311D,AAAA,0100,AAAA	;1
	Player	'Craig Billington',		013A,AAA4,0100,7777	;2
	Player	'Kevin Todd',			144A,DDA7,B57D,D7A5	;3
	Player	'Peter Stastny',		267D,ADAA,A1DD,D7F5	;4
	Player	'Alexnder Semak',		205A,AADA,A0DA,7DD0	;5
	Player	'Randy McKay',			2154,47A4,AC7D,4D7B	;6
	Player	'John MacLean',			157A,ADAD,A6AD,7D7B	;7
	Player	'Stephane Richer',		447D,DDAF,70DA,DDA2	;8
	Player	'Claude Lemieux',		229D,DDDA,B4AD,DD78	;9
	Player	'Doug Brown',			245A,D7D7,B077,DD72	;10
	Player	'Dave Barr',			116A,AAD4,B24A,A745	;11
	Player	'Tom Chorske',			0987,7AA4,50AA,DDA2	;12
	Player	'Claude Vilgrain',		198A,7AF7,52AF,D7A8	;13
	Player	'Valeri Zelepukin',		255D,DDDA,71DD,DAD5	;14
	Player	'Pat Conacher',			3267,74A4,514D,7F42	;15
	Player	'Troy Mallette',		0881,17D1,874D,774B	;16
	Player	'Zdeno Ciger',			336A,DA7A,41AD,7D72	;17
	Player	'Ken Daneyko',			0387,74A4,DB74,A74B	;18
	Player	'Bruce Driver',			235A,AAA7,A3A4,D4A5	;19
	Player	'Eric Weinrich',		058A,DADA,A3A7,D4A5	;20
	Player	'Alexei Kasatonov',		079D,AADD,B5DA,F4D5	;21
	Player	'Slava Fetisov',		02AD,77DD,B5D4,F1D8	;22
	Player	'Scott Stevens',		049D,ADFA,F7AA,F4DB	;23
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'New Jersey'
.ta
	StringB	'NJ'

NewYork
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\NYh.pal
	incbin	..\Extracted\Graphics\Pals\NYv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	7120,20F8,7989,7789
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	152,00
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,18,20,15,03,09,05,00	;line 1
	dc.b	01,21,24,16,05,08,03,00	;line 2
	dc.b	01,19,22,17,04,12,03,00	;line 3
	dc.b	01,18,19,03,05,09,04,00	;line 4
	dc.b	01,21,24,16,04,08,03,00	;line 5
	dc.b	01,19,21,03,07,04,11,00	;line 6
	dc.b	01,18,20,04,11,03,07,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'John Vanbiesbrk',		344A,ADAA,0100,ADAD	;1
	Player	'Mike Richter',			355D,ADDD,0100,DDDD	;2
	Player	'Mark Messier',			118F,DFFA,F3FD,F4F9	;3
	Player	'Sergei Nemchinov',		135D,ADDA,A1AF,F7A0	;4
	Player	'Darren Turcotte',		085F,DDDA,73DD,DDA6	;5
	Player	'Doug Weight',			395A,AA77,73AA,7773	;6
	Player	'Adam Graves',			095D,DDD7,A3AA,ADAC	;7
	Player	'Tony Amonte',			335D,DDDA,72AD,DDA6	;8
	Player	'Mike Gartner',			226F,FDDF,84FD,DDF6	;9
	Player	'Paul Broten',			3764,47D4,744A,7D49	;10
	Player	'Randy Gilhen',			1664,47A4,7177,AD43	;11
	Player	'Joey Kocur',			2667,4477,DC77,AF7C	;12
	Player	'Tie Domi',				2871,1471,8E17,4A1F	;13
	Player	'Tim Kerr',				12B7,7A4A,50DA,7A73	;14
	Player	'Kris King',			198D,D4D7,8BAA,ADAC	;15
	Player	'John Ogrodnick',		258A,AAAA,A1AD,DDA3	;16
	Player	'Jan Erixon',			207A,A7D7,71AD,AAA0	;17
	Player	'Brian Leetch',			025F,AFDD,83F7,F1F3	;18
	Player	'James Patrick',		038F,DDFD,B2D7,F1D6	;19
	Player	'Jeff Beukeboom',		2397,74D7,AA74,D17C	;20
	Player	'Joe Cirella',			068A,A4DA,8674,F47C	;21
	Player	'Mark Hardy',			1467,74F4,8574,A479	;22
	Player	'Jay Wells',			2487,74A7,A577,717C	;23
	Player	'Per Djoos',			4447,A7D7,8074,D176	;24
	Player	'Normand Rochefort',	0597,7114,B171,7A49	;25
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'New York'
.ta
	StringB	'NY'

Ottawa
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\OTWh.pal
	incbin	..\Extracted\Graphics\Pals\OTWv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	0702,02A6,1111,1411
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	96,00
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,12,13,10,07,02,03,00	;line 1
	dc.b	01,14,15,08,03,06,10,00	;line 2
	dc.b	01,16,17,09,04,05,10,00	;line 3
	dc.b	01,12,13,08,03,06,10,00	;line 4
	dc.b	01,17,14,07,10,02,03,00	;line 5
	dc.b	01,12,13,10,02,08,09,00	;line 6
	dc.b	01,17,16,08,09,10,02,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Peter Sidorkwicz',		3055,8AA5,0100,5555	;1
	Player	'Mark Lamb',			075C,C996,9196,6397	;2
	Player	'Mark Freer',			3756,6393,736C,6963	;3
	Player	'Laurie Boschman',		165D,77D7,A577,D77B	;4
	Player	'Rob Murphy',			1780,0202,2100,280A	;5
	Player	'Jim Thomson',			2586,6093,9A33,3C3D	;6
	Player	'Chris Lindberg',		3368,B5B5,5388,555A	;7
	Player	'Sylvain Turgeon',		207D,D77D,7377,AD75	;8
	Player	'Mike Peluso',			4474,44A4,DD4D,4D4F	;9
	Player	'Jeff Lazaro',			145C,F6C6,9796,6C68	;10
	Player	'Darcy Loewen',			3650,0202,2100,250A	;11
	Player	'Ken Hammond',			0668,8528,5582,B85C	;12
	Player	'Brad Shaw',			326B,2588,5282,8285	;13
	Player	'Kent Paynter',			0550,0020,2100,220A	;14
	Player	'Dominic Lavoie',		3880,0020,2000,220A	;15
	Player	'Darren Rumble',		3470,0020,2100,220A	;16
	Player	'Brad Miller',			44A2,5255,8D22,855F	;17
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Ottawa'
.ta
	StringB	'OTW'

Philadelphia
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\PHIh.pal
	incbin	..\Extracted\Graphics\Pals\PHIv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	2201,22E8,3443,2353
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	147,00
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,17,18,13,03,09,04,00	;line 1
	dc.b	01,21,23,15,04,10,03,00	;line 2
	dc.b	01,19,20,16,05,11,03,00	;line 3
	dc.b	01,17,23,12,04,10,03,00	;line 4
	dc.b	01,21,18,13,03,09,04,00	;line 5
	dc.b	01,17,23,04,09,03,05,00	;line 6
	dc.b	01,21,20,03,05,04,09,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Ron Hextall',			2769,9AA9,0100,CC99	;1
	Player	'Dominic Roussel',		3353,9AA3,0100,3366	;2
	Player	'Rod Brindamour',		177C,9C6C,75CC,F9C9	;3
	Player	'Mike Ricci',			186C,CC66,9399,F6C9	;4
	Player	'Pelle Eklund',			094F,C999,71C6,C9C0	;5
	Player	'Keith Acton',			2536,6663,A136,6C3C	;6
	Player	'Allan Conroy',			4653,3693,6536,633C	;7
	Player	'Steve Kasper',			1549,9639,A39F,6CC6	;8
	Player	'Kevin Dineen',			206C,FC66,7699,FC9C	;9
	Player	'Mark Recchi',			085F,CF36,73CC,C6C9	;10
	Player	'Dave Brown',			2180,0030,4C06,9F09	;11
	Player	'Dan Quinn',			105C,C936,4199,9693	;12
	Player	'Mark Pederson',		1476,6CC6,716C,C663	;13
	Player	'Claude Boivin',		4070,0660,0309,663C	;14
	Player	'Andrei Lomakin',		236C,9969,319C,99C3	;15
	Player	'Brad Jones',			476C,F666,6569,9C66	;16
	Player	'Steve Duchesne',		286C,CC6C,63C6,F3C9	;17
	Player	'Garry Galley',			0366,6996,9793,C399	;18
	Player	'Brian Benning',		1966,6969,A563,939C	;19
	Player	'Terry Carkner',		2996,6336,9B63,C36C	;20
	Player	'Kerry Huffman',		0579,9999,7399,F666	;21
	Player	'Dan Kordic',			0680,0390,7603,693C	;22
	Player	'Mark Howe',			0259,99FC,71C9,F3C3	;23
	Player	'Corey Foster',			4470,0603,1133,6C36	;24
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Philadelphia'
.ta
	StringB	'PHI'

Pittsburgh
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\PITh.pal
	incbin	..\Extracted\Graphics\Pals\PITv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	7621,10E7,5566,5725
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	182,00
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,18,17,13,04,09,03,00	;line 1
	dc.b	01,19,23,14,03,10,04,00	;line 2
	dc.b	01,20,21,15,05,08,04,00	;line 3
	dc.b	01,17,20,13,04,08,10,00	;line 4
	dc.b	01,21,18,03,10,09,04,00	;line 5
	dc.b	01,17,22,14,03,05,08,00	;line 6
	dc.b	01,18,20,05,08,14,03,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Tom Barrasso',			358C,9AC9,0000,99C9	;1
	Player	'Ken Wregget',			3166,9AA6,0100,9696	;2
	Player	'Ron Francis',			107C,9C6C,93CC,F6C3	;3
	Player	'Mario Lemieux',		668F,CFFC,90FC,C3F9	;4
	Player	'Bryan Trottier',		1969,9936,9199,C996	;5
	Player	'Jiri Hrdina',			386C,9696,63C3,6693	;6
	Player	'Ken Priestlay',		186C,C393,7596,6360	;7
	Player	'Joe Mullen',			075C,9FC9,70CC,F993	;8
	Player	'Jaromir Jagr',			688F,CCC9,A3FC,C9C3	;9
	Player	'Rick Tocchet',			9286,6CCC,DA9C,C99C	;10
	Player	'Jay Caufield',			16C3,3063,AC30,363C	;11
	Player	'Jamie Leach',			2079,9366,966C,6C60	;12
	Player	'Kevin Stevens',		2599,CF99,97CC,C9CC	;13
	Player	'Bob Errey',			125C,F996,A59C,CC69	;14
	Player	'Troy Loney',			2486,9666,CB69,993C	;15
	Player	'Phil Bourque',			2976,C966,AB9C,3669	;16
	Player	'Larry Murphy',			558C,9CFC,94C6,F3C6	;17
	Player	'Kjell Samuelsson',		23B6,639C,C693,F669	;18
	Player	'Gordie Roberts',		2869,66C3,9566,9069	;19
	Player	'Ulf Samuelsson',		056C,C399,FB93,F39C	;20
	Player	'Paul Stanton',			2269,933C,9463,C6C9	;21
	Player	'Grant Jennings',		0376,6396,A769,663C	;22
	Player	'Jim Paek',				0266,9393,6333,6366	;23
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Pittsburgh'
.ta
	StringB	'PIT'

Quebec
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\QUEh.pal
	incbin	..\Extracted\Graphics\Pals\QUEv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	2602,22E8,3212,1321
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	84,32
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,20,19,17,05,10,04,00	;line 1
	dc.b	01,18,24,14,04,08,05,00	;line 2
	dc.b	01,21,22,16,07,09,05,00	;line 3
	dc.b	01,20,19,05,10,09,04,00	;line 4
	dc.b	01,22,24,14,04,08,09,00	;line 5
	dc.b	01,20,24,16,04,14,05,00	;line 6
	dc.b	01,21,18,14,05,16,04,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Jacques Cloutier',		3232,8AA2,0100,2225	;1
	Player	'Stephane Fiset',		3142,8AA0,0100,2200	;2
	Player	'John Tanner',			3450,8AA0,0100,0000	;3
	Player	'Claude Lapointe',		4748,8855,5388,E859	;4
	Player	'Joe Sakic',			195B,BE88,51B8,E5E3	;5
	Player	'Jamie Baker',			2860,0552,2155,5B23	;6
	Player	'Marc Fortier',			0968,8522,3058,8856	;7
	Player	'Mats Sundin',			136B,BB2B,32BB,B8B9	;8
	Player	'Greg Paslawski',		2365,5828,508E,BB53	;9
	Player	'Owen Nolan',			116B,BB5B,36BE,B88C	;10
	Player	'Herb Raglan',			1485,B555,2625,582C	;11
	Player	'Mike McNeill',			2068,B222,2155,5553	;12
	Player	'Gino Cavallini',		4492,8555,5355,5B56	;13
	Player	'Mike Hough',			1868,5888,538B,E589	;14
	Player	'John Tonelli',			2178,8555,B355,5559	;15
	Player	'Doug Smail',			4148,8822,232B,B529	;16
	Player	'Valeri Kamensky',		177B,BB5E,60BB,82B3	;17
	Player	'Craig Wolanin',		0685,5222,5722,B529	;18
	Player	'Alexei Gusarov',		0558,8558,6185,B283	;19
	Player	'Mikhail Tatarinov',	0468,88BE,B5B2,E5B9	;20
	Player	'Steven Finn',			2975,5228,9B52,B85C	;21
	Player	'Adam Foote',			5255,5252,8252,B856	;22
	Player	'Tony Twist',			1590,0050,3D00,280C	;23
	Player	'Curtis Leschyshyn',	0788,B505,8355,E289	;24
	Player	'Dan Lambert',			5042,2822,015B,5256	;25
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Quebec'
.ta
	StringB	'QUE'

SanJose
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\SJh.pal
	incbin	..\Extracted\Graphics\Pals\SJv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	0702,12E6,2111,3211
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	133,34
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,24,20,16,09,11,12,00	;line 1
	dc.b	01,23,21,17,08,12,09,00	;line 2
	dc.b	01,19,22,15,07,13,09,00	;line 3
	dc.b	01,24,20,09,08,13,12,00	;line 4
	dc.b	01,22,23,07,12,11,09,00	;line 5
	dc.b	01,20,23,07,12,16,09,00	;line 6
	dc.b	01,24,21,16,09,07,12,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Jeff Hackett',			3042,8AA2,0100,2225	;1
	Player	'Jarmo Myllys',			3525,8AA2,0100,5528	;2
	Player	'Arturs Irbe',			3245,8AA8,0100,8855	;3
	Player	'Brian Hayward',		0155,8AA5,0100,5558	;4
	Player	'Dean Evason',			0852,2525,8458,5859	;5
	Player	'Perry Berezan',		166B,B505,6058,5E83	;6
	Player	'Mike Sullivan',		4755,8525,2158,EB53	;7
	Player	'Brian Lawton',			0965,5805,8358,B856	;8
	Player	'Kelly Kisio',			1155,5B28,628B,E289	;9
	Player	'Dale Craigwell',		3345,5855,8758,5523	;10
	Player	'Pat Falloon',			176B,BB08,50B8,B880	;11
	Player	'Brian Mullen',			1958,5828,5388,E886	;12
	Player	'David Bruce',			1565,5828,225B,BB56	;13
	Player	'Dave Snuggerud',		186B,8525,6582,5886	;14
	Player	'Jeff Odgers',			3672,5225,6B58,8E2C	;15
	Player	'Paul Fenton',			2258,5205,9358,BE53	;16
	Player	'Steve Bozek',			145B,B505,8185,8E53	;17
	Player	'Johan Garpenlov',		1058,8885,218B,5853	;18
	Player	'Rob Zettler',			0265,5225,5582,8889	;19
	Player	'Neil Wilkinson',		0568,8525,9482,E5BC	;20
	Player	'David Williams',		0365,5825,8452,B226	;21
	Player	'Link Gaetz',			2388,8208,BD85,288F	;22
	Player	'Jay More',				0468,550B,8485,E28C	;23
	Player	'Doug Wilson',			245B,880F,81B5,E5B3	;24
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'San Jose'
.ta
	StringB	'SJ'

StLouis
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\STLh.pal
	incbin	..\Extracted\Graphics\Pals\STLv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	4210,21D8,4364,4564
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	194,32
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,22,17,14,04,10,06,00	;line 1
	dc.b	01,18,20,15,06,08,04,00	;line 2
	dc.b	01,19,21,13,07,09,04,00	;line 3
	dc.b	01,22,17,06,10,08,04,00	;line 4
	dc.b	01,21,20,07,04,09,08,00	;line 5
	dc.b	01,22,20,07,09,13,05,00	;line 6
	dc.b	01,21,19,13,05,07,09,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Curtis Joseph',		315C,9CCC,0100,99CC	;1
	Player	'Guy Hebert',			4050,9AA0,0100,0000	;2
	Player	'Pat Jablonski',		0143,9AA0,0000,3333	;3
	Player	'Nelson Emerson',		073C,CC69,74CC,C696	;4
	Player	'Bob Bassen',			2839,C6C6,AB96,966C	;5
	Player	'Craig Janney',			156C,9C99,61CC,C3C3	;6
	Player	'Ron Sutter',			2259,99C6,C49C,F6C9	;7
	Player	'Brendan Shanahan',		1989,9C6C,9ACC,C9CC	;8
	Player	'Dave Christian',		2769,6996,309C,F993	;9
	Player	'Brett Hull',			167C,CF9F,90FC,CC96	;10
	Player	'Kelly Chase',			3960,0063,1603,6F0F	;11
	Player	'Darin Kimble',			2980,0360,7A36,360C	;12
	Player	'Rich Sutter',			2363,9693,6466,CC69	;13
	Player	'Dave Lowry',			1066,6636,9366,9C39	;14
	Player	'Ron Wilson',			1859,99C3,6169,9966	;15
	Player	'Dave MacKey',			2673,3033,6336,663C	;16
	Player	'Jeff Brown',			2189,9C9F,62C6,C3C3	;17
	Player	'Stephane Quintal',		3393,3633,9693,9399	;18
	Player	'Garth Butcher',		0576,9696,CA96,C09C	;19
	Player	'Rick Zombo',			0466,6699,7466,F066	;20
	Player	'Murray Baron',			0689,9366,4333,F639	;21
	Player	'Paul Cavallini',		148C,C999,95C3,F699	;22
	Player	'Lee Norwood',			2076,66C3,7763,636C	;23
	Player	'Rob Robinson',			4493,6033,6160,6933	;24
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'St. Louis'
.ta
	StringB	'STL'

TampaBay
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\TBYh.pal
	incbin	..\Extracted\Graphics\Pals\TBYv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	0702,02A7,2111,1411
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	48,00
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,13,12,09,02,06,03,00	;line 1
	dc.b	01,14,15,10,03,07,02,00	;line 2
	dc.b	01,16,17,11,04,08,02,00	;line 3
	dc.b	01,12,14,09,02,06,04,00	;line 4
	dc.b	01,15,13,11,04,07,02,00	;line 5
	dc.b	01,14,13,10,03,11,05,00	;line 6
	dc.b	01,16,18,11,05,10,03,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Wendell Young',		0159,9AA9,0100,9699	;1
	Player	'Anatoli Semenov',		196C,9CCC,71CC,C9C4	;2
	Player	'Rob Dimaio',			1846,9303,1269,9F05	;3
	Player	'Brian Bradley',		443B,8858,8488,5585	;4
	Player	'Michel Mongeau',		4163,3960,3139,6360	;5
	Player	'Tim Hunter',			1572,2285,BC22,2B2F	;6
	Player	'Tim Bergland',			1161,4444,1044,7740	;7
	Player	'Shayne Stevenson',		4960,0222,2000,282A	;8
	Player	'Mike Hartman',			2069,9363,CD33,9F3C	;9
	Player	'Dan Vincelette',		1675,5202,2125,5B2A	;10
	Player	'Basil McRae',			1785,5225,9F55,2B2F	;11
	Player	'Peter Taglianeti',		3276,63CC,C593,C669	;12
	Player	'Joe Reekie',			299C,66C9,7596,F36B	;13
	Player	'Rob Ramage',			0578,555B,B685,EBBD	;14
	Player	'Doug Crossman',		2867,77D7,7371,71A4	;15
	Player	'Bob McGill',			0464,411D,B274,7F4A	;16
	Player	'Jeff Bloemberg',		3870,0020,2000,222A	;17
	Player	'Shawn Chambers',		2570,0000,2100,220A	;18
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Tampa Bay'
.ta
	StringB	'TBY'

Toronto
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\TORh.pal
	incbin	..\Extracted\Graphics\Pals\TORv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	1411,12E8,2123,3232
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	211,00
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,17,19,13,03,06,05,00	;line 1
	dc.b	01,20,21,10,05,08,03,00	;line 2
	dc.b	01,18,22,14,04,07,03,00	;line 3
	dc.b	01,17,19,13,10,03,07,00	;line 4
	dc.b	01,18,22,05,07,06,13,00	;line 5
	dc.b	01,19,21,12,04,10,03,00	;line 6
	dc.b	01,18,17,10,03,12,04,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Grant Fuhr',			315E,8EEE,0000,BBEE	;1
	Player	'Rick Wamsley',			3055,8AA5,0100,5555	;2
	Player	'Doug Gilmour',			933E,8BB8,B1BB,E2B8	;3
	Player	'Dave McLlwain',		0768,5552,6388,B882	;4
	Player	'Peter Zezel',			2578,8B28,9188,B5B2	;5
	Player	'Glenn Anderson',		106B,EB28,57B8,B8B8	;6
	Player	'Mike Bullard',			2268,8828,2385,BB85	;7
	Player	'Rob Pearson',			1255,5822,305B,8B58	;8
	Player	'Mike Foligno',			7165,5855,E48B,5858	;9
	Player	'Mike Krushelski',		2678,8555,8385,EB58	;10
	Player	'Ken Baumgarter',		0870,0020,9D00,2E0E	;11
	Player	'Mark Osborne',			2185,5525,5558,8828	;12
	Player	'Wendel Clark',			1768,8B2E,B7B8,BBBB	;13
	Player	'Guy Larose',			1142,5525,532B,8B25	;14
	Player	'Joe Sacco',			2455,88E5,225B,5B52	;15
	Player	'Kent Mandervill',		1875,8585,5350,5520	;16
	Player	'Dave Ellett',			047B,B82E,95B5,E5B8	;17
	Player	'Bob Rouse',			0388,8525,9452,E258	;18
	Player	'Jamie Macoun',			3478,85BB,B582,E2B5	;19
	Player	'Todd Gill',			2358,8225,B552,8258	;20
	Player	'Ric Nattress',			0282,5582,5452,B228	;21
	Player	'Darryl Shannon',		2868,5225,8182,B552	;22
	Player	'Bob Halkidis',			3372,2222,2725,582B	;23
	Player	'Dimitri Mironov',		1568,5208,218B,55B0	;24
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Toronto'
.ta
	StringB	'TOR'

Vancouver
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\VANh.pal
	incbin	..\Extracted\Graphics\Pals\VANv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	4111,10E8,6877,7577
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	211,00
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,18,19,13,03,09,05,00	;line 1
	dc.b	01,17,21,12,05,11,03,00	;line 2
	dc.b	01,20,22,16,04,10,03,00	;line 3
	dc.b	01,18,19,13,04,09,05,00	;line 4
	dc.b	01,22,17,12,05,11,04,00	;line 5
	dc.b	01,19,22,06,07,12,05,00	;line 6
	dc.b	01,17,18,12,05,06,07,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Kirk McLean',			016D,AFFD,0100,DDFF	;1
	Player	'Troy Gamble',			3567,AAA7,0100,77AA	;2
	Player	'Cliff Ronning',		074F,FDD7,81DA,AAD4	;3
	Player	'Petr Nedved',			1947,7A77,41AD,DAA4	;4
	Player	'Igor Larionov',		183F,ADA7,71DF,F4F7	;5
	Player	'Ryan Walter',			0977,74A7,83A7,AD77	;6
	Player	'Tom Fergus',			1584,4D44,717D,A774	;7
	Player	'Robert Kron',			5844,7447,21A4,7F71	;8
	Player	'Trevor Linden',		168D,DDAD,A4DD,DADA	;9
	Player	'Jim Sandlak',			2594,7ADA,7A7A,AA7D	;10
	Player	'Pavel Bure',			104F,FDAA,71FA,DDD4	;11
	Player	'Greg Adams',			086A,ADAA,B1AD,FDA4	;12
	Player	'Geoff Courtnall',		146F,FD7A,45D7,DDDD	;13
	Player	'Gino Odjick',			29A4,44A4,AF44,4D4F	;14
	Player	'Garry Valk',			2364,47A4,4377,7A77	;15
	Player	'Sergio Momesso',		279D,ADDA,D77A,AD7D	;16
	Player	'Gerald Diduck',		048A,A77D,DAA4,F4AD	;17
	Player	'Dave Babych',			4497,77AA,85A4,F7A7	;18
	Player	'Jyrki Lumme',			216D,AAD7,83DA,F1D7	;19
	Player	'Robert Dirk',			2297,74A7,A7A4,A77D	;20
	Player	'Dana Murzyn',			0577,A4DD,B774,A77D	;21
	Player	'Doug Lidster',			037A,AADA,B2D7,F4D4	;22
	Player	'Randy Gregg',			2494,4444,5144,744A	;23
	Player	'Adrien Plavsic',		0667,7AD7,A374,7177	;24
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Vancouver'
.ta
	StringB	'VAN'

Winnipeg
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\WPGh.pal
	incbin	..\Extracted\Graphics\Pals\WPGv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	2020,10E7,4555,2185
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	149,48
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,20,21,17,07,10,04,00	;line 1
	dc.b	01,18,24,14,04,11,07,00	;line 2
	dc.b	01,22,23,15,05,09,07,00	;line 3
	dc.b	01,20,21,07,10,11,04,00	;line 4
	dc.b	01,22,18,14,04,12,11,00	;line 5
	dc.b	01,20,23,15,04,14,05,00	;line 6
	dc.b	01,22,18,14,05,15,04,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Bob Essensa',			352F,9CCF,0100,CCCC	;1
	Player	'Steph Beauregard',		3056,9AA6,0000,3666	;2
	Player	'Rick Tabaracci',		3156,9AA3,0100,3366	;3
	Player	'Troy Murray',			196C,9936,C099,F9C6	;4
	Player	'Mike Eagles',			3659,9636,D599,C96C	;5
	Player	'Stu Barnes',			1446,9666,0069,6C33	;6
	Player	'Thomas Steen',			256F,9CCC,A3FC,C3F6	;7
	Player	'Aaron Broten',			1156,6693,413C,6933	;8
	Player	'Lucien Deblois',		2376,6666,4066,9C66	;9
	Player	'Ed Olczyk',			167C,9CCC,63C9,CCC9	;10
	Player	'Pat Elynuik',			1559,9C6C,429C,C969	;11
	Player	'Luciano Borsato',		3839,9966,609C,9696	;12
	Player	'Danton Cole',			2469,C333,4099,6F36	;13
	Player	'Darrin Shannon',		3476,6999,919C,F693	;14
	Player	'Phil Sykes',			1743,0333,7339,9F39	;15
	Player	'Doug Evans',			3953,3990,633C,693C	;16
	Player	'Evgeny Davydov',		405C,C9FC,42C9,9CC6	;17
	Player	'Teppo Numminen',		276C,99C9,70C3,F393	;18
	Player	'Mike Lalor',			2279,63C6,7566,6669	;19
	Player	'Fredrik Olausson',		047C,9C0C,10C6,F3C3	;20
	Player	'Phil Housley',			064F,FF6C,61F6,C3F9	;21
	Player	'Randy Carlyle',		0876,6396,A360,F966	;22
	Player	'Shawn Cronin',			4480,0030,7D00,C60F	;23
	Player	'Mario Marois',			3363,3333,6463,9969	;24
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Winnipeg'
.ta
	StringB	'WPG'

Washington
.0
	dc.w	.pld-.0
	dc.w	.pad-.0
	dc.w	.tn-.0
	dc.w	.ls-.0
	dc.w	.sr-.0
	dc.w	.sodds-.0
.pad
	incbin	..\Extracted\Graphics\Pals\WSHh.pal
	incbin	..\Extracted\Graphics\Pals\WSHv.pal
.sr	;		uupu,uuuu,skpd,cfgo ; TODO - discover unknown attributes
	hex2	7320,00E7,9697,8458
.sodds	; TODO - rename this once unknowns/sodds are confirmed
	dc.b	164,32
.ls	;		-G,LD,RD,LW,-C,RW,XA,00
	dc.b	01,19,20,12,05,08,04,00	;line 1
	dc.b	01,18,24,15,04,11,05,00	;line 2
	dc.b	01,21,22,14,06,10,05,00	;line 3
	dc.b	01,19,18,15,07,04,05,00	;line 4
	dc.b	01,21,20,06,05,08,04,00	;line 5
	dc.b	01,21,24,12,05,06,07,00	;line 6
	dc.b	01,18,19,06,07,12,05,00	;line 7
.pld	;							unwl,sodp,chga,eytm
	Player	'Don Beaupre',			3337,AAAA,0100,AAAA	;1
	Player	'Mike Liut',			0167,AAA7,0100,A77A	;2
	Player	'Jim Hrivnak',			3954,AAA4,0100,1144	;3
	Player	'Dimitri Khristich',	085A,ADDD,A0DD,DAD2	;4
	Player	'Mike Ridley',			177D,DDAD,81DF,F4D2	;5
	Player	'Michal Pivonka',		207A,ADDA,A3DA,F7A2	;6
	Player	'Dale Hunter',			3277,7DAA,DB7F,D4DB	;7
	Player	'Dino Ciccarelli',		224F,DD7F,82FA,DDD8	;8
	Player	'Paul MacDermid',		2387,7777,D67A,7A7B	;9
	Player	'Peter Bondra',			125D,DDDA,71DD,AAA2	;10
	Player	'John Druce',			1977,7ADA,A07D,ADA2	;11
	Player	'Kelly Miller',			107D,DADA,71D7,D7D5	;12
	Player	'Alan May',				1674,747A,BA4D,4A4B	;13
	Player	'Todd Krygier',			2157,AAA7,8577,AD4B	;14
	Player	'Randy Burridge',		185D,AD7D,73AD,D4D5	;15
	Player	'Nick Kypreos',			0967,4474,BB7D,4A4B	;16
	Player	'Dave Tippett',			1457,A7A4,4177,7442	;17
	Player	'Calle Johansson',		068D,ADAD,A3DA,F1D2	;18
	Player	'Kevin Hatcher',		04AA,AADF,E4D7,F7D8	;19
	Player	'Sylvain Cote',			035A,AAAA,B0A7,D4A2	;20
	Player	'Al Iafrate',			34AD,AAAD,DBDA,F4AB	;21
	Player	'Rod Langway',			059A,74D4,A1A1,A172	;22
	Player	'Ken Sabourin',			0284,4141,1111,771B	;23
	Player	'Brad Schlegel',		285A,7147,7071,D770	;24
	dc.b 0,2	; TODO not sure why this is here
.tn
	StringB	'Washington'
.ta
	StringB	'WSH'


playoffseats
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


Credits
	String	'$ 1992 Electronic Arts'
	String	'Licensed by'
	String	'Sega Enterprises Ltd.'
	String	-1
	dc.b	0,2 ;	TODO -- this is strange-- maybe something missing from the macro?
	String  -1

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