local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')
local AFK = E:GetModule('AFK')

-- Pantalla de ausente de KnuUI: viste el marco de ElvUI (Modules/Misc/AFK.lua:52-60,336-397)
-- con el logo propio, franjas de peligro y los colores del tema activo.
local MEDIA = [[Interface\AddOns\KnuUI\media\]]
local styled

local function Style()
	local afk = AFK.AFKMode
	local bottom = afk and afk.bottom
	if not bottom or not bottom.LogoTop then return end
	local t = K:GetTheme()

	if not styled then
		styled = true
		-- Logo propio en lugar de los dos de ElvUI (AFK.lua:342-352).
		bottom.LogoBottom:Hide()
		bottom.LogoTop:SetTexture(MEDIA..'logo')
		bottom.LogoTop:Size(384, 192)
		-- Franjas de peligro en el borde superior del panel, repetidas en X.
		local stripes = bottom:CreateTexture(nil, 'OVERLAY')
		stripes:SetTexture(MEDIA..'franjas', 'REPEAT', 'CLAMP')
		stripes:SetHorizTile(true)
		stripes:SetPoint('BOTTOMLEFT', bottom, 'TOPLEFT', 0, 0)
		stripes:SetPoint('BOTTOMRIGHT', bottom, 'TOPRIGHT', 0, 0)
		stripes:SetHeight(8)
		bottom.KnuStripes = stripes
		-- Línea con el nombre del addon a la derecha.
		local tag = bottom:CreateFontString(nil, 'OVERLAY')
		tag:FontTemplate(nil, 14)
		tag:SetPoint('BOTTOMRIGHT', bottom, 'BOTTOMRIGHT', -20, 12)
		tag:SetText('KNUUI · KNUNET.COM')
		bottom.KnuTag = tag
	end

	-- Colores en cada activación: SetAFK pinta el logo con valuecolor (AFK.lua:123).
	bottom.LogoTop:SetVertexColor(1, 1, 1)
	if bottom.SetBackdropColor then
		bottom:SetBackdropColor(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, 0.92)
		bottom:SetBackdropBorderColor(t.accentDim.r, t.accentDim.g, t.accentDim.b)
	end
	bottom.KnuStripes:SetShown(E.db.KnuUITheme ~= 'neon')
	bottom.name:SetTextColor(t.accentHi.r, t.accentHi.g, t.accentHi.b)
	bottom.guild:SetTextColor(t.text.r, t.text.g, t.text.b)
	bottom.time:SetTextColor(t.accent.r, t.accent.g, t.accent.b)
	bottom.KnuTag:SetTextColor(t.muted.r, t.muted.g, t.muted.b)
end

function K:SetupAFK()
	if type(AFK.SetAFK) ~= 'function' then return end
	hooksecurefunc(AFK, 'SetAFK', function(_, status)
		if status then pcall(Style) end
	end)
end
