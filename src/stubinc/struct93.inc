; ------------- struct93 -------------
; SortCords sort object fields (SCstruct bytes each). Same values as
; NHL92Genesis/src/ram.asm. Checked against the 93 puck equates in
; ram_addrs.inc: puckx = SortCords+14*SCstruct, pucky-puckx = Ypos,
; puckz-puckx = Zpos, puckvx-puckx = Xvel.
; The 93 team struct differs from 92 (tmsize $1A2, 92 $88; tmdata $1E,
; 92 $E), so tmsize and tmdata are not defined here. Use the number.
Xpos equ 0
attribute equ 4
frame equ 6
Ypos equ $14
Zpos equ $18
Xvel equ $28
pflags equ $62
pflags2 equ $63
SCstruct equ $80
; ----------------------------------
