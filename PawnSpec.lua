local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- Flecha de mejora de Pawn sólo para la especialización activa.
-- Pawn marca un objeto como mejora si mejora cualquiera de las escalas visibles
-- (PawnIsItemAnUpgrade, Pawn.lua:3638) y en Forever no elige escala sola: su modo automático
-- sólo existe con especializaciones (VgerCore.SpecsExist, VgerCore.lua:49) y GetSpecialization()
-- devuelve nil (probado en el juego). Los tooltips siguen mostrando todas las escalas; sólo la
-- flecha de las bolsas (Baganator, API/Pawn.lua:62, y la de Pawn) se limita a la escala de la
-- especialización activa.
-- Especialización activa en Forever = la rama de talentos con más puntos. La ventana de talentos
-- lee los puntos así (rama forever de la UI de Blizzard,
-- Blizzard_PlayerSpells/Camelot/ClassTalents/Blizzard_ClassTalentsFrame.lua:95-100 y :339):
-- C_Traits.GetGroupDisplayInfoByTreeID da las 3 ramas en orden y C_Traits.GetGroupCurrencyInfo los
-- puntos gastados; las ramas sin puntos no vienen. El orden coincide con el SpecID de las escalas de
-- Pawn (paladín: 1 Sagrado, 2 Protección, 3 Reprensión; probado en el juego y en las escalas guardadas).
-- Sin puntos en ninguna rama, o con empate, la flecha queda como la deja Pawn.

local active -- índice de rama (1..3) o nil

local function ConfigID()
	local id = C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
	if not id and C_SpecializationInfo and C_SpecializationInfo.GetCombatConfigIDForSpecGroup then
		local group = C_SpecializationInfo.GetActiveSpecGroup and C_SpecializationInfo.GetActiveSpecGroup() or 1
		id = C_SpecializationInfo.GetCombatConfigIDForSpecGroup(group)
	end
	return id
end

local function ReadActive()
	if not (C_Traits and C_Traits.GetConfigInfo and C_Traits.GetGroupDisplayInfoByTreeID and C_Traits.GetGroupCurrencyInfo) then return nil end
	local config = ConfigID()
	local info = config and C_Traits.GetConfigInfo(config)
	local tree = info and info.treeIDs and info.treeIDs[1]
	if not tree then return nil end
	local groups = C_Traits.GetGroupDisplayInfoByTreeID(tree)
	if type(groups) ~= 'table' then return nil end
	local ids, index = {}, {}
	for i, g in ipairs(groups) do ids[i] = g.groupID; index[g.groupID] = i end
	local best, bestSpent, tie = nil, 0, false
	for _, g in ipairs(C_Traits.GetGroupCurrencyInfo(config, ids) or {}) do
		local c = g.currencyInfos and g.currencyInfos[1]
		local spent = c and tonumber(c.spent) or 0
		local i = index[g.traitNodeGroupID]
		if i and spent > bestSpent then best, bestSpent, tie = i, spent, false
		elseif i and spent > 0 and spent == bestSpent then tie = true end
	end
	if tie then return nil end
	return best
end

-- ¿Mejora la escala de la rama activa? Escalas propias sin SpecID (creadas por el jugador) cuentan siempre.
local function UpgradesActive(link)
	local Item = _G.PawnGetItemData and _G.PawnGetItemData(link)
	if not Item then return nil end
	local upgrades = _G.PawnIsItemAnUpgrade(Item)
	if not upgrades then return false end
	local _, _, classID = UnitClass('player')
	local scales = _G.PawnCommon and _G.PawnCommon.Scales or {}
	for _, u in ipairs(upgrades) do
		local scale = scales[u.ScaleName]
		if not scale or scale.SpecID == nil or scale.ClassID ~= classID or scale.SpecID == active then return true end
	end
	return false
end

local function Filter(original)
	return function(link, ...)
		local result = original(link, ...)
		if result ~= true or not active then return result end
		local ok, value = pcall(UpgradesActive, link)
		if ok and value ~= nil then return value end
		return result
	end
end

-- Baganator guarda el resultado por objeto y sólo lo borra con EquippedCacheUpdate (API/Pawn.lua:20-25).
local function Refresh()
	if _G.PawnResetTooltips then pcall(_G.PawnResetTooltips) end
	local S = _G.Syndicator
	if S and S.CallbackRegistry and S.API and S.API.GetCurrentCharacter then
		pcall(S.CallbackRegistry.TriggerEvent, S.CallbackRegistry, 'EquippedCacheUpdate', S.API.GetCurrentCharacter())
	end
end

local function Update()
	local ok, value = pcall(ReadActive)
	value = ok and value or nil
	if value ~= active then
		active = value
		Refresh()
	end
end

function K:SetupPawnSpec()
	if not (self:IsLoaded('Pawn') and _G.PawnIsItemAnUpgrade and _G.PawnShouldItemLinkHaveUpgradeArrowUnbudgeted) then return end
	if K.pawnSpecHooked then return end
	K.pawnSpecHooked = true
	_G.PawnShouldItemLinkHaveUpgradeArrowUnbudgeted = Filter(_G.PawnShouldItemLinkHaveUpgradeArrowUnbudgeted)
	if _G.PawnShouldItemLinkHaveUpgradeArrow then
		_G.PawnShouldItemLinkHaveUpgradeArrow = Filter(_G.PawnShouldItemLinkHaveUpgradeArrow)
	end
	local f = CreateFrame('Frame')
	for _, event in ipairs({ 'PLAYER_ENTERING_WORLD', 'TRAIT_CONFIG_UPDATED', 'TRAIT_CONFIG_LIST_UPDATED',
		'ACTIVE_TALENT_GROUP_CHANGED', 'PLAYER_TALENT_UPDATE', 'PLAYER_LEVEL_UP' }) do
		pcall(f.RegisterEvent, f, event)
	end
	f:SetScript('OnEvent', function() C_Timer.After(0.5, Update) end)
	Update()
end
