# ElvUIChat - AI Agent Instructions

## What This Project Is

A **personal-use** chat-only subset of ElvUI for **World of Warcraft Retail/Mainline ONLY** (Interface 120000 - Midnight 11.2.0+).

Extract ONLY chat features from full ElvUI - no action bars, unit frames, nameplates, bags, or other UI elements.

**Critical Exclusions:**
- Any code referencing `E.UnitFrames`, `E.ActionBars`, `E.NamePlates`, `E.DataTexts`, `E.Minimap`, etc.
- **Classic/TBC/Wrath/Cata/Mists support**: Remove ALL non-Retail version checks and code paths
- **Seasonal variants**: Remove Classic SOD, HC, Anniversary logic - we only support `E.Retail`
- **Movers**: Chat window doesn't need to be moved - remove Movers-related logic

**Project Philosophy:**
- **Minimalism**: When in doubt, leave it out
- **Retail only**: Strip out Classic/TBC/Wrath/Cata/Mists conditional code
- **Stability over features**: Only add new features if they directly improve chat
- **Personal use**: No need for extensive error handling or public support
- **Regular updates**: Sync with ElvUI Mainline releases when WoW expansions drop

## Architecture

### File Flow
```
OriginSource/ElvUI/          → Latest ElvUI (reference, read-only)
  ├── ElvUI_Mainline.toc     → Check Interface version
  └── Game/Shared/Modules/Chat/Chat.lua → Primary update source

source/ElvUIChat/            → Our slimmed addon (edit here)
  ├── ElvUIChat.toc          → Must match WoW Interface version
  ├── Core/init.lua          → Engine with ONLY: Chat, Layout, Skins, Blizzard, AFK modules
  ├── Core/Modules/Chat/     → Main chat functionality (4000+ lines)
  └── Skins/                 → ONLY: Battlenet, ChatConfig, CombatLog
```

### Namespace Rules (CRITICAL)

When copying from OriginSource, **3-step conversion**:

1. **Replace namespace** globally:
   ```powershell
   (Get-Content file.lua -Raw) -replace 'unpack\(ElvUI\)','unpack(ElvUIChat)' | Set-Content file.lua
   ```

2. **Replace database** variables:
   ```powershell
   (Get-Content file.lua -Raw) -replace 'ElvCharacterDB','ElvUIChatCharacterDB' | Set-Content file.lua
   ```

3. **Remove Classic code** - manually delete:
   - `if not E.Retail then ... end` blocks
   - `if E.Classic then ... end` blocks
   - `if E.Wrath then ... end` blocks
   - All seasonal variant checks (SOD, HC, Anniversary)
   - Simplify `if E.Retail then <CODE> end` → just use `<CODE>` directly

**Namespace reference:**
```lua
// ElvUI (source) uses:
unpack(ElvUI)
ElvDB, ElvPrivateDB, ElvCharacterDB

// We MUST use:
unpack(ElvUIChat)
ElvUIChatDB, ElvUIChatPrivateDB, ElvUIChatCharacterDB
```

**Character DB structure:**
- `ElvUIChatCharacterDB.ChatEditHistory` - Array of previous chat commands (up/down arrow history)
- `ElvUIChatCharacterDB.ChatHistoryLog` - Table of chat message history

### Dependency Management

**Required Dependencies:**
- Ace3 libraries (AceAddon, AceConsole, AceEvent, AceTimer, AceHook, AceConfig)
- LibSharedMedia-3.0
- LibStub
- CallbackHandler

**NOT Required:**
- ElvUI_Libraries (we bundle our own)
- ElvUI_Options (we have minimal options)
- Masque, BigWigs, Tukui, etc.

### Database Structure
- **Profile DBs**: `ElvUIChatDB` (global), `ElvUIChatPrivateDB` (private settings)
- **Character DB**: `ElvUIChatCharacterDB` - per-character storage (NOT profile-based)

## WoW API Compatibility (Interface 120000 - Midnight)

### Required Namespace Migrations
```lua
// Addon functions
GetAddOnMetadata()        → C_AddOns.GetAddOnMetadata()
GetAddOnEnableState()     → C_AddOns.GetAddOnEnableState()
IsAddOnLoaded()           → C_AddOns.IsAddOnLoaded()

// CVar functions (2 args only: cvar, value)
GetCVar()                 → C_CVar.GetCVar()
GetCVarBool()             → C_CVar.GetCVarBool()
SetCVar()                 → C_CVar.SetCVar()

// Chat functions (ChatFrameUtil namespace)
ChatEdit_SetLastTellTarget()           → ChatFrameUtil.SetLastTellTarget()
ChatFrame_ResolvePrefixedChannelName() → ChatFrameUtil.ResolvePrefixedChannelName()
ChatEdit_GetActiveWindow()             → ChatFrameUtil.GetActiveWindow()
ChatEdit_ChooseBoxForSend()            → ChatFrameUtil.ChooseBoxForSend()
ChatEdit_ParseText()                   → ChatFrameUtil.ParseText()
ChatEdit_GetChatFrame()                → ChatFrameUtil.GetChatFrame()
ChatEdit_UpdateHeader()                → ChatFrameUtil.UpdateHeader()
ChatEdit_ActivateChat()                → ChatFrameUtil.ActivateChat()

// Date function
date()                    → BetterDate()

// Misc
GetMouseButtonName()      → C_KeyBindings.GetMouseButtonName()
GetMouseButtonClicked()   → C_KeyBindings.GetMouseButtonClicked()
```

**Since we're Retail-only, ALL these APIs are available - no conditional checks needed.**

## Developer Workflows

### Build & Deploy

**Method 1: VS Code Task (Recommended)**
```powershell
# Press Ctrl+Shift+B → "Deploy ElvUIChat"
```

**Method 2: PowerShell Script**
```powershell
# Default deployment
.\build\deploy.ps1

# Custom WoW path
.\build\deploy.ps1 -SourcePath "source\ElvUIChat" -TargetPath "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\ElvUIChat"
```

**Method 3: Batch File** (legacy)
```powershell
build\deploy.cmd 'source\ElvUIChat' 'D:\Games\World of Warcraft\_retail_\Interface\AddOns\ElvUIChat'
```

**Tip**: Edit `build\config.ps1` to set your default WoW path.

### Code Validation (CRITICAL - ALWAYS RUN AFTER EDITS)

**MANDATORY after EVERY file edit** - validate syntax to catch errors immediately:

```powershell
# After editing any .lua file, ALWAYS run get_errors tool:
get_errors(filePaths: ["path/to/edited/file.lua"])

# For multi-file edits, validate all modified files:
get_errors(filePaths: ["file1.lua", "file2.lua", "file3.lua"])
```

**What to check:**
1. **Syntax errors** (parse errors, missing `end`, unmatched brackets):
   - `'end' expected (to close 'function' at line X)` → Missing `end` statement
   - `'<eof>' expected near 'end'` → Extra `end` statement
   - `'else' near X` → Missing `if` before `else`
   - `'elseif' near X` → Missing `if` before `elseif`

2. **Bracket/Quote matching** (manual verification for complex edits):
   - Every `{` has matching `}`
   - Every `(` has matching `)`
   - Every `[` has matching `]`
   - Every `'` has matching `'`
   - Every `"` has matching `"`
   - Every `function` has matching `end`
   - Every `if/do/while/for` has matching `end`

3. **Ignore these** (Lua Language Server warnings, not real errors):
   - `Undefined global 'ElvUIChat'` → Runtime WoW global
   - `Undefined global 'ElvUIChatDB'` → Runtime SavedVariable
   - `Fields cannot be injected into _G` → WoW allows this
   - Type checking warnings → Overly strict static analysis

**Workflow:**
```
1. Make edits using replace_string_in_file or multi_replace_string_in_file
2. IMMEDIATELY run get_errors on edited files
3. If syntax errors found:
   - Read the error carefully (line number, what's missing)
   - Read file context around error line
   - Fix the syntax error
   - Re-run get_errors to verify fix
4. Only after get_errors shows no syntax errors, continue
```

**Example:**
```python
# After editing Chat.lua:
multi_replace_string_in_file([...])  # Make changes
get_errors(["source/ElvUIChat/Core/Modules/Chat/Chat.lua"])  # VALIDATE
# If errors found → fix → get_errors again
# If no syntax errors → continue with next task
```

**Why this matters:**
- Prevents runtime crashes in WoW
- Catches missing `end` statements immediately
- Finds mismatched conditionals (`if`/`else`/`elseif` without pairs)
- Saves time debugging in-game

### Updating from ElvUI Source

**DO NOT overwrite blindly** - Follow this pattern:

1. **Backup current file**:
   ```powershell
   Copy-Item source\ElvUIChat\Core\Modules\Chat\Chat.lua source\ElvUIChat\Core\Modules\Chat\Chat.lua.backup
   ```

2. **Copy from origin**:
   ```powershell
   Copy-Item OriginSource\ElvUI\Game\Shared\Modules\Chat\Chat.lua source\ElvUIChat\Core\Modules\Chat\Chat.lua
   ```

3. **Fix namespace & remove Classic code** (PowerShell):
   ```powershell
   # Basic namespace replacements
   (Get-Content "source\ElvUIChat\Core\Modules\Chat\Chat.lua" -Raw) `
     -replace 'unpack\(ElvUI\)','unpack(ElvUIChat)' `
     -replace 'ElvCharacterDB','ElvUIChatCharacterDB' `
     | Set-Content "source\ElvUIChat\Core\Modules\Chat\Chat.lua" -NoNewline
   
   # Then manually review and remove:
   # - Classic/TBC/Wrath/Cata/Mists conditional blocks
   # - Seasonal variant checks (SOD, HC, Anniversary)
   # - Simplify "if E.Retail then" blocks to just the code inside
   ```

4. **Verify no broken module references**:
   ```powershell
   # Should only find: Chat, Layout, Skins (maybe Blizzard, AFK)
   Select-String "E:GetModule\(" source\ElvUIChat\Core\Modules\Chat\Chat.lua
   ```

### Files to Sync During Updates

| OriginSource Location | Our Location | Action |
|----------------------|--------------|--------|
| `ElvUI_Mainline.toc` | `ElvUIChat.toc` | Copy Interface version only |
| `Game/Shared/Modules/Chat/Chat.lua` | `Core/Modules/Chat/Chat.lua` | Copy + namespace fix |
| `Game/Mainline/Skins/Battlenet.lua` | `Skins/Battlenet.lua` | Copy + namespace fix |
| `Game/Mainline/Skins/ChatConfig.lua` | `Skins/ChatConfig.lua` | Copy + namespace fix |
| `Game/Mainline/Skins/CombatLog.lua` | `Skins/CombatLog.lua` | Copy + namespace fix |

**Never sync**: ActionBars, UnitFrames, NamePlates, DataTexts, DataBars, Bags, Minimap, Tooltip, etc.

## Project Conventions

### Module Initialization (Core/init.lua)

We only create these modules:
```lua
E.AFK = E:NewModule('AFK','AceEvent-3.0','AceTimer-3.0')
E.Blizzard = E:NewModule('Blizzard','AceEvent-3.0','AceHook-3.0')
E.Chat = E:NewModule('Chat','AceTimer-3.0','AceHook-3.0','AceEvent-3.0')
E.Layout = E:NewModule('Layout','AceEvent-3.0')
E.Skins = E:NewModule('Skins','AceTimer-3.0','AceHook-3.0','AceEvent-3.0')
```

**Do not add**: ActionBars, UnitFrames, NamePlates, DataTexts, DataBars, Bags, Minimap, Tooltip, etc.

**Expansion Detection (Retail-only simplified):**

Since we only support Retail, `init.lua` can be simplified to:
```lua
E.Retail = true
E.Classic = false
E.TBC = false
E.Wrath = false
E.Cata = false
E.Mists = false
```

No need for seasonal detection (SOD, HC, Anniversary, etc.).

### Libraries Used
```lua
E.Libs.LSM        // LibSharedMedia-3.0
E.Libs.AceDB      // AceDB-3.0
E.Libs.ACH        // LibAceConfigHelper
E.Libs.ACL        // AceLocale-3.0-ElvUIChat (note suffix!)
E.Libs.Deflate    // LibDeflate
E.Libs.SimpleSticky  // LibSimpleSticky-1.0
E.Libs.DualSpec   // LibDualSpec-1.0
```

### Common Patterns
```lua
// Unpack pattern (top of EVERY file)
local E, L, V, P, G = unpack(ElvUIChat)

// Get modules
local CH = E:GetModule('Chat')
local LO = E:GetModule('Layout')
local S = E:GetModule('Skins')

// Colors
E.InfoColor   = '|cff1784d1'  // Blue
E.InfoColor2  = '|cff9b9b9b'  // Silver

// Database access
CH.db         // Profile settings for Chat
E.db.chat     // Also profile settings
E.global      // Global settings
E.private     // Private settings
```

### Helper Functions Available

Modern ElvUIChat includes these in `Core/init.lua`:

```lua
E:ParseVersionString(addon)              // Parse addon version from metadata
E:SetCVar(cvar, value)                   // Safe CVar setter with boolean handling
E:GetAddOnEnableState(addon, character)  // Wrapper for C_AddOns function
E:IsAddOnEnabled(addon)                  // Check if addon enabled for player
E:AddonCompartmentFunc()                 // Handler for addon compartment (11.0+)
E:EscapeString(s)                        // Escape special pattern characters
E:StripString(s, ignoreTextures)         // Strip formatting codes
```

## Suggested Workflows

### Code Search & Validation
```powershell
# VALIDATE SYNTAX AFTER EDITS (critical!)
get_errors(filePaths: ["path/to/edited/file.lua"])

# Find all module references (should only be Chat, Layout, Skins, Blizzard, AFK)
Select-String "E:GetModule\(" source\ElvUIChat\**\*.lua

# Find database usage
Select-String "ElvUIChatDB|ElvUIChatPrivateDB|ElvUIChatCharacterDB" source\ElvUIChat\**\*.lua

# Check TOC version
Select-String "Interface:" source\ElvUIChat\ElvUIChat.toc

# Find potential namespace issues
Select-String "unpack\(ElvUI\)" source\ElvUIChat\**\*.lua  # Should find NONE
Select-String "ElvCharacterDB[^a-zA-Z]" source\ElvUIChat\**\*.lua  # Should find NONE
```

### Git Workflow Suggestions
```powershell
# Before major updates, create a branch
git checkout -b update-midnight-$(Get-Date -Format "yyyy-MM-dd")

# Commit checkpoints during multi-phase updates
git add source/ElvUIChat/ElvUIChat.toc source/ElvUIChat/Core/init.lua
git commit -m "Phase 2: Update TOC and Core for Midnight (Interface 120000)"

git add source/ElvUIChat/Core/Modules/Chat/Chat.lua
git commit -m "Phase 3: Update Chat.lua module (4191 lines)"

git add source/ElvUIChat/Skins/
git commit -m "Phase 4: Update chat skins"

# Tag successful updates
git tag -a v15.03-midnight -m "Updated to Midnight (11.2.0) Interface 120000"
```

### Quick Testing Cycle
```powershell
# 1. Deploy addon
.\build\deploy.ps1

# 2. Launch WoW
Start-Process "D:\Games\World of Warcraft\_retail_\Wow.exe"

# 3. In-game checks:
#    /console scriptErrors 1
#    /reload
#    /elvuichat
#    Test chat features (copy, timestamps, links, colors)
```

### Testing In-Game

After changes:
1. Check Lua errors on load (use BugSack addon or `/console scriptErrors 1`)
2. Test `/elvuichat` command opens config
3. Verify chat windows display and are movable
4. Check chat features: copy button, timestamps, URL links, tab flashing
5. Test chat edit history (up/down arrows in chat box)

## Critical Gotchas

1. **Lua Language Server Warnings**: Ignore undefined global warnings for WoW API (they're defined at runtime)
2. **SetCVar**: Modern API only takes 2 args `(cvar, value)`, not 3
3. **WorldFrame vs UIParent**: Tooltips use WorldFrame; UI frames use UIParent
4. **Character DB timing**: `ElvUIChatCharacterDB` may not exist until `OnInitialize` - always check/create
5. **Namespace confusion**: Remember ElvUI → ElvUIChat in ALL files when copying from OriginSource
6. **Over-including**: Don't pull in code that references modules we don't have (UnitFrames, ActionBars, etc.)
7. **Profile reset handlers**: Call `E:ResetProfile()` or `E:ResetPrivateProfile()`, not StaticPopup directly

## Debugging Common Issues

**Module not found:**
- Check for nil references to missing modules
- Verify all `E:GetModule()` calls only reference: Chat, Layout, Skins, Blizzard, AFK

**We only support Retail - no need for version checks:**
- All modern Midnight (11.2.0+) APIs should be available
- If an API is missing, check WoW patch notes or use wowlab MCP tools

**Chat module not initializing:**
- Check `E.Chat.Initialized` is true
- Test `/elvuichat` command opens config

## Reference Documentation

- Update tracking: `/UPDATE-PLAN.md` - Current migration status and task list
- WoW API: Use wowlab MCP tools for lookups
- ElvUI source: `/OriginSource/ElvUI/` (reference only, don't modify)

## Quick Commands
```powershell
# VALIDATE SYNTAX (run after every edit!)
get_errors(filePaths: ["path/to/edited/file.lua"])

# Find module references
Select-String "E:GetModule" source/**/*.lua

# Find database usage
Select-String "ElvUIChat.*DB" source/**/*.lua

# Check TOC version
Select-String "Interface:" source/ElvUIChat/ElvUIChat.toc

# Deploy addon
.\build\deploy.ps1
# Or: Ctrl+Shift+B → Deploy ElvUIChat
```

---

**Remember**: This is a chat-focused subset of ElvUI for **Retail only**. When updating, always ask: "Does this affect the chat window?" If no, don't include it.
