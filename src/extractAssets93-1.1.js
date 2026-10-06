const fs = require('fs').promises;
const path = require('path');
const crc32 = require('crc-32'); // Requires 'crc-32' package: npm install crc-32

// Asset definitions from the .lst file
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
    // ($16E53-$2EFA1) and src/graphics93.asm ($2EFA2-$7FB75). Names follow the NHL 92 extractor where 93 has the
    // same asset (z80_snd_drv, sfx_*_pcm, sfx_*_cmdstream, <name>.map.jim for bitmaps, <name>.anim for sprite frames).
    // Sound boundaries come from the tables the 68k driver reads (pcm_sample_table, fm_instrument_patches,
    // MusicTrackPointerTable; each event stream runs to the next one). Sound names are from the sfx / song call sites.
    // Absolute addresses (PCM sample table, song loop pointers, the Z80 FM patch bank address) and pad bytes are
    // source in sound93.asm, not slices, so the data relocates for Rev A.
    { name: 'z80_snd_drv93.bin', folder: 'Sound', start: 0x016E53, end: 0x0170CA }, // 93 Z80 driver after its first byte ($16E52 is Z80_Program_Code dc.b $18), up to the ld bc of the FM patch bank address. p_initialZ80 copies $295 bytes from $16E52
    { name: 'z80_snd_drv93_end.bin', folder: 'Sound', start: 0x0170CF, end: 0x0170DD }, // rest of the 93 Z80 driver
    { name: 'sfx_shotbh_pcm.bin', folder: 'Sound', start: 0x017156, end: 0x01734A }, // sample 2: shotbh
    { name: 'sfx_pass_pcm.bin', folder: 'Sound', start: 0x01734A, end: 0x018077 }, // sample 1: pass
    { name: 'sfx_oooh_pcm.bin', folder: 'Sound', start: 0x018078, end: 0x01B2BC }, // sample 12: oooh, sfx_id_0D, sfx_id_0E
    { name: 'sfx_crowdboo_pcm.bin', folder: 'Sound', start: 0x01B2BC, end: 0x01D809 }, // sample 11: crowdboo
    { name: 'sfx_check_pcm.bin', folder: 'Sound', start: 0x01D80A, end: 0x01F75C }, // sample 5: check1, check3
    { name: 'sfx_crowdcheer_pcm.bin', folder: 'Sound', start: 0x01F75C, end: 0x02263C }, // sample 13: crowdcheer, homewin
    { name: 'sfx_id_0E_pcm.bin', folder: 'Sound', start: 0x02263C, end: 0x0260BB }, // sample 14: sfx_id_0E
    { name: 'sfx_playerwall_pcm.bin', folder: 'Sound', start: 0x0260BC, end: 0x02656C }, // sample 6: playerwall, sfx_id_21-23
    { name: 'sfx_check2_pcm.bin', folder: 'Sound', start: 0x02656C, end: 0x026F9B }, // sample 4: check2, check4
    { name: 'sfx_hithigh_pcm.bin', folder: 'Sound', start: 0x026F9C, end: 0x0274F2 }, // samples 7 and 10: hithigh, hitlow, check1-4, songs $32 and $35-$37
    { name: 'sfx_shotfh_pcm.bin', folder: 'Sound', start: 0x0274F2, end: 0x0280AA }, // sample 3: shotfh
    { name: 'sfx_puckget_pcm.bin', folder: 'Sound', start: 0x0280AA, end: 0x02830A }, // sample 0: puckget
    { name: 'fm_instrument_patches.bin', folder: 'Sound', start: 0x02830A, end: 0x02870A }, // IDA unk_28338: 32 FM patches x 32 bytes (byte $1E = pitch bend scale)
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
    { name: 'sfx_id_21_cmdstream.bin', folder: 'Sound', start: 0x0288F2, end: 0x02890E }, // sound $21: no caller found, same patches as playerwall
    { name: 'sfx_id_22_cmdstream.bin', folder: 'Sound', start: 0x02890E, end: 0x02892A }, // sound $22: no caller found, same patches as playerwall
    { name: 'sfx_id_23_cmdstream.bin', folder: 'Sound', start: 0x02892A, end: 0x028946 }, // sound $23: no caller found, same patches as playerwall
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
    { name: 'sfx_id_0E_cmdstream.bin', folder: 'Sound', start: 0x028BE4, end: 0x028C00 }, // sound $E: wallcollb (puck over the wall)
    { name: 'sfx_id_0D_cmdstream.bin', folder: 'Sound', start: 0x028C00, end: 0x028C10 }, // sound $D: injury (setInjuryType), visiting goalie save
    { name: 'sfx_siren_cmdstream.bin', folder: 'Sound', start: 0x028C10, end: 0x028E38 }, // sound 0 (92 SFXsiren)
    { name: 'fmtune_goal_cmdstream.bin', folder: 'Sound', start: 0x028E38, end: 0x02910C }, // song $30: Goal
    { name: 'fmtune_periodstart_cmdstream.bin', folder: 'Sound', start: 0x02910C, end: 0x0292DC }, // song $31: StartPer
    { name: 'fmtune_period3_cmdstream.bin', folder: 'Sound', start: 0x0292DC, end: 0x029660 }, // song $32: CheckPeriodEnd, 3rd period
    { name: 'fmtune_powerplay_cmdstream.bin', folder: 'Sound', start: 0x029660, end: 0x029904 }, // song $33: updatepwrplay, home power play
    { name: 'fmtune_faceoff_cmdstream.bin', folder: 'Sound', start: 0x029904, end: 0x029BE4 }, // song $34: puckfaceoff
    { name: 'fmtune_title_cmdstream.bin', folder: 'Sound', start: 0x029BE4, end: 0x029C42 }, // song $35: TitleScreen, ExitToOpening (92 SngTitle)
    { name: 'fmtune_title_loop_cmdstream.bin', folder: 'Sound', start: 0x029C46, end: 0x02AF60 }, // song $35 loop body
    { name: 'fmtune_eog_cmdstream.bin', folder: 'Sound', start: 0x02AF64, end: 0x02C8A6 }, // song $36: IntermissionStart, PlayoffScreen, StartHL2 (92 SngEOG / SngPO)
    { name: 'fmtune_scouting_cmdstream.bin', folder: 'Sound', start: 0x02C8AA, end: 0x02CEC4 }, // song $37: ScoutingReport
    { name: 'ScoutingReportText.bin', folder: 'Text', start: 0x02CEC8, end: 0x02E1FB }, // ScoutingReportText (hockey93_07 stub): scouting report paragraphs
    { name: 'GameSetUp.map.jim', folder: 'Graphics', start: 0x02E1FC, end: 0x02EFA2 }, // 92 GameSetUp.map.jim: game setup bitmap (setoptions movea.l #$2E1FC)
    { name: 'GameSetup.anim', folder: 'Graphics', start: 0x02EFA2, end: 0x02F0B0 }, // GameSetupSprites: IDA GameSetupMap: game setup roster sprites (AddTeamSpriteFrame SetSframe, tiles from +8). The 92 GameSetUpMap bitmap is $2E1FC, in sound93
    { name: 'Title1.map.jim', folder: 'Graphics', start: 0x02F0B0, end: 0x031288 }, // Title1Map: 92 Title1Map: TitleScreen backdrop
    { name: 'Title2.map.jim', folder: 'Graphics', start: 0x031288, end: 0x031F10 }, // Title2Map: 92 Title2Map: second TitleScreen bitmap (no IDA label; hockey93_07 loads #$31288)
    { name: 'Title3.anim', folder: 'Graphics', start: 0x031F10, end: 0x0322CE }, // Title3Sprites: IDA Title3map: the three TitleAnimCallback sprites (SetSframe)
    { name: 'TitleLogo.anim', folder: 'Graphics', start: 0x0322CE, end: 0x032860 }, // TitleLogoSprites: IDA Titlemap2: the four title logo sprites (FinalizeSpriteList SetSframe); palette reused by PlayoffScreen
    { name: 'Scouting.map.jim', folder: 'Graphics', start: 0x032860, end: 0x033388 }, // ScoutMap: 92 ScoutMap (IDA unk_3288E): ScoutingReport background, also PlayoffScreen, SetupScreen, DrawTeamScreen
    { name: 'Framer.map.jim', folder: 'Graphics', start: 0x033388, end: 0x033400 }, // FramerMap: 92 FramerMap (IDA Framermap)
    { name: 'FaceOff.map.jim', folder: 'Graphics', start: 0x033400, end: 0x033864 }, // FaceOffMap: 92 FaceOffMap
    { name: 'IceRink.map.jim', folder: 'Graphics', start: 0x033864, end: 0x038906 }, // IceRinkMap: 92 IceRinkMap
    { name: 'Refs.map.jim', folder: 'Graphics', start: 0x038906, end: 0x039462 }, // RefsMap: 92 RefsMap
    { name: 'Refs2.map.jim', folder: 'Graphics', start: 0x039462, end: 0x03A378 }, // RefMap2: IDA RefMap2: the horizontal ref (PushRef); no 92 counterpart
    { name: 'Sprites.anim', folder: 'Graphics', start: 0x03A378, end: 0x0748E2 }, // Sprites: 92 Sprites (IDA SpritesMap): $FFFFFFFF, long offset to FrameDataOff, then tiles
    { name: 'Crowd.anim', folder: 'Graphics', start: 0x0748E2, end: 0x077170 }, // CrowdSprites: 92 CrowdSprites
    { name: 'FaceOff.anim', folder: 'Graphics', start: 0x077170, end: 0x0781E4 }, // FaceOffSprites: 92 FaceOffSprites
    { name: 'Zam.anim', folder: 'Graphics', start: 0x0781E4, end: 0x078CFE }, // ZamSprites: 92 ZamSprites
    { name: 'BigFont.map.jim', folder: 'Graphics', start: 0x078CFE, end: 0x0795B4 }, // BigFontMap: 92 BigFontMap (IDA bigfontmap)
    { name: 'SmallFont.map.jim', folder: 'Graphics', start: 0x0795B4, end: 0x07A282 }, // SmallFontMap: 92 SmallFontMap (IDA smallfontmap)
    { name: 'EnergyBar.map.jim', folder: 'Graphics', start: 0x07A282, end: 0x07A376 }, // EnergyBarMap: IDA unk_7A2B0: line energy bar frames drawn by linebar (92 dobar built the bar from font chars)
    { name: 'TeamBlocks.map.jim', folder: 'Graphics', start: 0x07A376, end: 0x07C54E }, // Teamblocksmap: 92 Teamblocksmap (IDA TeamBlocksmap)
    { name: 'Arrows.map.jim', folder: 'Graphics', start: 0x07C54E, end: 0x07C7AA }, // Arrowsmap: 92 Arrowsmap (IDA ArrowsMap)
    { name: 'EASN.map.jim', folder: 'Graphics', start: 0x07C7AA, end: 0x07C946 }, // EASNmap: 92 EASNmap
    { name: 'RonBarr.map.jim', folder: 'Graphics', start: 0x07C946, end: 0x07CF1E }, // RonBarrMap: IDA Ronbarrmap: Ron Barr picture on the ScoutingReport (93 only)
    { name: 'Scores.map.jim', folder: 'Graphics', start: 0x07CF1E, end: 0x07D304 }, // ScoresMap: IDA unk_7CF4C: bitmap under the title on the ShowScores "Scores" screen (93 only)
    { name: 'Stanley.anim', folder: 'Graphics', start: 0x07D304, end: 0x07F4F6 }, // Stanleymap: 92 Stanleymap (IDA StanleyMap). 92 Stanley.map.jim was a bitmap; 93 draws the cup as sprites (UpdateStanleyCupAnimation SetSframe)
    { name: 'EASN2.map.jim', folder: 'Graphics', start: 0x07F4F6, end: 0x07FB76 }, // EASNmap2: IDA EASNmap2: the five EASN bitmaps on the Stanley Cup screen (93 only)
];

// Expected CRC32 checksum (996931775 in hexadecimal)
const EXPECTED_CRC32 = 0xCBBF4262;

async function verifyCRC32(filePath) {
    try {
        const data = await fs.readFile(filePath);
        const calculatedCRC = crc32.buf(data) >>> 0; // Convert to unsigned 32-bit integer
        console.log('Caclulated CRC32:', calculatedCRC, EXPECTED_CRC32);
        return calculatedCRC === EXPECTED_CRC32;
    } catch (error) {
        console.error(`Error reading ROM file for CRC32 check: ${error.message}`);
        return false;
    }
}

async function extractAssets(romPath, options = {}) {
    // Set default options
    const extractOptions = {
        outputDir: options.outputDir || 'Extracted',
        verbose: options.verbose || false
    };
    
    try {
        // Verify CRC32
        const isValid = await verifyCRC32(romPath);
        if (!isValid) {
            console.error('CRC32 checksum mismatch. Expected 3B6BF8BF. Aborting extraction.');
            return;
        }

        // Read the ROM file
        const romData = await fs.readFile(romPath);

        // Create base Extracted directory
        const baseDir = extractOptions.outputDir;
        await fs.mkdir(baseDir, { recursive: true });

        // Extract each asset
        for (const asset of assets) {
            // Create output directory
            const outputDir = path.join(baseDir, asset.folder);
            await fs.mkdir(outputDir, { recursive: true });

            // Extract data
            const assetData = romData.slice(asset.start, asset.end);

            // Write to file
            const outputPath = path.join(outputDir, asset.name);
            await fs.writeFile(outputPath, assetData);
            
            if (extractOptions.verbose) {
                console.log(`Extracted ${asset.name} (${assetData.length} bytes) from offset 0x${asset.start.toString(16)} to 0x${asset.end.toString(16)}`);
                console.log(`Saved to ${outputPath}`);
            } else {
                console.log(`Extracted ${asset.name} to ${outputPath}`);
            }
        }

        console.log('Extraction completed successfully.');
        console.log(`Extracted ${assets.length} assets from NHLPA 93 ROM.`);
    } catch (error) {
        console.error(`Error during extraction: ${error.message}`);
    }
}

// Parse command line arguments
function parseArgs() {
    const args = process.argv.slice(2);
    const options = {
        romFile: null,
        outputDir: 'Extracted',
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

Usage: node src/extractAssets93-1.1.js [options] <rom_file_path>

Options:
  -h, --help              Display this help message
  -v, --verbose           Display detailed extraction information
  -o, --output <dir>      Specify output directory (default: 'Extracted')

Notes:
  - This script extracts all known assets from the NHLPA 93 retail ROM (nhlpa93retail.bin)
  - ROM checksums are verified to ensure correct ROM is used

Examples:
  node src/extractAssets93-1.1.js nhlpa93retail.bin
  node src/extractAssets93-1.1.js --verbose --output NHL93Assets nhlpa93retail.bin
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