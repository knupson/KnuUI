local addonName, ns = ...
local E = unpack(ElvUI)
local L = ns.L
local K = E:NewModule('KnuUI')
K.addonName = addonName
K.version = 29 -- Clave propia del perfil; se confirma al terminar el asistente.

local function Set(db, values)
	for key, value in pairs(values) do
		if type(value) == 'table' then
			db[key] = db[key] or {}
			Set(db[key], value)
		else
			db[key] = value
		end
	end
end

K.Set = Set

-- Datatext de la estadística principal según la clase ('Primary Stat' mostraba Intelecto sin
-- especialización en Forever).
local STAT_BY_CLASS = {
	WARRIOR = 'Strength', PALADIN = 'Strength', DEATHKNIGHT = 'Strength',
	ROGUE = 'Agility', HUNTER = 'Agility', DRUID = 'Agility', SHAMAN = 'Agility', MONK = 'Agility', DEMONHUNTER = 'Agility',
	MAGE = 'Intellect', PRIEST = 'Intellect', WARLOCK = 'Intellect', EVOKER = 'Intellect',
}
function K:PrimaryStatText()
	return STAT_BY_CLASS[E.myclass] or 'Primary Stat'
end

function K:CanApply()
	if not E.Forever then
		E:Print(L["KnuUI requires World of Warcraft: Forever."])
		return false
	end
	if InCombatLockdown() then
		E:Print(L["Leave combat before applying KnuUI."])
		return false
	end
	return true
end

function K:CleanupLegacy()
	-- Migración de claves propias de la versión anterior, sólo si existen.
	local old = E.db.datatexts.panels.ForeverUI_Data
	if old then old.enable = false end
	if E.db.movers then E.db.movers.DTPanelForeverUI_DataMover = nil end
end

function K:ApplyAll()
	if not self:CanApply() then return end
	self:ApplyLayout()
	self:ApplyTheme()
	self:ApplyChat()
	self:ApplyNameplates()
	self:ApplyTracker()
	self:ApplyCamera() -- una sola vez; después se fuerza desde las opciones
	if E.db.KnuUITanks then self:ApplyTanks(true) end -- modo de prueba elegido
	self:ApplyAddons()
	E.db.KnuUILayoutVersion = self.version
	ReloadUI()
end

-- ElvUI omite la salud en E.Modern: Modules/ActionBars/ActionBars.lua:993.
-- Hook del boceto v4 con los mecanismos nativos (:914,937).
local function KeepInjuredBarsVisible(parent)
	local panel = E.db.datatexts.panels.KnuUI_Data
	if not (E.Forever and panel and panel.enable) then return end
	-- En Forever la vida puede ser un valor secreto (sobre todo en combate) y compararla
	-- tira error: se omite. En combate las barras ya se ven por el fader nativo.
	local cur, max = UnitHealth('player'), UnitHealthMax('player')
	if E:IsSecretValue(cur) or E:IsSecretValue(max) then return end
	if cur < max then
		parent.mouseLock = true
		E:UIFrameFadeIn(parent, 0.2, parent:GetAlpha(), 1)
		E:GetModule('ActionBars'):FadeBlings(1)
	end
end

function K:Initialize()
	self:SetupInstaller()
	self:SetupAFK()
	if E.Forever then
		for _, setup in ipairs({ 'SetupAddonSkins', 'SetupButtons', 'SetupDock', 'SetupWoWProSkin', 'SetupTanks', 'SetupTracker', 'SetupDecor', 'SetupPanels', 'SetupWoWProES', 'SetupTomTomSkin', 'SetupBaganatorSkin', 'SetupExtras', 'SetupBNToast', 'SetupRaidMarkers', 'SetupFlightTimer', 'SetupCombatZoom', 'SetupPanelFade', 'SetupLootMonitor', 'SetupRankUpgrade', 'SetupPawnSpec', 'SetupTomTomRoute', 'SetupOffhand', 'SetupWorkspace' }) do
			local ok, err = pcall(self[setup], self)
			if not ok then E:Print(format(L["KnuUI: %s failed: %s"], setup, tostring(err))) end
		end
	end
	local parent = E:GetModule('ActionBars').fadeParent
	if parent then
		parent:HookScript('OnEvent', KeepInjuredBarsVisible)
		KeepInjuredBarsVisible(parent)
	end
	if E.Forever then
		self:CleanupLegacy()
		if not E.db.datatexts.panels.KnuUI_Data or E.db.KnuUILayoutVersion ~= self.version then
			self:OpenInstaller()
		end
	end
end

E:RegisterModule(K:GetName())
