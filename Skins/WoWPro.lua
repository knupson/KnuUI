local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')
local hooked = {}
local pending, applying

-- Fuentes relativas a D:/World of Warcraft/_forever_/Interface/AddOns/.
-- WoWPro/WoWPro_Frames.lua:1004,1348,1492,1545,1634,1647,1691,1716,1742,2436:
-- MainFrame, ButtonBar, TitleBar, StickyHeader, GuideFrame, Scrollbar y rows.
-- Esta versión no crea StickyFrame ni ScrollFrame: usa StickyHeader y GuideFrame.
-- WoWPro/WoWPro_RowUpdate.lua:67-95,1369 cambia fuentes/colores y refresca filas.
-- WoWPro/WoWPro.lua:414-436 registra perfiles de tema; acá conservamos el perfil.
-- ElvUI: General/Toolkit.lua:294,488,526 y Modules/Skins/Skins.lua:1597,1820,1898.
local function Call(object, method, ...)
 if object and type(object[method]) == 'function' then return object[method](object, ...) end
end

local function Backdrop(frame, t)
 if not frame then return end
 Call(frame, 'SetTemplate', 'Transparent')
 Call(frame, 'SetBackdropColor', t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, t.backdropFade.a)
 Call(frame, 'SetBackdropBorderColor', t.border.r, t.border.g, t.border.b)
end

local function Font(text, font, size, color)
 if not text then return end
 -- Conserva el tamaño que el usuario eligió; sólo cambia la familia y el color.
 local flags
 if type(text.GetFont) == 'function' then
  local _, oldSize, oldFlags = text:GetFont()
  size = oldSize or size
  flags = oldFlags
 end
 Call(text, 'SetFont', font, size, flags)
 Call(text, 'SetTextColor', color.r, color.g, color.b)
end

local function Style()
 local w = WoWPro
 if not w or not w.MainFrame then return end
 local t = K:GetTheme()
 local font = E.Libs.LSM:Fetch('font', 'Expressway')
 local skins = E:GetModule('Skins')
 local mf = w.MainFrame
 -- Un solo panel: el MainFrame lleva el fondo y borde del tema; los marcos internos quedan
 -- sin fondo propio (antes cada uno tenía el suyo y se veía un bloque negro adentro de otro).
 Backdrop(mf, t)
 Call(mf, 'SetBackdropColor', t.backdrop.r, t.backdrop.g, t.backdrop.b, 0.92)
 Call(mf, 'SetBackdropBorderColor', t.accentDim.r, t.accentDim.g, t.accentDim.b)
 for _, name in ipairs({ 'TitleBar', 'StickyHeader', 'GuideFrame', 'ButtonBar' }) do
  local f = w[name]
  if f then
   Call(f, 'SetBackdrop', nil)
   if f.backdrop then Call(f.backdrop, 'Hide') end
  end
 end
 -- Engranaje de opciones (WoWPro_Frames.lua:1088-1097, anclado a TOPRIGHT 0,0 del MainFrame):
 -- se mete 4 px hacia adentro para que no sobresalga del borde.
 local ob = w.OptionButton
 if ob and not InCombatLockdown() then
  ob:ClearAllPoints()
  ob:SetPoint('TOPRIGHT', mf, 'TOPRIGHT', -4, -4)
 end
 -- Posición: 8 px de la esquina superior izquierda, como minimapa y Details. Una sola vez por
 -- perfil, guardándola también en WoW-Pro (WoWPro_Frames.lua:627-645 y restauración :686-752,
 -- que divide los desplazamientos por la escala cuando no hay datos en porcentaje).
 if not E.db.KnuUIWoWProPlaced and not InCombatLockdown() and WoWProDB and WoWProDB.profile then
  E.db.KnuUIWoWProPlaced = true
  local scale = mf:GetScale() or 1
  WoWProDB.profile.position = { 'TOPLEFT', 'UIParent', 'TOPLEFT', 8 * scale, -8 * scale }
  mf:ClearAllPoints()
  mf:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 8, -8)
 end
 Font(w.TitleText, font, 14, t.accent)
 Font(w.ProgressText, font, 12, t.accent)
 Font(w.StickyHeaderTitle, font, 14, t.accent)
 for _, row in pairs(w.rows or {}) do
  -- Campos reales: WoWPro_Frames.lua:1767-1787,1801-1805.
  Font(row.step, font, 14, t.text)
  Font(row.note, font, 12, t.muted)
  Font(row.track, font, 12, t.accent)
  local highlight = Call(row, 'GetHighlightTexture')
  Call(highlight, 'SetColorTexture', t.accent.r, t.accent.g, t.accent.b, 0.15)
  if row.check then
   -- Widgets.lua:17-48: conservamos tildes dorados/grises y sus setters de estado.
   -- Sólo retiramos el relieve; StripTextures también borraría los tildes.
   Call(row.check, 'SetNormalTexture', nil)
   Call(row.check, 'SetPushedTexture', nil)
   Backdrop(row.check, t)
   Call(Call(row.check, 'GetHighlightTexture'), 'SetColorTexture', t.accent.r, t.accent.g, t.accent.b, 0.2)
  end
 end
 -- ButtonBar.Buttons y sus iconos: WoWPro_Frames.lua:1380-1441.
 for _, button in pairs(w.ButtonBar and w.ButtonBar.Buttons or {}) do
  Backdrop(button, t)
 end
 local slider = w.Scrollbar
 if slider and skins and type(skins.HandleSliderFrame) == 'function' then
  -- Widgets.lua:424-514: los botones y el borde son hijos anónimos del slider.
  -- Primero reemplazamos esos bordes/texturas; después ElvUI crea su propio backdrop.
  if type(slider.GetChildren) == 'function' then
   for _, child in ipairs({ slider:GetChildren() }) do
    if type(child.IsObjectType) == 'function' and child:IsObjectType('Button') then
     local point = Call(child, 'GetPoint')
     if not slider.KnuUISkinned and type(skins.HandleNextPrevButton) == 'function' then
      skins:HandleNextPrevButton(child, point == 'BOTTOM' and 'up' or 'down', t.accent, nil, nil, nil, Call(child, 'GetWidth'))
     end
     Backdrop(child, t)
     Call(Call(child, 'GetNormalTexture'), 'SetVertexColor', t.accent.r, t.accent.g, t.accent.b)
     Call(Call(child, 'GetPushedTexture'), 'SetVertexColor', t.accentHi.r, t.accentHi.g, t.accentHi.b)
     Call(Call(child, 'GetDisabledTexture'), 'SetVertexColor', t.muted.r, t.muted.g, t.muted.b)
    elseif child ~= slider.backdrop then
     Call(child, 'SetBackdrop', nil)
    end
   end
  end
  if not slider.KnuUISkinned then skins:HandleSliderFrame(slider, 'Transparent') end
  slider.KnuUISkinned = true
 end
 if slider then
  Backdrop(slider.backdrop, t)
  Call(Call(slider, 'GetThumbTexture'), 'SetVertexColor', t.accent.r, t.accent.g, t.accent.b)
 end
end

function K:SkinWoWPro()
 if applying or not E.Forever or E.db.KnuUISkinWoWPro == false or InCombatLockdown() then return false end
 applying = true
 local ok = self:WithAddon('WoWPro', Style)
 applying = false
 return ok
end

-- Agrupa hooks del mismo refresco en un único pase; sin polling permanente.
local function Schedule()
 if pending or E.db.KnuUISkinWoWPro == false then return end
 if C_Timer and type(C_Timer.After) == 'function' then
  pending = true
  C_Timer.After(0, function() pending = false; K:SkinWoWPro() end)
 else
  K:SkinWoWPro()
 end
end

local function Attach()
 K:WithAddon('WoWPro', function()
  if not WoWPro then return end
  -- CreateFrames y setters: Frames.lua:309,1445,1551,1594,1653,1742,2436.
  -- Fuentes/colores: RowUpdate.lua:67,82,1369. Hook de fuente inmediato para medir filas con Expressway.
  for _, method in ipairs({ 'CreateFrames', 'CreateRow', 'BackgroundSet', 'ButtonBarSet',
   'TitleBarLayout', 'TitleBarSet', 'StickyHeaderSet', 'RowFontSet', 'RowColorSet', 'RowUpdate' }) do
   if not hooked[method] and type(WoWPro[method]) == 'function' then
    hooksecurefunc(WoWPro, method, method == 'RowFontSet' and function() K:SkinWoWPro() end or Schedule)
    hooked[method] = true
   end
  end
 end)
 Schedule()
end

function K:SetupWoWProSkin()
 if E.db.KnuUISkinWoWPro == nil then E.db.KnuUISkinWoWPro = true end
 local events = CreateFrame('Frame')
 -- ADDON_LOADED: _ref/ElvUI/Game/Shared/Modules/Skins/Skins.lua:2242,2408.
 events:RegisterEvent('ADDON_LOADED')
 events:RegisterEvent('PLAYER_ENTERING_WORLD')
 events:RegisterEvent('PLAYER_REGEN_ENABLED')
 events:SetScript('OnEvent', function(_, event, name)
  if event ~= 'ADDON_LOADED' or name == 'WoWPro' then Attach() end
 end)
 Attach()
end
