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
  -- Tope de altura: después de cada armado de la ventana (MainFrameLayout llama a GuideWindowLayout, Frames.lua:884).
  if not hooked.MainFrameLayout and type(WoWPro.MainFrameLayout) == 'function' then
   hooksecurefunc(WoWPro, 'MainFrameLayout', function() pcall(K.LimitWoWPro, K) end)
   hooked.MainFrameLayout = true
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

-- Tope de altura de la guía con desplazamiento.
-- Con autoresize, WoW-Pro agranda la ventana hasta el borde de la pantalla (GetMainFrameMaxSize, WoWPro_Frames.lua:55-85),
-- y los pasos «As you go» no cuentan para numsteps (WoWPro_Config.lua:381): con varios, la guía tapaba el grupo.
-- Su propia barra se mueve de a un paso (GuideOffset, WoWPro_Frames.lua:1752-1760) y deja fijos los «As you go», así que
-- no sirve. KnuUI corta la ventana arriba del grupo y mueve las filas por píxeles dentro de GuideFrame, que WoW-Pro ya
-- recorta (SetClipsChildren, :1724): la fila 1 cuelga de GuideFrame y las demás de la anterior (CreateRow, :1773-1779).
-- Por defecto se ve el final (el paso actual va después de los «As you go»); la rueda del mouse sube y baja. En combate
-- no se toca nada (la ventana tiene botones seguros). Sólo con autoresize: el centro de comando lo apaga (Workspace.lua).
local GUIDE_GAP = 6
local limit = { scroll = 0, range = 0, user = false }

-- Borde superior del grupo y la banda de KnuUI (Layout.lua K.guideColumnPoints) que quedan debajo de la guía, en
-- coordenadas de UIParent: hasta ahí puede bajar. nil si ninguno comparte columna con la guía (guía movida a otro lado).
local function GuideFloor(MF)
	local ui = UIParent:GetEffectiveScale() or 1
	local ms = (MF:GetEffectiveScale() or 1) / ui
	local left, right = (MF:GetLeft() or 0) * ms, (MF:GetRight() or 0) * ms
	local floor
	for _, name in ipairs({ 'ElvUF_PartyMover', 'ElvUF_Raid1Mover' }) do
		local mover = _G[name]
		local top = mover and mover.GetTop and mover:GetTop()
		if top then
			local s = (mover:GetEffectiveScale() or 1) / ui
			local mLeft, mRight = (mover:GetLeft() or 0) * s, (mover:GetRight() or 0) * s
			if mLeft < right and mRight > left then floor = math.max(floor or 0, top * s) end
		end
	end
	return floor and floor + GUIDE_GAP
end

-- Botones de cada fila (usar objeto, objetivo, etc.): cuelgan de MainFrame y UIParent, así que el recorte de
-- GuideFrame no los alcanza. WoW-Pro los apaga con alfa y mouse (no con Hide: hay seguros) sólo por el borde de abajo
-- (UpdateFlyoutClip, WoWPro_Frames.lua:313-336); con las filas corridas también hay que mirar el de arriba.
-- Mismas claves que WoW-Pro (FLYOUT_KEYS, :315).
local FLYOUT_KEYS = { 'itembutton', 'targetbutton', 'jumpbutton', 'eabutton', 'itembuttonSecured', 'targetbuttonSecured', 'eabuttonSecured' }
local function ClipFlyouts()
	local GF = WoWPro and WoWPro.GuideFrame
	if limit.range <= 0 or not GF or not WoWPro.rows then return end
	-- En combate WoW-Pro puede volver a mostrarlos (su regla sólo mira abajo): el alfa se puede cambiar igual; el mouse,
	-- sólo en los que no son seguros (revisión de Codex 2026-11-22).
	local combat = InCombatLockdown()
	local top, bottom = GF:GetTop(), GF:GetBottom()
	if not (top and bottom) then return end
	for _, row in ipairs(WoWPro.rows) do
		local rowTop = row:GetTop()
		local titleHeight = row.step and row.step:GetHeight()
		local titleBottom = rowTop and titleHeight and rowTop - titleHeight
		local inView = row:IsShown() and titleBottom ~= nil and titleBottom >= bottom and rowTop <= top + 1
		for _, key in ipairs(FLYOUT_KEYS) do
			local b = row[key]
			if b then
				b:SetAlpha(inView and 1 or 0)
				if not (combat and b.IsProtected and b:IsProtected()) then b:EnableMouse(inView) end
			end
		end
	end
end

local function PlaceRows(scroll)
	local first = WoWPro and WoWPro.rows and WoWPro.rows[1]
	local GF = WoWPro and WoWPro.GuideFrame
	if not (first and GF) then return end
	first:ClearAllPoints()
	first:SetPoint('TOPLEFT', GF, 'TOPLEFT', 0, scroll)
	first:SetPoint('TOPRIGHT', GF, 'TOPRIGHT', 0, scroll)
	ClipFlyouts()
end

function K:LimitWoWPro()
	local MF = WoWPro and WoWPro.MainFrame
	local GF = WoWPro and WoWPro.GuideFrame
	local WP = WoWProDB and WoWProDB.profile
	if not (MF and GF and WP) or InCombatLockdown() then return false end
	local wanted = E.db.KnuUIWoWProLimit ~= false and WP.autoresize and MF:IsShown()
	local s = (MF:GetEffectiveScale() or 1) / (UIParent:GetEffectiveScale() or 1)
	local mfTop, gfTop = MF:GetTop(), GF:GetTop()
	if not (mfTop and gfTop) then return false end
	local floor = GuideFloor(MF)
	local maxH = floor and (mfTop * s - floor) / s
	local content = GF:GetHeight() or 0
	if not wanted or not maxH or MF:GetHeight() <= maxH then
		if limit.range > 0 then limit.range, limit.scroll, limit.user = 0, 0, false; PlaceRows(0) end
		return false
	end
	local pad = MF:GetHeight() - (mfTop - gfTop) - content -- lo que WoW-Pro dejó debajo de las filas
	local visible = math.max(maxH - (mfTop - gfTop) - math.max(pad, 0), 20)
	MF:SetHeight(maxH)
	GF:SetHeight(visible)
	limit.range = math.max(content - visible, 0)
	-- Sin rueda desde el último cambio: al final, donde está el paso actual.
	if not limit.user then limit.scroll = limit.range end
	limit.scroll = math.min(math.max(limit.scroll, 0), limit.range)
	PlaceRows(limit.scroll)
	if not limit.wheel then
		limit.wheel = true
		MF:EnableMouseWheel(true)
		-- Con el tope activo, la rueda es sólo de KnuUI: la de WoW-Pro (guidescroll, de a un paso, :1762-1766) haría
		-- un segundo desplazamiento. Sin tope, la de WoW-Pro sigue como siempre.
		local original = MF:GetScript('OnMouseWheel')
		MF:SetScript('OnMouseWheel', function(frame, delta)
			if limit.range <= 0 then
				if original then return original(frame, delta) end
				return
			end
			if InCombatLockdown() then return end
			limit.user = true
			limit.scroll = math.min(math.max(limit.scroll - delta * 40, 0), limit.range)
			if limit.scroll >= limit.range then limit.user = false end -- de vuelta abajo: sigue al paso actual
			PlaceRows(limit.scroll)
		end)
		-- WoW-Pro vuelve a calcular sus botones con su regla (sólo el borde de abajo): después, la de KnuUI.
		if type(WoWPro.UpdateFlyoutClip) == 'function' then hooksecurefunc(WoWPro, 'UpdateFlyoutClip', ClipFlyouts) end
	end
	return true
end
