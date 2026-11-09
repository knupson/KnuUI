local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')
local pending, applying

local function Settings()
 local t = K:GetTheme()
 -- _ref/ElvUI/Game/Shared/Defaults/Profile.lua:1400-1513: claves reales de chat.
 K.Set(E.db.chat, {
  panelBackdrop = 'SHOWBOTH', panelTabBackdrop = true, panelTabTransparency = false,
  panelBackdropNameLeft = '', panelBackdropNameRight = '',
  panelColor = { r = t.backdropFade.r, g = t.backdropFade.g, b = t.backdropFade.b, a = t.backdropFade.a },
  font = 'Expressway', fontSize = 12, fontOutline = 'OUTLINE',
  tabFont = 'Expressway', tabFontSize = 12, tabFontOutline = 'OUTLINE',
  tabSelectedTextEnabled = true, tabSelectedTextColor = t.accent,
  tabSelectorColor = t.accent, fadeTabsNoBackdrop = false,
 })
end

local function FixChatTabs()
 -- Todas las pestañas con el mismo alto de texto: sin salto de línea y centradas igual que las
 -- deja ElvUI (Modules/Chat/Chat.lua:1034-1038). Un nombre largo se corta con "..." en una línea.
 for i = 1, (_G.NUM_CHAT_WINDOWS or 10) do
  local tab = _G['ChatFrame'..i..'Tab']
  local text = tab and tab.Text
  if text then
   if text.SetWordWrap then text:SetWordWrap(false) end
   if text.SetNonSpaceWrap then text:SetNonSpaceWrap(false) end
   if text.SetMaxLines then text:SetMaxLines(1) end
   text:SetJustifyV('MIDDLE')
   text:ClearAllPoints()
   text:SetPoint('CENTER', tab, 'CENTER', 0, -1)
  end
 end
end

local function Style()
 Settings()
 FixChatTabs()
 local t = K:GetTheme()
 -- Layout/Layout.lua:214-234,273-298,337-415: panel.backdrop y paneles de pestañas.
 for _, side in ipairs({ 'Left', 'Right' }) do
  local panel, tab = _G[side..'ChatPanel'], _G[side..'ChatTab']
  if panel and panel.backdrop then
   panel.backdrop:SetBackdropColor(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, t.backdropFade.a)
   panel.backdrop:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
  end
  if tab then
   tab:SetTemplate('Default')
   tab:SetBackdropColor(t.backdrop.r, t.backdrop.g, t.backdrop.b, 1)
   tab:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
   if not tab.KnuLine then
    tab.KnuLine = tab:CreateTexture(nil, 'OVERLAY')
    tab.KnuLine:SetPoint('BOTTOMLEFT', tab, 'BOTTOMLEFT', 1, 0)
    tab.KnuLine:SetPoint('BOTTOMRIGHT', tab, 'BOTTOMRIGHT', -1, 0)
    tab.KnuLine:SetHeight(1)
   end
   tab.KnuLine:SetColorTexture(t.accentDim.r, t.accentDim.g, t.accentDim.b, 0.8)
  end
 end
end

function K:RefreshPanels()
 if not E.Forever then return false end
 if InCombatLockdown() then pending = true; return false end
 if applying then return false end
 applying = true
 local ok, err = pcall(Style)
 applying = false
 if not ok then E:Print(format(L["KnuUI: could not update the panels: %s"], tostring(err))) end
 return ok
end

function K:ApplyIntegratedPanels()
 if not self:CanApply() then return false end
 self:RefreshPanels()
 local layout, chat = E:GetModule('Layout'), E:GetModule('Chat')
 -- Layout/Layout.lua:214,273,282; Chat/Chat.lua:1490,1620,2918.
 for _, method in ipairs({ 'SetChatTabStyle', 'ToggleChatPanels', 'RepositionChatDataPanels' }) do
  if type(layout[method]) == 'function' then layout[method](layout) end
 end
 if type(chat.PositionChats) == 'function' then chat:PositionChats() end
 if type(chat.UpdateChatTabs) == 'function' then chat:UpdateChatTabs() end
 -- SetChatFont actualiza también el editbox; CHAT_FRAMES: Chat.lua:1163,1656.
 for _, name in ipairs(_G.CHAT_FRAMES or {}) do
  if _G[name] and type(chat.SetChatFont) == 'function' then chat:SetChatFont(nil, _G[name], 12) end
 end
 self:RefreshPanels()
 self:RefreshDock()
 self:RefreshDecor()
 return true
end

function K:SetupPanels()
 local events = CreateFrame('Frame')
 events:RegisterEvent('PLAYER_ENTERING_WORLD')
 events:RegisterEvent('PLAYER_REGEN_ENABLED')
 events:SetScript('OnEvent', function(_, event)
  if InCombatLockdown() then pending = true; return end
  if event ~= 'PLAYER_REGEN_ENABLED' or pending or K.detailsSkinPending then
   pending, K.detailsSkinPending = false, false
   K:ApplyIntegratedPanels()
  end
 end)
 for name, methods in pairs({
  Layout = { 'SetChatTabStyle', 'ToggleChatPanels', 'RepositionChatDataPanels', 'UpdatePanelTextures' },
  Chat = { 'Panels_ColorUpdate', 'PositionChats' }, -- Chat.lua:1646; Layout.lua:322.
 }) do
  local mod = E:GetModule(name, true)
  if mod then
   for _, method in ipairs(methods) do
    if type(mod[method]) == 'function' then hooksecurefunc(mod, method, function() K:RefreshPanels() end) end
   end
  end
 end
 self:RefreshPanels()
end
