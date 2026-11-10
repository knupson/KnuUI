local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')
local S = E:GetModule('Skins')

K:RegisterSkin('RareScanner', function()
	-- Aviso de raro: RareScanner.lua:56 lo crea como SecureActionButtonTemplate (nombre en
	-- Core/Libs/RSConstants.lua:395). Sólo el marco exterior: los botones de filtro usan íconos propios
	-- (RareScanner.lua:178-204) que HandleButton borraría. El motor lo aplica fuera de combate.
	K:WatchAddonFrame('RareScanner', 'RARESCANNER_BUTTON', function(button)
		local t = K:GetTheme()
		if button.CloseButton then S:HandleCloseButton(button.CloseButton) end
		K:SkinFont(button.Title, true)
		K:SkinFont(button.Description_text)
		-- RareScanner pone el borde blanco/negro al pasar el mouse (RareScanner.lua:116-121):
		-- después de su script se vuelve a los colores del tema.
		if not button.KnuHover then
			button.KnuHover = true
			button:HookScript('OnEnter', function(self)
				local c = K:GetTheme().accent
				self:SetBackdropBorderColor(c.r, c.g, c.b)
			end)
			button:HookScript('OnLeave', function(self)
				local c = K:GetTheme().border
				self:SetBackdropBorderColor(c.r, c.g, c.b)
			end)
		end
		button:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
	end, true)

	-- Explorador (Core/Plugins/ExplorerPlugin/RSExplorerTemplate.xml:389): fondo y marco propios
	-- (:9-30, atlas shop-loading-background y bordes NineSlice en el hijo Border). Sólo el exterior.
	K:WatchAddonFrame('RareScanner', 'RSExplorerFrame', function(frame)
		if frame.Border then frame.Border:StripTextures() end
		if frame.CloseButton then S:HandleCloseButton(frame.CloseButton) end
	end, true)
end)
