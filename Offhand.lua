local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Offhand (ventana estirada sobre dos monitores, Companion la deja en 1920x2160).
-- Offhand baja la escala de UIParent para que entre toda la ventana (Core/Viewport.lua:724, 0,35 con
-- hudScale 0,7). ElvUI arma su contenedor y sus bordes con medidas de la ventana entera. Medido con
-- /knudiag el 2026-11-12 (WTF\...\SavedVariables\KnuUI.lua):
--   * E:UIScale dentro de E:Initialize (ElvUI Core.lua:2037) deja ElvUIParent en 960x1080 y los
--     módulos se arman con ese tamaño;
--   * E.mult = 0,5 (bordes de medio píxel) porque E.perfect usa el alto de la ventana (2160);
--   * MinimapPanel con escala efectiva 0,711 y el resto de ElvUI en 0,356 (reloj y coordenadas al
--     doble de tamaño): ElvUI escala esos marcos ignorando al padre con E.uiscale (Minimap.lua:128-131).
-- Acá ElvUIParent se encaja en el rectángulo del juego que escribe Companion
-- (OffhandCompanionTopology.game, px físicos con origen abajo a la izquierda) con la escala que deja
-- cada unidad del mismo tamaño en píxeles que en una sola pantalla de 1080 con la escala de ElvUI:
--   escala efectiva = UIScale * altoJuego / altoVentana  (0,711 * 1080 / 2160 = 0,3556)
-- y E.perfect / E.uiscale se calculan con el alto del monitor de juego.
-- Opción: ElvUI > KnuUI > Offhand (E.db.KnuUIOffhand). Reemplaza al addon suelto OffhandElvFix.

local frame, pending, reported, warned

local function ElvFixLoaded()
	return C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded('OffhandElvFix')
end

local function Enabled()
	return not (E.db and E.db.KnuUIOffhand == false) and not ElvFixLoaded()
end

-- Rectángulos de Companion si la ventana está estirada de verdad (nil si no).
local function Topology()
	if not Enabled() then return end
	local t = _G.OffhandCompanionTopology
	if type(t) ~= 'table' or type(t.game) ~= 'table' then return end
	local pw, ph = tonumber(t.physicalWidth), tonumber(t.physicalHeight)
	local g = t.game
	if not pw or not ph or pw <= 0 or ph <= 0 or not tonumber(g.width) or not tonumber(g.height) then return end
	-- Mismo control que Offhand: la proporción de UIParent tiene que ser la de la ventana estirada.
	local w, h = _G.UIParent:GetWidth(), _G.UIParent:GetHeight()
	if not w or not h or h <= 0 or math.abs(w / h - pw / ph) > 0.01 then return end
	if g.width >= pw and g.height >= ph then return end -- un solo monitor: nada que corregir
	return t, pw, ph
end
K.OffhandTopology = Topology

-- Escala efectiva que necesita ElvUIParent (nil si la ventana no está estirada).
local function Target()
	local t, _, ph = Topology()
	if not t then return end
	local uiScale = tonumber(E.global and E.global.general and E.global.general.UIScale) or 0.711
	return uiScale * t.game.height / ph
end

-- Bordes de 1 px: E.perfect = 768 / alto físico (Core.lua:78, PixelPerfect.lua:100) y
-- E.mult = E.perfect / UIScale (PixelPerfect.lua:52). Con el alto del monitor de juego vuelve a dar 1.
-- E:OnInitialize ya llamó a UIMult antes de este archivo: se recalcula acá, antes de PLAYER_LOGIN.
if E.UIMult then
	local orig = E.UIMult
	E.UIMult = function(self, ...)
		local t = Topology()
		if t then E.perfect = 768 / t.game.height
		elseif E.physicalHeight and E.physicalHeight >= 1 then E.perfect = 768 / E.physicalHeight end -- PixelPerfect.lua:100 (revisión de Codex)
		return orig(self, ...)
	end
	if E.global and E.global.general and E.global.general.UIScale then E:UIMult() end
end

-- Marcos que ElvUI escala ignorando al padre (Minimap.lua:128-131) y el minimapa, que cuelga de
-- UIParent (escala 0,35 en vez de 0,356 de ElvUIParent: medido 173 px en vez de 176).
local function Rescale()
	local M = E.GetModule and E:GetModule('Minimap', true)
	if not M or not M.SetScale then return end
	for _, f in ipairs({ M.MapHolder, _G.MinimapPanel, _G.ElvUI_MinimapClusterHolder, _G.Minimap and _G.Minimap.backdrop, _G.Minimap and _G.Minimap.location }) do
		if f and f.IsIgnoringParentScale and f:IsIgnoringParentScale() then pcall(M.SetScale, M, f, 1) end
	end
	if M.UpdateIcons then pcall(M.UpdateIcons, M) end
	local mm = _G.Minimap
	local parent = mm and mm:GetParent()
	if mm and parent and E.UIParent and not mm:IsIgnoringParentScale() then
		-- Se compensa sobre la escala local que tenía el minimapa (ElvUI aplica M.db.scale al cluster, no al
		-- Minimap; revisión de Codex) y se repone al dejar de estar estirado.
		if mm.KnuOrigScale == nil then mm.KnuOrigScale = mm:GetScale() end
		local factor = E.UIParent:GetEffectiveScale() / parent:GetEffectiveScale()
		if math.abs(factor - 1) < 0.001 or not Topology() then
			pcall(mm.SetScale, mm, mm.KnuOrigScale)
			mm.KnuOrigScale = nil
		else
			pcall(mm.SetScale, mm, mm.KnuOrigScale * factor)
		end
	end
end

-- Movers de ElvUI: cuelgan de UIParent (Movers.lua:281), no de ElvUIParent. Con Offhand UIParent queda en
-- 0,35 y ElvUIParent en 0,356, así que sus desplazamientos y tamaños salen 1,6 % chicos. Medido con
-- /knudiag el 2026-11-12: ElvAB_5 en 'BOTTOM,ElvUIParent,BOTTOM,-422,28' quedaba en x 418,6 px en vez
-- de 410 (barras separadas del chat). Se les da la escala que los iguala a ElvUIParent.
local function ScaleMovers()
	if not E.CreatedMovers or not E.UIParent then return end
	local factor = 1
	if E.UIParent.KnuOffhand then factor = E.UIParent:GetEffectiveScale() / _G.UIParent:GetEffectiveScale() end
	for name in pairs(E.CreatedMovers) do
		local m = _G[name]
		if m and m.SetScale and math.abs(m:GetScale() - factor) > 0.0001 then pcall(m.SetScale, m, factor) end
	end
end
K.ScaleMovers = ScaleMovers
if E.CreateMover then hooksecurefunc(E, 'CreateMover', ScaleMovers) end

function K:OffhandFit()
	pending = false
	local parent = E.UIParent
	if not parent then return end
	if InCombatLockdown() then
		if frame then frame:RegisterEvent('PLAYER_REGEN_ENABLED') end
		return
	end
	local t, _, ph = Topology()
	if not t then
		if parent.KnuOffhand then -- la ventana dejó de estar estirada o se apagó la opción
			parent.KnuOffhand = nil
			parent:SetScale(1)
			parent:ClearAllPoints()
			parent:SetPoint('BOTTOM', _G.UIParent, 'BOTTOM')
			E:UIMult()
			E:UIScale()
			Rescale()
			ScaleMovers()
		end
		return
	end
	local g = t.game
	local target = Target()
	local unit = target * ph / 768 -- px físicos por unidad de ElvUIParent (1 con la escala de KnuUI)
	local w, h = g.width / unit, g.height / unit
	parent.KnuOffhand = true
	parent:SetScale(target / _G.UIParent:GetEffectiveScale())
	parent:ClearAllPoints()
	-- Centro de comando con la barra de datos arriba (Workspace.lua, K.CCBottomShift): ElvUIParent baja y
	-- crece lo mismo, así lo anclado abajo baja (barras a 4 px del borde, pedido del user 2026-11-13) y lo
	-- anclado arriba (minimapa, K) queda donde está.
	local shift = tonumber(K.CCBottomShift) or 0
	parent:SetPoint('BOTTOMLEFT', _G.UIParent, 'BOTTOMLEFT', (g.x or 0) / unit, (g.y or 0) / unit - shift)
	parent:SetSize(w, h + shift)
	parent.origHeight = h
	E.screenWidth, E.screenHeight = w, h
	E.uiscale = target
	Rescale()
	ScaleMovers()
	if not reported then
		reported = true
		E:Print(format(L["Offhand: ElvUI on the game monitor, %.0fx%.0f at scale %.4f."], w, h, target))
	end
end

-- Mismo momento que ElvUI: así sus módulos se arman ya con el tamaño del monitor de juego.
hooksecurefunc(E, 'UIScale', function()
	local target = Target()
	if not target then return end
	E.uiscale = target
	if not InCombatLockdown() then K:OffhandFit() end
end)

local function Queue()
	if pending then return end
	pending = true
	C_Timer.After(0, function() K:OffhandFit() end)
end

-- Para el menú de opciones.
function K:OffhandStatus()
	if ElvFixLoaded() then return L["Disable the OffhandElvFix addon: KnuUI does its job now."] end
	if not (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded('Offhand')) then return L["Offhand is not loaded."] end
	local t = _G.OffhandCompanionTopology
	if type(t) ~= 'table' or type(t.game) ~= 'table' then return L["Offhand is loaded but Companion has not written the monitor layout yet."] end
	local active = Topology() ~= nil
	return format(L["Window %dx%d, game %dx%d at %d,%d, workspace %dx%d at %d,%d. Spanned now: %s."],
		t.physicalWidth or 0, t.physicalHeight or 0, t.game.width or 0, t.game.height or 0, t.game.x or 0, t.game.y or 0,
		t.workspace and t.workspace.width or 0, t.workspace and t.workspace.height or 0,
		t.workspace and t.workspace.x or 0, t.workspace and t.workspace.y or 0, active and L["yes"] or L["no"])
end

function K:SetupOffhand()
	if frame then return end
	if ElvFixLoaded() then
		if not warned then
			warned = true
			E:Print(L["Disable the OffhandElvFix addon: KnuUI does its job now."])
		end
		return
	end
	frame = CreateFrame('Frame')
	frame:SetScript('OnEvent', function(_, event)
		if event == 'PLAYER_REGEN_ENABLED' then frame:UnregisterEvent('PLAYER_REGEN_ENABLED') end
		Queue()
	end)
	for _, ev in ipairs({ 'PLAYER_ENTERING_WORLD', 'UI_SCALE_CHANGED', 'DISPLAY_SIZE_CHANGED' }) do frame:RegisterEvent(ev) end
	hooksecurefunc(_G.UIParent, 'SetScale', Queue)
	local M = E.GetModule and E:GetModule('Minimap', true)
	if M and M.UpdateSettings then hooksecurefunc(M, 'UpdateSettings', function() if Topology() then Rescale() end end) end
	Queue()
end
