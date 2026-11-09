local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')
local ICON = [[Interface\AddOns\KnuUI\media\icono64]]
local PAGE_SIZE = 10

-- Conserva las seis acciones anteriores; toda acción se rechaza en combate.
-- addons/ElvUI_SLE/modules/uibuttons.lua:24,33,51,60 (opciones, addons, ausente, dados).
-- _ref/ElvUI/Game/Shared/General/Config.lua:1619 (ToggleOptions).
local function Actions()
 return {
  { label = L["ElvUI settings"], glyph = 'C', click = function() E:ToggleOptions() end },
  { label = L["Addon list"], glyph = 'A', click = function()
   if not AddonList then return end
   local toggle = AddonList:IsShown() and HideUIPanel or ShowUIPanel
   if type(toggle) == 'function' then toggle(AddonList) end
  end },
  { label = L["Toggle AFK"], glyph = 'S', click = function() SendChatMessage('', 'AFK') end },
  { label = L["Roll dice from 1 to 100"], glyph = 'R', click = function() RandomRoll(1, 100) end },
  { label = L["Reload UI"], glyph = 'UI', click = function() ReloadUI() end },
  { label = L["KnuUI installer"], icon = ICON, click = function() K:OpenInstaller() end },
 }
end

function K:StyleButtons()
 if not self.buttons or InCombatLockdown() then return end
 local t = self:GetTheme()
 for _, frame in ipairs({ self.buttons, self.flyout }) do
  frame:SetBackdropColor(t.backdrop.r, t.backdrop.g, t.backdrop.b, 0.97)
  frame:SetBackdropBorderColor(t.accent.r, t.accent.g, t.accent.b)
 end
 for _, row in ipairs(self.flyout.rows) do
  row.label:SetTextColor(t.text.r, t.text.g, t.text.b)
  row.glyph:SetTextColor(t.accent.r, t.accent.g, t.accent.b)
  row.highlight:SetColorTexture(t.accent.r, t.accent.g, t.accent.b, 0.16)
 end
end

function K:RefreshLauncher()
 if not self.flyout or InCombatLockdown() then return end
 local entries, names = Actions(), {}
 for name in pairs(self.launcherAddons or {}) do names[#names + 1] = name end
 table.sort(names)
 for _, name in ipairs(names) do entries[#entries + 1] = self.launcherAddons[name] end
 local panel = self.flyout
 local pages = math.max(1, math.ceil(#entries / PAGE_SIZE))
 panel.page = math.min(panel.page or 1, pages)
 for i, row in ipairs(panel.rows) do
  local entry = entries[(panel.page - 1) * PAGE_SIZE + i]
  row.entry = entry
  row:SetShown(entry ~= nil)
  if entry then
   row.label:SetText(entry.label)
   row.icon:SetTexture(entry.icon or ICON)
   row.icon:SetShown(not entry.glyph)
   row.glyph:SetText(entry.glyph or '')
  end
 end
 local count = math.min(PAGE_SIZE, #entries - (panel.page - 1) * PAGE_SIZE)
 panel:SetHeight(12 + count * 26 + (pages > 1 and 26 or 0))
 panel.previous:SetShown(pages > 1)
 panel.next:SetShown(pages > 1)
 panel.previous:SetText(L["‹ Previous"])
 panel.next:SetText(format(L["%d/%d · Next ›"], panel.page, pages))
 panel.pages = pages
 self:StyleButtons()
end

function K:SetupButtons()
 if self.buttons then return end
 if InCombatLockdown() then
  if not self.buttonsWait then
   self.buttonsWait = CreateFrame('Frame')
   self.buttonsWait:RegisterEvent('PLAYER_REGEN_ENABLED')
   self.buttonsWait:SetScript('OnEvent', function(frame)
    frame:UnregisterEvent('PLAYER_REGEN_ENABLED')
    K.buttonsWait = nil
    K:SetupButtons()
   end)
  end
  return
 end
 local button = CreateFrame('Button', 'KnuUI_Buttons', E.UIParent)
 self.buttons = button
 button:SetSize(26, 24)
 button:SetPoint('TOPRIGHT', E.UIParent, 'TOPRIGHT', -8, -212)
 button:SetTemplate('Default')
 local icon = button:CreateTexture(nil, 'ARTWORK')
 icon:SetTexture(ICON)
 icon:SetSize(22, 22)
 icon:SetPoint('CENTER')
 -- Escape y límite de pantalla: _ref/ElvUI/Game/Shared/General/Dropdown.lua:63-66.
 local panel = CreateFrame('Frame', 'KnuUI_LauncherPanel', E.UIParent)
 self.flyout = panel
 panel:SetWidth(260)
 panel:SetPoint('TOPRIGHT', button, 'BOTTOMRIGHT', 0, -4)
 panel:SetFrameStrata('DIALOG')
 panel:SetClampedToScreen(true)
 panel:SetTemplate('Default')
 panel:Hide()
 -- Sólo opacidad, 150 ms y curva cúbica ease-out. No hay una opción global de
 -- movimiento reducido en Defaults/Profile.lua ni Defaults/Private.lua de ElvUI 16.01.
 local elapsedFade = 0
 panel:SetScript('OnShow', function(self)
  elapsedFade = 0
  self:SetAlpha(0)
  self:SetScript('OnUpdate', function(frame, elapsed)
   elapsedFade = math.min(elapsedFade + elapsed, 0.15)
   local remaining = 1 - elapsedFade / 0.15
   frame:SetAlpha(1 - remaining * remaining * remaining)
   if elapsedFade >= 0.15 then frame:SetScript('OnUpdate', nil) end
  end)
 end)
 panel:SetScript('OnHide', function(self)
  self:SetScript('OnUpdate', nil)
  self:SetAlpha(1)
 end)
 table.insert(UISpecialFrames, 'KnuUI_LauncherPanel')
 panel.rows = {}
 for i = 1, PAGE_SIZE do
  local row = CreateFrame('Button', nil, panel)
  row:SetSize(248, 26)
  row:SetPoint('TOPLEFT', panel, 'TOPLEFT', 6, -6 - (i - 1) * 26)
  row.highlight = row:CreateTexture(nil, 'HIGHLIGHT')
  row.highlight:SetAllPoints()
  row.icon = row:CreateTexture(nil, 'ARTWORK')
  row.icon:SetSize(18, 18)
  row.icon:SetPoint('LEFT', row, 'LEFT', 4, 0)
  row.glyph = row:CreateFontString(nil, 'OVERLAY')
  row.glyph:FontTemplate('Expressway', 11)
  row.glyph:SetPoint('CENTER', row.icon, 'CENTER')
  row.label = row:CreateFontString(nil, 'OVERLAY')
  row.label:FontTemplate('Expressway', 12)
  row.label:SetPoint('LEFT', row, 'LEFT', 30, 0)
  row.label:SetWidth(212)
  row.label:SetJustifyH('LEFT')
  row:SetScript('OnClick', function(self)
   panel:Hide()
   if not self.entry or not K:CanApply() then return end
   -- El renglón es el botón sustituto para OnClick de LDB.
   local ok = pcall(self.entry.click, self)
   if not ok then E:Print(L["KnuUI: could not open that action; check the corresponding addon."]) end
  end)
  panel.rows[i] = row
 end
 for _, direction in ipairs({ 'previous', 'next' }) do
  local nav = CreateFrame('Button', nil, panel, 'UIPanelButtonTemplate')
  panel[direction] = nav
  nav:SetSize(122, 22)
  nav:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', direction == 'previous' and 6 or 132, 5)
  nav:SetScript('OnClick', function()
   panel.page = direction == 'previous' and math.max(1, panel.page - 1) or math.min(panel.pages, panel.page + 1)
   K:RefreshLauncher()
  end)
 end
 button:SetScript('OnClick', function()
  if panel:IsShown() then panel:Hide(); return end
  if not K:CanApply() then return end
  K:ScanMinimapButtons()
  K:RefreshLauncher()
  panel:Show()
 end)
 E:CreateMover(button, 'KnuUI_ButtonsMover', L["KnuUI launcher"], nil, nil, nil, 'ALL', nil, 'KnuUI')
 self:RefreshLauncher()
 self:SetupMinimapButtons()
end
