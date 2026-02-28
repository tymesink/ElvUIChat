## Plan: AceConfig-Based Options UI

TL;DR: Replace the custom ElvUI_Options-style frame with the standard AceConfig/AceConfigDialog + Blizzard AddOns panel, wire all existing chat settings from defaults, and keep slash commands opening the plain options. This removes reliance on the external ElvUI_Options folder and keeps the UI lightweight.

**Current State (as of review)**
- Steps 1, 2, 5, 7 are already complete: `E.Options` is set up, `RegisterOptionsTable('ElvUIChat', ...)` is called, the full chat options table exists in Options.lua, slash commands are registered in Core.lua, and defaults are aligned.
- Steps 3, 4, 6 are the remaining work.

**Steps**
1. ~~Wire core registration to the default AceConfig flow~~ **DONE** — `E.Options` setup and lib references are correct in init.lua; `RegisterOptionsTable('ElvUIChat', E.Options)` is called in `E:LoadConfigOptions()`.
2. ~~Build/verify the full chat options table~~ **DONE** — All groups (`general`, `historyGroup`, `fadingGroup`, `alerts`, `timestampGroup`, `panels`, etc.) exist in Options.lua with correct ACH helpers and DB paths.
3. Register with Blizzard's AddOns panel: in `E:LoadConfigOptions()` in source/ElvUIChat/Core/General/Options.lua, add `AceConfigDialog:AddToBlizOptions('ElvUIChat', 'ElvUIChat')` after the `RegisterOptionsTable` call.
4. Wire the invocation point — **CRITICAL, currently missing**: `E:LoadConfigOptions()` is defined but never called anywhere. With ElvUI_Options removed, nothing triggers it. Add a call to `E:LoadConfigOptions()` inside `E:Initialize()` in source/ElvUIChat/Core/General/Core.lua (after `E.data` and `E.charSettings` are set up).
5. Fix wrong AceConfig key throughout Config.lua — **CRITICAL**: multiple functions use `'ElvUI'` as the dialog key instead of `'ElvUIChat'`. All must be updated:
   - `E:Config_CloseWindow()` — `ACD:Close('ElvUI')` → `ACD:Close('ElvUIChat')`
   - `E:Config_OpenWindow()` — `ACD:Open('ElvUI')` → `ACD:Open('ElvUIChat')`
   - `E:Config_GetWindow()` — `ACD.OpenFrames.ElvUI` → `ACD.OpenFrames.ElvUIChat`
   - Config.lua:609 — `SetDefaultSize('ElvUI', ...)` → `SetDefaultSize('ElvUIChat', ...)`
6. Simplify `E:ToggleOptions` in source/ElvUIChat/Core/General/Config.lua: remove the `ElvUI_Options` load/check block; replace with a simple open/close toggle against `'ElvUIChat'`. Preserve the `ShowPopup`/`CONFIG_RL` reload prompt — settings like `private.chat.enable` and voice buttons set `E.ShowPopup = true`, which must trigger the reload popup when the dialog closes. Keep the `Config_WindowClosed` hook (or equivalent) wired to the `'ElvUIChat'` dialog.
7. ~~Keep slash commands~~ **DONE** — `/elvuichat` and `/ec` are already registered in Core.lua and call `ToggleOptions`.
8. Remove dead Config.lua infrastructure — **required, not optional**: strip the mover/grid/nudge code (`ToggleMoveMode`, `Grid_Create/Show/Hide`, `CreateMoverPopup`, `MoverNudgeFrame`, ~400 lines) which references functions that don't exist in this addon (`E:ToggleMovers`, `E:ResetMovers`, `E:ResetUI`, etc.) and will hard-error if invoked.
9. Clean up `ElvUI_Options` references in StaticPopups.lua:
   - Line ~249: UF reset block references `IsAddOnLoaded('ElvUI_Options')` and `UF` module — delete the entire conditional since UnitFrames don't exist.
   - Line ~398: strata boost block checks `IsAddOnLoaded('ElvUI_Options')` — simplify to check `ACD.OpenFrames['ElvUIChat']` directly instead.
10. Remove dead reference in Options.lua: `C.StateSwitchGetText` (line 51) references `E.global.unitframe.specialFilters` which doesn't exist. This function is only used for UnitFrame aura filter display — remove it.
11. ~~Defaults alignment~~ **DONE** — verified against Profile.lua, Private.lua, Global.lua.
12. Testing: open via `/elvuichat`, Interface → AddOns, and `/ec`; toggle key settings (history, timestamps, copy button, panels, class color mentions, alerts) to confirm they persist and apply immediately; verify no errors on load or open.

**Verification**
- Open options via `/elvuichat` and Interface → AddOns; ensure AceConfig dialog appears without pulling ElvUI_Options.
- Toggle representative settings and confirm visual/apply changes in chat.
- Toggle a reload-required setting (e.g., Chat Enable) and confirm the reload popup appears when closing the dialog.
- Reload UI to confirm persistence (settings saved to profile/private/global as appropriate).

**Decisions**
- Use plain AceConfig/AceConfigDialog + Blizzard AddOns panel (no external ElvUI_Options dependency).
- Cover the full chat settings set already present in defaults, not a reduced MVP.
- Keep `Config_WindowClosed` reload prompt mechanism intact.
- Treat Config.lua mover infrastructure removal as required, not optional.
