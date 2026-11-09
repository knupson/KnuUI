local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')
local S = E:GetModule('Skins')

-- Aviso de amigos de Battle.net con el tema de KnuUI. ElvUI le pone SetTemplate('Transparent')
-- (Skins/Battlenet.lua:14-22) y un mover propio, BNETMover (Modules/Blizzard/Blizzard.lua:168-173).
-- Acá sólo van colores, letra y botón de cerrar; los textos se recorren sin depender de sus nombres.

local function Style()
	local toast = _G.BNToastFrame
	if not toast or InCombatLockdown() then return end
	local t = K:GetTheme()
	if toast.SetTemplate then toast:SetTemplate('Transparent') end
	if toast.SetBackdropColor then
		toast:SetBackdropColor(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, 0.95)
		toast:SetBackdropBorderColor(t.accentDim.r, t.accentDim.g, t.accentDim.b)
	end
	local first = true
	for _, region in ipairs({ toast:GetRegions() }) do
		if region:IsObjectType('FontString') then
			local _, size = region:GetFont()
			if region.FontTemplate then region:FontTemplate('Expressway', size and math.floor(size + 0.5) or 12, 'OUTLINE') end
			-- La primera línea es el nombre del amigo: va en el color de acento del tema.
			if first then region:SetTextColor(t.accent.r, t.accent.g, t.accent.b); first = false end
		end
	end
	if toast.CloseButton and not toast.KnuClose then
		toast.KnuClose = true
		pcall(S.HandleCloseButton, S, toast.CloseButton)
	end
	if not toast.KnuLine then
		toast.KnuLine = toast:CreateTexture(nil, 'OVERLAY')
		toast.KnuLine:SetPoint('TOPLEFT', toast, 'TOPLEFT', 1, -1)
		toast.KnuLine:SetPoint('TOPRIGHT', toast, 'TOPRIGHT', -1, -1)
		toast.KnuLine:SetHeight(2)
	end
	toast.KnuLine:SetColorTexture(t.accent.r, t.accent.g, t.accent.b, 0.9)
end

function K:SkinBNToast() pcall(Style) end

function K:SetupBNToast()
	local toast = _G.BNToastFrame
	if not toast then return end
	-- La posición la aplica la distribución de elementos de Blizzard (Layout.lua, K.blizzardMovers).
	-- Blizzard rearma los textos en cada aviso: el estilo se reaplica al mostrarse.
	toast:HookScript('OnShow', function() K:SkinBNToast() end)
	K:SkinBNToast()
end
