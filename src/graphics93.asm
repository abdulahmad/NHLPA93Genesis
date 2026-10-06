;	graphics93.asm: retail $2EFA2-$7FB75, graphics data (92 hockey.asm incbins after part 3).
;	incbin only, no gap and no overlap. Each file is a slice of nhlpa93retail.bin written by
;	npm run extractassets (src/extractAssets93-1.1.js) into Extracted\Graphics and named after its label.
;	Labels are the NHL 92 names where 93 uses the data the same way, else the IDA name or a descriptive name.
;	SNASM symbols are case-insensitive, so the 92 spellings (FramerMap, SmallFontMap, ...) are the IDA names
;	the segments use. Other IDA / stub names the segments use are equates to the label, and the IDA
;	...Plus8 labels (and unk_7A2B8) point past a map's 8-byte header, so they are label+8, like 92 #IceRinkMap+8.
;	IDA unk_3574A (retail $3571C, inside IceRinkMap) and unk_44120 ($440F2, inside Spritetiles) are not
;	labels: their only references are the offset long at Sprites+4 and the string long #$44120 in showfaceoff.

GameSetUpMap		;retail $2EFA2-$2F0AF (270 bytes). 92 GameSetUpMap (IDA GameSetupMap); roster sprite tiles, AddTeamSpriteFrame
	incbin	..\Extracted\Graphics\GameSetUpMap.bin
	even
GameSetupMapPlus8	equ	GameSetUpMap+8	;retail $2EFAA
Title1Map		;retail $2F0B0-$31287 (8664 bytes). 92 Title1Map: TitleScreen backdrop
	incbin	..\Extracted\Graphics\Title1Map.bin
	even
Titlemap	equ	Title1Map	;IDA / stub name
Title2Map		;retail $31288-$31F0F (3208 bytes). 92 Title2Map: second TitleScreen bitmap (no IDA label; hockey93_07 loads #$31288)
	incbin	..\Extracted\Graphics\Title2Map.bin
	even
Title3Map		;retail $31F10-$322CD (958 bytes). IDA Title3map: the three TitleAnimCallback sprites (no 92 counterpart)
	incbin	..\Extracted\Graphics\Title3Map.bin
	even
Title3mapPlus8	equ	Title3Map+8	;retail $31F18
TitleLogoMap		;retail $322CE-$3285F (1426 bytes). IDA Titlemap2: the four title logo sprites (FinalizeSpriteList); palette reused by PlayoffScreen
	incbin	..\Extracted\Graphics\TitleLogoMap.bin
	even
Titlemap2	equ	TitleLogoMap	;IDA / stub name
Titlemap2Plus8	equ	TitleLogoMap+8	;retail $322D6
ScoutMap		;retail $32860-$33387 (2856 bytes). 92 ScoutMap (IDA unk_3288E): ScoutingReport background, also PlayoffScreen, SetupScreen, DrawTeamScreen
	incbin	..\Extracted\Graphics\ScoutMap.bin
	even
unk_3288E	equ	ScoutMap	;IDA / stub name
FramerMap		;retail $33388-$333FF (120 bytes). 92 FramerMap (IDA Framermap)
	incbin	..\Extracted\Graphics\FramerMap.bin
	even
FramermapPlus8	equ	FramerMap+8	;retail $33390
FaceOffMap		;retail $33400-$33863 (1124 bytes). 92 FaceOffMap
	incbin	..\Extracted\Graphics\FaceOffMap.bin
	even
IceRinkMap		;retail $33864-$38905 (20642 bytes). 92 IceRinkMap
	incbin	..\Extracted\Graphics\IceRinkMap.bin
	even
IceRinkMapPlus8	equ	IceRinkMap+8	;retail $3386C
RefsMap		;retail $38906-$39461 (2908 bytes). 92 RefsMap
	incbin	..\Extracted\Graphics\RefsMap.bin
	even
RefsMapPlus8	equ	RefsMap+8	;retail $3890E
RefMap2		;retail $39462-$3A377 (3862 bytes). IDA RefMap2: the horizontal ref (PushRef); no 92 counterpart
	incbin	..\Extracted\Graphics\RefMap2.bin
	even
RefMap2Plus8	equ	RefMap2+8	;retail $3946A
Sprites		;retail $3A378-$3A381 (10 bytes). 92 Sprites (Sprites.anim; IDA SpritesMap): $FFFFFFFF, then the offset to FrameDataOff
	incbin	..\Extracted\Graphics\Sprites.bin
	even
SpritesMap	equ	Sprites	;IDA / stub name
Spritetiles		;retail $3A382-$6FAC1 (218944 bytes). IDA Spritetiles: sprite tiles (92 Spritetiles was a RAM pointer to them)
	incbin	..\Extracted\Graphics\Spritetiles.bin
	even
FrameDataOff		;retail $6FAC2-$6FFD7 (1302 bytes). IDA FrameDataOff: frame offset table (= Sprites + the long at Sprites+4)
	incbin	..\Extracted\Graphics\FrameDataOff.bin
	even
SprDataBytes		;retail $6FFD8-$743CD (17398 bytes). IDA SprDataBytes: sprite frame data
	incbin	..\Extracted\Graphics\SprDataBytes.bin
	even
HotList		;retail $743CE-$748E1 (1300 bytes). IDA HotList: hot spot byte pairs per frame (GetHot)
	incbin	..\Extracted\Graphics\HotList.bin
	even
CrowdSprites		;retail $748E2-$7716F (10382 bytes). 92 CrowdSprites
	incbin	..\Extracted\Graphics\CrowdSprites.bin
	even
CrowdSpritesPlus8	equ	CrowdSprites+8	;retail $748EA
FaceOffSprites		;retail $77170-$781E3 (4212 bytes). 92 FaceOffSprites
	incbin	..\Extracted\Graphics\FaceOffSprites.bin
	even
FaceOffSpritesPlus8	equ	FaceOffSprites+8	;retail $77178
ZamSprites		;retail $781E4-$78CFD (2842 bytes). 92 ZamSprites
	incbin	..\Extracted\Graphics\ZamSprites.bin
	even
ZamSpritesPlus8	equ	ZamSprites+8	;retail $781EC
BigFontMap		;retail $78CFE-$795B3 (2230 bytes). 92 BigFontMap (IDA bigfontmap)
	incbin	..\Extracted\Graphics\BigFontMap.bin
	even
bigfontmapPlus8	equ	BigFontMap+8	;retail $78D06
SmallFontMap		;retail $795B4-$7A281 (3278 bytes). 92 SmallFontMap (IDA smallfontmap)
	incbin	..\Extracted\Graphics\SmallFontMap.bin
	even
smallfontmapPlus8	equ	SmallFontMap+8	;retail $795BC
EnergyBarMap		;retail $7A282-$7A375 (244 bytes). IDA unk_7A2B0: line energy bar frames drawn by linebar (92 dobar built the bar from font chars)
	incbin	..\Extracted\Graphics\EnergyBarMap.bin
	even
unk_7A2B0	equ	EnergyBarMap	;IDA / stub name
unk_7A2B8	equ	EnergyBarMap+8	;retail $7A28A
Teamblocksmap		;retail $7A376-$7C54D (8664 bytes). 92 Teamblocksmap (IDA TeamBlocksmap)
	incbin	..\Extracted\Graphics\Teamblocksmap.bin
	even
TeamBlocksmapPlus8	equ	Teamblocksmap+8	;retail $7A37E
Arrowsmap		;retail $7C54E-$7C7A9 (604 bytes). 92 Arrowsmap (IDA ArrowsMap)
	incbin	..\Extracted\Graphics\Arrowsmap.bin
	even
ArrowsMapPlus8	equ	Arrowsmap+8	;retail $7C556
EASNmap		;retail $7C7AA-$7C945 (412 bytes). 92 EASNmap
	incbin	..\Extracted\Graphics\EASNmap.bin
	even
EASNmapPlus8	equ	EASNmap+8	;retail $7C7B2
RonBarrMap		;retail $7C946-$7CF1D (1496 bytes). IDA Ronbarrmap: Ron Barr picture on the ScoutingReport (93 only)
	incbin	..\Extracted\Graphics\RonBarrMap.bin
	even
ScoresMap		;retail $7CF1E-$7D303 (998 bytes). IDA unk_7CF4C: bitmap under the title on the ShowScores "Scores" screen (93 only)
	incbin	..\Extracted\Graphics\ScoresMap.bin
	even
unk_7CF4C	equ	ScoresMap	;IDA / stub name
Stanleymap		;retail $7D304-$7F4F5 (8690 bytes). 92 Stanleymap (IDA StanleyMap): Stanley Cup sprites
	incbin	..\Extracted\Graphics\Stanleymap.bin
	even
StanleyMapPlus8	equ	Stanleymap+8	;retail $7D30C
EASNmap2		;retail $7F4F6-$7FB75 (1664 bytes). IDA EASNmap2: the five EASN bitmaps on the Stanley Cup screen (93 only)
	incbin	..\Extracted\Graphics\EASNmap2.bin
	even
EASNmap2Plus8	equ	EASNmap2+8	;retail $7F4FE
