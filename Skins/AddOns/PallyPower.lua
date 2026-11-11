local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- PallyPower Forever (PallyPower_Camelot.toc carga PallyPower_Vanilla.xml).
-- KnuUI rearma su barra como una franja compacta de una fila pegada a la guía de WoW-Pro:
--   primero lo propio (Auto, Aura, Furia justa + sello) y después una casilla por clase presente;
--   crece hacia la derecha y las listas de jugadores se abren hacia abajo.
-- Sólo se cambia tamaño, posición y estilo; clicks, hechizos y estado siguen siendo de PallyPower.
-- Cómo arma PallyPower la barra (PallyPower.lua):
--   CreateLayout (:2451): botones seguros hijos de PallyPowerFrame (1×1, PallyPower_Vanilla.xml).
--   UpdateLayout (:2570): los ubica respecto del centro de PallyPowerFrame según opt.layout, decide
--     cuáles se ven (clases presentes: atributo "Display" = 1) y aplica la escala opt.buffscale.
--     No corre en combate. KnuUI reacomoda todo justo después de cada UpdateLayout.
--   UpdateButton (:2873) / ButtonsUpdate (:3172): textos, íconos y color de estado cada segundo
--     (ApplyBackdrop, :4304, sólo SetBackdropColor).
-- El tamaño de los botones viene fijo del XML (100×34); opt.display.buttonWidth sólo cambia la
-- separación (:2578-2590), así que el tamaño y los íconos/textos internos se ponen acá.

local TILE, GAP, PAD = 31, 2, 3
local POP_W, POP_H, POP_GAP = 140, 20, 2

local backdrop
local function Flat(frame, t)
	if not frame or not frame.SetBackdrop then return end
	backdrop = backdrop or { bgFile = E.media.blankTex, edgeFile = E.media.blankTex, tile = false,
		edgeSize = E.mult, insets = { left = 0, right = 0, top = 0, bottom = 0 } }
	local r, g, b, a = frame:GetBackdropColor()
	frame:SetBackdrop(backdrop)
	if r then frame:SetBackdropColor(r, g, b, a) end
	frame:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
end

local function OwnButtons()
	return { _G.PallyPowerAuto, _G.PallyPowerAura, _G.PallyPowerRF }
end

local function StyleBar()
	local PP = _G.PallyPower
	if not PP or InCombatLockdown() then return end
	local t = K:GetTheme()
	for _, button in ipairs(OwnButtons()) do Flat(button, t) end
	for _, button in pairs(PP.classButtons or {}) do Flat(button, t) end
	for _, list in pairs(PP.playerButtons or {}) do
		for _, button in pairs(list) do Flat(button, t) end
	end
end

-- Estado (rojo/amarillo/verde/azul de PallyPower) sólo en una barra de 4 px abajo; borde oscuro de
-- ElvUI (E.media.bordercolor, como los botones de acción) y fondo del tema; el borde del tema va en
-- el marco de la grilla. Se aplica después de cada ApplyBackdrop de PallyPower.
local function Mute(button)
	if not button or not button.GetBackdropColor then return end
	local r, g, b = button:GetBackdropColor()
	if not r then return end
	local bg = K:GetTheme().backdropFade
	button:SetBackdropColor(bg.r, bg.g, bg.b, 0.9)
	local border = E.media.bordercolor or { 0, 0, 0 }
	button:SetBackdropBorderColor(border[1] or border.r or 0, border[2] or border.g or 0, border[3] or border.b or 0)
	if not button.KnuStripe then
		button.KnuStripe = button:CreateTexture(nil, 'OVERLAY', nil, 7)
	end
	local stripe = button.KnuStripe
	stripe:ClearAllPoints()
	stripe:SetPoint('BOTTOMLEFT', 1, 1)
	stripe:SetPoint('BOTTOMRIGHT', -1, 1)
	stripe:SetHeight(4)
	stripe:SetColorTexture(r, g, b, 1)
end

local function Font(fs, size)
	if not fs then return end
	if fs.FontTemplate then fs:FontTemplate('Expressway', size, 'OUTLINE') end
	fs:SetDrawLayer('OVERLAY', 7)
end

local function Icon(tex, size, point, x, y, relPoint)
	if not tex then return end
	tex:ClearAllPoints()
	tex:SetSize(size, size)
	tex:SetPoint(point, tex:GetParent(), relPoint or point, x, y)
	tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	-- En el XML íconos y textos comparten la capa OVERLAY: el ícono grande tapaba el tiempo.
	tex:SetDrawLayer('ARTWORK', 1)
end

local function Text(fs, point, x, y, size, justify, width)
	if not fs then return end
	fs:ClearAllPoints()
	fs:SetPoint(point, fs:GetParent(), point, x, y)
	if width then fs:SetWidth(width) end
	fs:SetJustifyH(justify or 'CENTER')
	Font(fs, size)
end

-- Interior de cada casilla. Los nombres son los del XML de PallyPower.
local function StyleTile(name, kind)
	if kind == 'class' then
		Icon(_G[name..'ClassIcon'], TILE - 4, 'CENTER', 0, 0)
		Icon(_G[name..'BuffIcon'], 13, 'TOPLEFT', 2, -2)
		Text(_G[name..'Time'], 'BOTTOM', 0, 5, 9, 'CENTER', TILE)
		Text(_G[name..'Time2'], 'BOTTOM', 0, 5, 9, 'CENTER', TILE)
		Text(_G[name..'Text'], 'TOPRIGHT', -2, -2, 10, 'RIGHT', 16)
	elseif kind == 'auto' then
		Icon(_G[name..'Icon'], TILE - 4, 'CENTER', 0, 0)
		Text(_G[name..'Time'], 'BOTTOM', 0, 5, 9, 'CENTER', TILE)
		Text(_G[name..'Time2'], 'BOTTOM', 0, 5, 9, 'CENTER', TILE)
		Text(_G[name..'Text'], 'TOPRIGHT', -2, -2, 10, 'RIGHT', 16)
	elseif kind == 'aura' then
		Icon(_G[name..'Icon'], TILE - 4, 'CENTER', 0, 0)
		for _, key in ipairs({ 'Player1', 'Player2' }) do
			if _G[name..key] then _G[name..key]:SetAlpha(0) end
		end
	elseif kind == 'rf' then
		-- Un solo botón seguro con dos íconos (clic izquierdo Furia justa, derecho sello).
		-- Sin Furia justa (opt.rf apagado) PallyPower le saca el ícono (RFAssign, :4368): casilla simple.
		local rf = _G.PallyPower and _G.PallyPower.opt and _G.PallyPower.opt.rf
		local icon, seal = _G[name..'Icon'], _G[name..'IconSeal']
		local t1, t2 = _G[name..'Time1'], _G[name..'Time2']
		if rf then
			Icon(icon, TILE - 4, 'LEFT', 2, 0)
			Icon(seal, TILE - 4, 'RIGHT', -2, 0)
			if icon then icon:SetAlpha(1) end
			if t1 then t1:SetAlpha(1); t1:ClearAllPoints(); t1:SetPoint('BOTTOM', icon, 'BOTTOM', 0, 2); t1:SetWidth(TILE); t1:SetJustifyH('CENTER'); Font(t1, 9) end
		else
			Icon(seal, TILE - 4, 'CENTER', 0, 0)
			if icon then icon:SetAlpha(0) end
			if t1 then t1:SetAlpha(0) end
		end
		if t2 then t2:ClearAllPoints(); t2:SetPoint('BOTTOM', seal, 'BOTTOM', 0, 2); t2:SetWidth(TILE); t2:SetJustifyH('CENTER'); Font(t2, 9) end
	end
end

-- Filas de jugadores al pasar el mouse por una clase: a la derecha de la casilla, hacia abajo.
local function StylePopup(name)
	local icon = _G[name..'BuffIcon']
	Icon(icon, 16, 'LEFT', 2, 0)
	local time = _G[name..'Time']
	if time and icon then
		time:ClearAllPoints(); time:SetPoint('LEFT', icon, 'RIGHT', 3, 0); time:SetWidth(34)
		time:SetJustifyH('LEFT'); Font(time, 9)
	end
	Text(_G[name..'Rng'], 'RIGHT', -4, 0, 9, 'RIGHT', 10)
	local dead, rng = _G[name..'Dead'], _G[name..'Rng']
	if dead and rng then dead:ClearAllPoints(); dead:SetPoint('RIGHT', rng, 'LEFT', -2, 0); Font(dead, 9) end
	local nameText = _G[name..'Name']
	if nameText and time then
		nameText:ClearAllPoints(); nameText:SetPoint('LEFT', time, 'RIGHT', 2, 0); nameText:SetWidth(POP_W - 82)
		nameText:SetJustifyH('LEFT'); Font(nameText, 10)
	end
end

local function Visible(button)
	return button and button:IsShown()
end

local function Size(button, w, h)
	button:SetSize(w, h)
end

-- Franja de una fila pegada a la derecha de la guía de WoW-Pro (8 px), con el borde de arriba
-- alineado al de la guía; crece hacia la derecha. Sin la guía, arriba a la izquierda (8, -8),
-- donde Skins/WoWPro.lua pone la guía.
-- Las listas de jugadores se abren hacia abajo, debajo de su casilla: el mouse baja directo sin
-- cruzar otra clase (al entrar a otra clase PallyPower cierra la lista abierta, PallyPower.lua:2484, 2502).
local pending
local function Arrange()
	local PP, header = _G.PallyPower, _G.PallyPowerFrame
	if not (PP and header and PP.classButtons) then return end
	if InCombatLockdown() then pending = true return end
	pending = false
	header:SetScale(1)
	-- El ancla de arrastre no sirve con la franja (la posición la pone KnuUI). Además de esconderla se
	-- le apaga el mouse: su OnDragStop llama a PallyPower:DragStop (PallyPower.lua:3950-3953), que no
	-- revisa el combate y movía PallyPowerFrame, protegido por sus botones seguros
	-- (ADDON_ACTION_BLOCKED 'PallyPowerFrame:StopMovingOrSizing()').
	local anchor = _G.PallyPowerAnchor
	if anchor then
		anchor:Hide()
		anchor:EnableMouse(false)
		anchor:SetAlpha(0)
	end

	-- Primero lo propio, después las clases presentes en el orden de PallyPower.
	local items = {}
	if Visible(_G.PallyPowerAuto) then items[#items + 1] = { _G.PallyPowerAuto, 'auto', 1 } end
	if Visible(_G.PallyPowerAura) then items[#items + 1] = { _G.PallyPowerAura, 'aura', 1 } end
	if Visible(_G.PallyPowerRF) then items[#items + 1] = { _G.PallyPowerRF, 'rf', (PP.opt and PP.opt.rf) and 2 or 1 } end
	for i, button in ipairs(PP.classButtons) do
		if button:GetAttribute('Display') == 1 and button:IsShown() then items[#items + 1] = { button, 'class', 1, i } end
	end

	local guide = _G.WoWPro and _G.WoWPro.MainFrame
	-- La guía puede mostrarse después del primer acomodo (al entrar, o al abrirla): sin esto la
	-- franja quedaba en la esquina, debajo de la guía. Se reacomoda cada vez que la guía aparece o se va.
	if guide and not guide.KnuPallyHooked then
		guide.KnuPallyHooked = true
		guide:HookScript('OnShow', function() C_Timer.After(0, function() pcall(Arrange) end) end)
		guide:HookScript('OnHide', function() C_Timer.After(0, function() pcall(Arrange) end) end)
	end
	header:ClearAllPoints()
	if guide and guide:IsShown() then
		header:SetPoint('TOPLEFT', guide, 'TOPRIGHT', 8 + PAD, -PAD)
	else
		header:SetPoint('TOPLEFT', E.UIParent, 'TOPLEFT', 8 + PAD, -8 - PAD)
	end

	-- Marco KnuUI detrás de las casillas: fondo del tema, línea de acento y sombra (Motion.lua).
	local frame = _G.KnuUI_PallyGrid
	if not frame then
		frame = CreateFrame('Frame', 'KnuUI_PallyGrid', header, 'BackdropTemplate')
		frame:SetTemplate('Transparent')
		if K.KnuFrame then K:KnuFrame(frame) end
	end
	frame:SetFrameStrata(_G.PallyPowerAuto and _G.PallyPowerAuto:GetFrameStrata() or 'LOW')
	frame:SetFrameLevel(header:GetFrameLevel())
	local t = K:GetTheme()
	frame:SetBackdropColor(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, t.backdropFade.a)
	frame:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)

	local col = 0
	for _, item in ipairs(items) do
		local button, kind, span, index = item[1], item[2], item[3], item[4]
		button:ClearAllPoints()
		button:SetPoint('TOPLEFT', header, 'TOPLEFT', col * (TILE + GAP), 0)
		Size(button, span * TILE + (span - 1) * GAP, TILE)
		if kind == 'class' then
			StyleTile('PallyPowerC'..index, 'class')
			for p, pop in ipairs(PP.playerButtons[index] or {}) do
				-- Debajo del marco (4 px por debajo de su borde), alineada con su casilla.
				pop:ClearAllPoints()
				pop:SetPoint('TOPLEFT', button, 'BOTTOMLEFT', 0, -(PAD + 4) - (p - 1) * (POP_H + POP_GAP))
				Size(pop, POP_W, POP_H)
				StylePopup('PallyPowerC'..index..'P'..p)
			end
		else
			StyleTile(button:GetName(), kind)
		end
		col = col + span
	end

	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', header, 'TOPLEFT', -PAD, PAD)
	frame:SetSize(col * TILE + math.max(0, col - 1) * GAP + 2 * PAD, TILE + 2 * PAD)
	frame:SetShown(col ~= 0)

	-- Al cargar, PallyPower pone su barra en el centro de UIParent más opt.display.offsetX/Y, con su
	-- escala opt.buffscale (PallyPower.lua:309-311): con los valores viejos aparecía un momento en la
	-- esquina, detrás de la guía, hasta este acomodo. Se guarda ahí la posición final, en las unidades
	-- de esa escala, para que el próximo arranque ya empiece en su lugar.
	C_Timer.After(0, function()
		local display = PP.opt and PP.opt.display
		local hx, hy = header:GetCenter()
		local ux, uy = UIParent:GetCenter()
		if not (display and hx and ux) then return end
		local ratio = UIParent:GetEffectiveScale() / (header:GetParent() or UIParent):GetEffectiveScale()
		local scale = tonumber(PP.opt.buffscale) or 1
		local hs = header:GetEffectiveScale() / UIParent:GetEffectiveScale()
		display.offsetX = (hx * hs - ux) / scale * ratio
		display.offsetY = (hy * hs - uy) / scale * ratio
	end)
end

-- Aviso de aura repetida: PallyPower pone en Player1/Player2 los paladines del subgrupo con la
-- misma aura (UpdateAuraButton, :4927). En la casilla se ve un "!" y los nombres van al tooltip.
local function AuraWarning()
	local aura = _G.PallyPowerAura
	if not aura then return end
	if not aura.KnuWarn then
		aura.KnuWarn = aura:CreateFontString(nil, 'OVERLAY')
		aura.KnuWarn:SetPoint('TOPRIGHT', -2, -1)
		Font(aura.KnuWarn, 13)
		aura.KnuWarn:SetText('!')
		aura.KnuWarn:SetTextColor(1, 0.3, 0.2)
		aura:HookScript('OnEnter', function(self)
			local p1, p2 = _G.PallyPowerAuraPlayer1, _G.PallyPowerAuraPlayer2
			local names = {}
			for _, fs in ipairs({ p1, p2 }) do
				local text = fs and fs:GetText()
				if text and text ~= '' then names[#names + 1] = text end
			end
			if #names == 0 then return end
			if not GameTooltip:IsOwned(self) then GameTooltip:SetOwner(self, 'ANCHOR_RIGHT') end
			GameTooltip:AddLine(table.concat(names, ', '), 1, 0.3, 0.2)
			GameTooltip:Show()
		end)
	end
	local text = _G.PallyPowerAuraPlayer1 and _G.PallyPowerAuraPlayer1:GetText()
	aura.KnuWarn:SetShown(text ~= nil and text ~= '')
end

-- Con dos tiempos en el mismo lugar se muestra el de la bendición superior si existe; si no, el de
-- la normal (el caso de Forever).
local function OneTime(name)
	local t1, t2 = _G[name..'Time'], _G[name..'Time2']
	if not (t1 and t2) then return end
	local text = t1:GetText()
	local first = text ~= nil and text ~= ''
	t1:SetAlpha(first and 1 or 0)
	t2:SetAlpha(first and 0 or 1)
end

local function Times()
	local PP = _G.PallyPower
	if not (PP and PP.classButtons) then return end
	for i in ipairs(PP.classButtons) do OneTime('PallyPowerC'..i) end
	OneTime('PallyPowerAuto')
end

K:RegisterSkin('PallyPower', function()
	local PP = _G.PallyPower
	if not PP or type(PP.ApplySkin) ~= 'function' then return end
	hooksecurefunc(PP, 'ApplySkin', function() pcall(StyleBar) end)
	if type(PP.ApplyBackdrop) == 'function' then
		hooksecurefunc(PP, 'ApplyBackdrop', function(_, button) pcall(Mute, button) end)
	end
	if type(PP.UpdateLayout) == 'function' then
		hooksecurefunc(PP, 'UpdateLayout', function() pcall(Arrange) end)
	end
	if type(PP.ButtonsUpdate) == 'function' then
		hooksecurefunc(PP, 'ButtonsUpdate', function() pcall(Times) end)
	end
	if type(PP.UpdateAuraButton) == 'function' then
		hooksecurefunc(PP, 'UpdateAuraButton', function() pcall(AuraWarning) end)
	end
	local events = CreateFrame('Frame')
	events:RegisterEvent('PLAYER_REGEN_ENABLED')
	events:RegisterEvent('PLAYER_ENTERING_WORLD')
	events:SetScript('OnEvent', function(_, event)
		if event == 'PLAYER_ENTERING_WORLD' or pending then
			C_Timer.After(1, function() pcall(Arrange) end)
		end
	end)
	StyleBar()
	pcall(Arrange)
	-- Ventana de asignaciones (PallyPower_Vanilla.xml: PallyPowerBlessingsFrame, fondo de tooltip).
	-- Sólo el marco exterior: adentro hay botones de bendición con íconos propios.
	K:WatchAddonFrame('PallyPower', 'PallyPowerBlessingsFrame', nil, true)
end)
