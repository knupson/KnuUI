-- Se ejecuta desde verificar.lua con el mismo motor, widgets y cola diferida.
local E, K, loaded, Widget, calls, SetCombat, Flush = ...
local oldPrint, errors = E.Print, {}
E.Print = function(_, message) errors[#errors + 1] = message end
local function Load(addon, file)
	local source = assert(io.open('addons/KnuUI/Skins/AddOns/'..file, 'r'))
	local text = source:read('*a'); source:close()
	assert(text:find("K:RegisterSkin('"..addon.."'", 1, true), addon..': falta registro')
	loaded[addon] = true
	K.addonSkinEvents.OnEvent(nil, 'ADDON_LOADED', addon)
end
local function Child(kind)
	local child = Widget(); child.kind = kind
	return child
end

-- Offhand: cuatro ventanas tardías, controles y repintado, sin tocar el canvas.
local previousOffhand = _G.Offhand
local controls = { StyleSurface = function(frame) frame:SetBackdropColor(1, 0, 0, 1) end }
_G.Offhand = { UIControls = controls, db = { theme = 'CLASSIC' } }
Load('Offhand', 'OffhandUI.lua')
local canvas = CreateFrame('Frame', 'OffhandCanvasFrame')
for _, name in ipairs({ 'OffhandFloatingConfigFrame', 'OffhandSetupWizardFrame', 'OffhandFirstLaunchFrame', 'OffhandWhatsNewFrame' }) do
	local frame = CreateFrame('Frame', name)
	local button, check, edit, slider, bar = Child('Button'), Child('CheckButton'), Child('EditBox'), Child('Slider'), Child('Slider')
	bar.globalName = 'OffhandTestScrollBar'
	local close = Child('Button')
	function close:GetNormalTexture() return { GetAtlas = function() return 'RedButton-Exit' end } end
	frame.children = { button, check, edit, slider, bar, close }
	SetCombat(true); Flush()
	assert(not frame.template and not calls[button])
	SetCombat(false); K.addonSkinEvents.OnEvent(nil, 'PLAYER_REGEN_ENABLED')
	assert(frame.template == 'Transparent' and frame.KnuAccentLine)
	assert(calls[button] == 'HandleButton' and calls[check] == 'HandleCheckBox')
	assert(calls[edit] == 'HandleEditBox' and calls[bar] == 'HandleScrollBar')
	assert(calls[close] == 'HandleCloseButton' and slider.template == 'Transparent')
	assert(edit.font == 'Expressway')
	controls.StyleSurface(button)
	assert(button.background[1] == K:GetTheme().backdropFade.r)
	E.db.KnuUIAddonSkinsOff.Offhand = true
	controls.StyleSurface(button); assert(button.background[1] == 1)
	E.db.KnuUIAddonSkinsOff.Offhand = nil
	_G[name] = nil
end
assert(not canvas.template and _G.Offhand.db.theme == 'CLASSIC')
_G.OffhandCanvasFrame, _G.Offhand = nil, previousOffhand

-- MaxDps: creación tardía y combate; ni StripTextures ni recorrido de hijos/brillo.
Load('MaxDps', 'MaxDps.lua')
local spell = CreateFrame('Frame', 'MaxDpsSpellFrame')
local icon, glow = Child('Texture'), Child('Frame')
spell.regions, spell.children = { icon }, { glow }
SetCombat(true); Flush(); assert(not spell.border)
SetCombat(false); K.addonSkinEvents.OnEvent(nil, 'PLAYER_REGEN_ENABLED')
assert(spell.border[1] == K:GetTheme().border.r)
assert(not spell.stripped and not spell.template and not icon.alpha and not glow.template)
_G.MaxDpsSpellFrame = nil

-- GatherMate2: el contenedor real sin texturas se omite por completo.
local gather = CreateFrame('Frame', 'GatherMate2_GenericDropDownMenu')
Load('GatherMate2', 'GatherMate2.lua'); Flush()
assert(not gather.stripped and not gather.template and not gather.KnuAccentLine)
_G.GatherMate2_GenericDropDownMenu = nil

-- HandyNotes: campos reales del editor, barra del template e icono conservado.
local handy = CreateFrame('Frame', 'HNEditFrame')
for _, field in ipairs({ 'titleTexture', 'title', 'titletext', 'desctext', 'titleinputframe', 'descframe', 'titleinputbox', 'descinputbox', 'CloseButton', 'continentcheckbox', 'okbutton', 'cancelbutton', 'descscrollframe', 'icondropdown' }) do handy[field] = Widget() end
handy.descscrollframe.ScrollBar = Widget()
handy.icondropdown.texture = Child('Texture')
local original = Child('Texture')
handy.icondropdown.regions = { original, handy.icondropdown.texture }
Load('HandyNotes', 'HandyNotes.lua'); Flush()
assert(handy.KnuAccentLine and handy.titleTexture.alpha == 0 and handy.title.font == 'Expressway')
assert(calls[handy.titleinputbox] == 'HandleEditBox' and calls[handy.descinputbox] == 'HandleEditBox')
assert(calls[handy.CloseButton] == 'HandleCloseButton' and calls[handy.okbutton] == 'HandleButton' and calls[handy.cancelbutton] == 'HandleButton')
assert(calls[handy.continentcheckbox] == 'HandleCheckBox' and calls[handy.descscrollframe.ScrollBar] == 'HandleScrollBar')
assert(original.alpha == 0 and not handy.icondropdown.texture.alpha and not handy.icondropdown.point)
_G.HNEditFrame = nil
for _, addon in ipairs({ 'Offhand', 'MaxDps', 'GatherMate2', 'HandyNotes' }) do loaded[addon] = nil end
E.Print = oldPrint
assert(#errors == 0, table.concat(errors, '\n'))
