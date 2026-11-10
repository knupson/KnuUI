local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Cámara: preset "Immersive" (LudiusMaximus, autor de DynamicCam), que viene dentro del addon.
-- API real (Interface/AddOns/DynamicCam/):
--   Core.lua:15        DynamicCam es global (AceAddon)
--   Core.lua:827       self.db = AceDB "DynamicCamDB"
--   Presets.lua:12-16  preset "Immersive"; Presets.lua:32 DynamicCam:LoadPreset(name)
--   Sharing.lua:368    ImportIntoCurrentProfile (resetea el perfil actual y reinicia el addon; sin /reload)
-- Se usa un perfil propio "KnuUI" para no pisar el perfil del jugador, y se aplica una sola vez.

-- Presets incluidos en DynamicCam (Presets.lua:12-27). Por defecto el más marcado.
local DEFAULT_PRESET, PROFILE = "Shushudaa's preset", 'KnuUI'

function K:ApplyCamera(force, preset)
	local PRESET = preset or E.global.KnuUICameraPreset or DEFAULT_PRESET
	if not self:IsLoaded('DynamicCam') then
		E:Print(L["KnuUI: DynamicCam is not installed."])
		return false
	end
	if InCombatLockdown() then
		E:Print(L["KnuUI: leave combat to apply the camera."])
		return false
	end
	local dc = _G.DynamicCam
	if not (dc and dc.db and type(dc.db.SetProfile) == 'function' and type(dc.LoadPreset) == 'function') then
		E:Print(L["KnuUI: the DynamicCam API was not found."])
		return false
	end
	if E.global.KnuUICameraApplied and not force then return true end
	local ok, err = pcall(function()
		dc.db:SetProfile(PROFILE)
		dc:LoadPreset(PRESET)
	end)
	if not ok then
		E:Print(format(L["KnuUI: could not apply the camera: %s"], tostring(err)))
		return false
	end
	E.global.KnuUICameraApplied = true
	E.global.KnuUICameraPreset = PRESET
	self:DisableBrokenCamSituations()
	self:SoftenCamSituations()
	self:ApplyCombatZoom()
	E:Print(format(L['KnuUI: camera "%s" applied to DynamicCam profile "%s".'], PRESET, PROFILE))
	return true
end

-- Situaciones de DynamicCam que fallan en Forever con su script y abren su ventana de error:
-- 200 "Piedra de hogar/Teletransporte" (DefaultSettings.lua:418-421; 'teleportSpells' nil al abrir
-- una caja) y 201 "Hechizos molestos" (:610-632; "bad argument #1 to 'pairs'"). Se apagan.
local BROKEN_SITUATIONS = { '200', '201' }
function K:DisableBrokenCamSituations()
	local dc = self:IsLoaded('DynamicCam') and _G.DynamicCam
	local situations = dc and dc.db and dc.db.profile and dc.db.profile.situations
	if not situations then return end
	for _, id in ipairs(BROKEN_SITUATIONS) do
		if situations[id] then situations[id].enabled = false end
	end
end

-- Todos los cambios de cámara sutiles (pedido del user: hablar con un jugador mareaba).
--   - Sin cambios de vista: SetView salta con la mezcla del juego, no con la de DynamicCam
--     (SituationManager.lua:725-745). Las situaciones con viewZoomType "view" pierden ese cambio.
--   - Sin giros de cámara (rotation).
--   - Toda transición de entrada y salida dura al menos 2,5 s (transitionTime, DefaultSettings.lua:25-29;
--     el valor por defecto es 1 s).
-- La situación "NPC Interaction" (300) se activa también al cambiar de objetivo (DefaultSettings.lua:643).
local SOFT_TIME = 2.5
local SITUATION_IDS = { '001', '002', '004', '005', '006', '020', '021', '023', '024', '030', '031', '033',
	'034', '050', '051', '060', '061', '100', '101', '102', '103', '104', '105', '106', '107', '112', '115',
	'120', '130', '160', '170', '200', '201', '300', '301', '302', '303', '310', '320', '323', '325', '330' }

function K:SoftenCamSituations()
	local dc = self:IsLoaded('DynamicCam') and _G.DynamicCam
	local situations = dc and dc.db and dc.db.profile and dc.db.profile.situations
	if not situations then return 0 end
	local seen, count = {}, 0
	local function Soften(s)
		if type(s) ~= 'table' or seen[s] then return end
		seen[s] = true
		s.transitionTime = s.transitionTime or {}
		local tt = s.transitionTime
		tt.timeToEnter = math.max(tonumber(tt.timeToEnter) or 1, SOFT_TIME)
		tt.timeToExit = math.max(tonumber(tt.timeToExit) or 1, SOFT_TIME)
		if type(s.viewZoom) == 'table' and s.viewZoom.viewZoomType == 'view' then s.viewZoom.enabled = false end
		if type(s.rotation) == 'table' then s.rotation.enabled = false end
		count = count + 1
	end
	for _, id in ipairs(SITUATION_IDS) do Soften(situations[id]) end
	for _, s in pairs(situations) do Soften(s) end -- situaciones propias del jugador
	return count
end

-- Distancia máxima y zoom automático en combate, implementación propia de KnuUI.
-- Distancia máxima: CVar cameraDistanceMaxZoomFactor 2.6 = 39 m, el tope que usa DynamicCam
-- (DefaultSettings.lua:891, Core.lua:1020); también va a los CVars del perfil de DynamicCam, que
-- los vuelve a poner en cada situación (Core.lua:787-791).
-- Zoom en combate: al entrar se guarda la distancia actual y se aleja hasta el tope; al salir se
-- vuelve a la distancia guardada (GetCameraZoom / CameraZoomOut / CameraZoomIn).
-- No se tocan las situaciones de DynamicCam: vienen apagadas (DefaultSettings.lua:11) y prenderlas
-- trae sus ajustes de hombro, que corrían la cámara a los costados al entrar y salir de combate.
local MAX_FACTOR, MAX_ZOOM = 2.6, 39
local saved

function K:ApplyCombatZoom()
	if InCombatLockdown() then return false end
	if E.global.KnuUICombatZoom == false then return true end
	SetCVar('cameraDistanceMaxZoomFactor', MAX_FACTOR)
	local dc = self:IsLoaded('DynamicCam') and _G.DynamicCam
	local standard = dc and dc.db and dc.db.profile and dc.db.profile.standardSettings
	if standard and type(standard.cvars) == 'table' then standard.cvars.cameraDistanceMaxZoomFactor = MAX_FACTOR end
	return true
end

-- Suave: con DynamicCam se usa su LibCamera (Libs/LibCamera/LibCamera.lua:197, SetZoom con
-- duración y curva; es lo mismo que usa DynamicCam en Core.lua:1490) con la curva InOutSine de
-- LibEasing (LibEasing.lua:430): arranca y frena despacio. Duración fija, no por velocidad.
-- Sin DynamicCam queda el zoom común de Blizzard.
local ZOOM_OUT_TIME, ZOOM_BACK_TIME = 3, 4 -- con 2,5 / 2 s la vuelta al salir de combate mareaba

local function Zoom(target, duration)
	local camera = LibStub and LibStub('LibCamera-1.0', true)
	local easing = LibStub and LibStub('LibEasing-1.0', true)
	if camera and camera.SetZoom then
		camera:SetZoom(target, duration, easing and easing.InOutSine)
		return
	end
	local current = GetCameraZoom()
	if target > current then CameraZoomOut(target - current) else CameraZoomIn(current - target) end
end

function K:CombatZoom(entering)
	if E.global.KnuUICombatZoom == false or type(GetCameraZoom) ~= 'function' then saved = nil return end
	local current = GetCameraZoom()
	if entering then
		saved = current
		if current < MAX_ZOOM - 0.5 then Zoom(MAX_ZOOM, ZOOM_OUT_TIME) end
	elseif saved then
		if current > saved + 0.5 then Zoom(saved, ZOOM_BACK_TIME) end
		saved = nil
	end
end

-- Al entrar, después de que DynamicCam cargue su perfil (Core.lua:653 demora su arranque).
-- La versión anterior (3.4 beta sin publicar) prendía las situaciones de combate de DynamicCam:
-- una vez se recarga el preset de cámara de KnuUI para deshacerlo (ApplyCamera -> LoadPreset).
function K:SetupCombatZoom()
	local events = CreateFrame('Frame')
	events:RegisterEvent('PLAYER_REGEN_DISABLED')
	events:RegisterEvent('PLAYER_REGEN_ENABLED')
	events:SetScript('OnEvent', function(_, event) pcall(K.CombatZoom, K, event == 'PLAYER_REGEN_DISABLED') end)
	C_Timer.After(3, function()
		if E.global.KnuUICombatZoomV ~= 2 and E.global.KnuUICameraApplied and K:IsLoaded('DynamicCam') and not InCombatLockdown() then
			E.global.KnuUICombatZoomV = 2
			pcall(K.ApplyCamera, K, true)
		end
		pcall(K.DisableBrokenCamSituations, K) -- también en perfiles ya aplicados
		pcall(K.SoftenCamSituations, K)
		pcall(K.ApplyCombatZoom, K)
	end)
end
