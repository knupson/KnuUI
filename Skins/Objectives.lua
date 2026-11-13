local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- Rastreador de misiones de Blizzard con estética KnuUI.
-- ElvUI ya lo skinea y le da mover/alto (Skins/ObjectiveTracker.lua:9-19,111-140;
-- Modules/Blizzard/ObjectiveFrame.lua:135,154). Acá sólo se cambian letra, colores y fondo,
-- con los mismos ganchos que usa ElvUI (tracker:AddBlock y header.Text).

local FONT = 'Expressway'
local TRACKERS = {
	'ScenarioObjectiveTracker', 'UIWidgetObjectiveTracker', 'CampaignQuestObjectiveTracker',
	'QuestObjectiveTracker', 'AdventureObjectiveTracker', 'AchievementObjectiveTracker',
	'MonthlyActivitiesObjectiveTracker', 'ProfessionsRecipeTracker', 'BonusObjectiveTracker',
	'WorldQuestObjectiveTracker', 'InitiativeTasksObjectiveTracker',
}
local hooked

local function SetFont(text, size)
	if text and text.FontTemplate then pcall(text.FontTemplate, text, FONT, size, 'OUTLINE') end
end

local function StyleHeader(header)
	if not header or not header.Text then return end
	local t = K:GetTheme()
	SetFont(header.Text, 13)
	header.Text:SetTextColor(t.accent.r, t.accent.g, t.accent.b)
end

local function StyleBlock(_, block)
	if not block or not E.db.KnuUISkinTracker then return end
	SetFont(block.HeaderText, 12)
	-- Las líneas viven en block.usedLines (campo de Blizzard); si no existe, no se toca nada.
	if type(block.usedLines) == 'table' then
		for _, line in pairs(block.usedLines) do
			if type(line) == 'table' then SetFont(line.Text, 11) end
		end
	end
end

local function Style()
	local frame = _G.ObjectiveTrackerFrame
	if not frame then return end
	local t = K:GetTheme()

	-- Con WoW-Pro cargado se oculta por defecto (pedido del user): en Forever Blizzard lo estira hasta
	-- abajo de la pantalla en su posición por defecto (Blizzard_ObjectiveTrackerContainer.lua:189-210)
	-- y tapaba a Details. Queda transparente y sin mouse. NUNCA se llama a SetCollapsed ni al botón
	-- desde acá: SetCollapsed escribe self.isCollapsed y corre Update() (Blizzard_ObjectiveTrackerContainer.lua:177-183);
	-- hecho desde un addon contamina el rastreador y ShouldShowMawBuffs falla al leer auras secretas
	-- (Blizzard_MawBuffs.lua:4), también dentro del Modo edición.
	if E.db.KnuUIHideTracker == nil then E.db.KnuUIHideTracker = true end
	-- Pedido del user (2026-11-13): "Todos los objetivos" no tiene que existir en ningún modo, con o sin
	-- WoW-Pro u Offhand. Se sostiene en 0: DynamicCam (LibHideUI) le devolvía la opacidad al terminar un
	-- fundido de la interfaz (visto en el juego). Sólo SetAlpha/EnableMouse, nunca Hide ni SetCollapsed.
	if E.db.KnuUIHideTracker then
		if not frame.KnuAlphaHooked then
			frame.KnuAlphaHooked = true
			local busy
			hooksecurefunc(frame, 'SetAlpha', function(self, a)
				if busy or not E.db.KnuUIHideTracker or a == 0 then return end
				busy = true
				self:SetAlpha(0)
				busy = false
			end)
		end
		frame:SetAlpha(0)
		frame:EnableMouse(false)
		local mini = frame.Header and frame.Header.MinimizeButton
		if mini then mini:EnableMouse(false) end
		return
	end
	frame:SetAlpha(1)
	frame:EnableMouse(true) -- por si antes se ocultó con WoW-Pro
	local mini = frame.Header and frame.Header.MinimizeButton
	if mini then mini:EnableMouse(true) end

	if not frame.KnuBackdrop then
		-- Fondo que abarca sólo el contenido visible (no todo el alto reservado del marco),
		-- con margen izquierdo para que entren los íconos de misión que Blizzard dibuja afuera.
		local bg = CreateFrame('Frame', nil, frame)
		bg:SetFrameLevel(math.max(frame:GetFrameLevel() - 1, 0))
		bg:SetTemplate('Transparent')
		frame.KnuBackdrop = bg
		local function Fit()
			local top = frame:GetTop()
			if not top then return end
			local bottom = frame.Header and frame.Header:GetBottom() or top
			if not frame.isCollapsed then
				for _, name in ipairs(TRACKERS) do
					local tracker = _G[name]
					if tracker and tracker:IsShown() and tracker:GetBottom() and tracker:GetHeight() > 1 then
						bottom = math.min(bottom, tracker:GetBottom())
					end
				end
			end
			bg:ClearAllPoints()
			bg:SetPoint('TOPLEFT', frame, 'TOPLEFT', -34, 6)
			local mini = frame.Header and frame.Header.MinimizeButton
			-- Borde derecho a 8 px de la pantalla, como el minimapa (Layout.lua: MinimapMover TOPRIGHT -8).
			bg:SetPoint('RIGHT', E.UIParent, 'RIGHT', -8, 0)
			bg:SetHeight(math.max(top - bottom + 12, 24))
		end
		Fit()
		C_Timer.NewTicker(1, function() pcall(Fit) end) -- liviano: sólo geometría
	end
	frame.KnuBackdrop:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
	-- El rastreador expandido nunca tapa el tooltip: el rastreador va en MEDIUM y el tooltip
	-- en TOOLTIP, arriba de todo, cada vez que se muestra. Sólo fuera de combate.
	if not InCombatLockdown() and frame:GetFrameStrata() ~= 'MEDIUM' then frame:SetFrameStrata('MEDIUM') end
	local tip = _G.GameTooltip
	if tip and not K.tooltipOnTop then
		K.tooltipOnTop = true
		tip:HookScript('OnShow', function(self)
			if self:GetFrameStrata() ~= 'TOOLTIP' then self:SetFrameStrata('TOOLTIP') end
			self:Raise()
		end)
	end

	StyleHeader(frame.Header)
	-- El botón +/- quedaba sobre el borde del fondo (medido: botón x 1900-1912, fondo hasta 1912).
	-- En Forever el rastreador lo ubica el Modo edición y KnuUI no lo mueve; se corre sólo el botón
	-- 10 px hacia adentro, una vez y fuera de combate (ElvUI sólo le cambia el tamaño: ObjectiveTracker.lua:40).
	-- Lo mismo para el botón de cada sección (Misiones, Logros...): quedaba en x 1908, sobre el borde.
	local function ShiftButton(header)
		local mini = header and header.MinimizeButton
		if mini and not mini.KnuShifted and not InCombatLockdown() then
			local point, rel, relPoint, x, y = mini:GetPoint(1)
			if point then
				mini.KnuShifted = true
				mini:ClearAllPoints()
				mini:SetPoint(point, rel, relPoint, (x or 0) - 10, y or 0)
			end
		end
	end
	ShiftButton(frame.Header)
	for _, name in ipairs(TRACKERS) do
		local tracker = _G[name]
		if tracker then ShiftButton(tracker.Header) end
	end
	-- Antes se contraía solo con button:Click(); se sacó porque el clic hecho por código corre
	-- SetCollapsed contaminado (ver arriba). Contraerlo queda en manos del jugador.
	for _, name in ipairs(TRACKERS) do
		local tracker = _G[name]
		if tracker then
			StyleHeader(tracker.Header)
			if not hooked and type(tracker.AddBlock) == 'function' then
				hooksecurefunc(tracker, 'AddBlock', StyleBlock)
			end
		end
	end
	hooked = true
end

function K:SkinTracker()
	if E.db.KnuUISkinTracker == nil then E.db.KnuUISkinTracker = true end
	if not E.db.KnuUISkinTracker then return end
	pcall(Style)
end

-- Posición y alto (opciones nativas de ElvUI): bajo la botonera del minimapa, 420 de alto.
function K:ApplyTracker(hideWithWoWPro)
	if not self:CanApply() then return false end
	E.db.KnuUISkinTracker = true
	if hideWithWoWPro ~= nil then E.db.KnuUIHideTracker = hideWithWoWPro end
	E.db.general.objectiveFrameHeight = 420 -- Profile.lua:55
	-- Separado del borde (40 px, deja lugar a los íconos que salen a la izquierda del fondo)
	-- y debajo de la botonera del minimapa; con 420 de alto termina lejos de Details (y=184).
	-- Posición: en Forever ElvUI usa ObjectiveTracker_SetupModern (Modules/Blizzard/ObjectiveFrame.lua:140-147),
	-- que no crea ObjectiveFrameMover; el rastreador lo ubica el Modo edición de Blizzard. KnuUI no lo
	-- mueve por código (tocar un sistema del Modo edición desde un addon puede contaminarlo).
	-- El "8" junto al minimapa es el compartimento de addons de Blizzard: se oculta (Profile.lua:302-304).
	if E.db.general.addonCompartment then E.db.general.addonCompartment.hide = true end
	return true
end

function K:SetupTracker()
	local f = CreateFrame('Frame')
	f:RegisterEvent('PLAYER_ENTERING_WORLD')
	f:RegisterEvent('ADDON_LOADED')
	f:SetScript('OnEvent', function(_, event, name)
		if event == 'ADDON_LOADED' and name ~= 'Blizzard_ObjectiveTracker' then return end
		C_Timer.After(1, function() K:SkinTracker() end)
	end)
end
