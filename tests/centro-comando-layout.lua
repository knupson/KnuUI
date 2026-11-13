-- Ejecutar desde la raíz del repo con Lua 5.1 (o lupa). Sin WoW.
-- Geometría del centro de comando (Workspace.lua CC:Layout) en 4 disposiciones.
local K = {}
E = { db = {}, GetModule = function() return K end, UIParent = {} }
ElvUI = { E }
local u = unpack; function unpack(t) if t == ElvUI then return E end return u(t) end
format = string.format
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
local function F(w, h) return { GetWidth = function() return w end, GetHeight = function() return h end } end
LeftChatPanel, RightChatPanel, DTPanelKnuUI_Data = F(400, 180), F(529, 180), F(971, 22)
WoWPro = { MainFrame = F(250, 300) }
CreateFrame = function() return {} end
local ns = { L = setmetatable({}, { __index = function(_, k) return k end }) }
loadfile('addons/KnuUI/Workspace.lua')('KnuUI', ns)
local CC = K.CC
local function inside(r, W, H) return r.x >= 0 and r.y >= 0 and r.x + r.w <= W + 0.01 and r.y + r.h <= H + 0.01 end
local function overlap(a, b) return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h end
local fails = 0
local function case(name, W, H, edge, ov)
	local r = CC:Layout(W, H, edge, ov)
	local ids = { 'guide', 'chat', 'details', 'data', 'map', 'bags' }
	for _, id in ipairs(ids) do
		local z = r[id]
		if not z then print(name, 'FALTA', id); fails = fails + 1
		elseif not inside(z, W, H) then print(name, 'FUERA', id, z.x, z.y, z.w, z.h); fails = fails + 1 end
	end
	local near = { 'guide', 'chat', 'details', 'data' }
	for i = 1, #near do for j = i + 1, #near do
		if overlap(r[near[i]], r[near[j]]) then print(name, 'PISA', near[i], near[j]); fails = fails + 1 end
	end end
	for _, id in ipairs(near) do
		if r.map.h > 0 and overlap(r[id], r.map) then print(name, 'PISA MAPA', id); fails = fails + 1 end
	end
	local s = {}
	for _, id in ipairs(ids) do local z = r[id]; s[#s + 1] = format('%s=%d,%d %dx%d', id, z.x, z.y, z.w, z.h) end
	print(name, table.concat(s, ' | '))
	-- Regla del user: lo más mirado (guía) más cerca del borde contiguo que el mapa.
	local function dist(z)
		if edge == 'bottom' then return z.y elseif edge == 'top' then return H - (z.y + z.h)
		elseif edge == 'left' then return z.x else return W - (z.x + z.w) end
	end
	if edge == 'bottom' or edge == 'top' then
		if not (dist(r.guide) < dist(r.map)) then print(name, 'REGLA: guía no está más cerca que el mapa'); fails = fails + 1 end
	end
end
case('LG arriba 1920x1080', 1920, 1080, 'bottom')
case('trabajo abajo', 1920, 1080, 'top')
-- Vertical 1080x1920 a la derecha; comparte con el juego y=851..1920 (topología del user: vertical
-- arranca 851 px más arriba que el principal).
case('vertical derecha', 1080, 1920, 'left', { 0, 1069 })
case('vertical izquierda', 1080, 1920, 'right', { 851, 1920 })
case('ultrawide arriba 2560x1080', 2560, 1080, 'bottom')
case('chico 1280x720 arriba', 1280, 720, 'bottom')
print(fails == 0 and 'GEOMETRIA OK' or ('FALLAS ' .. fails))
