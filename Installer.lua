local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')
local extraButton, skinButton, decorButton, addonSkinsButton

-- Contrato: _ref/ElvUI/Game/Shared/General/PluginInstaller.lua:6-20,80-102,297-337.
local function Page(title, first, second, third)
	local f = PluginInstallFrame
	if extraButton then extraButton:Hide() end
	if skinButton then skinButton:Hide() end
	if decorButton then decorButton:Hide() end
	if addonSkinsButton then addonSkinsButton:Hide() end
	f.tutorialImage:Show()
	f.SubTitle:SetText(title)
	f.Desc1:SetText(first or '')
	f.Desc2:SetText(second or '')
	f.Desc3:SetText(third or '')
end

local function Button(index, text, callback)
	local button = index == 5 and extraButton or PluginInstallFrame['Option'..index]
	button:SetText(text)
	button:SetScript('OnClick', callback)
	button:Show()
	button:Enable() -- SetupReset no restaura Enable después de un addon ausente.
	if index == 3 or index == 4 then button:SetWidth(100) end -- la página Addons los ensancha
	return button
end

local function Saved(callback)
	return function()
		if callback() then E:Print(L["KnuUI: settings saved. Reload from the Done page to see them."]) end
	end
end

local function Confirm()
	E:StaticPopup_Show('KNUUI_APPLY')
end

local installer = {
	Title = '|cffecd9bdKNU|r|cffffa82eUI|r', Name = 'KnuUI',
	tutorialImage = [[Interface\AddOns\KnuUI\media\logo]],
	tutorialImageSize = { 256, 128 }, tutorialImageVertexColor = { 1, 1, 1 },
	StepTitles = { L["Welcome"], L["Layout"], L["Role"], L["Theme"], L["Chat and data"], L["Addons"], L["Done"] },
	StepTitlesColor = { 0.659, 0.561, 0.439 }, StepTitlesColorSelected = { 1, 0.659, 0.18 }, -- knunet --muted / --amber
	Pages = {
		function()
			Page(L["Your interface, with KnuUI identity"],
				L["Compact layout for Forever: combat in the centre and chats in the corners."],
				L["Apply each section with its buttons or install everything with a confirmation."],
				L["Changes are saved to the current profile and show up after a reload."])
			Button(1, L["Apply all"], Confirm)
			Button(2, L["Go to Layout"], function() E:GetModule('PluginInstaller'):SetPage(2) end)
		end,
		function()
			Page(L["Compact layout · sketch v4"],
				L["Keeps the coordinates and measurements of the current design for 1920×1080."],
				L["Bars, units, auras, party, raid, minimap and experience."],
				L["Chat and colours are applied on their own pages."])
			Button(1, L["Layout"], Saved(function() return K:ApplyLayout() end))
			Button(2, L["Nameplates"], Saved(function() return K:ApplyNameplates() end))
			Button(3, L["Columns on"], Saved(function() return K:ApplyTanks(true) end))
			Button(4, L["Columns off"], Saved(function() return K:ApplyTanks(false) end))
		end,
		function()
			Page(format(L["Role: %s"], K:RoleName()),
				L["Tank: threat borders on frames and plates. MDPS: the base layout."],
				L["RDPS: bigger cast bar and target debuffs. Healer: party and raid in the centre."],
				L["Healer turns on incoming heals and HoT indicators. Reload to see it."])
			for i, role in ipairs(K.roles) do
				Button(i, K.roleNames[role], Saved(function() return K:ApplyRole(role) end))
			end
		end,
		function()
			Page(L["Theme: Knunet amber or Neon"],
				L["Dark backgrounds, thin borders, Expressway font and Melli texture."],
				L["Knunet: amber on warm black, like knunet.com. Neon: cyan and magenta."],
				L["Includes the AFK screen with the KnuUI logo. Class health or theme health."])
			Button(1, L["Knunet amber"], Saved(function() return K:ApplyTheme(nil, 'knunet') end))
			Button(2, L["Neon"], Saved(function() return K:ApplyTheme(nil, 'neon') end))
			Button(3, L["Class health"], Saved(function() return K:ApplyTheme(true) end))
			Button(4, L["Theme health"], Saved(function() return K:ApplyTheme(false) end))
			if not decorButton then
				decorButton = CreateFrame('Button', nil, PluginInstallFrame, 'UIPanelButtonTemplate')
				decorButton:SetSize(180, 30)
				decorButton:SetPoint('BOTTOM', PluginInstallFrame, 'BOTTOM', 0, 70)
				hooksecurefunc(E:GetModule('PluginInstaller'), 'SetupReset', function() decorButton:Hide() end)
			end
			decorButton:SetText(format(L["Decoration: %s"], E.db.KnuUIDecor ~= false and L["yes"] or L["no"]))
			decorButton:SetScript('OnClick', function()
				if K:ToggleDecor() then
					decorButton:SetText(format(L["Decoration: %s"], E.db.KnuUIDecor and L["yes"] or L["no"]))
				end
			end)
			decorButton:Show()
		end,
		function()
			Page(L["Chat and data, hand-tuned"],
				L["400×180 chats, edit box above, and panels with the same background and tabs."],
				L["Central 1100×22 bar with eight data points; time and coordinates on the minimap."],
				L["Replaces the previous data panels, including ForeverUI_Data."])
			Button(1, L["Apply chat and data"], Saved(function() return K:ApplyChat() end)):SetWidth(240)
			Button(2, L["Integrated panels"], Saved(function() return K:ApplyIntegratedPanels() end)):SetWidth(180)
		end,
		function()
			Page(L["Your addons, integrated"],
				L["Details!: font and texture. Baganator and DBM: compatibility information."],
				L["WoW-Pro and Questie: save their position below the minimap on reload."],
				L["Each button only affects the addon shown."])
			-- Dejamos espacio para tres filas de botones en esta página.
			PluginInstallFrame.tutorialImage:Hide()
			if not extraButton then
				-- Botón adicional: mismo template que PluginInstaller.lua:297.
				extraButton = CreateFrame('Button', nil, PluginInstallFrame, 'UIPanelButtonTemplate')
				extraButton:SetHeight(30)
				-- Evita que quede visible cuando otro plugin usa el asistente.
				-- Hook de métodos: Modules/Skins/Skins.lua:152; SetupReset: PluginInstaller.lua:80.
				hooksecurefunc(E:GetModule('PluginInstaller'), 'SetupReset', function()
					extraButton:Hide()
					if skinButton then skinButton:Hide() end
					PluginInstallFrame.tutorialImage:Show()
				end)
			end
			if not skinButton then
				skinButton = CreateFrame('Button', nil, PluginInstallFrame, 'UIPanelButtonTemplate')
				skinButton:SetHeight(30)
			end
			skinButton:SetText(L["WoW-Pro skin"])
			skinButton:SetScript('OnClick', function()
				if not K:CanApply() then return end
				E.db.KnuUISkinWoWPro = E.db.KnuUISkinWoWPro == false
				K:SkinWoWPro()
				E:Print(E.db.KnuUISkinWoWPro and L["KnuUI: WoW-Pro skin enabled."] or L["KnuUI: WoW-Pro skin disabled; reload to restore its appearance."])
				skinButton:SetText(format(L["WoW-Pro skin: %s"], E.db.KnuUISkinWoWPro and L["yes"] or L["no"]))
			end)
			skinButton:SetText(format(L["WoW-Pro skin: %s"], E.db.KnuUISkinWoWPro ~= false and L["yes"] or L["no"]))
			skinButton:Show()
			for i, entry in ipairs(K.addons) do
				local selected = entry -- Captura propia para Lua 5.1.
				local loaded = K:IsLoaded(selected.id)
				local button = Button(i, selected.label..(loaded and '' or L[" · not installed"]), function() K:ApplyAddon(selected) end)
				if not loaded then button:Disable() end
			end
			if not addonSkinsButton then
				addonSkinsButton = CreateFrame('Button', nil, PluginInstallFrame, 'UIPanelButtonTemplate')
				addonSkinsButton:SetSize(240, 30)
				addonSkinsButton:SetPoint('BOTTOM', PluginInstallFrame, 'BOTTOM', 0, 102)
				hooksecurefunc(E:GetModule('PluginInstaller'), 'SetupReset', function() addonSkinsButton:Hide() end)
			end
			addonSkinsButton:SetText(format(L["Addon skins: %s"], E.db.KnuUIAddonSkins ~= false and L["yes"] or L["no"]))
			addonSkinsButton:SetScript('OnClick', function()
				if not K:CanApply() then return end
				E.db.KnuUIAddonSkins = E.db.KnuUIAddonSkins == false
				addonSkinsButton:SetText(format(L["Addon skins: %s"], E.db.KnuUIAddonSkins and L["yes"] or L["no"]))
				E:Print(L["Reload the UI to apply addon skins."])
			end)
			addonSkinsButton:Show()
			-- Después de Show: los scripts nativos reposicionan Option1-4.
			for i = 1, 6 do
				local button = i == 6 and skinButton or i == 5 and extraButton or PluginInstallFrame['Option'..i]
				button:ClearAllPoints()
				button:SetWidth(170)
				local row = i <= 3 and 1 or 0
				local column = i <= 3 and i - 2 or i - 5
				button:SetPoint('BOTTOM', PluginInstallFrame, 'BOTTOM', column * 174, 34 + row * 34)
			end
		end,
		function()
			Page(L["Ready to play"],
				L["Reload to activate the sections you chose."],
				L["You can come back with /knu or from ElvUI → KnuUI."],
				L["Reloading marks this installer version as reviewed."])
			Button(1, L["Finish and reload"], function()
				if not K:CanApply() then return end
				K:CleanupLegacy()
				E.db.KnuUILayoutVersion = K.version
				ReloadUI()
			end):SetWidth(240)
		end,
	},
}

function K:OpenInstaller()
	E:GetModule('PluginInstaller'):Queue(installer)
end

local function Options()
	-- _ref/ElvUI_Libraries/Game/Shared/LibElvUIPlugin-1.0/LibElvUIPlugin-1.0.lua:107.
	-- Menú en pestañas (AceConfig childGroups = 'tab'): cada pestaña explica qué hace, las opciones
	-- ocupan el ancho completo para que ningún texto se corte y las dependientes se apagan solas.
	local function Reload() E:Print(L["KnuUI: settings saved. Reload from the Done page to see them."]) end
	local function Desc(order, text) return { order = order, type = 'description', fontSize = 'medium', name = text } end
	local function Head(order, text) return { order = order, type = 'header', name = text } end
	local function NoColumns() return not E.db.KnuUITanks end
	local function SetCompact(key)
		return function(_, value)
			E.db[key] = value
			if E.db.KnuUITanks and K:ApplyTanks(true) then Reload() end
		end
	end

	E.Options.args.KnuUI = {
		type = 'group', childGroups = 'tab',
		name = [[|TInterface\AddOns\KnuUI\media\icono64:16:16|t KnuUI]],
		args = {
			intro = Desc(1, L["Compact layout for WoW Forever. Changes are saved to the current ElvUI profile and most of them show after a reload."]),
			general = {
				order = 10, type = 'group', name = L["General"],
				args = {
					desc = Desc(1, L["Install or reapply KnuUI. The installer walks you through every section."]),
					install = { order = 2, type = 'execute', width = 'double', name = L["Open installer"], func = function() K:OpenInstaller() end },
					applyAll = { order = 3, type = 'execute', width = 'double', name = L["Apply all"], desc = L["Apply layout, theme, chat and addon settings, then reload."],
						func = function() E:StaticPopup_Show('KNUUI_APPLY') end },
				},
			},
			layout = {
				order = 20, type = 'group', name = L["Layout"],
				args = {
					roleHead = Head(1, L["Role"]),
					roleDesc = Desc(2, L["Tank: threat borders. MDPS: the base layout. RDPS: bigger cast bar and target debuffs. Healer: party and raid in the centre with incoming heals."]),
					role = { order = 3, type = 'select', width = 'double', name = L["Role"],
						values = function() local v = {} for _, r in ipairs(K.roles) do v[r] = K.roleNames[r] end return v end,
						sorting = K.roles,
						get = function() return E.db.KnuUIRole or 'mdps' end,
						set = function(_, role) if K:ApplyRole(role) then Reload() end end },
					columnsHead = Head(10, L["Health and mana columns"]),
					columnsDesc = Desc(11, L["Vertical health and mana bars next to the main bars, with larger side blocks of buttons."]),
					columns = { order = 12, type = 'toggle', width = 'full', name = L["Use health and mana columns"],
						get = function() return E.db.KnuUITanks end,
						set = function(_, value) if K:ApplyTanks(value) then Reload() end end },
					compactLeft = { order = 13, type = 'toggle', width = 'full', name = L["Compact left block (3×4): wider left chat"],
						desc = L["Frees 129 px for the left chat; the data bar shrinks the same."], disabled = NoColumns,
						get = function() return E.db.KnuUICompactLeft end, set = SetCompact('KnuUICompactLeft') },
					compactRight = { order = 14, type = 'toggle', width = 'full', name = L["Compact right block (3×4): wider Details"],
						desc = L["Frees 129 px for Details; the data bar shrinks the same."], disabled = NoColumns,
						get = function() return E.db.KnuUICompactRight end, set = SetCompact('KnuUICompactRight') },
					resetHead = Head(20, L["Positions"]),
					reapply = { order = 21, type = 'execute', width = 'double', name = L["Reapply layout"], desc = L["Puts bars, frames and panels back in their KnuUI positions."],
						func = function() if K:ApplyLayout() then Reload() end end },
					nameplates = { order = 22, type = 'execute', width = 'double', name = L["Reapply nameplates"],
						func = function() if K:ApplyNameplates() then Reload() end end },
				},
			},
			look = {
				order = 30, type = 'group', name = L["Appearance"],
				args = {
					desc = Desc(1, L["Colours, decoration and visual effects."]),
					theme = { order = 2, type = 'select', width = 'double', name = L["Theme"],
						values = function() local v = {} for key, theme in pairs(K.themes) do v[key] = theme.label end return v end,
						sorting = K.themeOrder,
						get = function() return E.db.KnuUITheme or 'knunet' end,
						set = function(_, value) if K:ApplyTheme(nil, value) then Reload() end end },
					classHealth = { order = 3, type = 'toggle', width = 'full', name = L["Health bars in class colour"],
						get = function() return E.db.KnuUIClassHealth ~= false end,
						set = function(_, value) if K:ApplyTheme(value) then Reload() end end },
					decor = { order = 4, type = 'toggle', width = 'full', name = L["Decoration: minimap corners, stripes and shadows"],
						get = function() return E.db.KnuUIDecor ~= false end,
						set = function(_, value) if (E.db.KnuUIDecor ~= false) ~= value then K:ToggleDecor() end end },
					combatGlow = { order = 5, type = 'toggle', width = 'full', name = L["Combat glow on the screen edges"],
						get = function() return E.db.KnuUICombatGlow ~= false end, set = function(_, value) E.db.KnuUICombatGlow = value end },
					panels = { order = 6, type = 'execute', width = 'double', name = L["Reapply chat and Details panels"],
						func = function() if K:ApplyIntegratedPanels() then Reload() end end },
				},
			},
			addons = {
				order = 40, type = 'group', name = L["Addons"],
				args = {
					desc = Desc(1, L["How KnuUI looks after other addons. Skins need a reload."]),
					addonSkins = { order = 2, type = 'toggle', width = 'full', name = L["Skins for supported addons (Auctionator, BugSack, Pawn, Questie...)"],
						get = function() return E.db.KnuUIAddonSkins ~= false end,
						set = function(_, value) if K:CanApply() then E.db.KnuUIAddonSkins = value; E:Print(L["Reload the UI to apply addon skins."]) end end },
					wowpro = { order = 3, type = 'toggle', width = 'full', name = L["WoW-Pro skin"],
						get = function() return E.db.KnuUISkinWoWPro ~= false end,
						set = function(_, value) E.db.KnuUISkinWoWPro = value; Reload() end },
					dbm = { order = 4, type = 'toggle', width = 'full', name = L["DBM bars with KnuUI texture and font"],
						desc = L["This writes DBM's own settings."],
						get = function() return E.db.KnuUISkinDBM end, set = function(_, value) E.db.KnuUISkinDBM = value; Reload() end },
					trackerHead = Head(10, L["Quest tracker"]),
					tracker = { order = 11, type = 'select', width = 'double', name = L["Quest tracker"],
						values = { show = L["Always show"], hide = L["Hide when WoW-Pro is loaded"] },
						get = function() return E.db.KnuUIHideTracker and 'hide' or 'show' end,
						set = function(_, value) if K:ApplyTracker(value == 'hide') then Reload() end end },
				},
			},
			camera = {
				order = 50, type = 'group', name = L["Camera"],
				args = {
					desc = Desc(1, L["DynamicCam presets (needs DynamicCam). Applied to a DynamicCam profile called KnuUI."]),
					preset = { order = 2, type = 'select', width = 'double', name = L["Camera preset"],
						values = { ["Shushudaa's preset"] = L["Cinematic (Shushudaa)"], Immersive = L["Soft immersive"], Vanillalike = L["Classic (almost no ActionCam)"] },
						get = function() return E.global.KnuUICameraPreset or "Shushudaa's preset" end,
						set = function(_, value) K:ApplyCamera(true, value) end },
					cinemaHead = Head(10, L["Cinema mode"]),
					cinemaDesc = Desc(11, L["Hides the interface and slowly orbits the camera; it ends when you enter combat. Also /knu cine or a key binding (Key Bindings > AddOns > KnuUI)."]),
					cinema = { order = 12, type = 'execute', width = 'double', name = L["Start cinema mode"], func = function() K:ToggleCinema() end },
				},
			},
		},
	}
end

function K:SetupInstaller()
	-- Popup: _ref/ElvUI/Game/Shared/General/StaticPopups.lua (PopupDialogs/OnAccept).
	E.PopupDialogs.KNUUI_APPLY = {
		text = L["Do you want to apply the layout, theme, chat/data and compatible addon settings to the current profile and reload?"],
		button1 = L["Apply and reload"], button2 = L["Cancel"],
		OnAccept = function() K:ApplyAll() end,
		timeout = 0, whileDead = true, hideOnEscape = true,
	}
	SLASH_KNUUI1, SLASH_KNUUI2 = '/knu', '/fui'
	SlashCmdList.KNUUI = function(message)
		local command = (message or ''):match('^%s*(.-)%s*$'):lower()
		if command == 'aplicar' or command == 'apply' then Confirm()
		elseif command == 'cine' or command == 'cinema' then K:ToggleCinema()
		else K:OpenInstaller() end
	end
	E.Libs.EP:RegisterPlugin(self.addonName, Options)
end
