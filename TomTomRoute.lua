local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- La flecha de TomTom por el camino más corto de Shortest Path Forever (pedido del user: ver sólo la
-- flecha de TomTom, sin la flecha, brújula ni secciones propias de Shortest Path).
-- 1) Cuando algo (WoW-Pro, Questie, /way) apunta la flecha de TomTom a un destino, KnuUI se lo pasa a
--    Shortest Path con su API pública: ShortestPathForever.API.Navigate(owner, uiMapID, x, y, title)
--    (ShortestPathForever/Core/API.lua:568; el punto es el mismo uiMapID y 0-1 que usa TomTom,
--    Core/TomTom.lua). Shortest Path calcula la ruta más corta (caminos, vuelos, barcos, portales).
-- 2) Shortest Path guía la ruta curva por curva poniendo el punto de usuario del juego en la próxima
--    curva o parada (C_Map.SetUserWaypoint, Journey/JourneyGuide.lua:421-460). KnuUI copia ese punto
--    a un punto temporal de TomTom (TomTom:AddWaypoint, core/waypoints.lua:415) que toma la flecha.
-- 3) Al terminar el viaje (o cerca del destino, donde Shortest Path deja de poner el punto) la flecha
--    vuelve al destino original.
-- La API pública de Shortest Path no da las coordenadas de cada tramo (JourneyLegs, API.lua:609-622):
-- por eso se lee el punto de usuario del juego.

local OWNER = 'KnuUI'
local original, mirror, mirrorKey, active, restoring, ticker

local function API()
	local spf = _G.ShortestPathForever
	return spf and spf.API
end

local function Remove(uid)
	if uid and _G.TomTom and _G.TomTom.RemoveWaypoint then pcall(_G.TomTom.RemoveWaypoint, _G.TomTom, uid) end
end

local function Stop()
	active = false
	if ticker then ticker:Cancel(); ticker = nil end
	Remove(mirror)
	mirror, mirrorKey = nil, nil
end

-- La flecha vuelve al destino original (si TomTom todavía lo tiene).
local function Restore()
	Stop()
	local tt = _G.TomTom
	if original and tt and tt.IsValidWaypoint and tt:IsValidWaypoint(original) then
		restoring = true
		pcall(tt.SetCrazyArrow, tt, original, original.arrivaldistance or 15, original.title)
		restoring = false
	end
end

local function Sync()
	if not active then return end
	local api, tt = API(), _G.TomTom
	if not (api and tt) then return Stop() end
	if not api.CurrentStop(OWNER) then return Restore() end -- el viaje terminó, se canceló o lo tomó otro
	local wp = C_Map.GetUserWaypoint and C_Map.GetUserWaypoint()
	local pos = wp and wp.position
	if not pos then
		-- Cerca del destino Shortest Path no pone punto: la flecha apunta al destino.
		if mirror then Restore(); active = true; ticker = ticker or C_Timer.NewTicker(0.5, function() pcall(Sync) end) end
		return
	end
	local key = format('%d:%.4f:%.4f', wp.uiMapID or 0, pos.x, pos.y)
	if key == mirrorKey then return end
	Remove(mirror)
	mirrorKey = key
	mirror = tt:AddWaypoint(wp.uiMapID, pos.x, pos.y, {
		title = original and original.title or nil,
		from = OWNER, persistent = false, minimap = false, world = false,
		crazy = true, silent = true, cleardistance = 0, arrivaldistance = 0,
	})
end

local function OnArrow(_, uid)
	if restoring or type(uid) ~= 'table' or uid == mirror or uid.from == OWNER or uid.corpse then return end
	local api = API()
	if not (api and api.Navigate) then return end
	if not (uid[1] and uid[2] and uid[3]) then return end
	Stop()
	original = uid
	if api.Navigate(OWNER, uid[1], uid[2], uid[3], uid.title) then
		active = true
		ticker = C_Timer.NewTicker(0.5, function() pcall(Sync) end)
	end
end

-- Una vez: apaga lo que Shortest Path dibuja en pantalla (sus opciones están en ShortestPathForeverDB,
-- Core/Core.lua:327-328, y se leen en vivo: UI/Arrow.lua:535, UI/Compass.lua:462, UI/Tracker.lua:406-415),
-- su seguimiento propio de TomTom (tomtomFollow, que escondía la flecha de TomTom: Core/TomTom.lua:525-537)
-- y el pin de navegación del juego en el mundo (CVar showInGameNavigation, UI/Arrow.lua:82).
-- Todo se puede volver a prender desde Esc > Opciones > AddOns > Shortest Path Forever.
local function Quiet()
	if E.global.KnuUISPFQuiet then return end
	local db = _G.ShortestPathForeverDB
	if type(db) ~= 'table' then return end
	db.arrow, db.compass, db.journeyTracker, db.tracker = false, false, false, false
	db.tomtomFollow = false
	if SetCVar then pcall(SetCVar, 'showInGameNavigation', '0') end
	E.global.KnuUISPFQuiet = true
end

function K:SetupTomTomRoute()
	if self.tomtomRouteHooked then return end
	local tt = _G.TomTom
	if not (self:IsLoaded('TomTom') and self:IsLoaded('ShortestPathForever') and tt and type(tt.SetCrazyArrow) == 'function') then return end
	if E.db.KnuUITomTomRoute == false then return end
	self.tomtomRouteHooked = true
	pcall(Quiet)
	hooksecurefunc(tt, 'SetCrazyArrow', function(...) pcall(OnArrow, ...) end)
end
