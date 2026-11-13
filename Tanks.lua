local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Modo tanques (prueba): la vida y el maná del jugador como columnas que se llenan y vacían,
-- a los costados de las cuádruples, y el objetivo al centro arriba de la barra de lanzamiento.
-- Vida: el marco nativo del jugador en vertical (ElvUI aplica health.orientation a cualquier
-- unidad: Modules/UnitFrames/Elements/Health.lua:221-222). Maná: columna propia que se
-- actualiza igual que oUF (oUF/elements/power.lua:261-264), válido con valores secretos.

local W, H = 66, 154 -- misma altura que los chats: y 28-182 (techo de chats en 184)
local X = 256 -- centro de cada columna respecto del centro de pantalla
-- Distribución en modo tanques (x en px; chats terminan en 404 y empiezan en 1516):
-- [3+5: 410-668] [vida: 671-737] [barras 1-2: 739-1181] [maná: 1183-1249] [4+6: 1252-1510]
-- (columnas de 66: 2-3 px de separación a cada lado, como el espaciado de los botones)
-- Bloques laterales: 6×4 botones de 41×37 (256×154) = dos barras de 12.
local BARS = {
	-- Bloques laterales 6×4 (24 botones por lado) en el mismo espacio: botones de 41×37
	-- (6·41+5·2 = 256 de ancho; 4·37+3·2 = 154 de alto). Dos barras de 12 por lado (6×2 cada una).
	bar3 = { buttons = 12, perRow = 6, size = 41, height = 37, mover = 'BOTTOM,ElvUIParent,BOTTOM,-422,106' },  -- y 106-182
	bar5 = { buttons = 12, perRow = 6, size = 41, height = 37, mover = 'BOTTOM,ElvUIParent,BOTTOM,-422,28' },   -- y 28-104
	bar4 = { buttons = 12, perRow = 6, size = 41, height = 37, mover = 'BOTTOM,ElvUIParent,BOTTOM,420,106' },
	bar6 = { buttons = 12, perRow = 6, size = 41, height = 37, mover = 'BOTTOM,ElvUIParent,BOTTOM,420,28' },
	-- Barras centrales más grandes: 12 de 35 px = 442 de ancho (739-1181).
	bar1 = { buttons = 12, perRow = 12, size = 35, mover = 'BOTTOM,ElvUIParent,BOTTOM,0,65' },  -- y 65-100
	bar2 = { buttons = 12, perRow = 12, size = 35, mover = 'BOTTOM,ElvUIParent,BOTTOM,0,28' },  -- y 28-63
}
local tank

-- Bloques laterales compactos (elegibles por lado en ElvUI > KnuUI): 3×4 botones de 41×37
-- (3·41+2·2 = 127 de ancho, 154 de alto, y 28-182) en vez de 6×4; sólo la barra 3 (izquierda)
-- o la 4 (derecha) y se apaga la 5 o la 6. Los 129 px que se liberan van al panel de ese lado
-- (chat o Details) y la barra de datos de abajo se achica y se corre lo mismo.
local FREED = 256 - 127
local SIDES = {
	left = { key = 'KnuUICompactLeft', bar = 'bar3', extra = 'bar5', mover = 'BOTTOM,ElvUIParent,BOTTOM,-356,28' }, -- x 541-668
	right = { key = 'KnuUICompactRight', bar = 'bar4', extra = 'bar6', mover = 'BOTTOM,ElvUIParent,BOTTOM,356,28' }, -- x 1252-1379
}

-- Anchos de chat y barra de datos según los bloques. Sin modo columnas vuelve a 400 / 1100.
function K:ApplySideBlocks()
	local left = E.db.KnuUITanks and E.db.KnuUICompactLeft and FREED or 0
	local right = E.db.KnuUITanks and E.db.KnuUICompactRight and FREED or 0
	if E.db.KnuUITanks then
		for _, side in pairs(SIDES) do
			if E.db[side.key] then
				self.Set(E.db.actionbar[side.bar], {
					enabled = true, buttons = 12, buttonsPerRow = 3, buttonSize = 41, buttonHeight = 37,
					buttonSpacing = 2, keepSizeRatio = false, mouseover = false, inheritGlobalFade = false,
					alpha = 1, point = 'TOPLEFT',
				})
				E.db.actionbar[side.extra].enabled = false
				E.db.movers['ElvAB_'..side.bar:match('%d+')] = side.mover
			end
		end
	end
	-- Chat: Profile.lua (E.db.chat.separateSizes, panelWidthRight); Dock.lua:316 usa el derecho.
	self.Set(E.db.chat, {
		separateSizes = left ~= right, panelWidth = 400 + left, panelWidthRight = 400 + right,
	})
	local data = E.global.datatexts.customPanels.KnuUI_Data
	if data then data.width = 1100 - left - right end
	E.db.movers.DTPanelKnuUI_DataMover = format('BOTTOM,ElvUIParent,BOTTOM,%d,2', math.floor((left - right) / 2))
end

local function PowerColor()
	local _, token = UnitPowerType('player')
	local c = token and PowerBarColor and PowerBarColor[token]
	if c then return c.r, c.g, c.b end
	return 0, 0.55, 1
end

local function UpdateTank()
	if not tank or not tank:IsShown() then return end
	local max = UnitPowerMax('player')
	tank.bar:SetMinMaxValues(0, max)
	tank.bar:SetValue(UnitPower('player'))
	tank.bar:SetStatusBarColor(PowerColor())
	-- Porcentaje sin aritmética propia: oUF/elements/tags.lua:390-393.
	if UnitPowerPercent and CurveConstants and CurveConstants.ScaleTo100 then
		tank.text:SetFormattedText('%d', UnitPowerPercent('player', nil, true, CurveConstants.ScaleTo100))
	end
end

local function CreateTank()
	tank = CreateFrame('Frame', 'KnuUI_ManaTank', E.UIParent)
	tank:SetSize(W, H)
	tank:SetTemplate('Transparent')
	local bar = CreateFrame('StatusBar', nil, tank)
	bar:SetPoint('TOPLEFT', tank, 'TOPLEFT', 2, -2)
	bar:SetPoint('BOTTOMRIGHT', tank, 'BOTTOMRIGHT', -2, 2)
	bar:SetOrientation('VERTICAL')
	bar:SetStatusBarTexture(E.Libs.LSM:Fetch('statusbar', 'Melli'))
	tank.bar = bar
	local text = bar:CreateFontString(nil, 'OVERLAY')
	text:FontTemplate(nil, 13, 'OUTLINE')
	text:SetPoint('TOP', bar, 'TOP', 0, -4)
	tank.text = text
	tank:SetPoint('BOTTOM', E.UIParent, 'BOTTOM', X, 28) -- pegado a las barras centrales (x 1183-1249 en 1920)
	E:CreateMover(tank, 'KnuUI_ManaTankMover', L["KnuUI: mana tank"], nil, nil, nil, 'ALL,GENERAL')
	tank:RegisterUnitEvent('UNIT_POWER_FREQUENT', 'player')
	tank:RegisterUnitEvent('UNIT_MAXPOWER', 'player')
	tank:RegisterUnitEvent('UNIT_DISPLAYPOWER', 'player')
	tank:RegisterEvent('PLAYER_ENTERING_WORLD')
	tank:SetScript('OnEvent', UpdateTank)
end

function K:SetupTanks()
	-- El ancho de la barra de datos vive en lo global de ElvUI (customPanels, compartido entre perfiles) y
	-- depende de los bloques compactos de ESTE perfil: al tocar "Chat y datos" en otro perfil quedaba en
	-- 1100 y pisaba chat y Details en el tuyo (visto en el juego 2026-11-13). Se recalcula al cargar.
	local data = E.global.datatexts and E.global.datatexts.customPanels and E.global.datatexts.customPanels.KnuUI_Data
	if data and E.db.datatexts and E.db.datatexts.panels and E.db.datatexts.panels.KnuUI_Data then
		local left = E.db.KnuUITanks and E.db.KnuUICompactLeft and FREED or 0
		local right = E.db.KnuUITanks and E.db.KnuUICompactRight and FREED or 0
		local width = 1100 - left - right
		if data.width ~= width then
			data.width = width
			-- Aplicar ya si ElvUI armó la barra (DataTexts.lua:710, como Workspace.lua RelayoutPanels).
			local DT = E:GetModule('DataTexts', true)
			local panel = DT and DT.PanelPool and DT.PanelPool.InUse and DT.PanelPool.InUse.KnuUI_Data
			if panel and DT.UpdatePanelAttributes then pcall(DT.UpdatePanelAttributes, DT, 'KnuUI_Data', data) end
			if panel and DT.UpdatePanelInfo then pcall(DT.UpdatePanelInfo, DT, 'KnuUI_Data') end
			local mover = _G.DTPanelKnuUI_DataMover
			if mover then mover:SetWidth(width) end
		end
	end
	if not E.db.KnuUITanks then return end
	if not tank then CreateTank() end
	-- Perfiles armados con columnas de 56 px: una vez se pasan a 64 y se recentran. Sólo se cambia
	-- el perfil y el marco propio del maná; el del jugador lo redibuja ElvUI con su perfil al cargar.
	-- No se llama a UF:CreateAndUpdateUF: si ElvUI todavía no registró el marco, crea uno nuevo
	-- (UnitFrames.lua:1376-1381) y el de vida desaparecía.
	if E.db.KnuUITanksWidth ~= W and not InCombatLockdown() then
		E.db.KnuUITanksWidth = W
		E.db.unitframe.units.player.width = W
		E.db.movers.ElvUF_PlayerMover = 'BOTTOM,ElvUIParent,BOTTOM,'..(-X)..',28'
		E.db.movers.KnuUI_ManaTankMover = 'BOTTOM,ElvUIParent,BOTTOM,'..X..',28'
		tank:SetSize(W, H)
		local UF = E:GetModule('UnitFrames', true)
		if UF and UF.player and type(UF.player.Update) == 'function' then pcall(UF.player.Update) end
		if E.SetMoverPoints and _G.KnuUI_ManaTankMover then pcall(E.SetMoverPoints, E, 'KnuUI_ManaTankMover') end
		if E.SetMoverPoints and _G.ElvUF_PlayerMover then pcall(E.SetMoverPoints, E, 'ElvUF_PlayerMover') end
	end
	local t = self:GetTheme()
	-- Mismo borde que la columna de vida y los botones: el de ElvUI (E.media.bordercolor). El
	-- t.border del tema Knunet intenso es marrón anaranjado y se veía distinto de la vida.
	local bc = E.media.bordercolor
	if bc then tank:SetBackdropBorderColor(bc[1], bc[2], bc[3]) else tank:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b) end
	tank:Show()
	UpdateTank()
end

-- Prende o apaga el modo; se ve al recargar.
function K:ApplyTanks(enable)
	if not self:CanApply() then return false end
	E.db.KnuUITanks = enable and true or false
	local player = E.db.unitframe.units.player
	if enable then
		self.Set(player, {
			width = W, height = H,
			portrait = { enable = false }, power = { enable = false },
			name = { text_format = '' },
			health = { orientation = 'VERTICAL', position = 'TOP', xOffset = 0, yOffset = -4, text_format = '[perhp<%]' },
		})
		self.Set(E.db.movers, {
			ElvUF_PlayerMover = 'BOTTOM,ElvUIParent,BOTTOM,'..(-X)..',28', -- vida: x 671-737
			KnuUI_ManaTankMover = 'BOTTOM,ElvUIParent,BOTTOM,'..X..',28', -- maná: x 1183-1249
			ExperienceBarMover = 'BOTTOM,ElvUIParent,BOTTOM,0,104', -- 442×8, y 104-112
			ShiftAB = 'BOTTOM,ElvUIParent,BOTTOM,0,116', -- y 116-140
			ElvUF_PlayerCastbarMover = 'BOTTOM,ElvUIParent,BOTTOM,14,146', -- y 146-174
			PetAB = 'BOTTOM,ElvUIParent,BOTTOM,0,178', -- y 178-202
			-- Objetivo + objetivo del objetivo como un solo bloque centrado: 300 + 6 + 110 = 416 px,
			-- de x 752 a 1168 (centro en 960). Objetivo 300×60 (y 208-268); su objetivo 110×24 arriba a la derecha.
			ElvUF_TargetMover = 'BOTTOM,ElvUIParent,BOTTOM,-58,208',
			ElvUF_TargetTargetMover = 'BOTTOM,ElvUIParent,BOTTOM,153,244',
		})
		if E.db.databars.experience then E.db.databars.experience.width = 442 end
		self.Set(E.db.unitframe.units.target, { width = 300, height = 60 })
		self.Set(E.db.unitframe.units.targettarget, { width = 110, height = 24 })
		-- La barra de lanzamiento del objetivo va sobre su barra de maná: acompaña el ancho nuevo.
		self.Set(E.db.unitframe.units.target.castbar, { width = 300 })
		-- Bloques laterales ampliados (ver BARS arriba). Claves de barra: Profile.lua (P.actionbar.barN).
		for key, cfg in pairs(BARS) do
			local bar = E.db.actionbar[key]
			if bar then
				self.Set(bar, {
					enabled = true, buttons = cfg.buttons, buttonsPerRow = cfg.perRow,
					buttonSize = cfg.size, buttonHeight = cfg.height or cfg.size, buttonSpacing = 2, keepSizeRatio = cfg.height == nil,
					mouseover = false, inheritGlobalFade = false, alpha = 1, point = 'TOPLEFT',
				})
				if bar.showGrid ~= nil then bar.showGrid = true end
				E.db.movers['ElvAB_'..key:match('%d+')] = cfg.mover
			end
		end
		self:ApplySideBlocks() -- bloques compactos elegidos y anchos de chat/datos
		self:ApplyRoleOverlay() -- el grupo del Healer sube para no pisar el objetivo centrado
	else
		player.health.orientation = 'HORIZONTAL'
		self:ApplyLayout() -- vuelve al marco 240×54 y a las posiciones del boceto v4
		self:ApplySideBlocks() -- chats de 400 y barra de datos de 1100 otra vez
	end
	return true
end
