local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- Skin de TomTom: flecha de navegación y bloque de coordenadas.
-- Marcos reales (rutas desde Interface/AddOns/TomTom/):
--   modules/crazy_arrow/crazy_arrow.lua:31,40-42  TomTomCrazyArrow con .title, .status y .tta
--   modules/coord_block.lua:97-120                 TomTomBlock (con BackdropTemplate) y .Text

local function Font(text, size, color)
	if not text or not text.FontTemplate then return end
	pcall(text.FontTemplate, text, 'Expressway', size, 'OUTLINE')
	if color then text:SetTextColor(color.r, color.g, color.b) end
end

-- Recuadro del tema detrás de los textos de la flecha (título, distancia, tiempo), que TomTom
-- apila debajo de la flecha (crazy_arrow.lua:43-45). Se ajusta al texto más ancho cada vez que
-- TomTom cambia el título o la distancia.
local function FitPanel(arrow)
	local panel = arrow.KnuPanel
	if not panel then return end
	local width, height = 0, 6
	for _, text in ipairs({ arrow.title, arrow.status, arrow.tta }) do
		if text and text:IsShown() and (text:GetText() or '') ~= '' then
			width = math.max(width, text:GetStringWidth() or 0)
			height = height + (text:GetStringHeight() or 0)
		end
	end
	panel:SetShown(width > 0)
	panel:SetSize(math.max(width + 16, 60), height + 4)
end

local function Panel(arrow, t)
	if not arrow.title then return end
	if not arrow.KnuPanel then
		local panel = CreateFrame('Frame', nil, arrow)
		panel:SetPoint('TOP', arrow.title, 'TOP', 0, 4)
		panel:SetFrameLevel(math.max(arrow:GetFrameLevel() - 1, 0))
		panel:EnableMouse(false)
		panel:SetTemplate('Transparent')
		arrow.KnuPanel = panel
		for _, text in ipairs({ arrow.title, arrow.status, arrow.tta }) do
			if text then hooksecurefunc(text, 'SetText', function() FitPanel(arrow) end) end
		end
	end
	arrow.KnuPanel:SetBackdropColor(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, 0.85)
	arrow.KnuPanel:SetBackdropBorderColor(t.accentDim.r, t.accentDim.g, t.accentDim.b)
	FitPanel(arrow)
end

-- Colores de la flecha con la paleta del tema, una vez por perfil: después manda lo que el usuario
-- elija en TomTom. TomTom los lee de profile.arrow (core/settings.lua:61-64; theme_classic.lua:102-113).
local function ArrowColors(t)
	local tomtom = _G.TomTom
	local profile = tomtom and ((tomtom.db and tomtom.db.profile) or tomtom.profile)
	local arrowDB = profile and profile.arrow
	if type(arrowDB) ~= 'table' then return end
	-- La 3.4 pasaba la flecha al tema "classic" (más fea y encimada sobre el recuadro): quien
	-- quedó así vuelve una vez a "modern" (themes.lua:30-52, SetActiveTheme).
	if E.db.KnuUITomTomClassic then
		E.db.KnuUITomTomClassic = nil
		if arrowDB.theme == 'classic' then
			arrowDB.theme = 'modern'
			local handler = tomtom.CrazyArrowThemeHandler
			if handler and handler.SetActiveTheme and _G.TomTomCrazyArrow then
				pcall(handler.SetActiveTheme, handler, _G.TomTomCrazyArrow, 'modern')
			end
		end
	end
	if E.db.KnuUITomTomColors then return end
	E.db.KnuUITomTomColors = true
	arrowDB.goodcolor = { t.accentHi.r, t.accentHi.g, t.accentHi.b } -- bien encaminado
	arrowDB.exactcolor = { t.accentHi.r, t.accentHi.g, t.accentHi.b }
	arrowDB.middlecolor = { t.accent.r, t.accent.g, t.accent.b }
	arrowDB.badcolor = { t.castNoInterrupt.r, t.castNoInterrupt.g, t.castNoInterrupt.b } -- al revés
end

-- Flecha moderna teñida: el tema "modern" (theme_modern.lua:12) dibuja una imagen ya coloreada y no
-- usa los colores de TomTom; sólo el "classic" los aplica (theme_classic.lua:99-113). Después de
-- cada cuadro del moderno se desatura la imagen y se tiñe con los mismos colores y la misma
-- cuenta que el clásico: bueno/medio/malo según el ángulo, "exacto" al llegar.
local function Lerp(a, b, f) return a + (b - a) * f end
local function Gradient(perc, bad, mid, good)
	if perc >= 1 then return unpack(good) elseif perc <= 0 then return unpack(bad) end
	local f = perc * 2
	local c1, c2 = bad, mid
	if f >= 1 then f, c1, c2 = f - 1, mid, good end
	return Lerp(c1[1], c2[1], f), Lerp(c1[2], c2[2], f), Lerp(c1[3], c2[3], f)
end

local function TintModern()
	local tomtom = _G.TomTom
	local handler = tomtom and tomtom.CrazyArrowThemeHandler
	local modern = handler and handler.themes and handler.themes.modern and handler.themes.modern.tbl
	if not modern or K.tomtomTinted then return end
	K.tomtomTinted = true
	local function Arrow()
		local arrowDB = tomtom.db and tomtom.db.profile and tomtom.db.profile.arrow
		local tex = modern.arrowTexture
		if arrowDB and tex and tex.SetDesaturated then tex:SetDesaturated(true) return tex, arrowDB end
	end
	hooksecurefunc(modern, 'NavigationArrow_OnUpdate', function(_, _, angle)
		local tex, db = Arrow()
		if not tex or type(angle) ~= 'number' then return end
		local perc = math.abs((math.pi - math.abs(angle)) / math.pi)
		local r, g, b
		if perc > 0.98 then r, g, b = unpack(db.exactcolor) else r, g, b = Gradient(perc, db.badcolor, db.middlecolor, db.goodcolor) end
		tex:SetVertexColor(r, g, b)
	end)
	hooksecurefunc(modern, 'ArrivalArrow_OnUpdate', function()
		local tex, db = Arrow()
		if tex then tex:SetVertexColor(unpack(db.exactcolor)) end
	end)
end

local function Style()
	if not K:IsLoaded('TomTom') then return end
	local t = K:GetTheme()
	local arrow = _G.TomTomCrazyArrow
	if arrow then
		Font(arrow.title, 13, t.text)
		Font(arrow.status, 12, t.accent)
		Font(arrow.tta, 11, t.muted)
		if not InCombatLockdown() then Panel(arrow, t) end
		ArrowColors(t)
		pcall(TintModern)
	end
	local block = _G.TomTomBlock
	if block then
		if block.SetTemplate then pcall(block.SetTemplate, block, 'Transparent') end
		if block.SetBackdropBorderColor then block:SetBackdropBorderColor(t.accentDim.r, t.accentDim.g, t.accentDim.b) end
		Font(block.Text, 12, t.accent)
	end
end

function K:SkinTomTom()
	pcall(Style)
end

local hooked

-- Flecha de TomTom al lado de la guía de WoW-Pro (x 8-258), una vez por perfil. Arriba al centro
-- chocaba con las barras de duración, que en Forever ubica el Modo edición de Blizzard y no se
-- pueden mover desde KnuUI. TomTom guarda la posición relativa a UIParent
-- (modules/crazy_arrow/crazy_arrow.lua:211-229); se convierte desde píxeles de ElvUIParent.
local function PlaceArrow()
	local tomtom, arrow = _G.TomTom, _G.TomTomCrazyArrow
	if E.db.KnuUITomTomPlaced or not tomtom or not arrow or not tomtom.profile or not tomtom.profile.arrow then return end
	if InCombatLockdown() then return end
	E.db.KnuUITomTomPlaced = true
	local scale = E.UIParent:GetEffectiveScale() / UIParent:GetEffectiveScale()
	local x, y = math.floor(300 * scale + 0.5), math.floor(-16 * scale + 0.5)
	tomtom.profile.arrow.position = { 'TOPLEFT', nil, 'TOPLEFT', x, y }
	arrow:ClearAllPoints()
	arrow:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', x, y)
end

function K:SetupTomTomSkin()
	C_Timer.After(2, function() pcall(PlaceArrow) end)
	-- TomTom vuelve a poner sus colores y su letra cada vez que corre ShowHideCoordBlock
	-- (modules/coord_block.lua:147-150,167); la skin se aplica justo después.
	local tomtom = _G.TomTom
	if not hooked and tomtom and type(tomtom.ShowHideCoordBlock) == 'function' then
		hooked = true
		hooksecurefunc(tomtom, 'ShowHideCoordBlock', function() K:SkinTomTom() end)
	end
	local f = CreateFrame('Frame')
	f:RegisterEvent('PLAYER_ENTERING_WORLD')
	f:SetScript('OnEvent', function()
		-- TomTom crea el bloque de coordenadas al habilitarlo; se reintenta un par de veces.
		for _, delay in ipairs({ 1, 4 }) do C_Timer.After(delay, function() K:SkinTomTom() end) end
	end)
end
