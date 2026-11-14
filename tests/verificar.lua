-- Ejecutar desde la raíz del repo con Lua 5.1 o posterior. No requiere WoW.
unpack = unpack or table.unpack
DEFAULT_CHAT_FRAME = { GetName = function() return 'ChatFrame1' end }
function GetCurrentRegion() return 1 end
local E = { Forever = true, Modern = true, myclass = 'PALADIN', filterMax = 8 }
local P, G, V = {}, {}, {}
ElvUI = { E, {}, V, P, G }
function E:CopyTable(dst, src)
	dst = dst or {}
	for k, v in pairs(src) do
		dst[k] = type(v) == 'table' and self:CopyTable({}, v) or v
	end
	return dst
end
function E:GetName() return 'ElvUI' end
function E:GetLocale() return 'esES' end
for _, file in ipairs({ 'Profile', 'Global', 'Private' }) do
	local path = '_ref/ElvUI/Game/Shared/Defaults/'..file..'.lua'
	local chunk = loadfile(path)
	-- Los worktrees no copian _ref; usar la referencia compartida del repo principal.
	-- KNUUI_REF_ROOT: carpeta que contiene _ref (con barra al final).
	if not chunk and os.getenv('KNUUI_REF_ROOT') then chunk = loadfile(os.getenv('KNUUI_REF_ROOT')..path) end
	assert(chunk, 'falta ' .. path .. ' (correr desde la carpeta que tiene _ref o definir KNUUI_REF_ROOT)')
	chunk()
end

local function Check(db, schema, path)
	for key, value in pairs(db) do
		assert(schema[key] ~= nil, 'Clave sin verificar: '..path..'.'..tostring(key))
		if type(value) == 'table' then Check(value, schema[key], path..'.'..tostring(key)) end
	end
end

local module, installer, options
local health, faded, healthHook = 100, 0, nil
local parent = {
 GetAlpha = function() return 0.2 end,
 HookScript = function(_, event, callback) assert(event == 'OnEvent'); healthHook = callback end,
}
local actionbars = { fadeParent = parent, FadeBlings = function(_, alpha) assert(alpha == 1) end }
function UnitHealth() return health end
function UnitHealthMax() return 100 end
function E:UIFrameFadeIn(frame, seconds, from, to)
 assert(frame == parent and seconds == 0.2 and from == 0.2 and to == 1)
 faded = faded + 1
end
function E:NewModule(name)
 module = { GetName = function() return name end }
 return module
end
function E:RegisterModule(name) assert(name == 'KnuUI') end
local pi = {
 Queue = function(_, data) installer = data end,
 SetupReset = function() end,
 SetPage = function(_, page) installer.Pages[page]() end,
}
local skinCallsByHelper = {}
local skins = {}
for _, method in ipairs({ 'HandleButton', 'HandleCheckBox', 'HandleEditBox', 'HandleSliderFrame', 'HandleScrollBar', 'HandleCloseButton' }) do
 skins[method] = function(_, frame) skinCallsByHelper[frame] = method end
end
function E:GetModule(name)
 if name == 'KnuUI' then return assert(module) end
 if name == 'ActionBars' then return actionbars end
 if name == 'DataTexts' then return { PanelPool = { InUse = { KnuUI_Data = _G.KnuTestData } } } end
 if name == 'Skins' then return skins end
 if name == 'AFK' or name == 'Layout' or name == 'Chat' or name == 'Minimap' or name == 'UnitFrames' or name == 'Distributor' then return {} end
 assert(name == 'PluginInstaller'); return pi
end
E.Libs = { EP = { RegisterPlugin = function(_, name, callback)
 assert(name == 'KnuUI'); options = callback
end } }
E.Libs.LSM = { Fetch = function(_, kind, name)
 if kind == 'statusbar' then assert(name == 'Melli'); return 'Melli.tga' end
 assert(kind == 'font' and name == 'Expressway'); return 'Expressway.ttf'
end }
function E:IsSecretValue() return false end
E.PopupDialogs, E.Options = {}, { args = {} }
local popup, reloads, combat = nil, 0, false
function E:StaticPopup_Show(name) popup = name end
function E:Print(message) assert(type(message) == 'string') end
function InCombatLockdown() return combat end
function ReloadUI() reloads = reloads + 1 end
SlashCmdList = {}
local loaded = {}
C_Timer = { NewTicker = function() return {} end, After = function(_, callback) callback() end }
C_AddOns = {
 IsAddOnLoaded = function(name) return loaded[name] end,
 GetAddOnMetadata = function(name, field)
  assert(name == 'KnuUI' and field == 'Version'); return 'prueba-version'
 end,
}
function hooksecurefunc(object, method, callback)
 if type(object) == 'string' then object, method, callback = _G, object, method end
 local original = object[method]
 object[method] = function(...)
  local result = { original(...) }
  callback(...)
  return unpack(result)
 end
end

-- Simulación de los botones del PluginInstaller, sin APIs del juego.
local buttons = {}
local function Widget()
 local w = { enabled = true }
 function w:SetText(text) self.text = text end
 function w:SetScript(event, callback) self[event] = callback end
 function w:Show() local changed = not self.shown; self.shown = true; if changed and self.OnShow then self:OnShow() end end
 function w:Hide() local changed = self.shown; self.shown = false; if changed and self.OnHide then self:OnHide() end end
 function w:Enable() self.enabled = true end
 function w:Disable() self.enabled = false end
 function w:SetWidth(value) self.width = value end
 function w:SetHeight(value) self.height = value end
 function w:ClearAllPoints() end
 function w:SetPoint(...) self.point = { ... } end
 function w:SetSize(width, height) self.width, self.height = width, height end
 function w:GetSize() return self.width or 400, self.height or 180 end
 function w:GetTop() return 180 end
 function w:GetBottom() return 0 end
 function w:GetLeft() return 0 end
 function w:GetRight() return self.width or 400 end
 function w:GetChildren() return unpack(self.children or {}) end
 function w:GetRegions() return unpack(self.regions or {}) end
 function w:GetObjectType() return self.kind or 'Frame' end
 function w:IsObjectType(kind) return self:GetObjectType() == kind end
 function w:GetText() return self.text end
 function w:StripTextures() self.stripped = true end
 function w:SetStatusBarTexture(texture) self.statusTexture = texture end
 function w:GetEffectiveScale() return 1 end
 function w:GetScale() return 1 end
 function w:IsShown() return self.shown ~= false end
 function w:GetAlpha() return 1 end
 function w:RegisterEvent(event) self.events = self.events or {}; self.events[event] = true end
 function w:UnregisterEvent(event) if self.events then self.events[event] = nil end end
 function w:HookScript(event, callback)
  local original = self[event]
  self[event] = function(...) if original then original(...) end; callback(...) end
 end
 function w:SetTemplate(template) self.template = template end
 function w:SetBackdropColor(...) self.background = { ... } end
 function w:SetBackdropBorderColor(...) self.border = { ... } end
 function w:SetFont(font, size) self.font, self.fontSize = font, size end
 function w:GetFont() return self.font, self.fontSize end
 function w:FontTemplate(font, size) self:SetFont(font, size) end
 function w:SetTextColor(...) self.color = { ... } end
 function w:SetColorTexture(...) self.color = { ... } end
 function w:SetNormalTexture(value) self.normal = value end
 function w:SetPushedTexture(value) self.pushed = value end
 function w:CreateFontString() return Widget() end
 function w:CreateTexture()
  local texture = Widget()
  self.textures = self.textures or {}; self.textures[#self.textures + 1] = texture
  return texture
 end
 function w:SetTexture(value) self.texture = value end
 function w:SetShown(value) self.shown = not not value end
 function w:SetFrameStrata() end
 function w:SetClampedToScreen() end
 function w:SetJustifyH() end
 function w:SetBlendMode() end
 function w:GetBackdropBorderColor() return unpack(self.border or {}) end
 function w:RegisterForClicks() end
 function w:SetWordWrap() end
 function w:EnableMouse() end
 function w:GetTexture() return self.texture end
 function w:SetAllPoints() end
 function w:GetFrameLevel() return 5 end
 function w:GetFrameStrata() return 'BACKGROUND' end
 function w:GetPoint() return 'TOPLEFT', E.UIParent, 'TOPLEFT', 0, 0 end
 function w:GetName() return self.globalName end
 function w:SetMovable(value) self.movable = value end
 function w:SetFrameLevel() end
 function w:SetBackdrop(value) self.backdropInfo = value end
 function w:SetAlpha(value) self.alpha = value end
 function w:SetTexCoord(...) self.coords = { ... } end
 function w:SetVertexColor(...) self.tint = { ... } end
 function w:SetHorizTile() end
 function w:CreateShadow(size, pass) assert(size == 3 and pass); return Widget() end
 return w
end
local eventFrames = {}
function CreateFrame(kind, name, frame, template)
 local widget = Widget()
 widget.kind, widget.globalName = kind, name
 if frame == PluginInstallFrame then
  assert(kind == 'Button' and template == 'UIPanelButtonTemplate')
  buttons[#buttons + 1] = widget
 elseif kind == 'Frame' and not name then
  eventFrames[#eventFrames + 1] = widget
 end
 if name then _G[name] = widget end
 return widget
end
UISpecialFrames = {}
E.Media = { Textures = { White8x8 = 'blanco' } }
E.UIParent = Widget()
Minimap = Widget(); Minimap.backdrop = Widget(); Minimap.location = Widget()
MinimapPanel, LeftChatPanel, RightChatPanel = Widget(), Widget(), Widget()
ElvUF_Player, ElvUF_Target, KnuTestData = Widget(), Widget(), Widget()
ElvUI_Bar1 = Widget()
WorldMapFrame = { backdrop = Widget() }
function E:CreateMover(frame, name)
 assert(name == 'KnuUI_ButtonsMover'); frame.moverName = name
end
PluginInstallFrame = { SubTitle = Widget(), Desc1 = Widget(), Desc2 = Widget(), Desc3 = Widget(), tutorialImage = Widget() }
for i = 1, 4 do PluginInstallFrame['Option'..i] = Widget() end

local function Fresh()
 E.db = E:CopyTable({}, P); E.global = E:CopyTable({}, G); E.private = E:CopyTable({}, V)
 E.private.bags.enable = false
 E.db.tooltip.xOffset = 17
 E.db.movers = { Ajeno = 'posición ajena', DTPanelForeverUI_DataMover = 'viejo' }
 E.db.datatexts.panels.ForeverUI_Data = { enable = true }
 E.db.datatexts.panels.Darth_Panel_1 = { enable = true }
 E.db.unitframe.units.player.customTexts.Ajeno = { text_format = '[name][absorbs:sl-short]' }
end

Fresh()
-- Cargar los archivos en el orden real del TOC también detecta nombres obsoletos.
format = format or string.format
GetLocale = GetLocale or function() return 'esES' end
date = date or os.date
debugstack = debugstack or function() return '' end
local ns = {} -- tabla compartida entre archivos (Locales/Locales.lua define ns.L)
for line in io.lines('addons/KnuUI/KnuUI.toc') do
 local file = line:match('^([%w_/%-]+%.lua)%s*$')
 if file then assert(loadfile('addons/KnuUI/'..file))('KnuUI', ns) end
end
-- Reutiliza el entorno sin ejecutar la batería ni sembrar perfiles ajenos.
if ... == 'render-harness' then
 return { E = E, K = module, fresh = function()
  E.db = E:CopyTable({}, P)
  E.global = E:CopyTable({}, G)
  E.private = E:CopyTable({}, V)
 end }
end
module:Initialize()
assert(installer and #installer.Pages == 7 and #installer.StepTitles == 7)
assert(installer.tutorialImage == [[Interface\AddOns\KnuUI\media\logo]])
assert(installer.tutorialImageSize[1] == 256 and installer.tutorialImageSize[2] == 128)
assert(not E.db.datatexts.panels.ForeverUI_Data.enable and not E.db.movers.DTPanelForeverUI_DataMover)
assert(module.buttons.moverName == 'KnuUI_ButtonsMover' and module.buttons.width == 26)
assert(module.flyout.rows[6].entry.label == 'Asistente de KnuUI' and not module.flyout.rows[7].shown)
assert(UISpecialFrames[1] == 'KnuUI_LauncherPanel' and E.db.KnuUIDecor)
assert(E.db.KnuUISkinWoWPro == true)
-- Migración profunda: el respaldo anterior jamás comparte tablas con el perfil.
E.db.KnuUIDock = nil
ForeverDockDB = { enabled = false, split = 0.6, wasLocked = { true }, savedStates = { { width = 321 } } }
local dock = module:GetDockDB()
assert(not dock.enabled and dock.split == 0.6 and dock.savedStates[1].width == 321)
dock.savedStates[1].width = 123
assert(ForeverDockDB.savedStates[1].width == 321)
local count = #eventFrames
loaded.ForeverDock = true
module:SetupDock(); module:SetupDock()
assert(#eventFrames == count) -- No instala eventos ni hooks competidores.
loaded.ForeverDock = nil
dock.enabled = true
options()
-- Menú en pestañas: cada grupo tiene descripción y todos los controles tienen nombre.
local menu = E.Options.args.KnuUI
assert(menu.childGroups == 'tab')
for _, key in ipairs({ 'general', 'layout', 'look', 'features', 'builds', 'addons', 'camera', 'offhand' }) do
 local group = menu.args[key]
 assert(group and group.type == 'group', key)
 for name, item in pairs(group.args) do
  assert(item.type and item.name ~= nil and item.order, key..'.'..name)
  if item.type == 'toggle' or item.type == 'select' or item.type == 'execute' or item.type == 'multiselect' then
   assert(item.width and item.desc, key..'.'..name..' sin ancho o ayuda')
   local desc = type(item.desc) == 'function' and item.desc() or item.desc
   assert(type(desc) == 'string' and #desc > 0, key..'.'..name..' sin descripción')
  end
 end
end
assert(menu.args.layout.args.reapply.type == 'execute' and menu.args.look.args.theme.type == 'select')
assert(menu.args.layout.args.compactRight.disabled() == not E.db.KnuUITanks)
-- Conjunto congelado antes de reorganizar: ninguna clave anterior puede desaparecer.
do
 local keys = { KnuUI = true }
 local function Collect(node)
  for key, item in pairs(node.args or {}) do keys[key] = true; Collect(item) end
 end
 Collect(menu)
 for _, key in ipairs(assert(loadfile('addons/KnuUI/tests/opciones-claves.lua'))()) do
  assert(keys[key], 'Opción perdida: '..key)
 end
 assert(menu.args.features.order == 32 and menu.args.features.name == 'Funciones')
 for _, key in ipairs({ 'lootMonitor', 'lootSelf', 'lootGroup', 'rankUpgrade', 'flightTimer', 'raidMarkers', 'detailsFade', 'panels' }) do
  assert(menu.args.features.args[key] and not menu.args.look.args[key], key)
 end
 for key, label in pairs({ lootHead = 'Botín', combatHead = 'Combate', travelHead = 'Viajes', panelsHead = 'Paneles' }) do
  assert(menu.args.features.args[key].type == 'header' and menu.args.features.args[key].name == label)
 end
 assert(menu.args.general.args.reapply == menu.args.layout.args.reapply)
 assert(menu.args.general.args.diag == menu.args.offhand.args.diag)
 assert(menu.args.look.args.theme.name == 'Paleta' and menu.args.look.args.theme.sorting == module.themeOrder)
end
SlashCmdList.KNUUI('')
assert(not popup and reloads == 0 and not E.db.datatexts.panels.KnuUI_Data)
SlashCmdList.KNUUI(' aplicar ')
assert(popup == 'KNUUI_APPLY' and reloads == 0)

-- Cada sección conserva las otras; no recarga por su cuenta.
local chatWidth = E.db.chat.panelWidth
local oldFont = E.db.unitframe.font
assert(module:ApplyLayout())
assert(E.db.movers.ElvUF_TargetTargetMover == 'BOTTOM,ElvUIParent,BOTTOM,507,192')
assert(E.db.unitframe.units.targettarget.width == 92 and E.db.unitframe.units.targettarget.height == 24)
assert(not E.db.movers.ElvUF_TargetCastbarMover)
assert(E.db.unitframe.units.target.castbar.overlayOnFrame == 'Power')
assert(E.db.unitframe.units.player.castbar.overlayOnFrame == 'None')
assert(E.db.unitframe.units.target.smartAuraPosition == 'DISABLED')
for _, key in ipairs({ 'buffs', 'debuffs' }) do
 local aura = E.db.unitframe.units.target[key]
 assert(aura.attachTo == 'FRAME' and aura.anchorPoint == 'TOPLEFT')
 assert(aura.growthX == 'RIGHT' and aura.growthY == 'UP' and aura.numrows == 1)
 assert(aura.perrow == 8 and aura.sizeOverride == 28 and aura.spacing == 2)
 assert(aura.yOffset == (key == 'buffs' and 2 or 32))
end
assert(E.db.chat.panelWidth == chatWidth and E.db.unitframe.font == oldFont)
assert(not E.db.datatexts.panels.KnuUI_Data and reloads == 0)
local layoutMover = E.db.movers.ElvAB_1
assert(module:ApplyTheme(false))
assert(E.db.movers.ElvAB_1 == layoutMover and not E.db.KnuUIClassHealth)
assert(not E.db.unitframe.colors.healthclass and E.db.unitframe.colors.health.g == module:GetTheme().health.g)
assert(module:ApplyTheme() and not E.db.KnuUIClassHealth)
assert(module:ApplyTheme(true) and E.db.unitframe.colors.healthclass)
assert(module:ApplyChat() and reloads == 0)
assert(E.db.chat.editBoxPosition == 'ABOVE_CHAT')

local function Validate()
 assert(E.private.bags.enable == false and E.db.tooltip.xOffset == 17)
 assert(E.db.movers.Ajeno == 'posición ajena')
 assert(E.db.unitframe.statusbar == 'Melli' and E.db.unitframe.font == 'Expressway')
 assert(E.db.unitframe.units.player.customTexts.Ajeno.text_format == '[name]')
 assert(E.db.chat.panelWidth == 401 and E.db.chat.panelHeight == 180)
 assert(not E.db.datatexts.panels.LeftChatDataPanel.enable)
 assert(not E.db.datatexts.panels.RightChatDataPanel.enable)
 assert(not E.db.datatexts.panels.ForeverUI_Data.enable)
 assert(not E.db.movers.DTPanelForeverUI_DataMover)
 local panels = E.db.datatexts.panels
 assert(panels.KnuUI_Data.enable and #panels.KnuUI_Data == 8)
 assert(panels.MinimapPanel[1] == 'Time' and panels.MinimapPanel[2] == 'Coords')
 local base = E:CopyTable({}, P)
 base.movers = E.db.movers -- Las coordenadas se comparan con el boceto v4 por separado.
 base.KnuUILayoutVersion = module.version; base.KnuUIClassHealth = true -- Claves propias.
 base.KnuUIDock = E:CopyTable({}, E.db.KnuUIDock)
 base.KnuUISkinWoWPro = true
 base.KnuUIDecor = true
 base.KnuUICombatGlow = true
 base.KnuUIAlertsPlaced = true
 base.KnuUIBNETPlaced = true
 base.KnuUIBlizzardPlaced = true
 base.KnuUITomTomPlaced = true
 base.KnuUITomTomColors = true
 base.KnuUISkinTracker = true
 base.KnuUIDetailsFade = true
 base.KnuUIFlightTimer = true
 base.KnuUIRankUpgrade = true
 base.KnuUICC = { preset = 'full', blocks = {}, custom = {} } -- Workspace.lua (centro de comando)
 base.datatexts.panels.KnuUI_Data = { enable = true, battleground = false }
 for i = 1, 8 do base.datatexts.panels.KnuUI_Data[i] = '' end
 base.datatexts.panels.ForeverUI_Data = { enable = true }
 base.datatexts.panels.Darth_Panel_1 = { enable = true }
 base.unitframe.units.player.customTexts.Ajeno = { text_format = '' }
 -- Base del autor (Base.lua): sus claves son válidas por definición; el modo por defecto lo fija ApplyAll.
 local function Merge(dst, src) for k, v in pairs(src) do if type(v) == 'table' then dst[k] = type(dst[k]) == 'table' and dst[k] or {}; Merge(dst[k], v) else dst[k] = v end end end
 Merge(base, module.Base or {})
 base.KnuUITanks = true; base.KnuUICompactRight = true; base.KnuUITanksGap = 4; base.KnuUITanksWidth = 66
 Check(E.db, base, 'E.db')
 local global = E:CopyTable({}, G)
 global.datatexts.customPanels.KnuUI_Data = G.datatexts.newPanelInfo
 global.KnuUIClock24 = true
 Check(E.global, global, 'E.global'); Check(E.private, V, 'E.private')
 for key in pairs(P.actionbar) do
  local id = tonumber(key:match('^bar(%d+)$'))
  if id then
   local bar = E.db.actionbar[key]
   assert(bar.enabled == (id <= 6))
   if id <= 4 then assert(bar.showGrid and not bar.mouseover and not bar.inheritGlobalFade) end
   if id <= 2 then assert(bar.buttons * bar.buttonSize + (bar.buttons-1) * bar.buttonSpacing == 406) end
   if id == 3 or id == 4 then assert(bar.buttonsPerRow == 4 and bar.buttonSize == 40) end
   if id == 5 or id == 6 then assert(not bar.mouseover and not bar.inheritGlobalFade) end
  end
 end
end

-- Este bloque valida el diseño sin columnas: se pide explícitamente (sin elegir, ApplyAll usa columnas).
E.db.KnuUITanks, E.db.KnuUICompactRight = false, false
E.PopupDialogs.KNUUI_APPLY.OnAccept()
assert(reloads == 1 and E.db.KnuUILayoutVersion == module.version)
Validate()
health = 50; healthHook(parent); assert(faded == 1 and parent.mouseLock)
health = 100; healthHook(parent); assert(faded == 1)
module:ApplyAll(); assert(reloads == 2); Validate()

-- APIs ausentes, incompatibles y detección que arroja error.
for _, entry in ipairs(module.addons) do assert(not module:ApplyAddon(entry)) end
loaded.Details = true
Details = { GetInstance = function() error('API diferente') end }
assert(not module:ApplyAddon(module.addons[1]))
local calls = 0
local window = {
 SetBarSettings = function(_, height, texture) assert(height == nil and texture == 'Melli'); calls = calls + 1 end,
 SetBarTextSettings = function(_, size, font) assert(size == nil and font == 'Expressway'); calls = calls + 1 end,
}
Details.GetInstance = function(_, id) return id <= 2 and window end
assert(module:ApplyAddon(module.addons[1]) and calls == 4)
loaded.WoWPro, loaded.Questie = true, true
WoWProDB = { profile = {} }; Questie = { db = { profile = {} } }
assert(module:ApplyAddon(module.addons[4]) and WoWProDB.profile.position[4] == -200)
assert(module:ApplyAddon(module.addons[5]) and Questie.db.profile.TrackerLocation[4] == -430)
-- Apariencia: usa campos reales, respeta tamaño de fuente y tolera campos ausentes.
WoWPro = { MainFrame = Widget(), TitleBar = Widget(), StickyHeader = Widget(), GuideFrame = Widget(),
 TitleText = Widget(), ProgressText = Widget(), StickyHeaderTitle = Widget(),
 rows = { { step = Widget(), note = Widget(), track = Widget(), check = Widget() } } }
WoWPro.rows[1].step:SetFont('Anterior', 17)
assert(module:SkinWoWPro())
assert(WoWPro.MainFrame.template == 'Transparent')
assert(WoWPro.rows[1].step.font == 'Expressway.ttf' and WoWPro.rows[1].step.fontSize == 17)
assert(WoWPro.TitleText.color[1] == module:GetTheme().accent.r)
E.db.KnuUISkinWoWPro = false
WoWPro.MainFrame.template = nil
assert(not module:SkinWoWPro() and not WoWPro.MainFrame.template)
E.db.KnuUISkinWoWPro = true
WoWPro.MainFrame.SetTemplate = function() error('API diferente') end
assert(not module:SkinWoWPro())
WoWPro = nil
local detect = C_AddOns.IsAddOnLoaded
C_AddOns.IsAddOnLoaded = function() error('detección rota') end
assert(not module:IsLoaded('Details'))
C_AddOns.IsAddOnLoaded = detect

-- Abrir cada página, acciones opcionales y limpieza del quinto botón.
for _, page in ipairs(installer.Pages) do pi:SetupReset(); page() end
assert(#buttons == 4 and not buttons[1].shown and not buttons[2].shown and not buttons[3].shown and not buttons[4].shown)
pi:SetupReset(); installer.Pages[6]()
assert(buttons[2].shown and buttons[2].enabled)
assert(not PluginInstallFrame.Option2.enabled) -- Baganator ausente.
assert(buttons[3].shown)
buttons[3].OnClick(); assert(E.db.KnuUISkinWoWPro == false)
buttons[3].OnClick(); assert(E.db.KnuUISkinWoWPro == true)
assert(buttons[4].shown and buttons[4].text == 'Skins de addons: sí')
buttons[4].OnClick(); assert(E.db.KnuUIAddonSkins == false)
buttons[4].OnClick(); assert(E.db.KnuUIAddonSkins == true)
pi:SetupReset(); assert(not buttons[1].shown and not buttons[2].shown and not buttons[3].shown and not buttons[4].shown)
installer.Pages[2](); assert(PluginInstallFrame.Option1.enabled)
local before = reloads
installer.Pages[7](); PluginInstallFrame.Option1.OnClick()
assert(reloads == before + 1)

Fresh(); combat = true
assert(not module:ApplyLayout() and not module:ApplyTheme() and not module:ApplyChat())
module:ApplyAll(); assert(reloads == before + 1 and not E.db.KnuUILayoutVersion)
combat = false; E.Forever = false
module:ApplyAll(); assert(reloads == before + 1)
E.Forever = true; loaded.ElvUI_SLE = true
E.db.sle = { uibuttons = { orientation = 'vertical' }, raidmarkers = {} }
E.db.movers.SLE_UIButtonsMover = 'posición anterior'
module:ApplyLayout()
assert(E.db.sle.uibuttons.orientation == 'vertical' and E.db.sle.raidmarkers.visibility == 'INPARTY')
assert(E.db.movers.SLE_UIButtonsMover == 'posición anterior')
-- Integraciones nuevas: ausencia, error aislado, persistencia y diferimiento por combate.
local object = { icon = 'prueba', label = 'Prueba' }
local clicks, hides, gearClicks = 0, 0, 0
object.OnClick = function(button, mouse) assert(button.dataObject == object and mouse == 'LeftButton'); clicks = clicks + 1 end
local dbButton = { db = {}, dataObject = object }
local library = {
 GetButtonList = function() return { 'Roto', 'Prueba' } end,
 GetMinimapButton = function(_, name) if name == 'Roto' then error('objeto roto') end; return dbButton end,
 Hide = function(_, name) assert(name == 'Prueba'); hides = hides + 1 end,
}
LibStub = function(name) if name == 'LibDBIcon-1.0' then return library end; return { GetDataObjectByName = function() return object end } end
GearQuestMinimapButton = Widget()
GearQuest = { Minimap = { SetHidden = function(_, hidden) assert(hidden) end }, Log = { Toggle = function() gearClicks = gearClicks + 1 end } }
module:ScanMinimapButtons()
assert(dbButton.db.hide == nil and hides == 1 and module.launcherAddons['LDB:Prueba'])
assert(not GearQuestMinimapButton.shown) -- La ocultación externa vigente es sólo de sesión.
module.buttons.OnClick(); assert(module.flyout.shown)
module.buttons.OnClick(); assert(not module.flyout.shown)
module.buttons.OnClick()
for _, row in ipairs(module.flyout.rows) do
 if row.entry and row.entry.label == 'Prueba' then row.OnClick(row) end
end
assert(clicks == 1 and not module.flyout.shown)
module.launcherAddons.GearQuest.click(); assert(gearClicks == 1)
local lastHides = hides
combat = true; module:ScanMinimapButtons(); assert(hides == lastHides and module.minimapScanPending)
assert(not module:ToggleDecor())
combat = false; module.minimapButtonsEvents.OnEvent(nil, 'PLAYER_REGEN_ENABLED')
assert(hides == lastHides + 1 and not module.minimapScanPending)
LibStub = function() error('biblioteca rota') end
module:ScanMinimapButtons() -- No propaga el error de LibStub.
local timers = {}
C_Timer = { After = function(delay, callback) timers[#timers + 1] = { delay, callback } end }
module.minimapButtonsEvents.OnEvent(nil, 'PLAYER_ENTERING_WORLD')
assert(#timers == 2 and timers[1][1] == 2 and timers[2][1] == 5)
for _, timer in ipairs(timers) do timer[2]() end
for i = 1, 12 do module.launcherAddons['Extra'..i] = { label = 'Extra '..i, click = function() end } end
module:RefreshLauncher()
assert(module.flyout.pages == 2)
module.flyout.next.OnClick(); assert(module.flyout.page == 2)
module.flyout.previous.OnClick(); assert(module.flyout.page == 1)
module.buttons.OnClick(); assert(module.flyout.shown)
module.minimapButtonsEvents.OnEvent(nil, 'PLAYER_REGEN_DISABLED')
assert(not module.flyout.shown)
assert(module:ToggleDecor() and E.db.KnuUIDecor == false)
assert(module:ToggleDecor() and E.db.KnuUIDecor == true)
assert(module:RefreshDecor())

-- Paneles reales simulados: geometría del dock, setters, refrescos y combate.
LeftChatPanel.backdrop, RightChatPanel.backdrop = Widget(), Widget()
LeftChatTab, RightChatTab = Widget(), Widget()
-- Pestañas de 24 px dentro del panel, como Layout.lua.
function RightChatTab:GetBottom() return 156 end
function LeftChatTab:GetBottom() return 156 end
local instances, skinCalls = {}, 0
local plugin = { Rows = { { widget = Widget() } }, saveddata = {} }
function plugin:GetPluginInstance() return instances[2] end
function plugin:RefreshRow(row) row.textfont = 'Vieja' end
function plugin:RefreshRows() for _, row in ipairs(self.Rows) do self:RefreshRow(row) end end
function plugin:SizeChanged() end
for id = 1, 2 do
 local instance = { baseframe = Widget(), rowframe = Widget(), ativa = true,
  row_info = { space = {}, texture_custom = 'Anterior' }, title = Widget(), toolbar_side = 1 }
 instance.baseframe.UPFrame, instance.baseframe.titleBar = Widget(), Widget()
 instance.baseframe.titleBar:SetHeight(20)
 instance.baseframe.cabecalho = { ball = Widget(), ball_r = Widget(), emenda = Widget(), top_bg = Widget() }
 function instance:IsEnabled() return self.ativa end
 function instance:SetSize(w, h) self.baseframe:SetSize(w, h) end
 function instance:LockInstance(value) self.isLocked = value end
 function instance:SetBackgroundAlpha(alpha) self.bg_alpha = alpha end
 function instance:SetBackdropTexture() self.backdropChanged = true end
 function instance:UpdateFullBorder(value) self.fullborder_shown = value end
 function instance:UpdateRowAreaBorder(value) self.rowareaborder_shown = value end
 function instance:InstanceWallpaper(value) self.wallpaperEnabled = value end
 function instance:InstanceRefreshRows() end
 function instance:SetBarSettings(h, texture, byClass, _, bg, bgClass, bgColor, alpha, icon, start, spacing, custom)
  skinCalls = skinCalls + 1
  self.row_info.height, self.row_info.texture, self.row_info.space.between = h, texture, spacing
  self.row_info.texture_custom = custom
  self.classBars, self.rowBackground = byClass, bgColor
  self:InstanceRefreshRows()
 end
 function instance:SetBarTextSettings(size, font, color, leftClass, rightClass, leftOutline, rightOutline)
  self.row_info.font_face = font
  self.textSize, self.textColor, self.outline = size, color, leftOutline and rightOutline
  self:InstanceRefreshRows()
 end
 function instance:SetTitleBarSettings(shown, height, texture, color)
  self.titlebar_shown, self.titlebar_height, self.titleColor = shown, height, color
 end
 function instance:AttributeMenu(enabled, x, y, font, size) self.titleFont, self.titleSize = font, size end
 function instance:GetTitleBarFontString() return self.title end
 function instance:RefreshTitleBar() end
 function instance:RefreshTitleBarText() self.title:SetText('Título nativo') end
 function instance:ChangeSkin() self.bg_alpha = 1 end
 function instance:SetAutoHideMenu() end
 function instance:StatusBarColor(r, g, b, a) self.statusAlpha = a end
 instances[id] = instance
end
Details = {
 GetInstance = function(_, id) return instances[id] end,
 GetPlugin = function(_, name) assert(name == 'Details_TinyThreat'); return plugin end,
 SetFontColor = function(_, title, color) title:SetTextColor(unpack(color)) end,
 SendEvent = function(_, event) assert(event == 'DETAILS_INSTANCE_SIZECHANGED'); plugin:RefreshRows() end,
}
loaded.Details, loaded.Details_TinyThreat = true, true
E.db.KnuUIDock = { enabled = true, split = 0.5, wasLocked = {}, savedStates = {} }
assert(module:ApplyIntegratedPanels())
assert(E.db.chat.panelBackdrop == 'SHOWBOTH' and E.db.chat.panelTabBackdrop)
assert(E.db.chat.font == 'Expressway' and E.db.chat.fontSize == 12 and E.db.chat.tabFontSize == 12)
assert(LeftChatPanel.backdrop.border[1] == RightChatPanel.backdrop.border[1])
assert(LeftChatTab.KnuLine.color[1] == module:GetTheme().accentDim.r)
for _, instance in ipairs(instances) do
 assert(instance._ElvUIEmbed and instance.bg_alpha == 0 and not instance.fullborder_shown and not instance.rowareaborder_shown)
 assert(instance.classBars and instance.outline and instance.textSize == 12)
 assert(instance.row_info.texture_custom == '' and instance.baseframe.width == 196)
 -- RightChatTab oculto con Details acoplado: Details ocupa ese alto (sigue debajo del borde).
 assert(instance.baseframe.point[5] < 0 and instance.baseframe.height >= 20)
 assert(instance.baseframe.cabecalho.top_bg.alpha == 0 and instance.statusAlpha == 0)
end
assert(skinCalls == 2) -- Los refrescos no reinician las barras continuamente.
assert(not RightChatTab.shown) -- barra de pestañas vacía oculta mientras Details está acoplado
local divider = assert(RightChatPanel.textures[1])
assert(divider.shown and divider.width == 1 and divider.color[1] == RightChatTab.KnuLine.color[1])
instances[2].ativa = false; module:RefreshDock()
assert(not divider.shown and not instances[2]._ElvUIEmbed)
instances[2].ativa = true; module:RefreshDock()
assert(divider.shown and instances[2]._ElvUIEmbed)
plugin:RefreshRows()
assert(plugin.Rows[1].textfont == 'Expressway.ttf' and plugin.saveddata.useclasscolors)
assert(plugin.Rows[1].widget.KnuRowBackground.color[4] == 0.12)
instances[1].is_interacting = true; instances[1]:SetAutoHideMenu()
assert(instances[1].title.color[1] == module:GetTheme().accent.r)
instances[1]:ChangeSkin()
assert(instances[1].bg_alpha == 0 and skinCalls == 3)
instances[1].row_info.texture = 'Vieja'; instances[1]:InstanceRefreshRows()
assert(instances[1].row_info.texture == 'Melli' and skinCalls == 4)
assert(module:ApplyTheme(nil, 'neon'))
assert(instances[2].textColor[1] == module:GetTheme().text.r and skinCalls == 6)
local previous = skinCalls
combat = true
instances[1]:ChangeSkin()
assert(instances[1].bg_alpha == 1 and skinCalls == previous and module.detailsSkinPending)
assert(not module:ApplyIntegratedPanels())
combat = false
for _, frame in ipairs(eventFrames) do
 if frame.events and frame.events.PLAYER_REGEN_ENABLED and frame.OnEvent then frame.OnEvent(frame, 'PLAYER_REGEN_ENABLED') end
end
assert(instances[1].bg_alpha == 0 and not module.detailsSkinPending)
loaded.ForeverDock = true
assert(not module:SkinDetails(instances[1])); loaded.ForeverDock = nil
local oldSetter = instances[1].SetBackgroundAlpha
instances[1].SetBackgroundAlpha = function() error('API rota') end
instances[1]:ChangeSkin() -- El hook aísla el error de terceros.
assert(not module:SkinDetails(instances[1]))
instances[1].SetBackgroundAlpha = oldSetter
assert(module:SkinDetails(instances[1])) -- El error no deja trabada la protección de reentrada.
-- Registro: inmediato, tardío, una sola ejecución, errores aislados y combate.
assert(P.KnuUIAddonSkins and type(P.KnuUIAddonSkinsOff) == 'table')
local runs = 0
loaded.KnuTestImmediate = true
module:RegisterSkin('KnuTestImmediate', function() runs = runs + 1 end)
module:RegisterSkin('KnuTestLate', function() runs = runs + 10 end)
assert(runs == 1)
loaded.KnuTestLate = true
combat = true
module.addonSkinEvents.OnEvent(nil, 'ADDON_LOADED', 'KnuTestLate')
assert(runs == 1)
combat = false
module.addonSkinEvents.OnEvent(nil, 'PLAYER_REGEN_ENABLED')
assert(runs == 11)
module.addonSkinEvents.OnEvent(nil, 'ADDON_LOADED', 'KnuTestLate')
assert(runs == 11)
loaded.KnuTestBroken = true
module:RegisterSkin('KnuTestBroken', function() runs = runs + 100; error('fallo aislado') end)
module.addonSkinEvents.OnEvent(nil, 'PLAYER_ENTERING_WORLD')
assert(runs == 111)
E.db.KnuUIAddonSkins = false
loaded.KnuTestOff = true
module:RegisterSkin('KnuTestOff', function() runs = runs + 1000 end)
assert(runs == 111)
E.db.KnuUIAddonSkins = true
E.db.KnuUIAddonSkinsOff.KnuTestOff = true
module.addonSkinEvents.OnEvent(nil, 'ADDON_LOADED', 'KnuTestOff')
assert(runs == 111)
E.db.KnuUIAddonSkinsOff.KnuTestOff = nil
module.addonSkinEvents.OnEvent(nil, 'ADDON_LOADED', 'KnuTestOff')
assert(runs == 1111)

-- Creación tardía real: Auctionator. El hook espera que terminen sus controles.
local deferred = {}
C_Timer.After = function(_, callback) deferred[#deferred + 1] = callback end
loaded.Auctionator = true
module.addonSkinEvents.OnEvent(nil, 'ADDON_LOADED', 'Auctionator')
local auction = CreateFrame('Frame', 'AuctionatorAHFrame')
auction.children = {}
for i, kind in ipairs({ 'Button', 'CheckButton', 'EditBox', 'Slider', 'Slider', 'Button', 'ScrollFrame' }) do
 local child = Widget(); child.kind = kind
 child.globalName = i == 5 and 'AuctionatorTestScrollBar' or i == 6 and 'AuctionatorTestCloseButton' or nil
 auction.children[i] = child
end
local nestedBar = Widget(); nestedBar.kind = 'Slider'
auction.children[7].ScrollBar = nestedBar
auction.TitleText = Widget()
local label = Widget(); label.kind = 'FontString'
auction.regions = { label }
assert(not auction.template and #deferred == 1)
deferred[1](); deferred = {}
assert(auction.stripped and auction.template == 'Transparent')
assert(auction.border[1] == module:GetTheme().border.r and label.font == 'Expressway')
assert(auction.TitleText.color[1] == module:GetTheme().accent.r)
for i, method in ipairs({ 'HandleButton', 'HandleCheckBox', 'HandleEditBox', 'HandleSliderFrame', 'HandleScrollBar', 'HandleCloseButton' }) do
 assert(skinCallsByHelper[auction.children[i]] == method)
end
assert(skinCallsByHelper[nestedBar] == 'HandleScrollBar')
local lateEdit = Widget(); lateEdit.kind = 'EditBox'
auction.children[#auction.children + 1] = lateEdit
combat = true
auction:Show(); deferred[1](); deferred = {}
assert(not skinCallsByHelper[lateEdit])
combat = false
module.addonSkinEvents.OnEvent(nil, 'PLAYER_REGEN_ENABLED')
assert(skinCallsByHelper[lateEdit] == 'HandleEditBox')
E.db.KnuUIAddonSkinsOff.Auctionator = true
auction.border = nil
auction:Hide(); auction:Show(); deferred[1](); deferred = {}
assert(not auction.border)
E.db.KnuUIAddonSkinsOff.Auctionator = nil

assert(loadfile('addons/KnuUI/tests/addon-skins.lua'))(E, module, loaded, Widget, skinCallsByHelper,
 function(value) combat = value end,
 function() local queue = deferred; deferred = {}; for _, callback in ipairs(queue) do callback() end end)

-- ThreatClassic2: barras hijas y fondo real, también después de sus eventos.
local threat = CreateFrame('Frame', 'ThreatClassic2BarFrame')
threat.bg = Widget()
local threatBar = Widget(); threatBar.kind = 'StatusBar'
threatBar.name, threatBar.val, threatBar.perc, threatBar.tps = Widget(), Widget(), Widget(), Widget()
threatBar.edgeBackdrop = Widget()
threat.children = { threatBar }
loaded.ThreatClassic2 = true
module.addonSkinEvents.OnEvent(nil, 'ADDON_LOADED', 'ThreatClassic2')
assert(threatBar.statusTexture == 'Melli.tga' and threatBar.name.font == 'Expressway')
assert(threat.bg.color[1] == module:GetTheme().backdropFade.r)
threatBar.statusTexture = 'Anterior'
combat = true; threat:OnEvent('PLAYER_LOGIN'); assert(threatBar.statusTexture == 'Anterior')
combat = false; module.addonSkinEvents.OnEvent(nil, 'PLAYER_REGEN_ENABLED')
assert(threatBar.statusTexture == 'Melli.tga')

-- DBM: sólo el setter de opciones, con las claves y rutas que acepta DBT.
local dbtWrites = 0
DBT = { Options = { Width = 173 } }
function DBT:SetOption(key, value)
 assert(key == 'Texture' or key == 'Font')
 self.Options[key] = value; dbtWrites = dbtWrites + 1
end
function DBT:LoadOptions() self.Options = { Width = 173 } end
loaded['DBM-Core'] = true
-- Opt-in: sin el toggle no escribe la configuración de DBM.
E.db.KnuUISkinDBM = true
module.addonSkinEvents.OnEvent(nil, 'ADDON_LOADED', 'DBM-Core')
assert(dbtWrites == 2 and DBT.Options.Texture == 'Melli.tga' and DBT.Options.Font == 'Expressway.ttf')
combat = true; DBT:LoadOptions(); assert(dbtWrites == 2)
combat = false
module.addonSkinEvents.OnEvent(nil, 'PLAYER_REGEN_ENABLED')
assert(dbtWrites == 4 and DBT.Options.Width == 173)

-- Opciones y fade: ease-out en 150 ms, cierre inmediato e interrupción limpia.
local skinsOption = E.Options.args.KnuUI.args.addons.args.addonSkins
assert(skinsOption.type == 'toggle')
skinsOption.set(nil, false)
assert(not E.db.KnuUIAddonSkins)
skinsOption.set(nil, true)
local flyout = module.flyout
flyout:Hide(); flyout:Show()
assert(flyout.alpha == 0 and flyout.OnUpdate)
flyout:OnUpdate(0.075); assert(flyout.alpha == 0.875)
flyout:OnUpdate(0.075); assert(flyout.alpha == 1 and not flyout.OnUpdate)
flyout:Hide(); flyout:Show(); flyout:OnUpdate(0.03); flyout:Hide()
assert(flyout.alpha == 1 and not flyout.OnUpdate and not flyout.shown)
-- Extras: se arman sin errores; el modo cine se corta al entrar en combate.
CreateColor = CreateColor or function(r, g, b, a) return { r = r, g = g, b = b, a = a } end
local xpNow, orbit = 100, 0
function UnitXP() return xpNow end
function UnitXPMax() return 1000 end
function MoveViewRightStart() orbit = orbit + 1 end
function MoveViewRightStop() orbit = orbit - 1 end
UIParent = UIParent or CreateFrame('Frame', 'UIParent')
assert(pcall(module.SetupExtras, module))
module:ToggleCinema(); assert(orbit == 1)
module:ToggleCinema(true); assert(orbit == 1) -- ya estaba prendido
module:ToggleCinema(false); assert(orbit == 0)
assert(type(KnuUI_ToggleCinema) == 'function' and BINDING_NAME_KNUUI_CINEMA)

-- Bloques laterales compactos: sólo en modo columnas; el panel del lado gana 129 px.
E.Forever, combat = true, false
E.db.KnuUICompactRight = true
E.global.datatexts.customPanels.KnuUI_Data = E.global.datatexts.customPanels.KnuUI_Data or { width = 1100 }
assert(module:ApplyTanks(true))
local ab = E.db.actionbar
assert(ab.bar4.buttonsPerRow == 3 and ab.bar4.buttons == 12 and not ab.bar6.enabled and ab.bar5.enabled)
assert(E.db.movers.ElvAB_4 == 'BOTTOMLEFT,ElvUIParent,BOTTOM,295,28')
assert(E.db.chat.separateSizes and E.db.chat.panelWidth == 401 and E.db.chat.panelWidthRight == 530)
assert(E.global.datatexts.customPanels.KnuUI_Data.width == 973)
assert(E.db.movers.DTPanelKnuUI_DataMover == 'BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,409,2')
Check(E.db.actionbar, P.actionbar, 'E.db.actionbar'); Check(E.db.chat, P.chat, 'E.db.chat')
assert(module:ApplyTanks(false))
assert(not E.db.chat.separateSizes and E.db.chat.panelWidthRight == 401 and E.global.datatexts.customPanels.KnuUI_Data.width == 1102)
assert(E.db.movers.DTPanelKnuUI_DataMover == 'BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,409,2')
E.db.KnuUICompactRight = nil

-- Temas: todos tienen los 12 colores que usa KnuUI, figuran en el orden del menú y se aplican.
local fields = { 'accent', 'accentHi', 'accentDim', 'text', 'muted', 'backdrop', 'backdropFade', 'border',
 'cast', 'castNoInterrupt', 'health', 'healthBackdrop' }
local ordered = {}
for _, key in ipairs(module.themeOrder) do ordered[key] = true end
for key, theme in pairs(module.themes) do
 assert(ordered[key], 'tema fuera del orden: '..key)
 assert(type(theme.label) == 'string', key)
 for _, field in ipairs(fields) do
  local c = theme[field]
  assert(c and c.r and c.g and c.b and c.r >= 0 and c.r <= 1, key..'.'..field)
 end
 E.Forever, combat = true, false
 assert(module:ApplyTheme(nil, key) and E.db.KnuUITheme == key and module:GetTheme() == theme)
end
assert(module:ApplyTheme(nil, 'knunet'))

-- Aviso de Battle.net: skin con el tema.
BNToastFrame = CreateFrame('Frame', 'BNToastFrame')
combat = false
module:SetupBNToast()
assert(BNToastFrame.KnuLine)

-- Distribución de elementos de Blizzard: la aplica el diseño y, una vez por perfil, la pisa
-- aunque el perfil traiga posiciones de otros addons (anclas a UIParent de S&L).
E.Forever = true
assert(module:ApplyLayout())
for name, position in pairs(module.blizzardMovers) do
 assert(E.db.movers[name] == position, name)
 assert(position:find('ElvUIParent', 1, true), name..' sin ElvUIParent')
end
assert(module.blizzardMovers.BNETMover == 'BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,4,212')
E.db.movers.LootFrameMover = 'TOPRIGHT,UIParent,TOPRIGHT,-531,-449' -- posición vieja
E.db.KnuUIBlizzardPlaced = nil
module.mirrorHooked = nil
assert(pcall(module.SetupExtras, module))
assert(E.db.movers.LootFrameMover == module.blizzardMovers.LootFrameMover and E.db.KnuUIBlizzardPlaced)

-- Roles: cada uno sólo usa claves que existen en los defaults de ElvUI y se deshace al cambiar.
E.Forever, combat = true, false
local units = E.db.unitframe.units
units.player.customTexts.Ajeno = nil -- texto ajeno del perfil de prueba
for _, role in ipairs(module.roles) do
 assert(module:ApplyRole(role) and E.db.KnuUIRole == role)
 Check(E.db.unitframe, P.unitframe, 'E.db.unitframe'); Check(E.db.nameplates, P.nameplates, 'E.db.nameplates')
end
module:ApplyRole('tank')
assert(units.party.threatStyle == 'BORDERS' and units.player.threatStyle == 'BORDERS' and E.db.nameplates.threat.indicator)
module:ApplyRole('rdps')
assert(units.party.threatStyle == 'GLOW' and not E.db.nameplates.threat.indicator)
assert(units.player.castbar.width == 340 and units.player.castbar.height == 32 and units.target.debuffs.sizeOverride == 32)
module:ApplyRole('healer')
assert(units.player.castbar.width == 300 and units.party.healPrediction.enable and units.party.buffIndicator.enable)
assert(E.db.movers.ElvUF_PartyMover == 'BOTTOM,ElvUIParent,BOTTOM,0,204' and E.db.movers.ElvUF_Raid3Mover == 'BOTTOM,ElvUIParent,BOTTOM,0,204')
assert(module:ApplyTanks(true) and E.db.movers.ElvUF_PartyMover == 'BOTTOM,ElvUIParent,BOTTOM,0,340')
assert(module:ApplyTanks(false) and E.db.movers.ElvUF_PartyMover == 'BOTTOM,ElvUIParent,BOTTOM,0,204')
module:ApplyRole('mdps')
assert(not units.party.healPrediction.enable and not units.party.buffIndicator.enable)
assert(units.raid1.buffIndicator.enable == P.unitframe.units.raid1.buffIndicator.enable)
assert(units.party.debuffs.sizeOverride == P.unitframe.units.party.debuffs.sizeOverride and units.party.width == 200)
assert(E.db.movers.ElvUF_PartyMover == 'TOPLEFT,ElvUIParent,LEFT,8,110')
combat = true; assert(not module:ApplyRole('healer') and E.db.KnuUIRole == 'mdps'); combat = false
-- Barra de marcas: botones seguros raidtarget/worldmarker, mover propio y visibilidad por driver.
do
 local drivers, movers, baseCreate = {}, {}, CreateFrame
 function CreateFrame(...)
  local widget = baseCreate(...)
  function widget:SetAttribute(key, value) self.attrs = self.attrs or {}; self.attrs[key] = value end
  return widget
 end
 function E:CreateMover(frame, name) movers[name] = frame end
 function E:RegisterClicks(frame) frame.clicks = true end
 function RegisterStateDriver(frame, _, value) drivers[frame] = value end
 function UnregisterStateDriver(frame) drivers[frame] = nil end
 combat = false
 E.db.KnuUIRaidMarkers = nil
 assert(module:UpdateRaidMarkers())
 local bar = _G.KnuUI_RaidMarkers
 assert(bar and movers.KnuUI_RaidMarkersMover == bar and drivers[bar] == '[group] show; hide')
 assert(#bar.buttons == 11)
 local skull, clear = _G.KnuUI_RaidMarker8, _G.KnuUI_RaidMarker0
 assert(skull.attrs.type1 == 'raidtarget' and skull.attrs.marker1 == 8 and skull.attrs.action1 == 'toggle')
 assert(skull.attrs.type2 == 'worldmarker' and skull.attrs.marker2 == 8 and skull.clicks)
 assert(_G.KnuUI_RaidMarker1.attrs.marker2 == 5) -- estrella = marca de suelo 5
 assert(clear.attrs.action1 == 'clear' and clear.attrs.action2 == 'clear' and not clear.attrs.marker2)
 E.db.KnuUIRaidMarkers = 'always'; assert(module:UpdateRaidMarkers() and not drivers[bar] and bar.shown)
 E.db.KnuUIRaidMarkers = 'off'; assert(module:UpdateRaidMarkers() and bar.shown == false)
 combat = true; assert(not module:UpdateRaidMarkers()); combat = false
 CreateFrame = baseCreate
end

-- Temporizador de vuelo: aprende la ruta en el primer vuelo, la usa en el segundo y no guarda
-- un vuelo cortado con TaxiRequestEarlyLanding.
do
 local now, onTaxi, baseCreate = 100, false, CreateFrame
 function CreateFrame(...)
  local widget = baseCreate(...)
  function widget:SetMinMaxValues(_, max) self.max = max end
  function widget:SetValue(value) self.value = value end
  function widget:SetStatusBarColor(...) self.barColor = { ... } end
  function widget:CreateBackdrop() self.backdrop = baseCreate('Frame') end
  return widget
 end
 function E:CreateMover(frame, name) frame.moverName = name end
 function GetTime() return now end
 function UnitOnTaxi() return onTaxi end
 function NumTaxiNodes() return 2 end
 function TaxiNodeGetType(i) return i == 1 and 'CURRENT' or 'REACHABLE' end
 function TaxiNodeName(i) return i == 1 and 'Ventormenta, Elwynn' or 'Villa Oscura, Bosque del Ocaso' end
 function TakeTaxiNode() end
 function TaxiRequestEarlyLanding() end
 E.global.KnuUIFlights = nil
 module:SetupFlightTimer()
 local function Fly(seconds, early)
  TakeTaxiNode(2)
  local bar = _G.KnuUI_FlightTimer
  bar.OnUpdate() -- todavía en tierra
  onTaxi = true; now = now + 1; bar.OnUpdate()
  if early then TaxiRequestEarlyLanding() end
  now = now + seconds; bar.OnUpdate()
  onTaxi = false; now = now + 0.2; bar.OnUpdate()
  return bar
 end
 local bar = Fly(80)
 module:FlushTweens() -- se oculta al terminar el fundido de salida (Motion.lua)
 assert(bar.moverName == 'KnuUI_FlightTimerMover' and bar.shown == false)
 assert(E.global.KnuUIFlights['Ventormenta, Elwynn>Villa Oscura, Bosque del Ocaso'] == 80)
 TakeTaxiNode(2); assert(bar.max == 80 and bar.text.text == 'Villa Oscura' and bar.shown)
 onTaxi = true; now = now + 1; bar.OnUpdate(); now = now + 30; bar.OnUpdate()
 assert(bar.value == 30 and bar.time.text == '0:50')
 onTaxi = false; bar.OnUpdate()
 Fly(20, true)
 -- Queda el último vuelo completo (30 s); el cortado con TaxiRequestEarlyLanding no lo pisa.
 assert(E.global.KnuUIFlights['Ventormenta, Elwynn>Villa Oscura, Bosque del Ocaso'] == 30)
 CreateFrame = baseCreate
end

-- Zoom de combate: sube el tope de cámara, aleja al entrar en combate y vuelve a la distancia de
-- antes al salir; las situaciones de DynamicCam no se tocan.
do
 local cvars, baseLoaded = {}, module.IsLoaded
 function SetCVar(name, value) cvars[name] = value end
 local situations = { ['006'] = { enabled = false } }
 _G.DynamicCam = { db = { profile = { standardSettings = { cvars = {} }, situations = situations } } }
 function module:IsLoaded(name) return name == 'DynamicCam' or baseLoaded(self, name) end
 combat = false; E.global.KnuUICombatZoom = nil
 assert(module:ApplyCombatZoom() and cvars.cameraDistanceMaxZoomFactor == 2.6)
 assert(_G.DynamicCam.db.profile.standardSettings.cvars.cameraDistanceMaxZoomFactor == 2.6)
 assert(situations['006'].enabled == false and not situations['006'].viewZoom)
 local zoom = 12
 function GetCameraZoom() return zoom end
 function CameraZoomOut(d) zoom = zoom + d end
 function CameraZoomIn(d) zoom = zoom - d end
 -- Sin LibCamera: zoom común de Blizzard.
 local oldStub = LibStub; LibStub = nil
 module:CombatZoom(true); assert(zoom == 39)
 module:CombatZoom(false); assert(zoom == 12)
 -- Con LibCamera (DynamicCam): zoom por tiempo con curva suave.
 local calls = {}
 local libs = { ['LibCamera-1.0'] = { SetZoom = function(_, target, duration, curve) calls[#calls + 1] = { target, duration, curve }; zoom = target end },
  ['LibEasing-1.0'] = { InOutSine = 'sine' } }
 LibStub = setmetatable({}, { __call = function(_, name) return libs[name] end })
 module:CombatZoom(true); module:CombatZoom(false)
 assert(calls[1][1] == 39 and calls[1][2] == 3 and calls[1][3] == 'sine' and calls[2][1] == 12 and calls[2][2] == 4)
 LibStub = oldStub
 E.global.KnuUICombatZoom = false; module:CombatZoom(true); assert(zoom == 12)
 combat = true; E.global.KnuUICombatZoom = nil; assert(not module:ApplyCombatZoom()); combat = false
 module.IsLoaded, _G.DynamicCam, E.global.KnuUICombatZoom = baseLoaded, nil, nil
end

-- Fundido de paneles: Details usa su regla "fuera de combate" al 15 %; el ojo la apaga; el chat
-- sólo cambia con su botón.
do
 local base, rows, switch = Widget(), Widget(), Widget()
 -- Regla vieja encendida por la versión anterior (valor 15): se apaga.
 local instance = { baseframe = base, rowframe = rows, windowSwitchButton = switch, hide_on_context = { {}, { enabled = true, value = 15 } } }
 local oldDetails = _G.Details
 _G.Details = { GetInstance = function(_, id) return id == 1 and instance or nil end, SetWindowAlphaForCombat = function() end }
 function UnitAffectingCombat() return false end
 combat = false
 E.db.KnuUIDetailsFade, E.db.KnuUIDetailsKeep, E.db.KnuUIChatClear = nil, nil, nil
 module.detailsAlphaHooked = nil
 module:SetupPanelFade(); module:UpdatePanelFade()
 local rule = instance.hide_on_context[2]
 assert(not rule.enabled and rule.value == 100)
 assert(RightChatPanel.alpha == 0.1 and base.alpha == 0.1 and rows.alpha == 0.1 and switch.alpha == 0.1)
 -- Details repone su alfa: KnuUI lo vuelve a bajar.
 base:SetAlpha(1); _G.Details.SetWindowAlphaForCombat(instance); assert(base.alpha == 0.1)
 combat = true; module:UpdatePanelFade(); assert(base.alpha == 1 and RightChatPanel.alpha == 1); combat = false
 local keep, chat = _G.KnuUI_DetailsKeep, _G.KnuUI_ChatClear
 keep.OnClick(keep); module:FlushTweens() -- el ojo anima el cambio (Motion.lua)
 assert(E.db.KnuUIDetailsKeep and base.alpha == 1 and RightChatPanel.alpha == 1)
 assert(LeftChatPanel.alpha ~= 0.1)
 chat.OnClick(chat); module:FlushTweens(); assert(E.db.KnuUIChatClear and LeftChatPanel.alpha == 0.1)
 chat.OnClick(chat); module:FlushTweens(); assert(LeftChatPanel.alpha == 1)
 E.db.KnuUIDetailsKeep, E.db.KnuUIChatClear = nil, nil
 _G.Details = oldDetails
end

-- Monitor de botín: muestra propio y de grupo según calidad, y nunca toca un texto secreto.
do
 local qualities = { [111] = 3, [222] = 0, [333] = 2 }
 C_Item = C_Item or {}
 function C_Item.GetItemInfo(link) local id = tonumber(link:match('item:(%d+)')); return 'x', link, qualities[id], nil, nil, nil, nil, nil, nil, 1000 + id end
 function C_Item.GetItemQualityColor() return 0, 0.4, 1 end
 function UnitName() return 'Knu' end
 function Ambiguate(name) return (name:gsub('%-.*', '')) end
 local secret = {}
 function issecretvalue(v) return v == secret end
 local baseCreate = CreateFrame
 function CreateFrame(...)
  local w = baseCreate(...)
  function w:SetWordWrap() end
  function w:GetTexture() return self.texture end
  function w:GetBackdropBorderColor() return unpack(self.border or {}) end
  return w
 end
 function E:CreateMover(frame, name) frame.moverName = name end
 local link = function(id, name) return '|cff0070dd|Hitem:'..id..'::::::::|h['..name..']|h|r' end
 E.db.KnuUILootMonitor = nil
 module:LootMessage('Recibes botín: '..link(111, 'Espada')..'x2.', 'Knu-Reino')
 local holder = _G.KnuUI_LootMonitor
 local rows = holder.rows
 assert(holder.moverName == 'KnuUI_LootMonitorMover')
 assert(rows[1].text.text == link(111, 'Espada')..' x2' and rows[1].shown and rows[1].icon.texture == 1111)
 module:LootMessage('Ana recibe botín: '..link(222, 'Basura')..'.', 'Ana') -- gris de otro: no
 assert(rows[1].text.text == link(111, 'Espada')..' x2')
 module:LootMessage('Ana recibe botín: '..link(333, 'Anillo')..'.', 'Ana-Otro') -- verde de otro: sí
 assert(rows[1].text.text == 'Ana: '..link(333, 'Anillo') and rows[2].text.text == link(111, 'Espada')..' x2')
 module:LootMessage(secret, 'Ana') -- secreto: se saltea sin error
 module:LootMessage('Ana recibe botín: '..link(333, 'Anillo')..'.', secret)
 module:LootMessage('texto sin objeto', 'Ana')
 assert(rows[1].text.text == 'Ana: '..link(333, 'Anillo') and not rows[3].shown)
 E.db.KnuUILootMonitor = false
 module:LootMessage('Recibes botín: '..link(111, 'Espada')..'.', 'Knu')
 assert(rows[1].text.text == 'Ana: '..link(333, 'Anillo'))
 E.db.KnuUILootMonitor = nil
 CreateFrame = baseCreate
 issecretvalue = nil
end

-- Rangos: al aprender Sello rango 2, las casillas con rango 1 pasan al 2; otras no se tocan.
do
 local spells = { [10] = { 'Sello', 'Rango 1' }, [20] = { 'Sello', 'Rango 2' }, [30] = { 'Bendición', 'Rango 1' }, [40] = { 'Sello', 'Rango 3' } }
 local actions = { [1] = 10, [5] = 30, [61] = 10, [99] = 40 }
 local cursor
 C_Spell = C_Spell or {}
 function C_Spell.GetSpellName(id) return spells[id] and spells[id][1] end
 function C_Spell.GetSpellSubtext(id) return spells[id] and spells[id][2] end
 function C_Spell.PickupSpell(id) cursor = id end
 function GetActionInfo(slot) if actions[slot] then return 'spell', actions[slot] end end
 function PlaceAction(slot) actions[slot], cursor = cursor, actions[slot] end
 function ClearCursor() cursor = nil end
 function GetCursorInfo() return cursor end
 combat = false; E.db.KnuUIRankUpgrade = nil
 assert(module:UpgradeSpellRank(20) == 2)
 assert(actions[1] == 20 and actions[61] == 20 and actions[5] == 30 and actions[99] == 40 and not cursor)
 combat = true; actions[1] = 10; assert(module:UpgradeSpellRank(20) == 0 and actions[1] == 10); combat = false
 E.db.KnuUIRankUpgrade = false; assert(module:UpgradeSpellRank(20) == 0); E.db.KnuUIRankUpgrade = nil
end

-- Accesos fijos: el marcado sale del desplegable y queda como botón a la izquierda de la K.
do
 combat = false
 local clicked
 module.launcherAddons = { WIM = { label = 'WIM', icon = 1, click = function() clicked = 'WIM' end },
  GearQuest = { label = 'GearQuest', icon = 2, click = function() end } }
 E.db.KnuUIPinned = { WIM = true }
 module:RefreshLauncher()
 local pin = _G.KnuUI_Pinned1
 assert(pin and pin.shown ~= false and pin.entry.label == 'WIM' and pin.point[2] == module.buttons)
 pin.OnClick(pin); assert(clicked == 'WIM')
 for _, row in ipairs(module.flyout.rows) do assert(not (row.entry and row.entry.label == 'WIM')) end
 E.db.KnuUIPinned = {}; module:RefreshLauncher(); assert(pin.shown == false)
 module.launcherAddons, E.db.KnuUIPinned = nil, nil
end

-- Cámara sutil: sin cambios de vista ni giros, transiciones de al menos 2,5 s; lo demás no se toca.
do
 local baseLoaded = module.IsLoaded
 local npc = { transitionTime = { timeToEnter = 1, timeToExit = 0.5 }, viewZoom = { enabled = true, viewZoomType = 'view', viewNumber = 2 } }
 local mount = { transitionTime = { timeToEnter = 4, timeToExit = 3 }, viewZoom = { enabled = true, viewZoomType = 'zoom', zoomValue = 20 }, rotation = { enabled = true } }
 local custom = { rotation = { enabled = true } }
 _G.DynamicCam = { db = { profile = { situations = { ['300'] = npc, ['100'] = mount, ['999'] = custom } } } }
 function module:IsLoaded(name) return name == 'DynamicCam' or baseLoaded(self, name) end
 assert(module:SoftenCamSituations() == 3)
 assert(npc.transitionTime.timeToEnter == 2.5 and npc.transitionTime.timeToExit == 2.5 and npc.viewZoom.enabled == false)
 assert(mount.transitionTime.timeToEnter == 4 and mount.viewZoom.enabled and mount.rotation.enabled == false)
 assert(custom.rotation.enabled == false and custom.transitionTime.timeToEnter == 2.5)
 module.IsLoaded, _G.DynamicCam = baseLoaded, nil
end

-- Builds: sólo claves propias ya usadas o claves presentes en los defaults reales de ElvUI.
do
 local schema = E:CopyTable({}, P)
 local own = {
  KnuUIRole = 'Roles.lua', KnuUITanks = 'Tanks.lua', KnuUICompactLeft = 'Tanks.lua', KnuUICompactRight = 'Tanks.lua',
  KnuUIRaidMarkers = 'RaidMarkers.lua', KnuUICombatGlow = 'Extras.lua', KnuUIDetailsFade = 'Fade.lua',
  KnuUILootMonitor = 'LootMonitor.lua', KnuUILootSelfQuality = 'LootMonitor.lua', KnuUILootGroupQuality = 'LootMonitor.lua',
 }
 for key, file in pairs(own) do
  local source = assert(io.open('addons/KnuUI/'..file, 'r'))
  local text = source:read('*a'); source:close()
  assert(text:find(key, 1, true), 'clave propia sin uso existente: '..key)
  schema[key] = true
 end
 local classes, countBuilds = {}, 0
 E.Forever, combat = true, false
 for _, id in ipairs(module.buildOrder) do
  local b = assert(module.builds[id])
  countBuilds = countBuilds + 1; classes[b.class] = true
  Check(b.settings, schema, 'builds.'..id)
  E.myclass = b.class
  E.db.KnuUIBuild = nil; E.db.KnuUIRole = b.role
  assert(module:SuggestedBuild() == id and module:SelectedBuild() == id)
  local choices = menu.args.builds.args.preset.values()
  assert(choices[id] and #b.desc > 0)
  for choice in pairs(choices) do assert(module.builds[choice].class == E.myclass) end
  assert(module:ApplyBuild(id) and E.db.KnuUIBuild == id and E.private.KnuUIRole == b.role)
  for key, value in pairs(b.settings) do
   if type(value) ~= 'table' then assert(E.db[key] == value, id..'.'..key) end
  end
  assert(E.db.actionbar.barPet.enabled == b.settings.actionbar.barPet.enabled)
  assert(E.db.actionbar.stanceBar.enabled == b.settings.actionbar.stanceBar.enabled)
  assert(E.db.actionbar.totemBar.enable == b.settings.actionbar.totemBar.enable)
  assert(E.db.unitframe.units.player.classbar.enable == b.settings.unitframe.units.player.classbar.enable)
  assert(E.db.nameplates.threat.indicator == (b.role == 'tank'))
 end
 local countClasses = 0; for _ in pairs(classes) do countClasses = countClasses + 1 end
 assert(countClasses == 9 and countBuilds == 18)
 E.myclass = 'PALADIN'
 assert(module:ApplyBuild('PALADIN_tank'))
 assert(module:ApplyBuild('PALADIN_mdps'))
 assert(E.db.unitframe.units.player.health.orientation == 'HORIZONTAL' and not E.db.chat.separateSizes)
 assert(E.global.datatexts.customPanels.KnuUI_Data.width == 1102)
 combat = true
 assert(not module:ApplyBuild('PALADIN_healer') and E.db.KnuUIRole == 'mdps')
 combat = false
 assert(not module:ApplyBuild('HUNTER_rdps') and not module:ApplyBuild('inexistente'))
 menu.args.builds.args.preset.set(nil, 'PALADIN_healer')
 assert(E.db.KnuUIBuild == 'PALADIN_healer' and E.db.KnuUIRole == 'mdps') -- elegir no aplica
 local before = reloads
 -- La acción rápida recomienda según el rol, aunque el select tenga otra build.
 menu.args.general.args.recommended.func()
 assert(popup == 'KNUUI_BUILD' and module.pendingBuild == module:SuggestedBuild() and reloads == before)
 E.PopupDialogs.KNUUI_BUILD.OnCancel()
 assert(not module.pendingBuild)
 menu.args.general.args.recommended.func()
 local suggested = module.pendingBuild
 E.PopupDialogs.KNUUI_BUILD.OnAccept()
 assert(E.db.KnuUIBuild == suggested and reloads == before + 1)
 menu.args.builds.args.preset.set(nil, 'PALADIN_healer')
 before = reloads
 menu.args.builds.args.apply.func()
 assert(popup == 'KNUUI_BUILD' and reloads == before)
 -- Captura la elección confirmada, aunque cambie el select mientras el diálogo está abierto.
 menu.args.builds.args.preset.set(nil, 'PALADIN_tank')
 E.PopupDialogs.KNUUI_BUILD.OnAccept()
 assert(E.db.KnuUIRole == 'healer' and E.db.KnuUIBuild == 'PALADIN_healer' and reloads == before + 1)
 E.myclass = 'MAGE'; E.db.KnuUIRole = 'tank'; E.db.KnuUIBuild = 'PALADIN_tank'
 assert(module:SelectedBuild() == 'MAGE_rdps')
 E.myclass = 'INEXISTENTE'
 assert(not module:SelectedBuild() and menu.args.builds.args.apply.disabled())
 assert(menu.args.general.args.recommended.disabled())
 E.myclass = 'PALADIN'
end

-- Offhand: sin API, con partes ausentes y con el contrato completo del PLAN.md.
do
 local names = { 'CC_IsActive', 'CC_GetState', 'CC_Presets', 'CC_ApplyPreset', 'CC_SetBlock', 'CC_Unlock', 'CC_Reset', 'OffhandStatus', 'DiagSnapshot' }
 local saved, oldOffhand = {}, _G.Offhand
 for _, name in ipairs(names) do saved[name] = module[name]; module[name] = nil end
 _G.Offhand = nil
 local off = menu.args.offhand.args
 local general = menu.args.general.args
 local function Dashboard()
  for key, option in pairs(general) do
   if option.type == 'description' and type(option.name) == 'function' then
    local ok, value = pcall(option.name)
    assert(ok and type(value) == 'string' and #value > 0, 'Estado inválido: '..key)
   end
  end
 end
 Dashboard()
 assert(general.version.name():find('prueba-version', 1, true))
 assert(general.offhand.name():find(ns.L['Inactive'], 1, true))
 local oldRole, oldPrivateRole, oldTheme, oldSkins = E.db.KnuUIRole, E.private.KnuUIRole, E.db.KnuUITheme, E.db.KnuUIAddonSkins
 E.db.KnuUIRole, E.private.KnuUIRole = nil, 'healer'
 assert(general.role.name():find(module.roleNames.healer, 1, true))
 E.db.KnuUITheme, E.db.KnuUIAddonSkins = 'nord', false
 assert(general.theme.name():find(module.themes.nord.label, 1, true))
 assert(general.skins.name():find(ns.L['Disabled'], 1, true))
 assert(menu.args.look.args.selectedPreview.name() == module:ThemePreview('nord'))
 local preview = menu.args.look.args.selectedPreview.name()
 local _, swatches = preview:gsub('|TInterface\\Buttons\\WHITE8X8:12:18:0:0:8:8:0:8:0:8:%d+:%d+:%d+|t', '')
 assert(swatches == 6)
 local dim = module.themes.nord.accentDim
 assert(preview:find(format(':%d:%d:%d|t', math.floor(dim.r * 255 + 0.5), math.floor(dim.g * 255 + 0.5), math.floor(dim.b * 255 + 0.5)), 1, true))
 E.db.KnuUIRole, E.private.KnuUIRole, E.db.KnuUITheme, E.db.KnuUIAddonSkins = oldRole, oldPrivateRole, oldTheme, oldSkins
 assert(not off.fit and off.status.name():find(ns.L['Command center loads with Offhand'], 1, true))
 local function Probe()
  for _, option in pairs(off) do
   if type(option.name) == 'function' then assert(pcall(option.name)) end
   if type(option.desc) == 'function' then assert(pcall(option.desc)) end
   if option.values and type(option.values) == 'function' then assert(pcall(option.values)) end
   if option.get then assert(pcall(option.get)) end
   if option.disabled then assert(option.disabled()) end
   if option.set then assert(pcall(option.set, nil, option.type == 'toggle' and true or 'workspace')) end
   if option.func then assert(pcall(option.func)) end
  end
 end
 Probe()
 module.CC_GetState = function() return { blocks = {} } end
 module.CC_IsActive = function() return true end
 Probe() -- estado disponible, mutadores ausentes
 Dashboard()
 local calls, state = {}, { orientation = 'horizontal', edge = 'top', preset = 'test', blocks = {} }
 module.CC_GetState = function() return state end
 module.CC_Presets = function() return { { id = 'test', label = 'prueba', desc = 'descripción' } } end
 module.CC_ApplyPreset = function(_, id) calls.preset = id end
 module.CC_SetBlock = function(_, id, dest) state.blocks[id] = { dest = dest, custom = true } end
 module.CC_Unlock = function(_, value) calls.unlock = value end
 module.CC_Reset = function() calls.reset = true end
 module.OffhandStatus = function() return 'estado' end
 module.DiagSnapshot = function(_, reason) calls.diag = reason end
 Dashboard()
 assert(general.offhand.name():find('prueba', 1, true) and general.offhand.name():find('horizontal', 1, true))
 state.orientation = 'vertical'
 assert(general.offhand.name():find('vertical', 1, true))
 E.global.KnuUIDiagOn = true; general.diag.func(); assert(calls.diag == 'manual')
 assert(off.status.name():find('estado', 1, true) and off.preset.values().test == 'prueba')
 off.preset.set(nil, 'test'); assert(calls.preset == 'test')
 for _, block in ipairs({ 'guide', 'chat', 'details', 'data', 'map', 'bags' }) do
  off[block].set(nil, 'workspace'); assert(off[block].get() == 'workspace')
  off[block].set(nil, 'game'); assert(state.blocks[block].dest == 'game')
 end
 off.unlock.set(nil, true); assert(calls.unlock and off.unlock.get())
 off.reset.func(); assert(calls.reset and not off.unlock.get())
 off.diag.func(); assert(calls.diag == 'manual')
 combat = true; calls.reset, calls.preset = nil, nil
 off.reset.func(); off.preset.set(nil, 'test')
 assert(off.reset.disabled() and not calls.reset and not calls.preset)
 combat = false
 -- Cada API faltante mantiene el menú usable, aun si las demás ya cargaron.
 for _, name in ipairs(names) do
  local value = module[name]; module[name] = nil
  Dashboard()
  assert(pcall(off.status.name) and pcall(off.preset.get) and pcall(off.preset.values))
  for _, key in ipairs({ 'preset', 'guide', 'unlock', 'reset', 'diag' }) do
   local option = off[key]
   assert(pcall(option.disabled) and pcall(option.desc))
   if option.set then assert(pcall(option.set, nil, key == 'unlock' and true or 'game')) end
   if option.func then assert(pcall(option.func)) end
  end
  module[name] = value
 end
 module.CC_IsActive = function() return false end
 calls.reset, calls.preset = nil, nil
 off.reset.func(); off.preset.set(nil, 'test')
 assert(off.reset.disabled() and off.guide.disabled() and not calls.reset and not calls.preset)
 _G.Offhand = { Options = { Open = function(self) assert(self == _G.Offhand.Options); calls.options = true end },
  Wizard = { Open = function(self) assert(self == _G.Offhand.Wizard); calls.wizard = true end },
  GatherOffScreenUI = function(self) assert(self == _G.Offhand); calls.gather = true end }
 off.options.func(); off.wizard.func(); off.gather.func()
 assert(calls.options and calls.wizard and calls.gather)
 _G.Offhand.Options.Open = function() error('API ajena incompatible') end
 assert(pcall(off.options.func)) -- el error de otro addon queda contenido
 _G.Offhand = oldOffhand
 for _, name in ipairs(names) do module[name] = saved[name] end
end

-- Acento de clase dinámico y muestras para todos los temas, sin compartir la tabla de ElvUI.
do
 local original = E.ClassColor
 local color = { r = 0.3, g = 0.6, b = 0.9 }
 E.ClassColor = function(_, class, rgb) assert(class == E.myclass and rgb); return color end
 module:GetTheme()
 assert(module.themes.class.accent.r == color.r and module.themes.class.accent ~= color)
 color.r = 0.8; module:GetTheme(); assert(module.themes.class.accent.r == 0.8)
 for key in pairs(module.themes) do
  assert(module:ThemePreview(key):find('WHITE8X8', 1, true))
  for _, field in ipairs(fields) do
   local c = module.themes[key][field]
   for _, component in ipairs({ 'r', 'g', 'b', 'a' }) do
    assert(type(c[component]) == 'number' and c[component] >= 0 and c[component] <= 1, key..'.'..field..'.'..component)
   end
  end
 end
 assert(#module.themeOrder == 17)
 E.ClassColor = original
end

-- Ninguna ayuda o etiqueta del frente B queda sin traducción esES (los nombres de paletas son propios).
do
 for _, file in ipairs({ 'Builds.lua', 'Installer.lua', 'Theme.lua' }) do
  local source = assert(io.open('addons/KnuUI/'..file, 'r'))
  local text = source:read('*a'); source:close()
  for key in text:gmatch('L%["(.-)"%]') do
   assert(rawget(ns.L, key), file..': falta traducción de '..key)
  end
 end
end

assert(loadfile('addons/KnuUI/tests/cooldown-viewer.lua'))()
print('OK: batería completa Lua 5.1; temas, builds por clase/rol, opciones y API Offhand ausente/parcial/completa.')
