local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')
local ADDON = 'Blizzard_CooldownViewer'
local styled = setmetatable({}, { __mode = 'k' })

local function Safe(region)
	return region and not (region.IsProtected and region:IsProtected())
end

local function Font(text, size)
	if not Safe(text) or not text.SetFont or styled[text] then return end
	text:SetFont(E.Libs.LSM:Fetch('font', 'Expressway'), size, 'OUTLINE')
	styled[text] = true
end

local function Hide(region)
	if Safe(region) then region:SetAlpha(0) end
end

local function Border(parent, anchor, background)
	if not Safe(parent) or not Safe(anchor) or styled[parent] then return end
	local t = K:GetTheme()
	-- Sólo el marco decorativo propio recibe anclas; nunca el viewer de Edit Mode.
	local border = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
	border:SetAllPoints(anchor)
	border:SetBackdrop({ edgeFile = E.media.blankTex, edgeSize = 1 })
	border:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b, 1)
	if background then
		local bg = parent:CreateTexture(nil, 'BACKGROUND')
		bg:SetAllPoints(parent)
		bg:SetColorTexture(t.backdrop.r, t.backdrop.g, t.backdrop.b, t.backdrop.a)
	end
	styled[parent] = border
end

local function Icon(owner, texture)
	if not Safe(owner) or not Safe(texture) then return end
	-- CooldownViewer.xml:29-36,98-105,167-174,224-231: máscara y overlay sin parentKey.
	if not styled[texture] then
		if texture.GetNumMaskTextures then
			for i = texture:GetNumMaskTextures(), 1, -1 do
				local mask = texture:GetMaskTexture(i)
				if Safe(mask) then texture:RemoveMaskTexture(mask) end
			end
		end
		texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		-- Blizzard dibuja el ícono más grande que su casilla y tapa el sobrante con la máscara redonda; sin la
		-- máscara los íconos se pisaban (visto en el juego 2026-11-13). 2 px adentro por lado: 4 entre íconos.
		texture:ClearAllPoints()
		texture:SetPoint('TOPLEFT', owner, 'TOPLEFT', 2, -2)
		texture:SetPoint('BOTTOMRIGHT', owner, 'BOTTOMRIGHT', -2, 2)
		styled[texture] = true
	end
	for _, region in ipairs({ owner:GetRegions() }) do
		if Safe(region) and region.GetAtlas and region:GetAtlas() == 'UI-HUD-CoolDownManager-IconOverlay' then Hide(region) end
	end
	Border(owner, texture)
	-- Casillas de auras no activas (visor de buffs): Blizzard las deja sin ícono y el borde quedaba como un
	-- botón vacío (visto en el juego 2026-11-13). El borde se ve sólo cuando hay ícono.
	local border = styled[owner]
	if type(border) == 'table' and border.SetShown and not border.KnuFollow then
		border.KnuFollow = true
		local function Sync()
			local tex = texture.GetTexture and texture:GetTexture()
			border:SetShown(texture:IsShown() and tex ~= nil and tex ~= '')
		end
		for _, method in ipairs({ 'Show', 'Hide', 'SetShown', 'SetTexture', 'SetAtlas' }) do
			if texture[method] then hooksecurefunc(texture, method, Sync) end
		end
		Sync()
	end
end

local function StyleItem(item)
	if InCombatLockdown() or not Safe(item) then return end
	-- CooldownViewerSecure.lua:3-35: el mapa de auras es seguro; no se lee ni se modifica.
	-- CooldownViewerItemData.lua:17-22: tampoco se inspeccionan IDs/datos de hechizos.
	local bar = item.Bar
	local owner = bar and item.Icon or item
	Icon(owner, bar and owner and owner.Icon or item.Icon)
	-- CooldownViewer.xml:57,126,198,237: textos de cargas y aplicaciones.
	if Safe(item.ChargeCount) then Font(item.ChargeCount.Current, 13) end
	if Safe(item.Applications) then Font(item.Applications.Applications, 13) end
	if bar and Safe(owner) then Font(owner.Applications, 12) end
	if Safe(item.Cooldown) then
		for _, region in ipairs({ item.Cooldown:GetRegions() }) do
			if Safe(region) and region.IsObjectType and region:IsObjectType('FontString') then Font(region, 16) end
		end
	end
	if Safe(item.DebuffBorder) then Hide(item.DebuffBorder.Texture) end
	-- CooldownViewer.xml:251-285: barra, fondo, pip y textos de nombre/duración.
	if Safe(bar) and Safe(bar:GetStatusBarTexture()) then
		if not styled[bar] then
			local t = K:GetTheme()
			bar:SetStatusBarTexture(E.Libs.LSM:Fetch('statusbar', 'Melli'))
			bar:SetStatusBarColor(t.accent.r, t.accent.g, t.accent.b, 1)
			Border(bar, bar, true)
		end
		Hide(bar.BarBG)
		Hide(bar.Pip)
		Font(bar.Name, 12)
		Font(bar.Duration, 12)
	end
end

local function Apply(item)
	-- El motor difiere los cambios hasta PLAYER_REGEN_ENABLED (Skins/Engine.lua:18-28).
	K:RunAddonSkin(ADDON, item, function() StyleItem(item) end)
end

local function Scan(viewer)
	if not Safe(viewer) or not viewer.itemFramePool then return end
	for item in viewer.itemFramePool:EnumerateActive() do Apply(item) end
end

K:RegisterSkin(ADDON, function()
	if E.db.KnuUISkinCooldownViewer == false then return end
	-- CooldownViewer.xml:298-337: los cuatro contenedores pertenecen a Edit Mode.
	for _, name in ipairs({ 'EssentialCooldownViewer', 'UtilityCooldownViewer', 'BuffIconCooldownViewer', 'BuffBarCooldownViewer' }) do
		local viewer = _G[name]
		if Safe(viewer) then
			-- CooldownViewer.lua:2033-2042: cada Acquire pasa por este método.
			-- Se engancha la instancia: BuffBar lo extiende en :2334-2338.
			pcall(hooksecurefunc, viewer, 'OnAcquireItemFrame', function(_, item) pcall(Apply, item) end)
			-- :2023-2027 permite refrescar sin adquirir; también cubre fuentes creadas tarde.
			pcall(hooksecurefunc, viewer, 'RefreshData', function(self) pcall(Scan, self) end)
			pcall(Scan, viewer)
		end
	end
end)
