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

	if E.db.KnuUIHideTracker and K:IsLoaded('WoWPro') then
		frame:SetAlpha(0)
		frame:EnableMouse(false)
		return
	end
	frame:SetAlpha(1)
	frame:EnableMouse(true) -- por si antes se ocultó con WoW-Pro

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
			if mini then bg:SetPoint('RIGHT', mini, 'RIGHT', 6, 0) else bg:SetPoint('RIGHT', E.UIParent, 'RIGHT', -8, 0) end
			bg:SetHeight(math.max(top - bottom + 12, 24))
		end
		Fit()
		C_Timer.NewTicker(1, function() pcall(Fit) end) -- liviano: sólo geometría
	end
	frame.KnuBackdrop:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)

	StyleHeader(frame.Header)
	-- Contraído por defecto (pedido del user): una vez por sesión, con el mismo botón que usa
	-- el jugador (ElvUI lo skinea en Skins/ObjectiveTracker.lua:24-51,115-117).
	if not K.trackerCollapsedOnce and not InCombatLockdown() then
		K.trackerCollapsedOnce = true
		local button = frame.Header and frame.Header.MinimizeButton
		if E.db.KnuUITrackerCollapsed ~= false and not frame.isCollapsed and button and button.Click then
			pcall(button.Click, button)
		end
	end
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
	E.db.movers.ObjectiveFrameMover = 'TOPRIGHT,ElvUIParent,TOPRIGHT,-22,-266' -- con el +/- adentro, termina a ~8 px del borde
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
