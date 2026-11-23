local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Posiciones medidas con tools/render. Las unidades usan centros desde abajo;
-- las anclas relativas conservan la separación al cambiar la resolución.
K.styles = {
	{ id = 'bruma', name = 'Bruma', category = 'Minimalista',
		movers = { x = 240, y = 290, cast = 900 }, settings = { width = 210, height = 44 } },
	{ id = 'tablero', name = 'Tablero', category = 'Utilidad',
		movers = { x = 220, y = 280, cast = 865 }, settings = { width = 240, height = 54 } },
	{ id = 'parentesis', name = 'Paréntesis', category = 'Combate',
		movers = { x = 260, y = 330, cast = 845 }, settings = { width = 220, height = 48 } },
}
local roles = { 'mdps', 'rdps', 'healer', 'tank' }

local function Style(id)
	for _, style in ipairs(K.styles) do if style.id == id then return style end end
end

function K:StyleProfiles()
	local list = {}
	for _, style in ipairs(self.styles) do
		for _, role in ipairs(roles) do
			list[#list + 1] = {
				name = 'KnuUI '..style.name..' · '..style.category..' · '..role:upper(),
				id = style.id, category = style.category, role = role,
			}
		end
	end
	return list
end

function K:PrintStyleProfiles()
	local category
	for index, profile in ipairs(self:StyleProfiles()) do
		if category ~= profile.category then category = profile.category; E:Print(category..':') end
		E:Print(format(L['%d. %s'], index, profile.name))
	end
end

function K:CreateStyleProfiles(recreate, quiet)
	if not self:CanApply() then return false end
	local profiles = ElvDB.profiles
	local current = E.data:GetCurrentProfile()
	-- Nunca se borra el perfil activo, aunque sea uno de los estilos.
	if recreate then
		for name, profile in pairs(profiles) do
			if name ~= current and name:match('^KnuUI ') and profile.KnuUIStyle then profiles[name] = nil end
		end
	end
	local count = 0
	for _, profile in ipairs(self:StyleProfiles()) do
		if not profiles[profile.name] and profile.name ~= current then
			profiles[profile.name] = {
				KnuUIStyle = profile.id, KnuUIRole = profile.role,
				KnuUITanks = false, KnuUIStylePending = true,
				-- La flecha de TomTom guarda su lugar en el perfil de TomTom, compartido con el perfil del jugador:
				-- un perfil de estilo no la mueve (Skins/TomTom.lua PlaceArrow corre una vez por perfil de ElvUI).
				KnuUITomTomPlaced = true,
			}
			count = count + 1
		end
	end
	if not quiet then
		E:Print(format(L['%d style profiles created; existing profiles were kept.'], count))
		self:PrintStyleProfiles()
	end
	return true
end

-- Instalador: crea los perfiles que falten y prueba el estilo con el rol actual del perfil.
function K:TryStyle(id)
	if not Style(id) or not self:CreateStyleProfiles(false, true) then return false end
	local role = E.db.KnuUIRole or E.private.KnuUIRole or 'mdps'
	for index, profile in ipairs(self:StyleProfiles()) do
		if profile.id == id and profile.role == role then return self:TryStyleProfile(tostring(index)) end
	end
	return false
end

function K:TryStyleProfile(value)
	if not self:CanApply() then return false end
	value = (value or ''):match('^%s*(.-)%s*$')
	local list, selected = self:StyleProfiles()
	local index = tonumber(value)
	if index then selected = list[index] end
	for _, profile in ipairs(list) do if profile.name == value then selected = profile end end
	if not selected or not ElvDB.profiles[selected.name] or not ElvDB.profiles[selected.name].KnuUIStyle then
		E:Print(L['Choose an existing style profile by number or full name.'])
		self:PrintStyleProfiles()
		return false
	end
	local current = E.data:GetCurrentProfile()
	if current == selected.name then return true end
	-- Se guarda sólo un perfil propio: al probar varios estilos seguidos, /knu volver sigue llevando al del jugador.
	local active = ElvDB.profiles[current]
	if not (active and active.KnuUIStyle) then E.global.KnuUIPreviousProfile = current end
	local pending = ElvDB.profiles[selected.name].KnuUIStylePending
	E.data:SetProfile(selected.name)
	-- Un perfil ya armado necesita recargar para verse entero (visto en el juego 2026-11-18: sin recargar queda
	-- mezclado). Uno pendiente pide la recarga solo al terminar de armarse.
	if not pending then E:StaticPopup_Show('CONFIG_RL') end
	return true
end

function K:ReturnStyleProfile()
	if not self:CanApply() then return false end
	local previous = E.global.KnuUIPreviousProfile
	if not previous or not ElvDB.profiles[previous] then
		E:Print(L['No previous profile is available.'])
		return false
	end
	E.data:SetProfile(previous)
	E:StaticPopup_Show('CONFIG_RL') -- sin recargar el perfil queda mezclado con el estilo (visto en el juego 2026-11-18)
	return true
end

function K:ApplyStyle(id)
	local style = Style(id)
	if not E.db.KnuUIStyle or E.db.KnuUIStyle ~= id or not style or not self:CanApply() then return false end
	local db, Set = E.db, self.Set
	local units, movers = db.unitframe.units, db.movers
	local healer = db.KnuUIRole == 'healer'
	local x, y = healer and 340 or style.movers.x, style.movers.y
	local function Place(name, anchor, relative, point, dx, dy)
		movers[name] = table.concat({ anchor, relative, point, dx, dy }, ',')
	end
	for _, unit in ipairs({ 'player', 'target' }) do
		Set(units[unit], { width = style.settings.width, height = style.settings.height,
			portrait = { enable = false }, power = { enable = true, detachFromFrame = false, height = 10 } })
	end
	Place('ElvUF_PlayerMover', 'CENTER', 'ElvUIParent', 'BOTTOM', -x, y)
	Place('ElvUF_TargetMover', 'CENTER', 'ElvUIParent', 'BOTTOM', x, y)
	Place('ElvUF_FocusMover', 'BOTTOMLEFT', 'ElvUF_Player', 'TOPLEFT', 0, 8)
	Place('ElvUF_PetMover', 'TOPLEFT', 'ElvUF_Player', 'BOTTOMLEFT', 0, -8)
	Place('ElvUF_TargetTargetMover', 'TOPRIGHT', 'ElvUF_Target', 'BOTTOMRIGHT', 0, -8)
	-- La banda del Healer queda exactamente como la dejó Roles.lua (y=204).
	if not healer then
		for i = 1, 3 do
			Set(units['raid'..i], { width = 80, height = 24, growthDirection = 'RIGHT_UP',
				groupsPerRowCol = 1, horizontalSpacing = 4, verticalSpacing = 4, groupSpacing = 4 })
			Place('ElvUF_Raid'..i..'Mover', 'BOTTOMLEFT', 'ElvUIParent', 'BOTTOMLEFT', 4, 218)
		end
		-- Encima del chat izquierdo en los tres estilos: a la derecha de la guía (x 320) quedaba flotando en el medio
		-- de la vista (visto en el juego 2026-11-18, descartado por el jugador).
		Place('ElvUF_PartyMover', 'BOTTOMLEFT', 'ElvUIParent', 'BOTTOMLEFT', 4, 246)
	end
	for i = 1, 2 do
		Set(db.actionbar['bar'..i], { buttonSize = 28, buttonHeight = 28, buttonSpacing = 2, buttonsPerRow = 12 })
		Place('ElvAB_'..i, 'BOTTOM', 'ElvUIParent', 'BOTTOM', 0, i == 1 and 60 or 28)
	end
	for i = 3, 4 do
		db.actionbar['bar'..i].enabled = id ~= 'bruma'
		if id == 'parentesis' then
			Set(db.actionbar['bar'..i], { buttonSize = 24, buttonHeight = 24, buttonsPerRow = 12 })
			Place('ElvAB_'..i, 'BOTTOM', 'ElvUIParent', 'BOTTOM', i == 3 and -340 or 340, 104)
		end
	end
	local cast = healer and 900 or style.movers.cast
	-- RDPS conserva los 340×32 del overlay; los demás usan una barra fina.
	if db.KnuUIRole ~= 'rdps' then Set(units.player.castbar, { width = 300, height = 24, iconSize = 24 }) end
	units.player.castbar.enable = true
	Place('ElvUF_PlayerCastbarMover', 'TOP', 'ElvUIParent', 'BOTTOM', 0, 1080 - cast)
	Place('PetAB', 'TOP', 'ElvUIParent', 'BOTTOM', 0, 140)
	Place('ShiftAB', 'TOP', 'ElvUIParent', 'BOTTOM', 0, 112)
	Place('ExperienceBarMover', 'TOP', 'ElvUIParent', 'BOTTOM', 0, 146)
	Set(db.databars.experience, { width = 358, height = 4 })
	Set(db.actionbar.stanceBar, { buttonSize = 20, buttonHeight = 20 })
	if id ~= 'tablero' then
		Set(db.auras.debuffs, { size = id == 'bruma' and 32 or 36, wrapAfter = 6, maxWraps = 2 })
		Place('DebuffsMover', 'TOPLEFT', 'ElvUF_Player', 'TOPLEFT', 0, 120)
	end
	-- Toda la pila (cinco tiradas de 32+4) queda arriba de las barras laterales.
	Place('AlertFrameMover', 'TOPRIGHT', 'ElvUIParent', 'BOTTOMRIGHT', -120, 470)
	Place('SocialMenuMover', 'TOPLEFT', 'ElvUIParent', 'TOPLEFT', 320, -187)
	Place('BNETMover', 'BOTTOMLEFT', 'ElvUIParent', 'BOTTOMLEFT', 430, 160)
	for _, unit in ipairs({ 'arena', 'boss' }) do
		Set(units[unit], { width = 180, height = 40, spacing = 6, growthDirection = 'DOWN',
			infoPanel = { enable = false }, portrait = { enable = false } })
		Place(unit == 'arena' and 'ArenaHeaderMover' or 'BossHeaderMover', 'TOPLEFT', 'ElvUIParent', 'BOTTOM', 385, 710)
	end
	Place('BossButton', 'BOTTOMLEFT', 'ElvUIParent', 'BOTTOMLEFT', 430, 220)
	Place('ZoneAbility', 'BOTTOMRIGHT', 'ElvUIParent', 'BOTTOMRIGHT', -430, 220)
	-- Utilidades fuera de la grilla central del Healer.
	for index, name in ipairs({ 'AltPowerBarMover', 'TotemBarMover', 'ThreatBarMover', 'RaidMarkerBarAnchor',
		'TotemTrackerMover', 'VehicleLeaveButton' }) do
		Place(name, 'TOP', 'ElvUIParent', 'TOP', 0, -350 - index * 30)
	end
	Place('ElvUF_FocusCastbarMover', 'TOP', 'ElvUIParent', 'TOP', -340, -360)
	-- Extras no debe reinstalar los movers base después de esta recarga.
	db.KnuUIBlizzardPlaced = true
	db.KnuUITomTomPlaced = true -- la flecha de TomTom es de TomTom, compartida con el perfil del jugador
	return true
end

function K:ApplyPendingStyle()
	local id = E.db.KnuUIStyle
	if not id or not E.db.KnuUIStylePending or not Style(id) then return false end
	-- En combate se espera al final sin cortar la carga del resto de KnuUI (Core.lua sigue con los demás módulos).
	if InCombatLockdown() then
		if self.styleEvents then self.styleEvents:RegisterEvent('PLAYER_REGEN_ENABLED') end
		return false
	end
	if not self:CanApply() then return false end
	if self.styleApplying then return true end
	self.styleApplying = true
	E.db.KnuUITanks = false
	self:ApplyLayout()
	self:ApplyChat()
	self:ApplyNameplates()
	self:ApplyTracker()
	self:ApplyTheme()
	self:ApplyBase()
	self:ApplyRoleOverlay()
	self:ApplyStyle(id)
	E.db.KnuUILayoutVersion = self.version
	E.db.KnuUIStylePending = nil
	self.styleApplying = nil
	-- ReloadUI sólo funciona desde un clic (probado en el juego 2026-11-18: ADDON_ACTION_BLOCKED 'Reload()' desde
	-- C_Timer). La ventana de ElvUI recarga con Aceptar (General/StaticPopups.lua:189-193).
	E:StaticPopup_Show('CONFIG_RL')
	return true
end

function K:StyleProfileChanged()
	-- Los callbacks de AceDB no garantizan orden. Esperar un cuadro deja que
	-- UpdateAll actualice E.db; al ejecutar se vuelve a verificar el perfil activo.
	C_Timer.After(0, function() K:ApplyPendingStyle() end)
end

function K:SetupStyles()
	if not self.styleEvents then
		self.styleEvents = CreateFrame('Frame')
		self.styleEvents:SetScript('OnEvent', function(frame)
			if not InCombatLockdown() then frame:UnregisterAllEvents(); K:ApplyPendingStyle() end
		end)
		if E.data and E.data.RegisterCallback then E.data.RegisterCallback(self, 'OnProfileChanged', 'StyleProfileChanged') end
	end
	return self:ApplyPendingStyle()
end
