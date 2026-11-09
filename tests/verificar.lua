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
	assert(loadfile('_ref/ElvUI/Game/Shared/Defaults/'..file..'.lua'))()
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
 if name == 'AFK' or name == 'Layout' or name == 'Chat' or name == 'Minimap' or name == 'UnitFrames' then return {} end
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
C_AddOns = { IsAddOnLoaded = function(name) return loaded[name] end }
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
local ns = {} -- tabla compartida entre archivos (Locales/Locales.lua define ns.L)
for line in io.lines('addons/KnuUI/KnuUI.toc') do
 local file = line:match('^([%w_/%-]+%.lua)%s*$')
 if file then assert(loadfile('addons/KnuUI/'..file))('KnuUI', ns) end
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
for _, key in ipairs({ 'general', 'layout', 'look', 'addons', 'camera' }) do
 local group = menu.args[key]
 assert(group and group.type == 'group', key)
 for name, item in pairs(group.args) do
  assert(item.type and item.name ~= nil and item.order, key..'.'..name)
  if item.type == 'toggle' or item.type == 'select' or item.type == 'execute' then assert(item.width, key..'.'..name..' sin ancho') end
 end
end
assert(menu.args.layout.args.reapply.type == 'execute' and menu.args.look.args.theme.type == 'select')
assert(menu.args.layout.args.compactRight.disabled() == not E.db.KnuUITanks)
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
 assert(E.db.chat.panelWidth == 400 and E.db.chat.panelHeight == 180)
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
 base.KnuUISkinTracker = true
 base.datatexts.panels.KnuUI_Data = { enable = true, battleground = false }
 for i = 1, 8 do base.datatexts.panels.KnuUI_Data[i] = '' end
 base.datatexts.panels.ForeverUI_Data = { enable = true }
 base.datatexts.panels.Darth_Panel_1 = { enable = true }
 base.unitframe.units.player.customTexts.Ajeno = { text_format = '' }
 Check(E.db, base, 'E.db')
 local global = E:CopyTable({}, G)
 global.datatexts.customPanels.KnuUI_Data = G.datatexts.newPanelInfo
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
assert(E.db.movers.ElvAB_4 == 'BOTTOM,ElvUIParent,BOTTOM,356,28')
assert(E.db.chat.separateSizes and E.db.chat.panelWidth == 400 and E.db.chat.panelWidthRight == 529)
assert(E.global.datatexts.customPanels.KnuUI_Data.width == 971)
assert(E.db.movers.DTPanelKnuUI_DataMover == 'BOTTOM,ElvUIParent,BOTTOM,-65,2')
Check(E.db.actionbar, P.actionbar, 'E.db.actionbar'); Check(E.db.chat, P.chat, 'E.db.chat')
assert(module:ApplyTanks(false))
assert(not E.db.chat.separateSizes and E.db.chat.panelWidthRight == 400 and E.global.datatexts.customPanels.KnuUI_Data.width == 1100)
assert(E.db.movers.DTPanelKnuUI_DataMover == 'BOTTOM,ElvUIParent,BOTTOM,0,2')
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

-- Aviso de Battle.net: posición sobre el chat izquierdo y borde del tema.
BNToastFrame = CreateFrame('Frame', 'BNToastFrame')
E.db.movers.BNETMover = nil
combat = false
module:SetupBNToast()
assert(E.db.movers.BNETMover == 'BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,4,212')
assert(BNToastFrame.KnuLine)

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
print('OK: TOC, defaults, secciones, compatibilidad, paneles, Details, motor de skins, carga tardía, DBT, toggles, roles, fade y combate.')
