local M = {}
local function escape(s)
 return tostring(s):gsub('&','&amp;'):gsub('<','&lt;'):gsub('>','&gt;'):gsub('"','&quot;'):gsub("'",'&#39;')
end
local function quote(s)
 return '"'..s:gsub('[%z\1-\31\\"]',function(ch)
  local short = {['"']='\\"',['\\']='\\\\',['\n']='\\n',['\r']='\\r',['\t']='\\t'}
  return short[ch] or string.format('\\u%04x',ch:byte())
 end)..'"'
end
function M.json(v)
 local t=type(v)
 if t=='string' then return quote(v) end
 if t=='number' then assert(v==v and math.abs(v)<math.huge,'Número no finito'); return string.format('%.12g',v) end
 if t=='boolean' then return tostring(v) end
 if t=='nil' then return 'null' end
 assert(t=='table','Tipo JSON inválido: '..t)
 local out={}
 if #v>0 then
  for _,item in ipairs(v) do out[#out+1]=M.json(item) end
  return '['..table.concat(out,',')..']'
 end
 local keys={}; for k in pairs(v) do keys[#keys+1]=k end; table.sort(keys)
 for _,k in ipairs(keys) do out[#out+1]=quote(k)..':'..M.json(v[k]) end
 return '{'..table.concat(out,',')..'}'
end
local function write(path,s)
 local f=assert(io.open(path,'wb'),'No se pudo escribir '..path)
 assert(f:write(s)); assert(f:close())
end
function M.save(path,data,theme)
 local function rgb(c) return string.format('%d,%d,%d',math.floor(c.r*255+.5),math.floor(c.g*255+.5),math.floor(c.b*255+.5)) end
 local out={'<!doctype html><html lang="es-AR"><meta charset="utf-8"><title>KnuUI · distribución offline</title><style>',
 'body{background:#100e0c;color:#eee;font:14px system-ui;margin:24px}h1{font-size:20px}',
 '.viewport{overflow:auto;border:1px solid #555}.canvas{position:relative;width:1920px;height:1080px;background-color:#121212;',
 'background-image:linear-gradient(#ffffff08 1px,transparent 1px),linear-gradient(90deg,#ffffff08 1px,transparent 1px);background-size:40px 40px}',
 '.block{position:absolute;box-sizing:border-box;border:1px solid rgb('..rgb(theme.border)..');background:rgba('..rgb(theme.backdrop)..',.65);color:rgb('..rgb(theme.accent)..');}',
 '.block span{position:absolute;left:2px;top:1px;white-space:nowrap;font:10px monospace;background:#111c;padding:1px 3px;z-index:1}',
 '.block:hover{z-index:100;background:#333e}.block:hover span{font-size:13px}.overlap{outline:2px solid #ff4545}.unknown{border-style:dashed}',
 'li{font:12px monospace;margin:5px 0}.bad{color:#ff7979}</style><h1>KnuUI · distribución offline · 1920×1080</h1>',
 '<p>Perfil: '..escape(data.profile)..' · personaje: '..escape(data.character or 'sin especificar')..' · tema: '..escape(data.theme)..'</p>',
 '<p>Rojo: intersección mayor a 4 unidades². Borde discontinuo: tamaño desconocido. Pasá el cursor para ver el detalle. ',
 'Se muestran estados condicionales juntos; una intersección no demuestra un conflicto durante el juego.</p><div class="viewport"><div class="canvas">'}
 for _,r in ipairs(data.rects) do
  local label=r.name..' '..string.format('%g×%g',r.width,r.height)..(r.unknown and ' (size unknown)' or '')
  local cls='block'..(r.overlap and ' overlap' or '')..(r.unknown and ' unknown' or '')
  local title=label..string.format(' · izquierda=%g abajo=%g',r.left,r.bottom)..' · '..(r.note or '')
  out[#out+1]=string.format('<div class="%s" title="%s" style="left:%.6fpx;top:%.6fpx;width:%.6fpx;height:%.6fpx"><span>%s</span></div>',
   cls,escape(title),r.left,1080-r.bottom-r.height,r.width,r.height,escape(label))
 end
 out[#out+1]='</div></div><h2>Leyenda ('..#data.rects..' bloques)</h2><ul>'
 for _,r in ipairs(data.rects) do
  out[#out+1]='<li'..(r.overlap and ' class="bad"' or '')..'>'..escape(r.name)..string.format(' %g×%g · (%g, %g)',r.width,r.height,r.left,r.bottom)..
   escape(r.note and ' · '..r.note or '')..'</li>'
 end
 out[#out+1]='</ul><h2>Movers omitidos</h2><ul>'
 for _,s in ipairs(data.skipped) do out[#out+1]='<li>'..escape(s)..'</li>' end
 out[#out+1]='</ul><h2>Advertencias y aproximaciones</h2><ul>'
 for _,s in ipairs(data.warnings) do out[#out+1]='<li>'..escape(s)..'</li>' end
 out[#out+1]='</ul><h2>Intersecciones</h2><ul>'
 for _,p in ipairs(data.overlaps) do
  out[#out+1]='<li class="bad">'..escape(p.a)..' / '..escape(p.b)..string.format(' · %g×%g · área %g',p.width,p.height,p.area)..'</li>'
 end
 out[#out+1]='</ul></html>'
 -- Las colecciones vacías se serializan como arrays, no objetos.
 local json=M.json(data)
 for _,key in ipairs({'rects','overlaps','skipped','warnings'}) do json=json:gsub('"'..key..'":{}','"'..key..'":[]') end
 write(path..'.json',json..'\n')
 write(path,table.concat(out,'\n'))
end
return M
