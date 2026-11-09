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
	E:Print(format(L['KnuUI: camera "%s" applied to DynamicCam profile "%s".'], PRESET, PROFILE))
	return true
end
