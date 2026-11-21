local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- Cuántos votaron qué en las tiradas de ElvUI. ElvUI escribe esos números sólo con LOOT_HISTORY_ROLL_CHANGED, y lo
-- registra sólo `if not E.Modern` (ElvUI/Game/Shared/Modules/Misc/LootRoll.lua:581-585); en Forever E.Modern es
-- verdadero (General/Initialize.lua:114) y ese evento no existe (probado en el juego 2026-11-20). Forever trae el
-- sistema de Retail: LOOT_HISTORY_UPDATE_DROP(encounterID, lootListKey) y C_LootHistory.GetSortedInfoForDrop
-- (rama forever, LootHistoryDocumentation.lua:59-174); el botín de bichos comunes llega como encuentro 0
-- «Miscelánea» (probado en el juego). Cada objeto del historial se ata a una sola barra por su rollID. Si alguna vez
-- hay dos candidatos del mismo ítem (dos barras para un objeto, o dos objetos para una barra), ese ítem queda bloqueado:
-- nada suyo se ata hasta que terminen todos los objetos y se cierren todas las barras involucradas (pedido del user
-- 2026-11-20: mejor sin número que con el número de otra tirada).
local drops = {}   -- 'encuentro:clave' -> { encounterID, lootListKey, link, bar, rollID, lost }
local blocked = {} -- ítem -> { drops = { id = true }, rolls = { rollID = true } }

-- EncounterLootDropRollState -> tipo de tirada de ElvUI (LootRoll.lua:33-39).
local ROLL_TYPE = { [0] = 1, [1] = 1, [2] = 4, [3] = 2, [5] = 0 }
local BUTTONS = { [0] = 'pass', [1] = 'need', [2] = 'greed', [3] = 'disenchant', [4] = 'transmog' }

local function Secret(value) return issecretvalue and issecretvalue(value) end
local function ItemID(link) return type(link) == 'string' and link:match('item:(%d+)') end
local function Finished(info) return info.winner ~= nil or info.allPassed end
local function Key(link) return ItemID(link) or link end

local function Bars()
	local misc = E:GetModule('Misc', true)
	return misc and misc.RollBars or {}
end

-- Barra libre (mostrando una tirada y sin objeto atado) que corresponde al objeto: primero por enlace completo,
-- después por número de objeto. Sólo si hay exactamente una.
local function Taken(bar)
	for _, drop in pairs(drops) do
		if drop.bar == bar and drop.rollID == bar.rollID then return true end
	end
end
local function FindBar(link)
	for _, exact in ipairs({ true, false }) do
		local found, count = nil, 0
		for _, bar in ipairs(Bars()) do
			local barLink = bar.rollID and bar.button and bar.button.link
			if barLink and not Taken(bar) and (exact and barLink == link or not exact and ItemID(barLink) and ItemID(barLink) == ItemID(link)) then
				found, count = bar, count + 1
			end
		end
		if count == 1 then return found end
		if count > 1 then return nil, true end
	end
end

-- ¿Otro objeto del mismo ítem que también espera barra?
local function HasRival(drop)
	for _, other in pairs(drops) do
		if other ~= drop and not other.bar and not other.lost and other.link and Key(other.link) == Key(drop.link) then
			return true
		end
	end
end

-- Suma al bloqueo del ítem cada objeto pendiente y cada barra a la vista de ese ítem.
local function Involve(item)
	local b = blocked[item] or { drops = {}, rolls = {} }
	blocked[item] = b
	for id, drop in pairs(drops) do
		if drop.link and Key(drop.link) == item then b.drops[id] = true end
	end
	for _, bar in ipairs(Bars()) do
		local link = bar.rollID and bar.button and bar.button.link
		if link and Key(link) == item then b.rolls[bar.rollID] = true end
	end
end

-- El bloqueo se levanta cuando ya no queda ningún objeto involucrado ni ninguna barra involucrada a la vista.
local function Blocked(item)
	local b = blocked[item]
	if not b then return false end
	for id in pairs(b.drops) do
		if drops[id] then return true end
	end
	for _, bar in ipairs(Bars()) do
		if bar.rollID and b.rolls[bar.rollID] then return true end
	end
	blocked[item] = nil
	return false
end

local function Paint(bar, info)
	wipe(bar.rolls)
	for _, roll in ipairs(info.rollInfos or {}) do
		local rollType = ROLL_TYPE[roll.state]
		if rollType then
			bar.rolls[rollType] = bar.rolls[rollType] or {}
			tinsert(bar.rolls[rollType], { roll.playerName, roll.playerClass }) -- lo lee el tooltip (LootRoll.lua:55-66)
		end
	end
	for rollType, key in pairs(BUTTONS) do
		local button = bar[key]
		if button and button.text then
			local list = bar.rolls[rollType]
			button.text:SetText(list and #list > 0 and #list or '')
		end
	end
end

-- Saca los objetos terminados cuya barra ya pasó a otra tirada o se cerró.
local function Sweep()
	for id, drop in pairs(drops) do
		if drop.done and drop.bar.rollID ~= drop.rollID then drops[id] = nil end
	end
end

function K:LootHistoryDrop(encounterID, lootListKey)
	if Secret(encounterID) or Secret(lootListKey) or not E.private.general.lootRoll then return end
	Sweep()
	local id = encounterID..':'..lootListKey
	local info = C_LootHistory.GetSortedInfoForDrop(encounterID, lootListKey)
	local drop = drops[id]
	if not info then drops[id] = nil return end
	if not drop then
		if Finished(info) then return end
		drop = { encounterID = encounterID, lootListKey = lootListKey }
		drops[id] = drop
	end
	drop.link = info.itemHyperlink
	if drop.bar and drop.bar.rollID ~= drop.rollID then
		-- La barra pasó a otra tirada (se canceló o se reutilizó): este objeto ya no se ata a ninguna otra.
		drop.bar, drop.rollID, drop.lost = nil, nil, true
	end
	if not drop.bar and not drop.lost and not Finished(info) then
		local item = Key(drop.link)
		if Blocked(item) then
			Involve(item)
		else
			local bar, many = FindBar(drop.link)
			if many or (bar and HasRival(drop)) then
				Involve(item)
			elseif bar then
				drop.bar, drop.rollID = bar, bar.rollID
			end
		end
	end
	if drop.bar then Paint(drop.bar, info) end
	if Finished(info) then
		-- Con barra, la reserva sigue hasta que esa barra cambie de tirada (Sweep): otro objeto no puede tomarla.
		if drop.bar then drop.done = true else drops[id] = nil end
	end
end

-- Votos que llegaron antes que la barra: al mostrarse una tirada se reintenta cada objeto sin barra.
function K:LootRollShown()
	Sweep()
	-- Una barra que aparece con su ítem bloqueado también queda involucrada, y dos barras libres del mismo ítem lo
	-- bloquean aunque todavía no haya llegado ningún objeto del historial.
	local free = {}
	for _, bar in ipairs(Bars()) do
		local link = bar.rollID and bar.button and bar.button.link
		if link then
			local item = Key(link)
			if blocked[item] and Blocked(item) then Involve(item) end
			if not Taken(bar) then free[item] = (free[item] or 0) + 1 end
		end
	end
	for item, count in pairs(free) do
		if count > 1 then Involve(item) end
	end
	for _, drop in pairs(drops) do
		if not drop.bar and not drop.lost then
			self:LootHistoryDrop(drop.encounterID, drop.lootListKey)
		end
	end
end

function K:SetupLootRollCounts()
	local misc = E:GetModule('Misc', true)
	if not (misc and misc.START_LOOT_ROLL and C_LootHistory and C_LootHistory.GetSortedInfoForDrop) then return end
	hooksecurefunc(misc, 'START_LOOT_ROLL', function() pcall(K.LootRollShown, K) end)
	local f = CreateFrame('Frame')
	if not pcall(f.RegisterEvent, f, 'LOOT_HISTORY_UPDATE_DROP') then return end
	pcall(f.RegisterEvent, f, 'LOOT_HISTORY_CLEAR_HISTORY')
	f:SetScript('OnEvent', function(_, event, encounterID, lootListKey)
		if event == 'LOOT_HISTORY_CLEAR_HISTORY' then wipe(drops) wipe(blocked) return end
		local ok, err = pcall(K.LootHistoryDrop, K, encounterID, lootListKey)
		if not ok and E.db.KnuUIDebug then E:Print(tostring(err)) end
	end)
end
