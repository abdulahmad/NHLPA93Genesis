VBLANK:                                 ; DATA XREF: ROM:00000078↑o
                move.l  (vbint).w,-(sp)
                rts
; End of function VBLANK

Begin:                                  ; CODE XREF: Reset+10C↑j
                move    #$2700,sr
                movea.w #(Stack-M68K_RAM),sp
                movea.w #(VSCRLPM-M68K_RAM),a0

loc_6458:                               ; CODE XREF: Begin+12↓j
                clr.l   (a0)+
                cmpa.w  #$CDF4,a0
                blt.s   loc_6458
                move.w  (VDP_CTRL).l,d0
                andi.w  #1,d0
                move.w  d0,(music_global_tick_counter).w
                jsr     (SetupStanleyCupCelebrationScreen).l
                jsr     (BackupRAM_Read).l
                jsr     (DefaultMenus).l ; set default menu choices for beginning of game
                jsr     (orjoy).l
                jsr     (p_initialZ80).l
                jsr     (p_turnoff).l
                jsr     (p_music_vblank).l
                jmp     Opening
; End of function Begin

loc_649E:                               ; CODE XREF: PeriodOver+D0↓j
                bsr.w   Readjoy1
                cmp.b   #$E0,d3
                bne.w   StartGame
                move.w  #3,(word_FFCADE).w
StartGame:                              ; CODE XREF: ROM:000064A6↑j
                clr.b   (gmode).w
                cmpi.w  #1,(OptPen).w
                bne.w   loc_64C4
                bset    #5,(gmode).w

loc_64C4:                               ; CODE XREF: StartGame+A↑j
                cmpi.w  #1,(OptPlayMode).w
                ble.w   loc_64D2
                bsr.w   ClearShotData

loc_64D2:                               ; CODE XREF: StartGame+1A↑j
                jsr     (clearTeamStats).l
                clr.w   (ScoreSumbytes).w
                clr.w   (word_FFC3F4).w
                clr.w   (gsp).w
                clr.w   (ChkCnt).w
                bsr.w   InitTeamShots
                jsr     (InitScores).l
                jsr     (setupice).l
                jmp     _sp
; End of function StartGame

ClearShotData:                          ; CODE XREF: StartGame+1E↑p
                moveq   #$30,d0 ; '0'
                movea.w #(outputbuffer-M68K_RAM),a0

loc_6504:                               ; CODE XREF: ClearShotData+8↓j
                clr.w   (a0)+
                dbf     d0,loc_6504
                rts
; End of function ClearShotData

InitTeamShots:                          ; CODE XREF: StartGame+38↑p
                                        ; StartHL+8C↓p
                movea.w #(hmtmstruct-M68K_RAM),a2
                bsr.w   InitShotStruct
                adda.w  #$1A2,a2
; End of function InitTeamShots

InitShotStruct:                         ; CODE XREF: InitTeamShots+4↑p
                move.w  #6,$24(a2)
                moveq   #$32,d0 ; '2'

loc_6520:                               ; CODE XREF: InitShotStruct+10↓j
                move.w  #$FFFE,$66(a2,d0.w)
                subq.w  #2,d0
                bpl.s   loc_6520
                rts
; End of function InitShotStruct

ResetClock:                             ; CODE XREF: StartPer+10↓p
                                        ; PeriodOver:_sp↓p
                bsr.w   GetPeriodTime
                cmpi.w  #3,(gsp).w
                blt.w   loc_6546
                tst.w   (OptPlayMode).w
                bne.w   loc_6546
                move.w  #$258,d0

loc_6546:                               ; CODE XREF: ResetClock+A↑j
                                        ; ResetClock+12↑j
                move.w  d0,(gameclock).w
                move.w  d0,(PerTimeTotal).w
                move.w  d0,(word_FFB048).w
                asr.w   #1,d0
                bsr.w   randomd0
                sub.w   d0,(word_FFB048).w
                bset    #0,(gmode).w
                rts
; End of function ResetClock

GetPeriodTime:                          ; CODE XREF: ResetClock↑p
                                        ; setplayer+C2↓p ...
                move.w  (word_FFCADE).w,d0
                asl.w   #1,d0
                lea     PeriodTimeTable(pc),a0
                move.w  (a0,d0.w),d0
                rts
; End of function GetPeriodTime
PeriodTimeTable:dc.b   1                ; DATA XREF: GetPeriodTime+6↑o
                dc.b $2C ; ,
                dc.b   2
                dc.b $58 ; X
                dc.b   4
                dc.b $B0
                dc.b   0
                dc.b $1E
StartPer:                               ; CODE XREF: PeriodOver+6E↓j
                movea.w #(Stack-M68K_RAM),sp
                jsr     (p_turnoff).l
                jsr     (setupice).l
                bsr.s   ResetClock
                ori.w   #$F000,(PadControlBits).w
                st      (c1playernum).w
                st      (c2playernum).w
                movea.w #(puckx-M68K_RAM),a3
                clr.w   (fox).w
                clr.w   (foy).w
                move.l  #$1B,d0
                bsr.w   assreplace
                bset    #2,(sflags2).w
                bclr    #4,(sflags).w
                move.w  #$FFFF,(lastsfx).w
                move.l  #$FFFF0000,(ReplayBufferPtr).w
                move.w  (vcount).w,(oldvcount).w
                bsr.w   DoGameFrame
                bsr.w   DoGameFrame
                move.w  (gamelevel).w,d0
                asl.w   #4,d0
                move.w  d0,(CwdExciteLvl).w
                move.w  #$31,-(sp) ; '1'
                bsr.w   song
                cmpi.w  #2,(gsp).w
                bge.w   Gameloop
                bset    #7,(sflags3).w
; End of function StartPer

Gameloop:                               ; CODE XREF: StartPer+76↑j
                                        ; Gameloop+E↓j ...
                bsr.w   DoGameFrame
                bsr.w   demoread
                btst    #0,(sflags).w
                beq.s   Gameloop
                bsr.w   Pausemode
                bra.s   Gameloop
; End of function Gameloop

DoGameFrame:                            ; CODE XREF: StartPer+56↑p
                                        ; StartPer+5A↑p ...
                move.w  (vcount).w,d7
                sub.w   (oldvcount).w,d7
                beq.s   DoGameFrame
                move.w  (vcount).w,(oldvcount).w
                bsr.w   periodicevents
                bsr.w   updateplayers   ; apply velocity and check collisions
                bsr.w   checkwindow
                bsr.w   updatereplay
                jmp     setvideo
; End of function DoGameFrame

periodicevents:                         ; CODE XREF: DoGameFrame+10↑p
                jsr     (PenaltyManager).l
                bsr.w   updatecrowdf
                jsr     (updatesound).l
                bsr.w   clockcont
                btst    #7,(sflags).w
                bne.w   rtss2
                sub.w   d7,(lldisp).w
                bpl.w   rtss2
                addi.w  #$18,(lldisp).w
                bsr.w   ChkGoalies
                bsr.w   UpdateCwdExcite
                bsr.w   CheckPeriodEnd
                bsr.w   UpdateLineChange
                bsr.w   CheckInjury
                jmp     updatepwrplay
CheckInjury:                            ; CODE XREF: periodicevents+3C↑p
                subq.w  #1,(InjCntDown).w
                bne.w   rtss2
                jmp     loc_14D36
UpdateLineChange:                       ; CODE XREF: periodicevents+38↑p
                tst.w   (OptLine).w
                bne.w   locret_66C6
                movea.w #(hmtmstruct-M68K_RAM),a2
                bsr.w   loc_66A0
                lea     $1A2(a2),a2

loc_66A0:                               ; CODE XREF: periodicevents+60↑p
                moveq   #$32,d0 ; '2'

loc_66A2:                               ; CODE XREF: periodicevents+8C↓j
                cmpi.w  #$FFFE,$66(a2,d0.w)
                bne.w   loc_66C2
                addi.w  #9,$32(a2,d0.w)
                cmpi.w  #$1000,$32(a2,d0.w)
                blt.w   loc_66C2
                move.w  #$1000,$32(a2,d0.w)

loc_66C2:                               ; CODE XREF: periodicevents+70↑j
                                        ; periodicevents+80↑j
                subq.w  #2,d0
                bpl.s   loc_66A2

locret_66C6:                            ; CODE XREF: periodicevents+58↑j
                rts
; End of function periodicevents

CheckPeriodEnd:                         ; CODE XREF: periodicevents+34↑p
                cmpi.w  #2,(gsp).w
                bne.w   locret_66F4
                btst    #4,(gmode).w
                bne.w   locret_66F4
                move.w  (gameclock).w,d0
                cmp.w   (word_FFB048).w,d0
                bgt.w   locret_66F4
                st      (word_FFB048).w
                move.w  #$32,-(sp) ; '2'
                bsr.w   song

locret_66F4:                            ; CODE XREF: CheckPeriodEnd+6↑j
                                        ; CheckPeriodEnd+10↑j ...
                rts
; End of function CheckPeriodEnd

UpdateCwdExcite:                        ; CODE XREF: periodicevents+30↑p
                move.w  (CwdExciteLvl).w,d0
                cmp.w   (word_FFB8A4).w,d0
                bls.w   loc_6706
                move.w  d0,(word_FFB8A4).w

loc_6706:                               ; CODE XREF: UpdateCwdExcite+8↑j
                ext.l   d0
                add.l   d0,(dword_FFB8A8).w
                addq.w  #1,(word_FFB8A6).w
                subq.w  #1,(CwdExciteLvl).w
                bpl.w   locret_671C
                clr.w   (CwdExciteLvl).w

locret_671C:                            ; CODE XREF: UpdateCwdExcite+1E↑j
                rts
; End of function UpdateCwdExcite

updatecrowdf:                           ; CODE XREF: periodicevents+6↑p
                                        ; IntermissionLoop+1A↓p
                cmpi.w  #$15E,(crowdlevel).w
                blt.w   loc_672C
                subq.w  #3,(crowdlevel).w

loc_672C:                               ; CODE XREF: updatecrowdf+6↑j
                sub.w   d7,(crowdlevel).w
                bpl.w   updatecrowdf_0
                clr.w   (crowdlevel).w

updatecrowdf_0:                         ; CODE XREF: updatecrowdf+12↑j
                sub.w   d7,(word_FFB8A0).w
                bpl.w   updatecrowdf_cf
                move.w  (crowdlevel).w,d0
                lsr.w   #1,d0
                cmp.w   #$7F,d0
                bls.w   updatecrowdf_1
                moveq   #$7F,d0

updatecrowdf_1:                         ; CODE XREF: updatecrowdf+2C↑j
                andi.w  #$60,d0 ; '`'
                addq.w  #2,(crowdstep).w
                andi.w  #$1E,(crowdstep).w
                add.w   (crowdstep).w,d0
                movea.l #cd0,a0
                move.b  (a0,d0.w),(crowdframe+1).w
                clr.w   d1
                move.b  1(a0,d0.w),d1
                move.w  (VDP_CNTR).l,d2
                and.w   d1,d2
                add.w   d2,d1
                move.w  d1,(word_FFB8A0).w

updatecrowdf_cf:                        ; CODE XREF: updatecrowdf+1E↑j
                clr.b   (crowdframe).w
                cmpi.w  #$118,(crowdlevel).w
                bls.w   rtss2
                move.w  (VDP_CNTR).l,d0
                andi.w  #$7F,d0
                cmp.w   #$13,d0
                blt.w   rtss2
                cmp.w   #$19,d0
                bgt.w   rtss2
                move.b  d0,(crowdframe).w
                rts
; End of function updatecrowdf

clockcont:                              ; CODE XREF: periodicevents+10↑p
                btst    #0,(gmode).w
                bne.w   rtss2
                tst.w   (gameclock).w
                bne.w   rtss2
                move.w  #4,-(sp)
                bsr.w   sfx
                bsr.w   freezewindow

clockcont_0:                            ; CODE XREF: puckfaceoff+2E↓j
                movea.w #(puckx-M68K_RAM),a3
                move.l  #$18,d0
                bsr.w   assinsert
                cmpi.w  #2,(gsp).w
                blt.w   loc_68AA
                move.l  #7,d0
                movea.w #(SortCords-M68K_RAM),a3
                cmpi.w  #3,(gamelevel).w
                bne.w   _t3
                cmpi.w  #7,(bosgames).w
                beq.w   _sc
                moveq   #$10,d3
                mulu.w  (gamenum).w,d3
                movea.w #(gstruct-M68K_RAM),a0
                adda.w  d3,a0
                clr.w   d3
                btst    #0,$E(a0)
                beq.w   _nf
                eori.w  #2,d3

_nf:                                    ; CODE XREF: clockcont+68↑j
                move.w  (tmstructtmscore).w,d1
                sub.w   (tmstructtmscoretmsize).w,d1
                bpl.w   _ns1
                eori.w  #2,d3

_ns1:                                   ; CODE XREF: clockcont+78↑j
                cmpi.w  #3,4(a0,d3.w)
                bne.w   _t3

_sc:                                    ; CODE XREF: clockcont+50↑j
                move.l  #8,d0
                moveq   #$B,d2

_t0:                                    ; CODE XREF: clockcont+9C↓j
                bclr    #3,$62(a3)
                adda.w  #$80,a3
                dbf     d2,_t0
                movea.w #(SortCords-M68K_RAM),a3

_t3:                                    ; CODE XREF: clockcont+46↑j
                                        ; clockcont+86↑j
                moveq   #5,d2
                move.w  (tmstructtmscore).w,d1
                sub.w   (tmstructtmscoretmsize).w,d1
                beq.w   loc_68AA
                bpl.w   _t2
                adda.w  #$300,a3

_t2:                                    ; CODE XREF: clockcont+B2↑j
                                        ; clockcont+D0↓j
                tst.w   $34(a3)
                ble.w   _n2
                bsr.w   assinsert
                move.l  #7,d0

_n2:                                    ; CODE XREF: clockcont+BE↑j
                adda.w  #$80,a3
                dbf     d2,_t2

_n3:                                    ; CODE XREF: clockcont+108↓j
                jsr     (ClearPenaltyBuffer).l
                addi.w  #$3E8,(crowdlevel).w
                addi.w  #$28,(CwdExciteLvl).w ; '('
                bset    #0,(gmode).w
                bset    #6,(gmode).w
                move.w  #4,d0
                bra.w   AddPenalty2
loc_68AA:                               ; CODE XREF: clockcont+32↑j
                                        ; clockcont+AE↑j
                cmpi.w  #3,(gsp).w
                bne.w   _eop
                tst.w   (OptPlayMode).w
                beq.s   _n3

_eop:                                   ; CODE XREF: clockcont+100↑j
                move.w  #2,d0
                bra.w   AddPenalty2
; End of function clockcont