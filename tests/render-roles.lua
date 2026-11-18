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
local function equal(a, b)
 if type(a) ~= type(b) then return false end
 if type(a) ~= 'table' then return a == b end
 for key, value in pairs(a) do if not equal(value,b[key]) then return false end end
 for key in pairs(b) do if a[key] == nil then return false end end
 return true
end
for key, reason in pairs(ALLOWED) do
 local a, b = key:match('^([^/]+)/([^/]+)$')
 assert(a and a < b and type(reason) == 'string' and reason:match('%S') and not reason:find('[\r\n]'),
  'Excepción inválida: '..key)
end

-- 16:9, ultrawide, 16:10 y 5:4.
local resolutions = {'1280x720', '1366x768', '1600x900', '1920x1080',
 '2560x1080', '2560x1440', '3440x1440', '3840x2160',
 '1280x800', '1440x900', '1680x1050', '1920x1200', '2560x1600', '1280x1024'}
-- Escala que deja KnuUI al aplicar el diseño en esa pantalla (Layout.lua K:LayoutScale); nil = automática.
local function ScaleFor(res)
 local w, h = res:match('^(%d+)x(%d+)$')
 return K:LayoutScale(tonumber(w), tonumber(h))
end
local summaries = {}
for _, res in ipairs(resolutions) do
 summaries[res] = {canvas=geometry.canvas(res),bad=0,problems={}}
end
local cases, layouts, failures, omitted, accepted = 0, 0, 0, 0, 0
for _, role in ipairs({'tank', 'mdps', 'rdps', 'healer'}) do
 for _, tanks in ipairs({false, true}) do
  for index = 1, tanks and #sides or 1 do
   local side = sides[index]
   harness.fresh()
   -- Sin SavedVariables: el default distribuido no es una escala elegida.
   E.global.general.UIScale = nil
   E.db.KnuUICompactLeft, E.db.KnuUICompactRight = side.left, side.right
   assert(K:ApplyRole(role), 'No se pudo aplicar el rol '..role)
   assert(K:ApplyTanks(tanks), 'No se pudo aplicar columnas')
   K:ApplyAll()
   assert(E.db.KnuUILayoutVersion == K.version, 'Aplicar todo no terminó')
   local c = {db = E.db, global = E.global, private = E.private}
   local nodes, aliases = models.build(c, '.', loader)
   layouts = layouts+1
   -- El perfil y los modelos se arman una vez; sólo cambian las anclas de pantalla.
   for _, res in ipairs(resolutions) do
    local summary = summaries[res]
    summary.canvas = geometry.canvas(res, ScaleFor(res))
    local rects, skipped = geometry.rectangles(nodes, aliases, summary.canvas)
    local problems = geometry.intersections(rects)
    -- Separación pareja en modo columnas (pedido del user 2026-11-13: "todo tiene que tener la misma
    -- distancia"): en la fila de abajo, 4 entre bloques vecinos y 4 a los bordes de la pantalla; la barra
    -- de datos, a 4 de cada chat.
    if tanks and res == '1920x1080' then
     local spans, data, chats = {}, nil, {}
     for _, r in ipairs(rects) do
      if r.name == 'DTPanelKnuUI_DataMover' then data = r
      elseif not r.unknown and r.bottom < 40 and r.height > 30 and not r.name:match('^ElvUF_Party') and not r.name:match('^ElvUF_Raid') then
       spans[#spans+1] = {r.left, r.left + r.width, r.name}
       if r.name:match('ChatMover$') then chats[r.name] = r end
      end
     end
     table.sort(spans, function(a, b) return a[1] < b[1] end)
     -- Barras apiladas (3 sobre 5, 1 sobre 2) ocupan la misma franja: se juntan.
     local merged = {}
     for _, s in ipairs(spans) do
      local last = merged[#merged]
      if last and s[1] < last[2] - 0.01 then last[2] = math.max(last[2], s[2]); last[3] = last[3]..'+'..s[3]
      else merged[#merged+1] = {s[1], s[2], s[3]} end
     end
     local function gapProblem(label, value)
      if math.abs(value - 4) > 0.01 then problems[#problems+1] = {a=label, b=string.format('separación %g', value), width=value, height=0} end
     end
     if os.getenv('KNU_DEBUG') then for _, m in ipairs(merged) do print(string.format('  %s %g-%g', m[3], m[1], m[2])) end end
     gapProblem('borde izquierdo', merged[1][1])
     gapProblem('borde derecho', summary.canvas.width - merged[#merged][2])
     for i = 2, #merged do gapProblem(merged[i-1][3]..'|'..merged[i][3], merged[i][1] - merged[i-1][2]) end
     if data and chats.LeftChatMover and chats.RightChatMover then
      gapProblem('LeftChat|Datos', data.left - (chats.LeftChatMover.left + chats.LeftChatMover.width))
      gapProblem('Datos|RightChat', chats.RightChatMover.left - (data.left + data.width))
     end
    end
    for _, outside in ipairs(geometry.outside(rects, summary.canvas)) do
     problems[#problems+1] = outside
    end
    local count = 0
    for _, problem in ipairs(problems) do
     local key = pairKey(problem.a, problem.b)
     local reason = ALLOWED[key]
     if reason then accepted=accepted+1 else count=count+1 end
     local label = string.format('%s (%gx%g)%s', key, problem.width, problem.height,
      reason and ' [permitido: '..reason..']' or '')
     summary.problems[label] = (summary.problems[label] or 0)+1
    end
    for _, message in ipairs(skipped) do
     print(res..' / '..role..' / '..side.name..': sin resolver: '..message)
    end
    if count > 0 or #skipped > 0 then summary.bad=summary.bad+1 end
    cases, failures, omitted = cases+1, failures+count, omitted+#skipped
   end
  end
 end
end
assert(layouts == 20 and cases == 20 * #resolutions, 'Matriz base incompleta')
-- Los doce estilos parten de defaults, sin importar el perfil del usuario.
-- Se comprueban también los marcadores desconocidos contra la columna reservada.
for _, profile in ipairs(K:StyleProfiles()) do
 harness.fresh()
 E.global.general.UIScale = nil
 E.private.KnuUIRole = 'rol del personaje'
 E.db.KnuUIStyle, E.db.KnuUIRole = profile.id, profile.role
 E.db.KnuUIStylePending, E.db.KnuUITanks = true, false
 local applyStyle = K.ApplyStyle
 K.ApplyStyle = function(self, id)
  local grid = {}
  if profile.role == 'healer' then
   for _, unit in ipairs({'party','raid1','raid2','raid3'}) do grid[unit]=E:CopyTable({},E.db.unitframe.units[unit]) end
  end
  local result = applyStyle(self,id)
  for unit, before in pairs(grid) do assert(equal(before,E.db.unitframe.units[unit]), 'El estilo modificó la grilla: '..unit) end
  return result
 end
 assert(K:ApplyPendingStyle(), profile.name)
 K.ApplyStyle = applyStyle
 assert(E.private.KnuUIRole == 'rol del personaje' and E.db.KnuUITanks == false)
 if profile.role == 'healer' then
  for _, name in ipairs({'Party','Raid1','Raid2','Raid3'}) do
   assert(E.db.movers['ElvUF_'..name..'Mover']=='BOTTOM,ElvUIParent,BOTTOM,0,204', 'Grilla del Healer movida')
  end
  assert(E.db.unitframe.units.party.width==82 and E.db.unitframe.units.party.height==46)
 elseif profile.role == 'tank' then
  assert(E.db.unitframe.units.player.threatStyle=='BORDERS' and E.db.nameplates.threat.indicator)
 elseif profile.role == 'rdps' then
  assert(E.db.unitframe.units.player.castbar.width==340 and E.db.unitframe.units.player.castbar.height==32)
  assert(E.db.unitframe.units.target.debuffs.sizeOverride==32)
 end
 local nodes, aliases = models.build({db=E.db,global=E.global,private=E.private}, '.', loader)
 layouts = layouts+1
 for _, res in ipairs(resolutions) do
  local summary = summaries[res]
  local canvas = geometry.canvas(res, ScaleFor(res))
  local rects, skipped = geometry.rectangles(nodes, aliases, canvas)
  local problems = geometry.intersections(rects)
  for _, outside in ipairs(geometry.outside(rects, canvas)) do problems[#problems+1] = outside end
  for _, r in ipairs(rects) do
   local top = canvas.height-r.bottom-r.height
   local w = math.min(r.left+r.width,308)-math.max(r.left,8)
   local h = math.min(top+r.height,600)-math.max(top,0)
   if w > 0 and h > 0 then
    problems[#problems+1] = {a=r.name,b='columna WoWPro',width=w,height=h}
   end
  end
  for _, p in ipairs(problems) do
   local label = string.format('%s / %s / %s (%gx%g)',profile.name,p.a,p.b,p.width,p.height)
   summary.problems[label] = (summary.problems[label] or 0)+1
  end
  for _, message in ipairs(skipped) do print(res..' / '..profile.name..': sin resolver: '..message) end
  if #problems > 0 or #skipped > 0 then summary.bad=summary.bad+1 end
  cases, failures, omitted = cases+1, failures+#problems, omitted+#skipped
 end
end
assert(layouts == 32 and cases == 32 * #resolutions, 'Matriz de estilos incompleta')
print('Resolución | Escala | Lienzo (unidades) | Combinaciones con problemas / 32')
for _, res in ipairs(resolutions) do
 local summary = summaries[res]
 local c = summary.canvas
 print(string.format('%s | %.9g | %gx%g | %d', res,c.scale,c.width,c.height,summary.bad))
 local labels = {}; for label in pairs(summary.problems) do labels[#labels+1]=label end
 table.sort(labels)
 for _, label in ipairs(labels) do print('  '..label..' ['..summary.problems[label]..' casos]') end
end
print(string.format('Combinaciones: %d; problemas no permitidos: %d; permitidos: %d; sin resolver: %d.',
 cases, failures, accepted, omitted))
assert(failures == 0 and omitted == 0, 'El diseño tiene solapes, bloques fuera de pantalla o sin resolver')
