-- Desde la raíz del repo; Lua 5.1, sin SavedVariables.
local ALLOWED = {
 -- ['BloqueA/BloqueB'] = 'Motivo en castellano; nombres en orden alfabético.',
}

local harness = assert(loadfile('addons/KnuUI/tests/verificar.lua'))('render-harness')
local E, K = harness.E, harness.K
local dir = 'addons/KnuUI/tools/render/'
local loader = dofile(dir..'loader.lua')
local models = dofile(dir..'models.lua')
local geometry = dofile(dir..'geometry.lua')
local sides = {
 {name = 'ninguno', left = false, right = false},
 {name = 'izquierdo', left = true, right = false},
 {name = 'derecho', left = false, right = true},
 {name = 'ambos', left = true, right = true},
}
local function pairKey(a, b)
 if b < a then a, b = b, a end
 return a..'/'..b
end
for key, reason in pairs(ALLOWED) do
 local a, b = key:match('^([^/]+)/([^/]+)$')
 assert(a and a < b and type(reason) == 'string' and reason:match('%S') and not reason:find('[\r\n]'),
  'Excepción inválida: '..key)
end

local cases, failures, omitted, accepted = 0, 0, 0, 0
print('Rol | Columnas | Compactos | Solapes | Pares (ancho x alto)')
for _, role in ipairs({'tank', 'mdps', 'rdps', 'healer'}) do
 for _, tanks in ipairs({false, true}) do
  for index = 1, tanks and #sides or 1 do
   local side = sides[index]
   harness.fresh()
   E.db.KnuUICompactLeft, E.db.KnuUICompactRight = side.left, side.right
   assert(K:ApplyRole(role), 'No se pudo aplicar el rol '..role)
   assert(K:ApplyTanks(tanks), 'No se pudo aplicar columnas')
   K:ApplyAll()
   assert(E.db.KnuUILayoutVersion == K.version, 'Aplicar todo no terminó')
   local c = {db = E.db, global = E.global, private = E.private}
   local nodes, aliases = models.build(c, '.', loader)
   local rects, skipped = geometry.rectangles(nodes, aliases)
   local pairs, count = {}, 0
   for _, overlap in ipairs(geometry.intersections(rects)) do
    local key = pairKey(overlap.a, overlap.b)
    local reason = ALLOWED[key]
    if reason then accepted = accepted+1 else count = count+1 end
    pairs[#pairs+1] = string.format('%s (%gx%g)%s', key, overlap.width, overlap.height,
     reason and ' [permitido: '..reason..']' or '')
   end
   table.sort(pairs)
   print(string.format('%s | %s | %s | %d | %s', role, tanks and 'sí' or 'no',
    side.name, count, #pairs > 0 and table.concat(pairs, '; ') or '-'))
   -- Una referencia sin resolver tampoco puede dar un falso éxito.
   for _, message in ipairs(skipped) do print('  Sin resolver: '..message) end
   cases, failures, omitted = cases+1, failures+count, omitted+#skipped
  end
 end
end
assert(cases == 20, 'Matriz incompleta')
print(string.format('Combinaciones: %d; solapes no permitidos: %d; permitidos: %d; sin resolver: %d.',
 cases, failures, accepted, omitted))
assert(failures == 0 and omitted == 0, 'El diseño tiene solapes o bloques sin resolver')
