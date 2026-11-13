local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')
local S = E:GetModule('Skins')
local handled = setmetatable({}, { __mode = 'k' })

local function Handle(frame, method)
	if not frame or handled[frame] then return end
	S[method](S, frame)
	handled[frame] = true
end

local function Theme(frame)
	if not frame then return end
	frame:SetTemplate('Transparent')
	local t = K:GetTheme()
	frame:SetBackdropColor(t.backdropFade.r, t.backdropFade.g, t.backdropFade.b, t.backdropFade.a)
	frame:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b)
end

local function Style(frame)
	-- HandyNotes/HandyNotes_EditFrame.lua:17,36,41: ventana, adorno y título.
	if frame.titleTexture then frame.titleTexture:SetAlpha(0) end
	if K.KnuFrame then K:KnuFrame(frame) end
	K:SkinFont(frame.title, true)
	-- Contenedores :72,94; entradas :77,104; scroll :99 (barra del template).
	Theme(frame.titleinputframe)
	Theme(frame.descframe)
	Handle(frame.titleinputbox, 'HandleEditBox')
	Handle(frame.descinputbox, 'HandleEditBox')
	local scroll = frame.descscrollframe
	Handle(scroll and (scroll.ScrollBar or _G.HandyNotes_EditScrollFrameScrollBar), 'HandleScrollBar')
	-- Cierre :62; casilla :185; aceptar :203; cancelar :210.
	Handle(frame.CloseButton, 'HandleCloseButton')
	Handle(frame.continentcheckbox, 'HandleCheckBox')
	Handle(frame.okbutton, 'HandleButton')
	Handle(frame.cancelbutton, 'HandleButton')
	-- Selector :137 y su icono :143. HandleDropDownBox reancla botón/texto y borra el icono:
	-- sólo fondo y borde propios, sin tocar anclajes ni la textura de la selección.
	local dropdown = frame.icondropdown or _G.HandyNotes_IconDropDown
	if dropdown and not handled[dropdown] then
		local regions = { dropdown:GetRegions() }
		for _, r in ipairs(regions) do
			if r ~= dropdown.texture and r:IsObjectType('Texture') then r:SetAlpha(0) end
		end
		Theme(dropdown)
		handled[dropdown] = true
	end
	-- Etiquetas :67,89,189; texto del selector :149.
	for _, text in ipairs({ frame.titletext, frame.desctext, frame.continentcheckbox and frame.continentcheckbox.string, dropdown and dropdown.Text }) do K:SkinFont(text) end
	K:SkinFont(frame.titleinputbox)
	K:SkinFont(frame.descinputbox)
end

K:RegisterSkin('HandyNotes', function()
	K:WatchAddonFrame('HandyNotes', 'HNEditFrame', function(frame) pcall(Style, frame) end, true)
end)
