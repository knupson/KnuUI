-- LuaJIT 2.1 / Lua 5.1. No requiere WoW ni bibliotecas externas.
local script=(arg[0] or ''):gsub('\\','/')
local dir=script:match('^(.*)/[^/]+$') or '.'
local root=dir:match('^(.*)/addons/KnuUI/tools/render$') or '.'
local loader=dofile(dir..'/loader.lua')
local geometry=dofile(dir..'/geometry.lua')
local models=dofile(dir..'/models.lua')
local output=dofile(dir..'/output.lua')
local function main()
 local options={}
 local i=1
 while i<=#arg do
  local k=arg[i]
  if k=='--help' then
   print('Uso: luajit addons/KnuUI/tools/render/render.lua --sv <ElvUI.lua> [--char "Nombre Reino"] [--profile <perfil>] --out <archivo.html>')
   return
  end
  assert(k=='--sv' or k=='--char' or k=='--profile' or k=='--out','Opción desconocida: '..tostring(k))
  assert(arg[i+1] and not arg[i+1]:match('^%-%-'),'Falta valor para '..k)
  assert(not options[k],'Opción repetida: '..k)
  options[k]=arg[i+1]; i=i+2
 end
 assert(options['--sv'] and options['--out'],'Se requieren --sv y --out (ver --help)')
 local c=loader.load(root,options['--sv'],options['--char'],options['--profile'])
 local nodes,aliases=models.build(c,root,loader)
 local rects,skipped=geometry.rectangles(nodes,aliases)
 local overlaps=geometry.intersections(rects)
 c.warnings[#c.warnings+1]='Escenario combinado: no evalúa combate, roster, visibility, mouseover ni estados transitorios.'
 c.warnings[#c.warnings+1]='Party/raid: header completo; auras: capacidad máxima. Marcadores desconocidos de 20×20.'
 c.warnings[#c.warnings+1]='Escala solicitada 1 unidad = 1 px; no simula redondeo E:Scale ni escalado adicional de plugins.'
 local data={width=1920,height=1080,profile=c.profile,character=c.character,theme=c.db.KnuUITheme or 'knunet',
  rects=rects,skipped=skipped,overlaps=overlaps,warnings=c.warnings}
 output.save(options['--out'],data,c.theme)
 print('Bloques: '..#rects)
 print('Omitidos: '..#skipped)
 for _,s in ipairs(skipped) do print(s) end
 print('Solapamientos: '..#overlaps)
 for _,p in ipairs(overlaps) do print(string.format('%s/%s:%gx%g',p.a,p.b,p.width,p.height)) end
end
local ok,err=pcall(main)
if not ok then io.stderr:write('Error: '..tostring(err)..'\n'); os.exit(1) end
