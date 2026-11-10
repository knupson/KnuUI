local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- PallyPower Forever (v1.6.5-classic, PallyPower_Camelot.toc carga PallyPower_Vanilla.xml).
-- La barra pinta fondo y borde con texturas de LibSharedMedia en PallyPower:ApplySkin
-- (PallyPower.lua:4275-4302) y el color de cada botón indica el estado del buff
-- (ApplyBackdrop, :4304-4310, sólo SetBackdropColor). KnuUI reemplaza fondo y borde por los planos
-- de ElvUI con borde del tema, después de cada ApplySkin: los colores de estado siguen intactos.
local function Flat(frame, backdrop, t)
	if not frame or not frame.SetBackdrop then return end
	local r, g, b, a = frame:GetBackdropColor()
	frame:SetBackdrop(backdrop)
	if r then frame:SetBackdropColor(r, g, b, a) end
	frame:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
end

local function StyleBar()
	local PP = _G.PallyPower
	if not PP or InCombatLockdown() then return end
	local t = K:GetTheme()
	local backdrop = { bgFile = E.media.blankTex, edgeFile = E.media.blankTex, tile = false,
		edgeSize = E.mult, insets = { left = 0, right = 0, top = 0, bottom = 0 } }
	for _, name in ipairs({ 'PallyPowerAura', 'PallyPowerRF', 'PallyPowerAuto' }) do
		Flat(_G[name], backdrop, t)
	end
	for _, button in pairs(PP.classButtons or {}) do Flat(button, backdrop, t) end
	for _, list in pairs(PP.playerButtons or {}) do
		for _, button in pairs(list) do Flat(button, backdrop, t) end
	end
end

-- Fondo oscuro del tema como el resto de la interfaz; el estado (rojo/amarillo/verde de
-- PallyPower) pasa a una franja de 3 px a la izquierda y al borde.
-- (Mezclarlo al 45 % en el fondo dejaba bloques verdes que no parecían skineados.)
-- Se aplica después de cada ApplyBackdrop de PallyPower, que es donde cambia el estado.
local TINT = 0 -- con 0.12 el fondo medido daba 0.06/0.12/0.02 y en pantalla seguía leyéndose verde
local function Mute(button)
	if not button or not button.GetBackdropColor then return end
	local r, g, b = button:GetBackdropColor()
	if not r then return end
	local bg = K:GetTheme().backdropFade
	button:SetBackdropColor(bg.r + (r - bg.r) * TINT, bg.g + (g - bg.g) * TINT, bg.b + (b - bg.b) * TINT, 0.9)
	button:SetBackdropBorderColor(r * 0.7, g * 0.7, b * 0.7)
	if not button.KnuStripe then
		button.KnuStripe = button:CreateTexture(nil, 'ARTWORK')
		button.KnuStripe:SetPoint('TOPLEFT', 1, -1)
		button.KnuStripe:SetPoint('BOTTOMLEFT', 1, 1)
		button.KnuStripe:SetWidth(3)
	end
	button.KnuStripe:SetColorTexture(r, g, b, 0.9)
end

-- Una vez por perfil: la barra queda debajo de la guía de WoW-Pro (Skins/WoWPro.lua la pone en
-- TOPLEFT 8,-8), pegada a la izquierda; sin WoW-Pro, a la izquierda bajo el borde superior.
-- PallyPower guarda su posición en opt.display.offsetX/Y respecto del centro de UIParent
-- (PallyPower.lua:309-311), así que se corrigen esos valores y se respetan si el jugador la mueve.
-- Borde superior izquierdo de lo que se ve de la barra, en píxeles de pantalla.
local function Bounds(PP)
	local left, top
	local function Measure(frame)
		if frame and frame:IsVisible() and frame:GetLeft() then
			local s = frame:GetEffectiveScale()
			left = math.min(left or math.huge, frame:GetLeft() * s)
			top = math.max(top or -math.huge, frame:GetTop() * s)
		end
	end
	for _, name in ipairs({ 'PallyPowerAura', 'PallyPowerRF', 'PallyPowerAuto' }) do Measure(_G[name]) end
	for _, button in pairs(PP.classButtons or {}) do Measure(button) end
	return left, top
end

local function Target()
	local ui = UIParent:GetEffectiveScale()
	local guide = _G.WoWPro and _G.WoWPro.MainFrame
	local top = (guide and guide:IsVisible() and guide:GetBottom()) and (guide:GetBottom() * guide:GetEffectiveScale() - 8 * ui)
		or (UIParent:GetTop() - 300) * ui
	return 8 * ui, top
end

-- La 1.ª versión sumaba el corrimiento a offsetX/Y (lo guardado) y no a la posición real: si el
-- juego había restaurado la barra en otro lugar, quedaba corrida. Ahora se parte del centro real
-- del marco, se verifica que llegó y recién ahí se marca hecho (KnuUIPallyPlaced2); si no, reintenta.
local function PlaceBar(try)
	try = try or 1
	local PP, header = _G.PallyPower, _G.PallyPowerFrame
	if E.db.KnuUIPallyPlaced2 or try > 5 or not header or not (PP and PP.opt and PP.opt.display) then return end
	if InCombatLockdown() then C_Timer.After(5, function() pcall(PlaceBar, try) end) return end
	local left, top = Bounds(PP)
	if not left then C_Timer.After(2, function() pcall(PlaceBar, try + 1) end) return end -- todavía no armó la barra
	local targetLeft, targetTop = Target()
	local s, ui = header:GetEffectiveScale(), UIParent:GetEffectiveScale()
	local cx, cy = header:GetCenter()
	local ux, uy = UIParent:GetCenter()
	local x = (cx * s + (targetLeft - left) - ux * ui) / s
	local y = (cy * s + (targetTop - top) - uy * ui) / s
	header:ClearAllPoints()
	header:SetPoint('CENTER', UIParent, 'CENTER', x, y)
	PP.opt.display.offsetX, PP.opt.display.offsetY = x, y
	C_Timer.After(0.3, function()
		local l, t = Bounds(PP)
		if l and math.abs(l - targetLeft) <= 2 and math.abs(t - targetTop) <= 2 then
			E.db.KnuUIPallyPlaced2 = true
		else
			C_Timer.After(2, function() pcall(PlaceBar, try + 1) end)
		end
	end)
end

K:RegisterSkin('PallyPower', function()
	local PP = _G.PallyPower
	if not PP or type(PP.ApplySkin) ~= 'function' then return end
	hooksecurefunc(PP, 'ApplySkin', function() pcall(StyleBar) end)
	if type(PP.ApplyBackdrop) == 'function' then
		hooksecurefunc(PP, 'ApplyBackdrop', function(_, button) pcall(Mute, button) end)
	end
	StyleBar()
	-- Después de que PallyPower y WoW-Pro terminen de ubicarse al entrar.
	C_Timer.After(3, function() pcall(PlaceBar) end)
	-- Ventana de asignaciones (PallyPower_Vanilla.xml: PallyPowerBlessingsFrame, fondo de tooltip).
	-- Sólo el marco exterior: adentro hay botones de bendición con íconos propios.
	K:WatchAddonFrame('PallyPower', 'PallyPowerBlessingsFrame', nil, true)
end)
