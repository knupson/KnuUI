local E, _, _, P = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Perfiles por rol: Tank, MDPS, RDPS y Healer. Se aplican encima del diseño base (boceto v4)
-- y del modo columnas, así que cambiar de rol no pisa el resto del perfil.
-- Referencias consultadas (2026-11-08):
--   Eltruism (eltreum0/eltruism, Layouts/LayoutHealer.lua:296-349): en Healer el grupo y la banda
--   van abajo al centro (party 150×60 RIGHT_UP, healPrediction y buffIndicator activos); en DPS/Tank
--   quedan arriba a la izquierda.
--   LuckyoneUI (Luckyone961/LuckyoneUI, Profiles/ElvUI/ElvUI.lua:1650-1782): mismo criterio; en
--   Healing la banda se agranda y va al centro, y activa la predicción de curación.
-- Ninguna de las dos separa MDPS de RDPS: esa diferencia (barra de lanzamiento y perjuicios del
-- objetivo más grandes para RDPS) es propia de KnuUI.
-- Claves verificadas en _ref/ElvUI/Game/Shared/Defaults/Profile.lua:1821 (UF_HealthPrediction),
-- 3016-3110 (party/raid1) y 873-883 (threat de placas); threatStyle: ElvUI_Options UnitFrames.lua:29.

K.roles = { 'tank', 'mdps', 'rdps', 'healer' }
K.roleNames = { tank = 'Tank', mdps = 'MDPS', rdps = 'RDPS', healer = 'Healer' }

local GROUPS = { 'party', 'raid1', 'raid2', 'raid3' }

local function Defaults(unit, key)
	return P.unitframe.units[unit] and P.unitframe.units[unit][key]
end

-- Deja grupo, banda, amenaza y barra de lanzamiento como los deja el diseño base.
local function Reset(Set, units)
	for _, unit in ipairs(GROUPS) do
		local db = units[unit]
		if db then
			Set(db, { threatStyle = 'GLOW' })
			if db.healPrediction then db.healPrediction.enable = false end
			if db.buffIndicator then
				-- El diseño base apaga los cuadraditos del grupo; la banda conserva el valor de ElvUI.
				local default = Defaults(unit, 'buffIndicator')
				db.buffIndicator.enable = unit ~= 'party' and default and default.enable or false
			end
		end
	end
	local partyDebuffs, def = units.party.debuffs, Defaults('party', 'debuffs')
	if partyDebuffs and def then
		Set(partyDebuffs, {
			enable = def.enable, sizeOverride = def.sizeOverride,
			perrow = def.perrow, anchorPoint = def.anchorPoint,
		})
	end
	Set(units.player, { threatStyle = 'GLOW' })
	if E.db.nameplates and E.db.nameplates.threat then E.db.nameplates.threat.indicator = false end
end

local function Tank(Set, units)
	-- Amenaza bien visible: borde de color en jugador, grupo y banda, e ícono en las placas.
	Set(units.player, { threatStyle = 'BORDERS' })
	for _, unit in ipairs(GROUPS) do
		if units[unit] then Set(units[unit], { threatStyle = 'BORDERS' }) end
	end
	if E.db.nameplates and E.db.nameplates.threat then E.db.nameplates.threat.indicator = true end
end

local function Rdps(Set, units)
	-- Barra de lanzamiento más grande (340×32, ícono de 32) y perjuicios del objetivo de 32.
	-- Normal: y 142-174 (barra de mascota en 174). Columnas: y 146-178 (mascota en 178).
	Set(units.player.castbar, { width = 340, height = 32, iconSize = 32 })
	Set(units.target.debuffs, { sizeOverride = 32 })
end

local function Healer(Set, units)
	-- Grupo y banda al centro, encima de las barras centrales (como Eltruism y LuckyoneUI).
	-- Normal: el bloque ocupa x 747-1173, entre el jugador (505-745) y las auras del objetivo
	-- (desde 1175), desde y 204 (la barra de mascota termina en 198).
	-- Columnas: el objetivo centrado y sus auras llegan a y 330, así que arranca en 340.
	local y = E.db.KnuUITanks and 340 or 204
	local text = {
		name = { attachTextTo = 'Health', position = 'TOP', xOffset = 0, yOffset = -4, text_format = '[classcolor][name:short]' },
		health = { attachTextTo = 'Health', position = 'BOTTOM', xOffset = 0, yOffset = 4, text_format = '[perhp<%]' },
	}
	-- 5 × 82 + 4 × 4 = 426 px de ancho.
	Set(units.party, {
		width = 82, height = 46, growthDirection = 'RIGHT_UP',
		horizontalSpacing = 4, verticalSpacing = 4,
		name = text.name, health = text.health,
		healPrediction = { enable = true },
		buffIndicator = { enable = true },
		debuffs = { enable = true, sizeOverride = 20, perrow = 4, anchorPoint = 'TOP' },
	})
	-- Banda: 5 por fila de 80 + 4 de separación = 416 px; los grupos crecen hacia arriba.
	for i = 1, 3 do
		local key = 'raid'..i
		Set(units[key], {
			width = 80, height = i == 3 and 28 or 36, growthDirection = 'RIGHT_UP',
			groupsPerRowCol = 1, horizontalSpacing = 4, verticalSpacing = 4, groupSpacing = 4,
			name = text.name, health = text.health,
			healPrediction = { enable = true },
			buffIndicator = { enable = true },
		})
	end
	local position = 'BOTTOM,ElvUIParent,BOTTOM,0,'..y
	for _, mover in ipairs({ 'ElvUF_PartyMover', 'ElvUF_Raid1Mover', 'ElvUF_Raid2Mover', 'ElvUF_Raid3Mover' }) do
		E.db.movers[mover] = position
	end
end

local apply = { tank = Tank, rdps = Rdps, healer = Healer }

-- Lo llaman ApplyLayout y ApplyTanks al final; no recarga ni toca otras secciones.
function K:ApplyRoleOverlay()
	local role = E.db.KnuUIRole or 'mdps'
	local units = E.db.unitframe.units
	E.db.movers = E.db.movers or {}
	Reset(self.Set, units)
	if apply[role] then apply[role](self.Set, units) end
end

-- Cambia de rol: vuelve a armar el diseño base (y las columnas si están activas) con el rol nuevo.
function K:ApplyRole(role)
	if not self:CanApply() or not self.roleNames[role] then return false end
	E.db.KnuUIRole = role
	E.private.KnuUIRole = role -- Extras.lua: cada personaje recuerda su rol
	self:ApplyLayout()
	if E.db.KnuUITanks then self:ApplyTanks(true) end
	return true
end

function K:RoleName()
	return self.roleNames[E.db.KnuUIRole or 'mdps']
end
