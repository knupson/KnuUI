local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- Manners (aviso para devolver beneficios). Su sistema de apariencias es interno (ns.Looks.Register, Looks/Looks.lua:12,
-- sin tabla global), así que no se pinta encima de su dibujo: se usan sus propios ajustes del aviso
-- (db.profile.prompt, Core.lua:717-886) a través de AceAddon y se le pide que se redibuje con su método público
-- RefreshConfig (Core.lua:6604-6633, que llama a ns.Prompt:ApplyStyle). Sólo se cambia lo que sigue con el valor por
-- defecto de Manners (lo que el jugador eligió queda), una vez por perfil de Manners.
-- Lugar: el de Manners (BOTTOM, 0, 300, Core.lua:725-728) cae sobre las auras del objetivo de KnuUI (render de la
-- disposición, 2026-11-22). Va a la derecha de la columna del objetivo, entre el objetivo del objetivo y el monitor
-- de botín: x 1180-1400, y 340-384 desde abajo, libre en el render; sus botones laterales crecen hacia la derecha
-- (Prompt/BreakFree.lua:373-374) y no tocan las tiradas del centro.
local POSITION = { point = 'BOTTOM', relPoint = 'BOTTOM', x = 330, y = 340 }

local function Same(a, b)
	if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
	for i = 1, 4 do if a[i] ~= b[i] then return false end end
	return true
end

local function Color(c, a) return { c.r, c.g, c.b, a or c.a or 1 } end

-- Devuelve los ajustes que KnuUI quiere para el aviso, con el tema actual.
function K:MannersWanted()
	local t = self:GetTheme()
	local LSM = E.Libs and E.Libs.LSM
	local wanted = {
		style = 'minimal', -- «Minimal: un borde fino, un panel suave» (Looks/Looks.lua:281)
		bgColor = Color(t.backdropFade or t.backdrop, 0.9),
		accentColor = Color(t.accent, 1),
	}
	if LSM and LSM.Fetch and LSM:Fetch('font', 'Expressway', true) then wanted.font = 'Expressway' end
	return wanted
end

function K:ApplyManners()
	local AceAddon = LibStub and LibStub('AceAddon-3.0', true)
	local manners = AceAddon and AceAddon:GetAddon('Manners', true)
	local db = manners and manners.db
	local p = db and db.profile and db.profile.prompt
	local defaults = db and db.defaults and db.defaults.profile and db.defaults.profile.prompt
	if type(p) ~= 'table' or type(defaults) ~= 'table' or type(db.GetCurrentProfile) ~= 'function' then return false end
	E.global.KnuUIManners = E.global.KnuUIManners or {}
	local profile = db:GetCurrentProfile()
	if E.global.KnuUIManners[profile] then return false end
	for key, value in pairs(self:MannersWanted()) do
		if Same(p[key], defaults[key]) then p[key] = value end
	end
	if p.point == defaults.point and p.relPoint == defaults.relPoint and p.x == defaults.x and p.y == defaults.y then
		for key, value in pairs(POSITION) do p[key] = value end
	end
	E.global.KnuUIManners[profile] = true
	if type(manners.RefreshConfig) == 'function' then pcall(manners.RefreshConfig, manners) end
	return true
end

local listener = {} -- clave propia para los callbacks de AceDB (CallbackHandler)

K:RegisterSkin('Manners', function()
	local function Apply() K:AfterCombat(function() K:ApplyManners() end, 'KnuUI:Manners') end
	Apply()
	-- Un perfil de Manners elegido, copiado o reiniciado en la sesión también se integra (revisión de Codex 2026-11-22).
	local AceAddon = LibStub and LibStub('AceAddon-3.0', true)
	local manners = AceAddon and AceAddon:GetAddon('Manners', true)
	local db = manners and manners.db
	if db and type(db.RegisterCallback) == 'function' then
		db.RegisterCallback(listener, 'OnProfileChanged', Apply)
		-- Reiniciado vuelve a los valores de Manners: se integra de nuevo.
		db.RegisterCallback(listener, 'OnProfileReset', function()
			if E.global.KnuUIManners and type(db.GetCurrentProfile) == 'function' then
				E.global.KnuUIManners[db:GetCurrentProfile()] = nil
			end
			Apply()
		end)
	end
end)
