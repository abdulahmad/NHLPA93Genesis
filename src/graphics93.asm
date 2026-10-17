;	Graphics data: the rink, sprites, fonts, screen maps and pictures, all incbin files from the extraction step.
;	The equates below name the tables inside the sprite data. The code that uses each block is named in its label comment.
;
;	In order: the setup, title and scouting screens (GameSetUpMap ... ScoutMap), the framer, faceoff, rink and
;	referee maps, the main Sprites block with its equates, then the crowd, faceoff and zamboni sprite files, the two
;	fonts, energy bar, team blocks, arrows, EASN logo, Ron Barr, Scores maps, Stanley Cup sprites and the five EASN bitmaps.
;
;	Files named .map.jim are tile maps: the longs at +0 and +4 are offsets to map data (used as adda.l (a0),a0 and
;	adda.l 4(a1),a1) and the compressed tiles start at +8 (DecompressGraphics*). Files named .anim are sprite frame
;	sets (see the Sprites entry below and the note in video93.asm). Each incbin is word aligned.

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
FramerMap		;Framer tiles and map (AddFramer, print93.asm, hockey93.asm, stats93.asm)
	incbin	..\Extracted\Graphics\Framer.map.jim
	even
FaceOffMap		;face off referee/players background map (logic93.asm checkfo setup)
	incbin	..\Extracted\Graphics\FaceOff.map.jim
	even
IceRinkMap		;rink tiles and map for game play (setupice, hockey93.asm)
	incbin	..\Extracted\Graphics\IceRink.map.jim
	even
RefsMap		;referee tiles and maps for the ref cameras (logic93.asm, penalty93.asm)
	incbin	..\Extracted\Graphics\Refs.map.jim
	even
RefMap2		;the horizontal ref (PushRef)
	incbin	..\Extracted\Graphics\Refs2.map.jim
	even
Sprites		;$FFFFFFFF, long offset to FrameDataOff, then tiles
	incbin	..\Extracted\Graphics\Sprites.anim
	even
Spritetiles	equ	Sprites+$A			;sprite tiles
FrameDataOff	equ	Sprites+$3574A	;frame offset table (= Sprites + the long at Sprites+4)
SprDataBytes	equ	Sprites+$35C60	;8-byte sprite entries of each frame
HotList	equ	Sprites+$3A056			;hot spot byte pair per frame
CrowdSprites		;crowd animation sprite frames (showcrowd in video93.asm)
	incbin	..\Extracted\Graphics\Crowd.anim
	even
FaceOffSprites		;face off sprite frames (checkfo2 in video93.asm, logic93.asm)
	incbin	..\Extracted\Graphics\FaceOff.anim
	even
ZamSprites		;zamboni sprite frames (video93.asm, penalty93.asm)
	incbin	..\Extracted\Graphics\Zam.anim
	even
BigFontMap		;big font tiles and map (BigFontChars; print93.asm, hockey93.asm)
	incbin	..\Extracted\Graphics\BigFont.map.jim
	even
SmallFontMap		;small font tiles and map (smallfontchars; AddSmallFont and the screens)
	incbin	..\Extracted\Graphics\SmallFont.map.jim
	even
EnergyBarMap		;line energy bar frames drawn by linebar
	incbin	..\Extracted\Graphics\EnergyBar.map.jim
	even
Teamblocksmap		;team block tiles and map (AddTeamBlock, hockey93.asm, print93.asm)
	incbin	..\Extracted\Graphics\TeamBlocks.map.jim
	even
Arrowsmap		;playoff tree arrow tiles (DrawTreeArrow in hockey93.asm)
	incbin	..\Extracted\Graphics\Arrows.map.jim
	even
EASNmap		;EASN logo tiles and map (setupEASNmap, DrawEASNMap)
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
