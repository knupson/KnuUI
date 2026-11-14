local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- Paneles de Blizzard (personaje, hechizos, talentos, amigos...) debajo de la guía de WoW-Pro (pedido del user
-- 2026-11-13: "que se abran por debajo de la guía, consistentes con el resto de la UI"). Blizzard los ubica a
-- TOP_OFFSET = -116 del borde de arriba (Blizzard_UIParentPanelManager/Shared/UIPanelLayoutFrame.lua:3) desde
-- un delegado prohibido (UIParentPanelManager.lua:152, :616-700). No se toca ese atributo (un valor escrito por
-- un addon contaminaría al delegado): después de que Blizzard los ubica, KnuUI corre hacia abajo los que
-- quedaron encima de la guía, sólo fuera de combate y conservando su posición horizontal.
local GAP = 4

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

local function Adjust(frame)
	if not (frame and frame.IsShown and frame:IsShown()) or InCombatLockdown() then return end
	if K.CC_IsActive and K:CC_IsActive() then return end -- el centro de comando ubica sus paneles (Workspace.lua)
	local bottom, gleft = Guide()
	if not bottom or frame:GetNumPoints() ~= 1 then return end
	local point, rel, relPoint, x, y = frame:GetPoint(1)
	if rel ~= _G.UIParent or (point ~= 'TOPLEFT' and point ~= 'TOP') then return end -- sólo lo que ubicó Blizzard
	local s = frame:GetEffectiveScale()
	local v = Visible(frame)
	local vs = v:GetEffectiveScale()
	if not (v:GetTop() and v:GetLeft()) then return end
	local gap = GAP * _G.UIParent:GetEffectiveScale()
	-- Vertical: el borde de arriba a 4 del borde de abajo de la guía, si quedaba encima o más lejos de lo pedido.
	local dy = v:GetTop() * vs - (bottom - gap)
	-- Horizontal: el panel de la izquierda alineado con el borde izquierdo de la guía (pedido del user).
	local dx = 0
	local left = v:GetLeft() * vs
	if math.abs(left - gleft) < 40 then dx = gleft - left end
	if math.abs(dy) <= 0.5 and math.abs(dx) <= 0.5 then return end
	if dy < -0.5 and v:GetTop() * vs < bottom - 3 * gap then dy = 0 end -- muy abajo: lo movió otra cosa, no se toca
	frame:ClearAllPoints()
	frame:SetPoint(point, rel, relPoint, x + dx / s, y - dy / s) -- desplazamientos en unidades del propio marco
end

local function AdjustAll()
	if InCombatLockdown() or type(_G.UIPanelWindows) ~= 'table' then return end
	for name in pairs(_G.UIPanelWindows) do
		local f = _G[name]
		if f then pcall(Adjust, f) end
	end
end

-- Mapa de OpenMap: no lo ubica Blizzard sino OpenMap, con su posición guardada (OpenMapDB.worldmap.window =
-- { punto, punto relativo, x, y } respecto de UIParent, OpenMap/Map/Window.lua:14-17; la vuelve a poner cuando
-- algo mueve el mapa). Si se abre encima de la guía (visto en el juego 2026-11-13), se baja esa posición lo
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

function K:SetupUIPanels()
	local map = _G.WorldMapFrame
	if map and not map.KnuPanelHook then
		map.KnuPanelHook = true
		map:HookScript('OnShow', function() C_Timer.After(0, function() pcall(AdjustMap) end) end)
	end
	if self.uiPanelsHooked then return end
	self.uiPanelsHooked = true
	-- Después de cada acomodo de Blizzard (mostrar, ocultar, reubicar), en el cuadro siguiente.
	local function Later() C_Timer.After(0, AdjustAll) end
	for _, fn in ipairs({ 'ShowUIPanel', 'HideUIPanel', 'UpdateUIPanelPositions' }) do
		if type(_G[fn]) == 'function' then hooksecurefunc(fn, Later) end
	end
end
