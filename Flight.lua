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
	-- Debajo de la flecha de TomTom, que suele ir arriba al centro.
	bar:SetPoint('TOP', E.UIParent, 'TOP', 0, -120)
	bar:SetStatusBarTexture(E.Libs.LSM:Fetch('statusbar', 'Melli'))
	bar:CreateBackdrop('Transparent')
	if K.KnuFrame and bar.backdrop then K:KnuFrame(bar.backdrop) end
	bar.text = bar:CreateFontString(nil, 'OVERLAY')
	bar.text:SetPoint('LEFT', 6, 0)
	bar.text:SetPoint('RIGHT', -44, 0)
	bar.text:SetJustifyH('LEFT')
	bar.text:SetWordWrap(false)
	bar.time = bar:CreateFontString(nil, 'OVERLAY')
	bar.time:SetPoint('RIGHT', -6, 0)
	for _, text in ipairs({ bar.text, bar.time }) do text:FontTemplate('Expressway', 12, 'OUTLINE') end
	bar:Hide()
	E:CreateMover(bar, 'KnuUI_FlightTimerMover', L["KnuUI: flight timer"], nil, nil, nil, 'ALL,GENERAL', nil, 'KnuUI')
end

-- Al volar, DynamicCam (situación "Taxi") puede esconder toda la interfaz con UIParent:Hide()
-- (DynamicCam/Core.lua:510-518). Mientras dura el vuelo la barra cuelga de WorldFrame, que no se
-- esconde, en el mismo lugar y tamaño de pantalla; al terminar vuelve a su mover.
-- Lugar base de la barra (su mover, o el punto fijo sobre WorldFrame durante el vuelo), corrido dy
-- hacia abajo. ElvUI la ancla por TOP a su mover (ElvUI/Game/Shared/General/Movers.lua:73-75).
local function Base(dy)
	bar:ClearAllPoints()
	if bar.detached then
		bar:SetPoint('CENTER', WorldFrame, 'BOTTOMLEFT', bar.detached.x, bar.detached.y - dy)
	elseif bar.mover then
		bar:SetPoint('TOP', bar.mover, 'TOP', 0, -dy)
	else
		bar:SetPoint('TOP', E.UIParent, 'TOP', 0, -120 - dy)
	end
end

local function ScreenRect(f)
	if not (f and f.IsVisible and f:IsVisible() and f.GetRect) then return end
	local l, b, w, h = f:GetRect()
	if not (l and w and w > 0) then return end
	local s = f:GetEffectiveScale()
	return l * s, b * s, (l + w) * s, (b + h) * s
end

-- La flecha de TomTom y sus textos (título, distancia, tiempo, con el recuadro de Skins/TomTom.lua)
-- pueden quedar donde está la barra: el user la mueve o aprieta Esc y la interfaz vuelve en pleno
-- vuelo. Si se superponen, la barra baja hasta quedar 6 px debajo de lo más bajo que pisa. Sólo por
-- eventos (pedido del user 2026-11-16, nada por tiempo): al mostrarla, cuando la flecha aparece, se
-- va, se mueve o su recuadro cambia de alto, y cuando vuelve la interfaz (Esc con DynamicCam).
local GAP = 6
local function Avoid()
	if not bar then return end
	Base(0)
	local l, b, r, t = ScreenRect(bar)
	if not l then return end
	local arrow = _G.TomTomCrazyArrow
	if not arrow then return end
	local regions = {}
	for _, f in ipairs({ arrow, arrow.KnuPanel, arrow.title, arrow.status, arrow.tta }) do
		local fl, fb, fr, ft = ScreenRect(f)
		if fl and fl < r and fr > l then regions[#regions + 1] = { fb, ft } end
	end
	-- Al bajar puede caer sobre otra parte (el recuadro de textos va debajo de la flecha): se repite
	-- hasta que el lugar quede libre. Cuentas en píxeles de pantalla, sin releer la barra.
	local scale, shift = bar:GetEffectiveScale(), 0
	for _ = 1, #regions + 1 do
		local low
		for _, region in ipairs(regions) do
			if region[1] < t - shift and region[2] > b - shift then low = math.min(low or region[1], region[1]) end
		end
		if not low then break end
		shift = t - low + GAP * scale
	end
	if shift > 0 then Base(shift / scale) end
end

local function Recheck() if bar and bar:IsShown() then pcall(Avoid) end end

local function HookAvoid()
	local arrow = _G.TomTomCrazyArrow
	if arrow and not arrow.KnuFlightHooked then
		arrow.KnuFlightHooked = true
		arrow:HookScript('OnShow', Recheck)
		arrow:HookScript('OnHide', Recheck)
		-- Al arrastrarla TomTom no pasa por SetPoint (crazy_arrow.lua:204-216).
		arrow:HookScript('OnDragStop', Recheck)
		hooksecurefunc(arrow, 'SetPoint', Recheck)
	end
	local panel = arrow and arrow.KnuPanel
	if panel and not panel.KnuFlightHooked then
		panel.KnuFlightHooked = true
		panel:HookScript('OnSizeChanged', Recheck)
	end
	if not UIParent.KnuFlightHooked then
		UIParent.KnuFlightHooked = true
		UIParent:HookScript('OnShow', Recheck)
	end
end

local function Detach()
	if not bar or bar.detached then return end
	Base(0)
	local x, y = bar:GetCenter()
	if not x then return end
	local s, ws = bar:GetEffectiveScale(), WorldFrame:GetEffectiveScale()
	bar:SetParent(WorldFrame)
	bar:SetScale(s / ws)
	bar:SetFrameStrata('HIGH')
	-- Con la escala nueva la barra conserva su escala efectiva, así que el centro queda en las mismas unidades.
	bar.detached = { x = x, y = y }
	Avoid()
end

local function Attach()
	if not bar or not bar.detached then return end
	bar.detached = nil
	bar:SetParent(E.UIParent)
	bar:SetScale(1)
	Base(0)
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
		local function Gone() if not flight then bar:Hide(); Attach() end end
		if K.FadeTo then K:FadeTo(bar, 0, nil, Gone) else Gone() end
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
	if not bar.detached then pcall(Detach) end -- por si al arrancar todavía no tenía posición
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
	-- Una sola línea: si el destino no entra en 240, la barra se ensancha (6 + texto + 44 del reloj).
	local measure = bar.text.GetUnboundedStringWidth or bar.text.GetStringWidth
	bar:SetWidth(math.max(240, math.ceil(measure(bar.text) + 54)))
	bar:SetAlpha(0)
	bar:Show()
	pcall(HookAvoid)
	pcall(Detach)
	pcall(Avoid)
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

-- Botón de bajarse del vuelo que queda colgado al aterrizar.
-- DynamicCam, al esconder la interfaz en el vuelo, anota qué marcos estaban a la vista y los
-- esconde (DynamicCam/UiHideModule.lua:530-536); al terminar muestra otra vez los anotados
-- (:608-610). El botón de bajarse estaba a la vista durante el vuelo, así que al aterrizar vuelve
-- a aparecer aunque ya no haya taxi ni vehículo, y tocarlo da error. Se esconde si no corresponde.
local function NotNeeded()
	if UnitOnTaxi and UnitOnTaxi('player') then return false end
	if CanExitVehicle and CanExitVehicle() then return false end
	return true
end

local function HookLeaveButton()
	local button = _G.MainMenuBarVehicleLeaveButton
	if not button or K.leaveButtonHooked then return end
	K.leaveButtonHooked = true
	button:HookScript('OnShow', function(self)
		C_Timer.After(0, function()
			if self:IsShown() and not InCombatLockdown() and NotNeeded() then self:Hide() end
		end)
	end)
end

function K:SetupFlightTimer()
	pcall(HookLeaveButton)
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
