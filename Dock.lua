-- Port de addons/ForeverDock/ForeverDock.lua; conserva ranuras, escalas y restauración.
-- Fuentes de terceros relativas a D:/World of Warcraft/_forever_/Interface/AddOns/:
-- Details/boot.lua:12 (Details y alias _detalhes).
-- Details/classes/class_instance.lua:1163,1443,1509,1613,1622,1669,1673,1800,1804,
-- :1957,2654,2709 (instancias, estado, bloqueo, agrupado, barras y tamaño).
-- Details/core/windows.lua:376,413,553 (posicao/libwindow, restauración y reajuste).
-- Campos: classes/class_instance.lua:1293,1476-1480,1538-1539,2334
-- (posicao, snap/horizontalSnap/verticalSnap, isLocked, hermanos y show_statusbar);
-- core/windows.lua:415 (window_scale); frames/window_main.lua:445 (toolbar_side),
-- :3742,3746 (titlebar_shown/titlebar_height).
-- Details/frames/window_main.lua:2638-2693,3740,3763,4180,7366,8081,9224
-- (baseframe/titleBar/rowframe/windowSwitchButton/UPFrame, títulos, filas, estrato y escala).
-- Details/frames/window_options2_sections.lua:808 (_ElvUIEmbed).
-- Details/functions/events.lua:303; frames/window_main.lua:515 (SendEvent y tamaño).
-- Details_TinyThreat/Details_TinyThreat.lua:123,948 escucha DETAILS_INSTANCE_SIZECHANGED.
-- _ref/ElvUI/Game/Shared/Layout/Layout.lua:214,273,337,391,412,415 (paneles y hooks).
-- _ref/ElvUI/Game/Shared/Modules/Chat/Chat.lua:1620 (PositionChats).
-- Los métodos opcionales se comprueban antes de invocarlos; Safe protege el acceso completo.
-- ForeverDock: Embebe las ventanas 1 y 2 de Details! en el RightChatPanel de ElvUI.
-- Escrito desde cero para World of Warcraft: Forever (1.60.1 / Interface 16001).

local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')
local _G = _G
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_ceil = math.ceil
local tonumber = tonumber
local tostring = tostring
local string_lower = string.lower
local string_match = string.match
local string_gsub = string.gsub
local string_format = string.format
local pairs = pairs
local wipe = wipe

local DEFAULTS = {
	enabled = true,
	split = 0.5,
	wasLocked = {},
	savedStates = {},
}

local HEADER_HEIGHT = 20 -- Altura de baseframe.UPFrame en Details/frames/window_main.lua
local STATUSBAR_HEIGHT = 14 -- Altura de la barra de estado inferior en Details/frames/window_main.lua
local MIN_BODY_HEIGHT = 20 -- Altura mínima del cuerpo (baseframe) de una ventana de Details!
local WINDOW_GAP = 4 -- Separación horizontal en píxeles entre ventana 1 y ventana 2

local sessionRelTo = {} -- Referencia en memoria al frame relativo original por ID de ventana (1, 2)
local hookedFrames = {}
local hooksInstalled = false
local isUpdating = false
local conflictWarned = false
local errorWarned = false
local pendingDock -- acople pendiente porque llegó en combate
local separator

-- Objeto propio; mismo color y grosor que Skins/Panels.lua (línea de pestañas).
local function Separator(panel, offset, inset)
 if not separator and not offset then return end
 if not separator then
  separator = panel:CreateTexture(nil, 'OVERLAY')
  separator:SetHeight(1)
 end
 separator:SetShown(offset ~= nil)
 if not offset then return end
 local t = K:GetTheme()
 separator:ClearAllPoints()
 separator:SetPoint('TOPLEFT', panel, 'TOPLEFT', inset, -offset)
 separator:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', -inset, -offset)
 separator:SetColorTexture(t.accentDim.r, t.accentDim.g, t.accentDim.b, 0.8)
end

local vseparator
-- Separador vertical entre las dos ventanas de Details (lado a lado).
local function VSeparator(panel, x, top)
 if not vseparator and not x then return end
 if not vseparator then
  vseparator = panel:CreateTexture(nil, 'OVERLAY')
  vseparator:SetWidth(1)
 end
 vseparator:SetShown(x ~= nil)
 if not x then return end
 local t = K:GetTheme()
 vseparator:ClearAllPoints()
 vseparator:SetPoint('TOPLEFT', panel, 'TOPLEFT', x, -top)
 vseparator:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', x, 4)
 vseparator:SetColorTexture(t.accentDim.r, t.accentDim.g, t.accentDim.b, 0.8)
end

local function PrintMsg(msg)
 E:Print('KnuUI Dock: '..msg)
end

-- Todas las entradas (eventos, hooks, comandos y temporizadores) pasan por acá.
-- Un error de terceros no deja isUpdating trabado ni propaga errores al cliente.
local function Safe(callback, ...)
 if InCombatLockdown() then pendingDock = true; return false end
 if not E.Forever or K:IsLoaded('ForeverDock') or not K:IsLoaded('Details') then return false end
 local ok, result = pcall(callback, ...)
 if not ok then
  isUpdating = false
  if not errorWarned then
   errorWarned = true
   PrintMsg(string_format(L["could not complete the docking: %s"], tostring(result)))
  end
 end
 return ok and result
end

-- Obtiene el motor de ElvUI y el frame RightChatPanel.
-- Referencia ElvUI: ElvUI/Game/Shared/Layout/Layout.lua (LO:CreateChatPanels crea RightChatPanel)
local function GetElvUI()
	if not _G.ElvUI then
		return nil, nil
	end
	local ok, E = pcall(unpack, _G.ElvUI)
	if not ok or not E then
		return nil, nil
	end
	return E, _G.RightChatPanel
end

-- Obtiene la tabla global de Details!.
-- Referencia Details!: Details/boot.lua (_G.Details y alias _G._detalhes)
local function GetDetails()
	return _G.Details or _G._detalhes
end

-- E.db es dueño del respaldo: nunca se escribe en ForeverDockDB.
-- La copia profunda evita compartir savedStates/wasLocked con el addon anterior.
function K:GetDockDB()
 if type(E.db.KnuUIDock) ~= 'table' then
  local old = type(_G.ForeverDockDB) == 'table' and _G.ForeverDockDB or DEFAULTS
  E.db.KnuUIDock = E:CopyTable({}, old)
 end
 local db = E.db.KnuUIDock
 if type(db.enabled) ~= 'boolean' then db.enabled = true end
 if type(db.split) ~= 'number' or db.split < 0.2 or db.split > 0.8 then db.split = 0.5 end
 if type(db.wasLocked) ~= 'table' then db.wasLocked = {} end
 if type(db.savedStates) ~= 'table' then db.savedStates = {} end
 return db
end
local function InitDB() return K:GetDockDB() end

local function CopyTable(src)
	if type(src) ~= "table" then
		return nil
	end
	local copy = {}
	for k, v in pairs(src) do
		copy[k] = (type(v) == "table") and CopyTable(v) or v
	end
	return copy
end

local function RestoreTable(target, source)
	if type(source) ~= "table" then
		return nil
	end
	if type(target) ~= "table" then
		return CopyTable(source)
	end
	wipe(target)
	for k, v in pairs(source) do
		target[k] = (type(v) == "table") and CopyTable(v) or v
	end
	return target
end

local function IsInstanceEnabled(instance)
	if not instance then
		return false
	end
	if type(instance.IsEnabled) == "function" then
		return instance:IsEnabled() and true or false
	end
	return instance.ativa and true or false
end

local function SetFrameShown(frame, shown)
	if not frame then
		return
	end
	if shown then
		if type(frame.Show) == "function" then
			frame:Show()
		end
	else
		if type(frame.Hide) == "function" then
			frame:Hide()
		end
	end
end

-- Sincroniza la visibilidad de baseframe y sus hermanos rowframe y windowSwitchButton
-- Referencia Details!: Details/frames/window_main.lua:2676,2689 (hermanos bajo windowParent)
local function SetInstanceShown(instance, shown)
	if not instance then
		return
	end
	SetFrameShown(instance.baseframe, shown)
	SetFrameShown(instance.rowframe, shown)
	SetFrameShown(instance.windowSwitchButton, shown)
end

-- Obtiene una instancia activa de Details! con su baseframe ya creado.
-- Referencias Details!:
--   Details:GetInstance(id) -> Details/classes/class_instance.lua y Details/functions/api2.lua
--   instance:IsEnabled() / instance.ativa -> Details/classes/class_instance.lua
--   instance.baseframe -> Details/frames/window_main.lua (_detalhes:CriaGumpPrincipal)
local function GetActiveInstance(Details, id)
	if not Details or type(Details.GetInstance) ~= "function" then
		return nil
	end
	local instance = Details:GetInstance(id)
	if not instance or not instance.baseframe or not IsInstanceEnabled(instance) then
		return nil
	end
	return instance
end

-- Obtiene la escala efectiva de un frame con respaldo seguro.
local function GetEffectiveFrameScale(frame, fallback)
	if frame then
		if type(frame.GetEffectiveScale) == "function" then
			local s = tonumber(frame:GetEffectiveScale())
			if s and s > 0 then
				return s
			end
		end
		if type(frame.GetScale) == "function" then
			local s = tonumber(frame:GetScale())
			if s and s > 0 then
				return s
			end
		end
	end
	if fallback and fallback > 0 then
		return fallback
	end
	return 1
end

-- Relación de escalas entre RightChatPanel y el baseframe de la instancia (core/windows.lua:415-429).
local function GetInstanceScaleRatio(panel, instance)
	local panelScale = GetEffectiveFrameScale(panel, 1)
	local baseScale = GetEffectiveFrameScale(instance and instance.baseframe, tonumber(instance and instance.window_scale))
	return panelScale / baseScale
end

-- Calcula las alturas ocupadas por el toolbar (UPFrame), la barra de título (titleBar)
-- y la barra de estado inferior fuera de instance.baseframe.
-- Referencia Details!: Details/frames/window_main.lua (UPFrame se ancla arriba de baseframe
-- cuando instance.toolbar_side == 1; titleBar se ancla siempre arriba en 2638-2641,3763-3780;
-- la barra de estado se ancla debajo si show_statusbar es true).
local function GetInstanceChrome(instance)
	local toolbarSide = instance.toolbar_side or 1
	local topChrome = (toolbarSide ~= 2) and HEADER_HEIGHT or 0
	local bottomChrome = (toolbarSide == 2) and HEADER_HEIGHT or 0

	local baseframe = instance.baseframe
	local titleBar = baseframe and baseframe.titleBar
	local titleBarShown = titleBar and type(titleBar.IsShown) == "function" and titleBar:IsShown()
	if titleBarShown or instance.titlebar_shown then
		local titleH
		if titleBarShown and type(titleBar.GetHeight) == "function" then
			titleH = tonumber(titleBar:GetHeight())
			if instance.titlebar_shown and tonumber(instance.titlebar_height) then
				titleH = math_max(titleH or 0, tonumber(instance.titlebar_height))
			end
		end
		if not titleH or titleH <= 0 then
			titleH = tonumber(instance.titlebar_height) or (titleBar and type(titleBar.GetHeight) == "function" and tonumber(titleBar:GetHeight())) or HEADER_HEIGHT
		end
		local titleScale = (titleBar and type(titleBar.GetScale) == "function" and tonumber(titleBar:GetScale())) or 1
		local yOff = 0
		if titleBar and type(titleBar.GetPoint) == "function" then
			local _, _, _, _, py = titleBar:GetPoint(1)
			yOff = tonumber(py) or 0
		end
		topChrome = math_max(topChrome, (titleH * titleScale) + yOff)
	end

	if instance.show_statusbar then
		bottomChrome = bottomChrome + STATUSBAR_HEIGHT
	end
	return topChrome, bottomChrome
end

-- Calcula la altura mínima de ranura (en coordenadas de panel) necesaria para alojar una instancia sin desbordar.
local function GetMinSlotHeight(panel, instance)
	local topChrome, bottomChrome = GetInstanceChrome(instance)
	local scaleRatio = GetInstanceScaleRatio(panel, instance)
	return math_ceil((topChrome + bottomChrome + MIN_BODY_HEIGHT) / scaleRatio)
end

-- Calcula las dimensiones útiles de RightChatPanel respetando el borde/espaciado de ElvUI
-- y dejando hueco para RightChatTab y RightChatDataPanel solo si ElvUI los dibuja dentro del panel.
-- Referencias ElvUI:
--   ElvUI/Game/Shared/Layout/Layout.lua (LO:CreateChatPanels, LO:ToggleChatPanels, LO:RepositionChatDataPanels)
--   ElvUI/Game/Shared/Modules/Chat/Chat.lua (E.db.chat.panelWidth, panelHeight, separateSizes, panelWidthRight, panelHeightRight)
local function GetPanelGeometry(E, panel)
	local border = (E and tonumber(E.Border)) or 1
	local spacing = (E and tonumber(E.Spacing)) or 1
	local sideInset = border + spacing
	local topInset = sideInset
	local bottomInset = sideInset

	local panelW, panelH = panel:GetSize()
	local chatDB = E and E.db and E.db.chat
	if (not panelW or panelW <= 1) and chatDB then
		panelW = chatDB.separateSizes and chatDB.panelWidthRight or chatDB.panelWidth
	end
	if (not panelH or panelH <= 1) and chatDB then
		panelH = chatDB.separateSizes and chatDB.panelHeightRight or chatDB.panelHeight
	end
	panelW = tonumber(panelW) or 400
	panelH = tonumber(panelH) or 200

	local pTop = panel:GetTop()
	local pBottom = panel:GetBottom()
	if pTop and pBottom and pTop > pBottom then
		-- Comprobar si RightChatTab es visible y está dibujado dentro de la parte superior de RightChatPanel
		local tab = _G.RightChatTab
		local tabVisible = tab and tab:IsShown() and (tab:GetAlpha() or 0) > 0
		if tabVisible and chatDB and chatDB.panelTabBackdrop == false then
			tabVisible = false
		end
		if tabVisible then
			local tTop, tBottom = tab:GetTop(), tab:GetBottom()
			if tTop and tBottom and tTop <= (pTop + 2) and tBottom > pBottom and (pTop - tBottom) < (panelH * 0.5) then
				topInset = math_max(topInset, math_ceil(pTop - tBottom) + spacing)
			end
		end

		-- Comprobar si RightChatDataPanel es visible y está dibujado dentro de RightChatPanel (abajo o arriba)
		local dt = _G.RightChatDataPanel
		local dtVisible = dt and dt:IsShown() and (dt:GetAlpha() or 0) > 0
		if dtVisible then
			local dTop, dBottom = dt:GetTop(), dt:GetBottom()
			if dTop and dBottom then
				if dBottom >= (pBottom - 2) and dTop > pBottom and (dTop - pBottom) < (panelH * 0.5) then
					bottomInset = math_max(bottomInset, math_ceil(dTop - pBottom) + spacing)
				elseif dTop <= (pTop + 2) and dBottom < pTop and (pTop - dBottom) < (panelH * 0.5) then
					topInset = math_max(topInset, math_ceil(pTop - dBottom) + spacing)
				end
			end
		end
	end

	local availW = math_max(1, panelW - (sideInset * 2))
	local availH = math_max(0, panelH - topInset - bottomInset)
	return sideInset, topInset, bottomInset, availW, availH
end

-- Guarda el estado original (bloqueo, posición, tamaño, estrato) antes de acoplar.
-- Referencias Details!:
--   instance.isLocked -> Details/classes/class_instance.lua
--   instance:SaveMainWindowPosition() -> Details/frames/window_main.lua
local function SaveOriginalState(id, instance)
	local db = InitDB()
	local baseframe = instance.baseframe
	if not db.savedStates[id] then
		local point, relTo, relPoint, x, y = baseframe:GetPoint(1)
		local w, h = baseframe:GetSize()
		local relToName
		if type(relTo) == "table" and type(relTo.GetName) == "function" then
			relToName = relTo:GetName()
		elseif type(relTo) == "string" then
			relToName = relTo
		end
		sessionRelTo[id] = (type(relTo) == "table") and relTo or nil
		db.savedStates[id] = {
			point = point,
			relToName = relToName,
			relPoint = relPoint,
			x = x,
			y = y,
			width = w,
			height = h,
			posicao = CopyTable(instance.posicao),
			libwindow = CopyTable(instance.libwindow),
			strata = instance.strata or baseframe:GetFrameStrata(),
			upStrata = baseframe.UPFrame and baseframe.UPFrame:GetFrameStrata() or nil,
			level = baseframe:GetFrameLevel(),
			rowLevel = instance.rowframe and instance.rowframe:GetFrameLevel() or nil,
			upLevel = baseframe.UPFrame and baseframe.UPFrame:GetFrameLevel() or nil,
			baseShown = baseframe:IsShown() and true or false,
			rowShown = instance.rowframe and (instance.rowframe:IsShown() and true or false) or nil,
			switchShown = instance.windowSwitchButton and (instance.windowSwitchButton:IsShown() and true or false) or nil,
		}
	end
	if db.wasLocked[id] == nil then
		local locked = instance.isLocked and true or false
		db.wasLocked[id] = locked
	end
end

-- Actualiza las barras y plugins de una instancia tras cambiar su tamaño.
-- Referencias Details!:
--   instance:ReajustaGump() -> Details/frames/window_main.lua
--   instance:RefreshBars() / instance:InstanceRefreshRows() -> Details/classes/class_instance.lua
--   Details:SendEvent("DETAILS_INSTANCE_SIZECHANGED", nil, instance) -> Details/frames/window_main.lua
--     (usado por plugins como Details_TinyThreat en Details_TinyThreat/Details_TinyThreat.lua)
local function RefreshInstanceLayout(Details, instance)
	if type(instance.ReajustaGump) == "function" then
		pcall(instance.ReajustaGump, instance)
	end
	if type(instance.InstanceRefreshRows) == "function" then
		pcall(instance.InstanceRefreshRows, instance)
	end
	if type(instance.RefreshBars) == "function" then
		pcall(instance.RefreshBars, instance)
	end
	if Details and type(Details.SendEvent) == "function" then
		pcall(Details.SendEvent, Details, "DETAILS_INSTANCE_SIZECHANGED", nil, instance)
	end
end

local DockWindows, DockWindowsUnsafe

-- Posiciona y dimensiona una ventana individual de Details! dentro de su ranura en RightChatPanel.
-- Referencias Details!:
--   instance._ElvUIEmbed -> Details/frames/window_options2_sections.lua:808 (marca de embebido en ElvUI)
--   Comentario de posicionamiento respecto a UIParent -> Details/frames/window_main.lua:275
--     (baseframe y rowframe se mantienen hijos de UIParent para no romper la escala ni el guardado
--      interno de posiciones de Details!; se anclan a RightChatPanel y sincronizan estrato/visibilidad).
--   instance:UngroupInstance() / instance.snap -> Details/frames/window_main.lua (desagrupa ventanas)
--   instance:LockInstance(true) -> Details/frames/window_main.lua (bloquea arrastre/redimensionado)
--   instance:SetSize(w, h) -> Details/classes/class_instance.lua / Details/functions/api2.lua
local function ApplySlotToInstance(Details, id, instance, panel, xOffset, visualTopOffset, width, slotHeight)
	local baseframe = instance.baseframe
	if not baseframe then
		return
	end

	SaveOriginalState(id, instance)

	if not hookedFrames[baseframe] then
		hookedFrames[baseframe] = true
		baseframe:HookScript("OnShow", function()
			if not isUpdating and InitDB().enabled then
				DockWindows()
			end
		end)
		if type(rawget(instance, "RestoreMainWindowPosition")) == "function" then
			hooksecurefunc(instance, "RestoreMainWindowPosition", function()
				if not isUpdating and InitDB().enabled then
					DockWindows()
				end
			end)
		end
	end

	-- Desagrupar para que el snap magnético de Details! no mueva una ventana al posicionar la otra
	if type(instance.UngroupInstance) == "function" then
		pcall(instance.UngroupInstance, instance)
	end
	if type(instance.snap) == "table" then
		wipe(instance.snap)
	end
	instance.horizontalSnap = false
	instance.verticalSnap = false

	-- Marcar como embebida en ElvUI (Details/frames/window_options2_sections.lua:808)
	instance._ElvUIEmbed = true
	-- La skin define el título antes de calcular su espacio ocupado.
	local okSkin, errSkin = pcall(K.SkinDetails, K, instance)
	if not okSkin then PrintMsg(string_format(L["Details skin: %s"], tostring(errSkin))) end

	-- Bloquear la ventana para evitar arrastres accidentales (Details/frames/window_main.lua)
	if not instance.isLocked then
		if type(instance.LockInstance) == "function" then
			pcall(instance.LockInstance, instance, true)
		else
			instance.isLocked = true
		end
	end
	baseframe:SetMovable(false)

	-- Mantener UIParent como padre (Details/frames/window_main.lua:275) e igualar estrato sobre el panel
	local panelStrata = panel:GetFrameStrata() or "LOW"
	local panelLevel = panel:GetFrameLevel() or 1
	if type(instance.SetFrameStrata) == "function" then
		pcall(instance.SetFrameStrata, instance, panelStrata)
	else
		instance.strata = panelStrata
		baseframe:SetFrameStrata(panelStrata)
		if instance.rowframe then
			instance.rowframe:SetFrameStrata(panelStrata)
		end
		if instance.windowSwitchButton then
			instance.windowSwitchButton:SetFrameStrata(panelStrata)
		end
	end
	baseframe:SetFrameLevel(panelLevel + 2)
	if instance.rowframe then
		instance.rowframe:SetFrameLevel(panelLevel + 5)
	end
	if baseframe.UPFrame then
		baseframe.UPFrame:SetFrameStrata(panelStrata)
		baseframe.UPFrame:SetFrameLevel(panelLevel + 6)
	end

	local scaleRatio = GetInstanceScaleRatio(panel, instance)
	local scaledWidth = width * scaleRatio
	local scaledSlotHeight = slotHeight * scaleRatio
	local scaledXOffset = xOffset * scaleRatio
	local scaledTopOffset = visualTopOffset * scaleRatio

	local topChrome, bottomChrome = GetInstanceChrome(instance)
	local bodyHeight = math_max(MIN_BODY_HEIGHT, scaledSlotHeight - topChrome - bottomChrome)
	local yOffset = -(scaledTopOffset + topChrome)

	baseframe:ClearAllPoints()
	baseframe:SetPoint("TOPLEFT", panel, "TOPLEFT", scaledXOffset, yOffset)
	if type(instance.SetSize) == "function" then
		pcall(instance.SetSize, instance, scaledWidth, bodyHeight)
	end
	baseframe:SetSize(scaledWidth, bodyHeight)

	SetInstanceShown(instance, panel:IsShown())

	RefreshInstanceLayout(Details, instance)
	local okSkin, errSkin = pcall(K.SkinDetails, K, instance)
	if not okSkin then PrintMsg(string_format(L["Details skin: %s"], tostring(errSkin))) end
end

-- Restaura el estado previo de una instancia cuando deja de estar acoplada (ej. /knudock off o ventana 2 cerrada).
-- Referencias Details!:
--   instance:LockInstance(flag) -> Details/frames/window_main.lua
--   instance:RestoreMainWindowPosition() -> Details/frames/window_main.lua
local function RestoreInstance(Details, id, instance, restorePosition, clearBackup)
	if not instance or not instance.baseframe then
		return
	end
	local db = InitDB()
	local baseframe = instance.baseframe

	instance._ElvUIEmbed = nil

	local wasLocked = db.wasLocked[id]
	if wasLocked ~= nil then
		if type(instance.LockInstance) == "function" then
			pcall(instance.LockInstance, instance, wasLocked)
		else
			instance.isLocked = wasLocked
		end
		baseframe:SetMovable(not wasLocked)
		if clearBackup then
			db.wasLocked[id] = nil
		end
	end

	local saved = db.savedStates[id]
	if saved then
		if saved.strata then
			instance.strata = saved.strata
			if type(instance.SetFrameStrata) == "function" then
				pcall(instance.SetFrameStrata, instance, saved.strata)
			else
				baseframe:SetFrameStrata(saved.strata)
				if instance.rowframe then
					instance.rowframe:SetFrameStrata(saved.strata)
				end
				if instance.windowSwitchButton then
					instance.windowSwitchButton:SetFrameStrata(saved.strata)
				end
			end
			if baseframe.UPFrame then
				baseframe.UPFrame:SetFrameStrata(saved.upStrata or saved.strata)
			end
		end
		if saved.level then
			baseframe:SetFrameLevel(saved.level)
		end
		if instance.rowframe and saved.rowLevel then
			instance.rowframe:SetFrameLevel(saved.rowLevel)
		end
		if baseframe.UPFrame and saved.upLevel then
			baseframe.UPFrame:SetFrameLevel(saved.upLevel)
		end
		if IsInstanceEnabled(instance) then
			if saved.baseShown ~= nil then
				SetFrameShown(baseframe, saved.baseShown)
			end
			if saved.rowShown ~= nil then
				SetFrameShown(instance.rowframe, saved.rowShown)
			end
			if saved.switchShown ~= nil then
				SetFrameShown(instance.windowSwitchButton, saved.switchShown)
			end
		end
	end

	if restorePosition then
		local restored = false
		if saved then
			if saved.posicao then
				instance.posicao = RestoreTable(instance.posicao, saved.posicao)
			end
			if saved.libwindow then
				instance.libwindow = RestoreTable(instance.libwindow, saved.libwindow)
			end
		end
		if saved and saved.point and saved.width and saved.height then
			local relTo = sessionRelTo[id] or (saved.relToName and _G[saved.relToName]) or (type(saved.relTo) == "table" and saved.relTo) or _G.UIParent
			baseframe:ClearAllPoints()
			baseframe:SetPoint(saved.point, relTo, saved.relPoint or saved.point, saved.x or 0, saved.y or 0)
			baseframe:SetSize(saved.width, saved.height)
			restored = true
		elseif type(instance.RestoreMainWindowPosition) == "function" then
			restored = pcall(instance.RestoreMainWindowPosition, instance)
		end
		if restored then
			RefreshInstanceLayout(Details, instance)
		end
		if saved then
			if saved.posicao then
				instance.posicao = RestoreTable(instance.posicao, saved.posicao)
			end
			if saved.libwindow then
				instance.libwindow = RestoreTable(instance.libwindow, saved.libwindow)
			end
		end
	end

	if clearBackup then
		db.savedStates[id] = nil
		sessionRelTo[id] = nil
	end
end

DockWindowsUnsafe = function()
	if isUpdating then
		return
	end
	local db = InitDB()
	if not db.enabled then
		return
	end

	local E, panel = GetElvUI()
	local Details = GetDetails()
	if not E or not panel or not Details then
		return
	end

	local win1 = GetActiveInstance(Details, 1)
	Separator(panel)
	if not win1 then
		return
	end
	local win2 = GetActiveInstance(Details, 2)

	isUpdating = true

	local sideInset, topInset, _, availW, availH = GetPanelGeometry(E, panel)
	local rawWin2 = (type(Details.GetInstance) == "function") and Details:GetInstance(2) or nil
	local min1H = GetMinSlotHeight(panel, win1)

	if availH < min1H then
		-- Si ni siquiera entra la ventana 1, suspender el acoplamiento sin borrar el respaldo
		if win1._ElvUIEmbed then
			RestoreInstance(Details, 1, win1, true, false)
		end
		if rawWin2 and rawWin2._ElvUIEmbed then
			RestoreInstance(Details, 2, rawWin2, true, false)
		end
		isUpdating = false
		return
	end

	if win2 then
		-- Lado a lado (pedido del user): ventana 1 a la izquierda, ventana 2 a la derecha,
		-- las dos con el alto completo del panel; db.split reparte el ancho.
		local min2H = GetMinSlotHeight(panel, win2)
		local usableW = availW - WINDOW_GAP
		if availH >= math_max(min1H, min2H) and usableW >= 120 then
			local slot1W = math_floor(usableW * db.split)
			slot1W = math_max(60, math_min(slot1W, usableW - 60))
			local slot2W = usableW - slot1W
			ApplySlotToInstance(Details, 1, win1, panel, sideInset, topInset, slot1W, availH)
			ApplySlotToInstance(Details, 2, win2, panel, sideInset + slot1W + WINDOW_GAP, topInset, slot2W, availH)
			Separator(panel, nil) -- se oculta la línea horizontal
			VSeparator(panel, sideInset + slot1W + math_floor(WINDOW_GAP / 2), topInset)
		else
			-- Si ambas no entran, usar solo la ventana 1 y desacoplar temporalmente la 2
			if rawWin2 and rawWin2._ElvUIEmbed then
				RestoreInstance(Details, 2, rawWin2, true, false)
			end
			VSeparator(panel, nil)
			ApplySlotToInstance(Details, 1, win1, panel, sideInset, topInset, availW, availH)
		end
	else
		-- Si solo existe la ventana 1, ocupa todo el panel interior
		VSeparator(panel, nil)
		if rawWin2 and rawWin2._ElvUIEmbed then
			RestoreInstance(Details, 2, rawWin2, true, false)
		end
		ApplySlotToInstance(Details, 1, win1, panel, sideInset, topInset, availW, availH)
	end

	isUpdating = false
end

DockWindows = function()
 if InCombatLockdown() then pendingDock = true return end
 return Safe(DockWindowsUnsafe)
end

function K:RefreshDock()
 return DockWindows()
end

local function UndockAll()
	if separator then separator:Hide() end
	if vseparator then vseparator:Hide() end
	local Details = GetDetails()
	if not Details or type(Details.GetInstance) ~= "function" then
		return
	end
	local db = InitDB()
	isUpdating = true
	for id = 1, 2 do
		local instance = Details:GetInstance(id)
		if instance and (instance._ElvUIEmbed or db.savedStates[id] or db.wasLocked[id] ~= nil) then
			RestoreInstance(Details, id, instance, true, true)
		end
	end
	isUpdating = false
end

-- Sincroniza visibilidad cuando RightChatPanel se oculta/muestra (ej. botón de ocultar chat o combate).
local function SyncVisibilityWithPanel(panel)
	if not InitDB().enabled then
		return
	end
	local Details = GetDetails()
	if not Details then
		return
	end
	local shown = panel:IsShown()
	if not shown and separator then separator:Hide() end
	for id = 1, 2 do
		local instance = GetActiveInstance(Details, id)
		if instance and instance.baseframe and instance._ElvUIEmbed then
			SetInstanceShown(instance, shown)
		end
	end
	if shown then
		DockWindows()
	end
end

-- Instala los hooks sobre RightChatPanel, los módulos Layout/Chat de ElvUI y el ciclo de vida de ventanas de Details!.
local function InstallHooks(E, panel, Details)
	if hooksInstalled then
		return
	end
	hooksInstalled = true

	panel:HookScript("OnSizeChanged", function()
		if InitDB().enabled then
			DockWindows()
		end
	end)
	panel:HookScript("OnShow", function(self)
		Safe(SyncVisibilityWithPanel, self)
	end)
	panel:HookScript("OnHide", function(self)
		Safe(SyncVisibilityWithPanel, self)
	end)

	-- Hooks de ElvUI cuando cambian las opciones del panel o datatexts
	-- Referencia ElvUI: ElvUI/Game/Shared/Layout/Layout.lua y ElvUI/Game/Shared/Modules/Chat/Chat.lua
	if type(E.GetModule) == "function" then
		local Layout = E:GetModule("Layout", true)
		if Layout then
			for _, method in ipairs({ "ToggleChatPanels", "RepositionChatDataPanels", "CreateChatPanels" }) do
				if type(Layout[method]) == "function" then
					hooksecurefunc(Layout, method, function()
						if InitDB().enabled then
							DockWindows()
						end
					end)
				end
			end
		end
		local Chat = E:GetModule("Chat", true)
		if Chat and type(Chat.PositionChats) == "function" then
			hooksecurefunc(Chat, "PositionChats", function()
				if InitDB().enabled then
					DockWindows()
				end
			end)
		end
	end

	-- Hooks de Details! cuando recrea, abre, cierra o restaura la posición de una ventana
	-- Referencias Details!:
	--   RestoreMainWindowPosition -> Details/core/windows.lua
	--   CriarInstancia / AtivarInstancia / EnableInstance / DesativarInstancia -> Details/classes/class_instance.lua
	local detailsHooks = {
		"RestoreMainWindowPosition",
		"CriarInstancia",
		"CreateInstance",
		"AtivarInstancia",
		"EnableInstance",
		"DesativarInstancia",
		"ReabrirTodasInstancias",
		"SetWindowScale",
		"RefreshTitleBar",
		"SetTitleBarSettings",
	}
	for _, method in ipairs(detailsHooks) do
		if type(Details[method]) == "function" then
			hooksecurefunc(Details, method, function()
				if not isUpdating and InitDB().enabled then
					DockWindows()
				end
			end)
		end
	end
end

local function PrintStatus()
	local db = InitDB()
	local E, panel = GetElvUI()
	local Details = GetDetails()
	local estado = db.enabled and L["enabled"] or L["disabled"]
	local pct = math_floor(db.split * 100 + 0.5)

	if not E or not panel or not Details then
		PrintMsg(string_format(L["Status: %s | Split: %.2f (%d%%) | ElvUI or Details! is missing."], estado, db.split, pct))
		return
	end

	local w1 = GetActiveInstance(Details, 1) and L["active"] or L["inactive"]
	local w2 = GetActiveInstance(Details, 2) and L["active"] or L["inactive"]
	PrintMsg(string_format(L["Status: %s | Window 1 split: %.2f (%d%%) | Window 1: %s | Window 2: %s."], estado, db.split, pct, w1, w2))
	PrintMsg(L["Usage: /knudock on | /knudock off | /knudock split <0.2-0.8>"])
end

-- Comando /knudock
local function Command(msg)
	if not K:CanApply() then return end
	local db = InitDB()
	local E, panel = GetElvUI()
	local Details = GetDetails()

	if not E or not panel or not Details then
		PrintMsg(L["ElvUI or Details! was not found. Docking is unavailable."])
		return
	end

	local input = string_match(msg or "", "^%s*(.-)%s*$") or ""
	local cmd, arg = string_match(string_lower(input), "^(%S+)%s*(.-)$")

	if not cmd or cmd == "" then
		PrintStatus()
		return
	end

	if cmd == "on" then
		db.enabled = true
		InstallHooks(E, panel, Details)
		DockWindows()
		PrintMsg(L["Docking enabled in the ElvUI right panel."])
	elseif cmd == "off" then
		db.enabled = false
		Safe(UndockAll)
		PrintMsg(L["Docking disabled and windows restored."])
	elseif cmd == "split" then
		local normalized = string_gsub(arg or "", ",", ".")
		local val = tonumber(normalized)
		if not val or val < 0.2 or val > 0.8 then
			PrintMsg(L["Invalid value. Use a number between 0.2 and 0.8 (example: /knudock split 0.6)."])
			return
		end
		db.split = val
		if db.enabled then
			InstallHooks(E, panel, Details)
			DockWindows()
		end
		PrintMsg(string_format(L["Width split for window 1 saved at %.2f (%d%%)."], val, math_floor(val * 100 + 0.5)))
	else
		PrintMsg(L["Unknown subcommand. Usage: /knudock [on | off | split <0.2-0.8>]"])
	end
end

-- Inicialización al entrar al mundo
local function TryActivate()
	local db = InitDB()
	local E, panel = GetElvUI()
	local Details = GetDetails()
	if not E or not panel or not Details then
		return false
	end
	InstallHooks(E, panel, Details)
	if db.enabled then
		DockWindows()
	end
	return true
end

function K:SetupDock()
 InitDB()
 if self:IsLoaded('ForeverDock') then
  if not conflictWarned then
   conflictWarned = true
   PrintMsg(L["ForeverDock is loaded: the built-in dock stays inactive. You can disable ForeverDock."])
  end
  return
 end
 _G.SLASH_KNUUIDOCK1 = '/knudock'
 _G.SlashCmdList.KNUUIDOCK = function(msg)
  local ok, err = pcall(Command, msg)
  if not ok then E:Print('KnuUI dock: '..tostring(err)) end
 end
 local eventFrame = CreateFrame('Frame')
 eventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
 eventFrame:RegisterEvent('ADDON_LOADED')
 eventFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
 eventFrame:SetScript('OnEvent', function(_, event, name)
  if event == 'PLAYER_REGEN_ENABLED' then
   if pendingDock then pendingDock = false; DockWindows() end
   return
  end
  if event == 'ADDON_LOADED' and name ~= 'Details' and name ~= 'Details_TinyThreat' then return end
  Safe(TryActivate)
  if _G.C_Timer and type(_G.C_Timer.After) == 'function' then
   _G.C_Timer.After(0.5, function() Safe(TryActivate) end)
   _G.C_Timer.After(1.5, function() Safe(TryActivate) end)
  end
 end)
 Safe(TryActivate)
end
