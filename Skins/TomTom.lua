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

local function Style()
	if not K:IsLoaded('TomTom') then return end
	local t = K:GetTheme()
	local arrow = _G.TomTomCrazyArrow
	if arrow then
		Font(arrow.title, 13, t.text)
		Font(arrow.status, 12, t.accent)
		Font(arrow.tta, 11, t.muted)
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
