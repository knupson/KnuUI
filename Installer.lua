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

-- Pedido del user (2026-11-13): "que cada botón te pida reload es malísimo, no tenés forma de saber qué está
-- cambiando". Se aplica en el momento con el refresco completo de ElvUI (E:UpdateAll, Core.lua:1751: diseño,
-- barras, datos, auras, placas, bolsas, chat, tooltip, minimapa y unidades) y se dice qué se aplicó.
local function Saved(label, callback)
	return function()
		if not callback() then return end
		pcall(E.UpdateAll, E)
		E:Print(format(L["KnuUI: %s applied. Anything that does not change yet shows after a reload."], label))
	end
end

-- Los botones que agrega KnuUI con el estilo de ElvUI (los de la página los viste PluginInstaller.lua:302-342).
local function Skin(button)
	local S = E:GetModule('Skins')
	if button and not button.KnuSkinned and S and S.HandleButton then
		button.KnuSkinned = true
		S:HandleButton(button)
	end
	return button
end

-- ElvUI cambia el ancho y el lugar de Option1-4 cada vez que se muestra otra (OnShow, PluginInstaller.lua:
-- 304-338) y el texto largo quedaba afuera del botón. Después de mostrarlas se acomodan acá, centradas.
local function Row(widths)
	local f, total, gap = PluginInstallFrame, 0, 4
	for _, w in ipairs(widths) do total = total + w end
	total = total + gap * (#widths - 1)
	local x = -total / 2
	for i, w in ipairs(widths) do
		local b = f['Option'..i]
		b:ClearAllPoints()
		b:SetWidth(w)
		b:SetPoint('BOTTOMLEFT', f, 'BOTTOM', x, 45)
		x = x + w + gap
	end
end

-- Barra de progreso con el acento del tema (ElvUI la pinta de rojo a verde, PluginInstaller.lua:126).
do
	local PI = E:GetModule('PluginInstaller')
	if PI and PI.SetPage then
		hooksecurefunc(PI, 'SetPage', function()
			local f = PluginInstallFrame
			if not (f and f.Status and f.Title and f.Title.GetText) then return end
			if (f.Title:GetText() or ''):find('KNU') and K.GetTheme then
				local t = K:GetTheme()
				local c = t and t.accent
				if c then f.Status:SetStatusBarColor(c.r, c.g, c.b) end
			end
		end)
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
				L["Each button applies right away to the current profile; a few details finish showing after a reload."])
			Button(1, L["Apply all"], Confirm)
			Button(2, L["Go to Layout"], function() E:GetModule('PluginInstaller'):SetPage(2) end)
		end,
		function()
			Page(L["Compact layout · sketch v4"],
				L["Keeps the coordinates and measurements of the current design for 1920×1080."],
				L["Bars, units, auras, party, raid, minimap and experience."],
				L["Chat and colours are applied on their own pages."])
			Button(1, L["Layout"], Saved(L["Layout"], function() return K:ApplyLayout() end))
			Button(2, L["Nameplates"], Saved(L["Nameplates"], function() return K:ApplyNameplates() end))
			Button(3, L["Columns on"], Saved(L["Columns on"], function() return K:ApplyTanks(true) end))
			Button(4, L["Columns off"], Saved(L["Columns off"], function() return K:ApplyTanks(false) end))
			Row({ 110, 110, 110, 110 })
		end,
		function()
			Page(format(L["Role: %s"], K:RoleName()),
				L["Tank: threat borders on frames and plates. MDPS: the base layout."],
				L["RDPS: bigger cast bar and target debuffs. Healer: party and raid in the centre."],
				L["Healer turns on incoming heals and HoT indicators. Reload to see it."])
			for i, role in ipairs(K.roles) do
				Button(i, K.roleNames[role], Saved(K.roleNames[role], function() return K:ApplyRole(role) end))
			end
			local widths = {}
			for i = 1, #K.roles do widths[i] = 110 end
			Row(widths)
		end,
		function()
			Page(L["Theme: Knunet amber or Neon"],
				L["Dark backgrounds, thin borders, Expressway font and Melli texture."],
				L["Knunet: amber on warm black, like knunet.com. Neon: cyan and magenta."],
				L["Includes the AFK screen with the KnuUI logo. Class health or theme health."])
			Button(1, L["Knunet amber"], Saved(L["Knunet amber"], function() return K:ApplyTheme(nil, 'knunet') end))
			Button(2, L["Neon"], Saved(L["Neon"], function() return K:ApplyTheme(nil, 'neon') end))
			Button(3, L["Class health"], Saved(L["Class health"], function() return K:ApplyTheme(true) end))
			Button(4, L["Theme health"], Saved(L["Theme health"], function() return K:ApplyTheme(false) end))
			Row({ 120, 120, 120, 120 })
			-- Sin logo en esta página: el botón de decoración lo tapaba (visto en el juego 2026-11-13).
			PluginInstallFrame.tutorialImage:Hide()
			if not decorButton then
				decorButton = Skin(CreateFrame('Button', nil, PluginInstallFrame, 'UIPanelButtonTemplate'))
				decorButton:SetSize(200, 30)
				decorButton:SetPoint('BOTTOM', PluginInstallFrame, 'BOTTOM', 0, 81)
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
				L["401×180 chats, edit box above, and panels with the same background and tabs."],
				L["Central 1102×22 bar with eight data points; time and coordinates on the minimap."],
				L["Replaces the previous data panels, including ForeverUI_Data."])
			Button(1, L["Apply chat and data"], Saved(L["Apply chat and data"], function() return K:ApplyChat() end))
			Button(2, L["Integrated panels"], Saved(L["Integrated panels"], function() return K:ApplyIntegratedPanels() end))
			Row({ 200, 200 })
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
				extraButton = Skin(CreateFrame('Button', nil, PluginInstallFrame, 'UIPanelButtonTemplate'))
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
				skinButton = Skin(CreateFrame('Button', nil, PluginInstallFrame, 'UIPanelButtonTemplate'))
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
				addonSkinsButton = Skin(CreateFrame('Button', nil, PluginInstallFrame, 'UIPanelButtonTemplate'))
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
	local function Reload()
		pcall(E.UpdateAll, E)
		E:Print(L["KnuUI: applied. Anything that does not change yet shows after a reload."])
	end
	local function Desc(order, text) return { order = order, type = 'description', fontSize = 'medium', name = text } end
	local function Head(order, text) return { order = order, type = 'header', name = text } end
	local function NoColumns() return not E.db.KnuUITanks end
	local function SetCompact(key)
		return function(_, value)
			if not K:CanApply() then return end
			E.db[key] = value
			if E.db.KnuUITanks and K:ApplyTanks(true) then Reload() end
		end
	end
	local function Reason(text, disabled, reason)
		return function() return text..(disabled() and '\n\n'..reason or '') end
	end
	local function CCState()
		if K.CC_GetState then return K:CC_GetState() or {} end
		return {}
	end
	local function CCPresets()
		if K.CC_Presets then return K:CC_Presets() or {} end
		return {}
	end
	local function CCDisabled(method)
		return not K[method] or (method == 'CC_ApplyPreset' and not K.CC_Presets)
			or not K.CC_GetState or not K.CC_IsActive or not K:CC_IsActive() or InCombatLockdown()
	end
	local ccReason = L["Command center loads with Offhand. Enable spanning over two monitors and leave combat to change blocks. Missing API methods stay disabled."]
	local unlocked = false
	local function OffhandMethod(owner, method)
		local addon = _G.Offhand
		local object = addon
		if owner then object = addon and addon[owner] end
		return object and type(object[method]) == 'function' and object or nil
	end
	local function OffhandButton(order, name, owner, method)
		local disabled = function() return not OffhandMethod(owner, method) or InCombatLockdown() end
		return { order = order, type = 'execute', width = 'double', name = name,
			desc = Reason(L["Open the selected Offhand tool. Requires the loaded addon API and leaving combat."], disabled, ccReason),
			disabled = disabled, func = function()
				local object = OffhandMethod(owner, method)
				if object and K:CanApply() then
					local ok, err = pcall(object[method], object)
					if not ok then E:Print(format(L["KnuUI: %s failed: %s"], name, tostring(err))) end
				end
			end }
	end
	local offhand = {
		desc = Desc(1, L["Offhand spans the game window over two monitors. KnuUI keeps ElvUI on the game monitor with the same size and 1 px borders as on a single screen."]),
		status = Desc(2, function()
			local lines = {}
			if K.OffhandStatus then lines[#lines + 1] = K:OffhandStatus() end
			if K.CC_GetState and K.CC_IsActive then
				local state = CCState()
				lines[#lines + 1] = format(L["Command center: %s · %s · %s"], K:CC_IsActive() and L["Active"] or L["Inactive"], L[state.orientation or 'Unknown'], L[state.edge or 'Unknown'])
			else lines[#lines + 1] = L["Command center loads with Offhand"] end
			return table.concat(lines, '\n')
		end),
		presetHead = Head(3, L["Workspace preset"]),
		preset = { order = 4, type = 'select', width = 'double', name = L["Workspace preset"],
			desc = function()
				local text = L["Assign blocks with a command center preset."]
				for _, preset in ipairs(CCPresets()) do
					if preset.id == CCState().preset then text = text..'\n'..L[preset.desc or ''] end
				end
				return text..(CCDisabled('CC_ApplyPreset') and '\n\n'..ccReason or '')
			end,
			values = function() local v = {} for _, p in ipairs(CCPresets()) do v[p.id] = L[p.label] end return v end,
			get = function() return CCState().preset end,
			disabled = function() return CCDisabled('CC_ApplyPreset') end,
			set = function(_, value) if not CCDisabled('CC_ApplyPreset') and K:CanApply() then K:CC_ApplyPreset(value) end end },
		blocksHead = Head(10, L["Block destination"]),
		toolsHead = Head(30, L["Workspace tools"]),
		unlock = { order = 31, type = 'toggle', width = 'full', name = L["Unlock workspace blocks"],
			desc = Reason(L["Allow dragging command center blocks; turn off to lock them again."], function() return CCDisabled('CC_Unlock') end, ccReason),
			disabled = function() return CCDisabled('CC_Unlock') end,
			get = function() return unlocked end,
			set = function(_, value) if not CCDisabled('CC_Unlock') and K:CanApply() then K:CC_Unlock(value); unlocked = value end end },
		reset = { order = 32, type = 'execute', width = 'double', name = L["Reset workspace"],
			desc = Reason(L["Restore command center block assignments and positions."], function() return CCDisabled('CC_Reset') end, ccReason),
			disabled = function() return CCDisabled('CC_Reset') end, confirm = true,
			confirmText = L["Reset command center assignments and positions?"],
			func = function() if not CCDisabled('CC_Reset') and K:CanApply() then K:CC_Reset(); unlocked = false end end },
		options = OffhandButton(33, L["Open Offhand options"], 'Options', 'Open'),
		wizard = OffhandButton(34, L["Open Offhand wizard"], 'Wizard', 'Open'),
		gather = OffhandButton(35, L["Gather off-screen windows"], nil, 'GatherOffScreenUI'),
		diagHead = Head(40, L["Diagnostics"]),
		diag = { order = 41, type = 'execute', width = 'double', name = L["Take a diagnostic snapshot (/knudiag)"],
			desc = Reason(L["Saves the size and position of every KnuUI block to KnuUI's SavedVariables on the next reload."], function() return not K.DiagSnapshot end, L["Diagnostic API is not loaded."]),
			disabled = function() return not K.DiagSnapshot end,
			func = function() if K.DiagSnapshot then if E.global.KnuUIDiagOn then K:DiagSnapshot('manual') else K:DiagEnable(true) end; E:Print(L["Diagnostic snapshot taken; /reload writes it to disk."]) end end },
	}
	local blockLabels = { L["Guide"], L["Chat"], 'Details!', L["Data"], L["Map"], L["Bags"] }
	for i, id in ipairs({ 'guide', 'chat', 'details', 'data', 'map', 'bags' }) do
		local block = id -- captura propia para Lua 5.1
		offhand[block] = { order = 10 + i, type = 'select', width = 'double', name = blockLabels[i],
			desc = Reason(L["Choose the game monitor or the adjacent workspace for this block."], function() return CCDisabled('CC_SetBlock') end, ccReason),
			values = { game = L["Game monitor"], workspace = L["Workspace"] }, sorting = { 'game', 'workspace' },
			disabled = function() return CCDisabled('CC_SetBlock') end,
			get = function() local blocks = CCState().blocks or {}; return blocks[block] and blocks[block].dest or 'game' end,
			set = function(_, value) if not CCDisabled('CC_SetBlock') and K:CanApply() then K:CC_SetBlock(block, value) end end }
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
					shareHead = Head(10, L["Share"]),
					shareDesc = Desc(11, L["Your whole interface in one text: ElvUI profile, role and KnuUI settings. Also /knu export and /knu import."]),
					export = { order = 12, type = 'execute', width = 'double', name = L["Export KnuUI"],
						desc = L["ElvUI profile, role and KnuUI settings in one text. Ctrl+C to copy."],
						func = function() E:ToggleOptions(); K:OpenShare('export') end },
					import = { order = 13, type = 'execute', width = 'double', name = L["Import KnuUI"],
						desc = L["Paste a KnuUI text (Ctrl+V). It is imported into a new profile; yours is not overwritten."],
						func = function() E:ToggleOptions(); K:OpenShare('import') end },
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
					theme = { order = 2, type = 'select', width = 'double', name = L["Palette"],
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
					raidMarkers = { order = 5.5, type = 'select', width = 'double', name = L["Raid marker bar"],
						desc = L["Left click marks your target, right click places a ground marker. Move it with /moveui."],
						values = { group = L["Only in a group"], always = L["Always"], off = L["Off"] },
						sorting = { 'group', 'always', 'off' },
						get = function() return E.db.KnuUIRaidMarkers or 'group' end,
						set = function(_, value) E.db.KnuUIRaidMarkers = value; K:UpdateRaidMarkers() end },
					detailsFade = { order = 5.55, type = 'toggle', width = 'full', name = L["Details very transparent out of combat (eye button above the panel keeps it visible)"],
						get = function() return E.db.KnuUIDetailsFade ~= false end,
						set = function(_, value) E.db.KnuUIDetailsFade = value; K:UpdatePanelFade() end },
					lootMonitor = { order = 5.57, type = 'toggle', width = 'full', name = L["Loot monitor: what you and your group loot, above the right panel"],
						get = function() return E.db.KnuUILootMonitor ~= false end, set = function(_, value) E.db.KnuUILootMonitor = value end },
					lootSelf = { order = 5.58, type = 'select', width = 'normal', name = L["Your loot from"],
						values = { [0] = L["Grey"], [1] = L["White"], [2] = L["Green"], [3] = L["Blue"], [4] = L["Purple"] },
						disabled = function() return E.db.KnuUILootMonitor == false end,
						get = function() return E.db.KnuUILootSelfQuality or 1 end, set = function(_, value) E.db.KnuUILootSelfQuality = value end },
					lootGroup = { order = 5.59, type = 'select', width = 'normal', name = L["Group loot from"],
						values = { [0] = L["Grey"], [1] = L["White"], [2] = L["Green"], [3] = L["Blue"], [4] = L["Purple"] },
						disabled = function() return E.db.KnuUILootMonitor == false end,
						get = function() return E.db.KnuUILootGroupQuality or 2 end, set = function(_, value) E.db.KnuUILootGroupQuality = value end },
					rankUpgrade = { order = 5.595, type = 'toggle', width = 'full', name = L["Replace old spell ranks on your bars when you learn a new one"],
						get = function() return E.db.KnuUIRankUpgrade ~= false end, set = function(_, value) E.db.KnuUIRankUpgrade = value end },
					flightTimer = { order = 5.6, type = 'toggle', width = 'full', name = L["Flight timer (learns each route the first time you fly it)"],
						get = function() return E.db.KnuUIFlightTimer ~= false end, set = function(_, value) E.db.KnuUIFlightTimer = value end },
					panels = { order = 6, type = 'execute', width = 'double', name = L["Reapply chat and Details panels"],
						func = function() if K:ApplyIntegratedPanels() then Reload() end end },
				},
			},
			builds = {
				order = 35, type = 'group', name = L["Builds"], args = {
					header = Head(1, L["Recommended interface builds"]),
					desc = Desc(2, L["Recommendations for your class and role, not talent builds. Selection alone does not apply changes. Applying replaces layout, nameplates and the listed settings in this ElvUI profile."]),
					preset = { order = 3, type = 'select', width = 'double', name = L["Recommended build"],
						desc = L["Defaults to your class and selected role. Only builds for your current class are listed."],
						values = function() local v = {} for id, b in pairs(K.builds) do if b.class == E.myclass then v[id] = b.label end end return v end,
						sorting = function() local v = {} for _, id in ipairs(K.buildOrder) do if K.builds[id].class == E.myclass then v[#v + 1] = id end end return v end,
						get = function() return K:SelectedBuild() end,
						set = function(_, id) if K.builds[id] and K.builds[id].class == E.myclass then E.db.KnuUIBuild = id end end },
					changes = Desc(4, function() local b = K.builds[K:SelectedBuild()]; return b and b.desc or L["No recommended build for this class."] end),
					apply = { order = 5, type = 'execute', width = 'double', name = L["Apply build"],
						desc = function() return L["Confirm to apply the selected interface build and reload. Leave combat first."]..(not K:SelectedBuild() and '\n'..L["No recommended build for this class."] or '') end,
						disabled = function() return not K:SelectedBuild() or InCombatLockdown() end,
						func = function() K.pendingBuild = K:SelectedBuild(); if K.pendingBuild then E:StaticPopup_Show('KNUUI_BUILD') end end },
				},
			},
			addons = {
				order = 40, type = 'group', name = L["Addons"],
				args = {
					desc = Desc(1, L["How KnuUI looks after other addons. Skins need a reload."]),
					pinned = { order = 1.5, type = 'multiselect', width = 'full', name = L["Minimap buttons always visible next to the K"],
						desc = L["The rest stay inside the K launcher."],
						values = function()
							local v = {}
							for key, entry in pairs(K.launcherAddons or {}) do v[key] = entry.label or key end
							return v
						end,
						get = function(_, key) return (E.db.KnuUIPinned or {})[key] == true end,
						set = function(_, key, value)
							E.db.KnuUIPinned = E.db.KnuUIPinned or {}
							E.db.KnuUIPinned[key] = value or nil
							K:RefreshLauncher()
						end },
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
						values = { show = L["Always show"], hide = L["Always hidden"] },
						get = function() return E.db.KnuUIHideTracker and 'hide' or 'show' end,
						set = function(_, value) if K:ApplyTracker(value == 'hide') then Reload() end end },
				},
			},
			offhand = { order = 60, type = 'group', name = 'Offhand', args = offhand },
			camera = {
				order = 50, type = 'group', name = L["Camera"],
				args = {
					desc = Desc(1, L["DynamicCam presets (needs DynamicCam). Applied to a DynamicCam profile called KnuUI."]),
					preset = { order = 2, type = 'select', width = 'double', name = L["Camera preset"],
						values = { ["Shushudaa's preset"] = L["Cinematic (Shushudaa)"], Immersive = L["Soft immersive"], Vanillalike = L["Classic (almost no ActionCam)"] },
						get = function() return E.global.KnuUICameraPreset or "Shushudaa's preset" end,
						set = function(_, value) K:ApplyCamera(true, value) end },
					combatZoom = { order = 3, type = 'toggle', width = 'full', name = L["Maximum camera distance and zoom out in combat"],
						desc = L["Raises the camera limit to the maximum and, with DynamicCam, zooms out when combat starts and back when it ends."],
						get = function() return E.global.KnuUICombatZoom ~= false end,
						set = function(_, value) E.global.KnuUICombatZoom = value; K:ApplyCombatZoom() end },
					cinemaHead = Head(10, L["Cinema mode"]),
					cinemaDesc = Desc(11, L["Hides the interface and slowly orbits the camera; it ends when you enter combat. Also /knu cine or a key binding (Key Bindings > AddOns > KnuUI)."]),
					cinema = { order = 12, type = 'execute', width = 'double', name = L["Start cinema mode"], func = function() K:ToggleCinema() end },
				},
			},
		},
	}
	-- Ayudas breves junto a cada control; las dependencias explican cómo habilitarlo.
	local args = E.Options.args.KnuUI.args
	local help = {
		install = L["Open the step-by-step installer without applying settings."],
		role = L["Rebuild the base layout with the selected role overlay; reload to see it."],
		columns = L["Switch between the base player frame and vertical health and mana columns."],
		nameplates = L["Restore KnuUI cast bars, auras and quest indicators on nameplates."],
		theme = L["Choose a palette. Preview shows accent, highlight, dim accent, text, background and border."],
		classHealth = L["Use each unit's class colour for health instead of the palette health colour."],
		decor = L["Show themed corners, stripes and shadows around KnuUI panels."],
		combatGlow = L["Show a coloured glow at the screen edges during combat."],
		detailsFade = L["Fade Details outside combat; the eye button can keep it visible. Requires Details."],
		lootMonitor = L["Display recent personal and group loot above the right panel."],
		rankUpgrade = L["Replace learned spell ranks on action bars outside combat."],
		flightTimer = L["Show route duration after learning a complete flight."],
		panels = L["Restore the themed chat and Details panels; reload to see changes."],
		addonSkins = L["Apply KnuUI colours and borders to supported addons after reloading."],
		wowpro = L["Apply the KnuUI appearance to WoW-Pro after reloading. Requires WoW-Pro."],
		tracker = L["Choose whether WoW-Pro replaces the Blizzard quest tracker."],
		preset = L["Apply a DynamicCam preset to its KnuUI profile. Requires DynamicCam."],
		cinema = L["Hide the interface and orbit the camera until combat starts; run again to stop."],
	}
	for _, group in pairs(args) do
		if group.args then
			for key, item in pairs(group.args) do
				if item.type ~= 'description' and item.type ~= 'header' and not item.desc then item.desc = help[key] end
			end
		end
	end
	args.general.args.header = Head(1.5, L["Installation"])
	args.look.args.coloursHead = Head(1.5, L["Palette and decoration"])
	args.look.args.effectsHead = Head(4.5, L["Combat and panels"])
	args.look.args.lootHead = Head(5.56, L["Loot and travel"])
	args.addons.args.header = Head(1.2, L["Launcher and skins"])
	args.camera.args.header = Head(1.5, L["Camera settings"])
	args.layout.args.compactLeft.desc = Reason(L["Frees 129 px for the left chat; the data bar shrinks the same."], NoColumns, L["Requires health and mana columns."])
	args.layout.args.compactRight.desc = Reason(L["Frees 129 px for Details; the data bar shrinks the same."], NoColumns, L["Requires health and mana columns."])
	for _, key in ipairs({ 'lootSelf', 'lootGroup' }) do
		args.look.args[key].desc = Reason(L["Minimum item quality shown in the loot monitor."], args.look.args[key].disabled, L["Enable the loot monitor first."])
	end
	local function NeedsAddon(group, key, addon)
		local item = args[group].args[key]
		local disabled = function() return not K:IsLoaded(addon) end
		local text = item.desc
		item.disabled = disabled
		item.desc = Reason(text, disabled, format(L["Requires loaded addon: %s."], addon))
	end
	NeedsAddon('look', 'detailsFade', 'Details')
	NeedsAddon('addons', 'wowpro', 'WoWPro')
	NeedsAddon('addons', 'dbm', 'DBM-Core')
	NeedsAddon('camera', 'preset', 'DynamicCam')
	-- Se trasladan las mismas tablas: getters, setters y dependencias quedan intactos.
	local features = {
		lootHead = args.look.args.lootHead,
		combatHead = Head(10, L["Combat"]),
		travelHead = Head(20, L["Travel"]),
		panelsHead = Head(30, L["Panels"]),
	}
	features.lootHead.order, features.lootHead.name = 1, L["Loot"]
	args.look.args.lootHead = nil
	for key, order in pairs({ lootMonitor = 2, lootSelf = 3, lootGroup = 4,
		raidMarkers = 11, rankUpgrade = 12, flightTimer = 21, detailsFade = 31, panels = 32 }) do
		features[key] = args.look.args[key]
		features[key].order = order
		args.look.args[key] = nil
	end
	args.features = { order = 32, type = 'group', name = L["Features"], args = features }
	args.look.args.effectsHead.name = L["Combat glow"]
	args.look.args.selectedPreview = Desc(2.5, function() return K:ThemePreview(E.db.KnuUITheme or 'knunet') end)

	-- AceConfig evalúa name al mostrar el panel: no se guarda una foto del estado.
	local general = args.general.args
	general.statusHead = Head(0.1, L["Current status"])
	general.version = Desc(0.2, function()
		return format(L["KnuUI version: %s"], C_AddOns.GetAddOnMetadata('KnuUI', 'Version') or L["Unknown"])
	end)
	general.role = Desc(0.3, function()
		local role = E.db.KnuUIRole or E.private.KnuUIRole
		return format(L["Current role: %s"], K.roleNames[role] or L["Unknown"])
	end)
	general.build = Desc(0.4, function()
		local build = K.builds[K:SelectedBuild()]
		return format(L["Selected build: %s"], build and build.label or L["No recommended build for this class."])
	end)
	general.theme = Desc(0.5, function()
		local theme = K.themes[E.db.KnuUITheme or 'knunet'] or K.themes.knunet
		return format(L["Current palette: %s"], theme.label)
	end)
	general.offhand = Desc(0.6, function()
		local text = format(L["Offhand: %s"], K.CC_IsActive and K:CC_IsActive() and L["Active"] or L["Inactive"])
		if K.CC_GetState then
			local state = CCState()
			local label = L["Unknown"]
			for _, preset in ipairs(CCPresets()) do
				if preset.id == state.preset then label = L[preset.label]; break end
			end
			text = text..'\n'..format(L["Workspace preset: %s · Orientation: %s"], label, L[state.orientation or 'Unknown'])
		end
		return text
	end)
	general.skins = Desc(0.7, function()
		return format(L["Addon skins: %s"], E.db.KnuUIAddonSkins ~= false and L["Enabled"] or L["Disabled"])
	end)
	general.header.name = L["Quick actions"]
	general.reapply = args.layout.args.reapply
	general.recommended = { order = 22, type = 'execute', width = 'double', name = L["Apply recommended build"],
		desc = L["Confirm to apply the recommended interface build for your class and role and reload. Leave combat first."],
		disabled = function() return not K:SuggestedBuild() or InCombatLockdown() end,
		func = function() K.pendingBuild = K:SuggestedBuild(); if K.pendingBuild then E:StaticPopup_Show('KNUUI_BUILD') end end }
	general.diag = offhand.diag

	args.look.args.previewHead = Head(7, L["Palette previews"])
	for i, key in ipairs(K.themeOrder) do
		local themeKey = key
		args.look.args['preview_'..key] = Desc(7 + i / 100, function() return K:ThemePreview(themeKey) end)
	end
end

function K:SetupInstaller()
	E.PopupDialogs.KNUUI_BUILD = {
		text = L["Apply the selected interface build to this profile and reload?"],
		button1 = L["Apply and reload"], button2 = L["Cancel"],
		OnAccept = function()
			local id = K.pendingBuild
			K.pendingBuild = nil
			if id and K:ApplyBuild(id) then ReloadUI() end
		end,
		OnCancel = function() K.pendingBuild = nil end,
		timeout = 0, whileDead = true, hideOnEscape = true,
	}
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
		elseif command == 'export' or command == 'exportar' then K:OpenShare('export')
		elseif command == 'import' or command == 'importar' then K:OpenShare('import')
		else K:OpenInstaller() end
	end
	E.Libs.EP:RegisterPlugin(self.addonName, Options)
end
