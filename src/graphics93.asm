;	Graphics data: the rink, the sprites, fonts, screen maps and pictures, all loaded from the
;	extracted graphics files. The equates below name the tables inside the sprite data.

GameSetUpMap	;game setup bitmap (setoptions)
	incbin	..\Extracted\Graphics\GameSetUp.map.jim	;game setup bitmap
	even

GameSetupSprites		;game setup roster sprites drawn with SetSframe by AddTeamSpriteFrame, tiles from +8
	incbin	..\Extracted\Graphics\GameSetup.anim
	even
Title1Map		;TitleScreen backdrop
	incbin	..\Extracted\Graphics\Title1.map.jim
	even
Title2Map		;second TitleScreen bitmap
	incbin	..\Extracted\Graphics\Title2.map.jim
	even
Title3Sprites		;the three TitleAnimCallback sprites
	incbin	..\Extracted\Graphics\Title3.anim
	even
TitleLogoSprites		;the four title logo sprites (AddTitleLogoSprites SetSframe); palette reused by PlayoffScreen
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
RefMap2		;the horizontal ref (PushRef)
	incbin	..\Extracted\Graphics\Refs2.map.jim
	even
Sprites		;$FFFFFFFF, long offset to FrameDataOff, then tiles
	incbin	..\Extracted\Graphics\Sprites.anim
	even
Spritetiles	equ	Sprites+$A	;sprite tiles
FrameDataOff	equ	Sprites+$3574A	;frame offset table (= Sprites + the long at Sprites+4)
SprDataBytes	equ	Sprites+$35C60	;8-byte sprite entries of each frame
HotList	equ	Sprites+$3A056	;hot spot byte pair per frame
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
EnergyBarMap		;line energy bar frames drawn by linebar
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
Stanleymap		;Stanley Cup sprites, drawn with SetSframe by UpdateStanleyCupAnimation (92 used a bitmap)
	incbin	..\Extracted\Graphics\Stanley.anim
	even
EASNmap2		;the five EASN bitmaps on the Stanley Cup screen
	incbin	..\Extracted\Graphics\EASN2.map.jim
	even
