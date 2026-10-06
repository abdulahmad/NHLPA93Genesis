;	NHLPA Hockey 93 (retail) segment $1510A-$15FE5
;	Data only: the 92 crowd frame table (updatecrowdf .cd0), the player logic assignment table asstab,
;	the 93 PenaltyList, bfasciicon, linelist, PlayerPositionText, PerLabels, sizetab, sublist,
;	priolist, the playoff tree layout (92 PlayoffScreen .setup), the line editor / roster attribute
;	column lists, and the menu item lists for the pause, intermission and line editor exit menus.
;	sram93 (BackupRAM_*) starts at $15FE6.
;	Global names from the IDA export, 92 names where the table is the same (see the
;	SEGMENT_AGENT.md rename table). Bytes match nhlpa93retail.bin.
;	Code addresses in the tables are retail addresses of the routines in earlier segments; the
;	Rev A listing has them $E or $18 higher.
;	Menu item lists (InitMenuState in menu93): two printsmall control Strings, then per item a
;	String and the handler address (dc.l). Item 0 leaves the menu, its handler is rtss. String $FF ends.

cd0	;$fftt = frame/time for various levels of crowd excitement. 92 updatecrowdf .cd0, same bytes.
	;Global in 93: used by updatecrowdf (hockey93_01), indexed by crowd level and crowdstep
	dc.w	$010c,$020c,$030c,$040c,$050c,$0a0c,$090c,$080c
	dc.w	$060c,$070c,$080c,$090c,$0a0c,$050c,$040c,$030c

	dc.w	$0107,$0207,$0307,$0407,$0507,$0b07,$0c07,$0d07
	dc.w	$0607,$0707,$0807,$0907,$0a07,$0b07,$0c07,$0d07

	dc.w	$0e07,$0f07,$1007,$1107,$1207,$0b07,$0c07,$0d07
	dc.w	$1207,$1107,$1007,$0f07,$0e07,$0d07,$0c07,$0b07

	dc.w	$0e03,$0f03,$1003,$1103,$1203,$0b03,$0c03,$0d03
	dc.w	$1203,$1103,$1003,$0f03,$0e03,$0d03,$0c03,$0b03

asstab	;jump table of all the player logic assignments. 92 asstab without assnothing, so from
	;assscore on the 93 numbers are one lower than 92. Used by updateplayers
	dc.l	rtss			;0
	dc.l	assdefo			;1 adefo
	dc.l	assdefd			;2 adefd
	dc.l	asswingd		;3 awingd
	dc.l	asswingo		;4 awingo
	dc.l	asscenterd		;5 acenterd
	dc.l	asscentero		;6 acentero
	dc.l	assscore		;7 ascore
	dc.l	assstanley		;8 astanley
	dc.l	asseben			;9 aeben
	dc.l	assepen			;$A aepen
	dc.l	assbench		;$B abench
	dc.l	asspenalty		;$C apenalty
	dc.l	assdopen		;$D adopen
	dc.l	assgoalie		;$E agoalie (IDA loc_B18A)
	dc.l	assgoalietopuck		;$F 93 only
	dc.l	asspuckc		;$10 apuckc
	dc.l	assnearest		;$11 anearest
	dc.l	assshoot		;$12 ashoot (IDA loc_C028)
	dc.l	asspassrec		;$13 apassrec (IDA loc_BFC6)
	dc.l	assfight		;$14 afight
	dc.l	assfwatch		;$15
	dc.l	assfaceoff		;$16
	dc.l	assfaceoffp1		;$17
	dc.l	pucknorm		;$18 puck logic
	dc.l	puckshadow		;$19
	dc.l	pucknothing		;$1A (IDA puckunflip in the Rev A listing)
	dc.l	puckfaceoff		;$1B
	dc.l	puckfaceoff2		;$1C

PenaltyList	;92 Penaltylist. Penalty number = word offset into this table; 93 reorders the numbers
	;and has 3 more entries. Used by AddPenalty, SetPA2, stats93 DisplayPenaltyEntry, ...
	dc.w	$0000
	dc.w	.eop-PenaltyList	;2 period over (92 PenEOP 2)
	dc.w	.eog-PenaltyList	;4 game over (92 PenEOG 4)
	dc.w	.ghold-PenaltyList	;6 (92 PenOOP $C)
	dc.w	.ghold-PenaltyList	;8 (92 PenGhold $E)
	dc.w	.whistle-PenaltyList	;$A whistle (92 PenWhistle $26)
	dc.w	.ice-PenaltyList	;$C icing (92 PenIcing 8)
	dc.w	.goal-PenaltyList	;$E goal (92 PenGoal 6)
	dc.w	.offsides-PenaltyList	;$10 offsides (92 PenOffsides $A)
	dc.w	.rough2-PenaltyList	;$12 roughing, slow down time $A
	dc.w	.p14-PenaltyList	;$14 93 only, no text
	dc.w	.charge-PenaltyList	;$16
	dc.w	.slash-PenaltyList	;$18
	dc.w	.rough-PenaltyList	;$1A
	dc.w	.cross-PenaltyList	;$1C
	dc.w	.hook-PenaltyList	;$1E
	dc.w	.trip-PenaltyList	;$20
	dc.w	.int-PenaltyList	;$22
	dc.w	.hold-PenaltyList	;$24
	dc.w	.fight-PenaltyList	;$26
	dc.w	.fight2-PenaltyList	;$28 93 only
	dc.w	.inst-PenaltyList	;$2A
	dc.w	.delay-PenaltyList	;$2C delay (92 PenDelay $24)

;format
;	dc.w	$ttmm	;tt=slow dnw time in half secs,mm=penalty min.
;	String	'penalty text'
;	dc.w	$ffdd,$ffdd,$ffdd,...	;ff = frame,dd=delay (neg for end)

.eop	dc.w	$0100
	String	'Period Over'
	dc.w	-$0510
.eog	dc.w	$0100
	String	'Game Over'
	dc.w	$0510,-$4060
.goal	dc.w	$0100
	dc.w	2			;String with no text (92 'Goal!')
	dc.w	$050a,-$4010
.p14	dc.w	$0100
	dc.w	2			;String with no text
	dc.w	$0510,-$4018
.ice	dc.w	$0100
	String	'Icing'
	dc.w	$0002,$0101,-$0206
.offsides	dc.w	$0100
	String	'Off-side'
	dc.w	$0002,$0301,-$040f
.ghold	dc.w	$0100
	String	'Face Off'
	dc.w	-$050a
.delay	dc.w	$0000
	String	'Penalty'
	dc.w	$0003,$0301,-$040f

.whistle	dc.w	$0000
	dc.w	2			;String with no text
	dc.w	-$050a

.charge	dc.w	$0402
	String	'Charging'
	dc.w	$0004,$0101,$0a01,$0b01,$0a01,$0b01,$0a01,$0b01,$0a01,$0b01,-$0101

.slash	dc.w	$0402
	String	'Slashing'
	dc.w	$0004,$0101,$0201,$0301,$0201,$0301,$0201,$0301,$0201,$0301,-$0101

.trip	dc.w	$0402
	String	'Tripping'
	dc.w	$0004,$0401,$0501,$0401,$0501,$0401,$0501,$0401,$0501,-$0101

.rough2	dc.w	$0a02
	String	'Roughing'
	dc.w	$0004,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,-$0101

.rough	dc.w	$0402
	String	'Roughing'
	dc.w	$0004,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,-$0101

.hook	dc.w	$0402
	String	'Hooking'
	dc.w	$0004,$0101,$0901,$0801,$0901,$0801,$0901,$0801,$0901,$0801,-$0101

.cross	dc.w	$0402
	String	'Cross Check'
	dc.w	$0004,$0601,$0f01,$1001,$0f01,$1001,$0f01,$1001,$0f01,$1001,-$0101

.int	dc.w	$0402
	String	'Interference'
	dc.w	$0004,$0101,$0c06,-$0101

.hold	dc.w	$0402
	String	'Holding'
	dc.w	$0004,$0101,$0706,-$0101

.fight	dc.w	$2805
	String	'Fighting'
	dc.w	$0004,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,-$0101
.fight2	dc.w	$2805
	String	'Fighting *'
	dc.w	$0004,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,-$0101
.inst	dc.w	$2802
	String	'Fight Instigator'
	dc.w	$0004,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,-$0101

bfasciicon	;equates to find each char definition for bigfont.map. 92 bfasciicon, 93 values.
	;Indexed by ascii - $20 in printbig .dochar (middle93_2)
	;	 -  -!  "  #  $  %  &  -'  (  )  *  +  ,  -  -.  /
	dc.b	-76,-73,00,00,00,00,00,-71,00,00,00,00,00,00,-72,00
	;	 0   1  2  3  4  5  6  7  8  9   :  ;  <  =  >  ?
	dc.b	51,-53,54,56,58,60,62,64,66,68,-71,00,00,00,00,74
	;	@  A  B  C  D  E  F  G	H  -I  J  K  L  M  N  O
	dc.b	74,00,02,04,06,08,10,12,14,-16,17,19,21,23,25,27
	;	P  Q  R  S  T  U  V  W	X  Y  Z
	dc.b	29,31,33,35,37,39,41,43,45,47,49
	IF REV=0
	dc.b	$F0			;pad, retail byte (Rev A: 0)
	ELSE
	dc.b	0
	ENDIF

linelist	String	'Sc1'	;text list for line choices. 92 linelist (93 PP1/PP2, 92 Pw1/Pw2).
	;Used by SetLCmode2, puckfaceoff2 and stats93 DrawMenuIcon
	String	'Sc2'
	String	'Chk'
	String	'PP1'
	String	'PP2'
	String	'PK1'
	String	'PK2'

PlayerPositionText	;93 only: position names for the line slots. Used by stats93 DisplayPlayerList
	String	'LD'
	String	'RD'
	String	'LW'
	String	'C'
	String	'RW'

PerLabels	String	'1',18	;text list for periods. 92 PerLabels. Used by printscores1, NewTicker3 and
	;stats93 DisplayGameInfo
	String	'2',19
	String	'3',20
	String	'OT'
	String	'Final'

sizetab	;sprite size code to tile count. 92 video.asm sizetab, used by addframe2
	dc.b	1,2,3,4,2,4,6,8,3,6,9,12,4,8,12,16

sublist	;substitution lists by position (goalie, LD, RD, LW, C, RW, extra attacker). 92 sublist;
	;93 uses word offsets from sublist (92 long pointers). Used by SetPlList
	dc.w	.defl-sublist		;goalie
	dc.w	.defl-sublist
	dc.w	.defr-sublist
	dc.w	.wingl-sublist
	dc.w	.center-sublist
	dc.w	.wingr-sublist
	dc.w	.center-sublist

.defl	dc.b	0+1,8+1,16+1,24+1,32+1,40+1,48+1	;list of players in there lines/each line = 8 bytes
	dc.b	0+2,8+2,16+2,24+2,32+2,40+2,48+2
.defr	dc.b	0+2,8+2,16+2,24+2,32+2,40+2,48+2
	dc.b	0+1,8+1,16+1,24+1,32+1,40+1,48+1
.wingl	dc.b	0+3,8+3,16+3,24+3,32+3,40+3,48+3
	dc.b	0+5,8+5,16+5,24+5,32+5,40+5,48+5
	dc.b	0+4,8+4,16+4,24+4,32+4,40+4,48+4
.wingr	dc.b	0+5,8+5,16+5,24+5,32+5,40+5,48+5
	dc.b	0+3,8+3,16+3,24+3,32+3,40+3,48+3
	dc.b	0+4,8+4,16+4,24+4,32+4,40+4,48+4
.center	dc.b	0+4,8+4,16+4,24+4,32+4,40+4,48+4
	dc.b	0+3,8+3,16+3,24+3,32+3,40+3,48+3
	dc.b	0+5,8+5,16+5,24+5,32+5,40+5,48+5
	dc.b	-1

priolist	dc.b	0,1,2,4,3,5,6	;positions in order of importance. 92 priolist. Used by SetPlList,
	;releasepl and getlinee
	IF REV=0
	dc.b	$23			;pad, retail byte (Rev A: 0)
	ELSE
	dc.b	0
	ENDIF

PlayoffTreeSetup	;IDA: unk_15556. Playoff tree layout by gamelevel. 92 PlayoffScreen .setup, same layout
	;with 93 columns. Used by PlayoffScreen (hockey93_06)
	dc.w	.l0-PlayoffTreeSetup
	dc.w	.l1-PlayoffTreeSetup
	dc.w	.l2-PlayoffTreeSetup
	dc.w	.l3-PlayoffTreeSetup
	dc.w	.l4-PlayoffTreeSetup

	;tree graphics for level 0: teams-1 then x,y per team (DrawTeamBlocks), arrows-1 then x,d0 per
	;arrow (DrawPlayoffBracket), scores-1 then x,y per score (FormatScore, negative: none)
.l0	dc.b	16-1
	dc.b	45,2,45,5,45,8,45,11,45,14,45,17,45,20,45,23
	dc.b	71,2,71,5,71,8,71,11,71,14,71,17,71,20,71,23
	dc.b	1,57,0,69,10
	dc.b	7,50,4,50,10,50,16,50,22,75,4,75,10,75,16,75,22

	;tree graphics for level 1
.l1	dc.b	16+8-1
	dc.b	31,2,31,5,31,8,31,11,31,14,31,17,31,20,31,23
	dc.b	85,2,85,5,85,8,85,11,85,14,85,17,85,20,85,23
	dc.b	45,4,45,10,45,15,45,21
	dc.b	71,4,71,10,71,15,71,21
	dc.b	3,43,0,57,2,69,8,83,10
	dc.b	3,50,8,50,18,75,8,75,18

	;tree graphics for level 2
.l2	dc.b	16+8+4-1
	dc.b	17,2,17,5,17,8,17,11,17,14,17,17,17,20,17,23
	dc.b	99,2,99,5,99,8,99,11,99,14,99,17,99,20,99,23
	dc.b	31,4,31,10,31,15,31,21
	dc.b	85,4,85,10,85,15,85,21
	dc.b	45,7,45,18
	dc.b	71,7,71,18
	dc.b	5,29,0,43,2,57,4,69,6,83,8,97,10
	dc.b	1,50,13,75,13

	;tree graphics for level 3
.l3	dc.b	16+8+4+2-1
	dc.b	3,2,3,5,3,8,3,11,3,14,3,17,3,20,3,23
	dc.b	113,2,113,5,113,8,113,11,113,14,113,17,113,20,113,23
	dc.b	17,4,17,10,17,15,17,21
	dc.b	99,4,99,10,99,15,99,21
	dc.b	31,7,31,18
	dc.b	85,7,85,18
	dc.b	45,12
	dc.b	71,12
	dc.b	5,15,0,29,2,43,4,83,6,97,8,111,10
	dc.b	0,63,23

	;tree graphics for level 4
.l4	dc.b	16+8+4+2+1-1
	dc.b	3,2,3,5,3,8,3,11,3,14,3,17,3,20,3,23
	dc.b	113,2,113,5,113,8,113,11,113,14,113,17,113,20,113,23
	dc.b	17,4,17,10,17,15,17,21
	dc.b	99,4,99,10,99,15,99,21
	dc.b	31,7,31,18
	dc.b	85,7,85,18
	dc.b	45,12
	dc.b	71,12
	dc.b	58,23
	dc.b	5,15,0,29,2,43,4,83,6,97,8,111,10
	dc.b	-1			;no scores
	IF REV=0
	dc.b	$47			;pad, retail byte (Rev A: 0)
	ELSE
	dc.b	0
	ENDIF

PAttribColumns	;93 only: skater attribute columns for stats93 PrintAttribHeader / DisplayPlayerList.
	;String header, then a long for GetNameandAttrib: high word = mask of rating nibbles to
	;average, low word = attribjmp offset (0 status, 2 energy, 4 handed, 6 weight, 8 fighting,
	;$A rating). A negative word ends the list
	String	'     Status    ]'
	dc.w	$0000,0			;status
	String	'[   Overall    ]'
	dc.w	$1f3a,$a		;rating
	String	'[   Energy     ]'
	dc.w	$0000,2			;energy
	String	'[   Agility    ]'
	dc.w	$1000,$a
	String	'[    Speed     ]'
	dc.w	$0800,$a
	String	'[   Handed     ]'
	dc.w	$0040,4			;handed
	String	'[Off. Awareness]'
	dc.w	$0400,$a
	String	'[Def. Awareness]'
	dc.w	$0200,$a
	String	'[  Shot Power  ]'
	dc.w	$0100,$a
	String	'[Shot  Accuracy]'
	dc.w	$0010,$a
	String	'[Pass  Accuracy]'
	dc.w	$0002,$a
	String	'[Stick Handling]'
	dc.w	$0020,$a
	String	'[    Weight    ]'
	dc.w	$2000,6			;weight
	String	'[  Endurance   ]'
	dc.w	$0008,$a
	String	'[Aggressiveness]'
	dc.w	$0001,$a
	String	'[   Checking   ]'
	dc.w	$0080,$a
	String	'[   Fighting    '
	dc.w	$0040,8			;fighting
	dc.w	-1

GAttribColumns	;93 only: goalie attribute columns, same format as PAttribColumns. Used by
	;stats93 DisplayPlayerList
	String	'     Status    ]'
	dc.w	$0000,0			;status
	String	'[   Overall    ]'
	dc.w	$1b0f,$a		;rating
	String	'[   Agility    ]'
	dc.w	$1000,$a
	String	'[    Speed     ]'
	dc.w	$0800,$a
	String	'[  Glove Hand  ]'
	dc.w	$0040,4			;handed
	String	'[Def. Awareness]'
	dc.w	$0200,$a
	String	'[ Puck Control ]'
	dc.w	$0100,$a
	String	'[ Stick  Right ]'
	dc.w	$0008,$a
	String	'[  Stick Left  ]'
	dc.w	$0004,$a
	String	'[ Glove  Right ]'
	dc.w	$0002,$a
	String	'[  Glove Left  ]'
	dc.w	$0001,$a
	String	'[    Weight     '
	dc.w	$2000,6			;weight
	dc.w	-1

PauseText	;93 only: pause menu item list (Pausemode, hockey93_01)
	String	$FE,5
	String	$FE,4
	String	'   Resume Game    '
	dc.l	rtss
	String	'  Instant Replay  '
	dc.l	ReplayMode
	String	'  Change Goalie   '
	dc.l	SelectGoalieMenu
	String	'    Edit Lines    '
	dc.l	LineEditor
	String	'    Game Stats    '
	dc.l	GameStatisticsScreen
	String	'   Player Stats   '
	dc.l	PlayerStatsScreen
	String	' Scoring Summary  '
	dc.l	ScoringSummaryScreen
	String	' Penalty Summary  '
	dc.l	PenaltySummaryScreen
	String	'   Team Roster    '
	dc.l	TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores
	String	'   Crowd Meter    '
	dc.l	CrowdMeterScreen
	String	'     Timeout      '
	dc.l	TimeoutMenu
	String	$FF

PauseText2	;93 only: pause menu item list without Timeout, used when tmflags bit 2 of the pausing
	;team is set (Pausemode)
	String	$FE,5
	String	$FE,4
	String	'   Resume Game    '
	dc.l	rtss
	String	'  Instant Replay  '
	dc.l	ReplayMode
	String	'  Change Goalie   '
	dc.l	SelectGoalieMenu
	String	'    Edit Lines    '
	dc.l	LineEditor
	String	'    Game Stats    '
	dc.l	GameStatisticsScreen
	String	'   Player Stats   '
	dc.l	PlayerStatsScreen
	String	' Scoring Summary  '
	dc.l	ScoringSummaryScreen
	String	' Penalty Summary  '
	dc.l	PenaltySummaryScreen
	String	'   Team Roster    '
	dc.l	TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores
	String	'   Crowd Meter    '
	dc.l	CrowdMeterScreen
	String	$FF

StartGameText	;IDA: no label (Rev A $15B82). 93 only: Intermission menu for gsp 0 (penalty93_2 .sslist)
	String	$FE,5
	String	$FE,4
	String	'    Start Game    '
	dc.l	rtss
	String	'  Change Goalie   '
	dc.l	SelectGoalieMenu
	String	'    Edit Lines    '
	dc.l	LineEditor
	String	'   Team Roster    '
	dc.l	TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores
	String	$FF

StartGameTextPO	;IDA: no label (Rev A $15C06). 93 only: Intermission menu for gsp 0 in the playoffs
	;(penalty93_2 .sslist), adds Playoff Stats
	String	$FE,5
	String	$FE,4
	String	'    Start Game    '
	dc.l	rtss
	String	'  Change Goalie   '
	dc.l	SelectGoalieMenu
	String	'    Edit Lines    '
	dc.l	LineEditor
	String	'   Team Roster    '
	dc.l	TeamRosterScreen
	String	'  Playoff Stats   '
	dc.l	DisplayTeamStats
	String	'   Other Scores   '
	dc.l	ShowScores
	String	$FF

IntermissionText	;IDA: no label (Rev A $15CA2). 93 only: Intermission menu for gsp 1-3, season and
	;playoffs (penalty93_2 .sslist)
	String	$FE,5
	String	$FE,4
	String	'   Resume Game    '
	dc.l	rtss
	String	'    Game Stats    '
	dc.l	GameStatisticsScreen
	String	'   Player Stats   '
	dc.l	PlayerStatsScreen
	String	' Scoring Summary  '
	dc.l	ScoringSummaryScreen
	String	' Penalty Summary  '
	dc.l	PenaltySummaryScreen
	String	'   Team Roster    '
	dc.l	TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores
	String	'   Crowd Meter    '
	dc.l	CrowdMeterScreen
	String	'  Change Goalie   '
	dc.l	SelectGoalieMenu
	String	'    Edit Lines    '
	dc.l	LineEditor
	String	$FF

ExitGameText	;IDA: no label (Rev A $15D9E). 93 only: Intermission menu for gsp 4 (penalty93_2 .sslist).
	;IDA's PlayoffScreenText2 label inside the Team Roster string is not created
	String	$FE,5
	String	$FE,4
	String	'    Exit Game     '
	dc.l	rtss
	String	'    Game Stats    '
	dc.l	GameStatisticsScreen
	String	'   Player Stats   '
	dc.l	PlayerStatsScreen
	String	' Scoring Summary  '
	dc.l	ScoringSummaryScreen
	String	' Penalty Summary  '
	dc.l	PenaltySummaryScreen
	String	'   Team Roster    '
	dc.l	TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores
	String	'   Crowd Meter    '
	dc.l	CrowdMeterScreen
	String	$FF

ExitGameTextPO	;IDA: no label (Rev A $15E6A). 93 only: Intermission menu for gsp 4 in the playoffs
	;(penalty93_2 .sslist), same items as ExitGameText
	String	$FE,5
	String	$FE,4
	String	'    Exit Game     '
	dc.l	rtss
	String	'    Game Stats    '
	dc.l	GameStatisticsScreen
	String	'   Player Stats   '
	dc.l	PlayerStatsScreen
	String	' Scoring Summary  '
	dc.l	ScoringSummaryScreen
	String	' Penalty Summary  '
	dc.l	PenaltySummaryScreen
	String	'   Team Roster    '
	dc.l	TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores
	String	'   Crowd Meter    '
	dc.l	CrowdMeterScreen
	String	$FF

AttributeScreenText	;93 only: line editor exit menu (stats93 ExitAttributeScreen)
	String	$FE,6,$F9,1
	String	$FE,4,$F9,1
	String	'       Exit       '
	dc.l	rtss
	String	'Set Original lines'
	dc.l	InitTeamSructure+$10	;Rev A $1294A: the line copy loop of InitTeamSructure (hockey93_06)
	String	'  Save Team Line  '
	dc.l	EncodePlayerAttributes
	String	'  Load Team Line  '
	dc.l	DecodePlayerAttributes
	String	$FF

ExitAttribText	;93 only: line editor exit menu without Load Team Line (stats93 ExitAttributeScreen)
	String	$FE,6,$F9,1
	String	$FE,4,$F9,1
	String	'       Exit       '
	dc.l	rtss
	String	'Set Original lines'
	dc.l	InitTeamSructure+$10	;Rev A $1294A
	String	'  Save Team Line  '
	dc.l	EncodePlayerAttributes
	String	$FF
