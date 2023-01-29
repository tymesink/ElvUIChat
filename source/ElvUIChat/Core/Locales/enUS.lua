-- English localization file for enUS and enGB.
local E = unpack(ElvUIChat)
local L = E.Libs.ACL:NewLocale('ElvUIChat', 'enUS', true, true)

L["LOGIN_MSG"] = ("Welcome to *ElvUIChat|r version *%.2f|r, type */ec|r to access the in-game configuration menu."):gsub('*', E.InfoColor)

----------------------------------
L["DESC_MOVERCONFIG"] = [=[Movers unlocked. Move them now and click Lock when you are done.

Options:
  LeftClick - Toggle Nudge Frame.
  RightClick - Open Config Section.
  Shift + RightClick - Hides mover temporarily.
  Ctrl + RightClick - Resets mover position to default.
]=]