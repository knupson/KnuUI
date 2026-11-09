local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- Placas de nombre KnuUI con el módulo nativo de ElvUI (sin Plater ni otros addons).
-- Ideas de la comunidad (Plater, Platynator, Kui, perfiles ElvUI de ToxiUI/Luckyone) llevadas a
-- claves existentes en _ref/ElvUI/Game/Shared/Defaults/Profile.lua (P.nameplates, ~657-1345).
-- Opciones de glowStyle: _ref/ElvUI_Options/Game/Shared/Nameplates.lua:717.
-- Tamaños: decisión de diseño para 1920×1080, a ajustar en el juego.

local function Enemy(t)
	return {
		health = {
			width = 120, height = 11, useClassColor = true,
			useClassificationColor = true, useClassificationColorInInstance = true,
			text = { enable = true, format = '[perhp]', position = 'CENTER', fontSize = 10 },
		},
		name = { enable = true, position = 'TOPLEFT', fontSize = 10 },
		level = { enable = true, fontSize = 10 },
		castbar = {
			enable = true, width = 120, height = 10, yOffset = -12,
			showIcon = true, iconPosition = 'LEFT', iconSize = 22, textPosition = 'BELOW',
			hideTime = false, displayTarget = true, sourceInterrupt = true, fontSize = 10,
		},
		raidTargetIndicator = { enable = true, size = 20, position = 'LEFT' },
		-- Sólo los debuffs propios: group1 ya es HARMFUL||PLAYER (Profile.lua:1279-1282).
		debuffs = {
			enable = true, numAuras = 5, size = 20, keepSizeRatio = true, spacing = 1,
			anchorPoint = 'TOPRIGHT', growthX = 'LEFT', growthY = 'UP', yOffset = 20,
			filterLists = { group1 = { enable = true }, group2 = { enable = false } },
		},
		buffs = { enable = true, numAuras = 3, size = 20 },
		auras = { enable = true, numAuras = 2, size = 20 },
	}
end

function K:ApplyNameplates()
	if not self:CanApply() then return false end
	local db = E.db.nameplates
	if not db then return false end
	local t = self:GetTheme()

	self.Set(db, {
		thinBorders = true, highlight = true,
		overlapH = 0.8, overlapV = 1.0,
		clickSize = { enemyWidth = 120, enemyHeight = 30, friendlyWidth = 120, friendlyHeight = 30 },
		classColorNames = true,
		threat = {
			enable = true, useThreatColor = true, useThreatClassification = true,
			beingTankedByTank = true, beingTankedByPet = true,
			goodScale = 1, badScale = 1, indicator = false, useSoloColor = false,
		},
		colors = {
			glowColor = { r = t.accent.r, g = t.accent.g, b = t.accent.b, a = 1 },
			castColor = { r = t.cast.r, g = t.cast.g, b = t.cast.b, a = 0.95 },
			castbarDesaturate = true, auraByType = true,
		},
	})
	local units = db.units
	if units.TARGET then
		self.Set(units.TARGET, { glowStyle = 'style6', arrow = 'Arrow9', arrowScale = 0.8, arrowSpacing = 3 })
	end
	if units.ENEMY_NPC then
		self.Set(units.ENEMY_NPC, Enemy())
		-- Ícono de misión sólo existe para NPCs (Plugins.lua:43).
		self.Set(units.ENEMY_NPC, { questIcon = { enable = true, position = 'RIGHT', size = 16, fontSize = 11 } })
	end
	if units.ENEMY_PLAYER then self.Set(units.ENEMY_PLAYER, Enemy()) end
	if units.FRIENDLY_PLAYER then
		self.Set(units.FRIENDLY_PLAYER, { nameOnly = true, health = { useClassColor = true } })
	end
	return true
end
