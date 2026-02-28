-- English localization file for enUS and enGB.
local E = unpack(ElvUIChat)
local L = E.Libs.ACL:NewLocale('ElvUIChat', 'enUS', true, true)

L["LOGIN_MSG"] = ("Welcome to *ElvUIChat|r version *%.2f|r, type */ec|r to access the in-game configuration menu."):gsub('*', E.InfoColor)

