;	graphics93.asm:, graphics data (92 incbins after part 3).
;	incbin only, no gap and no overlap. Each file is a slice of nhlpa93retail.bin written by
;	npm run extractassets (src/extractAssets93-1.1.js) into Extracted\Graphics. Files use the NHL 92 names
;	where 93 has the same asset: <name>.map.jim for data drawn as a bitmap / tile map, <name>.anim for
;	sprite frames (SetSframe / addframe2). Labels are the 92 names (Map = bitmap, Sprites = sprite frames)
;	where 93 uses the data the same way, else a descriptive name. SNASM symbols are case-insensitive, so the
;92 spellings also match the A map's tiles start past its 8-byte header: the segments
;write that as label+8, like 92 #IceRinkMap+8 (the names). ($3571C) and
;	unk_44120 ($440F2) are not labels: their only references are the offset long at Sprites+4 and the
;	string long #$44120 in showfaceoff.

GameSetupSprites		;game setup roster sprites (AddTeamSpriteFrame SetSframe, tiles from +8). The 92 GameSetUpMap bitmap is $2E1FC
	incbin	..\Extracted\Graphics\GameSetup.anim
	even
Title1Map		;TitleScreen backdrop
	incbin	..\Extracted\Graphics\Title1.map.jim
	even
Title2Map		;second TitleScreen bitmap ( loads #$31288)
	incbin	..\Extracted\Graphics\Title2.map.jim
	even
Title3Sprites		;the three TitleAnimCallback sprites (SetSframe)
	incbin	..\Extracted\Graphics\Title3.anim
	even
TitleLogoSprites		;the four title logo sprites (FinalizeSpriteList SetSframe); palette reused by PlayoffScreen
	incbin	..\Extracted\Graphics\TitleLogo.anim
	even
ScoutMap		;ScoutingReport background, also PlayoffScreen, SetupScreen, DrawTeamScreen
	incbin	..\Extracted\Graphics\Scouting.map.jim
	even
FramerMap
	incbin	..\Extracted\Graphics\Framer.map.jim
	even
FaceOffMap
	incbin	..\Extracted\Graphics\FaceOff.map.jim
	even
IceRinkMap
	incbin	..\Extracted\Graphics\IceRink.map.jim
	even
RefsMap
	incbin	..\Extracted\Graphics\Refs.map.jim
	even
RefMap2		;the horizontal ref (PushRef); no 92 counterpart
	incbin	..\Extracted\Graphics\Refs2.map.jim
	even
Sprites		;$FFFFFFFF, long offset to FrameDataOff, then tiles
	incbin	..\Extracted\Graphics\Sprites.anim
	even
Spritetiles	equ	Sprites+$A	;sprite tiles (92 Spritetiles was a RAM pointer to them)
FrameDataOff	equ	Sprites+$3574A	;frame offset table (= Sprites + the long at Sprites+4)
SprDataBytes	equ	Sprites+$35C60	;8-byte sprite entries of each frame
HotList	equ	Sprites+$3A056	;hot spot byte pair per frame (GetHot; 92 framelist SprStrHot)
CrowdSprites
	incbin	..\Extracted\Graphics\Crowd.anim
	even
FaceOffSprites
	incbin	..\Extracted\Graphics\FaceOff.anim
	even
ZamSprites
	incbin	..\Extracted\Graphics\Zam.anim
	even
BigFontMap
	incbin	..\Extracted\Graphics\BigFont.map.jim
	even
SmallFontMap
	incbin	..\Extracted\Graphics\SmallFont.map.jim
	even
EnergyBarMap		;line energy bar frames drawn by linebar (92 dobar built the bar from font chars)
	incbin	..\Extracted\Graphics\EnergyBar.map.jim
	even
Teamblocksmap
	incbin	..\Extracted\Graphics\TeamBlocks.map.jim
	even
Arrowsmap
	incbin	..\Extracted\Graphics\Arrows.map.jim
	even
EASNmap
	incbin	..\Extracted\Graphics\EASN.map.jim
	even
RonBarrMap		;Ron Barr picture on the ScoutingReport
	incbin	..\Extracted\Graphics\RonBarr.map.jim
	even
ScoresMap		;bitmap under the title on the ShowScores "Scores" screen
	incbin	..\Extracted\Graphics\Scores.map.jim
	even
Stanleymap		;92 Stanley.map.jim was a bitmap; 93 draws the cup as sprites (UpdateStanleyCupAnimation SetSframe)
	incbin	..\Extracted\Graphics\Stanley.anim
	even
EASNmap2		;the five EASN bitmaps on the Stanley Cup screen
	incbin	..\Extracted\Graphics\EASN2.map.jim
	even
