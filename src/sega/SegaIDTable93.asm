;	Sega ID header. The console reads this at $100 to find the cartridge's name, copyright,
;	serial number, checksum, supported controllers and memory ranges.
;
;	Rev A (v1.1, REV=1) differs from Rev 0 (v1.0, REV=0) in the release month, the upper case title,
;	the version number and the checksum, so each has its own copy of the header. Rev B (v1.2) is not built.

	org	$00000100

	IF REV=1
;	Rev A (v1.1)
	dc.b	'SEGA GENESIS    '		;$100	system type
	dc.b	'(C)T-50 1992.OCT'		;$110	copyright and release date (YYYY.MMM)
	dc.b	'NHLPA HOCKEY ''93'		;$120	domestic name (48 bytes)
	dc.b	'                '
	dc.b	'                '
	dc.b	'NHLPA HOCKEY ''93'		;$150	overseas name (48 bytes)
	dc.b	'                '
	dc.b	'                '
	dc.b	'GM T-50396 -01'		;$180	serial number: product and version (14 bytes)
	IF CHECKSUM=1
	dc.w	$FA57					;$18E	ROM checksum, patched in by the checksum tool
	ELSE
	dc.w	$0000					;$18E	ROM checksum (security check disabled)
	ENDIF
	ELSE
;	Rev 0 (v1.0)
	dc.b	'SEGA GENESIS    '		;$100	system type
	dc.b	'(C)T-50 1992.JUL'		;$110	copyright and release date (YYYY.MMM)
	dc.b	'NHLPA Hockey ''93'		;$120	domestic name (48 bytes)
	dc.b	'                '
	dc.b	'                '
	dc.b	'NHLPA Hockey ''93'		;$150	overseas name (48 bytes)
	dc.b	'                '
	dc.b	'                '
	dc.b	'GM T-50396 -00'		;$180	serial number: product and version (14 bytes)
	IF CHECKSUM=1
	dc.w	$2799					;$18E	ROM checksum, patched in by the checksum tool
	ELSE
	dc.w	$0000					;$18E	ROM checksum (security check disabled)
	ENDIF
	ENDIF
	dc.b	'J               '		;$190	supported devices: J = 3-button control pad
	dc.l	$00000000,$0007FFFF		;$1A0	ROM start and end address
	dc.l	$00FF0000,$00FFFFFF		;$1A8	RAM start and end address
	dc.b	'            '			;$1B0	external RAM info (unused, 12 bytes)
	dc.b	'            '			;$1BC	modem info (unused, 12 bytes)
	dc.b	'        '				;$1C8	reserved (40 bytes)
	dc.b	'                '
	dc.b	'                '
	dc.b	'U               '		;$1F0	region: U = USA
