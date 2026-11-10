local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Temporizador de vuelos, implementación propia de KnuUI. Aprende cuánto dura cada ruta la primera
-- vez que la volás y después muestra una barra con la cuenta regresiva y el tiempo en el tooltip.
-- En Forever las dos ventanas de vuelo (mapa de vuelo moderno y TaxiFrame clásico) terminan en
-- TakeTaxiNode (rama forever: Blizzard_FlightMap/FM_FlightPathDataProvider.lua:236,
-- Blizzard_UIPanels_Game/Shared/TaxiFrame.lua). Tiempos en E.global.KnuUIFlights["origen>destino"].
local START_WAIT, MIN_FLIGHT = 6, 5
local bar, flight

local function Times()
	E.global.KnuUIFlights = E.global.KnuUIFlights or {}
	return E.global.KnuUIFlights
end

local function CurrentNode()
	for i = 1, (NumTaxiNodes and NumTaxiNodes() or 0) do
		if TaxiNodeGetType(i) == 'CURRENT' then return TaxiNodeName(i) end
	end
end

local function Key(from, to) return from and to and (from..'>'..to) end

local function Clock(seconds)
	seconds = math.max(0, math.floor(seconds + 0.5))
	return format('%d:%02d', math.floor(seconds / 60), seconds % 60)
end

local function Place(name) return (name or ''):match('^([^,]+)') or name end

local function CreateBar()
	bar = CreateFrame('StatusBar', 'KnuUI_FlightTimer', E.UIParent)
	bar:SetSize(240, 18)
	bar:SetPoint('TOP', E.UIParent, 'TOP', 0, -40)
	bar:SetStatusBarTexture(E.Libs.LSM:Fetch('statusbar', 'Melli'))
	bar:CreateBackdrop('Transparent')
	if K.KnuFrame and bar.backdrop then K:KnuFrame(bar.backdrop) end
	bar.text = bar:CreateFontString(nil, 'OVERLAY')
	bar.text:SetPoint('LEFT', 6, 0)
	bar.text:SetPoint('RIGHT', -44, 0)
	bar.text:SetJustifyH('LEFT')
	bar.time = bar:CreateFontString(nil, 'OVERLAY')
	bar.time:SetPoint('RIGHT', -6, 0)
	for _, text in ipairs({ bar.text, bar.time }) do text:FontTemplate('Expressway', 12, 'OUTLINE') end
	bar:Hide()
	E:CreateMover(bar, 'KnuUI_FlightTimerMover', L["KnuUI: flight timer"], nil, nil, nil, 'ALL,GENERAL', nil, 'KnuUI')
end

local function Style()
	if not bar then return end
	local t = K:GetTheme()
	bar:SetStatusBarColor(t.accent.r, t.accent.g, t.accent.b)
	if bar.backdrop then bar.backdrop:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b) end
	bar.time:SetTextColor(t.text.r, t.text.g, t.text.b)
end
K.StyleFlightTimer = Style

local function Finish(landed)
	if not flight then return end
	local elapsed = GetTime() - (flight.started or GetTime())
	-- Sólo se guarda un vuelo completo: si se bajó antes (TaxiRequestEarlyLanding) no cuenta.
	if landed and flight.started and not flight.early and elapsed >= MIN_FLIGHT and flight.key then
		Times()[flight.key] = math.floor(elapsed + 0.5)
	end
	flight = nil
	if bar then
		bar:SetScript('OnUpdate', nil)
		-- Se va con fundido (Motion.lua) y recién ahí se oculta.
		if K.FadeTo then K:FadeTo(bar, 0, nil, function() if not flight then bar:Hide() end end) else bar:Hide() end
	end
end

local function OnUpdate()
	if not flight then return Finish(false) end
	local now = GetTime()
	local onTaxi = UnitOnTaxi('player')
	if not flight.started then
		if onTaxi then
			flight.started = now
		elseif now - flight.requested > START_WAIT then
			return Finish(false) -- el vuelo no arrancó
		end
		return
	end
	if not onTaxi then return Finish(true) end
	local elapsed = now - flight.started
	if flight.total then
		bar:SetValue(math.min(elapsed, flight.total))
		bar.time:SetText(Clock(flight.total - elapsed))
	else
		bar:SetValue(0)
		bar.time:SetText(Clock(elapsed))
	end
end

local function Start(slot)
	if E.db.KnuUIFlightTimer == false then return end
	local from, to = CurrentNode(), TaxiNodeName(slot)
	local key = Key(from, to)
	flight = { key = key, requested = GetTime(), total = key and Times()[key] }
	if not bar then CreateBar(); Style() end
	bar:SetMinMaxValues(0, flight.total or 1)
	bar.text:SetText(flight.total and Place(to) or format(L["%s (learning)"], Place(to) or ''))
	bar:SetAlpha(0)
	bar:Show()
	if K.FadeTo then K:FadeTo(bar, 1) else bar:SetAlpha(1) end
	bar:SetScript('OnUpdate', OnUpdate)
end

-- Línea extra en el tooltip de cada destino: tiempo aprendido o "sin datos".
local function TooltipLine(slot)
	if E.db.KnuUIFlightTimer == false or not slot or TaxiNodeGetType(slot) ~= 'REACHABLE' then return end
	local total = Times()[Key(CurrentNode(), TaxiNodeName(slot))]
	GameTooltip:AddLine(total and format(L["Flight time: %s"], Clock(total)) or L["Flight time: not learned yet"], 0.8, 0.8, 0.8)
	GameTooltip:Show()
end

local function HookFlightMap()
	local mixin = _G.FlightMap_FlightPointPinMixin
	if not mixin or K.flightMapHooked then return end
	K.flightMapHooked = true
	-- Los pines copian el mixin al crearse; se engancha apenas carga Blizzard_FlightMap.
	hooksecurefunc(mixin, 'OnMouseEnter', function(pin)
		pcall(TooltipLine, pin.taxiNodeData and pin.taxiNodeData.slotIndex)
	end)
end

function K:SetupFlightTimer()
	if type(TakeTaxiNode) ~= 'function' then return end
	if E.db.KnuUIFlightTimer == nil then E.db.KnuUIFlightTimer = true end
	hooksecurefunc('TakeTaxiNode', function(slot) pcall(Start, slot) end)
	if type(TaxiRequestEarlyLanding) == 'function' then
		hooksecurefunc('TaxiRequestEarlyLanding', function() if flight then flight.early = true end end)
	end
	if type(TaxiNodeOnButtonEnter) == 'function' then
		hooksecurefunc('TaxiNodeOnButtonEnter', function(button) pcall(TooltipLine, button and button:GetID()) end)
	end
	HookFlightMap()
	local f = CreateFrame('Frame')
	f:RegisterEvent('ADDON_LOADED')
	f:SetScript('OnEvent', function(_, _, name) if name == 'Blizzard_FlightMap' then HookFlightMap() end end)
end
