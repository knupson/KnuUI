local E, L, V, P, G = unpack(ElvUI)
local K = E:GetModule('KnuUI')
local Set = K.Set

-- Referencias bajo _ref/ElvUI/Game/Shared:
-- Defaults/Profile.lua:1383-1627,1690-2651,3257 (chat, datos, barras y unidades).
-- Movers adicionales: Modules/ActionBars/StanceBar.lua:259, PetBar.lua:284;
-- Modules/Maps/Minimap.lua:846; Modules/UnitFrames/UnitFrames.lua:1282-1306.
-- Movers: Layout/Layout.lua:348,400; Modules/ActionBars/ActionBars.lua:516;
-- Modules/UnitFrames/Units/Player.lua:59 y Units/*.lua (frame:GetName()..'Mover');
-- Modules/UnitFrames/Elements/CastBar.lua:185; Modules/Auras/Auras.lua:795,827;
-- Modules/DataBars/Experience.lua:314; Modules/DataTexts/DataTexts.lua:341.
-- Coordenadas absolutas sobre ElvUIParent; origen abajo a la izquierda.
local movers = {
	LeftChatMover = 'BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,4,4',
	RightChatMover = 'BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-4,4',
	DTPanelKnuUI_DataMover = 'BOTTOM,ElvUIParent,BOTTOM,0,2',
	-- Boceto v4. Centro: barra 1 (1 al ¿) y barra 2 en filas de 12 (x 757-1163).
	ElvAB_1 = 'BOTTOM,ElvUIParent,BOTTOM,0,64', -- 1 al ¿ arriba: 406×32, y 64-96
	ElvAB_2 = 'BOTTOM,ElvUIParent,BOTTOM,0,28', -- 406×32, y 28-60
	-- Cuádruples 4×3 de 40 px (166×124) a los costados, donde estaban los marcos.
	ElvAB_3 = 'BOTTOM,ElvUIParent,BOTTOM,-298,28', -- x 579-745, y 28-152
	ElvAB_4 = 'BOTTOM,ElvUIParent,BOTTOM,298,28', -- x 1175-1341, y 28-152
	ElvAB_5 = 'RIGHT,ElvUIParent,RIGHT,-4,0',
	ElvAB_6 = 'RIGHT,ElvUIParent,RIGHT,-40,0',
	ExperienceBarMover = 'BOTTOM,ElvUIParent,BOTTOM,0,100', -- 406×8, y 100-108
	ShiftAB = 'BOTTOM,ElvUIParent,BOTTOM,0,112', -- y 112-136
	ElvUF_PlayerCastbarMover = 'BOTTOM,ElvUIParent,BOTTOM,14,142', -- 300×28 + ícono, centrado; y 142-170
	PetAB = 'BOTTOM,ElvUIParent,BOTTOM,0,174', -- y 174-198
	-- Marcos arriba de las cuádruples, alineados con su borde de afuera hacia el centro.
	ElvUF_PlayerMover = 'BOTTOM,ElvUIParent,BOTTOM,-335,162', -- 240×54, x 505-745
	ElvUF_TargetMover = 'BOTTOM,ElvUIParent,BOTTOM,335,162', -- 240×54, x 1175-1415
	ElvUF_FocusMover = 'BOTTOM,ElvUIParent,BOTTOM,-398,226',
	ElvUF_PetMover = 'BOTTOM,ElvUIParent,BOTTOM,-273,226',
	ElvUF_TargetTargetMover = 'BOTTOM,ElvUIParent,BOTTOM,507,192', -- 92×24, x 1421-1513
	KnuUI_ButtonsMover = 'TOPRIGHT,ElvUIParent,TOPRIGHT,-8,-238', -- lanzador debajo de franjas y brillo, sin tocarlos
	ElvUF_PartyMover = 'TOPLEFT,ElvUIParent,LEFT,8,110',
	ElvUF_Raid1Mover = 'TOPLEFT,ElvUIParent,LEFT,8,110',
	ElvUF_Raid2Mover = 'TOPLEFT,ElvUIParent,LEFT,8,110',
	ElvUF_Raid3Mover = 'TOPLEFT,ElvUIParent,LEFT,8,110',
	MinimapMover = 'TOPRIGHT,ElvUIParent,TOPRIGHT,-8,-8',
	BuffsMover = 'TOPRIGHT,ElvUIParent,TOPRIGHT,-200,-8',
	DebuffsMover = 'TOPRIGHT,ElvUIParent,TOPRIGHT,-200,-148', -- debajo de 3 filas de buffs de 36
}

-- En Forever (E.Modern) no existen health:current-percent ni similares;
-- sí health:current:shortvalue, power:current:shortvalue y perhp (Tags/Modern.lua y oUF).
-- Tags: _ref/ElvUI/Game/Shared/Tags/Shared.lua:1408,1482,1485,1512;
-- _ref/ElvUI_Libraries/Game/Shared/oUF/elements/tags.lua:376.
local HEALTH_TEXT = '[health:current:shortvalue] - [perhp<%]'
local POWER_TEXT = '||cFF4FA3FF[power:current:shortvalue]||r'

local function UnitLayout(unit, width, height, small)
	local db = E.db.unitframe.units[unit]
	Set(db, {
		enable = true, width = width, height = height,
		infoPanel = { enable = false },
		-- Retrato 3D al costado (no superpuesto); el objetivo lo lleva a la derecha.
		portrait = {
			enable = not small, style = '3D', overlay = false, fullOverlay = false,
			width = 54, camDistanceScale = 2, rotation = 0, desaturation = 0, paused = false,
		},
		power = {
			enable = not small, height = 14, width = 'fill', detachFromFrame = false, offset = 0,
			attachTextTo = 'Power', position = 'RIGHT', xOffset = -3, yOffset = 0,
			text_format = small and '' or POWER_TEXT,
		},
		name = {
			attachTextTo = 'Health', position = 'LEFT', xOffset = 3, yOffset = 0,
			text_format = small and '[name:short]' or '[name:medium]',
		},
		health = {
			attachTextTo = 'Health', position = 'RIGHT', xOffset = -3, yOffset = 0,
			text_format = small and '[perhp<%]' or HEALTH_TEXT,
		},
	})
	-- Las auras del jugador van arriba; las del objetivo se acomodan aparte.
	for _, key in ipairs({ 'aurabar', 'auras', 'buffs', 'debuffs' }) do
		if db[key] then db[key].enable = false end
	end
	if db.castbar then db.castbar.enable = false end
end

function K:ApplyLayout()
	if not self:CanApply() then return false end
	-- S&L dejó experiencia y reputación verticales al costado de sus chats viejos.
	Set(E.db.databars.experience, {
		enable = true, orientation = 'HORIZONTAL', width = 406, height = 8, mouseover = false,
	})
	-- Conserva únicamente los ajustes opcionales de marcas de banda de S&L.
	self:ApplySLE()
	E.db.databars.reputation.enable = false -- valor por defecto de ElvUI
	-- Barra de marcas de banda de S&L: sólo en grupo (por defecto aparece al tener objetivo).


	E.db.actionbar.globalFadeAlpha = 0 -- pedido del user: nada se vuelve transparente (1 - 0 = opaco)
	-- perRow, tamaño, separación, sólo con mouse.
	local bars = {
		[1] = { 12, 32, 2, false },
		[2] = { 12, 32, 2, false },
		[3] = { 4, 40, 2, false },
		[4] = { 4, 40, 2, false },
		[5] = { 1, 32, 2, false }, -- siempre visibles, sin mouseover
		[6] = { 1, 32, 2, false },
	}
	for key in pairs(P.actionbar) do
		local id = tonumber(key:match('^bar(%d+)$'))
		if id then
			local db, cfg = E.db.actionbar[key], bars[id]
			db.enabled = cfg ~= nil
			-- El bloque central muestra las casillas vacías para leerse completo.
			if db.showGrid ~= nil then db.showGrid = id <= 4 end
			if cfg then
				Set(db, {
					buttons = 12, buttonsPerRow = cfg[1],
					buttonSize = cfg[2], buttonHeight = cfg[2], keepSizeRatio = true,
					buttonSpacing = cfg[3], backdrop = false, backdropSpacing = 0,
					widthMult = 1, heightMult = 1, alpha = 1, clickThrough = false,
					mouseover = cfg[4], inheritGlobalFade = false,
					point = 'TOPLEFT', visibility = P.actionbar[key].visibility,
				})
			end
		end
	end
	for _, key in ipairs({ 'stanceBar', 'barPet' }) do
		Set(E.db.actionbar[key], {
			enabled = true, buttonSize = 24, buttonHeight = 24, keepSizeRatio = true,
			buttonSpacing = 2, backdrop = false, backdropSpacing = 0,
			buttons = P.actionbar[key].buttons, buttonsPerRow = P.actionbar[key].buttons,
			point = 'BOTTOMLEFT', widthMult = 1, heightMult = 1,
			mouseover = false, inheritGlobalFade = false, alpha = 1, clickThrough = false,
			visibility = P.actionbar[key].visibility,
		})
	end

	-- Fuente de marcos: el default de ElvUI es 'MONOCHROMEOUTLINE' (Profile.lua:2078), que apaga
	-- el suavizado y con Expressway se ve pixelado. Se usa OUTLINE y un punto más grande.
	E.db.unitframe.fontSize = 11
	E.db.unitframe.fontOutline = 'OUTLINE'
	UnitLayout('player', 240, 54)
	UnitLayout('target', 240, 54)
	UnitLayout('focus', 115, 24, true)
	UnitLayout('pet', 115, 24, true)
	UnitLayout('targettarget', 92, 24, true)
	Set(E.db.unitframe.units.player.classbar, {
		enable = true, detachFromFrame = false, height = 4, fill = 'fill',
	})
	-- Barra de lanzamiento estilo Quartz (claves: Profile.lua:1726-1782; formatos:
	-- ElvUI_Options/Game/Shared/UnitFrames.lua:431). Ícono adentro a la izquierda,
	-- nombre a la izquierda, "actual / total" a la derecha, latencia y divisiones.
	local castFont = { enable = true, font = 'Expressway', fontSize = 14, fontStyle = 'OUTLINE' }
	local timeFont = { enable = true, font = 'Expressway', fontSize = 13, fontStyle = 'OUTLINE' }
	Set(E.db.unitframe.units.player.castbar, {
		-- 300×28 + ícono de 28 afuera a la izquierda (como Quartz). y 142-170.
		enable = true, width = 300, height = 28,
		icon = true, iconAttached = false, iconAttachedTo = 'Castbar', iconPosition = 'LEFT',
		iconSize = 28, iconXOffset = -3, iconYOffset = 0,
		insideInfoPanel = false, overlayOnFrame = 'None',
		format = 'CURRENTMAX', hideName = false, hideTime = false, nameLength = 0,
		spark = true, ticks = true, tickWidth = 1, latency = true,
		customTextFont = castFont, customTimeFont = timeFont,
		xOffsetText = 4, xOffsetTime = -4,
	})
	-- Objetivo: sobre su barra de maná, sin ícono, sólo nombre y tiempo restante.
	Set(E.db.unitframe.units.target.castbar, {
		enable = true, width = 240, height = 12, icon = false,
		insideInfoPanel = false, overlayOnFrame = 'Power', format = 'REMAINING',
		customTextFont = { enable = true, font = 'Expressway', fontSize = 11, fontStyle = 'OUTLINE' },
		customTimeFont = { enable = true, font = 'Expressway', fontSize = 11, fontStyle = 'OUTLINE' },
	})
	Set(E.db.unitframe.units.player.fader, {
		-- Sin desvanecer fuera de combate (pedido del user).
		enable = false, minAlpha = 0.2, maxAlpha = 1, delay = 0, smooth = 0.33,
		combat = true, casting = true, health = true, playertarget = true, hover = true,
		power = false, focus = false, unittarget = false, vehicle = true, dynamicflight = false,
	})
	for key in pairs(E.db.unitframe.units.player.fader.instanceDifficulties) do
		E.db.unitframe.units.player.fader.instanceDifficulties[key] = false
	end
	-- _ref/ElvUI/Game/Shared/Defaults/Profile.lua:1627-1663,2325;
	-- _ref/ElvUI_Options/Game/Shared/UnitFrames.lua:430.
	E.db.unitframe.units.target.smartAuraPosition = 'DISABLED'
	E.db.movers = E.db.movers or {}
	E.db.movers.ElvUF_TargetCastbarMover = nil -- Elements/CastBar.lua:300,384: usa Power.
	for _, key in ipairs({ 'buffs', 'debuffs' }) do
		Set(E.db.unitframe.units.target[key], {
			enable = true, attachTo = 'FRAME', anchorPoint = 'TOPLEFT',
			growthX = 'RIGHT', growthY = 'UP', numrows = 1, perrow = 8,
			sizeOverride = 28, spacing = 2, xOffset = 0,
			-- Beneficios y=218-246; perjuicios y=248-276, adjuntos al objetivo.
			yOffset = key == 'debuffs' and 32 or 2,
		})
	end

	-- Grupo con el mismo estilo que jugador/objetivo: nombre a la izquierda, vida a la derecha,
	-- maná fino sin texto, rol chico arriba a la derecha y sin los cuadraditos de AuraWatch.
	-- Claves: Profile.lua:1716-1724 (AuraWatch), 1864-1870 (Name), 1996-2004 (RoleIcon), 3016-3040.
	Set(E.db.unitframe.units.party, {
		enable = true, width = 200, height = 40, growthDirection = 'DOWN_RIGHT',
		verticalSpacing = 6, horizontalSpacing = 4, startFromCenter = false,
		infoPanel = { enable = false }, portrait = { enable = false },
		visibility = P.unitframe.units.party.visibility,
		name = { attachTextTo = 'Health', position = 'LEFT', xOffset = 4, yOffset = 0, text_format = '[classcolor][name:medium]' },
		health = { attachTextTo = 'Health', position = 'RIGHT', xOffset = -4, yOffset = 0, text_format = '[perhp<%]' },
		power = { enable = true, height = 6, width = 'fill', detachFromFrame = false, offset = 0, text_format = '' },
		roleIcon = { enable = true, position = 'TOPRIGHT', attachTo = 'Health', xOffset = -2, yOffset = -2, size = 12 },
		buffIndicator = { enable = false },
	})
	for i = 1, 3 do
		local key = 'raid'..i
		Set(E.db.unitframe.units[key], {
			enable = true, width = 80, height = 32, growthDirection = 'DOWN_RIGHT',
			groupsPerRowCol = 1, verticalSpacing = 4, horizontalSpacing = 4,
			groupSpacing = 4, startFromCenter = false, raidWideSorting = false,
			infoPanel = { enable = false }, portrait = { enable = false },
			numGroups = P.unitframe.units[key].numGroups,
			visibility = P.unitframe.units[key].visibility,
		})
	end
	-- Conserva los demás textos y quita únicamente las etiquetas de absorción de S&L.
	local function CleanText(text)
		if text and type(text.text_format) == 'string' then
			text.text_format = text.text_format:gsub('%[[^%]]*absorbs:sl%-[^%]]*%]', '')
		end
	end
	for _, unit in pairs(E.db.unitframe.units) do
		CleanText(unit.name)
		CleanText(unit.health)
		CleanText(unit.power)
		for _, text in pairs(unit.customTexts or {}) do CleanText(text) end
	end
	E.db.general.minimap.size = 176
	for _, key in ipairs({ 'buffs', 'debuffs' }) do
		Set(E.db.auras[key], {
			size = 36, height = 36, keepSizeRatio = true, growthDirection = 'LEFT_DOWN',
			wrapAfter = 12, maxWraps = key == 'buffs' and 3 or 1,
			horizontalSpacing = 4, verticalSpacing = 10,
		})
	end
	E.db.movers = E.db.movers or {}
	for name, position in pairs(movers) do
		if name ~= 'LeftChatMover' and name ~= 'RightChatMover' and name ~= 'DTPanelKnuUI_DataMover' then
			E.db.movers[name] = position
		end
	end
	self:ApplyRoleOverlay() -- Roles.lua: Tank, MDPS, RDPS o Healer
	self:CleanupLegacy()
	return true
end

function K:ApplyChat()
	if not self:CanApply() then return false end
	-- Panel: Defaults/Global.lua; Modules/DataTexts/DataTexts.lua:448.
	-- Registros: Modules/DataTexts/{Durability,Gold,Bags,Friends,Guild,System,Strength,Crit,Time,Coordinates}.lua.
	Set(E.db.chat, {
		panelWidth = 400, panelHeight = 180, separateSizes = false,
		panelWidthRight = 400, panelHeightRight = 180,
		-- Abajo del chat queda fuera de la pantalla (el chat está a 4 px del borde).
		editBoxPosition = 'ABOVE_CHAT',
	})
	E.db.datatexts.panels.LeftChatDataPanel.enable = false
	E.db.datatexts.panels.RightChatDataPanel.enable = false
	local darth = E.db.datatexts.panels.Darth_Panel_1
	if darth then darth.enable = false end

	-- DataTexts.lua completa los campos restantes desde G.datatexts.newPanelInfo.
	E.global.datatexts.customPanels.KnuUI_Data = E.global.datatexts.customPanels.KnuUI_Data or {}
	Set(E.global.datatexts.customPanels.KnuUI_Data, {
		width = 1100, height = 22, numPoints = 8, growth = 'HORIZONTAL',
		backdrop = true, border = true, panelTransparency = false, mouseover = false,
	})
	E.db.datatexts.panels.KnuUI_Data = E.db.datatexts.panels.KnuUI_Data or {}
	Set(E.db.datatexts.panels.KnuUI_Data, {
		enable = true, battleground = false,
		-- Fuerza y Crítico: 'Primary Stat' mostraba Intelecto sin especialización.
		'Durability', 'Gold', 'Bags', 'Friends', 'Guild', 'System', K:PrimaryStatText(), 'Crit',
	})

	Set(E.db.datatexts.panels.MinimapPanel, {
		enable = true, battleground = false, numPoints = 2, 'Time', 'Coords',
	})

	E.db.movers = E.db.movers or {}
	for _, name in ipairs({ 'LeftChatMover', 'RightChatMover', 'DTPanelKnuUI_DataMover' }) do
		E.db.movers[name] = movers[name]
	end
	self:CleanupLegacy()
	self:ApplyIntegratedPanels()
	return true
end
