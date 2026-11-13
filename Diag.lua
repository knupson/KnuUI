local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Registro de diagnóstico de la interfaz (pedido del user 2026-11-12: no depender de capturas).
-- Guarda en WTF\Account\<cuenta>\SavedVariables\KnuUI.lua (variable KnuUIDiag) la escala, tamaño,
-- rectángulo y anclaje de los bloques de KnuUI/ElvUI en varios momentos de la carga, y cada llamada
-- que cambia la escala, el tamaño o el anclaje de UIParent / ElvUIParent con quién la hizo.
-- Se rehace en cada sesión (no acumula). /knudiag toma una foto más a mano.

local diag
local FRAMES = {
	'UIParent', 'ElvUIParent', 'LeftChatPanel', 'RightChatPanel', 'LeftChatDataPanel', 'RightChatDataPanel',
	'ElvUI_Bar1', 'ElvUI_Bar1Button1', 'ElvUI_Bar2', 'ElvUI_Bar3', 'ElvUI_Bar4', 'ElvUI_Bar5', 'ElvUI_Bar6',
	'ElvUI_BottomPanel', 'ElvUI_TopPanel', 'Minimap', 'MinimapPanel', 'MMHolder', 'MinimapCluster',
	'ElvAB_1', 'ElvAB_2', 'ElvAB_3', 'ElvAB_4', 'ElvAB_5', 'ElvAB_6', 'LeftChatMover', 'RightChatMover',
	'DTPanelKnuUI_DataMover', 'ElvUI_MinimapHolder', 'KnuUI_Buttons', 'KnuUI_RaidMarkers', 'KnuUI_ManaTank', 'KnuUI_HealthTank', 'DetailsBaseFrame1',
	'DetailsBaseFrame2', 'KnuUI_Workspace', 'KnuUI_CC_guide', 'KnuUI_CC_chat', 'KnuUI_CC_details', 'KnuUI_CC_data',
	'KnuUI_CC_map', 'KnuUI_CC_bags', 'WoWProMainFrame', 'WorldMapFrame', 'PallyPowerFrame', 'TomTomCrazyArrow', 'DTPanelKnuUI_Data', 'ElvUF_Player', 'ElvUF_Target', 'ElvUI_PlayerBuffs', 'ChatFrame1',
}

local function r(v) if type(v) == 'number' then return math.floor(v * 1000 + 0.5) / 1000 end return v end

local function Name(f)
	if not f then return 'nil' end
	local ok, n = pcall(f.GetName, f)
	return (ok and n) or tostring(f)
end

local function Info(f)
	local t = {}
	pcall(function()
		t.shown = f:IsShown()
		t.scale = r(f:GetScale())
		t.eff = r(f:GetEffectiveScale())
		t.w, t.h = r(f:GetWidth()), r(f:GetHeight())
		local L, B, W, H = f:GetRect()
		t.rect = { r(L), r(B), r(W), r(H) }
		if L then -- en píxeles físicos de la ventana
			local px = f:GetEffectiveScale() * (select(2, GetPhysicalScreenSize()) / 768)
			t.px = { r(L * px), r(B * px), r(W * px), r(H * px) }
		end
		local n = f:GetNumPoints() or 0
		t.points = {}
		for i = 1, n do
			local p, rel, rp, x, y = f:GetPoint(i)
			t.points[i] = format('%s %s %s %s %s', tostring(p), Name(rel), tostring(rp), tostring(r(x)), tostring(r(y)))
		end
		t.parent = Name(f:GetParent())
	end)
	return t
end

local function Fonts(f, out, depth)
	if not f or depth > 3 then return end
	pcall(function()
		for _, reg in ipairs({ f:GetRegions() }) do
			if reg.GetObjectType and reg:GetObjectType() == 'FontString' then
				local font, size, flags = reg:GetFont()
				local ok, text = pcall(reg.GetText, reg)
				out[#out + 1] = format('%s | %s %s %s | eff %s | %s', Name(reg), tostring(font), tostring(r(size)),
					tostring(flags), tostring(r(reg:GetEffectiveScale())), ok and tostring(text) or '?')
			end
		end
		for _, child in ipairs({ f:GetChildren() }) do Fonts(child, out, depth + 1) end
	end)
end

function K:DiagSnapshot(label)
	if not diag then return end
	local s = { label = label, time = r(GetTime()) }
	s.elv = {
		mult = r(E.mult), perfect = r(E.perfect), uiscale = r(E.uiscale), UIScale = r(E.global and E.global.general and E.global.general.UIScale),
		screenWidth = r(E.screenWidth), screenHeight = r(E.screenHeight), physicalWidth = E.physicalWidth, physicalHeight = E.physicalHeight,
		Border = E.Border, Spacing = E.Spacing, PixelMode = E.PixelMode,
	}
	s.client = { physical = { GetPhysicalScreenSize() }, screen = { r(GetScreenWidth()), r(GetScreenHeight()) }, uiScaleCVar = GetCVar('uiScale'), useUiScale = GetCVar('useUiScale') }
	local topo = _G.OffhandCompanionTopology
	if type(topo) == 'table' then s.offhand = { pw = topo.physicalWidth, ph = topo.physicalHeight, game = topo.game, workspace = topo.workspace } end
	s.frames = {}
	for _, n in ipairs(FRAMES) do
		local f = _G[n]
		if f then s.frames[n] = Info(f) end
	end
	s.minimapFonts = {}
	Fonts(_G.MinimapPanel, s.minimapFonts, 0)
	Fonts(_G.Minimap, s.minimapFonts, 0)
	diag.snapshots[#diag.snapshots + 1] = s
end

local function Log(what, frame, ...)
	if not diag or #diag.calls >= 800 then return end
	local args = {}
	for i = 1, select('#', ...) do
		local v = select(i, ...)
		args[i] = type(v) == 'table' and Name(v) or tostring(r(v))
	end
	diag.calls[#diag.calls + 1] = format('%.3f %s:%s(%s) <- %s', GetTime(), Name(frame), what, table.concat(args, ', '),
		(debugstack(3, 3, 0) or ''):gsub('\n', ' / '))
end

local function Watch(f)
	if not f or f.KnuDiagWatched then return end
	f.KnuDiagWatched = true
	for _, m in ipairs({ 'SetScale', 'SetSize', 'SetWidth', 'SetHeight', 'SetPoint', 'ClearAllPoints', 'SetAllPoints', 'StartMoving', 'StopMovingOrSizing' }) do
		if f[m] then hooksecurefunc(f, m, function(self, ...) Log(m, self, ...) end) end
	end
end

-- Apagado por defecto (2026-11-13: con el registro siempre prendido no se sabía si demoraba la recarga).
-- /knudiag lo prende para la próxima carga; /knudiag off lo apaga.
local enabled = E.global and E.global.KnuUIDiagOn

if enabled then
	-- Arranca en la carga del archivo para ver también lo que pasa antes de PLAYER_LOGIN.
	_G.KnuUIDiag = { started = date('%Y-%m-%d %H:%M:%S'), version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata('KnuUI', 'Version'), snapshots = {}, calls = {} }
	diag = _G.KnuUIDiag
	Watch(_G.UIParent)
	Watch(E.UIParent)

	local ev = CreateFrame('Frame')
	ev:RegisterEvent('PLAYER_LOGIN')
	ev:RegisterEvent('PLAYER_ENTERING_WORLD')
	ev:RegisterEvent('ADDON_LOADED')
	ev:SetScript('OnEvent', function(_, event, arg)
		-- SavedVariables de KnuUI se cargan después del archivo y pisan la tabla: se vuelve a poner la de esta sesión.
		if event == 'ADDON_LOADED' and arg == 'KnuUI' then
			_G.KnuUIDiag = diag
			return
		end
		if event == 'ADDON_LOADED' then return end
		K:DiagSnapshot(event)
		if event == 'PLAYER_ENTERING_WORLD' then
			ev:UnregisterEvent('PLAYER_ENTERING_WORLD')
			Watch(_G.TomTomCrazyArrow)
			C_Timer.After(3, function() K:DiagSnapshot('PEW+3s') end)
			C_Timer.After(10, function()
				K:DiagSnapshot('PEW+10s')
				E:Print(L["Diagnostic saved (written to disk on /reload or logout)."])
			end)
		end
	end)
end

function K:DiagEnable(state)
	E.global.KnuUIDiagOn = state and true or nil
	E:Print(state and L["Diagnostic on from the next reload (/reload). /knudiag off turns it off."] or L["Diagnostic off from the next reload."])
end

SLASH_KNUDIAG1 = '/knudiag'
SlashCmdList.KNUDIAG = function(msg)
	if msg == 'off' then K:DiagEnable(false) return end
	if not enabled then K:DiagEnable(true) return end
	K:DiagSnapshot('manual')
	E:Print(L["Diagnostic snapshot taken; /reload writes it to disk."])
end
