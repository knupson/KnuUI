local M = {}
local points = {
 BOTTOMLEFT={0,0}, BOTTOM={.5,0}, BOTTOMRIGHT={1,0}, LEFT={0,.5},
 CENTER={.5,.5}, RIGHT={1,.5}, TOPLEFT={0,1}, TOP={.5,1}, TOPRIGHT={1,1},
}
M.points = points
function M.canvas(res, scale)
 local w, h = (res or '1920x1080'):match('^(%d+)[xX](%d+)$')
 w, h = tonumber(w), tonumber(h)
 assert(w and h and w > 0 and h > 0, 'Resolución inválida: '..tostring(res))
 -- PixelPerfect.lua:92-100; Install.lua:1386 (escala automática).
 local automatic = scale == nil
 scale = automatic and math.max(0.4, math.min(1.15, 768/h)) or tonumber(scale)
 assert(scale and scale > 0 and scale < math.huge, 'UIScale inválida')
 -- PixelPerfect.lua:59-81: UIParent escalado; E.UIParent usa GetScreenHeight.
 local height = 768/scale
 return {left=0,bottom=0,width=height*w/h,height=height,scale=scale,
  physicalWidth=w,physicalHeight=h,automatic=automatic,mult=(768/h)/scale}
end
function M.parse(s)
 if type(s) ~= 'string' then return nil, 'posición ausente' end
 -- General/Movers.lua:42-45 también acepta el separador antiguo ASCII 31.
 s = s:gsub('\031', ',')
 local p, ref, rp, x, y = s:match('^%s*([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)%s*$')
 if not points[p] or not points[rp] or not tonumber(x) or not tonumber(y) then
  return nil, 'posición inválida: '..s
 end
 return {p, ref, rp, tonumber(x), tonumber(y)}
end
function M.resolve(nodes, aliases, canvas)
 local done = {UIParent=canvas or M.canvas()}
 done.ElvUIParent = done.UIParent
 local visiting = {}
 local function get(name)
  name = aliases[name] or name
  if done[name] then return done[name] end
  if visiting[name] then return nil, 'ciclo en '..name end
  local n = nodes[name]
  if not n then return nil, 'referencia sin geometría: '..name end
  local a, err = M.parse(n.position)
  if not a then return nil, err end
  visiting[name] = true
  local ref; ref, err = get(a[2])
  visiting[name] = nil
  if not ref then return nil, err end
  local p, rp = points[a[1]], points[a[3]]
  local r = {left=ref.left+ref.width*rp[1]+a[4]-n.width*p[1],
   bottom=ref.bottom+ref.height*rp[2]+a[5]-n.height*p[2], width=n.width, height=n.height}
  done[name] = r
  return r
 end
 return get
end
-- Misma geometría para el CLI y las pruebas con tablas en memoria.
function M.rectangles(nodes, aliases, canvas)
 local get = M.resolve(nodes, aliases, canvas)
 local rects, skipped, keys = {}, {}, {}
 for name in pairs(nodes) do keys[#keys+1] = name end
 table.sort(keys)
 for _, name in ipairs(keys) do
  local n = nodes[name]
  if n.enabled then
   local r, err = get(name)
   if not r then skipped[#skipped+1] = name..': '..err
   else
    local rect = {}
    for k, v in pairs(r) do rect[k] = v end
    rect.name, rect.position, rect.note = name, n.position, n.note
    rect.approximate, rect.unknown = n.approximate or false, n.unknown or false
    if n.drawWidth then
     local a = M.points[n.drawAnchor]
     rect.moverWidth, rect.moverHeight = r.width, r.height
     rect.left = r.left+(r.width-n.drawWidth)*a[1]
     rect.bottom = r.bottom+(r.height-n.drawHeight)*a[2]
     rect.width, rect.height = n.drawWidth, n.drawHeight
    end
    rects[#rects+1] = rect
   end
  end
 end
 return rects, skipped
end
-- Grupo, bandas, arena y jefes nunca se ven a la vez: no cuentan como solape entre ellos.
local function Exclusive(name)
 return name:match('^ElvUF_Party') or name:match('^ElvUF_Raid') or name:match('^ArenaHeader') or name:match('^BossHeader')
end
-- Sólo solapes reales: los marcadores de tamaño desconocido (20x20) generaban ruido.
function M.intersections(rects)
 local result = {}
 for i, a in ipairs(rects) do
  for j=i+1,#rects do
   local b = rects[j]
   local skip = a.unknown or b.unknown or (Exclusive(a.name) and Exclusive(b.name))
   local w = math.min(a.left+a.width,b.left+b.width)-math.max(a.left,b.left)
   local h = math.min(a.bottom+a.height,b.bottom+b.height)-math.max(a.bottom,b.bottom)
   if not skip and w > 0 and h > 0 and w*h > 4 then
    a.overlap, b.overlap = true, true
    result[#result+1] = {a=a.name,b=b.name,width=w,height=h,area=w*h,
     uncertain=a.unknown or b.unknown or a.approximate or b.approximate or false}
   end
  end
 end
 return result
end
-- Un registro por borde; ancho y alto indican la franja que sobresale.
function M.outside(rects, canvas)
 canvas = canvas or M.canvas()
 local result = {}
 for _, r in ipairs(rects) do
   local edges = {
    {'izquierda', -r.left, r.height},
    {'derecha', r.left+r.width-canvas.width, r.height},
    {'abajo', r.width, -r.bottom},
    {'arriba', r.width, r.bottom+r.height-canvas.height},
   }
   for i, edge in ipairs(edges) do
    if (i <= 2 and edge[2] or edge[3]) > 1 then
     r.outside = true
     result[#result+1] = {a=r.name,b='pantalla:'..edge[1],width=edge[2],height=edge[3],
      uncertain=r.unknown or r.approximate or false}
    end
   end
 end
 return result
end
return M
