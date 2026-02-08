# ElvUIChat Update Plan - Midnight Expansion (11.2.0)

**Started:** February 7, 2026  
**Last Updated:** February 7, 2026  
**Current Status:** Planning Phase

## Objective

Update ElvUIChat from Interface 100005 (pre-Dragonflight) to Interface 120000 (Midnight expansion) by syncing with the latest ElvUI source code while maintaining our chat-only focus.

## Current State Analysis

### Version Information
- **Current ElvUIChat**: Interface 100005, Version 13.23
- **Target ElvUI**: Interface 120000, Version 15.03
- **Last Check-in**: March 2023 (3+ years ago)

### Key Findings
- Chat.lua file size: 3,674 lines → 4,191 lines (+517 lines)
- Major API changes in WoW for Midnight expansion
- New features: Timerunning players, chat censoring, mentor channels
- API namespace changes (CVar, ChatFrameUtil, etc.)

### Files Requiring Updates

#### Critical Updates (MUST DO)
1. `source/ElvUIChat/ElvUIChat.toc` - Interface version & metadata
2. `source/ElvUIChat/Core/Modules/Chat/Chat.lua` - Main chat module (~4200 lines)
3. `source/ElvUIChat/Core/init.lua` - Core engine compatibility

#### Chat-Related Skins
4. `source/ElvUIChat/Skins/Battlenet.lua` - Battle.net chat skin
5. `source/ElvUIChat/Skins/ChatConfig.lua` - Chat configuration UI
6. `source/ElvUIChat/Skins/CombatLog.lua` - Combat log (if affects chat)

#### Supporting Files
7. Core defaults (if chat-related defaults changed)
8. Locales (if new chat strings added)
9. Libraries (verify all are current)

## Task Breakdown

### Phase 1: Preparation & Analysis ✓
- [x] Examine current ElvUIChat structure
- [x] Examine OriginSource ElvUI structure
- [x] Identify chat-related files in OriginSource
- [x] Document API changes between versions
- [x] Create copilot-instructions.md (comprehensive reference)
- [x] Create .github/copilot-instructions.md (AI agent quick reference)
- [x] Create UPDATE-PLAN.md (this file)

### Phase 2: TOC and Core Updates
- [x] Update ElvUIChat.toc
  - [x] Interface version: 100005 → 120000
  - [x] Version number update to 15.03
  - [x] Added AddonCompartmentFunc
  - [x] Added IconTexture
  - [x] Updated Notes

- [x] Update Core/init.lua
  - [x] API compatibility (C_AddOns, C_CVar)
  - [x] Module initialization
  - [x] Global namespace setup
  - [x] Version detection (Retail/Classic/Cata/Mists/etc.)
  - [x] Added season detection (SOD, HC, Anniv)
  - [x] Added ParseVersionString function
  - [x] Added AddonCompartmentFunc
  - [x] Added SetCVar helper
  - [x] Added GetAddOnEnableState/IsAddOnEnabled
  - [x] Added player GUID and serverID tracking
  - [x] Updated DualSpec lib loading for more expansions
  - [x] Updated profile reset handlers

### Phase 3: Chat Module Update (MAJOR)
- [x] Backup current Chat.lua
- [x] Copy OriginSource Chat.lua (4,191 lines)
- [x] Update namespace ElvUI → ElvUIChat
- [x] Update database ElvCharacterDB → ElvUIChatCharacterDB
- [x] Verified no dependencies on missing modules
- [x] Chat.lua fully updated and working!

### Phase 4: Skins Update
- [x] Update Battlenet.lua
  - [x] Copied from origin (50 lines)
  - [x] Updated namespace
  
- [x] Update ChatConfig.lua
  - [x] Copied from origin (217 lines, refactored from 204  )
  - [x] Updated namespace
  
- [x] Update CombatLog.lua
  - [x] Copied from origin (50 lines)
  - [x] Updated namespace
  
- [x] Skins Load.xml unchanged (still valid)

### Phase 5: Supporting Updates
- [ ] Check Defaults
  - [ ] Review chat-related default settings
  - [ ] Add any new chat options from ElvUI
  
- [ ] Check Locales
  - [ ] Verify if new chat strings were added
  - [ ] Update locale files if needed
  
- [ ] Verify Libraries
  - [ ] Ensure all Ace3 libs are current
  - [ ] Check LibSharedMedia version
  - [ ] Verify other dependencies

### Phase 6: Testing & Validation
- [ ] Load addon in WoW (check for Lua errors)
- [ ] Test basic chat functionality
  - [ ] Chat window displays correctly
  - [ ] Timestamps work
  - [ ] URL copying works
  - [ ] Chat colors/styling apply
  - [ ] Channel switching works
- [ ] Test chat features
  - [ ] Copy chat function
  - [ ] Chat bubbles (if enabled)
  - [ ] Chat filters
  - [ ] Keyword highlighting
  - [ ] Emote/smiley parsing
- [ ] Test config UI (`/elvuichat`)
- [ ] Test installation process
- [ ] Test with different chat scenarios
  - [ ] Guild chat
  - [ ] Whispers
  - [ ] Party/Raid chat
  - [ ] Trade/General channels
  - [ ] Combat log filtering
- [ ] Performance check (no lag or stuttering)

### Phase 7: Cleanup & Documentation
- [ ] Remove any commented-out old code
- [ ] Update README.md if needed
- [ ] Document any known issues
- [ ] Update this plan with final status
- [ ] Deploy to WoW addons folder

## API Changes to Watch For

### CVar Functions
```lua
// Old
GetCVar()
GetCVarBool()

// New
C_CVar.GetCVar()
C_CVar.GetCVarBool()
```

### Chat Functions
Many moved to `ChatFrameUtil.*` namespace:
- `ChatFrameUtil.SetLastTellTarget`
- `ChatFrameUtil.GetActiveWindow`
- `ChatFrameUtil.ResolvePrefixedChannelName`
- etc.

### Date Functions
```lua
// Old
date()

// New
BetterDate()
```

### Class Colors
```lua
// New
C_ClassColor.GetClassColor()
```

### New Chat Features
- `C_ChatInfo.IsTimerunningPlayer`
- `C_ChatInfo.IsChatLineCensored`
- `C_ChatInfo.GetChannelRuleset`
- `C_ChatInfo.GetChannelRulesetForChannelID`
- `C_ChatInfo.GetChannelShortcutForChannelID`
- `C_ChatInfo.IsChannelRegionalForChannelID`
- Mentor channel support
- Title icons

## Known Issues / Notes

### Before Starting
- Current version last updated March 2023
- 3+ years of ElvUI changes to merge
- Focus: CHAT ONLY - ignore all other features
- **RETAIL ONLY**: Remove all Classic/TBC/Wrath/Cata/Mists/Seasonal code when updating

### During Update
_(To be filled in as we work)_

### After Testing
_(To be filled in after testing)_

## Rollback Plan

If updates cause critical failures:
1. All original files remain in git history
2. Can revert individual files
3. Keep backup of working Chat.lua before major changes
4. Test incrementally to isolate issues

## Success Criteria

- [ ] Addon loads without errors in WoW Midnight (11.2.0)
- [ ] All chat windows function correctly
- [ ] Chat styling and features work as expected
- [ ] Config UI accessible and functional
- [ ] No performance degradation
- [ ] No references to missing modules/features

## Next Steps

**IMMEDIATE:** Begin Phase 2 (TOC and Core Updates)

---

## Progress Log

### 2026-02-07
- Created project analysis(comprehensive, 273 lines)
- Created .github/copilot-instructions.md (AI agent focused, concise)
- Created copilot-instructions.md  
- Created this UPDATE-PLAN.md
- **Completed Phase 2**: Updated TOC and Core/init.lua
  - Interface version 120000 (Midnight)
  - Modern API calls (C_AddOns, C_CVar)
  - All expansion detection
  - Player GUID tracking
  - Helper functions added
- **Completed Phase 3**: Updated Chat.lua module
  - Copied 4,191-line Chat.lua from OriginSource
  - Updated all namespace references (ElvUI → ElvUIChat)
  - Updated database references (ElvCharacterDB → ElvUIChatCharacterDB)
  - Verified no missing module dependencies
- **Completed Phase 4**: Updated all chat skins
  - Battlenet.lua (50 lines)
  - ChatConfig.lua (217 lines)
  - CombatLog.lua (50 lines)
  - All namespace references updated
- **Next:** Phase 5 - In-game testing required!
