;	graphics93.asm: retail $2EFA2-$7FB75, graphics data (92 hockey.asm incbins after part 3).
;	incbin only, no gap and no overlap. Each file is a slice of nhlpa93retail.bin written by
;	npm run extractassets (src/extractAssets93-1.1.js) into Extracted\Graphics. Each slice starts at an IDA
;	or stub label (retail = Rev A - $2E) and is named after it; an unlabeled slice is named by its address.
;	The IDA ...Plus8 labels (and unk_7A2B8) point past a map's 8-byte header, so they are label+8
;	equates, like 92 #IceRinkMap+8, not separate slices.

GameSetupMap		;retail $2EFA2-$2F0AF (270 bytes)
	incbin	..\Extracted\Graphics\GameSetupMap.bin
	even
GameSetupMapPlus8	equ	GameSetupMap+8	;retail $2EFAA
Titlemap		;retail $2F0B0-$31287 (8664 bytes)
	incbin	..\Extracted\Graphics\Titlemap.bin
	even
Gfx_31288		;retail $31288-$31F0F (3208 bytes), no IDA or stub label (Rev A $312B6); 92 Title2Map
	incbin	..\Extracted\Graphics\Gfx_31288.bin
	even
Title3map		;retail $31F10-$322CD (958 bytes)
	incbin	..\Extracted\Graphics\Title3map.bin
	even
Title3mapPlus8	equ	Title3map+8	;retail $31F18
Titlemap2		;retail $322CE-$3285F (1426 bytes)
	incbin	..\Extracted\Graphics\Titlemap2.bin
	even
Titlemap2Plus8	equ	Titlemap2+8	;retail $322D6
unk_3288E		;retail $32860-$33387 (2856 bytes), stats93 stub name (IDA Rev A address)
	incbin	..\Extracted\Graphics\unk_3288E.bin
	even
Framermap		;retail $33388-$333FF (120 bytes)
	incbin	..\Extracted\Graphics\Framermap.bin
	even
FramermapPlus8	equ	Framermap+8	;retail $33390
FaceOffMap		;retail $33400-$33863 (1124 bytes)
	incbin	..\Extracted\Graphics\FaceOffMap.bin
	even
IceRinkMap		;retail $33864-$3571B (7864 bytes)
	incbin	..\Extracted\Graphics\IceRinkMap.bin
	even
IceRinkMapPlus8	equ	IceRinkMap+8	;retail $3386C
unk_3574A		;retail $3571C-$38905 (12778 bytes), IDA name (Rev A address)
	incbin	..\Extracted\Graphics\unk_3574A.bin
	even
RefsMap		;retail $38906-$39461 (2908 bytes)
	incbin	..\Extracted\Graphics\RefsMap.bin
	even
RefsMapPlus8	equ	RefsMap+8	;retail $3890E
RefMap2		;retail $39462-$3A377 (3862 bytes)
	incbin	..\Extracted\Graphics\RefMap2.bin
	even
RefMap2Plus8	equ	RefMap2+8	;retail $3946A
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
CrowdSprites		;retail $748E2-$7716F (10382 bytes)
	incbin	..\Extracted\Graphics\CrowdSprites.bin
	even
CrowdSpritesPlus8	equ	CrowdSprites+8	;retail $748EA
FaceOffSprites		;retail $77170-$781E3 (4212 bytes)
	incbin	..\Extracted\Graphics\FaceOffSprites.bin
	even
FaceOffSpritesPlus8	equ	FaceOffSprites+8	;retail $77178
ZamSprites		;retail $781E4-$78CFD (2842 bytes)
	incbin	..\Extracted\Graphics\ZamSprites.bin
	even
ZamSpritesPlus8	equ	ZamSprites+8	;retail $781EC
bigfontmap		;retail $78CFE-$795B3 (2230 bytes)
	incbin	..\Extracted\Graphics\bigfontmap.bin
	even
bigfontmapPlus8	equ	bigfontmap+8	;retail $78D06
smallfontmap		;retail $795B4-$7A281 (3278 bytes)
	incbin	..\Extracted\Graphics\smallfontmap.bin
	even
smallfontmapPlus8	equ	smallfontmap+8	;retail $795BC
unk_7A2B0		;retail $7A282-$7A375 (244 bytes), IDA name (Rev A address)
	incbin	..\Extracted\Graphics\unk_7A2B0.bin
	even
unk_7A2B8	equ	unk_7A2B0+8	;retail $7A28A
TeamBlocksmap		;retail $7A376-$7C54D (8664 bytes)
	incbin	..\Extracted\Graphics\TeamBlocksmap.bin
	even
TeamBlocksmapPlus8	equ	TeamBlocksmap+8	;retail $7A37E
ArrowsMap		;retail $7C54E-$7C7A9 (604 bytes)
	incbin	..\Extracted\Graphics\ArrowsMap.bin
	even
ArrowsMapPlus8	equ	ArrowsMap+8	;retail $7C556
EASNmap		;retail $7C7AA-$7C945 (412 bytes)
	incbin	..\Extracted\Graphics\EASNmap.bin
	even
EASNmapPlus8	equ	EASNmap+8	;retail $7C7B2
Ronbarrmap		;retail $7C946-$7CF1D (1496 bytes)
	incbin	..\Extracted\Graphics\Ronbarrmap.bin
	even
unk_7CF4C		;retail $7CF1E-$7D303 (998 bytes), IDA name (Rev A address)
	incbin	..\Extracted\Graphics\unk_7CF4C.bin
	even
StanleyMap		;retail $7D304-$7F4F5 (8690 bytes)
	incbin	..\Extracted\Graphics\StanleyMap.bin
	even
StanleyMapPlus8	equ	StanleyMap+8	;retail $7D30C
EASNmap2		;retail $7F4F6-$7FB75 (1664 bytes)
	incbin	..\Extracted\Graphics\EASNmap2.bin
	even
EASNmap2Plus8	equ	EASNmap2+8	;retail $7F4FE
