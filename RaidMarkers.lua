local E, _, _, P = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Barra de marcas: 8 marcas + borrar, ready check y pull de 10 s. Implementación propia de KnuUI.
-- Las marcas usan botones seguros con las acciones de Blizzard 'raidtarget' y 'worldmarker'
-- (Blizzard_FrameXML/SecureTemplates.lua:585-624): el clic corre código de Blizzard sin
-- contaminar, por eso funciona en Forever donde una macro con GetRaidTargetIndex falla
-- (valor secreto). Clic izquierdo: marca al objetivo; clic derecho: marca de suelo.
-- Orden de las marcas de suelo respecto de los íconos: ElvUI Modules/Misc/RaidUtility.lua:329.
P.KnuUIRaidMarkers = 'group' -- 'group' (sólo en grupo), 'always' o 'off'

local ICONS = [[Interface\TargetingFrame\UI-RaidTargetingIcons]]
local WORLD = { 5, 6, 3, 2, 7, 1, 4, 8 }
local SIZE, GAP = 20, 3 -- 20 + 2·3 = 26, el ancho del lanzador K
local bar

local function Tooltip(button, title, line)
	button:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_BOTTOM')
		GameTooltip:AddLine(title)
		if line then GameTooltip:AddLine(line, 1, 1, 1, true) end
		GameTooltip:Show()
	end)
	button:SetScript('OnLeave', function() GameTooltip:Hide() end)
end

local function Highlight(button)
	local hl = button:CreateTexture(nil, 'HIGHLIGHT')
	hl:SetAllPoints()
	button.hl = hl
end

-- Se arma en una local y recién al final pasa a `bar`: si algo falla a mitad, el próximo intento
-- vuelve a crearla en vez de quedarse con una barra incompleta.
local function Create()
	if _G.KnuUI_RaidMarkers then _G.KnuUI_RaidMarkers:Hide() end -- resto de un intento fallido
	local bar = CreateFrame('Frame', 'KnuUI_RaidMarkers', E.UIParent, 'SecureHandlerStateTemplate')
	bar:SetTemplate('Transparent')
	if K.KnuFrame then K:KnuFrame(bar) end
	bar:SetFrameStrata('MEDIUM')
	bar.buttons = {}
	-- Vertical: arriba al centro se encimaba con la flecha de TomTom.
	local y = GAP
	local function Place(button)
		button:SetSize(SIZE, SIZE)
		button:SetPoint('TOP', bar, 'TOP', 0, -y)
		y = y + SIZE + GAP
		Highlight(button)
		if K.Hoverable then K:Hoverable(button) end
		bar.buttons[#bar.buttons + 1] = button
	end

	for i = 8, 0, -1 do
		local button = CreateFrame('Button', 'KnuUI_RaidMarker'..i, bar, 'SecureActionButtonTemplate')
		E:RegisterClicks(button)
		button:SetAttribute('type1', 'raidtarget')
		button:SetAttribute('type2', 'worldmarker')
		local icon = button:CreateTexture(nil, 'ARTWORK')
		icon:SetPoint('TOPLEFT', 2, -2)
		icon:SetPoint('BOTTOMRIGHT', -2, 2)
		if i > 0 then
			button:SetAttribute('action1', 'toggle')
			button:SetAttribute('marker1', i)
			button:SetAttribute('action2', 'toggle')
			button:SetAttribute('marker2', WORLD[i])
			local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
			icon:SetTexture(ICONS)
			icon:SetTexCoord(col * 0.25, col * 0.25 + 0.25, row * 0.25, row * 0.25 + 0.25)
			Tooltip(button, _G['RAID_TARGET_'..i] or tostring(i), L["Left click: mark your target. Right click: place or remove the ground marker."])
		else
			-- Sin marcador: 'clear' quita la marca del objetivo; ClearRaidMarker(nil) borra todas las de suelo.
			button:SetAttribute('action1', 'clear')
			button:SetAttribute('action2', 'clear')
			icon:SetTexture([[Interface\Buttons\UI-GroupLoot-Pass-Up]])
			Tooltip(button, L["Clear markers"], L["Left click: clear your target's marker. Right click: clear all ground markers."])
		end
		Place(button)
	end

	-- Ready check y pull: llamadas comunes de la API (ElvUI hace lo mismo en RaidUtility.lua:532,548).
	local function Action(text, title, line, func)
		local button = CreateFrame('Button', nil, bar)
		button.text = button:CreateFontString(nil, 'OVERLAY')
		button.text:SetPoint('CENTER')
		-- La fuente antes del texto: sin ella SetText falla ("Font not set").
		button.text:FontTemplate('Expressway', 11, 'OUTLINE')
		button.text:SetText(text)
		button:SetScript('OnClick', func)
		Tooltip(button, title, line)
		Place(button)
		return button
	end
	bar.ready = Action('RC', L["Ready check"], nil, function()
		if C_PartyInfo and C_PartyInfo.DoReadyCheck then C_PartyInfo.DoReadyCheck() end
	end)
	bar.pull = Action('10', L["Pull timer"], L["Starts a 10 second countdown for the group."], function()
		if C_PartyInfo and C_PartyInfo.DoCountdown then C_PartyInfo.DoCountdown(10) end
	end)

	bar:SetSize(SIZE + GAP * 2, y)
	-- Centrada debajo del lanzador K (Buttons.lua, 26 px de ancho = el de la barra) para quedar alineadas;
	-- sin lanzador, a la derecha debajo del minimapa.
	if K.buttons then
		bar:SetPoint('TOP', K.buttons, 'BOTTOM', 0, -4)
	else
		bar:SetPoint('TOPRIGHT', E.UIParent, 'TOPRIGHT', -4, -280)
	end
	E:CreateMover(bar, 'KnuUI_RaidMarkersMover', L["KnuUI: raid markers"], nil, nil, nil, 'ALL,PARTY,RAID', nil, 'KnuUI')
	return bar
end

function K:StyleRaidMarkers()
	if not bar or InCombatLockdown() then return end
	local t = self:GetTheme()
	bar:SetBackdropColor(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, t.backdropFade.a)
	bar:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
	for _, button in ipairs(bar.buttons) do
		button.hl:SetColorTexture(t.accent.r, t.accent.g, t.accent.b, 0.25)
		if button.text then
			K:SkinFont(button.text)
			button.text:SetTextColor(t.accent.r, t.accent.g, t.accent.b)
		end
	end
end

-- La visibilidad va por un driver seguro, así se oculta o aparece también en combate.
function K:UpdateRaidMarkers()
	if InCombatLockdown() then return false end
	local mode = E.db.KnuUIRaidMarkers or 'group'
	if mode == 'off' and not bar then return true end
	if not bar then bar = Create() end
	UnregisterStateDriver(bar, 'visibility')
	if mode == 'off' then
		bar:Hide()
	elseif mode == 'always' then
		bar:Show()
	else
		RegisterStateDriver(bar, 'visibility', '[group] show; hide')
	end
	self:StyleRaidMarkers()
	return true
end

function K:SetupRaidMarkers()
	pcall(self.UpdateRaidMarkers, self)
end
