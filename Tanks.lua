local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Modo tanques (prueba): la vida y el maná del jugador como columnas que se llenan y vacían,
-- a los costados de las cuádruples, y el objetivo al centro arriba de la barra de lanzamiento.
-- Vida: el marco nativo del jugador en vertical (ElvUI aplica health.orientation a cualquier
-- unidad: Modules/UnitFrames/Elements/Health.lua:221-222). Maná: columna propia que se
-- actualiza igual que oUF (oUF/elements/power.lua:261-264), válido con valores secretos.

local W, H = 56, 154 -- misma altura que los chats: y 28-182 (techo de chats en 184)
-- Distribución en modo tanques (x en px; chats terminan en 404 y empiezan en 1516):
-- [3+5: 410-668] [vida: 674-730] [barras 1-2: 739-1181] [maná: 1190-1246] [4+6: 1252-1510]
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
	tank:SetPoint('BOTTOM', E.UIParent, 'BOTTOM', 258, 28) -- pegado a las barras centrales (x 1190-1246 en 1920)
	E:CreateMover(tank, 'KnuUI_ManaTankMover', L["KnuUI: mana tank"], nil, nil, nil, 'ALL,GENERAL')
	tank:RegisterUnitEvent('UNIT_POWER_FREQUENT', 'player')
	tank:RegisterUnitEvent('UNIT_MAXPOWER', 'player')
	tank:RegisterUnitEvent('UNIT_DISPLAYPOWER', 'player')
	tank:RegisterEvent('PLAYER_ENTERING_WORLD')
	tank:SetScript('OnEvent', UpdateTank)
end

function K:SetupTanks()
	if not E.db.KnuUITanks then return end
	if not tank then CreateTank() end
	local t = self:GetTheme()
	tank:SetBackdropBorderColor(t.accentDim.r, t.accentDim.g, t.accentDim.b)
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
			ElvUF_PlayerMover = 'BOTTOM,ElvUIParent,BOTTOM,-258,28', -- vida: x 674-730
			KnuUI_ManaTankMover = 'BOTTOM,ElvUIParent,BOTTOM,258,28', -- maná: x 1190-1246
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
		self:ApplyRoleOverlay() -- el grupo del Healer sube para no pisar el objetivo centrado
	else
		player.health.orientation = 'HORIZONTAL'
		self:ApplyLayout() -- vuelve al marco 240×54 y a las posiciones del boceto v4
	end
	return true
end
