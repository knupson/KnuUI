local E, _, _, P = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')
local S = E:GetModule('Skins')
local registry, pending, watched = {}, {}, {}
local styled = setmetatable({}, { __mode = 'k' })

P.KnuUIAddonSkins = true
P.KnuUIAddonSkinsOff = {}

local function Enabled(addon)
	return E.Forever and E.db and E.db.KnuUIAddonSkins ~= false
		and not (E.db.KnuUIAddonSkinsOff and E.db.KnuUIAddonSkinsOff[addon])
end

-- Toda entrada, incluidos los hooks tardíos, pasa por la misma cola fuera de combate.
function K:RunAddonSkin(addon, key, callback)
	if not Enabled(addon) then return end
	if InCombatLockdown() then
		pending[key] = { addon, callback }
		return
	end
	local ok, err = pcall(callback)
	if not ok then E:Print(format(L["KnuUI: %s failed: %s"], addon, tostring(err))) end
end

local function Run(addon)
	local entry = registry[addon]
	if not K.skinEngineReady or not entry or entry.done or not K:IsLoaded(addon) or not Enabled(addon) then return end
	K:RunAddonSkin(addon, entry, function()
		if entry.done then return end
		entry.done = true -- Un error no dispara reintentos infinitos.
		entry.callback()
	end)
end

function K:RegisterSkin(addon, callback)
	if registry[addon] then return end
	registry[addon] = { callback = callback }
	Run(addon)
end

local function Border(frame)
	local t = K:GetTheme()
	local backdrop = frame.backdrop or frame
	if backdrop.SetBackdropBorderColor then backdrop:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b) end
end

function K:SkinFont(text, title)
	if not text or not text.FontTemplate or InCombatLockdown() then return end
	-- Toolkit.lua:496: el nombre de LSM se resuelve dentro de FontTemplate.
	text:FontTemplate('Expressway')
	if title then
		local t = self:GetTheme()
		text:SetTextColor(t.accent.r, t.accent.g, t.accent.b)
	end
end

function K:SkinFrame(frame)
	if not frame or InCombatLockdown() then return end
	-- Shared/General/Toolkit.lua:488,294; Skins/Skins.lua:234.
	if not styled[frame] then frame:StripTextures(); styled[frame] = true end
	frame:SetTemplate('Transparent')
	local t = self:GetTheme()
	frame:SetBackdropColor(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, t.backdropFade.a)
	Border(frame)
	self:SkinFont(frame.TitleText, true)
	self:SkinFont(frame.TitleContainer and frame.TitleContainer.TitleText, true)
end

local handled = setmetatable({}, { __mode = 'k' })
function K:SkinChildren(frame)
	if not frame or InCombatLockdown() then return end
	local function Walk(node)
		for _, region in ipairs({ node:GetRegions() }) do
			if region:IsObjectType('FontString') then K:SkinFont(region) end
		end
		for _, field in ipairs({ 'TitleText', 'HeaderText' }) do K:SkinFont(node[field], true) end
		for _, child in ipairs({ node:GetChildren() }) do
			if not handled[child] then
				local name, kind = child:GetName() or '', child:GetObjectType()
				-- Firmas verificadas: Skins.lua:910,1016,1413,1597,1797,1898.
				-- ScrollFrame usa su ScrollBar; no se pasa el contenedor a un helper de slider.
				local bar = child.ScrollBar or (kind == 'ScrollFrame' and _G[name..'ScrollBar'])
				if bar then S:HandleScrollBar(bar); handled[bar] = true; Border(bar) end
				if name:match('CloseButton$') or child == node.CloseButton then S:HandleCloseButton(child)
				elseif kind == 'CheckButton' then S:HandleCheckBox(child)
				elseif kind == 'EditBox' then S:HandleEditBox(child)
				elseif name:match('ScrollBar$') and kind ~= 'ScrollFrame' then S:HandleScrollBar(child)
				elseif kind == 'Slider' then S:HandleSliderFrame(child)
				elseif kind == 'Button' then S:HandleButton(child) end
				handled[child] = true
			end
			Border(child)
			Walk(child)
		end
	end
	Walk(frame)
end

local bound = setmetatable({}, { __mode = 'k' })
function K:StyleAddonFrame(addon, frame, callback)
	if not frame then return end
	local function Apply()
		K:RunAddonSkin(addon, frame, function()
			if not bound[frame] then
				bound[frame] = true
				frame:HookScript('OnShow', function()
					-- Deja terminar la creación de controles dentro de OnShow.
					C_Timer.After(0, Apply)
				end)
			end
			K:SkinFrame(frame)
			K:SkinChildren(frame)
			if callback then callback(frame) end
		end)
	end
	Apply()
end

function K:WatchAddonFrame(addon, name, callback)
	watched[name] = { addon, callback }
	self:StyleAddonFrame(addon, _G[name], callback)
end

function K:HookAddonSkin(addon, object, method, callback)
	if object and type(object[method]) == 'function' then
		hooksecurefunc(object, method, function()
			K:RunAddonSkin(addon, callback, callback)
		end)
	end
end

function K:SetupAddonSkins()
	if self.skinEngineReady then return end
	self.skinEngineReady = true
	if E.db.KnuUIAddonSkins == nil then E.db.KnuUIAddonSkins = true end
	E.db.KnuUIAddonSkinsOff = E.db.KnuUIAddonSkinsOff or {}
	local events = CreateFrame('Frame')
	self.addonSkinEvents = events
	for _, event in ipairs({ 'ADDON_LOADED', 'PLAYER_ENTERING_WORLD', 'PLAYER_REGEN_ENABLED' }) do events:RegisterEvent(event) end
	events:SetScript('OnEvent', function(_, event, addon)
		if InCombatLockdown() then return end
		if event == 'ADDON_LOADED' then Run(addon) else for name in pairs(registry) do Run(name) end end
		local queue = pending
		pending = {}
		for key, work in pairs(queue) do K:RunAddonSkin(work[1], key, work[2]) end
		for name, work in pairs(watched) do K:StyleAddonFrame(work[1], _G[name], work[2]) end
	end)
	-- Sólo observa nombres registrados; el retraso deja terminar la creación y sus hijos.
	-- Creaciones verificadas en cada Skins/AddOns/*.lua. No se modifica CreateFrame.
	hooksecurefunc('CreateFrame', function(_, name)
		local work = name and watched[name]
		if work then C_Timer.After(0, function() K:StyleAddonFrame(work[1], _G[name], work[2]) end) end
	end)
	for name in pairs(registry) do Run(name) end
end
