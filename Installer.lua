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
	E.Options.args.KnuUI = {
		type = 'group', name = [[|TInterface\AddOns\KnuUI\media\icono64:16:16|t KnuUI]],
		args = {
			install = { order = 1, type = 'execute', name = L["Open installer"], func = function() K:OpenInstaller() end },
			layout = { order = 2, type = 'execute', name = L["Reapply layout"], func = Saved(function() return K:ApplyLayout() end) },
			role = { order = 2.5, type = 'select', name = L["Role"],
				values = function() local v = {} for _, r in ipairs(K.roles) do v[r] = K.roleNames[r] end return v end,
				sorting = K.roles,
				get = function() return E.db.KnuUIRole or 'mdps' end,
				set = function(_, role) if K:ApplyRole(role) then E:Print(L["KnuUI: settings saved. Reload from the Done page to see them."]) end end },
			combatGlow = { order = 2.75, type = 'toggle', name = L["Combat glow on the screen edges"],
				get = function() return E.db.KnuUICombatGlow ~= false end, set = function(_, v) E.db.KnuUICombatGlow = v end },
			cinema = { order = 2.8, type = 'execute', name = L["Cinema mode (hide the interface and orbit the camera)"], func = function() K:ToggleCinema() end },
			theme = { order = 3, type = 'execute', name = L["Reapply theme"], func = Saved(function() return K:ApplyTheme() end) },
			panels = { order = 3.25, type = 'execute', name = L["Panels: reapply"], func = Saved(function() return K:ApplyIntegratedPanels() end) },
			decor = { order = 3.5, type = 'execute',
				name = function() return format(L["Decoration: %s"], E.db.KnuUIDecor ~= false and L["yes"] or L["no"]) end,
				func = function() K:ToggleDecor() end },
			addonSkins = { order = 3.75, type = 'toggle', name = L["Addon skins"],
				desc = L["Reload the UI to apply addon skins."],
				get = function() return E.db.KnuUIAddonSkins ~= false end,
				set = function(_, value)
					if not K:CanApply() then return end
					E.db.KnuUIAddonSkins = value
					E:Print(L["Reload the UI to apply addon skins."])
				end },
			trackerShow = { order = 4, type = 'execute', name = L["Tracker: show"], func = Saved(function() return K:ApplyTracker(false) end) },
			trackerHide = { order = 5, type = 'execute', name = L["Tracker: hide with WoW-Pro"], func = Saved(function() return K:ApplyTracker(true) end) },
			dbm = { order = 9, type = 'toggle', name = L["DBM bars: KnuUI texture and font (changes DBM settings)"], get = function() return E.db.KnuUISkinDBM end, set = function(_, v) E.db.KnuUISkinDBM = v end },
			camera = { order = 6, type = 'execute', name = L["Camera: cinematic (Shushudaa)"], func = function() K:ApplyCamera(true, "Shushudaa's preset") end },
			cameraImm = { order = 7, type = 'execute', name = L["Camera: soft immersive"], func = function() K:ApplyCamera(true, 'Immersive') end },
			cameraVan = { order = 8, type = 'execute', name = L["Camera: classic (almost no ActionCam)"], func = function() K:ApplyCamera(true, 'Vanillalike') end },
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
