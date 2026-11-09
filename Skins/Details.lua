local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')
local applying
local hooked, configured = {}, {}

-- Fuentes relativas a D:/World of Warcraft/_forever_/Interface/AddOns/.
-- Cada llamada de terceros se verifica y ejecuta dentro de WithAddon/pcall.
local function Call(object, method, ...)
 if object and type(object[method]) == 'function' then return object[method](object, ...) end
end

local function TinyRow(plugin, row)
 if InCombatLockdown() then K.detailsSkinPending = true; return end
 -- Details/core/plugins.lua:80-90; TinyThreat.lua:220-238 hereda la configuración de instancia.
 local instance = Call(plugin, 'GetPluginInstance')
 if not instance or not instance._ElvUIEmbed or not row then return end
 local t = K:GetTheme()
 -- TinyThreat.lua:820-821,963-965 conserva los colores por clase del plugin.
 if type(plugin.saveddata) == 'table' then plugin.saveddata.useclasscolors = true end
 -- Details/Libs/DF/normal_bar.lua:295-312,328-338,809-814: setters y widget reales.
 row.textfont = E.Libs.LSM:Fetch('font', 'Expressway')
 row.textsize, row.shadow = 12, true
 row.textcolor = { t.text.r, t.text.g, t.text.b, 1 }
 row.texture = 'Melli'
 -- El background nativo es un resaltado que DF oculta al salir (:496,513).
 -- Fondo propio permanente; no modifica el color de la barra de amenaza.
 if row.widget then
  if not row.widget.KnuRowBackground then
   row.widget.KnuRowBackground = row.widget:CreateTexture(nil, 'BACKGROUND')
   row.widget.KnuRowBackground:SetAllPoints()
  end
  row.widget.KnuRowBackground:SetColorTexture(t.muted.r, t.muted.g, t.muted.b, 0.12)
 end
end

local function Tiny(instance)
 if not K:IsLoaded('Details_TinyThreat') then return end
 -- Details/core/plugins.lua:44,80; Details_TinyThreat.lua:68,220,242,248.
 local plugin = Call(_G.Details, 'GetPlugin', 'Details_TinyThreat')
 if not plugin or Call(plugin, 'GetPluginInstance') ~= instance then return end
 if not hooked[plugin] and type(plugin.RefreshRow) == 'function' then
  hooksecurefunc(plugin, 'RefreshRow', function(self, row)
   pcall(TinyRow, self, row)
  end)
  hooked[plugin] = true
 end
 -- SizeChanged y RefreshRows se ejecutan desde el dock con DETAILS_INSTANCE_SIZECHANGED.
 for _, row in ipairs(plugin.Rows or {}) do TinyRow(plugin, row) end
end

local function Style(instance)
 if not instance or not instance._ElvUIEmbed or not instance.baseframe then return end
 local t = K:GetTheme()
 local row = instance.row_info -- window_main.lua:3895-3984,4189-4205.
 if configured[instance] ~= t or (row and (row.texture ~= 'Melli' or row.font_face ~= 'Expressway'
  or row.height ~= 16 or row.space.between ~= 1 or (row.texture_custom and row.texture_custom ~= ''))) then
  -- class_instance.lua:2677; window_main.lua:7855 (sin borde en los dos backdrops).
  Call(instance, 'SetBackdropTexture')
  Call(instance, 'SetBackgroundAlpha', 0)
  -- window_main.lua:7426,7454,4427: bordes y wallpaper mediante setters propios.
  Call(instance, 'UpdateFullBorder', false)
  Call(instance, 'UpdateRowAreaBorder', false)
  Call(instance, 'InstanceWallpaper', false)
  -- window_main.lua:3895-3984: alto, textura, clase, fondo, alfa y separación.
  Call(instance, 'SetBarSettings', 16, 'Melli', true, nil, 'Melli', false,
   { t.muted.r, t.muted.g, t.muted.b, 0.12 }, 1, nil, nil, 1, '')
  -- window_main.lua:3615-3668: fuente, color fijo, clase de textos y contornos.
  Call(instance, 'SetBarTextSettings', 12, 'Expressway', { t.text.r, t.text.g, t.text.b, 1 }, false, false, true, true)
  -- window_main.lua:3740,7708: título visible, tamaño/fondo y texto nativo.
  Call(instance, 'SetTitleBarSettings', true, 20, 'Melli', { t.backdrop.r, t.backdrop.g, t.backdrop.b, 1 })
  Call(instance, 'AttributeMenu', true, nil, nil, 'Expressway', 12, { t.text.r, t.text.g, t.text.b, 1 }, 1, true)
  configured[instance] = t
 end
 -- Ventanas angostas (lado a lado, hasta 198 px): en Forever Details usa columnas fijas cada
 -- alignment_space px (Libs/DF/fw.lua:260-265; functions/rowtexts.lua:401-405; 60 por defecto,
 -- profiles.lua:835) y no puede recortar el nombre porque el ancho del texto es secreto
 -- (rowtexts.lua GetValueColumnsExtent). Se usa el texto simple de Details: "total (por segundo)"
 -- en un solo texto pegado al borde, sin porcentaje. Se escribe sólo si hace falta.
 local simple = _G.Details and _G.Details.righttext_simple_formatting
 if type(simple) == 'table' and (simple.enabled ~= true or simple.use_alignment ~= false) then
  simple.enabled, simple.use_alignment = true, false
  -- functions/util.lua:86-101: el modo simple sólo escribe lineText4; las columnas 2 y 3 del
  -- modo alineado quedarían con el número viejo, así que se vacían una vez acá.
  for _, bar in ipairs(instance.barras or {}) do
   for _, key in ipairs({ 'lineText2', 'lineText3', 'lineText12', 'lineText13' }) do Call(bar[key], 'SetText', '') end
  end
  Call(instance, 'InstanceRefreshRows')
 end
 if row and type(row.textR_show_data) == 'table' and row.textR_show_data[3] ~= false then
  Call(instance, 'SetBarRightTextSettings', true, true, false)
 end
 -- window_main.lua:4740-4790,6719-6737: texturas antiguas del marco, sin tocar botones.
 local base = instance.baseframe
 for _, field in ipairs({ 'ball', 'ball_r', 'emenda', 'top_bg' }) do Call(base.cabecalho and base.cabecalho[field], 'SetAlpha', 0) end
 for _, field in ipairs({ 'barra_esquerda', 'barra_direita', 'barra_fundo' }) do Call(base[field], 'SetAlpha', 0) end
 Call(instance, 'StatusBarColor', t.backdrop.r, t.backdrop.g, t.backdrop.b, 0, true) -- :8557.
 Call(instance, 'RefreshTitleBar') -- :3763; mantiene la configuración al refrescar.
 -- is_interacting: window_main.lua:7878. La ventana bajo el cursor lleva el acento.
 local color = instance.is_interacting and t.accent or t.text
 local title = Call(instance, 'GetTitleBarFontString') -- :7699; devuelve el label de DF.
 if title then
  -- functions/util.lua:1732; :7829-7848 usa este setter sobre el label del título.
  Call(_G.Details, 'SetFontColor', title, { color.r, color.g, color.b, 1 })
 end
 Tiny(instance)
 if not hooked[instance] then
  hooked[instance] = true
  -- Hooks sobre cada instancia: sus métodos pueden ser copias del prototipo Details.
  -- :4180,6616,3763,7631,7878; no se llama al dock desde un refresco de filas.
  for _, method in ipairs({ 'InstanceRefreshRows', 'ChangeSkin', 'RefreshTitleBar', 'RefreshTitleBarText', 'SetAutoHideMenu',
   'SetBarSettings', 'SetBarTextSettings', 'SetTitleBarSettings', 'SetBackgroundAlpha',
   'SetBackdropTexture', 'UpdateFullBorder', 'UpdateRowAreaBorder', 'InstanceWallpaper' }) do
   if type(instance[method]) == 'function' then
    hooksecurefunc(instance, method, function()
     if applying then return end
     if method ~= 'InstanceRefreshRows' and method ~= 'RefreshTitleBar'
      and method ~= 'RefreshTitleBarText' and method ~= 'SetAutoHideMenu' then configured[instance] = nil end
     K:SkinDetails(instance)
    end)
   end
  end
 end
end

function K:SkinDetails(instance)
 if InCombatLockdown() then self.detailsSkinPending = true; return false end
 if not E.Forever or applying or self:IsLoaded('ForeverDock') then return false end
 applying = true
 local ok = self:WithAddon('Details', function() Style(instance) end)
 applying = false
 return ok
end
