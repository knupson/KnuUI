local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Transparencia de bloques enteros (fondo, barras de título, filas y texto) al 10 % visible.
-- Details: automática fuera de combate, con un botón ojo para dejarlo siempre visible.
-- Chat: sólo con su botón ojo.
-- No se usa la regla "fuera de combate" de Details: en Forever sólo transparenta el fondo, porque
-- barras y título se funden sólo si no usa la API de Blizzard (Details/frames/window_main.lua:4662-4665).
-- Se baja el alfa de la ventana entera (baseframe, rowframe, windowSwitchButton: :4650-4656) y
-- del panel que la contiene. El chat y sus pestañas son hijos de LeftChatPanel
-- (ElvUI Modules/Chat/Chat.lua:1457-1458), así que basta con el alfa del panel.
-- Los botones cuelgan de E.UIParent para no transparentarse junto con su bloque.
local FADED = 0.1
local buttons = {}

local function Details() return _G.Details or _G._detalhes end

local function InCombat() return InCombatLockdown() or UnitAffectingCombat('player') end

local function DetailsFaded()
	return E.db.KnuUIDetailsFade ~= false and not E.db.KnuUIDetailsKeep and not InCombat()
end

local function Instances(callback)
	local D = Details()
	if not D or type(D.GetInstance) ~= 'function' then return end
	for id = 1, 5 do
		local instance = D:GetInstance(id)
		if instance and instance.baseframe then callback(instance) end
	end
end

-- animate: fundido de 250 ms (Motion.lua) al entrar/salir de combate o tocar el ojo. Sin animar
-- cuando Details repone su alfa por su cuenta: ahí se corrige al instante para que no parpadee.
local function SetBlockAlpha(frame, alpha, animate)
	if not frame or not frame.SetAlpha then return end
	if animate and K.FadeTo then K:FadeTo(frame, alpha) else frame:SetAlpha(alpha) end
end

local function ApplyDetails(animate)
	local alpha = DetailsFaded() and FADED or 1
	SetBlockAlpha(_G.RightChatPanel, alpha, animate)
	Instances(function(instance)
		-- Deja apagada la regla de Details que versiones anteriores de KnuUI encendían (valor 15).
		local rule = instance.hide_on_context and instance.hide_on_context[2]
		if rule and rule.value == 15 then rule.enabled, rule.value = false, 100 end
		for _, frame in ipairs({ instance.baseframe, instance.rowframe, instance.windowSwitchButton }) do
			SetBlockAlpha(frame, alpha, animate)
		end
	end)
end

local function ApplyChat(animate)
	SetBlockAlpha(_G.LeftChatPanel, E.db.KnuUIChatClear and FADED or 1, animate)
end

local function Button(name, panel, onClick, tooltip)
	local b = CreateFrame('Button', name, E.UIParent)
	b:SetSize(16, 16)
	b:SetPoint('BOTTOMRIGHT', panel, 'TOPRIGHT', 0, 2)
	b:SetFrameStrata('MEDIUM')
	b:SetTemplate('Transparent')
	b.icon = b:CreateTexture(nil, 'ARTWORK')
	b.icon:SetPoint('TOPLEFT', 2, -2)
	b.icon:SetPoint('BOTTOMRIGHT', -2, 2)
	b.icon:SetTexture([[Interface\Minimap\Tracking\None]])
	b:SetScript('OnClick', onClick)
	b:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
		GameTooltip:AddLine(tooltip())
		GameTooltip:Show()
	end)
	b:SetScript('OnLeave', function() GameTooltip:Hide() end)
	if K.Hoverable then K:Hoverable(b) end
	buttons[#buttons + 1] = b
	return b
end

function K:StyleFadeButtons()
	local t = self:GetTheme()
	for _, b in ipairs(buttons) do
		local active = (b == buttons.details and E.db.KnuUIDetailsKeep) or (b == buttons.chat and not E.db.KnuUIChatClear)
		local c = active and t.accent or t.muted
		b:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
		b.icon:SetVertexColor(c.r, c.g, c.b)
	end
end

function K:ApplyChatClear() ApplyChat() end

function K:UpdatePanelFade(animate)
	pcall(ApplyDetails, animate)
	ApplyChat(animate)
	if buttons.details then buttons.details:SetShown(E.db.KnuUIDetailsFade ~= false) end
	self:StyleFadeButtons()
end

function K:SetupPanelFade()
	if E.db.KnuUIDetailsFade == nil then E.db.KnuUIDetailsFade = true end
	if _G.RightChatPanel and not buttons.details then
		buttons.details = Button('KnuUI_DetailsKeep', _G.RightChatPanel, function()
			E.db.KnuUIDetailsKeep = not E.db.KnuUIDetailsKeep
			K:UpdatePanelFade(true)
		end, function() return E.db.KnuUIDetailsKeep and L["Details always visible (click to fade out of combat)"] or L["Details fades out of combat (click to keep it visible)"] end)
	end
	if _G.LeftChatPanel and not buttons.chat then
		buttons.chat = Button('KnuUI_ChatClear', _G.LeftChatPanel, function()
			E.db.KnuUIChatClear = not E.db.KnuUIChatClear
			K:UpdatePanelFade(true)
		end, function() return E.db.KnuUIChatClear and L["Chat faded (click to show it)"] or L["Chat visible (click to fade it)"] end)
	end
	-- Details vuelve a poner su alfa en varias situaciones (SetWindowAlphaForCombat, :4650-4656):
	-- después de cada una se reaplica el estado de KnuUI. Las instancias heredan los métodos de Details.
	local D = Details()
	if D and type(D.SetWindowAlphaForCombat) == 'function' and not K.detailsAlphaHooked then
		K.detailsAlphaHooked = true
		hooksecurefunc(D, 'SetWindowAlphaForCombat', function() pcall(ApplyDetails) end)
	end
	local events = CreateFrame('Frame')
	for _, event in ipairs({ 'PLAYER_REGEN_DISABLED', 'PLAYER_REGEN_ENABLED', 'PLAYER_ENTERING_WORLD' }) do events:RegisterEvent(event) end
	-- SetAlpha está permitido en combate; ni los paneles ni las ventanas de Details son protegidos.
	events:SetScript('OnEvent', function(_, event)
		if event == 'PLAYER_REGEN_DISABLED' then
			pcall(ApplyDetails, true)
		else
			C_Timer.After(0.5, function() pcall(ApplyDetails, event == 'PLAYER_REGEN_ENABLED') end)
		end
	end)
	C_Timer.After(3, function() K:UpdatePanelFade() end)
end
