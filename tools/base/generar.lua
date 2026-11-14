-- Genera addons/KnuUI/Base.lua: la configuración del autor como base de KnuUI (pedido del user 2026-11-13:
-- "tomá mi configuración como la base global; después salen las modificaciones por clase o rol").
-- Desde la raíz del repo, con LuaJIT o Lua 5.1:
--   luajit addons/KnuUI/tools/base/generar.lua '<WoW>/_forever_/WTF/Account/<cuenta>/SavedVariables/ElvUI.lua' '<Personaje>'
-- Toma sólo lo que difiere de lo que arma "Aplicar todo" en el mismo modo (melé, columnas, bloque derecho
-- compacto): así quedan las elecciones del autor y no se duplica lo que KnuUI ya calcula por modo o por rol.
-- Descarta el estado propio de esta PC y los restos de otras interfaces (Darth, ForeverUI, S&L).
local svPath, char = assert(arg[1], 'falta el archivo SavedVariables'), assert(arg[2], 'falta el personaje')
local out = arg[3] or 'addons/KnuUI/Base.lua'

-- Perfil que arma KnuUI, sobre los valores por defecto de ElvUI (P), con el arnés de los tests.
local harness = assert(loadfile('addons/KnuUI/tests/verificar.lua'))('render-harness')
local E, K = harness.E, harness.K
K.Base = nil -- sin la base anterior: se compara contra lo que arma KnuUI solo
harness.fresh()
E.global.general.UIScale = nil
E.db.KnuUICompactLeft, E.db.KnuUICompactRight = false, true
assert(K:ApplyRole('mdps') and K:ApplyTanks(true))
K:ApplyAll()
local generated, defaults = E.db, ElvUI[4]

-- Perfil guardado del autor (sólo lectura, en un entorno vacío).
local env = {}
local chunk = assert(loadfile(svPath))
setfenv(chunk, env)
chunk()
local key = assert(env.ElvDB.profileKeys[char], 'personaje sin perfil: ' .. char)
local mine = assert(env.ElvDB.profiles[key])

-- Lo que no es elección de diseño: estado de esta PC, migraciones de una vez y modos que elige cada uno.
local SKIP_TOP = {
	KnuUIDock = true, KnuUICC = true, KnuUITanksGap = true, KnuUITanksWidth = true, KnuUILayoutVersion = true,
	KnuUIBigMinimap = true, KnuUIRole = true, KnuUITanks = true, KnuUICompactLeft = true, KnuUICompactRight = true,
	KnuUIPinned = true, KnuUITomTomColors = true, dbConverted = true, convertPages = true,
}
local function Skip(path)
	local top = path[1]
	if SKIP_TOP[top] or (type(top) == 'string' and top:match('^KnuUI.*Placed%d*$')) then return true end
	local joined = table.concat(path, '.', 1, math.min(#path, 3))
	-- Posiciones ancladas a marcos de Blizzard (MirrorTimer1, RaidBossEmoteFrame...): ElvUI las arma solo.
	if top == 'movers' and #path == 2 then
		local rel = mine.movers and mine.movers[path[2]]
		rel = type(rel) == 'string' and rel:match('^[^,]+,([^,]+),')
		if rel and rel ~= 'ElvUIParent' and rel ~= 'UIParent' then return true end
	end
	-- Restos de otras interfaces y marcos que Forever no tiene.
	for _, pat in ipairs({ 'SLE', 'Darth', 'ForeverUI', 'VOICECHAT', 'PetBattle', 'Torghast', 'Azerite', 'Honor',
		'^movers%.ElvAB_[7-9]$', '^movers%.ElvAB_1[0-5]$', '^datatexts%.panels%.LeftChatDataPanel', '^datatexts%.panels%.RightChatDataPanel' }) do
		if joined:find(pat) then return true end
	end
	return false
end

local function Get(t, path)
	for _, k in ipairs(path) do
		if type(t) ~= 'table' then return nil end
		t = t[k]
	end
	return t
end
local function Same(a, b)
	if type(a) == 'number' and type(b) == 'number' then return math.abs(a - b) < 1e-4 end
	return a == b
end

-- Valor efectivo del autor: lo guardado o, si no está guardado, el de ElvUI por defecto.
local base, count = {}, 0
local function Put(path, value)
	local t = base
	for i = 1, #path - 1 do
		t[path[i]] = t[path[i]] or {}
		t = t[path[i]]
	end
	t[path[#path]] = value
	count = count + 1
end
local function Walk(t, path)
	for k, v in pairs(t) do
		local p = { unpack(path) }
		p[#p + 1] = k
		if not Skip(p) then
			if type(v) == 'table' then Walk(v, p)
			else
				local mineValue = Get(mine, p)
				if mineValue == nil then mineValue = Get(defaults, p) end
				if mineValue ~= nil and not Same(mineValue, v) then Put(p, mineValue) end
			end
		end
	end
end
Walk(generated, {})
-- Lo que el autor guardó y KnuUI no arma (claves que no existen en el perfil generado).
local function WalkMine(t, path)
	for k, v in pairs(t) do
		local p = { unpack(path) }
		p[#p + 1] = k
		if not Skip(p) then
			if type(v) == 'table' then WalkMine(v, p)
			elseif Get(generated, p) == nil and (p[1] == 'movers' or Get(defaults, p) ~= nil) then
				-- Sólo claves que ElvUI conoce (las viejas, como unitframe.maxAllowedGroups, no hacen nada).
				Put(p, v)
			end
		end
	end
end
WalkMine(mine, {})

local function Ser(v, ind)
	if type(v) == 'string' then return string.format('%q', v) end
	if type(v) == 'number' then
		if v == math.floor(v) then return string.format('%d', v) end
		return string.format('%.6g', v)
	end
	if type(v) ~= 'table' then return tostring(v) end
	local keys = {}
	for k in pairs(v) do keys[#keys + 1] = k end
	table.sort(keys, function(a, b)
		if type(a) == type(b) then return a < b end
		return type(a) == 'number'
	end)
	local parts = {}
	for _, k in ipairs(keys) do
		local kk = type(k) == 'number' and ('[' .. k .. ']') or (k:match('^[%a_][%w_]*$') and k or '[' .. string.format('%q', k) .. ']')
		parts[#parts + 1] = ind .. '\t' .. kk .. ' = ' .. Ser(v[k], ind .. '\t') .. ','
	end
	return '{\n' .. table.concat(parts, '\n') .. '\n' .. ind .. '}'
end
local f = assert(io.open(out, 'w'))
f:write('-- Generado por tools/base/generar.lua: no editar a mano. Configuración del autor que difiere de lo que\n')
f:write('-- arma "Aplicar todo" (melé, columnas, bloque derecho compacto). K:ApplyBase la pone sobre el diseño,\n')
f:write('-- antes de las modificaciones por rol (Roles.lua) y por modo (Tanks.lua).\n')
f:write('local E = unpack(ElvUI)\nlocal K = E:GetModule(\'KnuUI\')\n\n')
f:write('K.Base = ' .. Ser(base, '') .. '\n')
f:close()
print(string.format('Base: %d valores escritos en %s', count, out))
