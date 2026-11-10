-- Aceptar y entregar misiones automáticamente con WoW-Pro en un cliente que no está en inglés.
-- WoW-Pro decide comparando el título que da el cliente con el título del paso de la guía
-- (WoWPro_Events.lua: GOSSIP_SHOW_PUNTED, QUEST_GREETING_PUNTED, QUEST_DETAIL_PUNTED,
-- QUEST_PROGRESS_PUNTED, QUEST_COMPLETE, QUEST_ACCEPTED). Las guías traen los títulos en inglés
-- y el cliente esMX los da en castellano, así que nunca coinciden.
-- Antes de cada una de esas funciones se ponen en los pasos con el mismo QID los títulos que
-- muestra el diálogo. No se toca ningún archivo de WoW-Pro, así que sobrevive a sus actualizaciones.
-- Las funciones son campos de la tabla WoWPro y se buscan en cada llamada
-- (WoWPro_Events.lua:56 guarda el manejador en WoWPro[event] y :187-228 lo llama), así que
-- envolverlas alcanza.
-- También se reintenta el GOSSIP_SHOW que WoW-Pro descarta: en Forever el primero puede llegar
-- sin misiones cargadas y el segundo, ya con datos, se suprimía (WoWPro_Events.lua:549-557).

local locale = GetLocale and GetLocale()
if locale == 'enUS' or locale == 'enGB' then return end

local function StepHasQID(w, stepQIDs, qid)
	if stepQIDs == nil or stepQIDs == '*' or type(w.QIDsInTable) ~= 'function' then return false end
	local ok, found = pcall(w.QIDsInTable, w, stepQIDs, { [qid] = true })
	return ok and found and true or false
end

-- Pone el título del cliente en los pasos A/C/T de esa misión.
local function Align(w, qid, title)
	qid = tonumber(qid)
	if not qid or qid <= 0 or type(title) ~= 'string' or title == '' then return end
	local steps, qids, actions = w.step, w.QID, w.action
	if type(steps) ~= 'table' or type(qids) ~= 'table' or type(actions) ~= 'table' then return end
	for i, stepQIDs in pairs(qids) do
		local action = actions[i]
		if (action == 'A' or action == 'C' or action == 'T') and steps[i] ~= title and StepHasQID(w, stepQIDs, qid) then
			steps[i] = title
		end
	end
end

local function AlignList(w, list)
	if type(list) ~= 'table' then return end
	for _, info in ipairs(list) do
		if type(info) == 'table' then Align(w, info.questID, info.title) end
	end
end

-- Todas las misiones del diálogo abierto: chisme (gossip), saludo (greeting) y detalle/progreso/recompensa.
local function AlignDialog(w, extraQID)
	if type(w.GossipInfo_GetActiveQuests) == 'function' then
		local ok, list = pcall(w.GossipInfo_GetActiveQuests)
		if ok then AlignList(w, list) end
	end
	if type(w.GossipInfo_GetAvailableQuests) == 'function' then
		local ok, list = pcall(w.GossipInfo_GetAvailableQuests)
		if ok then AlignList(w, list) end
	end
	if GetNumActiveQuests and GetActiveTitle and GetActiveQuestID then
		for i = 1, GetNumActiveQuests() or 0 do Align(w, GetActiveQuestID(i), GetActiveTitle(i)) end
	end
	if GetNumAvailableQuests and GetAvailableTitle and GetAvailableQuestInfo then
		for i = 1, GetNumAvailableQuests() or 0 do
			Align(w, select(5, GetAvailableQuestInfo(i)), GetAvailableTitle(i))
		end
	end
	local title = GetTitleText and GetTitleText()
	local qid = GetQuestID and GetQuestID()
	if qid and qid ~= 0 then Align(w, qid, title) end
	if extraQID and extraQID ~= qid then Align(w, extraQID, title) end
end

local FUNCTIONS = { 'GOSSIP_SHOW_PUNTED', 'QUEST_GREETING_PUNTED', 'QUEST_DETAIL_PUNTED', 'QUEST_PROGRESS_PUNTED', 'QUEST_COMPLETE' }
local lastGossipPunted = 0

local function Wrap()
	local w = _G.WoWPro
	if not w or w.KnuUIQuestsWrapped or type(w.GOSSIP_SHOW_PUNTED) ~= 'function' then return false end
	w.KnuUIQuestsWrapped = true

	for _, name in ipairs(FUNCTIONS) do
		local original = w[name]
		if type(original) == 'function' then
			w[name] = function(...)
				if name == 'GOSSIP_SHOW_PUNTED' then lastGossipPunted = GetTime() end
				pcall(AlignDialog, w)
				return original(...)
			end
		end
	end

	-- QUEST_ACCEPTED(event, questLogIndex, questID): en Forever questID llega en 0 y el dato viene en el primero.
	local accepted = w.QUEST_ACCEPTED
	if type(accepted) == 'function' then
		w.QUEST_ACCEPTED = function(event, qlidx, qid, ...)
			pcall(AlignDialog, w, (qid and qid ~= 0) and qid or qlidx)
			return accepted(event, qlidx, qid, ...)
		end
	end

	local gossip = w.GOSSIP_SHOW
	if type(gossip) == 'function' then
		w.GOSSIP_SHOW = function(event, ...)
			local active = w.QuestDialogActive
			local result = gossip(event, ...)
			if active == event and (w.QuestCount or 0) == 0 then
				local asked = GetTime()
				local delay = (WoWProDB and WoWProDB.global and WoWProDB.global.QuestEngineDelay) or 0.5
				C_Timer.After(delay, function()
					-- Si mientras tanto ya corrió otro intento, no se repite.
					if lastGossipPunted < asked and w.QuestDialogActive == event and (w.QuestCount or 0) == 0 then
						pcall(w.GOSSIP_SHOW_PUNTED, event..'PUNTED_RETRY')
					end
				end)
			end
			return result
		end
	end
	return true
end

if not Wrap() then
	local f = CreateFrame('Frame')
	f:RegisterEvent('ADDON_LOADED')
	f:SetScript('OnEvent', function(self, _, name)
		if name == 'WoWPro' and Wrap() then self:UnregisterAllEvents() end
	end)
end
