const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');

// NHLPA 93 asset extractor: writes the retail ROM slices that the source incbins (team palettes in
// teamdata93.asm, sound and Z80 data in sound93.asm, graphics in graphics93.asm) into Extracted/.
// Run by npm run extractassets (and by every build). Slices are [start, end) retail addresses.
const assets = [
    { name: 'ASEh.pal', folder: 'Graphics/Pals', start: 0x388, end: 0x3A8 }, // ASE
    { name: 'ASEv.pal', folder: 'Graphics/Pals', start: 0x3A8, end: 0x3C8 },
    { name: 'ASWh.pal', folder: 'Graphics/Pals', start: 0x624, end: 0x644 }, // ASW
    { name: 'ASWv.pal', folder: 'Graphics/Pals', start: 0x644, end: 0x664 },
    { name: 'BOSh.pal', folder: 'Graphics/Pals', start: 0x8C4, end: 0x8E4 },
    { name: 'BOSv.pal', folder: 'Graphics/Pals', start: 0x8E4, end: 0x904 },
    { name: 'BUFh.pal', folder: 'Graphics/Pals', start: 0xB7C, end: 0xB9C },
    { name: 'BUFv.pal', folder: 'Graphics/Pals', start: 0xB9C, end: 0xBBC },
    { name: 'CGYh.pal', folder: 'Graphics/Pals', start: 0xE3E, end: 0xE5E },
    { name: 'CGYv.pal', folder: 'Graphics/Pals', start: 0xE5E, end: 0xE7E },
    { name: 'CHIh.pal', folder: 'Graphics/Pals', start: 0x10E4, end: 0x1104 },
    { name: 'CHIv.pal', folder: 'Graphics/Pals', start: 0x1104, end: 0x1124 },
    { name: 'DETh.pal', folder: 'Graphics/Pals', start: 0x13A4, end: 0x13C4 },
    { name: 'DETv.pal', folder: 'Graphics/Pals', start: 0x13C4, end: 0x13E4 },
    { name: 'EDMh.pal', folder: 'Graphics/Pals', start: 0x165C, end: 0x167C },
    { name: 'EDMv.pal', folder: 'Graphics/Pals', start: 0x167C, end: 0x169C },
    { name: 'HFDh.pal', folder: 'Graphics/Pals', start: 0x190A, end: 0x192A },
    { name: 'HFDv.pal', folder: 'Graphics/Pals', start: 0x192A, end: 0x194A },
    { name: 'LAh.pal', folder: 'Graphics/Pals', start: 0x1BBE, end: 0x1BDE },
    { name: 'LAv.pal', folder: 'Graphics/Pals', start: 0x1BDE, end: 0x1BFE },
    { name: 'LIh.pal', folder: 'Graphics/Pals', start: 0x1E88, end: 0x1EA8 }, // LI
    { name: 'LIv.pal', folder: 'Graphics/Pals', start: 0x1EA8, end: 0x1EC8 },
    { name: 'MINh.pal', folder: 'Graphics/Pals', start: 0x2134, end: 0x2154 },
    { name: 'MINv.pal', folder: 'Graphics/Pals', start: 0x2154, end: 0x2174 },
    { name: 'MTLh.pal', folder: 'Graphics/Pals', start: 0x23D6, end: 0x23F6 },
    { name: 'MTLv.pal', folder: 'Graphics/Pals', start: 0x23F6, end: 0x2416 },
    { name: 'NJh.pal', folder: 'Graphics/Pals', start: 0x26AE, end: 0x26CE },
    { name: 'NJv.pal', folder: 'Graphics/Pals', start: 0x26CE, end: 0x26EE },
    { name: 'NYh.pal', folder: 'Graphics/Pals', start: 0x2966, end: 0x2986 },
    { name: 'NYv.pal', folder: 'Graphics/Pals', start: 0x2986, end: 0x29A6 },
    { name: 'OTWh.pal', folder: 'Graphics/Pals', start: 0x2C2E, end: 0x2C4E }, // OTT
    { name: 'OTWv.pal', folder: 'Graphics/Pals', start: 0x2C4E, end: 0x2C6E },
    { name: 'PHIh.pal', folder: 'Graphics/Pals', start: 0x2E4C, end: 0x2E6C },
    { name: 'PHIv.pal', folder: 'Graphics/Pals', start: 0x2E6C, end: 0x2E8C },
    { name: 'PITh.pal', folder: 'Graphics/Pals', start: 0x3108, end: 0x3128 },
    { name: 'PITv.pal', folder: 'Graphics/Pals', start: 0x3128, end: 0x3148 },
    { name: 'QUEh.pal', folder: 'Graphics/Pals', start: 0x33AC, end: 0x33CC },
    { name: 'QUEv.pal', folder: 'Graphics/Pals', start: 0x33CC, end: 0x33EC },
    { name: 'SJh.pal', folder: 'Graphics/Pals', start: 0x3686, end: 0x36A6 },
    { name: 'SJv.pal', folder: 'Graphics/Pals', start: 0x36A6, end: 0x36C6 },
    { name: 'STLh.pal', folder: 'Graphics/Pals', start: 0x3940, end: 0x3960 },
    { name: 'STLv.pal', folder: 'Graphics/Pals', start: 0x3960, end: 0x3980 },
    { name: 'TBYh.pal', folder: 'Graphics/Pals', start: 0x3BF6, end: 0x3C16 }, // TB
    { name: 'TBYv.pal', folder: 'Graphics/Pals', start: 0x3C16, end: 0x3C36 },
    { name: 'TORh.pal', folder: 'Graphics/Pals', start: 0x3E34, end: 0x3E54 },
    { name: 'TORv.pal', folder: 'Graphics/Pals', start: 0x3E54, end: 0x3E74 },
    { name: 'VANh.pal', folder: 'Graphics/Pals', start: 0x40EE, end: 0x410E },
    { name: 'VANv.pal', folder: 'Graphics/Pals', start: 0x410E, end: 0x412E },
    { name: 'WPGh.pal', folder: 'Graphics/Pals', start: 0x43A8, end: 0x43C8 },
    { name: 'WPGv.pal', folder: 'Graphics/Pals', start: 0x43C8, end: 0x43E8 },
    { name: 'WSHh.pal', folder: 'Graphics/Pals', start: 0x4666, end: 0x4686 },
    { name: 'WSHv.pal', folder: 'Graphics/Pals', start: 0x4686, end: 0x46A6 },
    // Sound and graphics data: contiguous retail slices (end is exclusive) for the incbins in src/sound93.asm
    // ($16E53-$2E1FB) and src/graphics93.asm ($2E1FC-$7FB75). Names follow the NHL 92 extractor where 93 has the
    // same asset (z80_snd_drv, sfx_*_pcm, sfx_*_cmdstream, <name>.map.jim for bitmaps, <name>.anim for sprite frames).
    // Sound boundaries come from the tables the 68k driver reads (pcm_sample_table, fm_instrument_patches,
    // MusicTrackPointerTable; each event stream runs to the next one). Sound names are from the sfx / song call sites.
    // Absolute addresses (PCM sample table, song loop pointers, the Z80 FM patch bank address) and pad bytes are
    // source in sound93.asm, not slices, so the data relocates for Rev A.
    { name: 'z80_snd_drv93.bin', folder: 'Sound', start: 0x016E53, end: 0x0170CA }, // 93 Z80 driver after its first byte ($16E52 is Z80_Program_Code dc.b $18), up to the ld bc of the FM patch bank address. p_initialZ80 copies $295 bytes from $16E52
    { name: 'z80_snd_drv93_end.bin', folder: 'Sound', start: 0x0170CF, end: 0x0170DD }, // rest of the 93 Z80 driver
    { name: 'sfx_shotbh_pcm.bin', folder: 'Sound', start: 0x017156, end: 0x01734A }, // sample 2: shotbh
    { name: 'sfx_pass_pcm.bin', folder: 'Sound', start: 0x01734A, end: 0x018077 }, // sample 1: pass
    { name: 'sfx_oooh_pcm.bin', folder: 'Sound', start: 0x018078, end: 0x01B2BC }, // sample 12: oooh, sfx_oooh2, sfx_bglass
    { name: 'sfx_crowdboo_pcm.bin', folder: 'Sound', start: 0x01B2BC, end: 0x01D809 }, // sample 11: crowdboo
    { name: 'sfx_check_pcm.bin', folder: 'Sound', start: 0x01D80A, end: 0x01F75C }, // sample 5: check1, check3
    { name: 'sfx_crowdcheer_pcm.bin', folder: 'Sound', start: 0x01F75C, end: 0x02263C }, // sample 13: crowdcheer, homewin
    { name: 'sfx_bglass_pcm.bin', folder: 'Sound', start: 0x02263C, end: 0x0260BB }, // sample 14: sfx_bglass
    { name: 'sfx_playerwall_pcm.bin', folder: 'Sound', start: 0x0260BC, end: 0x02656C }, // sample 6: playerwall, sfx_playerwall2-23
    { name: 'sfx_check2_pcm.bin', folder: 'Sound', start: 0x02656C, end: 0x026F9B }, // sample 4: check2, check4
    { name: 'sfx_hithigh_pcm.bin', folder: 'Sound', start: 0x026F9C, end: 0x0274F2 }, // samples 7 and 10: hithigh, hitlow, check1-4, songs $32 and $35-$37
    { name: 'sfx_shotfh_pcm.bin', folder: 'Sound', start: 0x0274F2, end: 0x0280AA }, // sample 3: shotfh
    { name: 'sfx_puckget_pcm.bin', folder: 'Sound', start: 0x0280AA, end: 0x02830A }, // sample 0: puckget
    { name: 'fm_instrument_patches.bin', folder: 'Sound', start: 0x02830A, end: 0x02870A }, // 32 FM patches x 32 bytes (byte $1E = pitch bend scale)
    { name: 'sfx_beep1_cmdstream.bin', folder: 'Sound', start: 0x02877A, end: 0x028786 }, // sound 1 (SFXbeep1)
    { name: 'sfx_id_26_27_cmdstream.bin', folder: 'Sound', start: 0x028786, end: 0x02878A }, // sounds $26 and $27: empty stream
    { name: 'sfx_beep2_cmdstream.bin', folder: 'Sound', start: 0x02878A, end: 0x02879A }, // sound 2 (SFXbeep2)
    { name: 'sfx_horn_cmdstream.bin', folder: 'Sound', start: 0x02879A, end: 0x028816 }, // sound 4 (92 SFXhorn)
    { name: 'sfx_stdef_cmdstream.bin', folder: 'Sound', start: 0x028816, end: 0x028832 }, // sound 6 (92 SFXstdef)
    { name: 'sfx_puckget_cmdstream.bin', folder: 'Sound', start: 0x028832, end: 0x02884E }, // sound 7 (92 SFXpuckget), puckglue
    { name: 'sfx_puckice1_cmdstream.bin', folder: 'Sound', start: 0x02884E, end: 0x02885E }, // sound $2C: puck bounce by speed (92 SFXpuckice)
    { name: 'sfx_puckice2_cmdstream.bin', folder: 'Sound', start: 0x02885E, end: 0x02886E }, // sound $2D
    { name: 'sfx_puckice3_cmdstream.bin', folder: 'Sound', start: 0x02886E, end: 0x02887E }, // sound $2E
    { name: 'sfx_puckice4_cmdstream.bin', folder: 'Sound', start: 0x02887E, end: 0x02888E }, // sound $2F (SFXpuckice, Endfaceoff)
    { name: 'sfx_puckbody_cmdstream.bin', folder: 'Sound', start: 0x02888E, end: 0x0288AA }, // sound $24 (92 SFXpuckbody)
    { name: 'sfx_oooh_cmdstream.bin', folder: 'Sound', start: 0x0288AA, end: 0x0288C6 }, // sound 8 (92 SFXoooh), off the post with the clock running
    { name: 'sfx_puckpost_cmdstream.bin', folder: 'Sound', start: 0x0288C6, end: 0x0288D6 }, // sound $25 (92 SFXpuckpost)
    { name: 'sfx_playerwall_cmdstream.bin', folder: 'Sound', start: 0x0288D6, end: 0x0288F2 }, // sound $20 (92 SFXplayerwall)
    { name: 'sfx_playerwall2_cmdstream.bin', folder: 'Sound', start: 0x0288F2, end: 0x02890E }, // sound $21: no caller found, same patches as playerwall
    { name: 'sfx_playerwall3_cmdstream.bin', folder: 'Sound', start: 0x02890E, end: 0x02892A }, // sound $22: no caller found, same patches as playerwall
    { name: 'sfx_playerwall4_cmdstream.bin', folder: 'Sound', start: 0x02892A, end: 0x028946 }, // sound $23: no caller found, same patches as playerwall
    { name: 'sfx_puckwall1_cmdstream.bin', folder: 'Sound', start: 0x028946, end: 0x028956 }, // sound $28: puck off the wall by speed (wallcoll; 92 SFXpuckwall)
    { name: 'sfx_puckwall2_cmdstream.bin', folder: 'Sound', start: 0x028956, end: 0x028966 }, // sound $29
    { name: 'sfx_puckwall3_cmdstream.bin', folder: 'Sound', start: 0x028966, end: 0x028976 }, // sound $2A
    { name: 'sfx_puckwall4_cmdstream.bin', folder: 'Sound', start: 0x028976, end: 0x028986 }, // sound $2B
    { name: 'sfx_whistle_cmdstream.bin', folder: 'Sound', start: 0x028986, end: 0x028A24 }, // sound 3 (92 SFXwhistle)
    { name: 'sfx_shotwiff_cmdstream.bin', folder: 'Sound', start: 0x028A24, end: 0x028A34 }, // sound 5 (92 SFXshotwiff)
    { name: 'sfx_check1_cmdstream.bin', folder: 'Sound', start: 0x028A34, end: 0x028A50 }, // sound $1C: tackle sounds in turn (92 SFXcheck)
    { name: 'sfx_check2_cmdstream.bin', folder: 'Sound', start: 0x028A50, end: 0x028A6C }, // sound $1D
    { name: 'sfx_check3_cmdstream.bin', folder: 'Sound', start: 0x028A6C, end: 0x028A88 }, // sound $1E
    { name: 'sfx_check4_cmdstream.bin', folder: 'Sound', start: 0x028A88, end: 0x028AAC }, // sound $1F
    { name: 'sfx_pass1_cmdstream.bin', folder: 'Sound', start: 0x028AAC, end: 0x028ABC }, // sound $10: pass by puck height (92 SFXpass)
    { name: 'sfx_pass2_cmdstream.bin', folder: 'Sound', start: 0x028ABC, end: 0x028ACC }, // sound $11
    { name: 'sfx_pass3_cmdstream.bin', folder: 'Sound', start: 0x028ACC, end: 0x028ADC }, // sound $12
    { name: 'sfx_pass4_cmdstream.bin', folder: 'Sound', start: 0x028ADC, end: 0x028AEC }, // sound $13
    { name: 'sfx_shotbh1_cmdstream.bin', folder: 'Sound', start: 0x028AEC, end: 0x028AFC }, // sound $14: backhand shot by speed (92 SFXshotbh)
    { name: 'sfx_shotbh2_cmdstream.bin', folder: 'Sound', start: 0x028AFC, end: 0x028B0C }, // sound $15
    { name: 'sfx_shotbh3_cmdstream.bin', folder: 'Sound', start: 0x028B0C, end: 0x028B1C }, // sound $16
    { name: 'sfx_shotbh4_cmdstream.bin', folder: 'Sound', start: 0x028B1C, end: 0x028B2C }, // sound $17
    { name: 'sfx_shotfh1_cmdstream.bin', folder: 'Sound', start: 0x028B2C, end: 0x028B3C }, // sound $18: forehand shot by speed (92 SFXshotfh)
    { name: 'sfx_shotfh2_cmdstream.bin', folder: 'Sound', start: 0x028B3C, end: 0x028B4C }, // sound $19
    { name: 'sfx_shotfh3_cmdstream.bin', folder: 'Sound', start: 0x028B4C, end: 0x028B5C }, // sound $1A
    { name: 'sfx_shotfh4_cmdstream.bin', folder: 'Sound', start: 0x028B5C, end: 0x028B6C }, // sound $1B
    { name: 'sfx_hithigh_cmdstream.bin', folder: 'Sound', start: 0x028B6C, end: 0x028B7C }, // sound 9 (SFXhithigh)
    { name: 'sfx_hitlow_cmdstream.bin', folder: 'Sound', start: 0x028B7C, end: 0x028B8C }, // sound $A (SFXhitlow)
    { name: 'sfx_homewin_cmdstream.bin', folder: 'Sound', start: 0x028B8C, end: 0x028BC4 }, // sound $F: home team won (game end)
    { name: 'sfx_crowdcheer_cmdstream.bin', folder: 'Sound', start: 0x028BC4, end: 0x028BD4 }, // sound $B (SFXcrowdcheer)
    { name: 'sfx_crowdboo_cmdstream.bin', folder: 'Sound', start: 0x028BD4, end: 0x028BE4 }, // sound $C (SFXcrowdboo)
    { name: 'sfx_bglass_cmdstream.bin', folder: 'Sound', start: 0x028BE4, end: 0x028C00 }, // sound $E: wallcollb (puck over the wall)
    { name: 'sfx_oooh2_cmdstream.bin', folder: 'Sound', start: 0x028C00, end: 0x028C10 }, // sound $D: injury (setInjuryType), visiting goalie save
    { name: 'sfx_siren_cmdstream.bin', folder: 'Sound', start: 0x028C10, end: 0x028E38 }, // sound 0 (92 SFXsiren)
    { name: 'fmtune_goal_cmdstream.bin', folder: 'Sound', start: 0x028E38, end: 0x02910C }, // song $30: Goal
    { name: 'fmtune_periodstart_cmdstream.bin', folder: 'Sound', start: 0x02910C, end: 0x0292DC }, // song $31: StartPer
    { name: 'fmtune_lategame_cmdstream.bin', folder: 'Sound', start: 0x0292DC, end: 0x029660 }, // song $32: CheckLateGameSong, 3rd period
    { name: 'fmtune_powerplay_cmdstream.bin', folder: 'Sound', start: 0x029660, end: 0x029904 }, // song $33: updatepwrplay, home power play
    { name: 'fmtune_faceoff_cmdstream.bin', folder: 'Sound', start: 0x029904, end: 0x029BE4 }, // song $34: puckfaceoff
    { name: 'fmtune_title_cmdstream.bin', folder: 'Sound', start: 0x029BE4, end: 0x029C42 }, // song $35: TitleScreen, ExitToOpening (92 SngTitle)
    { name: 'fmtune_title_loop_cmdstream.bin', folder: 'Sound', start: 0x029C46, end: 0x02AF60 }, // song $35 loop body
    { name: 'fmtune_eop_cmdstream.bin', folder: 'Sound', start: 0x02AF64, end: 0x02C8A6 }, // song $36: IntermissionStart, PlayoffScreen, StartHL2 (92 SngEOG / SngPO)
    { name: 'fmtune_scouting_cmdstream.bin', folder: 'Sound', start: 0x02C8AA, end: 0x02CEC4 }, // song $37: ScoutingReport
    { name: 'ScoutingReportText.bin', folder: 'Text', start: 0x02CEC8, end: 0x02E1FB }, // ScoutingReportText: scouting report paragraphs
    { name: 'GameSetUp.map.jim', folder: 'Graphics', start: 0x02E1FC, end: 0x02EFA2 }, // 92 GameSetUp.map.jim: game setup bitmap (setoptions movea.l #$2E1FC)
    { name: 'GameSetup.anim', folder: 'Graphics', start: 0x02EFA2, end: 0x02F0B0 }, // GameSetupSprites: game setup roster sprites (AddTeamSpriteFrame SetSframe, tiles from +8).
    { name: 'Title1.map.jim', folder: 'Graphics', start: 0x02F0B0, end: 0x031288 }, // Title1Map: 92 Title1Map: TitleScreen backdrop
    { name: 'Title2.map.jim', folder: 'Graphics', start: 0x031288, end: 0x031F10 }, // Title2Map: 92 Title2Map: second TitleScreen bitmap (loaded by TitleScreen)
    { name: 'Title3.anim', folder: 'Graphics', start: 0x031F10, end: 0x0322CE }, // Title3Sprites: the three TitleAnimCallback sprites (SetSframe)
    { name: 'TitleLogo.anim', folder: 'Graphics', start: 0x0322CE, end: 0x032860 }, // TitleLogoSprites: the four title logo sprites (FinalizeSpriteList SetSframe); palette reused by PlayoffScreen
    { name: 'Scouting.map.jim', folder: 'Graphics', start: 0x032860, end: 0x033388 }, // ScoutMap: 92 ScoutMap: ScoutingReport background, also PlayoffScreen, SetupScreen, DrawTeamScreen
    { name: 'Framer.map.jim', folder: 'Graphics', start: 0x033388, end: 0x033400 }, // FramerMap: 92 FramerMap
    { name: 'FaceOff.map.jim', folder: 'Graphics', start: 0x033400, end: 0x033864 }, // FaceOffMap: 92 FaceOffMap
    { name: 'IceRink.map.jim', folder: 'Graphics', start: 0x033864, end: 0x038906 }, // IceRinkMap: 92 IceRinkMap
    { name: 'Refs.map.jim', folder: 'Graphics', start: 0x038906, end: 0x039462 }, // RefsMap: 92 RefsMap
    { name: 'Refs2.map.jim', folder: 'Graphics', start: 0x039462, end: 0x03A378 }, // RefMap2: the horizontal ref (PushRef); no 92 counterpart
    { name: 'Sprites.anim', folder: 'Graphics', start: 0x03A378, end: 0x0748E2 }, // Sprites: 92 Sprites: $FFFFFFFF, long offset to FrameDataOff, then tiles
    { name: 'Crowd.anim', folder: 'Graphics', start: 0x0748E2, end: 0x077170 }, // CrowdSprites: 92 CrowdSprites
    { name: 'FaceOff.anim', folder: 'Graphics', start: 0x077170, end: 0x0781E4 }, // FaceOffSprites: 92 FaceOffSprites
    { name: 'Zam.anim', folder: 'Graphics', start: 0x0781E4, end: 0x078CFE }, // ZamSprites: 92 ZamSprites
    { name: 'BigFont.map.jim', folder: 'Graphics', start: 0x078CFE, end: 0x0795B4 }, // BigFontMap: 92 BigFontMap
    { name: 'SmallFont.map.jim', folder: 'Graphics', start: 0x0795B4, end: 0x07A282 }, // SmallFontMap: 92 SmallFontMap
    { name: 'EnergyBar.map.jim', folder: 'Graphics', start: 0x07A282, end: 0x07A376 }, // EnergyBarMap: line energy bar frames drawn by linebar (92 dobar built the bar from font chars)
    { name: 'TeamBlocks.map.jim', folder: 'Graphics', start: 0x07A376, end: 0x07C54E }, // Teamblocksmap: 92 Teamblocksmap
    { name: 'Arrows.map.jim', folder: 'Graphics', start: 0x07C54E, end: 0x07C7AA }, // Arrowsmap: 92 Arrowsmap
    { name: 'EASN.map.jim', folder: 'Graphics', start: 0x07C7AA, end: 0x07C946 }, // EASNmap: 92 EASNmap
    { name: 'RonBarr.map.jim', folder: 'Graphics', start: 0x07C946, end: 0x07CF1E }, // RonBarrMap: Ron Barr picture on the ScoutingReport (93 only)
    { name: 'Scores.map.jim', folder: 'Graphics', start: 0x07CF1E, end: 0x07D304 }, // ScoresMap: bitmap under the title on the ShowScores "Scores" screen (93 only)
    { name: 'EASN.anim', folder: 'Graphics', start: 0x07D304, end: 0x07F4F6 }, // SpinningEASN: 92 Stanleymap. 92 Stanley.map.jim was a bitmap; 93 draws the cup as sprites (UpdateStanleyCupAnimation SetSframe)
    { name: 'EASN2.map.jim', folder: 'Graphics', start: 0x07F4F6, end: 0x07FB76 }, // EASNmap2: the five EASN bitmaps on the Stanley Cup screen (93 only)
];

// Rev B (v1.2, 1993.FEB) slices, in ROM addresses of that ROM. Where a slice is unchanged from Rev 0 it only moved.
// EA changed the EASN branding to EA Sports in this revision: the EASN pictures are EASports ones, and the spinning
// EASN animation (EASN.anim) and EASN2 are gone (one EASports2 picture replaces them on the Stanley Cup screen).
const REVB_SLICES = {
    'ASEh.pal': [0x000382, 0x0003A2],
    'ASEv.pal': [0x0003A2, 0x0003C2],
    'ASWh.pal': [0x00061E, 0x00063E],
    'ASWv.pal': [0x00063E, 0x00065E],
    'BOSh.pal': [0x0008BE, 0x0008DE],
    'BOSv.pal': [0x0008DE, 0x0008FE],
    'BUFh.pal': [0x000B76, 0x000B96],
    'BUFv.pal': [0x000B96, 0x000BB6],
    'CGYh.pal': [0x000E38, 0x000E58],
    'CGYv.pal': [0x000E58, 0x000E78],
    'CHIh.pal': [0x0010DE, 0x0010FE],
    'CHIv.pal': [0x0010FE, 0x00111E],
    'DETh.pal': [0x00139E, 0x0013BE],
    'DETv.pal': [0x0013BE, 0x0013DE],
    'EDMh.pal': [0x001656, 0x001676],
    'EDMv.pal': [0x001676, 0x001696],
    'HFDh.pal': [0x001904, 0x001924],
    'HFDv.pal': [0x001924, 0x001944],
    'LAh.pal': [0x001BB8, 0x001BD8],
    'LAv.pal': [0x001BD8, 0x001BF8],
    'LIh.pal': [0x001E82, 0x001EA2],
    'LIv.pal': [0x001EA2, 0x001EC2],
    'MINh.pal': [0x00212E, 0x00214E],
    'MINv.pal': [0x00214E, 0x00216E],
    'MTLh.pal': [0x0023D0, 0x0023F0],
    'MTLv.pal': [0x0023F0, 0x002410],
    'NJh.pal': [0x0026A8, 0x0026C8],
    'NJv.pal': [0x0026C8, 0x0026E8],
    'NYh.pal': [0x002960, 0x002980],
    'NYv.pal': [0x002980, 0x0029A0],
    'OTWh.pal': [0x002C28, 0x002C48],
    'OTWv.pal': [0x002C48, 0x002C68],
    'PHIh.pal': [0x002E46, 0x002E66],
    'PHIv.pal': [0x002E66, 0x002E86],
    'PITh.pal': [0x003102, 0x003122],
    'PITv.pal': [0x003122, 0x003142],
    'QUEh.pal': [0x0033A6, 0x0033C6],
    'QUEv.pal': [0x0033C6, 0x0033E6],
    'SJh.pal': [0x003680, 0x0036A0],
    'SJv.pal': [0x0036A0, 0x0036C0],
    'STLh.pal': [0x00393A, 0x00395A],
    'STLv.pal': [0x00395A, 0x00397A],
    'TBYh.pal': [0x003BF0, 0x003C10],
    'TBYv.pal': [0x003C10, 0x003C30],
    'TORh.pal': [0x003E2E, 0x003E4E],
    'TORv.pal': [0x003E4E, 0x003E6E],
    'VANh.pal': [0x0040E8, 0x004108],
    'VANv.pal': [0x004108, 0x004128],
    'WPGh.pal': [0x0043A2, 0x0043C2],
    'WPGv.pal': [0x0043C2, 0x0043E2],
    'WSHh.pal': [0x004660, 0x004680],
    'WSHv.pal': [0x004680, 0x0046A0],
    'z80_snd_drv93.bin': [0x016E47, 0x0170BE],
    'z80_snd_drv93_end.bin': [0x0170C3, 0x0170D1],
    'sfx_shotbh_pcm.bin': [0x01714A, 0x01733E],
    'sfx_pass_pcm.bin': [0x01733E, 0x01806B],
    'sfx_oooh_pcm.bin': [0x01806C, 0x01B2B0],
    'sfx_crowdboo_pcm.bin': [0x01B2B0, 0x01D7FD],
    'sfx_check_pcm.bin': [0x01D7FE, 0x01F750],
    'sfx_crowdcheer_pcm.bin': [0x01F750, 0x022630],
    'sfx_bglass_pcm.bin': [0x022630, 0x0260AF],
    'sfx_playerwall_pcm.bin': [0x0260B0, 0x026560],
    'sfx_check2_pcm.bin': [0x026560, 0x026F8F],
    'sfx_hithigh_pcm.bin': [0x026F90, 0x0274E6],
    'sfx_shotfh_pcm.bin': [0x0274E6, 0x02809E],
    'sfx_puckget_pcm.bin': [0x02809E, 0x0282FE],
    'fm_instrument_patches.bin': [0x0282FE, 0x0286FE],
    'sfx_beep1_cmdstream.bin': [0x02876E, 0x02877A],
    'sfx_id_26_27_cmdstream.bin': [0x02877A, 0x02877E],
    'sfx_beep2_cmdstream.bin': [0x02877E, 0x02878E],
    'sfx_horn_cmdstream.bin': [0x02878E, 0x02880A],
    'sfx_stdef_cmdstream.bin': [0x02880A, 0x028826],
    'sfx_puckget_cmdstream.bin': [0x028826, 0x028842],
    'sfx_puckice1_cmdstream.bin': [0x028842, 0x028852],
    'sfx_puckice2_cmdstream.bin': [0x028852, 0x028862],
    'sfx_puckice3_cmdstream.bin': [0x028862, 0x028872],
    'sfx_puckice4_cmdstream.bin': [0x028872, 0x028882],
    'sfx_puckbody_cmdstream.bin': [0x028882, 0x02889E],
    'sfx_oooh_cmdstream.bin': [0x02889E, 0x0288BA],
    'sfx_puckpost_cmdstream.bin': [0x0288BA, 0x0288CA],
    'sfx_playerwall_cmdstream.bin': [0x0288CA, 0x0288E6],
    'sfx_playerwall2_cmdstream.bin': [0x0288E6, 0x028902],
    'sfx_playerwall3_cmdstream.bin': [0x028902, 0x02891E],
    'sfx_playerwall4_cmdstream.bin': [0x02891E, 0x02893A],
    'sfx_puckwall1_cmdstream.bin': [0x02893A, 0x02894A],
    'sfx_puckwall2_cmdstream.bin': [0x02894A, 0x02895A],
    'sfx_puckwall3_cmdstream.bin': [0x02895A, 0x02896A],
    'sfx_puckwall4_cmdstream.bin': [0x02896A, 0x02897A],
    'sfx_whistle_cmdstream.bin': [0x02897A, 0x028A18],
    'sfx_shotwiff_cmdstream.bin': [0x028A18, 0x028A28],
    'sfx_check1_cmdstream.bin': [0x028A28, 0x028A44],
    'sfx_check2_cmdstream.bin': [0x028A44, 0x028A60],
    'sfx_check3_cmdstream.bin': [0x028A60, 0x028A7C],
    'sfx_check4_cmdstream.bin': [0x028A7C, 0x028AA0],
    'sfx_pass1_cmdstream.bin': [0x028AA0, 0x028AB0],
    'sfx_pass2_cmdstream.bin': [0x028AB0, 0x028AC0],
    'sfx_pass3_cmdstream.bin': [0x028AC0, 0x028AD0],
    'sfx_pass4_cmdstream.bin': [0x028AD0, 0x028AE0],
    'sfx_shotbh1_cmdstream.bin': [0x028AE0, 0x028AF0],
    'sfx_shotbh2_cmdstream.bin': [0x028AF0, 0x028B00],
    'sfx_shotbh3_cmdstream.bin': [0x028B00, 0x028B10],
    'sfx_shotbh4_cmdstream.bin': [0x028B10, 0x028B20],
    'sfx_shotfh1_cmdstream.bin': [0x028B20, 0x028B30],
    'sfx_shotfh2_cmdstream.bin': [0x028B30, 0x028B40],
    'sfx_shotfh3_cmdstream.bin': [0x028B40, 0x028B50],
    'sfx_shotfh4_cmdstream.bin': [0x028B50, 0x028B60],
    'sfx_hithigh_cmdstream.bin': [0x028B60, 0x028B70],
    'sfx_hitlow_cmdstream.bin': [0x028B70, 0x028B80],
    'sfx_homewin_cmdstream.bin': [0x028B80, 0x028BB8],
    'sfx_crowdcheer_cmdstream.bin': [0x028BB8, 0x028BC8],
    'sfx_crowdboo_cmdstream.bin': [0x028BC8, 0x028BD8],
    'sfx_bglass_cmdstream.bin': [0x028BD8, 0x028BF4],
    'sfx_oooh2_cmdstream.bin': [0x028BF4, 0x028C04],
    'sfx_siren_cmdstream.bin': [0x028C04, 0x028E2C],
    'fmtune_goal_cmdstream.bin': [0x028E2C, 0x029100],
    'fmtune_periodstart_cmdstream.bin': [0x029100, 0x0292D0],
    'fmtune_lategame_cmdstream.bin': [0x0292D0, 0x029654],
    'fmtune_powerplay_cmdstream.bin': [0x029654, 0x0298F8],
    'fmtune_faceoff_cmdstream.bin': [0x0298F8, 0x029BD8],
    'fmtune_title_cmdstream.bin': [0x029BD8, 0x029C36],
    'fmtune_title_loop_cmdstream.bin': [0x029C3A, 0x02AF54],
    'fmtune_eop_cmdstream.bin': [0x02AF58, 0x02C89A],
    'fmtune_scouting_cmdstream.bin': [0x02C89E, 0x02CEB8],
    'ScoutingReportText.bin': [0x02CEBC, 0x02E1F3],
    'GameSetUp.map.jim': [0x02E1F4, 0x02EF9A],
    'GameSetup.anim': [0x02EF9A, 0x02F0A6],
    'Title1.map.jim': [0x02F0A6, 0x03127E],
    'Title2.map.jim': [0x03127E, 0x031F06],
    'Title3.anim': [0x031F06, 0x0322C2],
    'TitleLogo.anim': [0x0322C2, 0x032852],
    'Scouting.map.jim': [0x032852, 0x0335AC],
    'Framer.map.jim': [0x0335AC, 0x033624],
    'FaceOff.map.jim': [0x033624, 0x033A88],
    'IceRink.map.jim': [0x033A88, 0x038A90],
    'Refs.map.jim': [0x038A90, 0x0395EC],
    'Refs2.map.jim': [0x0395EC, 0x03A502],
    'Sprites.anim': [0x03A502, 0x074A6A],
    'Crowd.anim': [0x074A6A, 0x0772F6],
    'FaceOff.anim': [0x0772F6, 0x078368],
    'Zam.anim': [0x078368, 0x078E52],
    'BigFont.map.jim': [0x078E52, 0x079708],
    'SmallFont.map.jim': [0x079708, 0x07A3D6],
    'EnergyBar.map.jim': [0x07A3D6, 0x07A4CA],
    'TeamBlocks.map.jim': [0x07A4CA, 0x07C6A2],
    'Arrows.map.jim': [0x07C7B2, 0x07CA0E],
    'EASports.map.jim': [0x07C6A2, 0x07C7B2],
    'RonBarr.map.jim': [0x07CA0E, 0x07CFE6],
    'Scores.map.jim': [0x07CFE6, 0x07D3CC],
    'EASports2.map.jim': [0x07D3CC, 0x07E2F4],
};

// Known retail ROMs. Slices are listed at retail addresses; each version maps a retail address to
// its own (Rev A: every slice from the Z80 driver at $16E53 on sits $2E bytes higher). The bytes of
// every slice are the same in both, so either ROM gives the same Extracted/ files.
const VERSIONS = [
    { id: 'retail', label: 'NHLPA Hockey 93 Rev 0 / v1.0 retail (1992.JUL, GM T-50396 -00)', file: 'nhlpa93retail.bin',
      sha1: '8efc1cacb079ea223966dda065c16c49e584cac2', size: 0x80000, date: '1992.JUL', serial: 'GM T-50396 -00',
      map: (a) => a },
    { id: 'reva', label: 'NHLPA Hockey 93 Rev A / v1.1 (1992.OCT, GM T-50396 -01)', file: 'nhlpa93retailRevA.bin',
      sha1: '2ab048fc7209df28b00ef47f2f686f5b7208466e', size: 0x80000, date: '1992.OCT', serial: 'GM T-50396 -01',
      map: (a) => (a >= 0x16E53 ? a + 0x2E : a) },
    { id: 'revb', label: 'NHLPA Hockey 93 Rev B / v1.2 (1993.FEB, GM T-50396 -00)', file: 'nhlpa93retailRevB.bin',
      sha1: '76c0f3d4665ffcd53adfffaa27fc4dded694f8f7', size: 0x80000, date: '1993.FEB', serial: 'GM T-50396 -00', slices: REVB_SLICES },
];

// Find the version of a ROM by SHA-1. Size and header are only used to explain a refusal.
function detectVersion(data) {
    const sha1 = crypto.createHash('sha1').update(data).digest('hex');
    const v = VERSIONS.find((x) => x.sha1 === sha1);
    if (v) return { version: v, sha1 };
    const date = data.subarray(0x118, 0x120).toString('latin1');
    const serial = data.subarray(0x180, 0x18E).toString('latin1');
    const near = VERSIONS.find((x) => x.size === data.length && x.date === date && x.serial === serial);
    let msg = `Unknown ROM: SHA-1 ${sha1}, ${data.length} bytes, header date '${date}', serial '${serial}'.\n`;
    if (near) msg += `Header matches ${near.label}, but the SHA-1 does not (bad dump, hack, or byte-swapped/interleaved file?).\n`;
    msg += 'Supported ROMs:\n' + VERSIONS.map((x) => `  ${x.label}: SHA-1 ${x.sha1} (${x.file})`).join('\n');
    return { version: null, sha1, msg };
}

async function extractAssets(romPath, options = {}) {
    // Set default options
    const extractOptions = {
        outputDir: options.outputDir || path.join(__dirname, '..', 'Extracted'),
        verbose: options.verbose || false
    };
    
    try {
        const romData = await fs.readFile(romPath);
        const { version, sha1, msg } = detectVersion(romData);
        if (!version) {
            console.error(msg + '\nAborting extraction.');
            process.exitCode = 1;
            return;
        }
        console.log(`ROM: ${version.label}`);

        // Create base Extracted directory
        const baseDir = extractOptions.outputDir;
        await fs.mkdir(baseDir, { recursive: true });
        // The completion marker is written last; remove it first so a broken run leaves none.
        const markerPath = path.join(baseDir, '.extract-complete.json');
        await fs.rm(markerPath, { force: true });
        const written = [];

        // Extract each asset (Rev B has its own slice list, see REVB_SLICES)
        const list = version.slices
            ? Object.keys(version.slices).map((name) => {
                const retail = assets.find((a) => a.name === name || (name.startsWith('EASports') && a.name.startsWith('EASN') && a.name.endsWith('.map.jim')));
                return { name, folder: (retail || { folder: 'Graphics' }).folder, start: version.slices[name][0], end: version.slices[name][1] };
            })
            : assets;
        for (const asset of list) {
            // Create output directory
            const outputDir = path.join(baseDir, asset.folder);
            await fs.mkdir(outputDir, { recursive: true });

            // Extract data
            const start = version.slices ? asset.start : version.map(asset.start), end = version.slices ? asset.end : version.map(asset.end - 1) + 1;
            const assetData = romData.slice(start, end);

            // Write to file
            const outputPath = path.join(outputDir, asset.name);
            await fs.writeFile(outputPath, assetData);
            written.push({ path: path.posix.join(asset.folder.replace(/\\/g, '/'), asset.name), size: assetData.length });
            
            if (extractOptions.verbose) {
                console.log(`Extracted ${asset.name} (${assetData.length} bytes) from offset 0x${start.toString(16)} to 0x${end.toString(16)}`);
                console.log(`Saved to ${outputPath}`);
            } else {
                console.log(`Extracted ${asset.name} to ${outputPath}`);
            }
        }

        // Completion marker for tools/prebuild.js: ROM, extractor version and every file written.
        const extractorSha1 = crypto.createHash('sha1').update(await fs.readFile(__filename)).digest('hex');
        await fs.writeFile(markerPath, JSON.stringify({ rom: version.id, romSha1: sha1, extractor: path.basename(__filename),
            extractorSha1, files: written }, null, 1) + '\n');
        console.log('Extraction completed successfully.');
        console.log(`Extracted ${list.length} assets from NHLPA 93 ROM.`);
    } catch (error) {
        console.error(`Error during extraction: ${error.message}`);
        process.exitCode = 1;
    }
}

// Parse command line arguments
function parseArgs() {
    const args = process.argv.slice(2);
    const options = {
        romFile: null,
        outputDir: path.join(__dirname, '..', 'Extracted'),
        verbose: false
    };

    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        
        if (arg === '-h' || arg === '--help') {
            displayHelp();
            process.exit(0);
        } else if (arg === '-v' || arg === '--verbose') {
            options.verbose = true;
        } else if (arg === '-o' || arg === '--output') {
            if (i + 1 < args.length) {
                options.outputDir = args[++i];
            } else {
                console.error('Error: Output directory not specified');
                displayHelp();
                process.exit(1);
            }
        } else if (!options.romFile) {
            options.romFile = arg;
        }
    }

    return options;
}

// Display help information
function displayHelp() {
    console.log(`
NHL 93 Asset Extractor
======================

This script extracts assets from NHLPA Hockey 93 ROM files.

Usage: node tools/extractAssets93.js [options] <rom_file_path>

Options:
  -h, --help              Display this help message
  -v, --verbose           Display detailed extraction information
  -o, --output <dir>      Specify output directory (default: <repo>/Extracted)

Notes:
  - Accepts the retail ROM (nhlpa93retail.bin) or the Rev A ROM (nhlpa93retailRevA.bin), found by SHA-1;
    both give the same files. Any other ROM is refused

Examples:
  node tools/extractAssets93.js nhlpa93retail.bin
  node tools/extractAssets93.js --verbose --output NHL93Assets nhlpa93retail.bin
    `);
}

// Main execution
const options = parseArgs();

if (!options.romFile) {
    console.error('Error: ROM file path not provided');
    displayHelp();
    process.exit(1);
}

console.log(`Extracting assets from: ${options.romFile}`);
console.log(`Output directory: ${options.outputDir}`);
if (options.verbose) {
    console.log('Verbose mode enabled');
}

extractAssets(options.romFile, {
    outputDir: options.outputDir,
    verbose: options.verbose
});