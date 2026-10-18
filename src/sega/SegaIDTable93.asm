;	Sega ID header. The console reads this at $100 to find the cartridge's name, copyright,
;	serial number, checksum, supported controllers and memory ranges.
;
;	Rev A (v1.1, REV=1) differs from Rev 0 (v1.0, REV=0) in the release month, the upper case title,
;	the version number and the checksum, so each has its own copy of the header. Rev B (v1.2, REV=2) is
;	1993.FEB, with the mixed case title again, version -00 and country code UEJ.

	org	$00000100
;					Data No. Address	Description

	IF REV=2
;	Rev B (v1.2)
	dc.b	'SEGA GENESIS    '		; 01	$100	Sega Genesis ID (16 bytes)
	dc.b	'(C)T-50 1993.FEB'		; 02	$110	company ID / release date (YYYY.MMM) (16 bytes)
	dc.b	'NHLPA Hockey ''93'		; 03	$120	game title for Japanese market (48 bytes)
	dc.b	'                '		; 		$130
	dc.b	'                '		; 		$140
	dc.b	'NHLPA Hockey ''93'		; 04	$150	game title for US market (48 bytes)
	dc.b	'                '		; 		$160
	dc.b	'                '		; 		$170
	dc.b	'GM T-50396 -00'		; 05	$180	cartridge cat., product no., version no. (14 bytes)
	IF CHECKSUM=1
	dc.w	$86DB					; 06	$18E	check sum data (installed by checksum program) (2 bytes)
	ELSE
	dc.w	$0000					; 06	$18E	check sum data (installed by checksum program) (2 bytes)
	ENDIF
	ELSE
	IF REV=1
;	Rev A (v1.1)
	dc.b	'SEGA GENESIS    '		; 01	$100	Sega Genesis ID (16 bytes)
	dc.b	'(C)T-50 1992.OCT'		; 02	$110	company ID / release date (YYYY.MMM) (16 bytes)
	dc.b	'NHLPA HOCKEY ''93'		; 03	$120	game title for Japanese market (48 bytes)
	dc.b	'                '		; 		$130
	dc.b	'                '		; 		$140
	dc.b	'NHLPA HOCKEY ''93'		; 04	$150	game title for US market (48 bytes)
	dc.b	'                '		; 		$160
	dc.b	'                '		; 		$170
	dc.b	'GM T-50396 -01'		; 05	$180	cartridge cat., product no., version no. (14 bytes)
	IF CHECKSUM=1
	dc.w	$FA57					; 06	$18E	check sum data (installed by checksum program) (2 bytes)
	ELSE
	dc.w	$0000					; 06	$18E	check sum data (installed by checksum program) (2 bytes)
	ENDIF
	ELSE
;	Rev 0 (v1.0)
	dc.b	'SEGA GENESIS    '		; 01	$100	Sega Genesis ID (16 bytes)
	dc.b	'(C)T-50 1992.JUL'		; 02	$110	company ID / release date (YYYY.MMM) (16 bytes)
	dc.b	'NHLPA Hockey ''93'		; 03	$120	game title for Japanese market (48 bytes)
	dc.b	'                '		; 		$130
	dc.b	'                '		; 		$140
	dc.b	'NHLPA Hockey ''93'		; 04	$150	game title for US market (48 bytes)
	dc.b	'                '		; 		$160
	dc.b	'                '		; 		$170
	dc.b	'GM T-50396 -00'		; 05	$180	cartridge cat., product no., version no. (14 bytes)
	IF CHECKSUM=1
	dc.w	$2799					; 06	$18E	check sum data (installed by checksum program) (2 bytes)
	ELSE
	dc.w	$0000					; 06	$18E	check sum data (installed by checksum program) (2 bytes)
	ENDIF
	ENDIF
	ENDIF
	dc.b	'J               '		; 07	$190	I/O peripheral info. (J=Control Pad) (16 bytes)
	dc.l	$00000000,$0007FFFF		; 08	$1A0	cartridge size (start and end address) (8 bytes)
	dc.l	$00FF0000,$00FFFFFF		; 09	$1A8	RAM size (start and end address) (8 bytes)
	dc.b	'            '			; 10	$1B0	external RAM info. (12 bytes)
	dc.b	'            '			; 11	$1BC	modem info. (12 bytes)
	dc.b	'        '				; 12	$1C8	inhibit to use (40 bytes)
	dc.b	'                '		; 		$1D0
	dc.b	'                '		; 		$1E0
	IF REV=2
	dc.b	'UEJ             '		; 13	$1F0	country code for release (16 bytes)
	ELSE
	dc.b	'U               '		; 13	$1F0	country code for release (16 bytes)
	ENDIF
