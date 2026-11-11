local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')
local S = E:GetModule('Skins')

-- Shortest Path Forever (v1.31.0). Su ventana propia es el panel "Servicios cercanos", una pestaña
-- del registro de misiones del mapa (UI/ServicesPanel.lua:613-626, ShortestPathForeverServicesPanel,
-- hijo de QuestMapFrame): fondo QuestLog-main-background (Art.CoverFrame), borde
-- QuestLogBorderFrameTemplate como primer hijo del cuerpo (:371), buscador SearchBoxTemplate (:327) y
-- ScrollFrameTemplate con su barra (:375-378).
-- KnuUI: fondo del tema opaco (el panel tapa la lista de misiones de abajo), borde y acento del tema,
-- el borde de Blizzard transparente (como hace ElvUI con DetailsFrame.BorderFrame, Skins/WorldMap.lua)
-- y buscador y barra de ElvUI.
-- La flecha, la brújula y los pasos en el rastreador de misiones no tienen fondo propio.

local function Walk(frame, fn, depth)
	depth = depth or 0
	if depth > 6 then return end
	for _, child in ipairs({ frame:GetChildren() }) do
		fn(child)
		Walk(child, fn, depth + 1)
	end
end

local function HasScrollFrame(frame)
	for _, c in ipairs({ frame:GetChildren() }) do
		if c:IsObjectType('ScrollFrame') then return true end
	end
	return false
end

-- Lo que se hace una sola vez: fondo de pergamino, borde de Blizzard, buscador y barra.
local function Dress(panel)
	-- Fondo de pergamino (capa BACKGROUND del panel, Art.CoverFrame).
	for _, r in ipairs({ panel:GetRegions() }) do
		if r:IsObjectType('Texture') and r:GetDrawLayer() == 'BACKGROUND' then r:SetAlpha(0) end
	end
	if K.KnuFrame then K:KnuFrame(panel) end
	-- Cuerpo (ServicesPanel.lua:368-372): el borde QuestLogBorderFrameTemplate se crea justo antes
	-- del visor, que es el que contiene el ScrollFrame.
	for _, body in ipairs({ panel:GetChildren() }) do
		local kids = { body:GetChildren() }
		for i = 2, #kids do
			if HasScrollFrame(kids[i]) then kids[i - 1]:SetAlpha(0) end
		end
	end
	Walk(panel, function(child)
		if child:IsObjectType('EditBox') and S.HandleEditBox and not child.KnuSkinned then
			child.KnuSkinned = true
			S:HandleEditBox(child)
		elseif child:IsObjectType('ScrollFrame') and child.ScrollBar and not child.ScrollBar.KnuSkinned then
			child.ScrollBar.KnuSkinned = true
			if child.ScrollBar.Track and S.HandleTrimScrollBar then
				S:HandleTrimScrollBar(child.ScrollBar)
			elseif S.HandleScrollBar then
				S:HandleScrollBar(child.ScrollBar)
			end
		end
	end)
end

-- En cada apertura (el motor de skins vuelve a poner el fondo semitransparente del tema): fondo
-- opaco, porque el panel tapa la lista de misiones que queda abajo.
local function StylePanel(panel)
	if not panel then return end
	if not panel.KnuSkinned then
		panel.KnuSkinned = true
		Dress(panel)
	end
	if panel.SetBackdropColor then
		local t = K:GetTheme()
		panel:SetBackdropColor(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, 1)
		panel:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
	end
end

-- Columna de ForeverCore (ForeverTrackerCompanion, ForeverCore/UI/TrackerHost.lua:123): ahí van la
-- sección "Viaje" de Shortest Path y las de otros addons Forever. Por defecto va pegada debajo del
-- rastreador de Blizzard (LayoutAttached, :563-627); con WoW-Pro, KnuUI deja ese rastreador invisible
-- pero sigue estirado hasta abajo (Skins/Objectives.lua), así que la columna caía sobre Details.
-- Con la API pública ForeverTrackerHost (:717-789, :1023) se pasa una vez por perfil a modo suelto, en
-- el lugar donde empieza el rastreador de Blizzard (arriba a la derecha), y se traba. SavePosition
-- guarda x e y en unidades de UIParent desde su esquina superior izquierda (LayoutDetached, :522-552).
local function PlaceColumn()
	local api, native = _G.ForeverTrackerHost, _G.ObjectiveTrackerFrame
	if E.db.KnuUIForeverColumnPlaced or InCombatLockdown() then return end
	if not (api and api.SetAttached and api.SavePosition and native and native:GetLeft()) then return end
	if not (E.db.KnuUIHideTracker ~= false and K:IsLoaded('WoWPro')) then return end
	local ui = UIParent:GetEffectiveScale()
	local ns = native:GetEffectiveScale()
	local x = native:GetLeft() * ns / ui
	local y = native:GetTop() * ns / ui - UIParent:GetTop()
	api.SetAttached(false)
	api.SavePosition(x, y)
	if api.SetLocked then api.SetLocked(true) end
	E.db.KnuUIForeverColumnPlaced = true
end

-- Estilo: sin el fondo de tooltip de ForeverCore (opacidad 0, :190-228) y con un marco de KnuUI detrás
-- que sigue el alto de la columna (ForeverCore lo ajusta al contenido, :508). Los títulos de sección
-- toman el color del tema y todos los textos Expressway; las líneas se crean de un pool a medida que
-- cambia el viaje, así que se revisan los textos nuevos mientras la columna está visible.
local fonted = setmetatable({}, { __mode = 'k' })
local function FontAll(frame, depth)
	depth = depth or 0
	if depth > 8 then return end
	for _, r in ipairs({ frame:GetRegions() }) do
		if r:IsObjectType('FontString') and not fonted[r] then
			fonted[r] = true
			local _, size, flags = r:GetFont()
			if r.FontTemplate then r:FontTemplate('Expressway', size or 12, flags or 'OUTLINE') end
		end
	end
	for _, c in ipairs({ frame:GetChildren() }) do FontAll(c, depth + 1) end
end

local function StyleHeaders(host)
	local t = K:GetTheme()
	for _, module in ipairs({ host:GetChildren() }) do
		local header = module.Header
		if header and header.Text then header.Text:SetTextColor(t.accent.r, t.accent.g, t.accent.b) end
	end
end

local function StyleColumn()
	local host, api = _G.ForeverTrackerCompanion, _G.ForeverTrackerHost
	if not host then return end
	if not host.KnuBackdrop then
		if api and api.SetBackdropOpacity then api.SetBackdropOpacity(0) end
		local bd = CreateFrame('Frame', nil, host, 'BackdropTemplate')
		bd:SetFrameLevel(math.max(0, host:GetFrameLevel() - 1))
		bd:SetPoint('TOPLEFT', host, 'TOPLEFT', -6, 6)
		bd:SetPoint('BOTTOMRIGHT', host, 'BOTTOMRIGHT', 6, -6)
		bd:SetTemplate('Transparent')
		if K.KnuFrame then K:KnuFrame(bd) end
		host.KnuBackdrop = bd
		local ticker
		host:HookScript('OnShow', function()
			if not ticker then ticker = C_Timer.NewTicker(1, function() pcall(FontAll, host); pcall(StyleHeaders, host) end) end
		end)
		host:HookScript('OnHide', function() if ticker then ticker:Cancel(); ticker = nil end end)
		if host:IsShown() then ticker = C_Timer.NewTicker(1, function() pcall(FontAll, host); pcall(StyleHeaders, host) end) end
	end
	local t = K:GetTheme()
	host.KnuBackdrop:SetBackdropColor(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, t.backdropFade.a)
	host.KnuBackdrop:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
	pcall(FontAll, host)
	pcall(StyleHeaders, host)
end

K:RegisterSkin('ShortestPathForever', function()
	-- El panel se crea cuando existe el registro de misiones (Attach, ServicesPanel.lua:613); se viste
	-- al crearse o, si ya existía, ahora.
	K:WatchAddonFrame('ShortestPathForever', 'ShortestPathForeverServicesPanel', function(panel) pcall(StylePanel, panel) end, true)
	pcall(StyleColumn)
	-- Brújula (ShortestPathForeverCompass, UI/Compass.lua:364, se crea al prenderla): letras, distancia
	-- y tiempo en la fuente del tema (:415, :447-448).
	local function Compass()
		local compass = _G.ShortestPathForeverCompass
		if compass then pcall(FontAll, compass) end
	end
	Compass()
	hooksecurefunc('CreateFrame', function(_, name)
		if name == 'ShortestPathForeverCompass' then C_Timer.After(0, Compass) end
	end)
	-- Después de que se ubiquen el rastreador de Blizzard (ElvUI/Edit Mode) y la columna.
	C_Timer.After(3, function() pcall(PlaceColumn) end)
end)
