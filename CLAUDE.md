# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A **personal-use**, chat-only subset of ElvUI for **World of Warcraft Retail/Mainline ONLY** (Interface 120000 - Midnight 11.2.0+). All Classic, TBC, Wrath, Cata, and Mists code paths are stripped out. This addon has no action bars, unit frames, nameplates, bags, or other non-chat UI elements.

## Build & Deploy

**Recommended:** VS Code task — `Ctrl+Shift+B → "Deploy ElvUIChat"`

**PowerShell:**
```powershell
.\build\deploy.ps1
# Custom path:
.\build\deploy.ps1 -SourcePath "source\ElvUIChat" -TargetPath "C:\...\Interface\AddOns\ElvUIChat"
```

Edit `build\config.ps1` to set your default WoW install path.

## Code Validation (CRITICAL — Run After Every Edit)

After editing any `.lua` file, validate syntax immediately:
```
get_errors(filePaths: ["path/to/edited/file.lua"])
```

Ignore these Lua Language Server false positives:
- `Undefined global 'ElvUIChat'` / `ElvUIChatDB` / `ElvUIChatPrivateDB` — WoW runtime globals
- `Fields cannot be injected into _G` — WoW allows this
- Type-checking warnings

Real errors to fix: `'end' expected`, `'<eof>' expected near 'end'`, unmatched brackets.

## Architecture

### Load Order (`Core/Load.xml`)
```
init.lua → Templates.xml → Locales → Media → Defaults → General → Layout → Modules
```

### Modules (only these four exist)
```lua
E.AFK    = E:NewModule('AFK',    'AceEvent-3.0', 'AceTimer-3.0')
E.Chat   = E:NewModule('Chat',   'AceTimer-3.0', 'AceHook-3.0', 'AceEvent-3.0')
E.Layout = E:NewModule('Layout', 'AceEvent-3.0')
E.Skins  = E:NewModule('Skins',  'AceTimer-3.0', 'AceHook-3.0', 'AceEvent-3.0')
```
`E:GetModule()` calls in any file must only reference these four.

### Key Files
| File | Purpose |
|------|---------|
| `Core/init.lua` | Engine bootstrap, module declarations, DB init |
| `Core/General/Core.lua` | `E:Initialize()`, slash commands, staggered updates |
| `Core/Modules/Chat/Chat.lua` | Main chat functionality (~4000+ lines) |
| `Core/General/Options.lua` | AceConfig options table (`E.db.chat`, `E.private`, `E.global`) |
| `Core/General/Config.lua` | `E:ToggleOptions()`, opens AceConfigDialog |
| `Core/Layout/Layout.lua` | Chat panel layout, fade toggles |
| `Core/Defaults/Profile.lua` | Profile defaults (`P.chat`, `P.general`) |
| `Core/Defaults/Private.lua` | Private (per-machine) defaults |
| `Core/Defaults/Global.lua` | Global (cross-profile) defaults |
| `Skins/Battlenet.lua` | BNet chat skin |
| `Skins/ChatConfig.lua` | Chat config frame skin |
| `Skins/CombatLog.lua` | Combat log skin |

### Namespace Pattern (top of EVERY file)
```lua
local E, L, V, P, G = unpack(ElvUIChat)
-- E = engine, L = locales, V = private DB profile, P = profile defaults, G = global defaults
```

### Database Variables
- `ElvUIChatDB` — profile/global SavedVariables
- `ElvUIChatPrivateDB` — private (per-machine) SavedVariables
- `ElvUIChatCharacterDB` — per-character storage (chat history, edit history)
  - `ElvUIChatCharacterDB.ChatEditHistory` — up/down arrow chat history
  - `ElvUIChatCharacterDB.ChatHistoryLog` — message log

### Libraries (`E.Libs.*`)
```lua
E.Libs.LSM        -- LibSharedMedia-3.0
E.Libs.AceDB      -- AceDB-3.0
E.Libs.ACH        -- LibAceConfigHelper
E.Libs.ACL        -- AceLocale-3.0-ElvUIChat (note: ElvUIChat suffix!)
E.Libs.Deflate    -- LibDeflate
E.Libs.DualSpec   -- LibDualSpec-1.0
```

## Updating from ElvUI Source

Source lives at `OriginSource/ElvUI/` (read-only reference). When syncing:

**Files to sync:**
| OriginSource | Our Location | Notes |
|---|---|---|
| `ElvUI_Mainline.toc` | `ElvUIChat.toc` | Interface version only |
| `Game/Shared/Modules/Chat/Chat.lua` | `Core/Modules/Chat/Chat.lua` | Copy + namespace fix |
| `Game/Mainline/Skins/Battlenet.lua` | `Skins/Battlenet.lua` | Copy + namespace fix |
| `Game/Mainline/Skins/ChatConfig.lua` | `Skins/ChatConfig.lua` | Copy + namespace fix |
| `Game/Mainline/Skins/CombatLog.lua` | `Skins/CombatLog.lua` | Copy + namespace fix |

**3-step namespace conversion (PowerShell):**
```powershell
(Get-Content file.lua -Raw) `
  -replace 'unpack\(ElvUI\)','unpack(ElvUIChat)' `
  -replace 'ElvCharacterDB','ElvUIChatCharacterDB' `
  | Set-Content file.lua -NoNewline
```
Then manually remove Classic/TBC/Wrath/Cata/Mists blocks, and simplify `if E.Retail then <CODE> end` → just `<CODE>`.

## WoW API Migrations (Midnight / Interface 120000)

All modern namespace APIs — no fallbacks needed:
```lua
C_AddOns.GetAddOnMetadata()          -- was GetAddOnMetadata()
C_AddOns.GetAddOnEnableState()       -- was GetAddOnEnableState()
C_CVar.GetCVar() / SetCVar()         -- SetCVar takes 2 args only: (cvar, value)
BetterDate()                         -- was date()
ChatFrameUtil.SetLastTellTarget()    -- was ChatEdit_SetLastTellTarget()
ChatFrameUtil.ResolvePrefixedChannelName()
C_KeyBindings.GetMouseButtonName()   -- was GetMouseButtonName()
```

## Common Gotchas

1. **Namespace confusion**: Every file must use `unpack(ElvUIChat)` — never `unpack(ElvUI)`
2. **SetCVar**: 2 args only `(cvar, value)`, not 3
3. **Module references**: `E:GetModule()` only for Chat, Layout, Skins, Blizzard, AFK
4. **`ElvUIChatCharacterDB` timing**: May not exist on first login — always check/create in `OnInitialize`
5. **Over-including**: Don't pull in code referencing `E.UnitFrames`, `E.ActionBars`, `E.NamePlates`, etc.

## WoW API Research

Use the `s-research` skill for API lookups:
```bash
mech call api.search -i '{"query": "ChatFrame*"}'
mech call api.info -i '{"api_name": "C_ChatInfo.SendAddonMessage"}'
```

## In-Game Testing

After deploy:
1. `/console scriptErrors 1` to surface Lua errors
2. `/reload`
3. `/elvuichat` — verify options dialog opens
4. Test: copy button, timestamps, URL links, tab flashing, chat edit history (↑↓ in chat box)
