-- Carga aislada: las SavedVariables no reciben globals ni APIs del anfitrión.
local M = {}
function M.read(path)
 local f = assert(io.open(path, 'rb'), 'No se pudo leer '..path)
 local s = f:read('*a'); f:close(); return s
end
function M.merge(dst, src)
 for k, v in pairs(src or {}) do
  if type(v) == 'table' then
   if type(dst[k]) ~= 'table' then dst[k] = {} end
   M.merge(dst[k], v)
  else dst[k] = v end
 end
 return dst
end
function M.run(path, env, ...)
 local chunk, err = loadfile(path); assert(chunk, err)
 setfenv(chunk, env); chunk(...)
 return env
end
function M.load(root, path, char, profile)
 local sv = M.run(path, {})
 local db = assert(sv.ElvDB, 'Falta ElvDB')
 if not profile then
  if not char then
   local keys = {}; for k in pairs(db.profileKeys or {}) do keys[#keys+1] = k end
   table.sort(keys)
   assert(#keys == 1, 'Indicá --char o --profile; personajes: '..table.concat(keys, ', '))
   char = keys[1]
  end
  profile = assert((db.profileKeys or {})[char], 'Personaje sin perfil: '..char)
 end
 local saved = assert((db.profiles or {})[profile], 'Perfil inexistente: '..profile)
 local E, P, G, V, K = { Forever = true, Modern = true, myclass = 'PALADIN', filterMax = 8 }, {}, {}, {}, {}
 function E:CopyTable(dst, src) return M.merge(dst or {}, src) end
 function E:GetName() return 'ElvUI' end
 function E:GetLocale() return 'esES' end
 function E:GetModule() return K end
 local env = setmetatable({ ElvUI = { E, {}, V, P, G },
  DEFAULT_CHAT_FRAME = { GetName = function() return 'ChatFrame1' end },
  GetCurrentRegion = function() return 1 end }, { __index = _G })
 env._G = env
 for _, file in ipairs({'Profile', 'Global', 'Private'}) do
  M.run(root..'/_ref/ElvUI/Game/Shared/Defaults/'..file..'.lua', env)
 end
 E.db, E.global = M.merge(P, saved), M.merge(G, db.global)
 local private = sv.ElvPrivateDB or {}
 local privateKey = char and (private.profileKeys or {})[char]
 E.private = M.merge(V, privateKey and (private.profiles or {})[privateKey] or {})
 -- Theme.lua sólo define tablas y funciones; no ejecutamos sus métodos de juego.
 local L = setmetatable({}, {__index = function(_, k) return k end})
 M.run(root..'/addons/KnuUI/Theme.lua', env, 'KnuUI', {L = L})
 local theme = K.themes[E.db.KnuUITheme or 'knunet'] or K.themes.knunet
 local warnings = {}
 if E.db.KnuUITheme == 'class' then
  warnings[#warnings+1] = 'Tema class: acento de respaldo; SavedVariables no identifica la clase.'
 end
 if not privateKey then warnings[#warnings+1] = 'Sin perfil privado del personaje: se usan defaults V.' end
 return {db = E.db, global = E.global, private = E.private, profile = profile,
  character = char, theme = theme, warnings = warnings}
end
return M
