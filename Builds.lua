local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Recomendaciones de interfaz, no talentos. Reutilizan los motores de Roles/Tanks/Nameplates.
-- Claves propias verificadas: Tanks.lua:37-38,139; Roles.lua:121; RaidMarkers.lua,
-- Extras.lua (combat glow), Fade.lua y LootMonitor.lua (calidades).
local roles = {
	tank = { label = L["Tank build"], desc = L["Columns, both compact blocks, threat borders and plates, group markers, combat glow, Details always visible. Loot: green for you, blue for the group."],
		settings = { KnuUITanks = true, KnuUICompactLeft = true, KnuUICompactRight = true,
			KnuUIRaidMarkers = 'group', KnuUICombatGlow = true, KnuUIDetailsFade = false,
			KnuUILootMonitor = true, KnuUILootSelfQuality = 2, KnuUILootGroupQuality = 3 } },
	mdps = { label = L["Melee build"], desc = L["Base layout without columns or compact blocks, group markers, combat glow, Details fades outside combat. Loot: white for you, green for the group."],
		settings = { KnuUITanks = false, KnuUICompactLeft = false, KnuUICompactRight = false,
			KnuUIRaidMarkers = 'group', KnuUICombatGlow = true, KnuUIDetailsFade = true,
			KnuUILootMonitor = true, KnuUILootSelfQuality = 1, KnuUILootGroupQuality = 2 } },
	rdps = { label = L["Ranged build"], desc = L["Base layout without columns or compact blocks, larger cast bar and target debuffs, group markers, no combat glow, Details fades. Loot: white for you, green for the group."],
		settings = { KnuUITanks = false, KnuUICompactLeft = false, KnuUICompactRight = false,
			KnuUIRaidMarkers = 'group', KnuUICombatGlow = false, KnuUIDetailsFade = true,
			KnuUILootMonitor = true, KnuUILootSelfQuality = 1, KnuUILootGroupQuality = 2 } },
	healer = { label = L["Healer build"], desc = L["Columns, compact right block, centred party and raid with incoming heals and HoTs, group markers, no combat glow, Details fades. Loot: green for you, blue for the group."],
		settings = { KnuUITanks = true, KnuUICompactLeft = false, KnuUICompactRight = true,
			KnuUIRaidMarkers = 'group', KnuUICombatGlow = false, KnuUIDetailsFade = true,
			KnuUILootMonitor = true, KnuUILootSelfQuality = 2, KnuUILootGroupQuality = 3 } },
}

-- ElvUI/Game/Shared/Defaults/Profile.lua:3286-3303 (barPet.enabled/mouseover),
-- 3304-3322 (stanceBar.enabled/mouseover), 3323-3340 (totemBar.enable/mouseover),
-- 2046-2063,2288 (unitframe.units.player.classbar.enable).
local classes = {
	WARRIOR = { roles = { 'tank', 'mdps' }, suggested = 'mdps', stance = true },
	PALADIN = { roles = { 'tank', 'mdps', 'healer' }, suggested = 'mdps', stance = true },
	HUNTER = { roles = { 'rdps' }, suggested = 'rdps', pet = true },
	ROGUE = { roles = { 'mdps' }, suggested = 'mdps', stance = true, power = true },
	PRIEST = { roles = { 'rdps', 'healer' }, suggested = 'healer' },
	SHAMAN = { roles = { 'mdps', 'rdps', 'healer' }, suggested = 'rdps', totem = true },
	MAGE = { roles = { 'rdps' }, suggested = 'rdps' },
	WARLOCK = { roles = { 'rdps' }, suggested = 'rdps', pet = true, power = true },
	DRUID = { roles = { 'tank', 'mdps', 'rdps', 'healer' }, suggested = 'mdps', stance = true, power = true },
}

K.builds, K.buildOrder = {}, {}
for _, class in ipairs({ 'WARRIOR', 'PALADIN', 'HUNTER', 'ROGUE', 'PRIEST', 'SHAMAN', 'MAGE', 'WARLOCK', 'DRUID' }) do
	local cfg = classes[class]
	for _, role in ipairs(cfg.roles) do
		local id = class..'_'..role
		local settings = E:CopyTable({}, roles[role].settings)
		settings.KnuUIRole = role
		settings.actionbar = {
			barPet = { enabled = cfg.pet == true, mouseover = false },
			stanceBar = { enabled = cfg.stance == true, mouseover = false },
			totemBar = { enable = cfg.totem == true, mouseover = false },
		}
		settings.unitframe = { units = { player = { classbar = { enable = cfg.power == true } } } }
		local notes = { roles[role].desc, L["Reapplies KnuUI nameplates; threat indicator only for tanks. Resets the Details eye override. Bars for other classes are disabled; class resources only appear when supported by Forever."] }
		if cfg.pet then notes[#notes + 1] = L["Pet bar enabled, without mouseover hiding."] end
		if cfg.stance then notes[#notes + 1] = L["Stance, form, stealth or aura bar enabled, without mouseover hiding."] end
		if cfg.totem then notes[#notes + 1] = L["Totem bar enabled, without mouseover hiding."] end
		if cfg.power then notes[#notes + 1] = L["Class resource bar enabled."] end
		K.builds[id] = { class = class, role = role, label = roles[role].label,
			desc = table.concat(notes, '\n\n'), settings = settings }
		K.buildOrder[#K.buildOrder + 1] = id
	end
end

function K:SuggestedBuild()
	local cfg = classes[E.myclass]
	if not cfg then return nil end
	local role = E.db.KnuUIRole or E.private.KnuUIRole or cfg.suggested
	local id = E.myclass..'_'..role
	return self.builds[id] and id or E.myclass..'_'..cfg.suggested
end

function K:SelectedBuild()
	local id = E.db.KnuUIBuild
	return self.builds[id] and self.builds[id].class == E.myclass and id or self:SuggestedBuild()
end

function K:ApplyBuild(id)
	local build = self.builds[id]
	if not build or build.class ~= E.myclass or not self:CanApply() then return false end
	-- Los motores reconstruyen el diseño: aplicar las barras de clase al final para no pisarlas.
	for key, value in pairs(build.settings) do
		if type(value) ~= 'table' then E.db[key] = value end
	end
	self:ApplyNameplates()
	E.private.KnuUIRole = build.role -- mismo recuerdo por personaje que Roles.lua:122
	self:ApplyTanks(build.settings.KnuUITanks) -- ambos caminos reaplican el overlay del rol
	self:ApplySideBlocks() -- también restaura los anchos cuando se sale de columnas
	self.Set(E.db.actionbar, build.settings.actionbar)
	self.Set(E.db.unitframe, build.settings.unitframe)
	E.db.KnuUIDetailsKeep = false
	if self.UpdateRaidMarkers then self:UpdateRaidMarkers() end
	if self.UpdatePanelFade then self:UpdatePanelFade() end
	E.db.KnuUIBuild = id
	return true
end
