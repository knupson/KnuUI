local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')
local D = E:GetModule('Distributor')

-- Exportar/importar toda la interfaz en un texto (pedido del user 2026-11-13, "todo en uno"): el perfil de
-- ElvUI completo (incluye las opciones de KnuUI que viven en E.db), el rol del personaje (E.private) y las
-- opciones globales de KnuUI (E.global). El perfil se arma igual que el exportador de ElvUI
-- (Distributor.lua:442-458: sólo lo distinto de los valores por defecto, sin las claves de su lista negra) y
-- el texto se codifica con las mismas funciones (C_EncodingUtil: CBOR, Deflate y Base64, Distributor.lua:12-17).
-- Al importar nunca se pisa un perfil existente: se crea uno nuevo con otro nombre si hace falta.
local PREFIX = '!KNU1!'
local GLOBAL_KEYS = { 'KnuUICameraPreset', 'KnuUICombatZoom', 'KnuUICombatZoomV', 'KnuUIClock', 'KnuUISPFQuiet', 'KnuUIFlights' }
local Enc = C_EncodingUtil
local Enums = _G.Enum or {}
local COMPRESS = Enums.CompressionMethod and Enums.CompressionMethod.Deflate or 0
local LEVEL = Enums.CompressionLevel and Enums.CompressionLevel.Default or 0

function K:ExportString()
	if not (Enc and Enc.SerializeCBOR) then return nil, L["This client cannot encode the text."] end
	local key, profile = D:GetProfileData('profile')
	if not key or type(profile) ~= 'table' then return nil, L["Could not read the ElvUI profile."] end
	-- ElvUI sólo exporta claves que existen en sus valores por defecto (Core.lua:859-860: RemoveTableDuplicates):
	-- todas las opciones KnuUI* del perfil quedaban afuera (visto en el juego 2026-11-13: al importar se abría el
	-- instalador). Se agregan tal cual, menos el estado interno del centro de comando (lo que guarda para
	-- devolver al salir: *Orig y questLogOpen), que es de esta PC.
	local raw = ElvDB.profiles[key] or {}
	for k, v in pairs(raw) do
		if type(k) == 'string' and k:find('^KnuUI') then
			if k == 'KnuUICC' and type(v) == 'table' then
				local cc = {}
				for ck, cv in pairs(v) do
					if not (type(ck) == 'string' and (ck:find('Orig$') or ck == 'questLogOpen' or ck == 'autoresizeFixed')) then
						cc[ck] = type(cv) == 'table' and E:CopyTable({}, cv) or cv
					end
				end
				profile[k] = cc
			else
				profile[k] = type(v) == 'table' and E:CopyTable({}, v) or v
			end
		end
	end
	local global = {}
	for _, k in ipairs(GLOBAL_KEYS) do
		if E.global[k] ~= nil then global[k] = E.global[k] end
	end
	-- Los paneles de datos propios (KnuUI_Data, etc.) se definen en lo global y el perfil sólo los configura
	-- (Layout.lua:301-310; ElvUI los crea desde lo global, DataTexts.lua:1055): sin esto no aparecen.
	local panels = E.global.datatexts and E.global.datatexts.customPanels
	local payload = { knuui = 1, key = key, profile = profile, private = { KnuUIRole = E.private.KnuUIRole }, global = global,
		panels = panels and E:CopyTable({}, panels) or nil }
	local ok, out = pcall(function()
		return PREFIX .. Enc.EncodeBase64(Enc.CompressString(Enc.SerializeCBOR(payload), COMPRESS, LEVEL))
	end)
	if not ok or not out then return nil, L["Could not encode the text."] end
	return out
end

local function Decode(text)
	text = (text or ''):gsub('%s', '')
	if text:sub(1, #PREFIX) ~= PREFIX then return nil, L["This is not a KnuUI text."] end
	local ok, payload = pcall(function()
		return Enc.DeserializeCBOR(Enc.DecompressString(Enc.DecodeBase64(text:sub(#PREFIX + 1)), COMPRESS))
	end)
	if not ok or type(payload) ~= 'table' or payload.knuui ~= 1 or type(payload.profile) ~= 'table' then
		return nil, L["The text is damaged or incomplete."]
	end
	return payload
end

local function FreeName(base)
	base = (type(base) == 'string' and base ~= '') and base or 'KnuUI'
	if not ElvDB.profiles[base] then return base end
	local i = 2
	while ElvDB.profiles[format('%s (%d)', base, i)] do i = i + 1 end
	return format('%s (%d)', base, i)
end

function K:ImportString(text)
	if InCombatLockdown() then return nil, L["Leave combat before applying KnuUI."] end
	local payload, err = Decode(text)
	if not payload then return nil, err end
	-- También las vacías: nil tiene significado propio (p. ej. KnuUICombatZoom nil = prendido, Camera.lua:133).
	local global = type(payload.global) == 'table' and payload.global or {}
	for _, k in ipairs(GLOBAL_KEYS) do E.global[k] = global[k] end
	if type(payload.panels) == 'table' and E.global.datatexts then
		E.global.datatexts.customPanels = E.global.datatexts.customPanels or {}
		for name, def in pairs(payload.panels) do
			if type(def) == 'table' then E.global.datatexts.customPanels[name] = E:CopyTable({}, def) end
		end
	end
	if type(payload.private) == 'table' and type(payload.private.KnuUIRole) == 'string' then
		E.private.KnuUIRole = payload.private.KnuUIRole
	end
	local name = FreeName(payload.key)
	ElvDB.profiles[name] = E:FilterTableFromBlacklist(payload.profile, D.blacklistedKeys.profile)
	E.data:SetProfile(name)
	return name
end

-- Ventana con un cuadro de texto para copiar o pegar.
local win
local function Window()
	if win then return win end
	local S = E:GetModule('Skins')
	local f = CreateFrame('Frame', 'KnuUI_ShareFrame', E.UIParent)
	f:SetSize(560, 360)
	f:SetPoint('CENTER')
	f:SetFrameStrata('DIALOG')
	f:SetTemplate('Transparent')
	if K.KnuFrame then K:KnuFrame(f) end
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag('LeftButton')
	f:SetScript('OnDragStart', f.StartMoving)
	f:SetScript('OnDragStop', f.StopMovingOrSizing)
	f:SetClampedToScreen(true)
	table.insert(UISpecialFrames, 'KnuUI_ShareFrame')

	f.title = f:CreateFontString(nil, 'OVERLAY')
	f.title:FontTemplate(nil, 14, 'OUTLINE')
	f.title:SetPoint('TOP', 0, -10)
	f.hint = f:CreateFontString(nil, 'OVERLAY')
	f.hint:FontTemplate(nil, 11)
	f.hint:SetPoint('TOP', f.title, 'BOTTOM', 0, -6)
	f.hint:SetWidth(530)

	local scroll = CreateFrame('ScrollFrame', 'KnuUI_ShareScroll', f, 'UIPanelScrollFrameTemplate')
	scroll:SetPoint('TOPLEFT', 12, -52)
	scroll:SetPoint('BOTTOMRIGHT', -32, 44)
	if S and S.HandleScrollBar and _G.KnuUI_ShareScrollScrollBar then S:HandleScrollBar(_G.KnuUI_ShareScrollScrollBar) end
	local box = CreateFrame('EditBox', nil, scroll)
	box:SetMultiLine(true)
	box:SetAutoFocus(false)
	box:SetFontObject(_G.ChatFontNormal)
	box:SetWidth(510)
	box:SetScript('OnEscapePressed', function() f:Hide() end)
	scroll:SetScrollChild(box)
	f.box = box
	local bg = CreateFrame('Frame', nil, f)
	bg:SetPoint('TOPLEFT', scroll, -4, 4)
	bg:SetPoint('BOTTOMRIGHT', scroll, 24, -4)
	bg:SetTemplate('Default')
	bg:SetFrameLevel(scroll:GetFrameLevel() - 1)
	scroll:EnableMouse(true)
	scroll:SetScript('OnMouseDown', function() box:SetFocus() end)

	local function Button(label, x, onClick)
		local b = CreateFrame('Button', nil, f, 'UIPanelButtonTemplate')
		b:SetSize(150, 24)
		b:SetPoint('BOTTOM', x, 12)
		b:SetText(label)
		if S and S.HandleButton then S:HandleButton(b) end
		b:SetScript('OnClick', onClick)
		return b
	end
	f.action = Button('', -80, function()
		if f.mode == 'export' then
			box:SetFocus(); box:HighlightText()
		else
			local name, err = K:ImportString(box:GetText())
			if not name then E:Print('KnuUI: ' .. err) return end
			f:Hide()
			E:Print(format(L["KnuUI: imported into the profile \"%s\". Reloading is recommended."], name))
			E:StaticPopup_Show('CONFIG_RL')
		end
	end)
	Button(L["Close"], 80, function() f:Hide() end)
	f:Hide()
	win = f
	return f
end

function K:OpenShare(mode)
	local f = Window()
	f.mode = mode
	if mode == 'export' then
		local text, err = K:ExportString()
		if not text then E:Print('KnuUI: ' .. err) return end
		f.title:SetText(L["Export KnuUI"])
		f.hint:SetText(L["ElvUI profile, role and KnuUI settings in one text. Ctrl+C to copy."])
		f.action:SetText(L["Select all"])
		f.box:SetText(text)
		f:Show()
		f.box:SetFocus()
		f.box:HighlightText()
	else
		f.title:SetText(L["Import KnuUI"])
		f.hint:SetText(L["Paste a KnuUI text (Ctrl+V). It is imported into a new profile; yours is not overwritten."])
		f.action:SetText(L["Import"])
		f.box:SetText('')
		f:Show()
		f.box:SetFocus()
	end
end
