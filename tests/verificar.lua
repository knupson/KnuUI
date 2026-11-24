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
 if name == 'Misc' then return _G.KnuTestMisc end
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
 function w:GetScript(event) return self[event] end
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
 function w:SetHitRectInsets(...) self.hitInsets = { ... } end
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
 function w:UnregisterAllEvents() self.events = {} end
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
 function w:GetStringWidth() return #(self.text or '') * 7 end
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
-- KnuLib-1.0 AfterCombat (acá no se carga Libs/KnuLib): misma semántica que lib:AfterCombat, una entrada por clave.
-- RunAfterCombat() hace de PLAYER_REGEN_ENABLED.
local afterQueue, afterKeys = {}, {}
local function TestAfterCombat(_, fn, key)
 if not InCombatLockdown() then fn() return true end
 local e = key ~= nil and afterKeys[key]
 if e then e.fn = fn return false end
 e = { fn = fn }; afterQueue[#afterQueue + 1] = e
 if key ~= nil then afterKeys[key] = e end
 return false
end
function RunAfterCombat()
 local q = afterQueue; afterQueue, afterKeys = {}, {}
 for _, e in ipairs(q) do e.fn() end
 return #q
end
function PendingAfterCombat(key) return afterKeys[key] ~= nil end
-- Core.lua delega en KnuLib: con una KnuLib falsa, la llamada le llega tal cual.
do
 local got
 local savedLS = LibStub
 LibStub = function(name) if name == 'KnuLib-1.0' then return { AfterCombat = function(_, fn, key) got = key; return 'kl' end } end end
 assert(module:AfterCombat(function() end, 'k') == 'kl' and got == 'k', 'AfterCombat no usa KnuLib')
 LibStub = savedLS
end
module.AfterCombat = TestAfterCombat
-- Reutiliza el entorno sin ejecutar la batería ni sembrar perfiles ajenos.
if ... == 'render-harness' then
 return { E = E, K = module, fresh = function()
  E.db = E:CopyTable({}, P)
  E.global = E:CopyTable({}, G)
  E.private = E:CopyTable({}, V)
 end }
end
-- /knu común (KnuLib minor 3): se registra en el login; acá con una KnuLib falsa que anota lo registrado.
local knuCommands, knuDefault = {}, nil
IsLoggedIn = function() return true end
LibStub = function(name)
 if name == 'KnuLib-1.0' then return {
  RegisterCommand = function(_, n, h, help, aliases) knuCommands[n] = { h = h, help = help, aliases = aliases } end,
  SetDefaultCommand = function(_, h) knuDefault = h end } end
end
module:Initialize()
LibStub = nil
-- Tiradas: el orden real de inicio (sin KnuUILootRollFix) deja el mover en el lugar nuevo (revisión de Codex 2026-11-16).
local ALERT = "TOP,ElvUIParent,TOP,0,-780"
assert(module.blizzardMovers.AlertFrameMover == ALERT and E.db.movers.AlertFrameMover == ALERT, 'tiradas: inicio')
assert(E.db.KnuUILootRollFix and E.db.KnuUIAlertPoint == nil)
do
 local set, post = 0, 0
 local oldSet, oldPost = E.SetMoverPoints, E.PostAlertMove
 E.SetMoverPoints = function() set = set + 1 end
 E.PostAlertMove = function() post = post + 1 end
 local function Case(current, dynamic)
  E.db.movers.AlertFrameMover, E.db.KnuUIAlertPoint = current, dynamic
  module:FitLootRolls()
  return E.db.movers.AlertFrameMover
 end
 assert(Case(nil) == ALERT)
 assert(Case("TOPLEFT,ElvUIParent,TOPLEFT,270,-150") == ALERT)
 assert(Case("TOPLEFT,ElvUIParent,TOPLEFT,368,-150") == ALERT)
 assert(Case("TOPLEFT,ElvUIParent,TOPLEFT,418,-150", "TOPLEFT,ElvUIParent,TOPLEFT,418,-150") == ALERT and E.db.KnuUIAlertPoint == nil)
 assert(set == 4 and post == 4, 'tiradas: SetMoverPoints y PostAlertMove')
 assert(Case("BOTTOM,ElvUIParent,BOTTOM,100,300") == "BOTTOM,ElvUIParent,BOTTOM,100,300", 'tiradas: mover del jugador')
 assert(Case("BOTTOM,ElvUIParent,BOTTOM,100,300", "TOPLEFT,ElvUIParent,TOPLEFT,418,-150") == "BOTTOM,ElvUIParent,BOTTOM,100,300")
 assert(Case(ALERT) == ALERT and set == 4 and post == 4, 'tiradas: idempotente')
 E.SetMoverPoints, E.PostAlertMove = oldSet, oldPost
end
-- Columna de la guía (x 8-308): las posiciones viejas de KnuUI pasan a la derecha; las demás no se tocan.
do
 local NEW = module.guideColumnPoints
 local set, oldSet = 0, E.SetMoverPoints
 E.SetMoverPoints = function() set = set + 1 end
 local function Case(name, current, inCombat)
  E.db.movers[name] = current
  combat = inCombat or false
  module:ClearGuideColumn()
  combat = false
  return E.db.movers[name]
 end
 for _, name in ipairs({ 'ElvUF_PartyMover', 'ElvUF_Raid1Mover', 'ElvUF_Raid2Mover', 'ElvUF_Raid3Mover' }) do
  assert(Case(name, 'TOPLEFT,ElvUIParent,LEFT,8,110') == NEW[name] and NEW[name] == 'BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,4,270', name)
 end
 assert(set == 4, 'columna: SetMoverPoints del grupo y la banda')
 -- Crecimiento hacia arriba: sólo si el grupo tenía el DOWN_RIGHT de KnuUI y su mover se migró.
 local party, updated = E.db.unitframe.units.party, 0
 local UF, oldGet = { CreateAndUpdateHeaderGroup = function(_, group) updated = updated + 1; assert(group == 'party') end }, E.GetModule
 E.GetModule = function(self, name, ...) if name == 'UnitFrames' then return UF end return oldGet(self, name, ...) end
 party.growthDirection = 'DOWN_RIGHT'
 assert(Case('ElvUF_PartyMover', 'TOPLEFT,ElvUIParent,LEFT,320,110') == NEW.ElvUF_PartyMover, 'columna: valor intermedio')
 assert(party.growthDirection == 'UP_RIGHT' and updated == 1, 'columna: crece hacia arriba')
 party.growthDirection = 'DOWN_RIGHT'
 assert(Case('ElvUF_PartyMover', 'BOTTOM,ElvUIParent,BOTTOM,0,204') and party.growthDirection == 'DOWN_RIGHT', 'columna: sin migrar no cambia el crecimiento')
 party.growthDirection = 'RIGHT_UP'
 assert(Case('ElvUF_PartyMover', 'TOPLEFT,ElvUIParent,LEFT,8,110') == NEW.ElvUF_PartyMover and party.growthDirection == 'RIGHT_UP', 'columna: crecimiento ajeno')
 assert(updated == 1, 'columna: refresca sólo si cambió el crecimiento')
 -- Banda: forma nueva sólo con los valores de KnuUI (80, 1); un ancho propio se respeta.
 local raid3, raid1 = E.db.unitframe.units.raid3, E.db.unitframe.units.raid1
 raid3.growthDirection, raid3.width, raid3.groupsPerRowCol = 'DOWN_RIGHT', 80, 1
 updated = 0
 local ok = pcall(Case, 'ElvUF_Raid3Mover', 'TOPLEFT,ElvUIParent,LEFT,8,110')
 assert(raid3.growthDirection == 'UP_RIGHT' and raid3.width == 80 and raid3.groupsPerRowCol == 2, 'banda 3: 4 columnas de 2')
 raid1.growthDirection, raid1.width, raid1.groupsPerRowCol = 'DOWN_RIGHT', 90, 1
 pcall(Case, 'ElvUF_Raid1Mover', 'TOPLEFT,ElvUIParent,LEFT,8,110')
 assert(raid1.growthDirection == 'UP_RIGHT' and raid1.width == 90 and raid1.groupsPerRowCol == 1, 'banda 1: ancho propio')
 raid1.growthDirection, raid1.width = 'DOWN_RIGHT', 80
 pcall(Case, 'ElvUF_Raid1Mover', 'TOPLEFT,ElvUIParent,LEFT,8,110')
 assert(raid1.width == 72 and raid1.groupsPerRowCol == 1, 'banda 1: 5 columnas de 72')
 set = set - 3
 E.GetModule = oldGet
 set = set - 2
 assert(Case('GMMover', 'TOPLEFT,ElvUIParent,TOPLEFT,8,-310') == 'TOPLEFT,ElvUIParent,TOPLEFT,320,-310')
 assert(Case('GMMover', 'TOPLEFT,ElvUIParent,TOPLEFT,270,-8') == 'TOPLEFT,ElvUIParent,TOPLEFT,320,-310', 'GM de Base.lua')
 assert(Case('LootFrameMover', 'TOPLEFT,ElvUIParent,TOPLEFT,270,-400') == 'TOPLEFT,ElvUIParent,TOPLEFT,530,-400')
 assert(set == 7, 'columna: SetMoverPoints por cada mover migrado')
 assert(Case('ElvUF_PartyMover', 'BOTTOM,ElvUIParent,BOTTOM,0,204') == 'BOTTOM,ElvUIParent,BOTTOM,0,204', 'columna: Healer')
 assert(Case('ElvUF_PartyMover', 'TOPLEFT,ElvUIParent,LEFT,40,90') == 'TOPLEFT,ElvUIParent,LEFT,40,90', 'columna: jugador')
 assert(Case('LootFrameMover', nil) == nil, 'columna: mover sin valor')
 assert(Case('ElvUF_PartyMover', 'TOPLEFT,ElvUIParent,LEFT,8,110', true) == 'TOPLEFT,ElvUIParent,LEFT,8,110', 'columna: combate')
 assert(set == 7, 'columna: en combate no mueve')
 assert(Case('ElvUF_PartyMover', NEW.ElvUF_PartyMover) == NEW.ElvUF_PartyMover and set == 7, 'columna: idempotente')
 -- Layout.lua y Base.lua ya escriben las posiciones nuevas.
 for name, point in pairs(NEW) do
  if module.blizzardMovers[name] then assert(module.blizzardMovers[name] == point, name) end
 end
 assert(module.Base.movers.GMMover == NEW.GMMover, 'Base.lua: GMMover')
 E.SetMoverPoints = oldSet
end
assert(installer and #installer.Pages == 8 and #installer.StepTitles == 8)
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
-- /fui es propio y ya no reclama /knu; /knu va por KnuLib con los mismos subcomandos y el instalador por defecto.
assert(SLASH_KNUUI1 == '/fui' and SLASH_KNUUI2 == nil)
for name, alias in pairs({ aplicar = 'apply', cine = 'cinema', enfriamientos = 'cooldowns', visores = 'viewers', exportar = 'export', importar = 'import', opinar = 'feedback' }) do
 assert(knuCommands[name] and knuCommands[name].aliases[1] == alias and knuCommands[name].help ~= name, name)
end
assert(knuCommands.aplicar.help == 'Aplicar KnuUI a este perfil')
popup = nil; knuDefault('')
assert(not popup and reloads == 0)
knuCommands.aplicar.h('')
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
 base.KnuUILootRollFix = true
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
 global.KnuUIFeedbackShown = true -- la invitación a opinar ya salió en Initialize (C_Timer.After inmediato)
 Check(E.global, global, 'E.global'); Check(E.private, V, 'E.private')
 assert(E.global.KnuUIFeedbackShown == true, 'opinar: Initialize no la mostró')
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
do -- Página de estilos: un botón por estilo y uno para seguir con el diseño propio.
 local tried, savedTry = {}, module.TryStyle
 module.TryStyle = function(_, id) tried[#tried+1] = id end
 installer.Pages[7]()
 for i = 1, 3 do PluginInstallFrame['Option'..i].OnClick() end
 assert(table.concat(tried, ',') == 'bruma,tablero,parentesis', 'Instalador: botones de estilo')
 -- La fila entra en el instalador (550 de ancho, PluginInstaller.lua).
 local total = 0
 for i = 1, 4 do total = total + (PluginInstallFrame['Option'..i].width or 0) end
 assert(total > 0 and total + 3 * 4 <= 550, 'Instalador: fila de estilos dentro del marco')
 module.TryStyle = savedTry
end
installer.Pages[8](); PluginInstallFrame.Option1.OnClick()
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
combat = true; module:ScanMinimapButtons(); assert(hides == lastHides and PendingAfterCombat('KnuUI:MinimapScan'))
assert(not module:ToggleDecor())
combat = false; RunAfterCombat()
assert(hides == lastHides + 1 and not PendingAfterCombat('KnuUI:MinimapScan'))
LibStub = function() error('biblioteca rota') end
module:ScanMinimapButtons() -- No propaga el error de LibStub.
-- Botones propios de cualquier addon en el minimapa (pedido del user 2026-11-22): universales, no addon por addon.
do
 local function Btn(name, opts)
  local b = Widget(); b.kind = 'Button'; b.globalName = name; b.shown = true
  b.icon = Widget(); b.icon.texture = opts and opts.icon or 'Interface/AddOns/X/icon'
  if not (opts and opts.noClick) then b.OnClick = function(_, mouse) b.lastClick = mouse end end
  if opts and opts.protected then function b:IsProtected() return true end end
  return b
 end
 local cheap, pin, zoom, secure = Btn('CheapUpgradesMinimapButton'), Btn('GatherMatePin12'), Btn('MinimapZoomIn'), Btn('SecureThingButton', { protected = true })
 local unnamed = Btn(nil)
 -- Pin de TomTom registrado en HereBeDragons, y un lanzador que sólo usa OnMouseUp.
 local ttpin = Btn('TTMinimapButton3')
 local mouseUp = Btn('OtroAddonMinimapButton', { noClick = true })
 mouseUp.OnMouseUp = function(_, mouse) mouseUp.lastClick = mouse end
 local savedMinimap = _G.Minimap
 _G.Minimap = Widget(); _G.Minimap.children = { cheap, pin, zoom, secure, unnamed, ttpin, mouseUp }
 local hbd = { minimapPins = { [ttpin] = {} } }
 LibStub = function(name) if name == 'HereBeDragons-Pins-2.0' then return hbd end end
 module:ScanMinimapButtons()
 local entry = module.launcherAddons['Btn:CheapUpgradesMinimapButton']
 assert(entry and entry.label == 'CheapUpgrades' and entry.icon == cheap.icon.texture, 'minimapa: botón propio absorbido')
 assert(cheap.shown == false and pin.shown and zoom.shown and secure.shown, 'minimapa: sólo el botón de addon')
 assert(not module.launcherAddons['Btn:GatherMatePin12'] and not module.launcherAddons['Btn:MinimapZoomIn'] and not module.launcherAddons['Btn:SecureThingButton'])
 entry.click(nil, 'RightButton'); assert(cheap.lastClick == 'RightButton', 'minimapa: clic derecho al original')
 entry.click(nil, 'LeftButton'); assert(cheap.lastClick == 'LeftButton')
 assert(ttpin.shown and not module.launcherAddons['Btn:TTMinimapButton3'], 'minimapa: pin de mapa intacto')
 local other = module.launcherAddons['Btn:OtroAddonMinimapButton']
 assert(other and mouseUp.shown == false, 'minimapa: lanzador con OnMouseUp absorbido')
 other.click(nil, 'RightButton'); assert(mouseUp.lastClick == 'RightButton')
 -- El addon lo vuelve a mostrar: se oculta otra vez; un escaneo nuevo lo mantiene en el menú.
 cheap:Show(); assert(cheap.shown == false, 'minimapa: no reaparece')
 module:ScanMinimapButtons()
 assert(module.launcherAddons['Btn:CheapUpgradesMinimapButton'], 'minimapa: sigue en el menú')
 _G.Minimap = savedMinimap
 module.absorbedButtons[cheap], module.absorbedButtons[mouseUp] = nil, nil
 module.launcherAddons['Btn:CheapUpgradesMinimapButton'], module.launcherAddons['Btn:OtroAddonMinimapButton'] = nil, nil
 LibStub = nil
end
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
 GetPlugin = function(_, name) assert(name == 'DETAILS_PLUGIN_TINY_THREAT'); return plugin end,
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
assert(E.db.movers.ElvUF_PartyMover == 'BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,4,270' and units.party.growthDirection == 'UP_RIGHT')
for i = 1, 3 do assert(E.db.movers['ElvUF_Raid'..i..'Mover'] == module.guideColumnPoints['ElvUF_Raid'..i..'Mover'], 'banda '..i) end
assert(units.raid1.width == 72 and units.raid2.width == 72 and units.raid3.width == 80 and units.raid3.groupsPerRowCol == 2 and units.raid1.groupsPerRowCol == 1)
-- Ancho de la banda: hasta x 404, antes del foco (x 409). Entre columnas suma horizontalSpacing y groupSpacing (ElvUI UnitFrames.lua:960,1049).
for i = 1, 3 do local r = units['raid'..i]; local cols = math.ceil(r.numGroups / r.groupsPerRowCol); assert(4 + cols * r.width + (cols - 1) * (r.horizontalSpacing + r.groupSpacing) <= 404, 'banda '..i..' ancho') end
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
 local tipLines = {}
 GameTooltip = { AddLine = function(_, text) tipLines[#tipLines + 1] = text end, Show = function() end }
 function TaxiNodeOnButtonEnter() end
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
 assert(bar.width == 240) -- nombre corto: ancho base
 local oldName = TaxiNodeName
 TaxiNodeName = function(i) return i == 1 and oldName(1) or 'Refugio Roca del Sol de las Tierras Lejanas, Zona' end
 TakeTaxiNode(2); assert(bar.width == math.ceil(#'Refugio Roca del Sol de las Tierras Lejanas (aprendiendo)' * 7 + 54))
 TaxiNodeName = oldName; TakeTaxiNode(2); assert(bar.width == 240)
 -- Flecha de TomTom pisando la barra: la barra baja 6 px debajo de lo más bajo que pisa (Flight.lua, Avoid).
 local function Rect(l, b, w, h) return function() return l, b, w, h end end
 local function Visible() return true end
 bar.GetRect, bar.IsVisible = Rect(840, 942, 240, 18), Visible
 TomTomCrazyArrow = { GetRect = Rect(930, 990, 56, 42), IsVisible = Visible, GetEffectiveScale = function() return 1 end,
  KnuPanel = { GetRect = Rect(900, 950, 120, 40), IsVisible = Visible, GetEffectiveScale = function() return 1 end } }
 TakeTaxiNode(2); assert(bar.point[1] == 'TOP' and bar.point[5] == -120 - 16, 'barra no bajó debajo de TomTom')
 TomTomCrazyArrow.KnuPanel.GetRect = Rect(300, 950, 120, 40) -- flecha a un costado: no se mueve
 TakeTaxiNode(2); assert(bar.point[5] == -120, 'barra se movió sin superposición')
 -- Flecha pisa la barra y, al bajar, la barra caería sobre el recuadro de textos (debajo de la flecha):
 -- tiene que seguir bajando hasta quedar libre (hallazgo de la revisión de Codex 2026-11-16).
 TomTomCrazyArrow.GetRect = Rect(930, 950, 56, 42)
 TomTomCrazyArrow.KnuPanel.GetRect = Rect(900, 910, 120, 30)
 TakeTaxiNode(2); assert(bar.point[5] == -120 - 56, 'barra quedó sobre el recuadro de TomTom: '..tostring(bar.point[5]))
 TomTomCrazyArrow, bar.GetRect, bar.IsVisible = nil, nil, nil
 onTaxi = true; now = now + 1; bar.OnUpdate(); now = now + 30; bar.OnUpdate()
 assert(bar.value == 30 and bar.time.text == '0:50')
 onTaxi = false; bar.OnUpdate()
 Fly(20, true)
 -- Queda el último vuelo completo (30 s); el cortado con TaxiRequestEarlyLanding no lo pisa.
 assert(E.global.KnuUIFlights['Ventormenta, Elwynn>Villa Oscura, Bosque del Ocaso'] == 30)
 module:FlushTweens()
 -- Vuelta (Villa Oscura>Ventormenta) sin tiempo propio: se estima con la ida (30 s), marcada como aprox.
 local function Tip() tipLines = {}; TaxiNodeOnButtonEnter({ GetID = function() return 2 end }); return tipLines[1] end
 assert(Tip() == 'Tiempo de vuelo: 0:30')
 local fwdName = TaxiNodeName
 TaxiNodeName = function(i) return i == 1 and 'Villa Oscura, Bosque del Ocaso' or 'Ventormenta, Elwynn' end
 assert(Tip() == 'Tiempo de vuelo: aprox. 0:30', 'tooltip aprox: '..tostring(Tip()))
 TakeTaxiNode(2)
 assert(bar.max == 30 and bar.text.text == 'Ventormenta (aprox.)', 'etiqueta aprox: '..tostring(bar.text.text))
 assert(bar.width == 240 and bar.text.point[2] == -50)
 -- Destino largo aprox.: el reloj con '~'/'+' reserva 50 (no 44) y la barra se ensancha a texto + 60;
 -- el siguiente vuelo exacto vuelve a 44.
 local longName = 'Refugio Roca del Sol de las Tierras Lejanas, Zona'
 E.global.KnuUIFlights[longName..'>Villa Oscura, Bosque del Ocaso'] = 40
 local backName = TaxiNodeName
 TaxiNodeName = function(i) return i == 1 and 'Villa Oscura, Bosque del Ocaso' or longName end
 TakeTaxiNode(2)
 assert(bar.width == math.ceil(#'Refugio Roca del Sol de las Tierras Lejanas (aprox.)' * 7 + 60) and bar.text.point[2] == -50,
  'reserva del reloj aprox: '..tostring(bar.width)..' '..tostring(bar.text.point[2]))
 E.global.KnuUIFlights['Villa Oscura, Bosque del Ocaso>'..longName] = 40
 TakeTaxiNode(2)
 assert(bar.text.text == 'Refugio Roca del Sol de las Tierras Lejanas' and bar.text.point[2] == -44
  and bar.width == math.ceil(#'Refugio Roca del Sol de las Tierras Lejanas' * 7 + 54))
 E.global.KnuUIFlights[longName..'>Villa Oscura, Bosque del Ocaso'] = nil
 E.global.KnuUIFlights['Villa Oscura, Bosque del Ocaso>'..longName] = nil
 TaxiNodeName = backName
 TakeTaxiNode(2); assert(bar.text.text == 'Ventormenta (aprox.)')
 onTaxi = true; now = now + 1; bar.OnUpdate(); now = now + 10; bar.OnUpdate()
 assert(bar.time.text == '~0:20', 'reloj aprox: '..tostring(bar.time.text))
 now = now + 20; bar.OnUpdate(); assert(bar.time.text == '~0:00')
 now = now + 5; bar.OnUpdate()
 assert(bar.time.text == '+0:05' and bar.value == 30, 'pasado de lo estimado: '..tostring(bar.time.text))
 onTaxi = false; now = now + 0.2; bar.OnUpdate(); module:FlushTweens()
 -- Al aterrizar se guarda el tiempo real de la vuelta (35 s) y la próxima vez es exacto.
 assert(E.global.KnuUIFlights['Villa Oscura, Bosque del Ocaso>Ventormenta, Elwynn'] == 35)
 TakeTaxiNode(2); assert(bar.max == 35 and bar.text.text == 'Ventormenta')
 onTaxi = true; now = now + 1; bar.OnUpdate(); now = now + 5; bar.OnUpdate()
 assert(bar.time.text == '0:30')
 onTaxi = false; bar.OnUpdate(); module:FlushTweens()
 -- El tiempo propio manda sobre el de vuelta, y un aterrizaje anticipado con estimación no se guarda.
 E.global.KnuUIFlights['Villa Oscura, Bosque del Ocaso>Ventormenta, Elwynn'] = nil
 E.global.KnuUIFlights['Ventormenta, Elwynn>Villa Oscura, Bosque del Ocaso'] = 30
 Fly(10, true); module:FlushTweens()
 assert(E.global.KnuUIFlights['Villa Oscura, Bosque del Ocaso>Ventormenta, Elwynn'] == nil)
 E.global.KnuUIFlights['Villa Oscura, Bosque del Ocaso>Ventormenta, Elwynn'] = 50
 TakeTaxiNode(2); assert(bar.max == 50 and bar.text.text == 'Ventormenta')
 assert(Tip() == 'Tiempo de vuelo: 0:50')
 onTaxi = false; now = now + 10; bar.OnUpdate(); module:FlushTweens()
 TaxiNodeName = fwdName
 GameTooltip, TaxiNodeOnButtonEnter = nil, nil
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

-- Pawn y la hoja de personaje (Compat.lua): el botón de Pawn no cuelga de PaperDollItemsFrame hasta que ElvUI estila la
-- hoja (si no, ElvUI corta en HandleIcon por falta de .icon); después Pawn lo vuelve a poner. Con el estilo apagado, nada.
do
 local button, items, frame = { }, { name = 'items' }, { name = 'frame' }
 function button:SetParent(p) self.parent = p end
 local moves = 0
 local function Setup()
  PawnUI_InventoryPawnButton, PaperDollFrame, PaperDollItemsFrame, CharacterHeadSlot, PawnCommon = button, frame, items, {}, {}
  PawnUI_InventoryPawnButton_Move = function() moves = moves + 1; button:SetParent(items) end
  skins.LoadSkin = function() end
  module.pawnPaperDoll = nil
  module:SetupPawnPaperDoll()
 end
 Setup()
 PawnUI_InventoryPawnButton_Move() -- PLAYER_LOGIN de Pawn, antes del estilo de ElvUI
 assert(button.parent == frame)
 skins:LoadSkin({}) -- otro estilo: la hoja todavía no
 assert(button.parent == frame)
 CharacterHeadSlot.template = 'Default'
 local before = moves
 skins:LoadSkin({})
 assert(button.parent == items and moves == before + 1)
 skins:LoadSkin({}) -- una sola vez
 assert(moves == before + 1)
 -- Estilo de personaje de ElvUI apagado: el botón queda donde lo pone Pawn.
 E.private.skins.blizzard.character = false
 Setup()
 PawnUI_InventoryPawnButton_Move()
 assert(button.parent == items)
 E.private.skins.blizzard.character = true
 PawnUI_InventoryPawnButton, PaperDollFrame, PaperDollItemsFrame, CharacterHeadSlot, PawnCommon, PawnUI_InventoryPawnButton_Move = nil, nil, nil, nil, nil, nil
 skins.LoadSkin, module.pawnPaperDoll = nil, nil
end

-- Hueco de bolsa de componentes vacío (Compat.lua): el tooltip dice qué va ahí; con bolsa o en otro hueco, nada.
-- Como en Forever, SetInventoryItem sin datos oculta el tooltip y le saca el dueño; sin dueño SetText no escribe.
do
 local text, tipOwner
 local equipped = {}
 local slotFrame = { IsVisible = function(self) return not self.hidden end }
 GameTooltip = {
  SetOwner = function(_, o) tipOwner = o end,
  GetOwner = function() return tipOwner end,
  SetInventoryItem = function(_, _, slot) if not equipped[slot] then tipOwner = nil end end,
  SetText = function(_, t) if tipOwner then text = t end end,
  HookScript = function(self, script, fn) assert(script == 'OnShow'); self.onShow = fn end,
  Show = function(self) if self.onShow then self.onShow(self) end end,
  Hide = function() tipOwner = nil end,
 }
 Enum = { BagIndex = { ReagentBag = 5 } }
 C_Container = { ContainerIDToInventoryID = function(id) return 30 + id end }
 GetInventoryItemID = function(_, slot) return equipped[slot] end
 module.reagentSlotTip = nil
 module:SetupReagentSlotTip()
 GameTooltip:SetOwner(slotFrame, 'ANCHOR_RIGHT')
 GameTooltip:SetInventoryItem('player', 35)
 assert(text == 'Reagent bag slot: only reagent bags fit here' or text == 'Hueco de bolsa de componentes: sólo entran bolsas de componentes')
 assert(tipOwner == slotFrame)
 text = nil
 GameTooltip:SetOwner(slotFrame, 'ANCHOR_RIGHT')
 GameTooltip:SetInventoryItem('player', 34) -- otra bolsa
 assert(text == nil)
 equipped[35] = 12345
 GameTooltip:SetOwner(slotFrame, 'ANCHOR_RIGHT')
 GameTooltip:SetInventoryItem('player', 35) -- con bolsa puesta: el tooltip del objeto
 assert(text == nil)
 equipped[35] = nil
 GameTooltip:SetOwner(slotFrame, 'ANCHOR_RIGHT')
 GameTooltip:SetInventoryItem('target', 35) -- inspección de otro: nada
 assert(text == nil)
 slotFrame.hidden = true -- el dueño ya no se ve: no se reabre sobre nada
 GameTooltip:SetOwner(slotFrame, 'ANCHOR_RIGHT')
 GameTooltip:SetInventoryItem('player', 35)
 assert(text == nil and tipOwner == nil)
 slotFrame.hidden = nil
 -- Dueño viejo: otro tooltip con ese dueño ya se mostró y se cerró; una consulta sin SetOwner nuevo no lo reabre.
 GameTooltip:SetOwner(slotFrame, 'ANCHOR_RIGHT')
 GameTooltip:Show()
 GameTooltip:Hide()
 GameTooltip:SetInventoryItem('player', 35)
 assert(text == nil and tipOwner == nil)
 -- Ya usado una vez: una segunda consulta sin SetOwner tampoco.
 GameTooltip:SetOwner(slotFrame, 'ANCHOR_RIGHT')
 GameTooltip:SetInventoryItem('player', 35)
 assert(text ~= nil); text = nil
 GameTooltip:Hide()
 GameTooltip:SetInventoryItem('player', 35)
 assert(text == nil)
 EQUIP_CONTAINER_REAGENT = 'Equipar bolsa de componentes'
 GameTooltip:SetOwner(slotFrame, 'ANCHOR_RIGHT')
 GameTooltip:SetInventoryItem('player', 35)
 assert(text == 'Equipar bolsa de componentes')
 local hooked = GameTooltip.SetInventoryItem
 module:SetupReagentSlotTip() -- una sola vez
 assert(GameTooltip.SetInventoryItem == hooked)
 GameTooltip, Enum, C_Container, GetInventoryItemID, EQUIP_CONTAINER_REAGENT = nil, nil, nil, nil, nil
 module.reagentSlotTip = nil
end

-- Manners (Skins/AddOns/Manners.lua): sólo cambia lo que sigue por defecto, una vez por perfil, y le pide redibujarse.
do
 local defaults = { style = 'glass', classicArt = false, font = 'Friz', bgColor = { 0.04, 0.04, 0.06, 0.88 }, accentColor = { 0.45, 0.4, 0.9, 1 },
  point = 'BOTTOM', relPoint = 'BOTTOM', x = 0, y = 300 }
 local function Copy(t) local c = {} for k, v in pairs(t) do c[k] = type(v) == 'table' and { unpack(v) } or v end return c end
 local refreshed, profile = 0, 'Yaestoy'
 local manners = { db = { defaults = { profile = { prompt = defaults } }, GetCurrentProfile = function() return profile end } }
 function manners:RefreshConfig() refreshed = refreshed + 1 end
 local oldStub = LibStub
 LibStub = function(name) if name == 'AceAddon-3.0' then return { GetAddon = function(_, n) return n == 'Manners' and manners or nil end } end end
 E.global.KnuUIManners = nil
 local button, art = Widget(), Widget()
 art.outro = {}
 button.children = { Widget(), art }
 _G.MannersPrompt = button
 -- Todo por defecto: estilo, fuente, colores y lugar de KnuUI.
 manners.db.profile = { prompt = Copy(defaults) }
 assert(module:ApplyManners() == true and refreshed == 1)
 local p = manners.db.profile.prompt
 assert(p.style == 'minimal' and p.font == 'Expressway' and p.x == 330 and p.y == 340 and p.point == 'BOTTOM')
 assert(p.classicArt == true and p.minimalLine == false and E.global.KnuUIManners.Yaestoy == 3, 'manners: sin arte pintado ni línea blanca')
 local back = button.KnuBack
 assert(back and back.art == art and back.shown and back.fill.shown ~= false, 'manners: panel de KnuUI dentro de art')
 assert(art.textures and #art.textures == 5 and back.accent == nil, 'manners: fondo y 4 bordes, sin línea encimada')
 -- Manners redibuja (SetSize) con otra apariencia elegida en sus opciones: el panel se oculta solo.
 p.style = 'glass'; button:SetSize(220, 44)
 assert(back.shown == false and back.fill.shown == false, 'manners: oculto al cambiar de apariencia')
 p.style = 'minimal'; button:SetSize(220, 44)
 assert(back.shown and back.fill.shown, 'manners: vuelve con Mínima')
 local accent = module:GetTheme().accent
 assert(p.accentColor[1] == accent.r and p.accentColor[4] == 1 and p.bgColor[4] == 0.9)
 -- Una vez por perfil.
 p.style = 'glass'
 assert(module:ApplyManners() == false and p.style == 'glass' and refreshed == 1)
 -- Otro perfil con cosas elegidas por el jugador: se respetan.
 profile = 'Otro'
 manners.db.profile = { prompt = Copy(defaults) }
 p = manners.db.profile.prompt
 p.style, p.y, p.accentColor = 'leather', 500, { 1, 0, 0, 1 }
 assert(module:ApplyManners() == true)
 assert(p.style == 'leather' and p.y == 500 and p.x == 0 and p.accentColor[1] == 1 and p.font == 'Expressway')
 -- Con otra apariencia elegida por el jugador, el panel de KnuUI no se muestra.
 assert(button.KnuBack.shown == false, 'manners: panel oculto con otra apariencia')
 assert(#art.textures == 5, 'manners: el panel se crea una sola vez')
 -- Perfil integrado por 3.6.9 (true): sólo suma lo nuevo (sin arte pintado) y respeta lo demás.
 profile = 'Viejo'
 manners.db.profile = { prompt = Copy(defaults) }
 p = manners.db.profile.prompt
 p.style, p.y = 'minimal', 340
 E.global.KnuUIManners.Viejo = true
 assert(module:ApplyManners() == true and p.classicArt == true and p.minimalLine == false and E.global.KnuUIManners.Viejo == 3)
 assert(button.KnuBack.shown)
 -- Sin Manners o con otra estructura: nada.
 profile = 'Tercero'
 manners.db.defaults = nil
 assert(module:ApplyManners() == false and E.global.KnuUIManners.Tercero == nil)
 LibStub, E.global.KnuUIManners, _G.MannersPrompt = oldStub, nil, nil
end

-- Guía de WoW-Pro con tope (Skins/WoWPro.lua K:LimitWoWPro): no baja del grupo, se ve el final y la rueda la mueve.
do
 local function Box(top, height, left, right)
  local b = { top = top, height = height, left = left or 8, right = right or 308, shown = true }
  function b:GetTop() return self.top end
  function b:GetHeight() return self.height end
  function b:SetHeight(h) self.height = h end
  function b:GetLeft() return self.left end
  function b:GetRight() return self.right end
  function b:GetEffectiveScale() return 1 end
  function b:IsShown() return self.shown end
  function b:EnableMouseWheel() self.wheelOn = true end
  function b:GetScript() return self.wowproWheel end
  function b:SetScript(_, fn) self.onWheel = fn end
  function b:GetBottom() return self.top - self.height end
  function b:SetAlpha(a) self.alpha = a end
  function b:EnableMouse(on) self.mouse = on end
  function b:ClearAllPoints() self.points = {} end
  function b:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = { ... } end
  return b
 end
 local savedUI = UIParent.GetEffectiveScale
 UIParent.GetEffectiveScale = function() return 1 end
 -- Ventana arriba a la izquierda (top 1072), filas desde 1030 con 700 de contenido y 10 de margen abajo: 752 de alto.
 local MF, GF, row = Box(1072, 752), Box(1030, 700), Box(1030, 100)
 -- Rueda propia de WoW-Pro (guidescroll, de a un paso): con tope no tiene que correr.
 local wowproWheel = 0
 MF.wowproWheel = function() wowproWheel = wowproWheel + 1 end
 -- Botón de la fila (usar objeto): fuera de la vista, sin alfa ni mouse. La fila sigue a su desplazamiento.
 row.step = Box(0, 20); row.itembutton = Box(0, 20)
 function row:GetTop() local p = self.points and self.points[1]; return 1030 + (p and p[5] or 0) end
 local clips = 0
 _G.WoWPro = { MainFrame = MF, GuideFrame = GF, rows = { row }, UpdateFlyoutClip = function() clips = clips + 1 end }
 _G.WoWProDB = { profile = { autoresize = true } }
 _G.ElvUF_PartyMover = Box(494, 224, 4, 204)
 combat = false
 assert(module:LimitWoWPro() == true, 'guía: corta')
 -- Piso: 494 + 6 = 500 -> alto 572; filas visibles 572 - 42 - 10 = 520; recorrido 700 - 520 = 180, empieza abajo.
 assert(MF.height == 572 and GF.height == 520, 'guía: alto hasta el grupo')
 local function Y() return row.points[1][5] end
 assert(Y() == 180 and MF.wheelOn and MF.onWheel, 'guía: muestra el final (paso actual)')
 -- Abajo la fila 1 quedó 180 arriba del borde superior: su botón no se ve ni se puede tocar.
 assert(row.itembutton.alpha == 0 and row.itembutton.mouse == false, 'guía: botón de fila fuera de la vista')
 MF.onWheel(MF, 1) -- rueda para arriba
 assert(Y() == 140 and wowproWheel == 0, 'guía: la rueda sube, sin la rueda de WoW-Pro')
 MF.onWheel(MF, 10)
 assert(Y() == 0, 'guía: tope arriba')
 assert(row.itembutton.alpha == 1 and row.itembutton.mouse == true, 'guía: botón de fila a la vista')
 -- Si WoW-Pro recalcula sus botones con su regla, después corre la de KnuUI.
 row.itembutton.alpha = 0; _G.WoWPro.UpdateFlyoutClip()
 assert(row.itembutton.alpha == 1 and clips == 1, 'guía: recorte de KnuUI después del de WoW-Pro')
 -- En combate, con la fila arriba fuera de la vista: alfa 0 igual; el mouse no se toca en un botón seguro.
 MF.onWheel(MF, -1); MF.onWheel(MF, 1) -- fila corrida 40 arriba (fuera de la vista)
 MF.onWheel(MF, -1)
 local secured = row.itembutton
 function secured:IsProtected() return true end
 combat = true; secured.alpha, secured.mouse = 1, true
 _G.WoWPro.UpdateFlyoutClip()
 assert(secured.alpha == 0 and secured.mouse == true, 'guía: en combate sólo alfa en botones seguros')
 combat = false; secured.IsProtected = nil
 MF.onWheel(MF, 10)
 -- WoW-Pro vuelve a armarse (paso nuevo): respeta lo que subiste.
 MF.height, GF.height = 752, 700
 module:LimitWoWPro()
 assert(Y() == 0, 'guía: conserva la posición elegida')
 MF.onWheel(MF, -10) -- abajo del todo: vuelve a seguir el final
 MF.height, GF.height = 800, 748
 module:LimitWoWPro()
 assert(Y() == 228, 'guía: abajo sigue al paso actual')
 -- En combate no se toca nada.
 combat = true; MF.height = 752
 assert(module:LimitWoWPro() == false and MF.height == 752)
 combat = false
 -- Entra sin cortar: filas en su lugar.
 MF.height, GF.height = 300, 248
 assert(module:LimitWoWPro() == false and Y() == 0, 'guía: sin tope si entra')
 MF.onWheel(MF, 1)
 assert(wowproWheel == 1, 'guía: sin tope, la rueda es la de WoW-Pro')
 -- Guía movida lejos del grupo, o sin autoresize (centro de comando): no se corta.
 MF.height, GF.height, MF.left, MF.right = 752, 700, 900, 1200
 assert(module:LimitWoWPro() == false and MF.height == 752, 'guía: lejos del grupo')
 MF.left, MF.right = 8, 308
 _G.WoWProDB.profile.autoresize = false
 assert(module:LimitWoWPro() == false and MF.height == 752, 'guía: sin autoresize')
 _G.WoWPro, _G.WoWProDB, _G.ElvUF_PartyMover, UIParent.GetEffectiveScale = nil, nil, nil, savedUI
end

-- Cruces de cierre: estilo de ElvUI y, en las chicas, zona de clic de 22 px (ElvUI recorta 6/7 px por lado).
do
 local small, big = Widget(), Widget()
 small:SetSize(16, 16); big:SetSize(32, 32)
 module:SkinClose(small); module:SkinClose(big); module:SkinClose(nil)
 assert(skinCallsByHelper[small] == 'HandleCloseButton' and skinCallsByHelper[big] == 'HandleCloseButton')
 assert(small.hitInsets[1] == -3 and small.hitInsets[2] == -3 and small.hitInsets[3] == -3 and small.hitInsets[4] == -3)
 assert(big.hitInsets == nil)
end

-- Votos de las tiradas (LootRollCounts.lua): ElvUI no los escribe en Forever; KnuUI los toma del historial de botín.
do
 wipe = wipe or function(t) for k in pairs(t) do t[k] = nil end return t end
 tinsert = tinsert or table.insert
 local secret = {}
 issecretvalue = function(v) return v == secret end
 local function Bar()
  local bar = { rolls = {}, button = {} }
  for _, key in ipairs({ 'need', 'greed', 'pass', 'disenchant', 'transmog' }) do bar[key] = { text = Widget() } end
  return bar
 end
 local misc = { RollBars = { Bar(), Bar(), Bar(), Bar() } }
 local starts = {}
 function misc:START_LOOT_ROLL(_, rollID) local s = starts[rollID]; s.bar.rollID = rollID; s.bar.button.link = s.link; wipe(s.bar.rolls) end
 _G.KnuTestMisc = misc
 local history, queried = {}, 0
 C_LootHistory = { GetSortedInfoForDrop = function(e, k) queried = queried + 1; return history[e..':'..k] end }
 local frame
 local baseCreate = CreateFrame
 CreateFrame = function(...) frame = baseCreate(...); return frame end
 module:SetupLootRollCounts()
 CreateFrame = baseCreate
 assert(frame.events.LOOT_HISTORY_UPDATE_DROP and frame.events.LOOT_HISTORY_CLEAR_HISTORY)
 local function Fire(e, k) frame.OnEvent(frame, 'LOOT_HISTORY_UPDATE_DROP', e, k) end
 local function Text(bar, key) return bar[key].text.text end
 local A = '|cff0070dd|Hitem:500::::::::60:::::|h[Diseño A]|h|r'
 local function R(name, state) return { playerName = name, playerClass = 'MAGE', state = state } end
 local b1, b2, b3 = misc.RollBars[1], misc.RollBars[2], misc.RollBars[3]
 -- 1) Barra a la vista y votos: necesidad (principal y secundaria), codicia, paso; sin tirar no cuenta.
 starts[11] = { bar = b1, link = A }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 11)
 history['0:1'] = { itemHyperlink = A, rollInfos = { R('Ana', 0), R('Beto', 1), R('Caro', 3), R('Dani', 5), R('Eva', 4) } }
 Fire(0, 1)
 assert(Text(b1, 'need') == 2 and Text(b1, 'greed') == 1 and Text(b1, 'pass') == 1 and Text(b1, 'transmog') == '')
 assert(#b1.rolls[1] == 2 and b1.rolls[1][1][1] == 'Ana' and b1.rolls[1][1][2] == 'MAGE' and b1.rolls[0][1][1] == 'Dani')
 -- Un voto más actualiza la misma barra sin duplicar.
 history['0:1'].rollInfos[5] = R('Eva', 2)
 Fire(0, 1)
 assert(Text(b1, 'need') == 2 and Text(b1, 'transmog') == 1)
 -- Una segunda tirada del mismo objeto no le roba el objeto atado a la barra 1.
 local b4 = misc.RollBars[4]
 starts[13] = { bar = b4, link = A }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 13)
 history['0:1'].rollInfos[6] = R('Fede', 3)
 Fire(0, 1)
 assert(Text(b1, 'greed') == 2 and Text(b4, 'greed') == nil)
 b4.rollID = nil
 -- Otro objeto igual sin barra propia no pisa la barra 1, que ya tiene dueño.
 history['0:5'] = { itemHyperlink = A, rollInfos = { R('Gus', 5), R('Hugo', 5) } }
 Fire(0, 5)
 assert(Text(b1, 'pass') == 1)
 history['0:5'].allPassed = true; Fire(0, 5)
 -- 2) Votos antes que la barra, con un enlace distinto del mismo objeto: se pintan al mostrarse (por número de objeto).
 history['0:2'] = { itemHyperlink = '|Hitem:600::::::::60|h[B]|h', rollInfos = { R('Ana', 3) } }
 Fire(0, 2)
 assert(Text(b2, 'greed') == nil)
 starts[21] = { bar = b2, link = '|cff1eff00|Hitem:600::::::::61:::::|h[B]|h|r' }
 misc:START_LOOT_ROLL('START_LOOT_ROLL', 21)
 assert(Text(b2, 'greed') == 1)
 -- 3) Dos barras con el mismo objeto: no se adivina.
 local C = '|Hitem:700|h[C]|h'
 starts[31] = { bar = b3, link = C }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 31)
 b2.rollID, b2.button.link = 32, C
 history['0:3'] = { itemHyperlink = C, rollInfos = { R('Ana', 0) } }
 Fire(0, 3)
 assert(Text(b3, 'need') == nil and next(b3.rolls) == nil)
 -- 4) Sin datos (nil) no rompe; 5) secreto y tiradas de ElvUI apagadas no consultan.
 Fire(0, 99)
 local before = queried
 module:LootHistoryDrop(secret, 1); module:LootHistoryDrop(0, secret) -- sin pcall: un error rompe la prueba
 E.private.general.lootRoll = false; Fire(0, 1); E.private.general.lootRoll = true
 assert(queried == before)
 -- 6) Objeto terminado (ganador) que no tenía barra: no se guarda ni se pinta en una tirada nueva del mismo objeto.
 local D = '|Hitem:800|h[D]|h'
 history['0:4'] = { itemHyperlink = D, winner = R('Ana', 0), rollInfos = { R('Ana', 0) } }
 Fire(0, 4)
 b3.rollID = nil
 starts[41] = { bar = b3, link = D }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 41)
 assert(Text(b3, 'need') == nil)
 -- 7) Al terminar la tirada de la barra 1, el objeto se suelta: una tirada nueva del mismo objeto no hereda sus votos.
 history['0:1'].winner = R('Ana', 0); Fire(0, 1)
 starts[12] = { bar = b1, link = A }; b1.need.text.text = nil
 misc:START_LOOT_ROLL('START_LOOT_ROLL', 12)
 assert(b1.need.text.text == nil)
 -- 8) Dos objetos iguales esperando barra (revisión de Codex): la barra nueva no se queda con ninguno.
 local G2 = '|Hitem:900|h[G]|h'
 history['0:6'] = { itemHyperlink = G2, rollInfos = { R('Ana', 3) } }
 history['0:7'] = { itemHyperlink = G2, rollInfos = { R('Beto', 5) } }
 Fire(0, 6); Fire(0, 7)
 b2.rollID = nil
 starts[61] = { bar = b2, link = G2 }; b2.greed.text.text, b2.pass.text.text = nil, nil
 misc:START_LOOT_ROLL('START_LOOT_ROLL', 61)
 assert(b2.greed.text.text == nil and b2.pass.text.text == nil)
 history['0:6'].allPassed, history['0:7'].allPassed = true, true; Fire(0, 6); Fire(0, 7)
 -- 9) Barra cancelada con el objeto todavía abierto: otra tirada del mismo objeto no hereda esos votos.
 local H = '|Hitem:950|h[H]|h'
 b4.rollID = nil
 starts[71] = { bar = b4, link = H }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 71)
 history['0:8'] = { itemHyperlink = H, rollInfos = { R('Ana', 0) } }
 Fire(0, 8)
 assert(Text(b4, 'need') == 1)
 b4.need.text.text = nil
 starts[72] = { bar = b4, link = H }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 72)
 Fire(0, 8)
 assert(b4.need.text.text == nil)
 -- 10) Secuencia combinada (revisión de Codex): dos objetos iguales, barra bloqueada y cancelada, uno termina, barra
 -- nueva del mismo ítem: no hereda los votos del objeto cancelado.
 local J = '|Hitem:960|h[J]|h'
 history['0:9'] = { itemHyperlink = J, rollInfos = { R('Ana', 0) } }
 history['0:10'] = { itemHyperlink = J, rollInfos = { R('Beto', 3) } }
 Fire(0, 9); Fire(0, 10)
 b2.rollID = nil
 starts[81] = { bar = b2, link = J }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 81)
 b2.rollID = nil -- cancelada
 history['0:10'].winner = R('Beto', 3); Fire(0, 10)
 starts[82] = { bar = b2, link = J }; b2.need.text.text = nil
 misc:START_LOOT_ROLL('START_LOOT_ROLL', 82)
 Fire(0, 9)
 assert(b2.need.text.text == nil)
 -- 11) Un objeto y dos barras posibles; una se cancela: el objeto no se ata a la que queda.
 local L2 = '|Hitem:970|h[L]|h'
 b3.rollID, b4.rollID = nil, nil
 starts[91] = { bar = b3, link = L2 }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 91)
 starts[92] = { bar = b4, link = L2 }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 92)
 history['0:11'] = { itemHyperlink = L2, rollInfos = { R('Ana', 5) } }
 Fire(0, 11)
 b4.rollID = nil; b3.pass.text.text = nil
 Fire(0, 11)
 assert(b3.pass.text.text == nil)
 -- 12) Secuencia de Codex: dos barras iguales A y B, llega el objeto de una (ambiguo), se cancela A, llega el objeto
 -- de una tercera tirada antes que su barra: no se ata a B. El ítem queda bloqueado mientras haya involucrados.
 local M = '|Hitem:980|h[M]|h'
 b3.rollID, b4.rollID = nil, nil
 starts[101] = { bar = b3, link = M }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 101)
 starts[102] = { bar = b4, link = M }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 102)
 history['0:12'] = { itemHyperlink = M, rollInfos = { R('Ana', 0) } }
 Fire(0, 12)
 b3.rollID = nil -- se cancela A
 history['0:13'] = { itemHyperlink = M, rollInfos = { R('Beto', 5) } }
 b4.need.text.text, b4.pass.text.text = nil, nil
 Fire(0, 13)
 assert(b4.need.text.text == nil and b4.pass.text.text == nil)
 starts[103] = { bar = b3, link = M }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 103)
 Fire(0, 13)
 assert(b3.pass.text.text == nil and b4.pass.text.text == nil)
 -- 13) Terminan los objetos y se cierran las barras: el bloqueo se levanta y la tirada siguiente sí muestra números.
 history['0:12'].winner = R('Ana', 0); history['0:13'].allPassed = true; Fire(0, 12); Fire(0, 13)
 b3.rollID, b4.rollID = nil, nil
 starts[104] = { bar = b3, link = M }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 104)
 history['0:14'] = { itemHyperlink = M, rollInfos = { R('Caro', 3) } }
 Fire(0, 14)
 assert(Text(b3, 'greed') == 1)
 -- 14) El objeto involucrado terminó pero una barra involucrada sigue a la vista: el ítem sigue bloqueado.
 local N = '|Hitem:990|h[N]|h'
 b3.rollID, b4.rollID = nil, nil
 starts[105] = { bar = b3, link = N }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 105)
 starts[106] = { bar = b4, link = N }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 106)
 history['0:15'] = { itemHyperlink = N, rollInfos = { R('Ana', 0) } }
 Fire(0, 15)
 history['0:15'].winner = R('Ana', 0); Fire(0, 15)
 b3.rollID = nil
 history['0:16'] = { itemHyperlink = N, rollInfos = { R('Beto', 0) } }
 b4.need.text.text = nil
 Fire(0, 16)
 assert(b4.need.text.text == nil)
 -- 15) Secuencia de Codex: A y B bloquean el ítem, termina el objeto, aparece C con B a la vista, se cierra B, llega el
 -- objeto de D antes que su barra: no se ata a C (C apareció bloqueada).
 local O = '|Hitem:995|h[O]|h'
 b1.rollID, b2.rollID, b3.rollID, b4.rollID = nil, nil, nil, nil
 starts[111] = { bar = b1, link = O }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 111)
 starts[112] = { bar = b2, link = O }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 112)
 history['0:17'] = { itemHyperlink = O, rollInfos = { R('Ana', 0) } }
 Fire(0, 17)
 history['0:17'].winner = R('Ana', 0); Fire(0, 17)
 b1.rollID = nil
 starts[113] = { bar = b3, link = O }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 113)
 b2.rollID = nil
 history['0:18'] = { itemHyperlink = O, rollInfos = { R('Beto', 0) } }
 b3.need.text.text = nil
 Fire(0, 18)
 assert(b3.need.text.text == nil)
 -- 16) Secuencia de Codex: A tiene barra, B del mismo ítem espera, A termina con su barra todavía a la vista, llega B:
 -- no toma la barra de A. Cuando la barra de A se cierra y aparece la de B, B sí se pinta.
 local Q = '|Hitem:997|h[Q]|h'
 b1.rollID, b2.rollID, b3.rollID, b4.rollID = nil, nil, nil, nil
 starts[121] = { bar = b1, link = Q }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 121)
 history['0:19'] = { itemHyperlink = Q, rollInfos = { R('Ana', 0) } }
 Fire(0, 19)
 assert(Text(b1, 'need') == 1)
 history['0:20'] = { itemHyperlink = Q, rollInfos = { R('Beto', 5) } }
 Fire(0, 20)
 history['0:19'].winner = R('Ana', 0); Fire(0, 19)
 b1.pass.text.text = nil
 Fire(0, 20)
 assert(b1.pass.text.text == nil)
 b1.rollID = nil
 starts[122] = { bar = b2, link = Q }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 122)
 assert(Text(b2, 'pass') == 1)
 -- 17) Un objeto terminado cuya barra ya se cerró no deja el ítem bloqueado para siempre.
 local T = '|Hitem:998|h[T]|h'
 b1.rollID, b2.rollID, b3.rollID, b4.rollID = nil, nil, nil, nil
 starts[131] = { bar = b1, link = T }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 131)
 history['0:21'] = { itemHyperlink = T, rollInfos = { R('Ana', 0) } }
 Fire(0, 21)
 starts[132] = { bar = b2, link = T }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 132)
 starts[133] = { bar = b3, link = T }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 133)
 history['0:22'] = { itemHyperlink = T, rollInfos = { R('Beto', 0) } }
 Fire(0, 22) -- dos barras libres: el ítem queda bloqueado, con 0:21 involucrado
 history['0:21'].winner = R('Ana', 0); Fire(0, 21)
 history['0:22'].allPassed = true; Fire(0, 22)
 b1.rollID, b2.rollID, b3.rollID = nil, nil, nil
 starts[134] = { bar = b4, link = T }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 134)
 history['0:23'] = { itemHyperlink = T, rollInfos = { R('Caro', 3) } }
 Fire(0, 23)
 assert(Text(b4, 'greed') == 1)
 -- 18) Secuencia de Codex: dos barras iguales antes del historial, se cancela A y llega su objeto todavía abierto: no
 -- se ata a B.
 local U = '|Hitem:999|h[U]|h'
 b1.rollID, b2.rollID, b3.rollID, b4.rollID = nil, nil, nil, nil
 starts[141] = { bar = b1, link = U }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 141)
 starts[142] = { bar = b2, link = U }; misc:START_LOOT_ROLL('START_LOOT_ROLL', 142)
 b1.rollID = nil
 history['0:24'] = { itemHyperlink = U, rollInfos = { R('Ana', 0) } }
 b2.need.text.text = nil
 Fire(0, 24)
 assert(b2.need.text.text == nil)
 _G.KnuTestMisc, C_LootHistory, issecretvalue = nil, nil, nil
end

-- Rangos: cadena = nombre sin mayúsculas/acentos + ícono original (Ranks.lua). Casos del juego: Martillo de
-- Justicia (rango 1) y Martillo de justicia (rango 2) son el mismo hechizo; el botón atrasado se corrige solo.
do
 local spells = {
  [10] = { 'Sello', 'Rango 1', 1 }, [20] = { 'Sello', 'Rango 2', 1 }, [30] = { 'Bendición', 'Rango 1', 2 },
  [40] = { 'Sello', 'Rango 3', 1 }, [853] = { 'Martillo de Justicia', 'Rango 1', 135963 },
  [5588] = { 'Martillo de justicia', 'Rango 2', 135963 }, [70] = { 'Sello', 'Rango 1', 9 },
  [80] = { 'ÁGUILA', 'Rango 1', 5 }, [81] = { 'águila', 'Rango 2', 5 }, [90] = { 'Sin rango', '', 6 },
 }
 local actions = { [1] = 10, [5] = 30, [61] = 10, [99] = 40, [4] = 853, [7] = 70, [8] = 80, [9] = 90 }
 local macros = { [12] = 10 }
 local cursor, failPickup
 C_Spell = C_Spell or {}
 function C_Spell.GetSpellName(id) return spells[id] and spells[id][1] end
 function C_Spell.GetSpellSubtext(id) return spells[id] and spells[id][2] end
 function C_Spell.GetSpellTexture(id) if spells[id] then return 999, spells[id][3] end end -- visible distinto del original
 function C_Spell.PickupSpell(id) if not failPickup then cursor = id end end
 function GetActionInfo(slot)
  if macros[slot] then return 'macro', macros[slot] end
  if actions[slot] then return 'spell', actions[slot] end
 end
 function PlaceAction(slot) actions[slot], cursor = cursor, actions[slot] end
 function ClearCursor() cursor = nil end
 function GetCursorInfo() if cursor then return 'spell', 1, 0, cursor end end
 local book, bookReads = {}, 0
 C_SpellBook = {
  GetNumSpellBookSkillLines = function() bookReads = bookReads + 1; return 1 end,
  GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = #book } end,
  GetSpellBookItemInfo = function(i) return book[i] and { spellID = book[i], isPassive = false } end,
 }
 combat = false; E.db.KnuUIRankUpgrade = nil
 -- Al aprender Sello rango 2: las casillas con el 1 pasan al 2; el 3, la Bendición, otro ícono y la macro no.
 assert(module:UpgradeSpellRank(20) == 2)
 assert(actions[1] == 20 and actions[61] == 20 and actions[5] == 30 and actions[99] == 40 and not cursor)
 assert(actions[7] == 70 and macros[12] == 10, 'otro ícono o macro tocados')
 -- Martillo: nombres que difieren en la mayúscula, mismo ícono original -> mismo hechizo.
 assert(module:UpgradeSpellRank(5588) == 1 and actions[4] == 5588, 'Martillo de justicia no reemplazado')
 -- Acentos en mayúscula: ÁGUILA y águila son la misma cadena.
 assert(module:UpgradeSpellRank(81) == 1 and actions[8] == 81)
 -- Sin rango: no es cadena.
 assert(module:UpgradeSpellRank(90) == 0 and actions[9] == 90)
 -- Barrido contra el libro: un botón atrasado se corrige sin evento de aprendizaje.
 actions[4] = 853; book = { 853, 5588, 10, 40 }
 assert(module:UpgradeAllRanks() >= 1 and actions[4] == 5588)
 assert(actions[1] == 40 and actions[61] == 40, 'Sello al rango más alto del libro')
 -- Combate: queda pendiente y se aplica al salir.
 actions[4] = 853; combat = true
 assert(module:UpgradeAllRanks() == 0 and actions[4] == 853); combat = false
 assert(module:UpgradeAllRanks() == 1 and actions[4] == 5588)
 -- Cursor ocupado: no se toca; al soltar, se aplica.
 actions[4] = 853; cursor = 77
 assert(module:UpgradeAllRanks() == 0 and actions[4] == 853 and cursor == 77); cursor = nil
 assert(module:UpgradeAllRanks() == 1 and actions[4] == 5588)
 -- PickupSpell que no deja nada en el cursor: no se cuenta ni se toca la casilla.
 actions[4] = 853; failPickup = true
 assert(module:UpgradeAllRanks() == 0 and actions[4] == 853); failPickup = false
 -- Por eventos: lo pendiente se aplica solo al salir de combate y al soltar el cursor.
 local rankFrame, baseCreateRanks, baseAfter = nil, CreateFrame, C_Timer.After
 C_Timer.After = function(_, callback) callback() end
 function CreateFrame(...) rankFrame = baseCreateRanks(...); return rankFrame end
 module:SetupRankUpgrade()
 CreateFrame = baseCreateRanks
 actions[4] = 853; combat = true
 rankFrame.OnEvent(rankFrame, 'SPELLS_CHANGED')
 assert(actions[4] == 853, 'en combate no se toca')
 combat = false; rankFrame.OnEvent(rankFrame, 'PLAYER_REGEN_ENABLED')
 assert(actions[4] == 5588, 'pendiente no aplicado al salir de combate')
 actions[4] = 853; cursor = 77
 rankFrame.OnEvent(rankFrame, 'LEARNED_SPELL_IN_SKILL_LINE')
 assert(actions[4] == 853 and rankFrame.events.CURSOR_CHANGED, 'esperando el cursor')
 rankFrame.OnEvent(rankFrame, 'CURSOR_CHANGED'); assert(actions[4] == 853, 'todavía arrastrando')
 cursor = nil; rankFrame.OnEvent(rankFrame, 'CURSOR_CHANGED')
 assert(actions[4] == 5588 and not rankFrame.events.CURSOR_CHANGED, 'pendiente no aplicado al soltar el cursor')
 C_Timer.After = baseAfter
 -- Varias señales antes de que corra el temporizador = una sola revisión del libro.
 local timers = {}
 C_Timer.After = function(_, callback) timers[#timers + 1] = callback end
 actions[4] = 853; bookReads = 0
 for _, event in ipairs({ 'SPELLS_CHANGED', 'SPELL_TEXT_UPDATE', 'LEARNED_SPELL_IN_SKILL_LINE' }) do rankFrame.OnEvent(rankFrame, event) end
 assert(#timers == 1 and actions[4] == 853, 'señales no agrupadas: '..#timers)
 timers[1](); assert(bookReads == 1 and actions[4] == 5588)
 C_Timer.After = baseAfter
 -- Opción apagada: con un botón atrasado no se toca nada y ni se lee el libro.
 actions[4] = 853; bookReads = 0; E.db.KnuUIRankUpgrade = false
 assert(module:UpgradeSpellRank(5588) == 0 and module:UpgradeAllRanks() == 0 and actions[4] == 853 and bookReads == 0)
 E.db.KnuUIRankUpgrade = nil
 C_SpellBook = nil
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

-- Perfiles aislados: creación, comandos reales, inicialización y combate.
do
 local savedDB, savedGlobal, savedPrivate = E.db, E.global, E.private
 local savedData, savedElvDB, savedEvents = E.data, ElvDB, module.styleEvents
 local savedScreen, savedPrint, savedAfter = GetPhysicalScreenSize, E.Print, C_Timer.After
 -- ReloadUI está bloqueada fuera de un clic: el estilo pide recargar con la ventana CONFIG_RL. Acá cada ventana
 -- cuenta como una recarga aceptada; una llamada directa a ReloadUI rompe la prueba.
 local savedPopup, savedReload = E.StaticPopup_Show, ReloadUI
 E.StaticPopup_Show = function(_, name) popup = name; if name == 'CONFIG_RL' then reloads = reloads + 1 end end
 ReloadUI = function() error('ReloadUI directo: bloqueado en el juego') end
 local savedLibStub=LibStub
 LibStub=nil
 C_Timer.After=function(_, fn) fn() end
 local function Equal(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= 'table' then return a == b end
  for k, v in pairs(a) do if not Equal(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
 end
 local current, switches, callback = 'Personal', 0, nil
 local raw = { unitframe={units={player={width=713}}}, ajeno={uno={dos=3}} }
 local original = E:CopyTable({}, raw)
 ElvDB = { profiles={ Personal=raw, ['KnuUI ajeno']={ajeno=true},
  ['Ajeno con marcador']={KnuUIStyle='bruma'} } }
 E.data = {
  GetCurrentProfile = function() return current end,
  SetProfile = function(_, name)
   assert(ElvDB.profiles[name]); current=name; switches=switches+1
   -- AceDB aporta defaults al perfil vacío; UpdateAll actualiza E.db antes del callback.
   if name == 'Personal' then E.db=raw
   else
    E.db=E:CopyTable(E:CopyTable({}, P), ElvDB.profiles[name])
    ElvDB.profiles[name]=E.db
   end
   if callback then callback() end
  end,
  RegisterCallback = function(owner, event, method)
   assert(owner == module and event == 'OnProfileChanged' and method == 'StyleProfileChanged')
   callback=function() owner[method](owner) end
  end,
 }
 Fresh()
 E.private.KnuUIRole = 'tank'
 local beforeDB, beforePrivate = E:CopyTable({}, E.db), E:CopyTable({}, E.private)
 local printed = {}
 E.Print = function(_, message) printed[#printed+1]=message end
 assert(knuCommands.perfiles and knuCommands.probar and knuCommands.volver)
 assert(knuCommands.perfiles.h(''))
 local list = module:StyleProfiles()
 assert(#list == 12 and switches == 0 and Equal(raw, original) and Equal(beforeDB,E.db))
 assert(Equal(beforePrivate,E.private))
 local categories, names = {}, {}
 for i, p in ipairs(list) do
  assert(not names[p.name] and p.name:match('^KnuUI ') and p.name:find(' · '..p.category..' · '..p.role:upper(),1,true))
  names[p.name],categories[p.category]=true,(categories[p.category] or 0)+1
  local seed=ElvDB.profiles[p.name]
  assert(Equal(seed,{KnuUIStyle=p.id,KnuUIRole=p.role,KnuUITanks=false,KnuUIStylePending=true,KnuUITomTomPlaced=true}))
  assert(printed[i+1+math.ceil(i/4)] == format('%d. %s',i,p.name), 'Lista numerada y agrupada')
 end
 assert(categories.Minimalista==4 and categories.Utilidad==4 and categories.Combate==4)
 local first=ElvDB.profiles[list[1].name]
 assert(knuCommands.perfiles.h('') and ElvDB.profiles[list[1].name] == first)
 first.ajeno=true
 ElvDB.profiles['KnuUI obsoleto']={KnuUIStyle='viejo'}
 assert(knuCommands.perfiles.h('rehacer'))
 assert(ElvDB.profiles[list[1].name] ~= first and not ElvDB.profiles[list[1].name].ajeno)
 assert(not ElvDB.profiles['KnuUI obsoleto'] and ElvDB.profiles['KnuUI ajeno'].ajeno)
 assert(ElvDB.profiles['Ajeno con marcador'].KnuUIStyle and Equal(raw,original) and switches==0)
 -- El perfil activo jamás se recrea, tampoco si es un estilo.
 current=list[1].name; first=ElvDB.profiles[current]
 assert(module:CreateStyleProfiles(true) and ElvDB.profiles[current]==first)
 current='Personal'
 combat=true
 local snapshot=E:CopyTable({},ElvDB)
 assert(not knuCommands.perfiles.h('') and not knuCommands.perfiles.h('rehacer'))
 assert(not knuCommands.probar.h('1') and not knuCommands.volver.h(''))
 assert(Equal(snapshot,ElvDB) and switches==0 and E.global.KnuUIPreviousProfile==nil)
 combat=false
 assert(not module:ApplyStyle('bruma') and Equal(beforeDB,E.db))
 assert(not module:ApplyPendingStyle())
 -- Registra el callback que también cubre el selector nativo de ElvUI.
 module.styleEvents=nil
 assert(not module:SetupStyles() and callback)
 local methods = {'ApplyLayout','ApplyChat','ApplyNameplates','ApplyTracker','ApplyTheme','ApplyBase','ApplyRoleOverlay','ApplyStyle'}
 local excluded = {'ApplyCamera','ApplyCooldownLayout','ApplyAddons','ApplyTanks','ApplyRole'}
 local originals, order = {}, {}
 for _, name in ipairs(methods) do
  local method=name; originals[method]=module[method]
  module[method]=function(self,...)
   order[#order+1]=method
   assert(E.db.KnuUIRole=='healer' and E.private.KnuUIRole=='tank')
   return originals[method](self,...)
  end
 end
 for _, name in ipairs(excluded) do originals[name]=module[name]; module[name]=function() error('Paso excluido: '..name) end end
 GetPhysicalScreenSize=function() return 1280,720 end
 local oldReloads=reloads
 assert(knuCommands.probar.h('3') and current==list[3].name and E.global.KnuUIPreviousProfile=='Personal')
 -- ApplyLayout también aplica el overlay; la secuencia explícita conserva el orden auditado.
 assert(table.concat(order,',')=='ApplyLayout,ApplyRoleOverlay,ApplyChat,ApplyNameplates,ApplyTracker,ApplyTheme,ApplyBase,ApplyRoleOverlay,ApplyStyle')
 assert(reloads==oldReloads+1 and E.db.KnuUILayoutVersion==module.version and not E.db.KnuUIStylePending)
 assert(math.abs(E.global.general.UIScale-768/1080)<1e-12, 'Se necesitan las dos dimensiones físicas')
 assert(E.private.KnuUIRole=='tank' and E.db.KnuUIRole=='healer' and not E.db.KnuUITanks)
 local globalOnce, privateOnce=E:CopyTable({},E.global),E:CopyTable({},E.private)
 assert(not module:ApplyPendingStyle() and reloads==oldReloads+1)
 -- Repetir las escrituras compartidas de la inicialización es idempotente.
 E.db.KnuUIStylePending=true
 assert(module:ApplyPendingStyle() and Equal(globalOnce,E.global) and Equal(privateOnce,E.private))
 -- Extras no debe imponer el rol del personaje sobre el del estilo.
 local savedCreate, roleCalls=CreateFrame,0
 C_Timer.After=function(_, fn) fn() end
 local frames={}
 CreateFrame=function(...) local f=savedCreate(...); frames[#frames+1]=f; return f end
 module.ApplyRole=function() roleCalls=roleCalls+1; return false end
 module:SetupExtras()
 for _, f in ipairs(frames) do
  if f.events and f.events.PLAYER_REGEN_DISABLED and f.events.PLAYER_ENTERING_WORLD then f.OnEvent(f,'PLAYER_ENTERING_WORLD') end
 end
 assert(roleCalls==0 and E.private.KnuUIRole=='tank' and E.db.KnuUIRole=='healer')
 E.db.KnuUIStyle=nil
 module:SetupExtras()
 for _, f in ipairs(frames) do
  if f.events and f.events.PLAYER_REGEN_DISABLED and f.events.PLAYER_ENTERING_WORLD then f.OnEvent(f,'PLAYER_ENTERING_WORLD') end
 end
 assert(roleCalls>0, 'Extras conserva el rol por personaje fuera de estilos')
 E.db.KnuUIStyle=list[3].id
 CreateFrame=savedCreate
 for name, fn in pairs(originals) do module[name]=fn end
 oldReloads=reloads; popup=nil
 assert(knuCommands.volver.h('') and current=='Personal' and Equal(raw,original))
 assert(popup=='CONFIG_RL' and reloads==oldReloads+1, 'Volver pide recargar con la ventana')
 oldReloads=reloads; popup=nil
 local styleCalls, savedApplyStyle = 0, module.ApplyStyle
 module.ApplyStyle=function(...) styleCalls=styleCalls+1; return savedApplyStyle(...) end
 assert(knuCommands.probar.h('3') and styleCalls==0, 'Volver a un estilo inicializado no lo reaplica')
 assert(popup=='CONFIG_RL' and reloads==oldReloads+1, 'Un estilo ya armado pide recargar')
 module.ApplyStyle=savedApplyStyle
 assert(knuCommands.volver.h(''))
 assert(knuCommands.probar.h(list[2].name) and current==list[2].name)
 -- Probar otro estilo encima de un estilo conserva el perfil del jugador para volver.
 assert(knuCommands.probar.h('4') and current==list[4].name and E.global.KnuUIPreviousProfile=='Personal')
 assert(knuCommands.volver.h('') and current=='Personal')
 -- Instalador: el botón de un estilo crea lo que falte y prueba ese estilo con el rol del perfil activo.
 assert(knuCommands.volver.h('') and current=='Personal')
 local roleNow = E.db.KnuUIRole or E.private.KnuUIRole or 'mdps'
 local beforeCount = 0; for _ in pairs(ElvDB.profiles) do beforeCount = beforeCount + 1 end
 assert(module:TryStyle('parentesis'))
 local want; for _, p in ipairs(list) do if p.id=='parentesis' and p.role==roleNow then want=p.name end end
 assert(want and current==want and E.global.KnuUIPreviousProfile=='Personal', 'Instalador: estilo con el rol actual')
 local afterCount = 0; for _ in pairs(ElvDB.profiles) do afterCount = afterCount + 1 end
 assert(afterCount==beforeCount, 'Instalador: no duplica perfiles')
 assert(not module:TryStyle('inexistente'))
 assert(knuCommands.volver.h('') and current=='Personal')
 -- Perfil anterior borrado: volver no hace nada y no falla.
 E.global.KnuUIPreviousProfile='Borrado'
 assert(not knuCommands.volver.h('') and current=='Personal')
 E.global.KnuUIPreviousProfile='Personal'
 assert(not knuCommands.probar.h('99') and not knuCommands.probar.h('inexistente'))
 oldReloads=reloads
 E.data:SetProfile(list[5].name)
 assert(reloads==oldReloads+1 and not E.db.KnuUIStylePending, 'Selector nativo de ElvUI')
 assert(knuCommands.volver.h('') and Equal(raw,original))
 -- AceDB puede avisar antes de que ElvUI cambie E.db. El callback espera un cuadro.
 local queued={}
 C_Timer.After=function(_, fn) queued[#queued+1]=fn end
 oldReloads=reloads
 callback()
 assert(#queued==1 and reloads==oldReloads)
 E.db=E:CopyTable({}, P)
 E.db.KnuUIStyle,E.db.KnuUIRole,E.db.KnuUIStylePending='bruma','healer',true
 queued[1]()
 assert(reloads==oldReloads+1 and not E.db.KnuUIStylePending and E.private.KnuUIRole=='tank')
 C_Timer.After=function(_, fn) fn() end
 -- Carga en combate: espera, y sólo inicializa el perfil que siga activo al salir.
 Fresh(); E.private.KnuUIRole='tank'
 E.db.KnuUIStyle,E.db.KnuUIRole,E.db.KnuUIStylePending='tablero','healer',true
 combat=true; oldReloads=reloads
 module:Initialize()
 assert(E.db.KnuUIStylePending and reloads==oldReloads)
 assert(module.styleEvents.events.PLAYER_REGEN_ENABLED)
 combat=false
 module.styleEvents.OnEvent(module.styleEvents,'PLAYER_REGEN_ENABLED')
 assert(reloads==oldReloads+1 and not E.db.KnuUIStylePending and E.private.KnuUIRole=='tank')
 module.styleEvents.OnEvent(module.styleEvents,'PLAYER_REGEN_ENABLED')
 assert(reloads==oldReloads+1)
 E.db.KnuUIStylePending=true; combat=true; module.styleEvents.events.PLAYER_REGEN_ENABLED=nil
 assert(not module:ApplyPendingStyle() and module.styleEvents.events.PLAYER_REGEN_ENABLED, 'En combate espera sin cortar la carga')
 E.db.KnuUIStyle=nil; combat=false
 module.styleEvents.OnEvent(module.styleEvents,'PLAYER_REGEN_ENABLED')
 assert(reloads==oldReloads+1, 'No aplicar el estilo después de abandonar el perfil pendiente')
 E.db,E.global,E.private=savedDB,savedGlobal,savedPrivate
 E.data,ElvDB,module.styleEvents=savedData,savedElvDB,savedEvents
 GetPhysicalScreenSize,E.Print,C_Timer.After=savedScreen,savedPrint,savedAfter
 E.StaticPopup_Show, ReloadUI = savedPopup, savedReload
 LibStub=savedLibStub
 print('OK: 12 perfiles aislados; comandos, recreación, inicialización, roles y combate.')
end

-- Flecha de TomTom: la posición vieja de KnuUI (x 300, encima del borde de la guía) pasa a x 316; si el jugador la
-- movió, no se toca. TomTom guarda la posición en su propio perfil, compartido entre perfiles de ElvUI.
do
 local savedTT, savedArrow, savedAfter, savedLoaded = _G.TomTom, _G.TomTomCrazyArrow, C_Timer.After, module.IsLoaded
 local savedEUI, savedUI, savedDB = E.UIParent.GetEffectiveScale, UIParent.GetEffectiveScale, E.db
 E.UIParent.GetEffectiveScale = function() return 1 end
 UIParent.GetEffectiveScale = function() return 1 end
 C_Timer.After = function(_, fn) fn() end
 module.IsLoaded = function() return false end
 local point
 _G.TomTomCrazyArrow = { ClearAllPoints = function() end, SetPoint = function(_, ...) point = { ... } end }
 local function Run(pos, placed)
  E.db = { KnuUITomTomPlaced = placed }
  _G.TomTom = { profile = { arrow = { position = pos } } }
  point = nil
  module:SetupTomTomSkin()
  return _G.TomTom.profile.arrow.position
 end
 local p = Run({ 'TOPLEFT', nil, 'TOPLEFT', 300, -16 }, true)
 assert(p[4] == 316 and p[5] == -16 and point and point[4] == 316 and E.db.KnuUITomTomPlaced, 'flecha: x 300 pasa a 316')
 p = Run({ 'TOPLEFT', nil, 'TOPLEFT', 900, -40 }, true)
 assert(p[4] == 900 and not point, 'flecha: movida por el jugador')
 p = Run({ 'CENTER', nil, 'CENTER', 0, 0 }, nil)
 assert(p[4] == 316 and p[1] == 'TOPLEFT', 'flecha: primera vez en el perfil')
 E.db = { KnuUITomTomPlaced = true, KnuUIStyle = 'tablero' }
 _G.TomTom = { profile = { arrow = { position = { 'TOPLEFT', nil, 'TOPLEFT', 300, -16 } } } }
 point = nil; module:SetupTomTomSkin()
 assert(_G.TomTom.profile.arrow.position[4] == 300 and not point, 'flecha: un perfil de estilo no la mueve')
 _G.TomTom, _G.TomTomCrazyArrow, C_Timer.After, module.IsLoaded = savedTT, savedArrow, savedAfter, savedLoaded
 E.UIParent.GetEffectiveScale, UIParent.GetEffectiveScale, E.db = savedEUI, savedUI, savedDB
end

-- Auditoría 2026-11-19 (Codex): cámara sólo en el perfil «KnuUI» de DynamicCam, build Healer -> Tank sin
-- arrastrar el grupo del Healer, animación reemplazada que no sigue corriendo y flecha por la guía de Shortest Path.
do
 local savedAfter, savedLoaded = C_Timer.After, module.IsLoaded
 C_Timer.After = function(_, fn) fn() end
 local function Cam(profile)
  local s = { ['300'] = { transitionTime = { timeToEnter = 1, timeToExit = 1 }, rotation = { enabled = true } } }
  _G.DynamicCam = { db = { profile = { standardSettings = { cvars = {} }, situations = s },
   GetCurrentProfile = function() return profile end } }
  module.IsLoaded = function(_, name) return name == 'DynamicCam' or savedLoaded(module, name) end
  E.global.KnuUICameraApplied, E.global.KnuUICombatZoomV = true, 2
  module:SetupCombatZoom()
  return s['300']
 end
 -- La migración única (KnuUICombatZoomV) tampoco cambia un perfil ajeno al de KnuUI.
 local applied = false
 local savedApply = module.ApplyCamera
 module.ApplyCamera = function() applied = true; return true end
 Cam('Mi perfil'); E.global.KnuUICombatZoomV = nil; module:SetupCombatZoom()
 assert(not applied and E.global.KnuUICombatZoomV == nil, 'cámara: la migración pisó un perfil ajeno')
 module.ApplyCamera = savedApply
 local mine = Cam('Mi perfil')
 assert(mine.rotation.enabled == true and mine.transitionTime.timeToEnter == 1, 'cámara: perfil ajeno intacto')
 local knu = Cam('KnuUI')
 assert(knu.rotation.enabled == false and knu.transitionTime.timeToEnter == 2.5, 'cámara: perfil KnuUI suavizado')
 -- Cámaras un 50 % más lejos (pedido del user 2026-11-22): una vez, sólo en el perfil «KnuUI», tope 39, todos los tipos.
 local function CamZ(profile)
  local s = { a = { viewZoom = { zoomValue = 8, zoomMin = 10 } }, b = { viewZoom = { zoomValue = 28 } },
   c = { viewZoom = { zoomType = 'in', zoomValue = 5 } }, d = { viewZoom = { zoomType = 'range', zoomMin = 10, zoomMax = 14 } } }
  _G.DynamicCam = { db = { profile = { standardSettings = { cvars = {} }, situations = s },
   GetCurrentProfile = function() return profile end } }
  E.global.KnuUICameraApplied, E.global.KnuUICombatZoomV, E.global.KnuUICamFarther = true, 2, nil
  module:SetupCombatZoom()
  return s
 end
 local z = CamZ('Mi perfil')
 assert(z.a.viewZoom.zoomValue == 8 and z.b.viewZoom.zoomValue == 28 and E.global.KnuUICamFarther == nil, 'cámara lejos: perfil ajeno')
 z = CamZ('KnuUI')
 assert(z.a.viewZoom.zoomValue == 12 and z.a.viewZoom.zoomMin == 15 and z.b.viewZoom.zoomValue == 39, 'cámara lejos: 50 % y tope')
 assert(z.c.viewZoom.zoomValue == 7.5 and z.d.viewZoom.zoomMin == 15 and z.d.viewZoom.zoomMax == 21, 'cámara lejos: in y rango')
 module:SetupCombatZoom()
 assert(z.a.viewZoom.zoomValue == 12 and E.global.KnuUICamFarther == 1, 'cámara lejos: una sola vez')
 -- Si el inicio cae en combate, se aplica al salir.
 combat = true
 local zc = CamZ('KnuUI')
 assert(zc.a.viewZoom.zoomValue == 8 and E.global.KnuUICamFarther == nil and PendingAfterCombat('KnuUI:CamFarther'), 'cámara lejos: espera fin de combate')
 combat = false; RunAfterCombat()
 assert(zc.a.viewZoom.zoomValue == 12 and E.global.KnuUICamFarther == 1, 'cámara lejos: aplicada al salir de combate')
 E.global.KnuUICamFarther = nil
 _G.DynamicCam, E.global.KnuUICameraApplied, E.global.KnuUICombatZoomV = nil, nil, nil
 module.IsLoaded = savedLoaded

 -- Motion: una animación reemplazada por otra que ya está en su valor no sigue escribiendo el valor viejo.
 local v = 0
 module:Tween('auditoria', 0, 1, 0.25, function(x) v = x end)
 module:Tween('auditoria', 0, 0, 0.25, function(x) v = x end)
 module:FlushTweens()
 assert(v == 0, 'motion: la animación vieja quedó corriendo')

 -- Builds: Healer -> Tank deja el grupo igual que Melee -> Tank.
 local savedClass = E.myclass
 E.myclass = 'DRUID'
 local party = E.db.unitframe.units.party
 assert(module:ApplyBuild('DRUID_mdps') and module:ApplyBuild('DRUID_tank'))
 local ref = { party.width, party.growthDirection, E.db.movers.ElvUF_PartyMover }
 assert(module:ApplyBuild('DRUID_healer') and party.width == 82)
 assert(module:ApplyBuild('DRUID_tank'))
 assert(party.width == ref[1] and party.growthDirection == ref[2] and E.db.movers.ElvUF_PartyMover == ref[3],
  'builds: el grupo del Healer quedó en la build Tank')
 E.myclass = savedClass
 C_Timer.After = savedAfter
end

-- TomTomRoute: la flecha sigue la próxima curva de API.Guidance (sin punto de usuario del juego), se actualiza
-- por la suscripción, y nunca borra un punto de TomTom que no creó KnuUI.
do
 local savedTT, savedSPF, savedLoaded, savedHooked = _G.TomTom, _G.ShortestPathForever, module.IsLoaded, module.tomtomRouteHooked
 local savedRoute, savedQuiet = E.db.KnuUITomTomRoute, E.global.KnuUISPFQuiet
 local points, removed, arrow, listener = {}, {}, nil, nil
 local guidance = { point = { map = 1, x = 0.2, y = 0.3 } }
 local tt = {}
 function tt:SetCrazyArrow(uid) arrow = uid end
 function tt:IsValidWaypoint(uid) return not removed[uid] end
 function tt:RemoveWaypoint(uid) removed[uid] = true end
 function tt:AddWaypoint(m, x, y, opts)
  local key = m..':'..x..':'..y..':'..tostring(opts.title)
  if points[key] and not removed[points[key]] then return points[key] end
  local uid = { m, x, y, title = opts.title, from = opts.from }
  points[key] = uid; arrow = uid
  return uid
 end
 _G.TomTom = tt
 local stop = true
 _G.ShortestPathForever = { API = {
  Navigate = function() return true end,
  CurrentStop = function() return stop end,
  Guidance = function() return guidance end,
  Subscribe = function(fn) listener = fn end,
 } }
 module.IsLoaded = function(_, name) return name == 'TomTom' or name == 'ShortestPathForever' or savedLoaded(module, name) end
 module.tomtomRouteHooked, E.db.KnuUITomTomRoute, E.global.KnuUISPFQuiet = nil, nil, true
 module:SetupTomTomRoute()
 assert(type(listener) == 'function', 'ruta: sin suscripción a Shortest Path')
 local dest = { 1, 0.8, 0.9, title = 'Destino', from = 'WoWPro' }
 points['1:0.8:0.9:Destino'] = dest
 tt:SetCrazyArrow(dest)
 assert(arrow and arrow ~= dest and arrow[2] == 0.2 and arrow.from == 'KnuUI', 'ruta: la flecha no fue a la curva')
 local first = arrow
 guidance = { point = { map = 1, x = 0.5, y = 0.5 } }
 listener({ guidance = 1 })
 assert(removed[first] and arrow[2] == 0.5, 'ruta: la suscripción no movió la flecha')
 -- La curva cae justo en el destino (mismo mapa, coordenadas y título): TomTom devuelve el original.
 guidance = { point = { map = 1, x = 0.8, y = 0.9 } }
 listener({ guidance = 1 })
 assert(arrow == dest and not removed[dest], 'ruta: no apunta al destino original')
 stop = false
 listener({ ended = 1 })
 assert(not removed[dest] and arrow == dest, 'ruta: al terminar borró el punto original')
 _G.TomTom, _G.ShortestPathForever, module.IsLoaded, module.tomtomRouteHooked = savedTT, savedSPF, savedLoaded, savedHooked
 E.db.KnuUITomTomRoute, E.global.KnuUISPFQuiet = savedRoute, savedQuiet
end

-- Invitación a opinar: una sola vez por cuenta, con los dos links, demorada; /knu opinar la repite siempre.
do
 local savedPrint, savedAfter, savedFlag = E.Print, C_Timer.After, E.global.KnuUIFeedbackShown
 local printed, queued = {}, {}
 E.Print = function(_, msg) printed[#printed + 1] = msg end
 C_Timer.After = function(delay, fn) queued[#queued + 1] = { delay, fn } end
 E.global.KnuUIFeedbackShown = nil
 module:SetupFeedback()
 assert(#printed == 0 and #queued == 1 and queued[1][1] == 20, 'opinar: no quedó demorada 20 s')
 queued[1][2]()
 assert(#printed == 1 and E.global.KnuUIFeedbackShown == true, 'opinar: no salió o no marcó el flag')
 assert(printed[1]:find(module.feedbackURL, 1, true) and printed[1]:find(module.issuesURL, 1, true), 'opinar: faltan los links')
 assert(module.feedbackURL:find('curseforge.com/wow/addons/knuui', 1, true) and module.issuesURL:find('github.com/knupson/KnuUI/issues', 1, true), 'opinar: links equivocados')
 module:SetupFeedback()
 assert(#queued == 1 and #printed == 1, 'opinar: se repitió con el flag puesto')
 -- Dos SetupFeedback antes de que venza la demora: sale una sola vez.
 E.global.KnuUIFeedbackShown, queued, printed = nil, {}, {}
 module:SetupFeedback(); module:SetupFeedback()
 for _, q in ipairs(queued) do q[2]() end
 assert(#printed == 1, 'opinar: salió dos veces')
 assert(not printed[1]:find(module.otherAddonsURL, 1, true), 'otros addons: no va en el aviso automático')
 module:PrintFeedback()
 assert(#printed == 2, 'opinar: el comando no la repite')
 SlashCmdList.KNUUI('opinar'); SlashCmdList.KNUUI('feedback')
 assert(#printed == 6, 'opinar: falta el subcomando o la línea de otros addons')
 knuCommands.opinar.h('')
 assert(#printed == 8, 'opinar: /knu opinar no la muestra')
 assert(printed[7]:find(module.feedbackURL, 1, true) and printed[8]:find(module.otherAddonsURL, 1, true), 'otros addons: falta al pie de /knu opinar')
 local companionAt = printed[8]:find(module.companionURL, 1, true)
 assert(module.companionURL == 'https://companion.knunet.com' and companionAt and companionAt < printed[8]:find(module.otherAddonsURL, 1, true), 'otros addons: KnuCompanion no va primero')
 assert(module.otherAddonsURL == 'https://www.curseforge.com/members/knupwns/projects', 'otros addons: link equivocado')
 E.Print, C_Timer.After, E.global.KnuUIFeedbackShown = savedPrint, savedAfter, savedFlag
end

assert(loadfile('addons/KnuUI/tests/cooldown-viewer.lua'))()
assert(loadfile('addons/KnuUI/tests/cooldown-layout.lua'))()
print('OK: batería completa Lua 5.1; temas, builds por clase/rol, opciones y API Offhand ausente/parcial/completa.')
