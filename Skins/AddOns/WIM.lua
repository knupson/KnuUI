local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- WIM 3.19 (Interface 16001). Cada ventana de susurro pasa por WIM.ApplySkinToWindow
-- (WIM/Sources/Skinner.lua:327), que al final llama ApplyModernThemeToWindow (:1972): ahí WIM
-- muestra su marco moderno (obj.wimChrome, :765, con .well y .input) o los 9 bordes de la skin
-- (obj.widgets.Backdrop.tl..bg, :340-395). KnuUI deja ese arte transparente y dibuja detrás el
-- panel del tema. Además:
--   - El ícono de clase va dentro de un agujero redondo del marco moderno (:2064-2086); sin el marco
--     quedaba un círculo negro suelto: se oculta.
--   - WIM repone la opacidad de su marco en obj.UpdateProps (Sources/WindowHandler.lua:1547-1625,
--     opción windowAlpha; medido 0.8 en el juego) y la vuelve a llamar sola al mostrar la ventana:
--     la skin se reaplica después de cada UpdateProps, no sólo después de ApplySkinToWindow.
-- No se tocan los botones: WIM les repone las texturas en cada pasada.
local panels = setmetatable({}, { __mode = 'k' })
local hookedProps = setmetatable({}, { __mode = 'k' })

local function Panel(owner, anchor, level)
	local p = panels[owner]
	if not p then
		p = CreateFrame('Frame', nil, owner)
		p:SetTemplate('Transparent')
		panels[owner] = p
	end
	p:ClearAllPoints()
	p:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -2, 2)
	p:SetPoint('BOTTOMRIGHT', anchor, 'BOTTOMRIGHT', 2, -2)
	p:SetFrameLevel(math.max(level, 0))
	local t = K:GetTheme()
	p:SetBackdropColor(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, t.backdropFade.a)
	p:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
	return p
end

local function StyleWindow(obj)
	local w = obj and obj.widgets
	if not w or InCombatLockdown() then return end
	if not hookedProps[obj] and type(obj.UpdateProps) == 'function' then
		hookedProps[obj] = true
		hooksecurefunc(obj, 'UpdateProps', function(self) pcall(StyleWindow, self) end)
		-- Ventanas restauradas al recargar: WIM las arma antes que KnuUI y puede no volver a llamar
		-- UpdateProps; al mostrarse se reaplica (medido: tras /reload quedaba el marco de WIM y el ícono en alfa 1).
		obj:HookScript('OnShow', function(self) C_Timer.After(0, function() pcall(StyleWindow, self) end) end)
		-- UpdateIcon cambia imagen y máscara del ícono (WindowHandler.lua:1215) y RPProfiles la vuelve a
		-- llamar al mostrarse (Modules/RPProfiles.lua:441): también se reaplica después (revisión de Codex).
		if type(obj.UpdateIcon) == 'function' then
			hooksecurefunc(obj, 'UpdateIcon', function(self) pcall(StyleWindow, self) end)
		end
	end
	local bd = w.Backdrop
	if bd then
		for _, key in ipairs({ 'tl', 'tr', 'bl', 'br', 't', 'b', 'l', 'r', 'bg' }) do
			if bd[key] then bd[key]:SetAlpha(0) end
		end
	end
	local chrome = obj.wimChrome
	if chrome then
		chrome:SetAlpha(0)
		if chrome.well then chrome.well:SetAlpha(0) end
		if chrome.input then chrome.input:SetAlpha(0) end
	end
	-- La burbuja sobre negro es este mismo ícono: celda "blank" de modern-icons.png cuando no se conoce
	-- la clase (Skins/Modern/skin.lua:131, WindowHandler.lua:1270). Se oculta, además de alfa 0.
	if w.class_icon then w.class_icon:SetAlpha(0); w.class_icon:Hide() end
	Panel(obj, obj, obj:GetFrameLevel() - 1)
	if w.msg_box then
		local box = Panel(w.msg_box, w.msg_box, w.msg_box:GetFrameLevel() - 1)
		box:SetBackdropColor(0, 0, 0, 0.5)
	end
	K:SkinFont(w.from, true)
	K:SkinFont(w.char_info)
	-- Mensajes y caja de texto con la letra de la interfaz (Expressway, con contorno). WIM conserva la
	-- fuente que encuentra y sólo cambia el tamaño (UpdateProps, WindowHandler.lua:1551-1553), así que
	-- se pone una vez y se respeta su opción de tamaño. Los colores siguen los de WIM por tipo de mensaje.
	local font = E.Libs.LSM:Fetch('font', 'Expressway')
	for _, box in ipairs({ w.chat_display, w.msg_box }) do
		if box and box.GetFont and box.SetFont then
			local _, size = box:GetFont()
			box:SetFont(font, size or 13, 'OUTLINE')
			if box.SetShadowOffset then box:SetShadowOffset(0, 0) end
		end
	end
end

K:RegisterSkin('WIM', function()
	local WIM = _G.WIM
	if not WIM or type(WIM.ApplySkinToWindow) ~= 'function' then return end
	-- WIM llama a ApplySkinToWindow por su entorno (setfenv a WIM, Skinner.lua:20), así que el
	-- gancho sobre la tabla WIM alcanza también a sus llamadas internas.
	hooksecurefunc(WIM, 'ApplySkinToWindow', function(obj) pcall(StyleWindow, obj) end)
	-- El marco moderno se arma en ApplyModernThemeToWindow (Skinner.lua:1972), también por su entorno.
	if type(WIM.ApplyModernThemeToWindow) == 'function' then
		hooksecurefunc(WIM, 'ApplyModernThemeToWindow', function(obj) pcall(StyleWindow, obj) end)
	end
	-- Ventanas ya creadas antes de cargar la skin (Skinner.lua:263,2278: WIM:GetWindowSoupBowl().windows):
	-- ahora y otra vez unos segundos después, cuando WIM ya terminó de restaurarlas y armar su marco.
	local function All()
		local bowl = type(WIM.GetWindowSoupBowl) == 'function' and WIM:GetWindowSoupBowl()
		if bowl and type(bowl.windows) == 'table' then
			for _, entry in ipairs(bowl.windows) do pcall(StyleWindow, entry.obj) end
		end
	end
	All()
	C_Timer.After(3, All)
end)
