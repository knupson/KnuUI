local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Rangos de hechizos en las barras, implementación propia de KnuUI. En Forever el botón se queda
-- con el rango que se arrastró: al aprender uno nuevo no se actualiza solo (guía de macros de
-- Kami Labs; foro de Blizzard us.forums.blizzard.com/en/wow/t/2402539).
--
-- Qué rangos son del mismo hechizo: en Forever la API no los une. Probado en el juego con
-- Martillo de justicia: 853 (Rango 1) y 5588 (Rango 2) dan GetBaseSpell = FindBaseSpellByID = sí mismos
-- e IsSpellBookItemLowRank = false. Lo que comparten es el ícono original (135963) y el nombre, salvo
-- la mayúscula: Blizzard escribe «Martillo de Justicia» el 1 y «Martillo de justicia» el 2 (por eso
-- la comparación exacta de nombres dejaba el botón en rango 1). Clave de cadena = nombre normalizado
-- (minúsculas, también letras acentuadas) + ícono original. Es una heurística: dos hechizos distintos
-- con mismo nombre e ícono se tomarían como uno; no se conoce ese caso.
--
-- La lista de hechizos sale del libro (C_SpellBook, banco del jugador): para cada cadena, el rango más
-- alto conocido. Se revisan las 180 casillas de acción y cada hechizo con rango menor se reemplaza
-- (C_Spell.PickupSpell + PlaceAction + ClearCursor, como Blizzard_ActionBar/Shared/ActionButton.lua; en
-- el juego ya reemplazó Bendición de protección, Bendición de sabiduría y Redención).
-- Las macros no se tocan. Fuera de combate y con el cursor libre; si no se puede, queda pendiente
-- (PLAYER_REGEN_ENABLED, CURSOR_CHANGED). El subtexto («Rango N») puede venir vacío hasta que cargan los
-- datos (SpellBookDocumentation.lua:1020): se vuelve a revisar con SPELL_TEXT_UPDATE y SPELLS_CHANGED.
local SLOTS = 180
local PLAYER_BANK = 0 -- Enum.SpellBookSpellBank.Player (SpellBookConstantsDocumentation.lua:42)

local function Rank(spellID)
	local text = C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(spellID)
	return tonumber(type(text) == 'string' and text:match('(%d+)') or '') or 0
end

local function Name(spellID)
	return C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
end

-- Minúsculas ASCII y Latin-1 en UTF-8 (Á É Í Ó Ú Ñ Ü...: \195\128-\195\158 pasan a +32, salvo ×).
local function Norm(name)
	name = name:lower():gsub('\195([\128-\158])', function(c)
		if c == '\151' then return '\195'..c end
		return '\195'..string.char(c:byte() + 32)
	end)
	return (name:gsub('^%s+', ''):gsub('%s+$', ''))
end

-- Clave de cadena de rangos; nil si falta el nombre, el ícono o el rango.
local function Chain(spellID)
	local name = Name(spellID)
	if type(name) ~= 'string' or name == '' or Rank(spellID) <= 0 then return end
	local icon, original
	if C_Spell.GetSpellTexture then icon, original = C_Spell.GetSpellTexture(spellID) end
	icon = original or icon
	if not icon then return end
	return Norm(name)..'#'..tostring(icon)
end

-- Rango más alto conocido de cada cadena, según el libro de hechizos.
local function Known()
	local best, SB = {}, C_SpellBook
	if not (SB and SB.GetNumSpellBookSkillLines and SB.GetSpellBookSkillLineInfo and SB.GetSpellBookItemInfo) then return best end
	for line = 1, SB.GetNumSpellBookSkillLines() or 0 do
		local info = SB.GetSpellBookSkillLineInfo(line)
		if info and not info.shouldHide then
			for i = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
				local item = SB.GetSpellBookItemInfo(i, PLAYER_BANK)
				local id = item and item.spellID
				if id and not item.isPassive then
					local key, rank = Chain(id), Rank(id)
					if key and (not best[key] or rank > best[key].rank) then best[key] = { id = id, rank = rank } end
				end
			end
		end
	end
	return best
end

-- Pone spellID en la casilla y confirma que quedó.
local function Place(slot, spellID)
	C_Spell.PickupSpell(spellID)
	local kind = GetCursorInfo()
	if kind ~= 'spell' then ClearCursor() return false end
	PlaceAction(slot)
	ClearCursor()
	local _, now = GetActionInfo(slot)
	return now == spellID
end

local pending, waitingCursor, events = false, false, nil

local function Wait(why)
	pending = true
	if why == 'cursor' and events and not waitingCursor then
		waitingCursor = true
		events:RegisterEvent('CURSOR_CHANGED')
	end
end

-- Se puede tocar las barras ahora: opción activa, fuera de combate y con el cursor libre.
local function Ready()
	if E.db.KnuUIRankUpgrade == false then pending = false return false end
	if InCombatLockdown() then Wait('combat') return false end
	if GetCursorInfo and GetCursorInfo() then Wait('cursor') return false end
	pending = false
	return true
end

-- Revisa las casillas contra lo conocido (ya comprobado Ready). Devuelve cuántas cambió.
local function Sweep(best, only)
	local total, done = 0, {}
	for slot = 1, SLOTS do
		local kind, id = GetActionInfo(slot)
		if kind == 'spell' and id then
			local key = Chain(id)
			local target = key and best[key]
			if target and target.id ~= id and target.rank > Rank(id) and (not only or only == key) then
				if Place(slot, target.id) then
					total = total + 1
					done[target.id] = (done[target.id] or 0) + 1
				end
			end
		end
	end
	for id, count in pairs(done) do
		E:Print(format(L["%s rank %d placed on %d action buttons."], Name(id) or '?', Rank(id), count))
	end
	return total
end

-- Al aprender spellID: las casillas con un rango menor de la misma cadena pasan a ese rango.
function K:UpgradeSpellRank(spellID)
	if not spellID then return 0 end
	local key = Chain(spellID)
	if not key then return 0 end
	if not Ready() then return 0 end
	return Sweep({ [key] = { id = spellID, rank = Rank(spellID) } }, key)
end

-- Todas las casillas contra el libro de hechizos (corrige botones que ya estaban atrasados).
function K:UpgradeAllRanks()
	if not Ready() then return 0 end -- antes de recorrer el libro
	return Sweep(Known())
end

function K:SetupRankUpgrade()
	if E.db.KnuUIRankUpgrade == nil then E.db.KnuUIRankUpgrade = true end
	local queued = false
	-- Varias señales seguidas = una sola revisión, medio segundo después (el libro ya tiene el rango nuevo).
	local function Queue()
		if queued then return end
		queued = true
		C_Timer.After(0.5, function() queued = false; pcall(K.UpgradeAllRanks, K) end)
	end
	-- Un marco nuevo no está escuchando el cursor todavía (si se rearma el módulo, la espera vuelve a empezar).
	if events and events.UnregisterAllEvents then events:UnregisterAllEvents() end
	waitingCursor = false
	events = CreateFrame('Frame')
	for _, event in ipairs({ 'LEARNED_SPELL_IN_SKILL_LINE', 'PLAYER_ENTERING_WORLD', 'SPELLS_CHANGED',
		'SPELL_TEXT_UPDATE', 'PLAYER_REGEN_ENABLED' }) do
		events:RegisterEvent(event)
	end
	events:SetScript('OnEvent', function(self, event)
		if event == 'CURSOR_CHANGED' then
			if GetCursorInfo and GetCursorInfo() then return end -- todavía arrastrando
			waitingCursor = false
			self:UnregisterEvent('CURSOR_CHANGED')
			if pending then Queue() end
		elseif event == 'PLAYER_REGEN_ENABLED' then
			if pending then Queue() end
		else
			Queue()
		end
	end)
end
