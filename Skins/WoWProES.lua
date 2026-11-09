local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- Traducción de las notas de WoW-Pro en el momento de cargar cada guía.
-- WoW-Pro arma la guía partiendo el texto en líneas y llamando a WoWPro.ParseSteps(steps)
-- (WoWPro_Parser.lua:1305-1314; definición en :1070). Se envuelve esa función para
-- reemplazar el texto que sigue a |N| por su traducción (addon privado KnuUI_WoWProES).
-- Así sobrevive a las actualizaciones de WoW-Pro: no se toca ningún archivo de guía.
-- Las notas sin traducción se anotan en E.global.KnuUIWoWProPendientes para traducirlas después.

local function Translate(steps)
	-- La tabla la aporta el addon privado KnuUI_WoWProES (no viene en el paquete público).
	local tabla = _G.KnuUI_WoWProES
	if type(steps) ~= 'table' or type(tabla) ~= 'table' then return end
	if E.db and E.db.KnuUITranslateWoWPro == false then return end
	local pendientes = {}
	if E.global then
		E.global.KnuUIWoWProPendientes = E.global.KnuUIWoWProPendientes or {}
		pendientes = E.global.KnuUIWoWProPendientes
	end
	local getTitle = C_QuestLog and (C_QuestLog.GetTitleForQuestID or C_QuestLog.GetQuestInfo) -- como ElvUI QuestIcons.lua:21
	for i, line in ipairs(steps) do
		-- Pasos A/C/T con QID: el título se reemplaza por el del cliente (esMX) si ya está en caché.
		if type(line) == 'string' and getTitle then
			local action, title, rest = line:match('^([ACT]) ([^|]+)(|.*)$')
			local qid = rest and tonumber(rest:match('|QID|(%d+)'))
			if qid then
				local ok, es = pcall(getTitle, qid)
				if ok and type(es) == 'string' and es ~= '' and not es:find('|', 1, true) then
					line = action..' '..es..rest
					steps[i] = line
				elseif C_QuestLog.RequestLoadQuestByID then
					pcall(C_QuestLog.RequestLoadQuestByID, qid) -- queda en caché para la próxima carga
				end
			end
		end
		if type(line) == 'string' and line:find('|N|', 1, true) then
			steps[i] = line:gsub('|N|([^|]*)', function(note)
				local es = tabla[note]
				if es then return '|N|'..es end
				if note:find('%a') and not pendientes[note] then pendientes[note] = true end
				return nil -- deja la nota original
			end)
		end
	end
end

-- Se envuelve apenas carga WoW-Pro (ADDON_LOADED llega antes de que cargue cualquier guía).
-- KnuUI carga antes que WoWPro por orden alfabético, así que se escucha el evento desde acá.
local function Wrap()
	local w = _G.WoWPro
	if not w or type(w.ParseSteps) ~= 'function' or w.KnuUIParseWrapped then return false end
	local original = w.ParseSteps
	w.ParseSteps = function(steps, ...)
		pcall(Translate, steps)
		return original(steps, ...)
	end
	w.KnuUIParseWrapped = true
	return true
end

local locale = GetLocale()
if locale == 'esMX' or locale == 'esES' then
	if not Wrap() then
		local f = CreateFrame('Frame')
		f:RegisterEvent('ADDON_LOADED')
		f:SetScript('OnEvent', function(self, _, name)
			if name == 'WoWPro' and Wrap() then self:UnregisterAllEvents() end
		end)
	end
end

function K:SetupWoWProES() end -- el trabajo se hace al cargar el archivo (ver arriba)
