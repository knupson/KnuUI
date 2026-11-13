-- Ejecutar desde la raíz del repo con Lua 5.1 (o lupa). Sin WoW.
-- Ciclo activar -> apagar -> activar del centro de comando (Workspace.lua) con stubs.
format = string.format
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
local function Frame(name, w, h, parent)
	local f = { name = name, w = w or 100, h = h or 100, sc = 1, parent = parent, points = {}, shown = true }
	function f:GetName() return self.name end
	function f:GetWidth() return self.w end
	function f:GetHeight() return self.h end
	function f:SetSize(a, b) self.w, self.h = a, b end
	function f:GetScale() return self.sc end
	function f:SetScale(s) self.sc = s end
	function f:GetEffectiveScale() return self.sc * (self.parent and self.parent:GetEffectiveScale() or 1) end
	function f:ClearAllPoints() self.points = {} end
	function f:SetPoint(...) self.points[#self.points + 1] = { ... } end
	function f:GetPoint(i) local p = self.points[i or 1]; if p then return unpack(p) end end
	function f:GetNumPoints() return #self.points end
	function f:Show() self.shown = true end
	function f:Hide() self.shown = false end
	function f:IsShown() return self.shown end
	function f:GetLeft() return 10 end
	function f:GetTop() return 900 end
	function f:GetBottom() return 10 end
	function f:GetRect() return 0, 0, self.w, self.h end
	function f:GetCenter() return 50, 50 end
	function f:CreateTexture() return setmetatable({}, { __index = function() return function() end end }) end
	function f:SetFrameStrata() end
	function f:SetFrameLevel() end
	function f:IsIgnoringParentScale() return false end
	function f:GetParent() return self.parent end
	function f:SetScript() end
	function f:RegisterEvent() end
	function f:UnregisterEvent() end
	function f:SetBackdrop() end
	function f:SetAllPoints() end
	return f
end
UIParent = Frame('UIParent', 1950, 2194); UIParent.sc = 0.35
local K = {}
local EP = Frame('ElvUIParent', 1920, 1080, UIParent); EP.sc = 1.016
E = { db = { movers = { LeftChatMover = 'BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,4,4', RightChatMover = 'BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-4,4' } },
	UIParent = EP, GetModule = function() return K end, global = { general = { UIScale = 0.711 } } }
local setMoverCalls = {}
function E:SetMoverPoints(name) setMoverCalls[#setMoverCalls + 1] = name end
function E:SaveMoverPosition() end
ElvUI = { E }
local u = unpack; function unpack(t) if t == ElvUI then return E end return u(t) end
CreateFrame = function(_, name, parent) local f = Frame(name, 1, 1, parent); if name then _G[name] = f end; return f end
hooksecurefunc = function(t, k, f) if type(t) == 'table' and type(t[k]) == 'function' then local o = t[k]; t[k] = function(...) local r = o(...); f(...); return r end end end
InCombatLockdown = function() return false end
C_Timer = { After = function(_, f) f() end, NewTicker = function() return {} end }
C_AddOns = { IsAddOnLoaded = function(n) return n == 'Offhand' end }
GetPhysicalScreenSize = function() return 1920, 2160 end
LeftChatMover, RightChatMover = Frame('LeftChatMover', 400, 180, UIParent), Frame('RightChatMover', 529, 180, UIParent)
LeftChatPanel, RightChatPanel = Frame('LeftChatPanel', 400, 180, EP), Frame('RightChatPanel', 529, 180, EP)
DTPanelKnuUI_DataMover = Frame('DTPanelKnuUI_DataMover', 971, 22, UIParent)
local guide = Frame('WoWProMainFrame', 250, 300, UIParent); guide:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 8, -8)
WoWPro = { MainFrame = guide }
WorldMapFrame = Frame('WorldMapFrame', 1000, 700, UIParent); WorldMapFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
OpenMapDB = { worldmap = { window = false, windowSize = false, windowScale = 1 } }
local spanned = true
K.OffhandTopology = function() return spanned and {} or nil end
OffhandCompanionTopology = { physicalWidth = 1920, physicalHeight = 2160, game = { x = 0, y = 0, width = 1920, height = 1080 }, workspace = { x = 0, y = 1080, width = 1920, height = 1080 } }
local ns = { L = setmetatable({}, { __index = function(_, k) return k end }) }
loadfile('addons/KnuUI/Workspace.lua')('KnuUI', ns)
local CC = K.CC
local fails = 0
local function check(cond, msg) if not cond then print('FALLA', msg); fails = fails + 1 end end

-- 1) activar
K:SetupWorkspace()
CC:Apply()
check(K:CC_IsActive(), 'activo')
check(LeftChatMover.KnuCC and select(2, LeftChatMover:GetPoint(1)) == _G.KnuUI_CC_chat, 'chat al monitor de trabajo')
check(guide.KnuCC and select(2, guide:GetPoint(1)) == _G.KnuUI_CC_guide, 'guía a su zona')
check(type(OpenMapDB.worldmap.window) == 'table', 'mapa escrito en OpenMap')
check(E.db.KnuUICC.mapOrig ~= nil, 'mapa original guardado')

-- 2) apagar (ventana sin estirar)
spanned = false
CC:Apply()
check(not K:CC_IsActive(), 'inactivo')
check(not LeftChatMover.KnuCC, 'chat devuelto')
local found = false
for _, n in ipairs(setMoverCalls) do if n == 'LeftChatMover' then found = true end end
check(found, 'SetMoverPoints del chat')
local p, rel = guide:GetPoint(1)
check(p == 'TOPLEFT' and rel == UIParent, 'guía vuelve a TOPLEFT UIParent')
check(OpenMapDB.worldmap.window == false and E.db.KnuUICC.mapOrig == nil, 'OpenMap vuelve a sus valores')
check(select(1, WorldMapFrame:GetPoint(1)) == 'CENTER', 'mapa vuelve al lugar efectivo')

-- 3) el user mueve la guía en una pantalla y se vuelve a activar/apagar
guide:ClearAllPoints(); guide:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
spanned = true; CC:Apply()
spanned = false; CC:Apply()
local _, _, _, gx = guide:GetPoint(1)
check(gx == 100, 'guía conserva la posición nueva del segundo ciclo (gx=' .. tostring(gx) .. ')')

-- 4) cerrar con el centro activo y volver sin Offhand: mapa pendiente
spanned = true; CC:Apply()
check(E.db.KnuUICC.mapOrig ~= nil, 'mapa guardado otra vez')
-- simula una sesión nueva: active=false pero mapOrig quedó en el perfil
spanned = false
CC:Restore() -- deja active false (ya repone el mapa); se vuelve a escribir mapOrig a mano para el caso de sesión nueva
E.db.KnuUICC.mapOrig = { window = false, windowSize = false, windowScale = 1 }
OpenMapDB.worldmap.window = { 'TOPLEFT', 'BOTTOMLEFT', 5, 2000 }
CC:Apply()
check(OpenMapDB.worldmap.window == false, 'sesión nueva sin Offhand repone el mapa')
print(fails == 0 and 'CICLO OK' or ('FALLAS ' .. fails))
