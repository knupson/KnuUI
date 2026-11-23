local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- La flecha de TomTom por el camino más corto de Shortest Path Forever: se ve sólo la flecha de TomTom, sin la flecha, brújula
-- ni secciones propias de Shortest Path.
-- 1) Cuando algo (WoW-Pro, Questie, /way) apunta la flecha de TomTom a un destino, KnuUI se lo pasa a
--    Shortest Path con su API pública: ShortestPathForever.API.Navigate(owner, uiMapID, x, y, title)
--    (ShortestPathForever/Core/API.lua:568; el punto es el mismo uiMapID y 0-1 que usa TomTom,
--    Core/TomTom.lua). Shortest Path calcula la ruta más corta (caminos, vuelos, barcos, portales).
-- 2) Shortest Path guía la ruta curva por curva; KnuUI lee la próxima curva o parada con API.Guidance
--    y la copia a un punto temporal de TomTom (TomTom:AddWaypoint, core/waypoints.lua:415) que toma la flecha.
-- 3) Al terminar el viaje (o cerca del destino, donde Shortest Path deja de poner el punto) la flecha
--    vuelve al destino original.

local OWNER = 'KnuUI'
local original, mirror, mirrorKey, active, restoring, subscribed
local Subscribe

local function API()
	local spf = _G.ShortestPathForever
	return spf and spf.API
end

local function Remove(uid)
	if uid and _G.TomTom and _G.TomTom.RemoveWaypoint then pcall(_G.TomTom.RemoveWaypoint, _G.TomTom, uid) end
end

local function Stop()
	active = false
	Remove(mirror)
	mirror, mirrorKey = nil, nil
end

-- La flecha apunta a un punto de TomTom que no es de KnuUI (sin que KnuUI lo vuelva a desviar).
local function Point(tt, uid)
	restoring = true
	pcall(tt.SetCrazyArrow, tt, uid, uid.arrivaldistance or 15, uid.title)
	restoring = false
end

-- La flecha vuelve al destino original (si TomTom todavía lo tiene).
local function Restore()
	Stop()
	local tt = _G.TomTom
	if original and tt and tt.IsValidWaypoint and tt:IsValidWaypoint(original) then Point(tt, original) end
end

-- La próxima curva o parada. Con sus opciones de fábrica (guideStops = true, arrowDirect = false;
-- Core/Core.lua:124,131) Shortest Path no pone el punto de usuario del juego (Journey/JourneyGuide.lua:544-549):
-- se lee con API.Guidance (Core/API.lua:698; point = {map, x, y}, JourneyGuide.lua:905-935).
-- Sin esa función (versión vieja) queda el punto de usuario del juego.
local function NextPoint(api)
	if type(api.Guidance) == 'function' then
		local ok, g = pcall(api.Guidance)
		local p = ok and type(g) == 'table' and g.point
		if p and p.map and p.x and p.y then return p.map, p.x, p.y end
		return nil
	end
	local wp = C_Map.GetUserWaypoint and C_Map.GetUserWaypoint()
	local pos = wp and wp.position
	if pos then return wp.uiMapID, pos.x, pos.y end
end

local function Sync()
	if not active then return end
	local api, tt = API(), _G.TomTom
	if not (api and tt) then return Stop() end
	if not api.CurrentStop(OWNER) then return Restore() end -- el viaje terminó, se canceló o lo tomó otro
	local map, x, y = NextPoint(api)
	if not map then
		-- Cerca del destino (o recalculando) no hay curva: la flecha apunta al destino y se sigue escuchando.
		if mirror or mirrorKey then Restore(); active = true end
		return
	end
	local key = format('%d:%.4f:%.4f', map, x, y)
	if key == mirrorKey then return end
	Remove(mirror)
	mirror, mirrorKey = nil, key
	local uid = tt:AddWaypoint(map, x, y, {
		title = original and original.title or nil,
		from = OWNER, persistent = false, minimap = false, world = false,
		crazy = true, silent = true, cleardistance = 0, arrivaldistance = 0,
	})
	-- TomTom devuelve el punto que ya tenga mismo mapa, coordenadas y título (core/waypoints.lua:435-437):
	-- si no lo creó KnuUI no se guarda como temporal (Stop lo borraría) y sólo se le apunta la flecha.
	if type(uid) == 'table' and uid.from ~= OWNER then
		Point(tt, uid)
	else
		mirror = uid
	end
end

local function OnArrow(_, uid)
	if restoring or type(uid) ~= 'table' or uid == mirror or uid.from == OWNER or uid.corpse then return end
	local api = API()
	if not (api and api.Navigate) then return end
	if not (uid[1] and uid[2] and uid[3]) then return end
	Stop()
	original = uid
	pcall(Subscribe) -- por si la API no estaba publicada al iniciar
	if api.Navigate(OWNER, uid[1], uid[2], uid[3], uid.title) then
		active = true
		pcall(Sync)
	end
end

-- Los cambios de la guía llegan por la suscripción pública (ForeverCore/Core/APIKit.lua:103; canales guidance,
-- leg, ended y active, Core/API.lua:81-92): sin sondeo por tiempo.
function Subscribe()
	local api = API()
	if subscribed or not (api and type(api.Subscribe) == 'function') then return end
	subscribed = true
	api.Subscribe(function() pcall(Sync) end)
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
	pcall(Subscribe)
end
