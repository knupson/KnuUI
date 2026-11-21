-- Ubicación de los paneles de Blizzard respecto de la guía de WoW-Pro (UIPanels.lua). Correr desde la raíz del repo:
--   luajit addons/KnuUI/tests/paneles.lua
-- Modelo: pantalla 1920x1080 px; cada marco tiene su escala; las posiciones se miden en píxeles con y hacia arriba.
unpack = unpack or table.unpack

local queue = {}
C_Timer = { After = function(_, fn) queue[#queue + 1] = fn end }
local function Flush()
	local n = 0
	while #queue > 0 do
		local q = queue; queue = {}
		for _, fn in ipairs(q) do fn(); n = n + 1 end
	end
	return n
end

local combat = false
function InCombatLockdown() return combat end

function hooksecurefunc(object, method, callback)
	if type(object) == 'string' then object, method, callback = _G, object, method end
	local original = object[method]
	object[method] = function(...)
		local result = { original(...) }
		callback(...)
		return unpack(result)
	end
end

local events
function CreateFrame()
	events = { RegisterEvent = function() end }
	function events:SetScript(_, fn) self.fn = fn end
	return events
end

local SW, SH = 1920, 1080
local UIParent = { u = 1 }
function UIParent:GetEffectiveScale() return self.u end
function UIParent:GetRight() return SW / self.u end
function UIParent:GetTop() return SH / self.u end
_G.UIParent = UIParent

-- Marco con un único punto relativo a UIParent: TOPLEFT/TOPLEFT o TOP/TOP, offsets en unidades propias.
local function Frame(name, w, h, point, x, y, scale)
	local f = { name = name, w = w, h = h, scale = scale or 1, shown = true, scripts = {} }
	f.pt = { point, UIParent, point, x, y }
	function f:GetName() return self.name end
	function f:GetEffectiveScale() return UIParent.u * self.scale end
	function f:IsShown() return self.shown end
	function f:GetNumPoints() return self.pt and 1 or 0 end
	function f:GetPoint() return unpack(self.pt) end
	function f:ClearAllPoints() self.pt = nil end
	function f:SetPoint(p, rel, rp, px, py) self.pt = { p, rel, rp, px, py } end
	function f:HookScript(ev, fn)
		local old = self.scripts[ev]
		self.scripts[ev] = function(...) if old then old(...) end; fn(...) end
	end
	function f:Fire(ev) if self.scripts[ev] then self.scripts[ev](self) end end
	function f:StopMovingOrSizing() end
	local function Box()
		local es = f:GetEffectiveScale()
		local pw, ph = SW / es, SH / es -- tamaño de la pantalla en unidades del marco
		local p, _, _, px, py = unpack(f.pt)
		local left = p == 'TOP' and (pw / 2 + px - f.w / 2) or px
		local top = ph + py
		return left, top
	end
	function f:GetLeft() local l = Box(); return l end
	function f:GetRight() local l = Box(); return l + self.w end
	function f:GetTop() local _, t = Box(); return t end
	function f:GetBottom() local _, t = Box(); return t - self.h end
	return f
end

-- Rectángulo en píxeles de pantalla, con y desde arriba para leerlo como en las capturas.
local function Px(f)
	local es = f:GetEffectiveScale()
	return f:GetLeft() * es, SH - f:GetTop() * es, f:GetRight() * es, SH - f:GetBottom() * es
end
local function Near(a, b) return math.abs(a - b) < 0.01 end

local slots = {}
function GetUIPanel(key) return slots[key] end
local cc = false

local K = { blizzardMovers = {}, CC_IsActive = function() return cc end }
-- KnuLib AfterCombat: una entrada por clave; AfterCombatRun() hace de PLAYER_REGEN_ENABLED.
local after, afterKeys = {}, {}
function K:AfterCombat(fn, key)
	if not InCombatLockdown() then fn() return true end
	if afterKeys[key] then afterKeys[key].fn = fn return false end
	local e = { fn = fn }; after[#after + 1] = e; afterKeys[key] = e
	return false
end
local function AfterCombatRun() local q = after; after, afterKeys = {}, {}; for _, e in ipairs(q) do e.fn() end end
local E = { db = {} }
function E:GetModule(name) assert(name == 'KnuUI'); return K end
ElvUI = { E }

-- Guía: x 8-308; el borde de abajo cambia según el caso (en píxeles desde arriba).
local guide = Frame('WoWProMainFrame', 300, 395, 'TOPLEFT', 8, -8)
WoWPro = { MainFrame = guide, CreateFrames = function() end }
local function GuideBottom(px) guide.h = px - 8; guide:Fire('OnSizeChanged') end

-- Funciones globales de Blizzard que KnuUI engancha (deben existir antes del setup).
local calls = {}
for _, name in ipairs({ 'ShowUIPanel', 'HideUIPanel', 'UpdateUIPanelPositions', 'UpdateScaleForFitForOpenPanels' }) do
	_G[name] = function() calls[name] = (calls[name] or 0) + 1 end
end

local fn = assert(loadfile('addons/KnuUI/UIPanels.lua'))
fn()
K:SetupUIPanels()
Flush()

-- 1. Talentos centrado por Blizzard (x 352-1570): no toca la guía -> no se mueve.
GuideBottom(403); Flush()
local talents = Frame('PlayerSpellsFrame', 1218, 708, 'TOP', 0, -116)
slots.center = talents
K:SetupUIPanels() -- idempotente
guide:Fire('OnShow'); Flush()
local l, t = Px(talents)
assert(Near(l, 351) and Near(t, 116), 'talentos no debía moverse: '..l..','..t)
slots.center = nil

-- 2. Personaje 398x484 en x 16, arriba 116 -> se cruza; abajo entra (407+484=891 <= 940) -> debajo y alineado.
local char = Frame('CharacterFrame', 398, 484, 'TOPLEFT', 16, -116)
slots.left = char
guide:Fire('OnShow'); Flush()
l, t = Px(char)
assert(Near(l, 8) and Near(t, 407), 'personaje debajo de la guía: '..l..','..t)

-- 3. La guía crece hasta 600: abajo no entra (604+484 > 940) -> a la derecha (x 312), arriba la de Blizzard (116).
GuideBottom(600); Flush()
l, t = Px(char)
assert(Near(l, 312) and Near(t, 116), 'personaje a la derecha: '..l..','..t)

-- 4. La guía se achica de nuevo: vuelve a base y se recalcula (sin acumular corrimientos).
GuideBottom(403); Flush()
l, t = Px(char)
assert(Near(l, 8) and Near(t, 407), 'personaje recalculado: '..l..','..t)

-- 5. La guía se oculta: vuelve a lo de Blizzard.
guide.shown = false; guide:Fire('OnHide'); Flush()
l, t = Px(char)
assert(Near(l, 16) and Near(t, 116), 'personaje restaurado: '..l..','..t)
guide.shown = true; guide:Fire('OnShow'); Flush()

-- 6. Dos paneles empujados por Blizzard (left + center): mismo corrimiento, separación intacta.
local friends = Frame('FriendsFrame', 385, 424, 'TOPLEFT', 16 + 398 + 0, -116)
slots.center = friends
guide:Fire('OnShow'); Flush()
local cl = Px(char)
local fl, ft = Px(friends)
assert(Near(fl - cl, 398) and Near(ft, 407), 'segundo panel: '..fl..','..ft)
slots.center = nil

-- 7. Sin lugar abajo ni a la derecha -> queda donde lo puso Blizzard.
local huge = Frame('CollectionsJournal', 1700, 760, 'TOPLEFT', 16, -116)
slots.left = huge
guide:Fire('OnShow'); Flush()
l, t = Px(huge)
assert(Near(l, 16) and Near(t, 116), 'sin lugar: '..l..','..t)
slots.left = char

-- 8. Escalas distintas: UIParent 0.75 y panel 1.25 -> mismo resultado en píxeles.
UIParent.u = 0.75
local scaled = Frame('MacroFrame', 338 / 0.9375, 424 / 0.9375, 'TOPLEFT', 16 / 0.9375, -116 / 0.9375, 1.25)
guide.scale = 1 / 0.75 -- la guía sigue midiendo 300 px
slots.left = scaled
guide:Fire('OnShow'); Flush()
l, t = Px(scaled)
assert(Near(l, 8) and Near(t, 403 + 4 * 0.75), 'escalas: '..l..','..t)
UIParent.u, guide.scale = 1, 1
slots.left = char
guide:Fire('OnShow'); Flush()

-- 9. Blizzard reubica un panel corrido en otro punto: se olvida y se usa el nuevo como base.
l, t = Px(char)
assert(Near(t, 407))
char:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 400, -116) -- ya no se cruza con la guía
guide:Fire('OnShow'); Flush()
l, t = Px(char)
assert(Near(l, 400) and Near(t, 116), 'nuevo punto de Blizzard respetado: '..l..','..t)
char:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 16, -116)

-- 10. Combate: nada; al salir, se aplica. Varias señales en un cuadro -> una pasada.
combat = true
guide:Fire('OnShow'); guide:Fire('OnSizeChanged'); guide:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 8, -8)
assert(Flush() == 1, 'una sola pasada por cuadro')
l, t = Px(char)
assert(Near(l, 16) and Near(t, 116), 'en combate no se mueve')
combat = false
AfterCombatRun(); Flush()
l, t = Px(char)
assert(Near(l, 8) and Near(t, 407), 'al salir de combate')

-- 11. Arrastre de la guía (StopMovingOrSizing, sin SetPoint): se recalcula.
guide.pt = { 'TOPLEFT', UIParent, 'TOPLEFT', 8, -300 } -- ahora x 8-308, y 300-695
guide:StopMovingOrSizing(); Flush()
l, t = Px(char)
assert(Near(l, 312) and Near(t, 116), 'tras arrastrar la guía: '..l..','..t)
guide.pt = { 'TOPLEFT', UIParent, 'TOPLEFT', 8, -8 }; guide:Fire('OnShow'); Flush()

-- 12. Panel cerrado mientras estaba corrido: se restaura aunque esté oculto.
l, t = Px(char); assert(Near(t, 407))
char.shown = false; slots.left = nil; char:Fire('OnHide'); Flush()
char.shown = true
l, t = Px(char)
assert(Near(l, 16) and Near(t, 116), 'cerrado y restaurado: '..l..','..t)
slots.left = char

-- 13. Nunca se tocan: GameMenuFrame, mapa, varios puntos, anclado a otro marco, centro de comando.
local menu = Frame('GameMenuFrame', 260, 300, 'TOPLEFT', 16, -116)
slots.left, slots.center = nil, menu
guide:Fire('OnShow'); Flush()
l, t = Px(menu); assert(Near(l, 16) and Near(t, 116), 'menú')
local other = Frame('MailFrame', 338, 424, 'TOPLEFT', 16, -116)
other.pt[2] = {}
slots.center = other
guide:Fire('OnShow'); Flush()
assert(other.pt[4] == 16 and other.pt[5] == -116, 'anclado a otro marco')
slots.center = nil
slots.left = char; cc = true
guide:Fire('OnShow'); Flush()
l, t = Px(char); assert(Near(l, 16) and Near(t, 116), 'centro de comando')
cc = false

-- 14. WoW-Pro crea la guía después (CreateFrames): se engancha una sola vez.
local hooks = 0
local g2 = Frame('WoWProMainFrame', 300, 395, 'TOPLEFT', 8, -8)
local hs = g2.HookScript
function g2:HookScript(...) hooks = hooks + 1; return hs(self, ...) end
WoWPro.MainFrame = g2
WoWPro:CreateFrames(); WoWPro:CreateFrames(); Flush()
assert(hooks == 3, 'guía enganchada una vez: '..hooks)
l, t = Px(char)
assert(Near(l, 8) and Near(t, 407), 'con la guía nueva')

-- 15. Las señales llegan por las funciones de Blizzard (sin tocar la guía).
local function Reset()
	slots.left, slots.center = nil, nil
	char.shown = true
	g2:Fire('OnShow'); Flush() -- restaura lo corrido
end
Reset()
local mac = Frame('MacroFrame', 338, 424, 'TOPLEFT', 16, -116)
slots.left = mac; ShowUIPanel(mac); Flush()
l, t = Px(mac); assert(Near(l, 8) and Near(t, 407), 'ShowUIPanel: '..l..','..t)
-- Blizzard vuelve a ubicarlo en su punto (como hace el delegado) y avisa por UpdateUIPanelPositions.
mac:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 16, -116)
UpdateUIPanelPositions(); Flush()
l, t = Px(mac); assert(Near(l, 8) and Near(t, 407), 'UpdateUIPanelPositions: '..l..','..t)
mac:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 16, -116)
UpdateScaleForFitForOpenPanels(); Flush()
l, t = Px(mac); assert(Near(l, 8) and Near(t, 407), 'UpdateScaleForFitForOpenPanels: '..l..','..t)
slots.left = nil; mac.shown = false; HideUIPanel(mac); Flush()
mac.shown = true
l, t = Px(mac); assert(Near(l, 16) and Near(t, 116), 'HideUIPanel restaura: '..l..','..t)
assert(calls.ShowUIPanel == 1 and calls.HideUIPanel == 1 and calls.UpdateUIPanelPositions == 1
	and calls.UpdateScaleForFitForOpenPanels == 1, 'los originales de Blizzard siguen corriendo')

-- 16. Dos paneles separados con la guía en el hueco entre ellos: ninguno se cruza -> no se mueven.
-- Guía en x 600-900, y 200-300: con la caja que junta los dos se cruzaría y entrarían debajo (304+424 <= 940).
g2.pt = { 'TOPLEFT', UIParent, 'TOPLEFT', 600, -200 }; g2.h = 100
local a = Frame('CharacterFrame', 400, 424, 'TOPLEFT', 100, -116)
local b = Frame('FriendsFrame', 385, 424, 'TOPLEFT', 1000, -116)
slots.left, slots.center = a, b
g2:Fire('OnShow'); Flush()
local al, at = Px(a); local bl, bt = Px(b)
assert(Near(al, 100) and Near(at, 116) and Near(bl, 1000) and Near(bt, 116), 'guía en el hueco')
slots.left, slots.center = nil, nil

-- 17. Guía que WoW-Pro dejó en su punto de creación (TOPLEFT/UIParent/RIGHT -210,175) sin restaurar la posición
-- guardada: KnuUI le pide a WoW-Pro que la restaure (AnchorSync), salvo en combate o con la restauración inhibida.
local syncs, failNext = 0, false
local function DefaultPoint() g2.pt = { 'TOPLEFT', UIParent, 'RIGHT', -210, 175 } end
local function Saved() local p, rel, rp, x, y = g2:GetPoint(1); return p == 'TOPLEFT' and rel == UIParent and rp == 'TOPLEFT' and x == 8 and y == -8 end
WoWProDB = { profile = { position = { 'TOPLEFT', nil, 'TOPLEFT', 8, -8 } } }
WoWPro.InhibitAnchorStore = false
function WoWPro.AnchorSync()
	syncs = syncs + 1
	local was = WoWPro.InhibitAnchorStore
	WoWPro.InhibitAnchorStore = true
	g2:ClearAllPoints()
	if failNext then failNext = false; error('falla interna') end
	g2:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 8, -8)
	WoWPro.InhibitAnchorStore = was
end
function WoWPro.CustomizeFrames() end
WoWPro:CreateFrames(); Flush() -- engancha CustomizeFrames
-- a) Fuera de combate: después de CustomizeFrames se restaura.
DefaultPoint(); WoWPro:CustomizeFrames(); Flush()
assert(syncs == 1 and Saved(), 'guía restaurada: '..syncs)
-- b) En combate no; al salir, sí.
DefaultPoint(); combat = true; WoWPro:CustomizeFrames(); Flush()
assert(syncs == 1, 'en combate no se restaura')
combat = false; AfterCombatRun(); Flush()
assert(syncs == 2 and Saved(), 'restaurada al salir de combate')
-- c) Con la restauración inhibida (redimensionando) no; el próximo aviso de la guía la restaura.
DefaultPoint(); WoWPro.InhibitAnchorSync = true; g2:Fire('OnSizeChanged'); Flush()
assert(syncs == 2, 'inhibida')
WoWPro.InhibitAnchorSync = nil; g2:Fire('OnSizeChanged'); Flush()
assert(syncs == 3 and Saved(), 'restaurada después de la inhibición')
-- d) AnchorSync falla a mitad: la guía no queda sin ancla, InhibitAnchorStore vuelve, y se reintenta.
DefaultPoint(); failNext = true; WoWPro:CustomizeFrames(); Flush()
assert(syncs == 4 and g2:GetNumPoints() == 1 and WoWPro.InhibitAnchorStore == false, 'error interno')
local p, _, rp = g2:GetPoint(1); assert(p == 'TOPLEFT' and rp == 'RIGHT')
g2:Fire('OnShow'); Flush()
assert(syncs == 5 and Saved(), 'reintento tras el error')
-- e) En la posición guardada, arrastrada a otro lado o en una zona del centro de comando: nunca se toca.
g2:Fire('OnShow'); Flush()
g2.pt = { 'TOPLEFT', UIParent, 'TOPLEFT', 500, -300 }; g2:StopMovingOrSizing(); Flush()
g2:SetPoint('TOPLEFT', {}, 'TOPLEFT', 0, 0); Flush()
assert(syncs == 5, 'posiciones propias no se tocan')
-- f) El centro de comando devuelve la guía al punto de creación (lo había capturado así): se restaura.
g2:SetPoint('TOPLEFT', UIParent, 'RIGHT', -210, 175); Flush()
assert(syncs == 6 and Saved(), 'después de devolverla el centro de comando')
-- g) Sin datos de WoW-Pro: nada, sin error.
WoWProDB = nil; DefaultPoint(); WoWPro:CustomizeFrames(); Flush()
assert(syncs == 6)

print('PANELES OK')
