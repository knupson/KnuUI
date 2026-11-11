local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')
local S = E:GetModule('Skins')

-- OpenMap (mapa del mundo continuo para Forever). Usa el WorldMapFrame de Blizzard, que ya skinea
-- ElvUI, y arma sus propias ventanas con unas pocas funciones de OpenMap.Look (Core.lua:195-290):
--   Look:Window  (Core.lua:250): marco de metal de Blizzard (NineSlicePanelTemplate) + fondo de roca
--                y sombra, título y botón X. Lo usan noticias, chinchetas, notas, reporte, dibujo, etc.
--   Look:Panel   (Core.lua:211): fondo oscuro con borde fino (frame.omBackdrop).
--   Look:Dropdown(Core.lua:232): fondo del menú desplegable de Blizzard (atlas common-dropdown-bg).
-- El menú de OpenMap (OpenMapMenu) se viste con una función local, Dress (Map/Panel.lua:431-458),
-- con el mismo marco y fondo que Look:Window.
-- KnuUI envuelve esas funciones: esconde sólo lo que ellas agregan (se compara qué texturas y marcos
-- había antes y después de llamarlas) y pone el fondo, borde, línea de acento y sombra del tema.

-- Cada envoltura respeta en el momento el interruptor general y la exclusión por addon
-- (Skins/Engine.lua, Enabled).
local function Active()
	if not E.Forever then return false end
	local db = E.db
	if not db then return true end -- todavía sin perfil: el valor por defecto es prendido
	return db.KnuUIAddonSkins ~= false and not (db.KnuUIAddonSkinsOff and db.KnuUIAddonSkinsOff.OpenMap)
end

local function Snapshot(frame)
	local regions, children = {}, {}
	for _, r in ipairs({ frame:GetRegions() }) do regions[r] = true end
	for _, c in ipairs({ frame:GetChildren() }) do children[c] = true end
	return regions, children
end

local function IsNineSlice(frame)
	return frame and (frame.TopLeftCorner ~= nil or frame.layoutType ~= nil)
end

local function IsCloseButton(button)
	if not (button and button.IsObjectType and button:IsObjectType('Button')) then return false end
	local tex = button:GetNormalTexture()
	local atlas = tex and tex.GetAtlas and tex:GetAtlas()
	return atlas == 'RedButton-Exit' or (button.GetName and (button:GetName() or ''):match('CloseButton$') ~= nil)
end

local function Theme(frame)
	if not frame.SetTemplate then return end
	frame:SetTemplate('Transparent')
	local t = K:GetTheme()
	frame:SetBackdropColor(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, t.backdropFade.a)
	frame:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
	if K.KnuFrame then K:KnuFrame(frame) end
end

-- Esconde lo agregado desde la foto "antes" (texturas y el marco de metal) y deja el resto.
local function Undress(frame, regions, children)
	for _, r in ipairs({ frame:GetRegions() }) do
		if not regions[r] and r:IsObjectType('Texture') then r:SetAlpha(0) end
	end
	for _, c in ipairs({ frame:GetChildren() }) do
		if not children[c] then
			if IsNineSlice(c) then c:Hide()
			elseif IsCloseButton(c) and S and S.HandleCloseButton then S:HandleCloseButton(c) end
		end
	end
end

-- Botones UIPanelButtonTemplate (rojos de Blizzard, con piezas Left/Middle/Right) y buscadores
-- SearchBoxTemplate que OpenMap agrega dentro de sus ventanas (p. ej. Map/Welcome.lua:46, Nav.lua:369).
-- Se buscan en el cuadro siguiente: las ventanas los crean después de llamar a Look:Window.
local function SkinControls(frame, depth)
	depth = depth or 0
	if not frame or depth > 6 then return end
	for _, c in ipairs({ frame:GetChildren() }) do
		if not c.KnuSkinned then
			if c:IsObjectType('Button') and c.Left and c.Middle and c.Right and S.HandleButton then
				c.KnuSkinned = true
				S:HandleButton(c, true)
			elseif c:IsObjectType('EditBox') and c.Instructions and not c.backdrop and S.HandleEditBox then
				c.KnuSkinned = true
				S:HandleEditBox(c)
			end
		end
		SkinControls(c, depth + 1)
	end
end

local function WrapWindow(Look)
	local original = Look.Window
	Look.Window = function(self, frame, ...)
		local regions, children = Snapshot(frame)
		local top, text, close = original(self, frame, ...)
		if not Active() then return top, text, close end
		pcall(function()
			Undress(frame, regions, children)
			Theme(frame)
			if text then K:SkinFont(text, true) end
			if close and S and S.HandleCloseButton and not close.KnuSkinned then
				close.KnuSkinned = true
				S:HandleCloseButton(close)
			end
			C_Timer.After(0, function() pcall(SkinControls, frame) end)
			frame:HookScript('OnShow', function(f) pcall(SkinControls, f) end)
		end)
		return top, text, close
	end
end

-- Coordenadas: OpenMap muestra las suyas en el mapa (caja "Jugador", Map/Extras.lua) y apaga las de
-- Blizzard para no duplicarlas (Extras.lua:30-34). ElvUI (ElvUI_CoordsHolder, Maps/WorldMap.lua:265)
-- y TomTom (TomTomWorldFrame, modules/map_coords.lua) agregaban otras dos: con OpenMap cargado se
-- vuelven invisibles en el mapa, sin tocar sus opciones guardadas.
local function HideOtherCoords()
	if not Active() then return end
	for _, name in ipairs({ 'ElvUI_CoordsHolder', 'TomTomWorldFrame' }) do
		local f = _G[name]
		if f then f:SetAlpha(0) end
	end
	if _G.WorldMapFrame then pcall(SkinControls, _G.WorldMapFrame) end
end

local function WrapPanel(Look)
	local original = Look.Panel
	Look.Panel = function(self, frame, opts, ...)
		local bd = original(self, frame, opts, ...)
		if not Active() then return bd end
		pcall(function()
			local t = K:GetTheme()
			bd:SetBackdropColor(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, (opts and opts.alpha) or 0.9)
			bd:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
		end)
		return bd
	end
end

local function WrapDropdown(Look)
	local original = Look.Dropdown
	Look.Dropdown = function(self, frame, ...)
		local regions, children = Snapshot(frame)
		local a, b, c, d = original(self, frame, ...)
		if not Active() then return a, b, c, d end
		pcall(function()
			Undress(frame, regions, children)
			Theme(frame)
		end)
		return a, b, c, d
	end
end

-- El menú: Dress pone el fondo de roca y la sombra en la capa BACKGROUND del propio menú y el marco
-- de metal como hijo NineSlice (Map/Panel.lua:431-450).
local function DressMenu()
	local menu = _G.OpenMapMenu
	if not menu or menu.KnuSkinned then return end
	menu.KnuSkinned = true
	for _, r in ipairs({ menu:GetRegions() }) do
		if r:IsObjectType('Texture') and r:GetDrawLayer() == 'BACKGROUND' then r:SetAlpha(0) end
	end
	for _, c in ipairs({ menu:GetChildren() }) do
		if IsNineSlice(c) then c:Hide()
		elseif IsCloseButton(c) and S and S.HandleCloseButton then S:HandleCloseButton(c) end
	end
	Theme(menu)
end

-- Se engancha apenas carga OpenMap (antes de que arme ventanas al entrar, como las novedades):
-- el motor de skins recién corre cuando arranca KnuUI.
local function Install()
	local ns = _G.OpenMap
	local Look = ns and ns.Look
	if type(Look) ~= 'table' or K.openMapWrapped then return K.openMapWrapped end
	K.openMapWrapped = true
	if type(Look.Window) == 'function' then WrapWindow(Look) end
	if type(Look.Panel) == 'function' then WrapPanel(Look) end
	if type(Look.Dropdown) == 'function' then WrapDropdown(Look) end
	-- El menú se crea al abrir el mapa (Map/Panel.lua:1296): se viste en el cuadro siguiente.
	hooksecurefunc('CreateFrame', function(_, name)
		if name == 'OpenMapMenu' and Active() then C_Timer.After(0, function() pcall(DressMenu) end) end
	end)
	-- Cada vez que se abre el mapa (ElvUI y TomTom vuelven a mostrar sus coordenadas).
	if _G.WorldMapFrame then
		_G.WorldMapFrame:HookScript('OnShow', function() C_Timer.After(0, function() pcall(HideOtherCoords) end) end)
	end
	return true
end

if not Install() then
	local f = CreateFrame('Frame')
	f:RegisterEvent('ADDON_LOADED')
	f:SetScript('OnEvent', function(self, _, name)
		if name == 'OpenMap' and Install() then self:UnregisterAllEvents() end
	end)
end

-- Registro en el motor: el menú, si ya existía al arrancar KnuUI.
K:RegisterSkin('OpenMap', function()
	Install()
	pcall(DressMenu)
end)
