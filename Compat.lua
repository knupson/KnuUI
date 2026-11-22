local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Las rutas de terceros citadas parten de D:/World of Warcraft/_forever_/Interface/AddOns/.
-- C_AddOns: _ref/ElvUI/Game/Shared/General/Config.lua:25,107.
function K:IsLoaded(name)
	if not C_AddOns or type(C_AddOns.IsAddOnLoaded) ~= 'function' then return false end
	local ok, loaded = pcall(C_AddOns.IsAddOnLoaded, name)
	return ok and not not loaded
end

function K:WithAddon(name, callback)
	if not self:IsLoaded(name) then return false, L["not installed or not loaded"] end
	local ok, result = pcall(callback)
	if not ok then return false, L["incompatible API; the adjustment could not be completed"] end
	return true, result
end

function K:ApplySLE()
	-- addons/ElvUI_SLE/defaults/profile.lua:1429-1435; modules/raidmarkers.lua:17,163;
	-- Se conserva el ajuste de marcas de banda; su barra de botones queda intacta.
	self:WithAddon('ElvUI_SLE', function()
		if E.db.sle and E.db.sle.raidmarkers then E.db.sle.raidmarkers.visibility = 'INPARTY' end
	end)
end

K.addons = {
	{ id = 'Details', label = 'Details!', apply = function()
		-- Details/classes/class_instance.lua:1163; API UI.txt:93-105,124-126;
		-- frames/window_main.lua:3615-3623,3895. nil conserva los otros parámetros.
		if not Details or type(Details.GetInstance) ~= 'function' then error('API') end
		local windows = {}
		for i = 1, 2 do
			local instance = Details:GetInstance(i)
			if instance then
				if type(instance.SetBarSettings) ~= 'function' or type(instance.SetBarTextSettings) ~= 'function' then error('API') end
				windows[#windows + 1] = instance
			end
		end
		for _, instance in ipairs(windows) do
			instance:SetBarSettings(nil, 'Melli')
			instance:SetBarTextSettings(nil, 'Expressway')
		end
		return #windows > 0 and L["texture and font applied; the dock keeps its anchors"] or L["no existing windows; no windows were created"]
	end },
	{ id = 'Baganator', label = 'Baganator', apply = function()
		-- Baganator/Skins/ElvUI.lua:220-221 registra su propia skin.
		return L["includes its own ElvUI skin; pick it in Baganator. Your bags are kept"]
	end },
	{ id = 'DBM-Core', label = 'DBM', apply = function()
		-- Skins/AddOns/DBM-Core.lua aplica Texture/Font con el setter verificado de DBT.
		return L["DBM bars follow the addon skins setting; reload to apply it"]
	end },
	{ id = 'WoWPro', label = 'WoW-Pro', manual = true, apply = function()
		-- WoWPro/WoWPro_Frames.lua:627-645 guarda position en píxeles;
		-- :688-705,735-752 restaura position/expansionAnchor (divide por escala).
		if not WoWProDB or type(WoWProDB.profile) ~= 'table' then error('perfil') end
		WoWProDB.profile.expansionAnchor = 'TOPRIGHT'
		WoWProDB.profile.position = { 'TOPRIGHT', 'UIParent', 'TOPRIGHT', -200, -260 }
		return L["position saved below the minimap; reload to see it"]
	end },
	{ id = 'Questie', label = 'Questie', manual = true, apply = function()
		-- Questie/Modules/Tracker/TrackerBaseFrame.lua:131-133,353:
		-- TrackerLocation es una tupla SetPoint persistida, relativa a UIParent.
		if not Questie or not Questie.db or type(Questie.db.profile) ~= 'table' then error('perfil') end
		Questie.db.profile.TrackerLocation = { 'TOPRIGHT', 'UIParent', 'TOPRIGHT', -430, -260 }
		return L["position saved to the left of WoW-Pro; reload to see it"]
	end },
}

function K:ApplyAddon(entry)
	if not self:CanApply() then return false end
	local ok, message = self:WithAddon(entry.id, entry.apply)
	E:Print(entry.label..': '..message..'.')
	return ok
end

function K:ApplyAddons()
	-- ElvUI/Game/Shared/Skins/CooldownManager.lua:8; Defaults/Private.lua:108.
	-- Sólo al aplicar la configuración de addons, junto con Core.lua:84.
	E.private.skins.blizzard.cooldownManager = true
	for _, entry in ipairs(self.addons) do
		-- Mover rastreadores (WoW-Pro, Questie) sólo con su botón: el user ya los tiene ubicados.
		if not entry.manual and self:IsLoaded(entry.id) then self:ApplyAddon(entry) end
	end
end

-- Pawn y la hoja de personaje de ElvUI. En Forever, Pawn cuelga su botón de PaperDollItemsFrame al iniciar sesión
-- (Pawn/PawnUI.lua:71-73, llamado desde Pawn.lua:254 en PLAYER_LOGIN), y ElvUI trata a todo botón de ese marco como
-- casilla de equipo y le hace S:HandleIcon(Slot.icon) (ElvUI/Game/Shared/Skins/Character.lua:859-865); el botón de
-- Pawn no tiene .icon (PawnUI.xml:128, UIPanelButtonTemplate) y ElvUI corta con «attempt to index local 'icon'» sin
-- terminar la hoja. Mientras ElvUI no la haya estilado, el botón queda en su padre del XML (PaperDollFrame,
-- PawnUI.xml:276); después de cada S:LoadSkin se mira si ya lo hizo (CharacterHeadSlot con plantilla, Toolkit.lua:297)
-- y entonces Pawn lo vuelve a poner donde quiere. Con el estilo de personaje de ElvUI apagado no se toca nada.
function K:SetupPawnPaperDoll()
	if self.pawnPaperDoll or not E.Forever or type(_G.PawnUI_InventoryPawnButton_Move) ~= 'function' then return end
	local S = E:GetModule('Skins', true)
	if not (S and S.LoadSkin and _G.PawnUI_InventoryPawnButton and _G.PaperDollFrame) then return end
	self.pawnPaperDoll = true
	local pending = true
	local function Skinned()
		local slot = _G.CharacterHeadSlot
		return slot and slot.template ~= nil
	end
	local function SkinOn()
		local blizzard = E.private and E.private.skins and E.private.skins.blizzard
		return blizzard and blizzard.enable and blizzard.character
	end
	local function Hold()
		if pending and SkinOn() and not Skinned() then
			_G.PawnUI_InventoryPawnButton:SetParent(_G.PaperDollFrame)
		end
	end
	hooksecurefunc('PawnUI_InventoryPawnButton_Move', Hold)
	hooksecurefunc(S, 'LoadSkin', function()
		if pending and Skinned() then
			pending = false
			if _G.PawnCommon then pcall(_G.PawnUI_InventoryPawnButton_Move) end
		end
	end)
	Hold()
end
K:SetupPawnPaperDoll()
