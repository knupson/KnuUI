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
function K:SetupTomTomSkin()
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
