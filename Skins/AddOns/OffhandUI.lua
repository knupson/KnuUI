local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')
local S = E:GetModule('Skins')

-- Sólo estas ventanas: nunca OffhandCanvasFrame ni las opciones guardadas de Offhand.
-- Offhand/UI/Options.lua:300; UI/Wizard.lua:191; UI/Onboarding.lua:366; UI/WhatsNew.lua:101.
local names = { 'OffhandFloatingConfigFrame', 'OffhandSetupWizardFrame', 'OffhandFirstLaunchFrame', 'OffhandWhatsNewFrame' }
local handled = setmetatable({}, { __mode = 'k' })

local function Theme(frame)
	local t = K:GetTheme()
	local bd = frame.backdrop or frame
	if bd.SetBackdropColor then
		bd:SetBackdropColor(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, t.backdropFade.a)
		bd:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
	end
end

local function IsClose(button)
	local tex = button.GetNormalTexture and button:GetNormalTexture()
	local path = tex and tex.GetTexture and tex:GetTexture()
	return (type(path) == 'string' and path:find('UI%-Panel%-MinimizeButton') ~= nil)
		or (tex and tex.GetAtlas and tex:GetAtlas() == 'RedButton-Exit')
end

-- Fotos previas a los helpers, como OpenMap: sólo se retiran fondos originales, nunca las
-- texturas que agregan ElvUI/KnuFrame. Se conservan logos, marcas y muestras de color.
-- Cabeceras: Offhand/UI/Themes.lua:383-400; tarjetas: UI/Options.lua:521, UI/Wizard.lua:175,
-- UI/Onboarding.lua:405. Controles: UI/Controls.lua:136,366,408,418,441,708,954,1027;
-- botones y cierre: UI/Options.lua:381-394; UI/Wizard.lua:225; UI/Onboarding.lua:387,440-478;
-- UI/WhatsNew.lua:111,130,145. Barras: UI/Options.lua:467,2280.
local function Dress(frame, depth)
	depth = depth or 0
	if depth > 10 or (frame.IsProtected and frame:IsProtected()) then return end
	local children = { frame:GetChildren() }
	if not handled[frame] then
		local regions = { frame:GetRegions() }
		local kind, name = frame:GetObjectType(), frame:GetName() or ''
		if kind == 'CheckButton' then S:HandleCheckBox(frame)
		elseif kind == 'EditBox' then S:HandleEditBox(frame)
		elseif kind == 'Button' then
			-- El texto clickeable de cada casilla es un Button hijo de la casilla (Controls.lua:718,970):
			-- skinearlo como botón le ponía un recuadro alrededor del texto (visto en el juego 2026-11-13).
			local parent = frame.GetParent and frame:GetParent()
			local isLabel = parent and parent.IsObjectType and parent:IsObjectType('CheckButton')
			if isLabel then -- se deja como está
			elseif IsClose(frame) then S:HandleCloseButton(frame) else S:HandleButton(frame) end
		elseif name:match('ScrollBar$') then S:HandleScrollBar(frame)
		elseif kind == 'Slider' then
			-- HandleSliderFrame cambia alto/anclajes; se conserva la geometría de Controls.lua:366.
			frame:SetTemplate('Transparent')
			local thumb = frame.GetThumbTexture and frame:GetThumbTexture()
			local t = K:GetTheme()
			if thumb then thumb:SetVertexColor(t.accent.r, t.accent.g, t.accent.b) end
		elseif depth > 0 and frame.GetBackdrop and frame:GetBackdrop() then
			for _, r in ipairs(regions) do
				if r:IsObjectType('Texture') and (r:GetDrawLayer() == 'BACKGROUND' or r:GetDrawLayer() == 'BORDER') then r:SetAlpha(0) end
			end
			for _, c in ipairs(children) do
				if c.TopLeftCorner or c.layoutType then c:Hide() end
			end
			frame:SetTemplate('Transparent')
		end
		handled[frame] = true
	end
	Theme(frame)
	for _, r in ipairs({ frame:GetRegions() }) do
		if r:IsObjectType('FontString') then K:SkinFont(r) end
	end
	if frame:IsObjectType('EditBox') then K:SkinFont(frame) end
	-- La barra ya tiene flechas de ElvUI; no volver a vestirlas como botones comunes.
	if (frame:GetName() or ''):match('ScrollBar$') then return end
	for _, child in ipairs(children) do
		if child ~= frame.backdrop and child ~= frame.KnuShadow then Dress(child, depth + 1) end
	end
end

local function Style(frame)
	Dress(frame)
	if K.KnuFrame then K:KnuFrame(frame) end
end

K:RegisterSkin('Offhand', function()
	for _, name in ipairs(names) do
		K:WatchAddonFrame('Offhand', name, function(frame) pcall(Style, frame) end, true)
	end
	-- UI/Controls.lua:29,164-179 repinta al pasar el mouse y al enfocar. Sólo controles ya vestidos.
	local controls = _G.Offhand and _G.Offhand.UIControls
	if controls and type(controls.StyleSurface) == 'function' then
		hooksecurefunc(controls, 'StyleSurface', function(frame)
			if handled[frame] then K:RunAddonSkin('Offhand', frame, function() Theme(frame) end) end
		end)
	end
end)
