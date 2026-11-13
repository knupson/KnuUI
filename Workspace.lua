local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Centro de comando con Offhand (pedido del user 2026-11-12): cuando Offhand estira la ventana sobre
-- dos monitores, el monitor de trabajo junta lo que no es combate (guía + PallyPower, chat, Details,
-- datos, mapa, bolsas) y el de juego queda con barras, marcos, minimapa y la flecha de TomTom.
-- Regla de diseño del user: "lo que veo más seguido tiene que estar lo más cerca posible del monitor
-- contiguo". Las zonas se calculan desde el borde que el monitor de trabajo comparte con el de juego
-- (arriba, abajo, izquierda o derecha) y para cualquier resolución u orientación.
-- Datos de Offhand: Offhand.Viewport:GetMetrics() (Offhand/Core/Viewport.lua:459-500) da los
-- rectángulos en píxeles físicos (workspacePixel*, gamePixel*, origen abajo a la izquierda) y
-- isSpanned. Revisiones de diseño (Codex, Gemini, NVIDIA; docs/knuui-final/PLAN.md): no se escribe en
-- el perfil de Offhand (Routing:SetRule lo haría, WorkspaceRouting.lua:32-34), todo se mueve fuera de
-- combate y la detección se rehace con una firma de los rectángulos.
-- Los movers de ElvUI aceptan cualquier marco global como ancla (ElvUI General/Movers.lua:63-70): acá
-- se anclan a marcos de zona propios en tiempo de ejecución, sin escribir E.db.movers, así el diseño de
-- una sola pantalla queda intacto. Lo que el user arrastre en modo centro de comando se guarda aparte
-- (E.db.KnuUICC.custom) relativo a su zona.

local CC = {}
K.CC = CC

-- El panel de datos de ElvUI no se llama KnuUI_Data: DT:FetchFrame lo crea como ElvUI_DTPanelN y lo guarda en
-- DT.PanelPool.InUse[nombre] (ElvUI DataTexts.lua:139-158). Antes se buscaba _G.KnuUI_Data, que no existe,
-- y por eso DynamicCam escondía la barra al volar (visto en el juego 2026-11-13).
local function DataPanel()
	local DT = E:GetModule('DataTexts', true)
	return DT and DT.PanelPool and DT.PanelPool.InUse and DT.PanelPool.InUse.KnuUI_Data
end

local M = 4   -- margen contra los bordes del monitor: el del chat en el diseño de una pantalla (Layout.lua:41-42, 4,4)
local G = 6   -- separación entre bloques: la del chat con las barras abajo (x 404 -> 410, medido con /knudiag)
local PALLY = 60 -- alto máximo de la tira de PallyPower con el centro de comando: casilla de hasta 54 + 3 de margen arriba y abajo (Skins/AddOns/PallyPower.lua, MAX_TILE)

-- Bloques que puede manejar el centro de comando, en orden de prioridad (lo más mirado primero).
CC.blocks = {
	{ id = 'guide', label = L["WoW-Pro guide + PallyPower"] },
	{ id = 'chat', label = L["Chat"], mover = 'LeftChatMover' },
	{ id = 'details', label = L["Details"], mover = 'RightChatMover' },
	{ id = 'data', label = L["Data bar"], mover = 'DTPanelKnuUI_DataMover' },
	{ id = 'map', label = L["Map"] },
	{ id = 'bags', label = L["Bags"] },
}
local byId = {}
for _, b in ipairs(CC.blocks) do byId[b.id] = b end

-- Presets: qué bloques van al monitor de trabajo.
CC.presets = {
	{ id = 'full', label = L["Command center (recommended)"], desc = L["Guide, chat, Details, data, map and bags on the workspace; the game monitor keeps only combat."],
		blocks = { guide = 'workspace', chat = 'workspace', details = 'workspace', data = 'workspace', map = 'workspace', bags = 'workspace' } },
	{ id = 'social', label = L["Social and guide up"], desc = L["Guide, chat and Details on the workspace; data bar, map and bags stay with the game."],
		blocks = { guide = 'workspace', chat = 'workspace', details = 'workspace', data = 'game', map = 'game', bags = 'game' } },
	{ id = 'maps', label = L["Only map and bags up"], desc = L["The single-screen layout stays on the game monitor; map and bags open on the workspace."],
		blocks = { guide = 'game', chat = 'game', details = 'game', data = 'game', map = 'workspace', bags = 'workspace' } },
	{ id = 'raid', label = L["Raid: meters up"], desc = L["Details and chat on the workspace next to the game monitor; guide stays with the game."],
		blocks = { guide = 'game', chat = 'workspace', details = 'workspace', data = 'workspace', map = 'workspace', bags = 'workspace' } },
	{ id = 'off', label = L["Everything on the game monitor"], desc = L["Like a single screen; the workspace is left to Offhand."],
		blocks = { guide = 'game', chat = 'game', details = 'game', data = 'game', map = 'game', bags = 'game' } },
}
local presetById = {}
for _, p in ipairs(CC.presets) do presetById[p.id] = p end

local holder, zones, active, signature, pending, unlocked = nil, {}, false, nil, false, false
-- Posición de una pantalla de cada mover, tomada del perfil vigente cuando entra al monitor de trabajo
-- (revisión de Codex: tomada una sola vez, un arrastre posterior reponía una posición vieja).
local savedBefore = {}
local frame

local function DB()
	E.db.KnuUICC = E.db.KnuUICC or {}
	local db = E.db.KnuUICC
	db.preset = db.preset or 'full'
	db.blocks = db.blocks or {}
	db.custom = db.custom or {}
	return db
end

local function Dest(id)
	local db = DB()
	local v = db.blocks[id]
	if v then return v end
	local p = presetById[db.preset] or presetById.full
	return p.blocks[id] or 'game'
end

-- Métricas de Offhand (píxeles físicos, origen abajo a la izquierda) o nil si no hay span real.
local function Metrics()
	if not (K.OffhandTopology and K.OffhandTopology()) then return end
	local off = _G.Offhand
	local m
	if off and off.Viewport and off.Viewport.GetMetrics then
		local ok, res = pcall(off.Viewport.GetMetrics, off.Viewport)
		if ok and type(res) == 'table' and res.isSpanned then m = res end
	end
	local t = _G.OffhandCompanionTopology
	local function n(v) return tonumber(v) end
	if m and n(m.workspacePixelWidth) and n(m.workspacePixelLeft) and n(m.workspacePixelBottom) and n(m.gamePixelWidth) and n(m.gamePixelLeft) and n(m.gamePixelBottom) then
		return {
			ws = { x = n(m.workspacePixelLeft), y = n(m.workspacePixelBottom), w = n(m.workspacePixelWidth), h = n(m.workspacePixelHeight) },
			game = { x = n(m.gamePixelLeft), y = n(m.gamePixelBottom), w = n(m.gamePixelWidth), h = n(m.gamePixelHeight) },
			ph = n(m.physicalHeight),
		}
	elseif type(t) == 'table' and type(t.workspace) == 'table' and type(t.game) == 'table' and tonumber(t.workspace.x) and tonumber(t.game.x) then
		return {
			ws = { x = n(t.workspace.x), y = n(t.workspace.y), w = n(t.workspace.width), h = n(t.workspace.height) },
			game = { x = n(t.game.x), y = n(t.game.y), w = n(t.game.width), h = n(t.game.height) },
			ph = n(t.physicalHeight),
		}
	end
end

-- Borde del monitor de trabajo que toca al de juego.
local function Edge(ws, game)
	if ws.y >= game.y + game.h - 1 then return 'bottom' end -- trabajo arriba del juego
	if ws.y + ws.h <= game.y + 1 then return 'top' end      -- trabajo abajo
	if ws.x >= game.x + game.w - 1 then return 'left' end   -- trabajo a la derecha
	return 'right'                                          -- trabajo a la izquierda
end

-- Tamaño real de cada bloque en unidades de ElvUIParent (1 px con la escala de KnuUI).
local function BlockSize(id)
	if id == 'chat' then
		local p = _G.LeftChatPanel
		return (p and p:GetWidth()) or 400, (p and p:GetHeight()) or 180
	elseif id == 'details' then
		local p = _G.RightChatPanel
		return (p and p:GetWidth()) or 529, (p and p:GetHeight()) or 180
	elseif id == 'data' then
		local p = DataPanel() or _G.DTPanelKnuUI_DataMover
		return (p and p:GetWidth()) or 960, (p and p:GetHeight()) or 22
	elseif id == 'guide' then
		local g = _G.WoWPro and _G.WoWPro.MainFrame
		local w = g and g:GetWidth() or 250
		return math.max(250, w), 320
	end
	return 0, 0
end

-- Calcula los rectángulos de zona dentro del holder (unidades = px de pantalla), origen abajo-izq.
-- Prioridad desde el borde contiguo: banda cercana con guía, chat y Details; después la barra de datos;
-- el resto (lejos) para mapa y bolsas.
function CC:Layout(W, H, edge, overlap)
	local r = {}
	local horizontal = edge == 'bottom' or edge == 'top'
	local gw, gh = BlockSize('guide')
	local cw, ch = BlockSize('chat')
	local dw, dh = BlockSize('details')
	local tw, th = BlockSize('data')
	if horizontal then
		-- Pedido del user (2026-11-13, segunda vuelta): barra de datos arriba de todo del monitor de trabajo;
		-- guía, chat y Details con la misma altura llenando la franja pegada al juego; PallyPower adentro del
		-- bloque de Details, abajo, sobre la segunda ventana (Tiny Threat). Distancias: margen M (borde de
		-- Offhand + 4) y 6 px entre bloques.
		local band = math.max(180, math.min(360, math.floor(H * 0.30)))
		local avail = W - 2 * M - 2 * G
		local gwide = math.floor(avail * 0.26)
		local cwide = math.floor(avail * 0.36)
		local dwide = avail - gwide - cwide
		local nearY = edge == 'bottom' and M or (H - M - band)
		r.guide = { x = M, y = nearY, w = gwide, h = band }
		r.chat = { x = M + gwide + G, y = nearY, w = cwide, h = band }
		r.details = { x = W - M - dwide, y = nearY, w = dwide, h = band }
		-- Tira de PallyPower: mitad derecha del bloque de Details (ventana Tiny Threat), pegada abajo.
		local half = math.floor(dwide / 2)
		r.pally = { x = r.details.x + dwide - half, y = nearY + G, w = half - G, h = PALLY }
		local dataY = edge == 'bottom' and (H - M - th) or M
		r.data = { x = M, y = dataY, w = W - 2 * M, h = th }
		local farY0 = edge == 'bottom' and (nearY + band + G) or (dataY + th + G)
		local farY1 = edge == 'bottom' and (dataY - G) or (nearY - G)
		r.map = { x = M, y = farY0, w = W - 2 * M, h = math.max(0, farY1 - farY0) }
		r.bags = r.map
	else
		-- Vertical (o lado a lado): la columna entera toca el borde; lo más mirado va en la franja que
		-- comparte altura con el monitor de juego (overlap), lo demás en lo que sobresale.
		local o0, o1 = overlap and overlap[1] or 0, overlap and overlap[2] or H
		local x0 = M
		local top = o1 - M
		r.data = { x = x0, y = math.max(M, top - th), w = math.min(tw, W - 2 * M), h = th }
		top = r.data.y - G
		r.guide = { x = x0, y = math.max(M, top - gh), w = math.min(gw, W - 2 * M), h = gh }
		top = r.guide.y - G
		r.chat = { x = x0, y = math.max(M, top - ch), w = math.min(cw, W - 2 * M), h = ch }
		top = r.chat.y - G
		r.details = { x = x0, y = math.max(o0 + M, top - dh), w = math.min(dw, W - 2 * M), h = dh }
		-- Lejos: lo que sobresale por arriba o por abajo del monitor de juego.
		local above = H - o1
		local below = o0
		if above >= below then
			r.map = { x = M, y = o1 + G, w = W - 2 * M, h = math.max(0, H - M - o1 - G) }
		else
			r.map = { x = M, y = M, w = W - 2 * M, h = math.max(0, o0 - G - M) }
		end
		r.bags = { x = M, y = r.map.y, w = math.floor((W - 2 * M) * 0.5), h = r.map.h }
		if r.map.h < 200 then -- casi sin espacio fuera de la franja: mapa y bolsas en lo que quede abajo
			local free = r.details.y - G - M
			r.map = { x = M, y = M, w = W - 2 * M, h = math.max(0, free) }
			r.bags = r.map
		end
	end
	return r
end

local function Zone(id)
	if zones[id] then return zones[id] end
	local z = CreateFrame('Frame', 'KnuUI_CC_' .. id, holder)
	zones[id] = z
	return z
end

local function Snapshot()
	local m = Metrics()
	if not m then return end
	return format('%d,%d,%d,%d|%d,%d,%d,%d|%s', m.ws.x, m.ws.y, m.ws.w, m.ws.h, m.game.x, m.game.y, m.game.w, m.game.h,
		tostring(E.UIParent and E.UIParent:GetEffectiveScale()))
end

-- Holder con la misma escala efectiva que ElvUIParent: 1 unidad = los mismos px que en el monitor de juego.
local function PlaceHolder(m)
	holder = holder or CreateFrame('Frame', 'KnuUI_Workspace', _G.UIParent)
	local eff = E.UIParent:GetEffectiveScale()
	holder:SetScale(eff / _G.UIParent:GetEffectiveScale())
	local unit = eff * (m.ph or select(2, GetPhysicalScreenSize())) / 768 -- px físicos por unidad
	holder:ClearAllPoints()
	holder:SetPoint('BOTTOMLEFT', _G.UIParent, 'BOTTOMLEFT', m.ws.x / unit, m.ws.y / unit)
	holder:SetSize(m.ws.w / unit, m.ws.h / unit)
	holder.unit = unit
	holder:Show()
	return unit
end

-- Ancla un mover de ElvUI a su zona (o lo devuelve a su lugar guardado).
local function PlaceMover(name, zone, point)
	local mover = _G[name]
	if not mover then return end
	local custom = DB().custom[name]
	if not mover.KnuCC then savedBefore[name] = E.db.movers and E.db.movers[name] end
	mover:ClearAllPoints()
	if custom then
		mover:SetPoint('BOTTOMLEFT', zone, 'BOTTOMLEFT', custom[1], custom[2])
	else
		mover:SetPoint(point or 'BOTTOMLEFT', zone, point or 'BOTTOMLEFT', 0, 0)
	end
	mover.KnuCC = true
end

local function RestoreMover(name)
	local mover = _G[name]
	if mover and mover.KnuCC then
		mover.KnuCC = nil
		if E.SetMoverPoints then pcall(E.SetMoverPoints, E, name) end
	end
end

local guideOrig, guideBusy, guideZone, guidePoint
local function HookGuideFlyouts()
	local W = _G.WoWPro
	if CC.flyoutHooked or not W or type(W.PositionFlyoutButton) ~= 'function' then return end
	CC.flyoutHooked = true
	hooksecurefunc(W, 'PositionFlyoutButton', function(_, button, row, useActive)
		if not (button and row and active and Dest('guide') == 'workspace') or InCombatLockdown() then return end
		button:ClearAllPoints()
		button:SetPoint('TOPRIGHT', row, 'TOPRIGHT', useActive and -38 or -4, -4)
	end)
	-- Reubicar los que ya están visibles.
	if W.rows and W.PositionTargetUseButtons then
		for _, row in ipairs(W.rows) do pcall(W.PositionTargetUseButtons, W, row) end
	end
end

local function PlaceGuide(zone, edge)
	pcall(HookGuideFlyouts)
	local g = _G.WoWPro and _G.WoWPro.MainFrame
	local log = _G.KnuUIDiag and _G.KnuUIDiag.calls
	if not g then if log then log[#log + 1] = 'CC guía: sin WoWPro.MainFrame' end return end
	if log then log[#log + 1] = format('CC guía: ubicando en %s (%s)', zone:GetName() or '?', tostring(edge)) end
	if not guideOrig and not g.KnuCC then guideOrig = { g:GetPoint(1) } end
	-- La guía crece hacia afuera del borde contiguo: abajo -> se ancla por abajo y crece hacia arriba.
	guidePoint = (edge == 'bottom') and 'BOTTOMLEFT' or 'TOPLEFT'
	guideZone = zone
	guideBusy = true
	g:ClearAllPoints()
	-- La guía cuelga de UIParent (escala de Offhand): el ancla en la zona deja su lugar en px correcto.
	g:SetPoint(guidePoint, zone, guidePoint, 0, 0)
	guideBusy = false
	g.KnuCC = true
	if K.PallyArrange then C_Timer.After(0, K.PallyArrange) end
	-- WoW-Pro vuelve a poner su posición guardada cuando redibuja la guía (WoWPro_Frames.lua): mientras
	-- dure el centro de comando, cada SetPoint ajeno se corrige.
	if not g.KnuCCHooked then
		g.KnuCCHooked = true
		hooksecurefunc(g, 'SetPoint', function(self)
			if guideBusy or not self.KnuCC or not guideZone or InCombatLockdown() then return end
			guideBusy = true
			self:ClearAllPoints()
			self:SetPoint(guidePoint, guideZone, guidePoint, 0, 0)
			guideBusy = false
		end)
	end
end

local function RestoreGuide()
	local g = _G.WoWPro and _G.WoWPro.MainFrame
	if not g or not g.KnuCC then return end
	g.KnuCC = nil
	guideBusy = true
	g:ClearAllPoints()
	if guideOrig and guideOrig[1] then
		g:SetPoint(guideOrig[1], guideOrig[2] or _G.UIParent, guideOrig[3] or guideOrig[1], guideOrig[4] or 0, guideOrig[5] or 0)
	else
		g:SetPoint('TOPLEFT', _G.UIParent, 'TOPLEFT', 8, -8)
	end
	guideOrig = nil -- el próximo ciclo toma la posición vigente (revisión de Codex)
	guideBusy = false
end

-- Tamaños en el monitor de trabajo: chat y Details (E.db.chat.panelWidth/Height y *Right, que ElvUI usa en
-- LO:ToggleChatPanels, Layout.lua:205-211; el acople de Details de KnuUI sigue el tamaño del panel,
-- Dock.lua:779), barra de datos (E.global.datatexts.customPanels.KnuUI_Data.width, DataTexts.lua:723) y
-- guía (WoWPro.SetMainFrameSize sin persistir, WoWPro_Frames.lua:78-81). Tus valores se guardan en
-- E.db.KnuUICC.sizeOrig y vuelven al salir del centro de comando (o en la carga siguiente sin Offhand).
local function RelayoutPanels()
	local LO = E.GetModule and E:GetModule('Layout', true)
	local CH = E.GetModule and E:GetModule('Chat', true)
	local DT = E.GetModule and E:GetModule('DataTexts', true)
	if LO and LO.ToggleChatPanels then pcall(LO.ToggleChatPanels, LO) end
	if CH and CH.PositionChats then pcall(CH.PositionChats, CH) end
	local settings = E.global.datatexts and E.global.datatexts.customPanels and E.global.datatexts.customPanels.KnuUI_Data
	-- El ancho lo aplica DT:UpdatePanelAttributes(name, db) (DataTexts.lua:710-723); UpdatePanelInfo sólo
	-- reparte los textos (visto en el juego: con UpdatePanelInfo la barra quedaba con el ancho viejo).
	if DT and DT.UpdatePanelAttributes and settings and DataPanel() then pcall(DT.UpdatePanelAttributes, DT, 'KnuUI_Data', settings) end
	if DT and DT.UpdatePanelInfo and DataPanel() then pcall(DT.UpdatePanelInfo, DT, 'KnuUI_Data') end
	local mover = _G.DTPanelKnuUI_DataMover
	if mover and settings and settings.width then mover:SetWidth(settings.width) end
end

function CC:ApplySizes(rects)
	if InCombatLockdown() then return end
	local db = DB()
	local chat = E.db.chat
	local panel = E.global.datatexts and E.global.datatexts.customPanels and E.global.datatexts.customPanels.KnuUI_Data
	if not rects then
		local o = db.sizeOrig
		if not o then return end
		chat.panelWidth, chat.panelHeight = o.panelWidth, o.panelHeight
		chat.panelWidthRight, chat.panelHeightRight = o.panelWidthRight, o.panelHeightRight
		chat.separateSizes = o.separateSizes
		if panel and o.dataWidth then panel.width = o.dataWidth end
		db.sizeOrig = nil
		RelayoutPanels()
		local g = _G.WoWPro and _G.WoWPro.MainFrame
		local WP = _G.WoWProDB and _G.WoWProDB.profile
		if WP and o.autoresize ~= nil then WP.autoresize = o.autoresize end
		if g and o.guideW and _G.WoWPro.SetMainFrameSize then pcall(_G.WoWPro.SetMainFrameSize, o.guideW, o.guideH or g:GetHeight()) end
		if _G.WoWPro and _G.WoWPro.UpdateGuide then pcall(_G.WoWPro.UpdateGuide, _G.WoWPro) end
		return
	end
	if not db.sizeOrig then
		local g = _G.WoWPro and _G.WoWPro.MainFrame
		db.sizeOrig = { panelWidth = chat.panelWidth, panelHeight = chat.panelHeight, panelWidthRight = chat.panelWidthRight,
			panelHeightRight = chat.panelHeightRight, separateSizes = chat.separateSizes, dataWidth = panel and panel.width,
			guideW = g and g:GetWidth(), guideH = g and g:GetHeight(),
			autoresize = _G.WoWProDB and _G.WoWProDB.profile and _G.WoWProDB.profile.autoresize }
	end
	local o = db.sizeOrig
	local cOn, dOn = Dest('chat') == 'workspace', Dest('details') == 'workspace'
	chat.separateSizes = true
	chat.panelWidth = cOn and math.floor(rects.chat.w) or o.panelWidth
	chat.panelHeight = cOn and math.floor(rects.chat.h) or o.panelHeight
	chat.panelWidthRight = dOn and math.floor(rects.details.w) or (o.panelWidthRight or o.panelWidth)
	chat.panelHeightRight = dOn and math.floor(rects.details.h) or (o.panelHeightRight or o.panelHeight)
	if panel then panel.width = Dest('data') == 'workspace' and math.floor(rects.data.w) or o.dataWidth end
	RelayoutPanels()
	local g = _G.WoWPro and _G.WoWPro.MainFrame
	if g and Dest('guide') == 'workspace' and _G.WoWPro.SetMainFrameSize then
		-- La guía cuelga de UIParent (escala de Offhand): el ancho de la zona se pasa a sus unidades.
		local k = holder:GetEffectiveScale() / g:GetEffectiveScale()
		-- Misma altura que chat y Details (pedido del user): WoW-Pro ajusta el alto al contenido con
		-- autoresize (WoWPro_Frames.lua:960-966); se apaga mientras dure el centro de comando.
		local WP = _G.WoWProDB and _G.WoWProDB.profile
		if WP then WP.autoresize = false end
		CC.guideSize = { rects.guide.w * k, rects.guide.h * k }
		if not CC.guideSizeHooked then
			CC.guideSizeHooked = true
			local busy = false
			hooksecurefunc(_G.WoWPro, 'SetMainFrameSize', function(w, h, persist)
				local s = CC.guideSize
				if busy or persist or not s or not active or Dest('guide') ~= 'workspace' or InCombatLockdown() then return end
				if math.abs((w or 0) - s[1]) < 1 and math.abs((h or 0) - s[2]) < 1 then return end
				busy = true
				pcall(_G.WoWPro.SetMainFrameSize, s[1], s[2])
				busy = false
			end)
		end
		pcall(_G.WoWPro.SetMainFrameSize, rects.guide.w * k, rects.guide.h * k)
		if _G.WoWPro.UpdateGuide then pcall(_G.WoWPro.UpdateGuide, _G.WoWPro) end
	end
end

-- Monitor de juego con el centro de comando (pedido del user 2026-11-13):
-- * con la barra de datos arriba, todo el bloque de abajo baja 24 px (lo que ocupaba la barra: y 2-24,
--   Layout.lua DTPanelKnuUI_DataMover) y queda a 4 px del borde, como el resto;
-- * con Details arriba, el bloque derecho vuelve a 6x4 (el compacto 3x4 le daba 129 px a Details,
--   Tanks.lua SIDES/FREED): se apaga KnuUICompactRight y se reaplican las columnas; al salir vuelve;
-- * el tooltip va abajo a la derecha (TooltipMover), a 4 px de los bordes.
local DATA_H = 24
local function UpdateBars()
	local AB = E.GetModule and E:GetModule('ActionBars', true)
	if AB and AB.UpdateButtonSettings then pcall(AB.UpdateButtonSettings, AB) end
	if E.UpdateActionBars then pcall(E.UpdateActionBars, E) end
	if E.SetMoversPositions then pcall(E.SetMoversPositions, E) end
end

function CC:ApplyGame(on)
	if InCombatLockdown() then return end
	local db = DB()
	local changedBars = false
	-- 1) bajar el bloque
	local shift = (on and Dest('data') == 'workspace' and Dest('chat') == 'workspace' and Dest('details') == 'workspace') and DATA_H or 0
	if (K.CCBottomShift or 0) ~= shift then
		K.CCBottomShift = shift
		if K.OffhandFit then K:OffhandFit() end
	end
	-- 2) bloque derecho
	local wantWide = on and Dest('details') == 'workspace' and E.db.KnuUITanks and (E.db.KnuUICompactRight or db.compactRightOrig ~= nil)
	if wantWide and db.compactRightOrig == nil and E.db.KnuUICompactRight and K.ApplyTanks then
		db.compactRightOrig = true
		E.db.KnuUICompactRight = false
		pcall(K.ApplyTanks, K, true)
		UpdateBars()
		changedBars = true
	elseif not wantWide and db.compactRightOrig ~= nil and K.ApplyTanks then
		E.db.KnuUICompactRight = db.compactRightOrig
		db.compactRightOrig = nil
		pcall(K.ApplyTanks, K, true)
		UpdateBars()
		changedBars = true
	end
	-- 3) tooltip abajo a la derecha del monitor de juego. ElvUI pega el tooltip al panel derecho (Details)
	-- mientras su mover no tenga posición guardada (Tooltip.lua:177, HasMoverBeenMoved('TooltipMover')): con
	-- Details arriba el tooltip se iba al monitor de trabajo. Se le da una posición guardada mientras dure el
	-- centro de comando; la tuya (o ninguna) vuelve al salir (E.db.KnuUICC.ttOrig).
	if on and Dest('details') == 'workspace' then
		if db.ttOrig == nil then db.ttOrig = (E.db.movers and E.db.movers.TooltipMover) or false end
		E.db.movers = E.db.movers or {}
		local want = format('BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-4,%d', 4 + shift)
		if E.db.movers.TooltipMover ~= want then
			E.db.movers.TooltipMover = want
			if E.SetMoverPoints then pcall(E.SetMoverPoints, E, 'TooltipMover') end
		end
	elseif db.ttOrig ~= nil then
		E.db.movers.TooltipMover = db.ttOrig or nil
		db.ttOrig = nil
		if E.SetMoverPoints then pcall(E.SetMoverPoints, E, 'TooltipMover') end
	end
	return changedBars
end

-- Pedidos del user (2026-11-13) para el monitor de trabajo:
-- * margen: nada pegado al borde ni encima del marco que dibuja Offhand alrededor del lienzo
--   (OffhandCanvasFrame, tema con insets de 11-12 px: Offhand/UI/Themes.lua:21-27,240-256): margen =
--   inset del marco + 4;
-- * letra más grande arriba: chat (E.db.chat.fontSize), Details (fila y texto, Skins/Details.lua) y
--   guía de WoW-Pro (WoWProDB.profile.stepfontsize/notefontsize + WoWPro.RowFontSet, WoWPro_Config.lua:675-745);
--   tus valores se guardan en E.db.KnuUICC.fontOrig y vuelven al salir;
-- * los botones del ojo (Fade.lua: KnuUI_ChatClear, KnuUI_DetailsKeep) no hacen falta arriba;
-- * bolsas (Baganator, Baganator/ViewManagement/Initialize.lua:152-154) y paneles de Blizzard
--   (personaje, hechizos, profesiones...) se abren arriba, centrados sobre el mapa y más grandes;
-- * el mapa se abre centrado en vos con un poco más de zoom (OpenMap API.GetView/ShowWorld/WorldFromMap,
--   OpenMap/API.lua:38-98).
local FONT_UP = 4 -- +2 y después otros +2 (pedidos del user 2026-11-13)
function CC.WorkspaceMargin()
	local c = _G.OffhandCanvasFrame
	local bd = c and c.GetBackdrop and c:GetBackdrop()
	local i = bd and bd.insets
	local inset = i and math.max(i.left or 0, i.right or 0, i.top or 0, i.bottom or 0) or 0
	if c and c.IsShown and not c:IsShown() then inset = 0 end
	return inset + 4
end

function CC:ApplyFonts(on)
	if InCombatLockdown() then return end
	local db = DB()
	local W = _G.WoWProDB and _G.WoWProDB.profile
	if on then
		if not db.fontOrig then
			db.fontOrig = { chat = E.db.chat.fontSize, step = W and W.stepfontsize, note = W and W.notefontsize }
		end
		local o = db.fontOrig
		if Dest('chat') == 'workspace' and o.chat then E.db.chat.fontSize = o.chat + FONT_UP end
		if Dest('details') == 'workspace' then K.CCDetailsFont, K.CCDetailsRow = 12 + FONT_UP, 16 + FONT_UP + 2 end
		local dp = E.db.datatexts and E.db.datatexts.panels and E.db.datatexts.panels.KnuUI_Data
		if dp and Dest('data') == 'workspace' then
			if o.dataFonts == nil then o.dataFonts = dp.fonts and E:CopyTable({}, dp.fonts) or false end
			local base = tonumber(E.db.datatexts.fontSize) or 12
			dp.fonts = { enable = true, font = E.db.datatexts.font, fontSize = base + FONT_UP, fontOutline = E.db.datatexts.fontOutline }
		end
		if W and Dest('guide') == 'workspace' then
			if o.step then W.stepfontsize = o.step + FONT_UP end
			if o.note then W.notefontsize = o.note + FONT_UP end
		end
	else
		local o = db.fontOrig
		if not o then return end
		if o.chat then E.db.chat.fontSize = o.chat end
		local dp = E.db.datatexts and E.db.datatexts.panels and E.db.datatexts.panels.KnuUI_Data
		if dp and o.dataFonts ~= nil then dp.fonts = o.dataFonts or nil end
		if W then
			if o.step then W.stepfontsize = o.step end
			if o.note then W.notefontsize = o.note end
		end
		K.CCDetailsFont, K.CCDetailsRow = nil, nil
		db.fontOrig = nil
	end
	local CH = E.GetModule and E:GetModule('Chat', true)
	if CH and CH.SetupChat then pcall(CH.SetupChat, CH) end
	local D = _G.Details
	if D and D.GetInstance and K.SkinDetails then
		for i = 1, 4 do
			local inst = D:GetInstance(i)
			if inst then pcall(K.SkinDetails, K, inst) end
		end
	end
	if _G.WoWPro and _G.WoWPro.RowFontSet then pcall(_G.WoWPro.RowFontSet) end
	if _G.WoWPro and _G.WoWPro.UpdateGuide then pcall(_G.WoWPro.UpdateGuide, _G.WoWPro) end
end

-- Chat de Offhand (dockChat): Offhand reubica ChatFrame1 con HUD:AlignChatFrame (Offhand/Core/SeamRedirect.lua:121)
-- porque no reconoce a ElvUI como dueño del chat; al subir de nivel lo sacó del panel de arriba (visto en el
-- juego 2026-11-13). Con el chat en el monitor de trabajo se apaga; al restaurar vuelve tu valor.
function CC:ApplyOffhandChat(on)
	local off = _G.Offhand
	local odb = off and off.db
	if type(odb) ~= 'table' then return end
	local db = DB()
	if on and Dest('chat') == 'workspace' then
		if db.dockChatOrig == nil then db.dockChatOrig = (odb.dockChat ~= false) end
		odb.dockChat = false
	elseif db.dockChatOrig ~= nil then
		odb.dockChat = db.dockChatOrig
		db.dockChatOrig = nil
	end
end

function CC:ApplyEyes(on)
	for _, name in ipairs({ 'KnuUI_ChatClear', 'KnuUI_DetailsKeep' }) do
		local b = _G[name]
		if b then
			if on then b.KnuCCHidden = true; b:SetAlpha(0); b:EnableMouse(false)
			elseif b.KnuCCHidden then b.KnuCCHidden = nil; b:SetAlpha(1); b:EnableMouse(true) end
		end
	end
	-- Sin los botones, arriba nada se atenúa: Details siempre visible y chat sin atenuar (Fade.lua lee
	-- E.db.KnuUIDetailsKeep y E.db.KnuUIChatClear); tus valores vuelven al salir.
	local db = DB()
	if on and not db.fadeOrig then
		db.fadeOrig = { keep = E.db.KnuUIDetailsKeep or false, clear = E.db.KnuUIChatClear or false }
		E.db.KnuUIDetailsKeep, E.db.KnuUIChatClear = true, false
		if K.UpdatePanelFade then pcall(K.UpdatePanelFade, K) end
	elseif not on and db.fadeOrig then
		E.db.KnuUIDetailsKeep, E.db.KnuUIChatClear = db.fadeOrig.keep, db.fadeOrig.clear
		db.fadeOrig = nil
		if K.UpdatePanelFade then pcall(K.UpdatePanelFade, K) end
	end
end

-- Paneles que se abren arriba, centrados sobre el mapa y un 25 % más grandes.
local PANELS = { 'CharacterFrame', 'PlayerSpellsFrame', 'SpellBookFrame', 'PlayerTalentFrame', 'TalentFrame',
	'ProfessionsFrame', 'ProfessionsBookFrame', 'TradeSkillFrame', 'CraftFrame', 'AchievementFrame',
	'CollectionsJournal', 'EncounterJournal', 'FriendsFrame', 'PVEFrame', 'CommunitiesFrame', 'MacroFrame',
	'KeyBindingFrame', 'HonorFrame', 'WhatsTrainingFrame' }
local PANEL_SCALE = 1.25
local function CenterPanel(f)
	if not active or InCombatLockdown() or not f or not f:IsShown() or (f.IsProtected and f:IsProtected()) then return end
	local z = zones.map or holder
	if not z then return end
	if f.KnuCCScale == nil then f.KnuCCScale = f:GetScale() end
	f:SetScale(f.KnuCCScale * PANEL_SCALE)
	f:ClearAllPoints()
	f:SetPoint('CENTER', z, 'CENTER', 0, 0)
end
local function HookPanels()
	for _, name in ipairs(PANELS) do
		local f = _G[name]
		if f and not f.KnuCCPanelHooked then
			f.KnuCCPanelHooked = true
			-- Después de que el juego u Offhand la ubiquen (Offhand guarda la posición donde la soltaste).
			f:HookScript('OnShow', function(self) C_Timer.After(0.15, function() CenterPanel(self) end) end)
		end
	end
	for _, prefix in ipairs({ 'Baganator_SingleViewBackpackViewFrame', 'Baganator_CategoryViewBackpackViewFrame' }) do
		for _, group in ipairs({ '', 'blizzard', 'dark', 'elvui', 'gw2', 'ndui', 'custom', 'Blizzard', 'Dark', 'ElvUI' }) do
			local f = _G[prefix .. group]
			if f and not f.KnuCCBagHooked then
				f.KnuCCBagHooked = true
				f:HookScript('OnShow', function(self)
					C_Timer.After(0.15, function()
						local z = zones.map
						if not active or Dest('bags') ~= 'workspace' or InCombatLockdown() or not z or not self:IsShown() then return end
						self:ClearAllPoints()
						-- Centradas en el panel de arriba (pedido del user 2026-11-13).
						self:SetPoint('CENTER', z, 'CENTER', 0, 0)
					end)
				end)
			end
		end
	end
end
local function UnscalePanels()
	if InCombatLockdown() then return end
	for _, name in ipairs(PANELS) do
		local f = _G[name]
		if f and f.KnuCCScale then f:SetScale(f.KnuCCScale); f.KnuCCScale = nil end
	end
end

-- Mapa centrado en vos con un poco más de zoom que el que traía (x1,6), una vez por sesión; después
-- se respeta el zoom que dejes y sólo se centra en vos.
local mapZoom
local function CenterMapOnPlayer()
	local api = _G.OpenMapAPI -- global pública de OpenMap (OpenMap/API.lua:2-3)
	if not api or not api.ShowWorld or not api.GetView or not active or Dest('map') ~= 'workspace' then return end
	local uiMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit('player')
	local pos = uiMap and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(uiMap, 'player')
	if not pos then return end
	local ok, x, y = pcall(pos.GetXY, pos)
	if not ok or type(x) ~= 'number' then return end
	local u, v = api.WorldFromMap(uiMap, x, y)
	if not u then return end
	local _, _, z = api.GetView()
	if not mapZoom then mapZoom = (tonumber(z) or 1) * 1.6 end
	pcall(api.ShowWorld, u, v, mapZoom)
end
CC.CenterMapOnPlayer = CenterMapOnPlayer

-- Barra de datos de arriba con más datos (pedido del user: aprovechar el ancho nuevo). Los nombres son los
-- registrados en ElvUI (DT:RegisterDatatext: Location.lua, Time.lua, Experience.lua, Quests.lua, Mail.lua).
local EXTRA_DT = { 'Location', 'Time', 'Experience', 'Quests', 'Mail' }
function CC:ApplyDataTexts(on)
	if InCombatLockdown() then return end
	local db = DB()
	local panel = E.db.datatexts and E.db.datatexts.panels and E.db.datatexts.panels.KnuUI_Data
	local settings = E.global.datatexts and E.global.datatexts.customPanels and E.global.datatexts.customPanels.KnuUI_Data
	if not panel or not settings then return end
	if on and Dest('data') == 'workspace' then
		if not db.dataOrig then
			local slots = {}
			for i = 1, 16 do slots[i] = panel[i] end
			db.dataOrig = { numPoints = settings.numPoints, slots = slots }
		end
		local n = #EXTRA_DT
		local base = db.dataOrig.numPoints or 8
		settings.numPoints = base + n
		for i, name in ipairs(EXTRA_DT) do panel[base + i] = name end
	elseif db.dataOrig then
		settings.numPoints = db.dataOrig.numPoints
		for i = 1, 16 do panel[i] = db.dataOrig.slots[i] end
		db.dataOrig = nil
	else
		return
	end
	RelayoutPanels()
end

local applying, dirty, lastHeavy = false, false, nil
function CC:Apply()
	pending = false
	if applying then dirty = true return end
	applying = true
	local ok, err = pcall(self.ApplyNow, self)
	applying = false
	if not ok and _G.KnuUIDiag and _G.KnuUIDiag.calls then table.insert(_G.KnuUIDiag.calls, 'CC Apply: ' .. tostring(err)) end
	if dirty then dirty = false; C_Timer.After(0.2, function() CC:Apply() end) end
end

function CC:ApplyNow()
	if InCombatLockdown() then
		if frame then frame:RegisterEvent('PLAYER_REGEN_ENABLED') end
		return
	end
	local m = Metrics()
	if not m or E.db.KnuUICCEnabled == false then
		if active then self:Restore() else self:RestoreSaved() end
		-- revisión de Codex: cerrar con el centro activo dejaba el mapa en el monitor ausente
		return
	end
	PlaceHolder(m)
	local unit = holder.unit
	local W, H = holder:GetWidth(), holder:GetHeight()
	local edge = Edge(m.ws, m.game)
	local overlap
	if edge == 'left' or edge == 'right' then
		local o0 = math.max(m.ws.y, m.game.y) - m.ws.y
		local o1 = math.min(m.ws.y + m.ws.h, m.game.y + m.game.h) - m.ws.y
		overlap = { o0 / unit, o1 / unit }
	end
	M = CC.WorkspaceMargin() -- borde de Offhand + 4 px
	local rects = self:Layout(W, H, edge, overlap)
	M = 4
	self.edge, self.orientation = edge, (m.ws.w >= m.ws.h) and 'horizontal' or 'vertical'
	for id, rect in pairs(rects) do
		local z = Zone(id)
		z:ClearAllPoints()
		z:SetPoint('BOTTOMLEFT', holder, 'BOTTOMLEFT', math.floor(rect.x + 0.5), math.floor(rect.y + 0.5))
		z:SetSize(math.max(1, rect.w), math.max(1, rect.h))
	end
	for _, b in ipairs(CC.blocks) do
		local dest = Dest(b.id)
		if b.mover then
			if dest == 'workspace' then
				local point = 'BOTTOMLEFT'
				if b.id == 'details' then point = 'BOTTOMRIGHT' end
				if b.id == 'data' then point = 'BOTTOM' end
				PlaceMover(b.mover, Zone(b.id), point)
			else
				RestoreMover(b.mover)
			end
		elseif b.id == 'guide' then
			local ok, err = pcall(dest == 'workspace' and PlaceGuide or RestoreGuide, Zone('guide'), edge)
			if not ok and _G.KnuUIDiag and _G.KnuUIDiag.calls then table.insert(_G.KnuUIDiag.calls, 'CC guía: ' .. tostring(err)) end
		end
	end
	if self.ApplyMap then pcall(self.ApplyMap, self, Dest('map') == 'workspace' and Zone('map') or nil) end
	local dests = {}
	for _, b in ipairs(CC.blocks) do dests[#dests + 1] = Dest(b.id) end
	local heavyKey = table.concat({ Snapshot() or '', table.concat(dests, ','), tostring(M), tostring(FONT_UP), tostring(E.db.KnuUICCMapOnly), tostring(_G.WoWPro and _G.WoWPro.MainFrame ~= nil) }, '|')
	if heavyKey ~= lastHeavy or not active then
		lastHeavy = heavyKey
		pcall(self.ApplySizes, self, rects)
		local changed = self:ApplyGame(true)
		pcall(self.ApplyFonts, self, true)
		pcall(self.ApplyDataTexts, self, true)
		if changed then pcall(self.ApplySizes, self, rects) end -- ApplyTanks reescribe anchos de chat/datos
		pcall(self.ApplyEyes, self, true)
		pcall(self.ApplyOffhandChat, self, true)
		pcall(HookPanels)
	end
	pcall(self.MapOnly, self, active and E.db.KnuUICCMapOnly ~= false and Dest('map') == 'workspace')
	if self.ApplyBags then pcall(self.ApplyBags, self, Dest('bags') == 'workspace' and Zone('bags') or nil) end
	if self.ApplyFrame then pcall(self.ApplyFrame, self, rects) end
	if K.ScaleMovers then pcall(K.ScaleMovers) end
	local wasActive = active
	active = true
	if not wasActive then pcall(CC.RefreshDynamicCam) end
	signature = Snapshot()
end

-- Devuelve lo que el centro de comando cambió en tus perfiles (tamaños, letra, datos, mapa, tooltip, bloque
-- derecho) aunque no esté activo. Se usa al entrar sin Offhand o sin el estirado: si el juego se cerró con el
-- centro activo, esos valores quedaron guardados (visto en el juego 2026-11-13: sin Offhand, chat y Details
-- quedaron con el tamaño del monitor de arriba y la guía con la letra grande).
function CC:RestoreSaved()
	local d = DB()
	if d.mapOrig then pcall(self.ApplyMap, self, nil) end
	if d.compactRightOrig ~= nil or d.ttOrig ~= nil then pcall(self.ApplyGame, self, false) end
	if d.fontOrig then pcall(self.ApplyFonts, self, false) end
	if d.dataOrig then pcall(self.ApplyDataTexts, self, false) end
	if d.fadeOrig then pcall(self.ApplyEyes, self, false) end
	if d.dockChatOrig ~= nil then pcall(self.ApplyOffhandChat, self, false) end
	if d.sizeOrig then pcall(self.ApplySizes, self, nil) end
end

function CC:Restore()
	lastHeavy = nil
	CC.guideSize = nil
	active = false -- antes de restaurar: el hook de SetMoverPoints no tiene que volver a encolar
	signature = nil
	for _, b in ipairs(CC.blocks) do
		if b.mover then RestoreMover(b.mover) end
	end
	pcall(RestoreGuide)
	pcall(self.ApplyFonts, self, false)
	pcall(self.ApplyDataTexts, self, false)
	pcall(self.ApplyEyes, self, false)
	pcall(self.ApplyOffhandChat, self, false)
	pcall(UnscalePanels)
	pcall(self.ApplyGame, self, false)
	pcall(self.ApplySizes, self, nil)
	if K.PallyArrange then C_Timer.After(0, K.PallyArrange) end
	if self.ApplyMap then pcall(self.ApplyMap, self, nil) end
	if self.ApplyBags then pcall(self.ApplyBags, self, nil) end
	if holder then holder:Hide() end
	active = false
	signature = nil
end

-- Mapa (OpenMap). OpenMap guarda dónde va la ventana del mapa en su propia configuración
-- (OpenMap/Map/Window.lua:14-17: window = { point, relPoint, x, y } relativo a UIParent, windowSize,
-- windowScale) y la vuelve a poner cada vez que algo la mueve (Window.lua:54-73, 269-275). Offhand
-- abandona el mapa cuando lo maneja OpenMap (revisión de Codex: CanvasCompatibility.lua:113). Acá se
-- escribe la zona del mapa en esos valores mientras dura el centro de comando; los tuyos se guardan en
-- E.db.KnuUICC.mapOrig y vuelven al salir.
function CC:ApplyMap(zone)
	local db = _G.OpenMapDB and _G.OpenMapDB.worldmap
	if not db then return end
	local cc = DB()
	if not zone then
		if cc.mapOrig then
			db.window = cc.mapOrig.window or false
			db.windowSize = cc.mapOrig.windowSize or false
			db.windowScale = cc.mapOrig.windowScale or 1
			local eff = cc.mapOrig.eff
			cc.mapOrig = nil
			CC.PlaceMapNow()
			-- Sin lugar guardado en OpenMap (window = false) PlaceMapNow no mueve nada: se repone el lugar y
			-- tamaño que tenía el mapa antes del centro de comando (revisión de Codex).
			local map = _G.WorldMapFrame
			if eff and map and not InCombatLockdown() and not db.window then
				map:ClearAllPoints()
				map:SetPoint(eff[1], _G.UIParent, eff[2], eff[3], eff[4])
				if eff[5] and not db.windowSize then map:SetSize(eff[5], eff[6]) end
			end
		end
		return
	end
	if not cc.mapOrig then
		cc.mapOrig = { window = db.window, windowSize = db.windowSize, windowScale = db.windowScale }
		local map = _G.WorldMapFrame
		if map and map:GetNumPoints() >= 1 then
			local p, _, rp, x, y = map:GetPoint(1)
			cc.mapOrig.eff = { p, rp, x or 0, y or 0, map:GetWidth(), map:GetHeight() }
		end
	end
	local ui = _G.UIParent
	local zs = zone:GetEffectiveScale() / ui:GetEffectiveScale() -- unidades de la zona -> de UIParent
	local scale = tonumber(db.windowScale) or 1
	local left, top = zone:GetLeft(), zone:GetTop()
	if not left or not top then return end
	local w = math.max(480, zone:GetWidth() * zs / scale)
	local h = math.max(320, zone:GetHeight() * zs / scale)
	db.window = { 'TOPLEFT', 'BOTTOMLEFT', left * zs / scale, top * zs / scale }
	db.windowSize = { math.floor(w), math.floor(h) }
	CC.mapBase = { window = { 'TOPLEFT', 'BOTTOMLEFT', left * zs / scale, top * zs / scale }, size = { math.floor(w), math.floor(h) } }
	CC.PlaceMapNow()
end

-- OpenMap reaplica su lugar guardado cuando algo llama a SetPoint/SetSize del mapa (Window.lua:269-275),
-- no con ClearAllPoints: se ubica directo con los valores ya escritos y OpenMap los confirma.
-- Mapa "sólo mapa" en el monitor de trabajo (pedido del user 2026-11-13: "que sea solo mapa, sin los
-- demás extras"). El registro de misiones al costado lo abre o cierra Blizzard según el CVar
-- questLogOpen, que OpenMap sólo acompaña (OpenMap/Map/Window.lua:324-331): mientras dure el centro de
-- comando queda en 0 y el tuyo vuelve al salir (E.db.KnuUICC.questLogOpen). Los adornos de la ventana
-- (título y botones, BorderFrame; desplegables, NavBar; flecha del panel; agarre de OpenMap; botones y
-- coordenadas sobre el mapa) quedan invisibles y sin mouse; el lienzo (ScrollContainer, con los pines)
-- no se toca. Se cierra con M como siempre. Opción: E.db.KnuUICCMapOnly = false.
local stripped = {}
local function MapOnlyWanted()
	return active and E.db.KnuUICCMapOnly ~= false and Dest('map') == 'workspace'
end

local function StripMap()
	local map = _G.WorldMapFrame
	if not map or InCombatLockdown() or not MapOnlyWanted() or (map.IsMaximized and map:IsMaximized()) then return end
	local keep = map.ScrollContainer
	-- El registro de misiones (map.QuestLog) no se oculta: con L el juego abre este mismo mapa con el
	-- registro al costado y quedaba invisible (visto en el juego 2026-11-13). Con M no aparece porque
	-- questLogOpen queda en 0.
	for _, child in ipairs({ map:GetChildren() }) do
		if child ~= keep and child ~= map.QuestLog and not stripped[child] and not (child.IsProtected and child:IsProtected()) then
			stripped[child] = { alpha = child:GetAlpha(), mouse = child.IsMouseEnabled and child:IsMouseEnabled() }
			child:SetAlpha(0)
			if child.EnableMouse then pcall(child.EnableMouse, child, false) end
		end
	end
	if CC.FitMapToZone then CC.FitMapToZone() end
	-- Lo que va encima del lienzo (botones de seguimiento, coordenadas de OpenMap) cuelga de él o del mapa.
	for _, child in ipairs({ keep and keep:GetChildren() or nil }) do
		local name = child.GetName and child:GetName() or ''
		-- Todo lo que no es el lienzo: botones de seguimiento y la barra de coordenadas de OpenMap (un Frame
		-- hijo del ScrollContainer, OpenMap/Map/Extras.lua:206; en el juego quedaba "Jugador x, y").
		if child ~= (keep.Child) and not stripped[child] and not name:find('Canvas')
			and not (child.IsProtected and child:IsProtected()) then
			stripped[child] = { alpha = child:GetAlpha(), mouse = child.IsMouseEnabled and child:IsMouseEnabled() }
			child:SetAlpha(0)
			pcall(child.EnableMouse, child, false)
		end
	end
end

local function UnstripMap()
	if InCombatLockdown() then return end
	for child, st in pairs(stripped) do
		pcall(child.SetAlpha, child, st.alpha or 1)
		if st.mouse ~= nil and child.EnableMouse then pcall(child.EnableMouse, child, st.mouse) end
		stripped[child] = nil
	end
end

function CC:MapOnly(on)
	local db = DB()
	if on then
		if db.questLogOpen == nil then db.questLogOpen = GetCVar('questLogOpen') or '1' end
		SetCVar('questLogOpen', '0')
		local map = _G.WorldMapFrame
		if map and not map.KnuCCStripHooked then
			map.KnuCCStripHooked = true
			map:HookScript('OnShow', function() C_Timer.After(0, StripMap); C_Timer.After(0.3, CenterMapOnPlayer) end)
			-- Después de abrirlo con L (el juego pone questLogOpen en 1) la M vuelve a abrir sólo el mapa.
			map:HookScript('OnHide', function() if MapOnlyWanted() then SetCVar('questLogOpen', '0') end end)
			if map.QuestLog then
				map.QuestLog:HookScript('OnShow', function() C_Timer.After(0, function() if CC.FitMapToZone then CC.FitMapToZone() end end) end)
				map.QuestLog:HookScript('OnHide', function() C_Timer.After(0, function() if CC.FitMapToZone then CC.FitMapToZone() end end) end)
			end
		end
		if map and map:IsShown() then
			-- Ya abierto: se cierra el panel con la acción de Blizzard que usa su propia flecha.
			if map.QuestLog and map.QuestLog:IsShown() and map.HandleUserActionCloseSidePanel then pcall(map.HandleUserActionCloseSidePanel, map) end
			C_Timer.After(0, StripMap)
		end
	else
		UnstripMap()
		if db.questLogOpen ~= nil then
			SetCVar('questLogOpen', db.questLogOpen)
			db.questLogOpen = nil
		end
	end
end

-- Que el mapa (y el registro de misiones, si está abierto) no pise el borde de Offhand ni la barra de datos
-- (vistos en el juego 2026-11-13: sin registro el lienzo se estiraba más allá de la ventana; con registro,
-- el registro pasaba el borde derecho y su búsqueda subía hasta la barra). Se vuelve al tamaño de la zona,
-- se mide lo que sobresale del lienzo y del registro y se achica/corre la ventana lo justo.
function CC.FitMapToZone()
	local db = _G.OpenMapDB and _G.OpenMapDB.worldmap
	local map, z, base = _G.WorldMapFrame, zones.map, CC.mapBase
	if not (db and map and z and base and active and Dest('map') == 'workspace') or InCombatLockdown() then return end
	db.window = { base.window[1], base.window[2], base.window[3], base.window[4] }
	db.windowSize = { base.size[1], base.size[2] }
	CC.PlaceMapNow()
	C_Timer.After(0, function()
		if not map:IsShown() or InCombatLockdown() then return end
		local ql, sc = map.QuestLog, map.ScrollContainer
		if ql and sc and ql:IsShown() and ql:GetLeft() and sc:GetTop() then
			-- Registro de misiones alineado arriba y abajo con el lienzo (pedido del user 2026-11-13: quedaba
			-- más alto arriba y más bajo abajo que el mapa). Se ancla al mapa con desplazamientos medidos, no al
			-- lienzo, para no crear una dependencia circular si el lienzo cuelga del registro.
			local qs, ss, mps = ql:GetEffectiveScale(), sc:GetEffectiveScale(), map:GetEffectiveScale()
			local mR, mT, mB = map:GetRight() * mps, map:GetTop() * mps, map:GetBottom() * mps
			local l, rr = ql:GetLeft() * qs, ql:GetRight() * qs
			local t, bt = sc:GetTop() * ss, sc:GetBottom() * ss
			ql:ClearAllPoints()
			ql:SetPoint('TOPRIGHT', map, 'TOPRIGHT', (rr - mR) / qs, (t - mT) / qs)
			ql:SetPoint('BOTTOMLEFT', map, 'BOTTOMRIGHT', (l - mR) / qs, (bt - mB) / qs)
			-- Las pestañas que Blizzard pone a la derecha del registro pisaban el borde de Offhand (pedido del
			-- user 2026-11-13: borrarlas). Se esconden los marcos chicos que empiezan a la derecha del registro.
			for _, parent in ipairs({ map, ql, map.BorderFrame }) do
				if parent and parent.GetChildren then
					for _, c in ipairs({ parent:GetChildren() }) do
						local cl, cw = c:GetLeft(), c:GetWidth()
						if c ~= ql and c ~= sc and cl and cw and cw < 80 and cl * c:GetEffectiveScale() >= rr - 2
							and not (c.IsProtected and c:IsProtected()) then
							c:Hide()
							if not c.KnuCCTabHook then
								c.KnuCCTabHook = true
								c:HookScript('OnShow', function(self) if active and Dest('map') == 'workspace' then self:Hide() end end)
							end
						end
					end
				end
			end
		end
		local zs = z:GetEffectiveScale()
		local zr, zt, zb = z:GetRight() * zs, z:GetTop() * zs, z:GetBottom() * zs
		local right, top, bottom = -math.huge, -math.huge, math.huge
		for _, f in ipairs({ map.ScrollContainer, map.QuestLog }) do
			if f and f:IsShown() and f:GetRight() then
				local s = f:GetEffectiveScale()
				right = math.max(right, f:GetRight() * s)
				top = math.max(top, f:GetTop() * s)
				bottom = math.min(bottom, f:GetBottom() * s)
			end
		end
		if right == -math.huge then return end
		local ms = map:GetEffectiveScale() * (tonumber(db.windowScale) or 1) / map:GetScale() -- px por unidad de offset
		local u = map:GetEffectiveScale()
		local overR = math.max(0, right - zr) / u
		local overT = math.max(0, top - zt) / u
		local overB = math.max(0, zb - bottom) / u
		if overR < 0.5 and overT < 0.5 and overB < 0.5 then return end
		db.windowSize = { math.floor(base.size[1] - overR), math.floor(base.size[2] - overT - overB) }
		db.window = { base.window[1], base.window[2], base.window[3], base.window[4] - overT }
		CC.PlaceMapNow()
	end)
end

function CC.PlaceMapNow()
	local db = _G.OpenMapDB and _G.OpenMapDB.worldmap
	local map = _G.WorldMapFrame
	if not db or not map or InCombatLockdown() or (map.IsMaximized and map:IsMaximized()) then return end
	local w = db.window
	if type(w) == 'table' then
		map:ClearAllPoints()
		map:SetPoint(w[1], _G.UIParent, w[2], w[3], w[4])
	end
	local s = db.windowSize
	if type(s) == 'table' then map:SetSize(s[1], s[2]) end
end

-- Fondo temático del monitor de trabajo (encima del lienzo de Offhand, debajo de todo lo demás) con una
-- línea de acento sobre el borde que toca al monitor de juego.
function CC:ApplyFrame()
	if not holder then return end
	local t = K.GetTheme and K:GetTheme()
	if not t then return end
	local bg = holder.KnuBG
	if not bg then
		bg = holder:CreateTexture(nil, 'BACKGROUND', nil, -8)
		bg:SetAllPoints(holder)
		holder.KnuBG = bg
		local line = holder:CreateTexture(nil, 'BACKGROUND', nil, -7)
		holder.KnuLine = line
	end
	holder:SetFrameStrata('BACKGROUND')
	holder:SetFrameLevel(0)
	local c = t.backdropFade or t.backdrop or { r = 0, g = 0, b = 0 }
	bg:SetColorTexture(c.r, c.g, c.b, E.db.KnuUICCBackdrop == false and 0 or 0.92)
	local line = holder.KnuLine
	local a = t.accentDim or t.accent or { r = 1, g = 0.66, b = 0.18 }
	line:SetColorTexture(a.r, a.g, a.b, 0.9)
	line:ClearAllPoints()
	local e = CC.edge
	if e == 'bottom' then line:SetPoint('BOTTOMLEFT'); line:SetPoint('BOTTOMRIGHT'); line:SetHeight(2)
	elseif e == 'top' then line:SetPoint('TOPLEFT'); line:SetPoint('TOPRIGHT'); line:SetHeight(2)
	elseif e == 'left' then line:SetPoint('TOPLEFT'); line:SetPoint('BOTTOMLEFT'); line:SetWidth(2)
	else line:SetPoint('TOPRIGHT'); line:SetPoint('BOTTOMRIGHT'); line:SetWidth(2) end
end

-- Contornos y nombres de zona mientras se desbloquea para mover.
function CC:ShowZones(show)
	local t = K.GetTheme and K:GetTheme()
	for id, z in pairs(zones) do
		if show then
			if not z.KnuOutline then
				local o = CreateFrame('Frame', nil, z, 'BackdropTemplate')
				o:SetAllPoints(z)
				o:SetBackdrop({ edgeFile = E.media.blankTex, edgeSize = 1 })
				local fs = o:CreateFontString(nil, 'OVERLAY')
				fs:SetFont(E.media.normFont, 12, 'OUTLINE')
				fs:SetPoint('TOPLEFT', 4, -4)
				o.text = fs
				z.KnuOutline = o
			end
			local a = t and t.accent or { r = 1, g = 0.66, b = 0.18 }
			z.KnuOutline:SetBackdropBorderColor(a.r, a.g, a.b, 0.8)
			z.KnuOutline.text:SetText(byId[id] and byId[id].label or id)
			z.KnuOutline:Show()
		elseif z.KnuOutline then
			z.KnuOutline:Hide()
		end
	end
end

-- Vuelo con el centro de comando (pedido del user 2026-11-12: "arriba visible, abajo oculto").
-- DynamicCam oculta la interfaz con hideUI de la situación (perfil KnuUI: Taxi 160 con
-- hideEntireUI = true, lo que esconde también el monitor de trabajo, que cuelga de UIParent). En
-- DynamicCam:FadeOutUI(fadeOutTime, settings) (DynamicCam/Core.lua:476-546) la rama sin hideEntireUI
-- usa keepCustomFrames + customFramesToKeep (nombre = true) de LibHideUI. Mientras el centro de comando
-- está activo se le pasa una copia de esos ajustes con los marcos del monitor de trabajo; el perfil de
-- DynamicCam no se modifica.
function CC.OnWorkspace(f)
	if not f or not holder or not f.GetCenter or not holder:IsShown() then return false end
	local x, y = f:GetCenter()
	local l, b, w, h = holder:GetRect()
	if not x or not l then return false end
	local fs, hs = f:GetEffectiveScale(), holder:GetEffectiveScale()
	x, y = x * fs, y * fs
	return x >= l * hs and x <= (l + w) * hs and y >= b * hs and y <= (b + h) * hs
end

local KEEP = { 'KnuUI_Workspace', 'LeftChatPanel', 'RightChatPanel', 'DetailsBaseFrame1', 'DetailsBaseFrame2',
	'WoWProMainFrame', 'PallyPowerFrame', 'KnuUI_PallyGrid', 'WorldMapFrame', 'KnuUI_FlightTimer' }
local function HookDynamicCam()
	local dc = _G.DynamicCam
	if CC.dcHooked or not dc or type(dc.FadeOutUI) ~= 'function' then return end
	CC.dcHooked = true
	local orig = dc.FadeOutUI
	dc.FadeOutUI = function(self, fadeOutTime, settings)
		if active and type(settings) == 'table' and E.db.KnuUICCFlight ~= false then
			local copy = {}
			for k, v in pairs(settings) do copy[k] = v end
			copy.hideEntireUI = false
			-- Si iba a ocultar todo, el monitor de juego queda en 0 y no atenuado (revisión de Codex).
			if settings.hideEntireUI then copy.fadeOpacity = 0 end
			copy.keepCustomFrames = true
			-- LibHideUI oculta ChatFrameN aparte (LibHideUI.lua:78-84); con el chat arriba se conserva.
			if Dest('chat') == 'workspace' then copy.keepChatFrame = true end
			local keep = {}
			if type(settings.customFramesToKeep) == 'table' then for k, v in pairs(settings.customFramesToKeep) do keep[k] = v end end
			for _, name in ipairs(KEEP) do
				-- Sólo lo que de verdad está en el monitor de trabajo (centro del marco dentro del holder).
				if name == 'KnuUI_Workspace' or CC.OnWorkspace(_G[name]) then keep[name] = true end
			end
			local dp = DataPanel()
			if dp and dp:GetName() and CC.OnWorkspace(dp) then keep[dp:GetName()] = true end
			copy.customFramesToKeep = keep
			-- Los retratos 3D de ElvUI (frame.Portrait3D, UnitFrames/Elements/Portrait.lua:13) no respetan la
			-- transparencia de UIParent: con la interfaz atenuada (no oculta) quedaba el retrato del objetivo
			-- sobre el personaje (visto en el juego 2026-11-13). Se esconden hasta que vuelve la interfaz.
			if not InCombatLockdown() then
				for _, name in ipairs({ 'ElvUF_Player', 'ElvUF_Target', 'ElvUF_TargetTarget', 'ElvUF_Focus', 'ElvUF_Pet' }) do
					local uf = _G[name]
					local m = uf and uf.Portrait3D
					if m and m.IsShown and m:IsShown() then m:Hide(); m.KnuCCHidden = true end
				end
			end
			return orig(self, fadeOutTime, copy)
		end
		return orig(self, fadeOutTime, settings)
	end
end
CC.HookDynamicCam = HookDynamicCam

-- Si DynamicCam ya ocultó toda la interfaz (por ejemplo, recarga en pleno vuelo: entra en la situación
-- antes de que el centro de comando se active), se vuelve a aplicar con los marcos del monitor de trabajo.
-- DynamicCam:FadeOutUI(0, situación.hideUI) es la misma llamada que usa DynamicCam (Core.lua:400).
function CC.RefreshDynamicCam()
	local dc = _G.DynamicCam
	if not dc or _G.UIParent:IsShown() or InCombatLockdown() then return end
	local id = dc.currentSituationID
	local s = id and dc.db and dc.db.profile and dc.db.profile.situations and dc.db.profile.situations[id]
	if not (s and s.hideUI and s.hideUI.enabled) then return end
	dc:FadeInUI(0)
	dc:FadeOutUI(0, s.hideUI)
end

-- Al volver la interfaz (DynamicCam:FadeInUI, Core.lua:555) se muestran los retratos escondidos.
local function HookDynamicCamIn()
	local dc = _G.DynamicCam
	if CC.dcInHooked or not dc or type(dc.FadeInUI) ~= 'function' then return end
	CC.dcInHooked = true
	hooksecurefunc(dc, 'FadeInUI', function(_, fadeInTime)
		-- Con la interfaz atenuada (no oculta) LibHideUI devuelve la opacidad de cada marco al terminar;
		-- el rastreador de misiones, que KnuUI deja transparente con WoW-Pro (Skins/Objectives.lua:51-57),
		-- volvía a verse (visto en el juego 2026-11-13). Se reaplica después del fundido.
		if K.SkinTracker then C_Timer.After((tonumber(fadeInTime) or 0.5) + 0.3, function() K:SkinTracker() end) end
		for _, name in ipairs({ 'ElvUF_Player', 'ElvUF_Target', 'ElvUF_TargetTarget', 'ElvUF_Focus', 'ElvUF_Pet' }) do
			local uf = _G[name]
			local m = uf and uf.Portrait3D
			if m and m.KnuCCHidden and not InCombatLockdown() then m.KnuCCHidden = nil; m:Show() end
		end
	end)
end

local function Queue()
	if pending then return end
	pending = true
	C_Timer.After(0.2, function() CC:Apply() end)
end
CC.Queue = Queue

-- API para el menú (docs/knuui-final/PLAN.md).
function K:CC_IsActive() return active end
function K:CC_GetState()
	local db = DB()
	local blocks = {}
	for _, b in ipairs(CC.blocks) do blocks[b.id] = { dest = Dest(b.id), custom = b.mover and db.custom[b.mover] ~= nil or false, label = b.label } end
	return { active = active, orientation = CC.orientation, edge = CC.edge, preset = db.preset, blocks = blocks, unlocked = unlocked }
end
function K:CC_Presets() return CC.presets end
function K:CC_Blocks() return CC.blocks end
function K:CC_ApplyPreset(id)
	if not presetById[id] then return end
	local db = DB()
	db.preset = id
	wipe(db.blocks)
	Queue()
end
function K:CC_SetBlock(id, dest)
	if not byId[id] or (dest ~= 'game' and dest ~= 'workspace') then return end
	DB().blocks[id] = dest
	Queue()
end
function K:CC_Reset()
	local db = DB()
	wipe(db.custom)
	wipe(db.blocks)
	db.preset = 'full'
	Queue()
end
function K:CC_Unlock(state)
	unlocked = state and true or false
	if unlocked then
		if E.ToggleMoveMode then pcall(E.ToggleMoveMode, E) end
	elseif E.ToggleMoveMode and E.ConfigurationMode then
		pcall(E.ToggleMoveMode, E)
	end
	if CC.ShowZones then pcall(CC.ShowZones, CC, unlocked) end
end

-- Un arrastre (/moveui) en modo centro de comando no toca el diseño de una pantalla: ElvUI acaba de
-- escribir E.db.movers[name] (Movers.lua:381-386); se guarda la posición relativa a la zona y se
-- devuelve el valor anterior.
local function HookMovers()
	if CC.moversHooked or not E.SaveMoverPosition then return end
	CC.moversHooked = true
	hooksecurefunc(E, 'SaveMoverPosition', function(_, name)
		if not active then return end
		for _, b in ipairs(CC.blocks) do
			if b.mover == name and Dest(b.id) == 'workspace' then
				local mover, zone = _G[name], zones[b.id]
				if mover and zone and mover:GetLeft() and zone:GetLeft() then
					DB().custom[name] = { math.floor(mover:GetLeft() - zone:GetLeft() + 0.5), math.floor(mover:GetBottom() - zone:GetBottom() + 0.5) }
				end
				E.db.movers[name] = savedBefore[name]
				C_Timer.After(0, function() CC:Apply() end)
				return
			end
		end
	end)
	-- ElvUI reaplica todas las posiciones en cambios de perfil y al cerrar el modo mover
	-- (Movers.lua:500-510): se vuelve a anclar lo del centro de comando.
	hooksecurefunc(E, 'SetMoverPoints', function(_, name)
		if not active then return end
		for _, b in ipairs(CC.blocks) do
			if b.mover == name and Dest(b.id) == 'workspace' then Queue() return end
		end
	end)
end

function K:SetupWorkspace()
	if frame then return end
	if not (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded('Offhand')) then
		-- Sin Offhand: devolver lo que haya quedado guardado del centro de comando (una vez, al entrar,
		-- cuando ElvUI, WoW-Pro y Details ya armaron sus ventanas).
		local once = CreateFrame('Frame')
		once:RegisterEvent('PLAYER_ENTERING_WORLD')
		once:SetScript('OnEvent', function(self)
			self:UnregisterAllEvents()
			C_Timer.After(1, function()
				if InCombatLockdown() then return end
				pcall(CC.RestoreSaved, CC)
				if K.PallyArrange then pcall(K.PallyArrange) end
			end)
		end)
		return
	end
	frame = CreateFrame('Frame')
	frame:SetScript('OnEvent', function(_, event)
		if event == 'PLAYER_REGEN_ENABLED' then frame:UnregisterEvent('PLAYER_REGEN_ENABLED') end
		Queue()
	end)
	for _, ev in ipairs({ 'PLAYER_ENTERING_WORLD', 'UI_SCALE_CHANGED', 'DISPLAY_SIZE_CHANGED' }) do frame:RegisterEvent(ev) end
	hooksecurefunc(_G.UIParent, 'SetScale', Queue)
	local off = _G.Offhand
	if off and off.API and off.API.RegisterGeometryCallback then
		pcall(off.API.RegisterGeometryCallback, 'KnuUI', function() Queue() end)
	end
	-- Firma de rectángulos cada 2 s: Companion puede reescribir la topología sin evento de pantalla.
	C_Timer.NewTicker(2, function()
		local s = Snapshot()
		if s ~= signature then
			-- También ElvUI (Offhand.lua): sacar el estirado sin recargar lo dejaba con la geometría estirada.
			if K.OffhandFit then C_Timer.After(0.3, function() K:OffhandFit() end) end
			Queue() return
		end
		-- La guía de WoW-Pro puede aparecer después del primer acomodo: se reintenta hasta ubicarla.
		local g = _G.WoWPro and _G.WoWPro.MainFrame
		if active and g and not g.KnuCC and Dest('guide') == 'workspace' then Queue() end
	end)
	HookMovers()
	pcall(HookDynamicCam)
	local gp = _G.OffhandForeverGamepadMainMenuController
	if gp and GetCVar and GetCVar('GamePadEnable') == '0' and E.db.KnuUIOffhandGamepadScan ~= true then
		gp:Hide()
		if not gp.KnuHideHooked then
			gp.KnuHideHooked = true
			gp:HookScript('OnShow', function(self) if GetCVar('GamePadEnable') == '0' and E.db.KnuUIOffhandGamepadScan ~= true then self:Hide() end end)
		end
	end
	pcall(HookDynamicCamIn)
	-- Ventana de opciones de ElvUI/KnuUI (E:Config_GetWindow, ElvUI General/Config.lua:1115-1118): con el
	-- centro de comando abre en el monitor de trabajo, sobre la zona del mapa, y no tapa el juego.
	if E.ToggleOptions then
		hooksecurefunc(E, 'ToggleOptions', function()
			C_Timer.After(0, function()
				if not active or E.db.KnuUICCConfig == false or InCombatLockdown() then return end
				local f = E.Config_GetWindow and E:Config_GetWindow()
				local z = zones.map or holder
				if f and f:IsShown() and z then
					f:ClearAllPoints()
					f:SetPoint('TOP', z, 'TOP', 0, 0) -- por arriba: la ventana es más alta que la zona del mapa
				end
			end)
		end)
	end
	Queue()
end
