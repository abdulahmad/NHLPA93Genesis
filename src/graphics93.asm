;	graphics93.asm: retail $2EFA2-$7FB75, graphics data (92 hockey.asm incbins after part 3).
;	incbin only, no gap and no overlap. Each file is a slice of nhlpa93retail.bin written by
;	npm run extractassets (src/extractAssets93-1.1.js) into Extracted\Graphics. Each slice starts at an IDA
;	or stub label (retail = Rev A - $2E) and is named after it; an unlabeled slice is named by its address.

GameSetupMap		;retail $2EFA2-$2EFA9 (8 bytes)
	incbin	..\Extracted\Graphics\GameSetupMap.bin
	even
GameSetupMapPlus8		;retail $2EFAA-$2F0AF (262 bytes)
	incbin	..\Extracted\Graphics\GameSetupMapPlus8.bin
	even
Titlemap		;retail $2F0B0-$31287 (8664 bytes)
	incbin	..\Extracted\Graphics\Titlemap.bin
	even
Gfx_31288		;retail $31288-$31F0F (3208 bytes), no IDA or stub label (Rev A $312B6); 92 Title2Map
	incbin	..\Extracted\Graphics\Gfx_31288.bin
	even
Title3map		;retail $31F10-$31F17 (8 bytes)
	incbin	..\Extracted\Graphics\Title3map.bin
	even
Title3mapPlus8		;retail $31F18-$322CD (950 bytes)
	incbin	..\Extracted\Graphics\Title3mapPlus8.bin
	even
Titlemap2		;retail $322CE-$322D5 (8 bytes)
	incbin	..\Extracted\Graphics\Titlemap2.bin
	even
Titlemap2Plus8		;retail $322D6-$3285F (1418 bytes)
	incbin	..\Extracted\Graphics\Titlemap2Plus8.bin
	even
unk_3288E		;retail $32860-$33387 (2856 bytes), stats93 stub name (IDA Rev A address)
	incbin	..\Extracted\Graphics\unk_3288E.bin
	even
Framermap		;retail $33388-$3338F (8 bytes)
	incbin	..\Extracted\Graphics\Framermap.bin
	even
FramermapPlus8		;retail $33390-$333FF (112 bytes)
	incbin	..\Extracted\Graphics\FramermapPlus8.bin
	even
FaceOffMap		;retail $33400-$33863 (1124 bytes)
	incbin	..\Extracted\Graphics\FaceOffMap.bin
	even
IceRinkMap		;retail $33864-$3386B (8 bytes)
	incbin	..\Extracted\Graphics\IceRinkMap.bin
	even
IceRinkMapPlus8		;retail $3386C-$3571B (7856 bytes)
	incbin	..\Extracted\Graphics\IceRinkMapPlus8.bin
	even
unk_3574A		;retail $3571C-$38905 (12778 bytes), IDA name (Rev A address)
	incbin	..\Extracted\Graphics\unk_3574A.bin
	even
RefsMap		;retail $38906-$3890D (8 bytes)
	incbin	..\Extracted\Graphics\RefsMap.bin
	even
RefsMapPlus8		;retail $3890E-$39461 (2900 bytes)
	incbin	..\Extracted\Graphics\RefsMapPlus8.bin
	even
RefMap2		;retail $39462-$39469 (8 bytes)
	incbin	..\Extracted\Graphics\RefMap2.bin
	even
RefMap2Plus8		;retail $3946A-$3A377 (3854 bytes)
	incbin	..\Extracted\Graphics\RefMap2Plus8.bin
	even
SpritesMap		;retail $3A378-$3A381 (10 bytes)
	incbin	..\Extracted\Graphics\SpritesMap.bin
	even
Spritetiles		;retail $3A382-$440F1 (40304 bytes)
	incbin	..\Extracted\Graphics\Spritetiles.bin
	even
unk_44120		;retail $440F2-$6FAC1 (178640 bytes), IDA name (Rev A address)
	incbin	..\Extracted\Graphics\unk_44120.bin
	even
FrameDataOff		;retail $6FAC2-$6FFD7 (1302 bytes)
	incbin	..\Extracted\Graphics\FrameDataOff.bin
	even
SprDataBytes		;retail $6FFD8-$743CD (17398 bytes)
	incbin	..\Extracted\Graphics\SprDataBytes.bin
	even
HotList		;retail $743CE-$748E1 (1300 bytes)
	incbin	..\Extracted\Graphics\HotList.bin
	even
CrowdSprites		;retail $748E2-$748E9 (8 bytes)
	incbin	..\Extracted\Graphics\CrowdSprites.bin
	even
CrowdSpritesPlus8		;retail $748EA-$7716F (10374 bytes)
	incbin	..\Extracted\Graphics\CrowdSpritesPlus8.bin
	even
FaceOffSprites		;retail $77170-$77177 (8 bytes)
	incbin	..\Extracted\Graphics\FaceOffSprites.bin
	even
FaceOffSpritesPlus8		;retail $77178-$781E3 (4204 bytes)
	incbin	..\Extracted\Graphics\FaceOffSpritesPlus8.bin
	even
ZamSprites		;retail $781E4-$781EB (8 bytes)
	incbin	..\Extracted\Graphics\ZamSprites.bin
	even
ZamSpritesPlus8		;retail $781EC-$78CFD (2834 bytes)
	incbin	..\Extracted\Graphics\ZamSpritesPlus8.bin
	even
bigfontmap		;retail $78CFE-$78D05 (8 bytes)
	incbin	..\Extracted\Graphics\bigfontmap.bin
	even
bigfontmapPlus8		;retail $78D06-$795B3 (2222 bytes)
	incbin	..\Extracted\Graphics\bigfontmapPlus8.bin
	even
smallfontmap		;retail $795B4-$795BB (8 bytes)
	incbin	..\Extracted\Graphics\smallfontmap.bin
	even
smallfontmapPlus8		;retail $795BC-$7A281 (3270 bytes)
	incbin	..\Extracted\Graphics\smallfontmapPlus8.bin
	even
unk_7A2B0		;retail $7A282-$7A289 (8 bytes), IDA name (Rev A address)
	incbin	..\Extracted\Graphics\unk_7A2B0.bin
	even
unk_7A2B8		;retail $7A28A-$7A375 (236 bytes), IDA name (Rev A address)
	incbin	..\Extracted\Graphics\unk_7A2B8.bin
	even
TeamBlocksmap		;retail $7A376-$7A37D (8 bytes)
	incbin	..\Extracted\Graphics\TeamBlocksmap.bin
	even
TeamBlocksmapPlus8		;retail $7A37E-$7C54D (8656 bytes)
	incbin	..\Extracted\Graphics\TeamBlocksmapPlus8.bin
	even
ArrowsMap		;retail $7C54E-$7C555 (8 bytes)
	incbin	..\Extracted\Graphics\ArrowsMap.bin
	even
ArrowsMapPlus8		;retail $7C556-$7C7A9 (596 bytes)
	incbin	..\Extracted\Graphics\ArrowsMapPlus8.bin
	even
EASNmap		;retail $7C7AA-$7C7B1 (8 bytes)
	incbin	..\Extracted\Graphics\EASNmap.bin
	even
EASNmapPlus8		;retail $7C7B2-$7C945 (404 bytes)
	incbin	..\Extracted\Graphics\EASNmapPlus8.bin
	even
Ronbarrmap		;retail $7C946-$7CF1D (1496 bytes)
	incbin	..\Extracted\Graphics\Ronbarrmap.bin
	even
unk_7CF4C		;retail $7CF1E-$7D303 (998 bytes), IDA name (Rev A address)
	incbin	..\Extracted\Graphics\unk_7CF4C.bin
	even
StanleyMap		;retail $7D304-$7D30B (8 bytes)
	incbin	..\Extracted\Graphics\StanleyMap.bin
	even
StanleyMapPlus8		;retail $7D30C-$7F4F5 (8682 bytes)
	incbin	..\Extracted\Graphics\StanleyMapPlus8.bin
	even
EASNmap2		;retail $7F4F6-$7F4FD (8 bytes)
	incbin	..\Extracted\Graphics\EASNmap2.bin
	even
EASNmap2Plus8		;retail $7F4FE-$7FB75 (1656 bytes)
	incbin	..\Extracted\Graphics\EASNmap2Plus8.bin
	even
