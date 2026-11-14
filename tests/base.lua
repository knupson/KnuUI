-- Desde la raíz del repo; Lua 5.1. La base del autor (Base.lua) es el resultado de "Aplicar todo":
-- con el rol del autor (melé) y el modo por defecto, cada valor de la base tiene que quedar tal cual en el
-- perfil (ningún paso posterior lo pisa). Con otros roles, sólo puede cambiar lo que toca ese rol.
local harness = assert(loadfile('addons/KnuUI/tests/verificar.lua'))('render-harness')
local E, K = harness.E, harness.K
assert(type(K.Base) == 'table' and next(K.Base), 'Base.lua vacío')

local function Leaves(t, path, out)
	for k, v in pairs(t) do
		local p = path == '' and tostring(k) or path .. '.' .. tostring(k)
		if type(v) == 'table' then Leaves(v, p, out) else out[#out + 1] = { p, v } end
	end
	return out
end
local function Get(t, dotted)
	for k in dotted:gmatch('[^%.]+') do
		if type(t) ~= 'table' then return nil end
		local n = tonumber(k)
		if t[k] ~= nil then t = t[k] else t = n and t[n] end
	end
	return t
end
local function Same(a, b)
	if type(a) == 'number' and type(b) == 'number' then return math.abs(a - b) < 1e-4 end
	return a == b
end

local leaves = Leaves(K.Base, '', {})
local function Run(role)
	harness.fresh()
	E.global.general.UIScale = nil
	assert(K:ApplyRole(role))
	E.db.KnuUITanks, E.db.KnuUICompactLeft, E.db.KnuUICompactRight = nil, nil, nil -- sin elegir: el modo por defecto
	K:ApplyAll()
	assert(E.db.KnuUITanks == true and E.db.KnuUICompactRight == true, 'el modo por defecto no es el del autor')
	local bad = {}
	for _, leaf in ipairs(leaves) do
		local got = Get(E.db, leaf[1])
		if not Same(got, leaf[2]) then bad[#bad + 1] = string.format('%s: base %s, quedó %s', leaf[1], tostring(leaf[2]), tostring(got)) end
	end
	return bad
end

local bad = Run('mdps')
for _, line in ipairs(bad) do print('  ' .. line) end
assert(#bad == 0, #bad .. ' valores de la base no quedaron con el rol del autor')
for _, role in ipairs({ 'tank', 'rdps', 'healer' }) do
	print(string.format('%s: %d valores de la base cambiados por el rol', role, #Run(role)))
end
print(string.format('BASE OK: %d valores', #leaves))
