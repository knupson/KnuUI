-- Ejecutar desde la raíz con LuaJIT; también se incluye en verificar.lua.
local function Run(disabled)
	local hooks, queue, combat, borders = {}, {}, false, 0
	local theme = { border = { r = .2, g = .3, b = .4 }, accent = { r = 1, g = .6, b = .1 }, backdrop = { r = .1, g = .1, b = .1, a = 1 } }
	local K, E = {}, { db = { KnuUISkinCooldownViewer = disabled }, media = { blankTex = 'blank' }, Libs = {} }
	function E:GetModule() return K end
	E.Libs.LSM = { Fetch = function(_, _, name) return name end }
	function K:GetTheme() return theme end
	function K:RegisterSkin(_, callback) self.callback = callback end
	function K:RunAddonSkin(_, key, callback)
		if combat then queue[key] = callback else assert(pcall(callback)) end
	end
	local function Region(kind)
		local r = { regions = {}, kind = kind }
		function r:IsProtected() return self.protected end
		function r:GetRegions() return unpack(self.regions) end
		function r:IsObjectType(value) return self.kind == value end
		function r:GetAtlas() return self.atlas end
		function r:SetAlpha(value) self.alpha = value end
		function r:SetFont(font, size, flags) assert(not combat and not self.protected); self.font = { font, size, flags }; self.fontCalls = (self.fontCalls or 0) + 1 end
		function r:SetTexCoord(...) assert(not combat and not self.protected); self.crop = { ... }; self.cropCalls = (self.cropCalls or 0) + 1 end
		function r:GetNumMaskTextures() return self.mask and 1 or 0 end
		function r:GetMaskTexture() return self.mask end
		function r:RemoveMaskTexture(mask) assert(mask == self.mask); self.mask = nil end
		function r:SetAllPoints(anchor) self.anchor = anchor end
		function r:SetBackdrop(value) assert(value.edgeSize == 1); self.backdrop = value end
		function r:SetBackdropBorderColor(...) self.border = { ... } end
		function r:SetColorTexture(...) self.color = { ... } end
		function r:CreateTexture() self.bg = Region(); return self.bg end
		function r:GetStatusBarTexture() return self.texture end
		function r:SetStatusBarTexture(value) self.texture.file = value end
		function r:SetStatusBarColor(...) self.color = { ... } end
		return r
	end
	local function Item(bar)
		local item, icon = Region(), Region('Texture')
		icon.mask = Region()
		local overlay = Region(); overlay.atlas = 'UI-HUD-CoolDownManager-IconOverlay'
		local owner = item
		if bar then owner = Region(); item.Icon = owner; owner.Icon = icon else item.Icon = icon end
		owner.regions = { icon, overlay }; owner.Applications = Region('FontString')
		item.ChargeCount = Region(); item.ChargeCount.Current = Region('FontString')
		item.Applications = Region(); item.Applications.Applications = Region('FontString')
		item.Cooldown = Region(); item.Cooldown.regions = { Region('FontString') }
		item.DebuffBorder = Region(); item.DebuffBorder.Texture = Region()
		if bar then
			item.Bar = Region(); item.Bar.texture = Region('Texture')
			for _, key in ipairs({ 'Name', 'Duration', 'BarBG', 'Pip' }) do item.Bar[key] = Region('FontString') end
		end
		return item, icon, overlay
	end
	local env = setmetatable({ ElvUI = { E } }, { __index = _G })
	env._G = env
	function env.InCombatLockdown() return combat end
	function env.CreateFrame(_, _, parent)
		assert(not combat and not parent.protected); borders = borders + 1
		local border = Region()
		function border:SetBackdropBorderColor(r, g, b)
			assert(r == theme.border.r and g == theme.border.g and b == theme.border.b)
		end
		return border
	end
	function env.hooksecurefunc(object, method, callback)
		hooks[object] = hooks[object] or {}; hooks[object][method] = callback
	end
	local viewers, items, icons, overlays = {}, {}, {}, {}
	for i, name in ipairs({ 'EssentialCooldownViewer', 'UtilityCooldownViewer', 'BuffIconCooldownViewer', 'BuffBarCooldownViewer' }) do
		local viewer = {}
		-- Cualquier intento de cambiar geometría hace fallar la prueba.
		for _, method in ipairs({ 'SetPoint', 'ClearAllPoints', 'SetSize', 'SetWidth', 'SetHeight', 'SetScale' }) do
			viewer[method] = function() error('se modificó la geometría del viewer') end
		end
		items[i], icons[i], overlays[i] = Item(i == 4)
		viewer.itemFramePool = {}
		-- EnumerateActive devuelve el frame como primer resultado, como FramePool.
		function viewer.itemFramePool:EnumerateActive()
			local done
			return function() if not done then done = true; return items[i] end end
		end
		viewers[i], env[name] = viewer, viewer
	end
	local chunk = assert(loadfile('addons/KnuUI/Skins/CooldownViewer.lua'))
	setfenv(chunk, env); chunk(); K.callback()
	if disabled == false then
		assert(not next(hooks) and borders == 0 and not next(queue))
		for _, icon in ipairs(icons) do assert(not icon.crop) end
		return
	end
	assert(borders == 5)
	for i, viewer in ipairs(viewers) do
		assert(icons[i].crop[1] == .08 and icons[i].crop[2] == .92 and not icons[i].mask and overlays[i].alpha == 0)
		assert(items[i].ChargeCount.Current.font[1] == 'Expressway')
		hooks[viewer].OnAcquireItemFrame(viewer, items[i]); hooks[viewer].RefreshData(viewer)
		assert(icons[i].cropCalls == 1 and items[i].ChargeCount.Current.fontCalls == 1)
		local acquired, icon = Item(i == 4)
		hooks[viewer].OnAcquireItemFrame(viewer, acquired)
		assert(icon.cropCalls == 1)
	end
	assert(borders == 10) -- Reutilizar un ítem no duplica bordes; adquirir otro sí lo decora.
	assert(items[4].Bar.texture.file == 'Melli' and items[4].Bar.color[1] == theme.accent.r)
	assert(items[4].Bar.Name.font[2] == 12 and items[4].Bar.Duration.font[3] == 'OUTLINE')
	local item, icon = Item(); item.protected = true
	hooks[viewers[1]].OnAcquireItemFrame(viewers[1], item); assert(not icon.crop)
	item.protected = nil; icon.protected = true
	hooks[viewers[1]].OnAcquireItemFrame(viewers[1], item); assert(not icon.crop)
	item, icon = Item(); combat = true
	hooks[viewers[1]].OnAcquireItemFrame(viewers[1], item); assert(not icon.crop and queue[item])
	combat = false; queue[item](); assert(icon.cropCalls == 1)
	-- Un ítem incompatible no propaga el error del hook a Blizzard.
	assert(pcall(hooks[viewers[1]].OnAcquireItemFrame, viewers[1], {}))
end
Run(false)
Run(nil) -- nil también habilita el skin.
Run(true) -- true también habilita el skin.
print('OK: Cooldown Viewer; pools, fuentes, barras, geometría, combate y protección.')
