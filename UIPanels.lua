local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- Paneles de Blizzard y la guía de WoW-Pro (arriba a la izquierda, alto variable según los pasos): se abren por debajo de la guía.
-- Bajar todo panel de UIPanelWindows a 4 px de la guía, sin mirar si se cruzan ni si entra en pantalla, dejaba los talentos (1218x708,
-- centrados por Blizzard en x 352, Blizzard_PlayerSpells/Camelot/Blizzard_PlayerSpellsFrame.xml:9-10) con la mitad de abajo fuera
-- de la pantalla, aunque no tocaban la guía (x 8-308).
--
-- Se trabaja con los paneles que Blizzard tiene abiertos en sus casillas (GetUIPanel, UIParentPanelManager.lua:
-- 946; casillas left/center/right/doublewide, :229-233), todos juntos para no romper el empuje del segundo panel:
--   1. Si ninguno se cruza con la guía, no se toca nada.
--   2. Si alguno se cruza: debajo de la guía (y alineados a su borde izquierdo si estaban a menos de 40) sólo si el
--      conjunto entra entero, dejando abajo los mismos 140 que usa Blizzard (ClampUIPanelY, :1007-1010).
--   3. Si abajo no entra: a la derecha de la guía, a la altura que eligió Blizzard, si entra entero.
--   4. Si tampoco: queda donde lo puso Blizzard (entero en pantalla, aunque tape la guía).
-- Todo en píxeles de pantalla (y crece hacia arriba); GAP, BOTTOM, MARGIN y ALIGN son unidades de UIParent.
-- Blizzard ubica los paneles desde un delegado prohibido (:152, :616-700): no se toca, se corrige después, fuera de
-- combate, con hooks (sin sondeos).
local GAP, BOTTOM, MARGIN, ALIGN = 4, 140, 10, 40
local SLOTS = { 'left', 'center', 'right', 'doublewide' }
-- GameMenuFrame se ancla solo (centerFrameSkipAnchoring, Mainline/UIPanelWindows.lua:4); el mapa tiene AdjustMap.
local SKIP = { GameMenuFrame = true, WorldMapFrame = true }

-- Se mide el fondo visible (ElvUI pone el skin en .backdrop, con márgenes respecto del marco): con el marco
-- invisible la separación quedaba más grande y el borde izquierdo corrido (visto en el juego 2026-11-13).
local function Visible(f)
	local b = f.backdrop
	if b and b.IsShown and b:IsShown() and b:GetTop() then return b end
	return f
end

local function Guide()
	local g = _G.WoWPro and _G.WoWPro.MainFrame
	if not (g and g:IsShown() and g:GetBottom()) then return end
	local v = Visible(g)
	local s = v:GetEffectiveScale()
	return v:GetBottom() * s, v:GetLeft() * s
end

local function Rect(f)
	local v = Visible(f)
	local l, r, b, t = v:GetLeft(), v:GetRight(), v:GetBottom(), v:GetTop()
	if not (l and r and b and t) then return end
	local s = v:GetEffectiveScale()
	return l * s, r * s, b * s, t * s
end

local function Near(a, b) return math.abs(a - b) < 0.5 end

-- Paneles que KnuUI corrió: base = el punto que puso Blizzard, last = el que puso KnuUI. Si el panel sigue en last
-- (abierto o cerrado), se vuelve a base antes de recalcular: una guía que cambia no acumula corrimientos y un panel
-- cerrado no se reabre corrido. Si está en otro punto, lo reubicó otro (Blizzard u otro addon) y se olvida.
-- Ambigüedad aceptada: si Blizzard escribiera justo last, se lo toma como propio; volver a base y recalcular da el
-- mismo resultado.
local moved = setmetatable({}, { __mode = 'k' })

local function RestoreMoved()
	for f, m in pairs(moved) do
		moved[f] = nil
		if f:GetNumPoints() == 1 then
			local p, rel, rp, x, y = f:GetPoint(1)
			local b = m.base
			if p == b[1] and rel == b[2] and rp == b[3] and Near(x, m.last[1]) and Near(y, m.last[2]) then
				f:ClearAllPoints()
				f:SetPoint(b[1], b[2], b[3], b[4], b[5])
			end
		end
	end
end

local function Managed(f)
	if not (f and f.IsShown and f:IsShown() and f:GetLeft()) then return end
	local name = f.GetName and f:GetName()
	if name and SKIP[name] then return end
	if f:GetNumPoints() ~= 1 then return end
	local _, rel = f:GetPoint(1)
	return rel == _G.UIParent
end

local queued, Queue

local function HookPanel(f)
	if f.KnuPanelSizeHooked then return end
	f.KnuPanelSizeHooked = true
	-- Talentos cambia de tamaño al pasar a hechizos (Blizzard_PlayerSpellsFrame.lua:433-441).
	f:HookScript('OnSizeChanged', function() Queue() end)
	f:HookScript('OnHide', function() Queue() end)
end

-- La guía es el ancla del resto del diseño. WoW-Pro la crea en TOPLEFT/UIParent/RIGHT -210,175
-- (WoWPro_Frames.lua:1037) y restaura la posición guardada UNA vez por sesión (:868-872); si esa vez AnchorSync no
-- hace nada (en combate o con InhibitAnchorSync, :705-707), queda en ese punto toda la sesión (debajo del minimapa).
-- Ese punto sólo lo pone la creación: AnchorStore siempre ancla la esquina
-- elegida a la misma esquina (:648-649) y el centro de comando usa sus zonas. Si la guía está ahí, se le pide a
-- WoW-Pro que restaure lo guardado. El centro de comando, al devolverla (Workspace.lua RestoreGuide), pasa por
-- SetPoint: lo engancha HookGuide y se revisa en la pasada siguiente.
local fixingGuide = false

local function AtCreationPoint(g)
	if g:GetNumPoints() ~= 1 then return false end
	local p, rel, rp, x, y = g:GetPoint(1)
	return p == 'TOPLEFT' and rel == _G.UIParent and rp == 'RIGHT' and Near(x or 0, -210) and Near(y or 0, 175)
end

local function EnsureGuide()
	local WP = _G.WoWPro
	local g = type(WP) == 'table' and WP.MainFrame
	local db = _G.WoWProDB
	if not (g and type(WP.AnchorSync) == 'function' and type(db) == 'table' and type(db.profile) == 'table'
		and db.profile.position) then return end
	if not AtCreationPoint(g) or WP.InhibitAnchorSync then return end -- inhibida: la reintenta el próximo aviso
	-- AnchorSync activa InhibitAnchorStore y lo devuelve al final (:709-710); si fallara a mitad, se devuelve acá.
	-- Mientras tanto los SetPoint propios no disparan otra pasada (HookGuide): si WoW-Pro fallara siempre, eso sería
	-- reintentar en cada cuadro. Se reintenta con el próximo aviso real de la guía.
	local store = WP.InhibitAnchorStore
	fixingGuide = true
	local ok = pcall(WP.AnchorSync)
	if not ok then WP.InhibitAnchorStore = store end
	-- Nunca sin ancla: si falló después de ClearAllPoints, vuelve al punto de WoW-Pro.
	if g:GetNumPoints() == 0 then g:SetPoint('TOPLEFT', _G.UIParent, 'RIGHT', -210, 175) end
	fixingGuide = false
end

local function Arrange()
	queued = false
	if InCombatLockdown() then K:AfterCombat(function() Queue() end, 'KnuUI:UIPanels'); return end
	pcall(EnsureGuide)
	RestoreMoved()
	if K.CC_IsActive and K:CC_IsActive() then return end -- el centro de comando ubica sus paneles (Workspace.lua)
	local g = _G.WoWPro and _G.WoWPro.MainFrame
	if not (g and g:IsShown()) or type(_G.GetUIPanel) ~= 'function' then return end
	local gl, gr, gb, gt = Rect(g)
	if not gl then return end
	local set, seen, hit = {}, {}, false
	local l, r, b, t
	for _, slot in ipairs(SLOTS) do
		local ok, f = pcall(_G.GetUIPanel, slot)
		if ok and f and not seen[f] and Managed(f) then
			seen[f] = true
			local fl, fr, fb, ft = Rect(f)
			if fl then
				HookPanel(f)
				set[#set + 1] = f
				l, r = math.min(l or fl, fl), math.max(r or fr, fr)
				b, t = math.min(b or fb, fb), math.max(t or ft, ft)
				if fl < gr and fr > gl and fb < gt and ft > gb then hit = true end
			end
		end
	end
	if not hit then return end
	local UI = _G.UIParent
	local u = UI:GetEffectiveScale()
	local sw, sh = UI:GetRight() * u, UI:GetTop() * u
	local function Fits(dx, dy)
		return l + dx >= 0 and r + dx <= sw - MARGIN * u and b + dy >= BOTTOM * u and t + dy <= sh
	end
	local dx, dy = 0, (gb - GAP * u) - t
	if math.abs(l - gl) < ALIGN * u then dx = gl - l end
	if not Fits(dx, dy) then
		dx, dy = gr + GAP * u - l, 0
		if not Fits(dx, dy) then return end
	end
	if math.abs(dx) <= 0.5 and math.abs(dy) <= 0.5 then return end
	for _, f in ipairs(set) do
		local p, rel, rp, x, y = f:GetPoint(1)
		local fs = f:GetEffectiveScale()
		local nx, ny = x + dx / fs, y + dy / fs -- desplazamiento en unidades del propio marco
		f:ClearAllPoints()
		f:SetPoint(p, rel, rp, nx, ny)
		moved[f] = { base = { p, rel, rp, x, y }, last = { nx, ny } }
	end
end

-- Varias señales en el mismo cuadro = una sola pasada, en el cuadro siguiente (Blizzard ya terminó de ubicar).
function Queue()
	if queued then return end
	queued = true
	C_Timer.After(0, function() pcall(Arrange) end)
end

-- La guía la crea WoW-Pro al abrir una guía (WoWPro:CreateFrames, WoWPro_Frames.lua:2461-2463) y se arrastra con
-- StartMoving/StopMovingOrSizing (:2326-2336), que no pasa por SetPoint.
local function HookGuide()
	local WP = _G.WoWPro
	if type(WP) ~= 'table' then return end
	if type(WP.CreateFrames) == 'function' and not WP.KnuPanelsCreateHooked then
		WP.KnuPanelsCreateHooked = true
		hooksecurefunc(WP, 'CreateFrames', function() HookGuide(); Queue() end)
	end
	-- Después de CustomizeFrames (donde WoW-Pro hace su única restauración, :868-872) se revisa si quedó bien.
	if type(WP.CustomizeFrames) == 'function' and not WP.KnuPanelsCustomizeHooked then
		WP.KnuPanelsCustomizeHooked = true
		hooksecurefunc(WP, 'CustomizeFrames', function() HookGuide(); Queue() end)
	end
	local g = WP.MainFrame
	if not g or g.KnuPanelsGuideHooked then return end
	g.KnuPanelsGuideHooked = true
	for _, script in ipairs({ 'OnSizeChanged', 'OnShow', 'OnHide' }) do g:HookScript(script, function() Queue() end) end
	hooksecurefunc(g, 'SetPoint', function() if not fixingGuide then Queue() end end)
	hooksecurefunc(g, 'StopMovingOrSizing', function() Queue() end)
end

-- Mapa de OpenMap: no lo ubica Blizzard sino OpenMap, con su posición guardada (OpenMapDB.worldmap.window =
-- { punto, punto relativo, x, y } respecto de UIParent, OpenMap/Map/Window.lua:14-17; la vuelve a poner cuando
-- algo mueve el mapa). Si se abre encima de la guía, se baja esa posición lo
-- justo para quedar a 4 de la guía, y se guarda: la próxima vez ya abre ahí.
local function AdjustMap()
	local map = _G.WorldMapFrame
	if not (map and map:IsShown()) or InCombatLockdown() or (map.IsMaximized and map:IsMaximized()) then return end
	if K.CC_IsActive and K:CC_IsActive() then return end
	local bottom, gleft = Guide()
	local g = _G.WoWPro and _G.WoWPro.MainFrame
	if not (bottom and g and map:GetTop() and map:GetLeft()) then return end
	local gs = Visible(g):GetEffectiveScale()
	local s = map:GetEffectiveScale()
	if map:GetLeft() * s > Visible(g):GetRight() * gs then return end -- no se cruzan a lo ancho
	local dy = map:GetTop() * s - (bottom - GAP * _G.UIParent:GetEffectiveScale())
	if dy < 0 then dy = 0 end
	-- Borde izquierdo alineado con la guía, como los paneles (en el juego quedaba ~30 más a la derecha).
	local dx = 0
	if math.abs(map:GetLeft() * s - gleft) < 40 then dx = gleft - map:GetLeft() * s end
	if dy <= 0.5 and math.abs(dx) <= 0.5 then return end
	local db = _G.OpenMapDB and _G.OpenMapDB.worldmap
	if db and type(db.window) == 'table' and tonumber(db.window[4]) and tonumber(db.window[3]) then
		local scale = tonumber(db.windowScale) or 1
		local u = _G.UIParent:GetEffectiveScale() * scale
		db.window[3] = db.window[3] + dx / u
		db.window[4] = db.window[4] - dy / u
		if K.CC and K.CC.PlaceMapNow then pcall(K.CC.PlaceMapNow) end
	elseif map:GetNumPoints() == 1 then
		local p, rel, rp, x, y = map:GetPoint(1)
		map:ClearAllPoints()
		map:SetPoint(p, rel, rp, x + dx / s, y - dy / s)
	end
end

-- Tiradas de botín y alertas: el lugar está en K.blizzardMovers.AlertFrameMover (Layout.lua, al centro arriba del
-- objetivo). Esto es sólo la migración de perfiles con una posición vieja puesta por KnuUI: x 270 o 368 junto a la
-- guía, o la que calculaba la versión que seguía el ancho de la guía (E.db.KnuUIAlertPoint). Un mover que el
-- jugador movió a otro lado no se toca. E:SetMoverPoints no corre PostAlertMove (ElvUI General/Movers.lua:58-77),
-- que es lo que decide si crecen hacia arriba o abajo: se llama aparte.
local OLD_ALERT_POINTS = {
	['TOPLEFT,ElvUIParent,TOPLEFT,270,-150'] = true,
	['TOPLEFT,ElvUIParent,TOPLEFT,368,-150'] = true,
}

function K:FitLootRolls()
	local movers, target = E.db.movers, K.blizzardMovers.AlertFrameMover
	if not (movers and target) then return end
	local current, dynamic = movers.AlertFrameMover, E.db.KnuUIAlertPoint
	local own = current == nil or OLD_ALERT_POINTS[current] or (dynamic ~= nil and current == dynamic)
	E.db.KnuUIAlertPoint = nil
	if not own or current == target then return end
	movers.AlertFrameMover = target
	if E.SetMoverPoints then pcall(E.SetMoverPoints, E, 'AlertFrameMover') end
	if E.PostAlertMove then pcall(E.PostAlertMove, E) end
end

-- Columna de la guía (x 8-308): versiones anteriores ponían ahí el grupo, la banda, el ticket GM y el botín, y la
-- guía los tapaba al crecer. Grupo y banda van encima del chat izquierdo, creciendo hacia arriba. Pasa a la
-- posición nueva (Layout.lua, Base.lua) sólo un mover que tiene exactamente la posición vieja de KnuUI; si el jugador lo movió, o el rol Healer / las columnas lo pusieron abajo, no se toca.
-- En combate no se escribe nada: grupo y banda son cabeceras seguras ancladas a su mover. Se reintenta al cargar.
local OLD_COLUMN_POINTS = {
	ElvUF_PartyMover = { 'TOPLEFT,ElvUIParent,LEFT,8,110', 'TOPLEFT,ElvUIParent,LEFT,320,110' },
	ElvUF_Raid1Mover = { 'TOPLEFT,ElvUIParent,LEFT,8,110', 'TOPLEFT,ElvUIParent,LEFT,320,110' },
	ElvUF_Raid2Mover = { 'TOPLEFT,ElvUIParent,LEFT,8,110', 'TOPLEFT,ElvUIParent,LEFT,320,110' },
	ElvUF_Raid3Mover = { 'TOPLEFT,ElvUIParent,LEFT,8,110', 'TOPLEFT,ElvUIParent,LEFT,320,110' },
	GMMover = { 'TOPLEFT,ElvUIParent,TOPLEFT,8,-310', 'TOPLEFT,ElvUIParent,TOPLEFT,270,-8' },
	LootFrameMover = { 'TOPLEFT,ElvUIParent,TOPLEFT,270,-400' },
}
K.guideColumnPoints = {
	ElvUF_PartyMover = 'BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,4,270',
	ElvUF_Raid1Mover = 'BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,4,270',
	ElvUF_Raid2Mover = 'BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,4,270',
	ElvUF_Raid3Mover = 'BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,4,270',
	GMMover = 'TOPLEFT,ElvUIParent,TOPLEFT,320,-310',
	LootFrameMover = 'TOPLEFT,ElvUIParent,TOPLEFT,530,-400',
}

local RAID_SHAPE = { raid1 = { 72, 1 }, raid2 = { 72, 1 }, raid3 = { 80, 2 } } -- ancho, grupos por columna
local GROUPS = { ElvUF_PartyMover = 'party', ElvUF_Raid1Mover = 'raid1', ElvUF_Raid2Mover = 'raid2', ElvUF_Raid3Mover = 'raid3' }

function K:ClearGuideColumn()
	local movers = E.db.movers
	if not movers or InCombatLockdown() then return end
	for name, olds in pairs(OLD_COLUMN_POINTS) do
		local current = movers[name]
		for _, old in ipairs(olds) do
			if current == old then
				movers[name] = K.guideColumnPoints[name]
				local group = GROUPS[name]
				local db = group and E.db.unitframe and E.db.unitframe.units[group]
				if db and db.growthDirection == 'DOWN_RIGHT' then
					db.growthDirection = 'UP_RIGHT' -- apoyado sobre el chat: un grupo chico queda abajo
					-- Banda: con el ancho y las columnas que ponía KnuUI (80, 1) llegaría al foco; pasa a los de Layout.lua.
					local shape = RAID_SHAPE[group]
					if shape and db.width == 80 and db.groupsPerRowCol == 1 then
						db.width, db.groupsPerRowCol = shape[1], shape[2]
					end
					local UF = E:GetModule('UnitFrames', true)
					if UF and UF.CreateAndUpdateHeaderGroup then pcall(UF.CreateAndUpdateHeaderGroup, UF, group) end
				end
				if E.SetMoverPoints then pcall(E.SetMoverPoints, E, name) end
				break
			end
		end
	end
end

function K:SetupUIPanels()
	local map = _G.WorldMapFrame
	if map and not map.KnuPanelHook then
		map.KnuPanelHook = true
		map:HookScript('OnShow', function() C_Timer.After(0, function() pcall(AdjustMap) end) end)
	end
	pcall(self.FitLootRolls, self)
	pcall(self.ClearGuideColumn, self)
	if self.uiPanelsHooked then return end
	self.uiPanelsHooked = true
	-- Después de cada acomodo de Blizzard. UpdateScaleForFitForOpenPanels hace que el delegado reubique por dentro
	-- sin pasar por la UpdateUIPanelPositions global (UIParentPanelManager.lua:758-766, :1197-1198).
	for _, fn in ipairs({ 'ShowUIPanel', 'HideUIPanel', 'UpdateUIPanelPositions', 'UpdateScaleForFitForOpenPanels' }) do
		if type(_G[fn]) == 'function' then hooksecurefunc(fn, function() Queue() end) end
	end
	HookGuide()
	local events = CreateFrame('Frame')
	events:RegisterEvent('ADDON_LOADED')
	events:SetScript('OnEvent', function(_, event, name)
		if event == 'ADDON_LOADED' and name == 'WoWPro' then pcall(HookGuide); Queue() end
	end)
	Queue()
end
