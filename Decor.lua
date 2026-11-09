local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')
local MEDIA = [[Interface\AddOns\KnuUI\media\]]
local decorated = {}
local pending, applying

-- Texturas/plantillas: _ref/ElvUI/Game/Shared/General/Toolkit.lua:294,410-434,526.
-- Cada adorno es propio: apagarlo no oculta sombras de otros módulos.
local function Overlay(frame)
 local record = decorated[frame]
 if record then return record end
 local layer = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
 layer:SetAllPoints(frame)
 layer:SetFrameLevel(frame:GetFrameLevel() + 5)
 record = { layer = layer, textures = {} }
 decorated[frame] = record
 return record
end

local function Texture(record, key, file)
 if not record.textures[key] then
  local texture = record.layer:CreateTexture(nil, 'OVERLAY')
  texture:SetTexture(MEDIA..file)
  record.textures[key] = texture
 end
 return record.textures[key]
end

local function Corners(frame, size, alpha)
 if not frame then return end
 local record, t = Overlay(frame), K:GetTheme()
 for i, point in ipairs({ 'TOPLEFT', 'TOPRIGHT', 'BOTTOMLEFT', 'BOTTOMRIGHT' }) do
  local corner = Texture(record, point, 'esquina')
  corner:SetSize(size, size)
  corner:SetPoint(point, record.layer, point, 0, 0)
  -- Esquina base arriba/izquierda; reflejos para las otras tres esquinas.
  -- SetTexCoord: _ref/ElvUI/Game/Shared/Modules/Skins/Skins.lua:144.
  local left, right = (i == 2 or i == 4) and 1 or 0, (i == 2 or i == 4) and 0 or 1
  local top, bottom = i >= 3 and 1 or 0, i >= 3 and 0 or 1
  corner:SetTexCoord(left, right, top, bottom)
  corner:SetVertexColor(t.accent.r, t.accent.g, t.accent.b, alpha)
 end
end

local function Shadow(frame)
 if not frame or type(frame.CreateShadow) ~= 'function' then return end
 local record = Overlay(frame)
 if not record.shadow then record.shadow = frame:CreateShadow(3, true) end
 if record.shadow then record.shadow:SetAlpha(0.25); record.shadow:Show() end
end

local function TopLine(frame)
 if not frame then return end
 local record, t = Overlay(frame), K:GetTheme()
 local line = Texture(record, 'line', 'brillo')
 line:SetPoint('TOPLEFT', frame, 'TOPLEFT', 1, 0)
 line:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -1, 0)
 line:SetHeight(1)
 line:SetVertexColor(t.accent.r, t.accent.g, t.accent.b, 0.8)
end

local function ZoneText()
 if InCombatLockdown() then pending = true; return end
 if E.db.KnuUIDecor == false then return end
 -- Minimap.location: Modules/Maps/Minimap.lua:333-340,893-896 (ya anclado arriba).
 local text = _G.Minimap and _G.Minimap.location
 if not text then return end
 local t = K:GetTheme()
 text:FontTemplate('Expressway', E.db.general.minimap.locationFontSize, E.db.general.minimap.locationFontOutline)
 text:SetTextColor(t.text.r, t.text.g, t.text.b)
 text:Show()
end

local function WorldMap()
 -- Skins/WorldMap.lua:196-203,316-322,523-529: skin moderna y backdrop de ElvUI.
 local map = _G.WorldMapFrame
 local backdrop = map and map.backdrop
 if not backdrop then return end
 local record, t = Overlay(backdrop), K:GetTheme()
 record.layer:SetBackdrop({ edgeFile = E.Media.Textures.White8x8, edgeSize = 1 })
 record.layer:SetBackdropBorderColor(t.accentDim.r, t.accentDim.g, t.accentDim.b, 0.8)
 if not record.title then
  -- Rótulo propio: la referencia moderna no expone un TitleText del mapa.
  record.title = record.layer:CreateFontString(nil, 'OVERLAY')
  record.title:SetPoint('BOTTOM', backdrop, 'TOP', 0, 2)
  record.title:FontTemplate('Expressway', 12, 'OUTLINE')
  record.title:SetText(L["World map"])
 end
 record.title:SetTextColor(t.text.r, t.text.g, t.text.b)
end

local function Style()
 local enabled = E.db.KnuUIDecor ~= false
 for _, record in pairs(decorated) do
  record.layer:SetShown(enabled)
  if record.shadow then record.shadow:SetShown(enabled) end
 end
 if not enabled then return end
 local t = K:GetTheme()
 local minimap = _G.Minimap
 if minimap then
  -- SetMinimapMask: Modules/Maps/Minimap.lua:728-734; no modifica el mover.
  local maps = E:GetModule('Minimap', true)
  if maps and type(maps.SetMinimapMask) == 'function' then maps:SetMinimapMask(true) end
  local frame = minimap.backdrop or minimap
  local record = Overlay(frame)
  record.layer:SetBackdrop({ edgeFile = E.Media.Textures.White8x8, edgeSize = 1 })
  record.layer:SetBackdropBorderColor(t.accent.r, t.accent.g, t.accent.b, 0.8)
  Corners(frame, 20, 0.8)
  Shadow(frame)
  ZoneText()
 end
 -- MinimapPanel: Modules/Maps/Minimap.lua:600; franjas repetibles como Afk.lua.
 local panel = _G.MinimapPanel
 if panel then
  local record = Overlay(panel)
  local stripes = Texture(record, 'stripes', 'franjas')
  stripes:SetTexture(MEDIA..'franjas', 'REPEAT', 'CLAMP')
  stripes:SetHorizTile(true)
  -- Debajo del panel de datos, con 2 px de aire: no tapa hora ni coordenadas.
  stripes:SetPoint('TOPLEFT', panel, 'BOTTOMLEFT', 1, -2)
  stripes:SetPoint('TOPRIGHT', panel, 'BOTTOMRIGHT', -1, -2) -- ancho completo; el botón K va más abajo
  stripes:SetHeight(6)
  stripes:SetAlpha(0.45)
  local glow = Texture(record, 'glow', 'brillo')
  glow:SetPoint('TOPLEFT', stripes, 'BOTTOMLEFT', -1, -1)
  glow:SetPoint('TOPRIGHT', stripes, 'BOTTOMRIGHT', 1, -1)
  glow:SetHeight(8)
  glow:SetVertexColor(t.accent.r, t.accent.g, t.accent.b, 0.5)
 end
 -- Layout/Layout.lua:337,391; DataTexts/DataTexts.lua:140-156 (nombres dinámicos).
 TopLine(_G.LeftChatPanel)
 TopLine(_G.RightChatPanel)
 local dt = E:GetModule('DataTexts', true)
 TopLine(dt and dt.PanelPool and dt.PanelPool.InUse and dt.PanelPool.InUse.KnuUI_Data)
 -- UnitFrames/UnitFrames.lua:905; ActionBars/ActionBars.lua:413-414.
 for _, name in ipairs({ 'ElvUF_Player', 'ElvUF_Target', 'KnuUI_ManaTank' }) do
  local frame = _G[name]
  if frame then Corners(frame, 12, 0.5); Shadow(frame) end
 end
 for i = 1, 6 do Shadow(_G['ElvUI_Bar'..i]) end
 WorldMap()
end

function K:RefreshDecor()
 if InCombatLockdown() then pending = true; return false end
 if applying then return false end
 applying = true
 local ok, err = pcall(Style)
 applying = false
 if not ok then E:Print(format(L["KnuUI: could not refresh the decoration: %s"], tostring(err))) end
 return ok
end

function K:ToggleDecor()
 if not self:CanApply() then return false end
 E.db.KnuUIDecor = E.db.KnuUIDecor == false
 self:RefreshDecor()
 -- Restaura máscara/fuente/color mediante los setters originales de ElvUI.
 if not E.db.KnuUIDecor then
  local maps = E:GetModule('Minimap', true)
  if maps then
   if type(maps.SetMinimapMask) == 'function' then maps:SetMinimapMask(not E.db.general.minimap.circle) end
   if type(maps.UpdateSettings) == 'function' then maps:UpdateSettings() end
   if type(maps.Update_ZoneText) == 'function' then maps:Update_ZoneText() end
  end
 end
 return true
end

function K:SetupDecor()
 if E.db.KnuUIDecor == nil then E.db.KnuUIDecor = true end
 local events = CreateFrame('Frame')
 events:RegisterEvent('PLAYER_ENTERING_WORLD')
 events:RegisterEvent('ADDON_LOADED')
 events:RegisterEvent('PLAYER_REGEN_ENABLED')
 events:SetScript('OnEvent', function(_, event)
  if event ~= 'PLAYER_REGEN_ENABLED' or pending then pending = false; K:RefreshDecor() end
 end)
 -- Ganchos reales; el bloqueo de combate se aplica antes de crear o cambiar marcos.
 for name, methods in pairs({
  Minimap = { 'UpdateSettings', 'Update_ZoneText', 'Minimap_EnterLeave' }, -- Minimap.lua:262-265
  DataTexts = { 'LoadDataTexts' },
  UnitFrames = { 'Update_AllFrames' }, -- UnitFrames.lua:868
  Skins = { 'WorldMapFrame' },
 }) do
  local mod = E:GetModule(name, true)
  if mod then
   for _, method in ipairs(methods) do
    if type(mod[method]) == 'function' then
     hooksecurefunc(mod, method, (method == 'Update_ZoneText' or method == 'Minimap_EnterLeave') and ZoneText or function() K:RefreshDecor() end)
    end
   end
  end
 end
 self:RefreshDecor()
 if C_Timer and type(C_Timer.After) == 'function' then C_Timer.After(2, function() K:RefreshDecor() end) end
end
