local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Rangos de hechizos en las barras, implementación propia de KnuUI. En Forever el botón se queda
-- con el rango que se arrastró: al aprender uno nuevo no se actualiza solo (guía de macros de
-- Kami Labs; foro de Blizzard us.forums.blizzard.com/en/wow/t/2402539).
-- Al aprender un hechizo (LEARNED_SPELL_IN_SKILL_LINE, rama forever
-- SpellBookDocumentation.lua:849-858, trae el spellID) se buscan en las 180 casillas de acción los
-- rangos más bajos del mismo hechizo y se reemplazan por el nuevo: C_Spell.PickupSpell + PlaceAction
-- (la usa Blizzard_ActionBar/Shared/ActionButton.lua) + ClearCursor. Sólo fuera de combate; en
-- combate queda pendiente hasta salir. Las macros no se tocan.
local SLOTS = 180

local function Rank(spellID)
	local text = C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(spellID)
	return tonumber(type(text) == 'string' and text:match('(%d+)') or '') or 0
end

local function Name(spellID)
	return C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
end

local pending = {}

-- Devuelve cuántas casillas se actualizaron.
function K:UpgradeSpellRank(spellID)
	if E.db.KnuUIRankUpgrade == false or not spellID then return 0 end
	if InCombatLockdown() then pending[spellID] = true return 0 end
	if GetCursorInfo and GetCursorInfo() then return 0 end -- el jugador está arrastrando algo
	local name, rank = Name(spellID), Rank(spellID)
	if not name or rank == 0 then return 0 end -- sin rangos: nada que actualizar
	local count = 0
	for slot = 1, SLOTS do
		local kind, id = GetActionInfo(slot)
		if kind == 'spell' and id and id ~= spellID and Name(id) == name and Rank(id) < rank then
			C_Spell.PickupSpell(spellID)
			PlaceAction(slot)
			ClearCursor()
			count = count + 1
		end
	end
	if count > 0 then
		E:Print(format(L["KnuUI: %s rank %d placed on %d action buttons."], name, rank, count))
	end
	return count
end

function K:SetupRankUpgrade()
	if E.db.KnuUIRankUpgrade == nil then E.db.KnuUIRankUpgrade = true end
	local f = CreateFrame('Frame')
	f:RegisterEvent('LEARNED_SPELL_IN_SKILL_LINE')
	f:RegisterEvent('PLAYER_REGEN_ENABLED')
	f:SetScript('OnEvent', function(_, event, spellID)
		if event == 'PLAYER_REGEN_ENABLED' then
			local queue = pending
			pending = {}
			for id in pairs(queue) do pcall(K.UpgradeSpellRank, K, id) end
		else
			-- Un instante después, cuando el libro ya tiene el rango nuevo.
			C_Timer.After(0.5, function() pcall(K.UpgradeSpellRank, K, spellID) end)
		end
	end)
end
