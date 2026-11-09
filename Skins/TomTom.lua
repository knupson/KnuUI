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
	if E.db.KnuUITomTomColors or type(arrowDB) ~= 'table' then return end
	E.db.KnuUITomTomColors = true
	arrowDB.goodcolor = { t.accentHi.r, t.accentHi.g, t.accentHi.b } -- bien encaminado
	arrowDB.exactcolor = { t.accentHi.r, t.accentHi.g, t.accentHi.b }
	arrowDB.middlecolor = { t.accent.r, t.accent.g, t.accent.b }
	arrowDB.badcolor = { t.castNoInterrupt.r, t.castNoInterrupt.g, t.castNoInterrupt.b } -- al revés
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
