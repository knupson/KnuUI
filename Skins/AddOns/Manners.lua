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
-- Versión de la integración por perfil (E.global.KnuUIManners[perfil]). 2: sin el arte pintado de Mínima y con panel
-- propio de KnuUI (el user vio los «bordes rotos» del panel ahumado pintado, Prompt/Panel.lua:1436-1452).
local MANNERS_V = 3
-- 3: sin la línea blanca con puntas de Mínima (Looks/MinimalDress.lua:9-11, `minimalLine = false` la saca, :26,410) ni
-- la línea de acento de KnuUI: con las dos líneas de luz de Manners (Prompt/Panel.lua:364-372,805-826) y el borde
-- quedaban líneas encimadas (visto por el user 2026-11-22).

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
		-- «Earlier art»: Mínima sin su pintura (panel ahumado de bordes irregulares), sólo letras y una línea fina
		-- (Core.lua:847; Prompt/Panel.lua:509-520). El panel lo pone KnuUI (SkinMannersPrompt).
		classicArt = true,
		minimalLine = false,
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
	local done = E.global.KnuUIManners[profile]
	if done == true then done = 1 end -- 3.6.9 guardaba true
	if (tonumber(done) or 0) >= MANNERS_V then self:SkinMannersPrompt(p) return false end
	for key, value in pairs(self:MannersWanted()) do
		if Same(p[key], defaults[key]) then p[key] = value end
	end
	if p.point == defaults.point and p.relPoint == defaults.relPoint and p.x == defaults.x and p.y == defaults.y then
		for key, value in pairs(POSITION) do p[key] = value end
	end
	E.global.KnuUIManners[profile] = MANNERS_V
	if type(manners.RefreshConfig) == 'function' then pcall(manners.RefreshConfig, manners) end
	self:SkinMannersPrompt(p)
	return true
end

-- Panel de KnuUI detrás del aviso: fondo del tema y borde de 1 px. Se dibuja con
-- texturas dentro del propio `art` de Manners (Prompt/Panel.lua:165), en la capa más baja (BACKGROUND -8): así sigue
-- solo sus fundidos y la atenuación en combate (Prompt/Effects.lua:638-654, 685-696; revisión de Codex 2026-11-22) y
-- queda debajo de las letras y el ícono, que son regiones de `art` en capas más altas. `art` se reconoce por los
-- grupos de animación que Manners le cuelga (outro, comeback: Effects.lua:645,654). Sólo con la apariencia Mínima,
-- que no tiene panel propio (Prompt/Panel.lua:557-561): Manners llama a SetSize del botón en cada redibujo
-- (Panel.lua:522, también al elegir otra apariencia en sus opciones), y ahí se vuelve a mirar.
local function MannersPrompt()
	local AceAddon = LibStub and LibStub('AceAddon-3.0', true)
	local manners = AceAddon and AceAddon:GetAddon('Manners', true)
	local db = manners and manners.db
	return db and db.profile and db.profile.prompt
end

local function FindArt(button)
	for _, child in ipairs({ button:GetChildren() }) do
		if child.outro or child.comeback then return child end
	end
end

function K:SkinMannersPrompt(p)
	local button = _G.MannersPrompt
	if not (button and button.GetChildren) then return nil end
	local back = button.KnuBack
	if not back then
		local art = FindArt(button)
		if not art then return nil end
		back = { art = art }
		local function Tex(sub) return art:CreateTexture(nil, 'BACKGROUND', nil, sub) end
		back.fill = Tex(-8)
		back.fill:SetAllPoints(art)
		local px = E.mult or 1
		back.edges = {}
		for i, pts in ipairs({ { 'TOPLEFT', 'TOPRIGHT', true }, { 'BOTTOMLEFT', 'BOTTOMRIGHT', true },
			{ 'TOPLEFT', 'BOTTOMLEFT', false }, { 'TOPRIGHT', 'BOTTOMRIGHT', false } }) do
			local e = Tex(-7)
			e:SetPoint(pts[1], art, pts[1])
			e:SetPoint(pts[2], art, pts[2])
			if pts[3] then e:SetHeight(px) else e:SetWidth(px) end
			back.edges[i] = e
		end
		button.KnuBack = back
		if not button.KnuBackHooked then
			button.KnuBackHooked = true
			hooksecurefunc(button, 'SetSize', function() K:SkinMannersPrompt(MannersPrompt()) end)
		end
	end
	local t = self:GetTheme()
	local bg = t.backdropFade or t.backdrop
	back.fill:SetColorTexture(bg.r, bg.g, bg.b, 0.9)
	for _, e in ipairs(back.edges) do e:SetColorTexture(t.border.r, t.border.g, t.border.b, 1) end
	local shown = not p or p.style == 'minimal'
	back.shown = shown
	back.fill:SetShown(shown)
	for _, e in ipairs(back.edges) do e:SetShown(shown) end
	return back
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
