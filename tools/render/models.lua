-- Referencias ElvUI relativas a _ref/ElvUI/Game/Shared/.
local M = {}
function M.build(c, root, loader)
 local db, private = c.db, c.private
 local nodes, aliases, handled = {}, {}, {}
 local pixel = private.general.pixelPerfect
 local border, spacing = pixel and 1 or 2, pixel and 0 or 1
 -- General/Initialize.lua:726-728. E:Scale se toma identidad por el lienzo pedido.
 local function add(name, w, h, position, enabled, note, approximate)
  handled[name] = true
  nodes[name] = {name=name,width=w,height=h,position=(db.movers or {})[name] or position,
   enabled=enabled ~= false,note=note,approximate=approximate or false}
  return nodes[name]
 end
 -- Layout.lua:40-72: leer el literal evita ejecutar la instalación del addon.
 local layout = loader.read(root..'/addons/KnuUI/Layout.lua')
 local literal = assert(layout:match('local movers = (%b{})'), 'Falta tabla movers de KnuUI')
 local fn = assert(loadstring('return '..literal)); setfenv(fn, {})
 local defaults = fn()
 local function pos(name, fallback) return defaults[name] or fallback end
 local abSource = loader.read(root..'/_ref/ElvUI/Game/Shared/Modules/ActionBars/ActionBars.lua')
 local barPositions = {}
 for id, position in abSource:gmatch("bar(%d+) = {[^\n]-position = '([^']+)'") do
  barPositions[tonumber(id)] = position
 end
 for i=1,15 do
  local b, name = db.actionbar['bar'..i], 'ElvAB_'..i
  handled[name] = true
  if b then
   -- ActionBars/ActionBars.lua:172-226,121-146: caja del backdrop y multiplicadores.
   -- Las barras de acciones tienen 12 botones (bucle de PositionAndSizeBar:339).
   local count = math.min(b.buttons,12)
   if count > 0 then
    local cols = math.max(1,math.min(b.buttonsPerRow,count))
    local rows, gap = math.ceil(count/cols), b.buttonSpacing
    local w = cols*b.buttonSize+(cols-1)*gap
    local h = rows*(b.keepSizeRatio and b.buttonSize or b.buttonHeight)+(rows-1)*gap
    if b.backdrop then
     w = w+2*b.backdropSpacing+(w+gap)*(math.max(1,b.widthMult)-1)
     h = h+2*b.backdropSpacing+(h+gap)*(math.max(1,b.heightMult)-1)
    end
    add(name,w,h,pos(name,barPositions[i]),private.actionbar.enable and b.enabled)
    -- ActionBars/ActionBars.lua:252-260: el frame puede desplazarse respecto del mover.
    if b.backdrop then
     local up = b.point == 'BOTTOMLEFT' or b.point == 'BOTTOMRIGHT'
     local left = b.point == 'BOTTOMRIGHT' or b.point == 'TOPRIGHT'
     local anchor = up and 'BOTTOMLEFT' or 'TOPLEFT'
     nodes['ElvUI_Bar'..i] = {width=w,height=h,enabled=false,
      position=anchor..','..name..','..anchor..','..(left and border or -border)..','..(up and -border or border)}
    else aliases['ElvUI_Bar'..i] = name end
   end
  end
 end
 local names = {player='Player',target='Target',targettarget='TargetTarget',focus='Focus',
  pet='Pet',focustarget='FocusTarget',pettarget='PetTarget',targettargettarget='TargetTargetTarget',
  party='Party',raid1='Raid1',raid2='Raid2',raid3='Raid3',raidpet='Raidpet'}
 local ufDefaults = {player='BOTTOM,ElvUIParent,BOTTOM,-342,139',target='BOTTOM,ElvUIParent,BOTTOM,342,139',
  targettarget='BOTTOM,ElvUIParent,BOTTOM,342,100',pet='BOTTOM,ElvUIParent,BOTTOM,-342,100',
  focus='BOTTOM,ElvUIParent,BOTTOM,342,59',targettargettarget='BOTTOM,ElvUIParent,BOTTOM,0,160',
  focustarget='BOTTOM,ElvUF_Focus,TOP,0,7',pettarget='BOTTOM,ElvUF_Pet,TOP,0,7'}
 for unit, suffix in pairs(names) do
  local b, name = db.unitframe.units[unit], 'ElvUF_'..suffix..'Mover'
  if b then
   local h = b.height+(b.infoPanel and b.infoPanel.enable and b.infoPanel.height or 0)
   local w, approximate, note = b.width, false, nil
   -- Units/Player.lua:68-69,96; Units/Target.lua:51-52; las otras Units usan igual regla.
   if unit == 'party' or unit:match('^raid') then
    -- UnitFrames/UnitFrames.lua:950-1078. Aproximación: grupos completos, sin roster.
    -- Reproduce el tamaño del header; no agrega mascotas ni subelementos externos.
    approximate, note = true, 'Grupo completo; sin roster ni evaluación de visibility.'
    local n = unit == 'party' and 1 or math.min(8,b.numGroups)
    local per = unit == 'party' and 1 or b.groupsPerRowCol
    local W, H = w+b.horizontalSpacing,h+b.verticalSpacing
    local width,height,newCols,newRows = 0,0,0,0
    local horizontal = b.growthDirection:match('^RIGHT') or b.growthDirection:match('^LEFT')
    for i=1,n do
     local last = (i-1)%per
     if last == 0 then
      if horizontal then height=height+H+b.groupSpacing; newRows=newRows+1
      else width=width+W+b.groupSpacing; newCols=newCols+1 end
     elseif horizontal then
      if newRows == 1 then width=width+W*5+b.groupSpacing; newCols=newCols+1 end
     elseif newCols == 1 then height=height+H*5+b.groupSpacing; newRows=newRows+1 end
     if height == 0 then height=H*5+b.groupSpacing end
     if width == 0 then width=W*5+b.groupSpacing end
    end
    w,h = width-b.horizontalSpacing-b.groupSpacing,height-b.verticalSpacing-b.groupSpacing
   end
   add(name,w,h,pos(name,ufDefaults[unit] or 'BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,4,248'),
    private.unitframe.enable and b.enable,note,approximate)
   aliases['ElvUF_'..suffix] = name
  end
 end
 -- Layout/Layout.lua:181-210: el mover incluye 23 unidades si tiene datatext integrado.
 for _, side in ipairs({'Left','Right'}) do
  local separate = side == 'Right' and db.chat.separateSizes
  local w = separate and db.chat.panelWidthRight or db.chat.panelWidth
  local h = separate and db.chat.panelHeightRight or db.chat.panelHeight
  local panelHeight = h
  local showData = db.datatexts.panels[side..'ChatDataPanel'].enable
  if showData then h=h+23 end
  local name = side..'ChatMover'
  add(name,w,h,pos(name),true)
  local anchor = side == 'Left' and 'BOTTOMLEFT' or 'BOTTOMRIGHT'
  local offset = showData and db.chat[side..'ChatDataPanelAnchor'] ~= 'ABOVE_CHAT' and 23 or 0
  nodes[side..'ChatPanel'] = {width=w,height=panelHeight,enabled=false,
   position=anchor..','..name..','..anchor..',0,'..offset}
 end
 -- DataTexts/DataTexts.lua:329-341,448-449: defaults por panel, posición inicial CENTER.
 for panel, saved in pairs(c.global.datatexts.customPanels) do
  local b = loader.merge(loader.merge({},c.global.datatexts.newPanelInfo),saved)
  local name = 'DTPanel'..panel..'Mover'
  local settings = db.datatexts.panels[panel]
  add(name,b.width,b.height,pos(name,'CENTER,ElvUIParent,CENTER,0,0'),settings and settings.enable or false)
  aliases[panel] = name
 end
 -- Maps/Minimap.lua:600-614 y Layout/Layout.lua:462-465 (panel de 22 o 19).
 local map = db.general.minimap
 local size = map.size*map.scale
 local panelEnabled = db.datatexts.panels.MinimapPanel.enable
 local panelHeight = pixel and 22 or 19
 local w = size+(pixel and 2 or 6)
 local h = size+((panelEnabled and panelHeight or (pixel and 1 or -1))-1)+(pixel and 2 or 8)
 add('MinimapMover',w,h,pos('MinimapMover','TOPRIGHT,ElvUIParent,TOPRIGHT,-3,-3'),private.general.minimap.enable)
 aliases.ElvUI_MinimapHolder = 'MinimapMover'
 local offset = pixel and 1 or 3
 nodes.Minimap = {width=size,height=size,position='TOPRIGHT,MinimapMover,TOPRIGHT,'..(-offset)..','..(-offset),enabled=false}
 nodes.MinimapPanel = {width=size+2*border,height=panelHeight,
  position='TOPLEFT,Minimap,BOTTOMLEFT,'..(-border)..','..(pixel and 0 or -3),enabled=false}
 -- Auras/Auras.lua:578-615 y Containers.lua:625-637,1060-1076.
 -- Modern mide una fila inicialmente. Dibujamos la capacidad máxima, no auras activas.
 for _, kind in ipairs({'buffs','debuffs'}) do
  local b = db.auras[kind]
  local name = kind == 'buffs' and 'BuffsMover' or 'DebuffsMover'
  local horizontal = b.growthDirection:match('^LEFT') or b.growthDirection:match('^RIGHT')
  local bw,bh = b.size,b.keepSizeRatio and b.size or b.height
  local mw,mh = bw,(bh+b.horizontalSpacing)*b.wrapAfter
  if horizontal then mw,mh=(bw+b.horizontalSpacing)*b.wrapAfter,bh end
  local n = add(name,mw,mh,pos(name,(kind == 'buffs' and 'TOPRIGHT' or 'BOTTOMRIGHT')..
   ',ElvUI_MinimapHolder,'..(kind == 'buffs' and 'TOPLEFT' or 'BOTTOMLEFT')..','..(-6-border)..','..(-spacing)),
   private.auras.enable and private.auras[kind == 'buffs' and 'buffsHeader' or 'debuffsHeader'],
   'Capacidad máxima configurada; cantidad activa desconocida.',true)
  local columns,rows = b.wrapAfter,b.maxWraps
  if not horizontal then columns,rows=rows,columns end
  -- Containers.lua:636-637: spacing en el eje principal, lineSpacing entre líneas.
  local gx,gy = b.horizontalSpacing,b.verticalSpacing
  if not horizontal then gx,gy=gy,gx end
  n.drawWidth,n.drawHeight=columns*bw+(columns-1)*gx,rows*bh+(rows-1)*gy
  local left = b.growthDirection:find('RIGHT',1,true)
  local down = b.growthDirection:find('DOWN',1,true)
  n.drawAnchor=(down and 'TOP' or 'BOTTOM')..(left and 'LEFT' or 'RIGHT')
 end
 -- Tamaños y anclas propios: Tanks.lua:12-13,88-101; Buttons.lua:147-148;
 -- Flight.lua:36-38; LootMonitor.lua:16-17,63-68; RaidMarkers.lua:16,45-50,102-110.
 local own = {
  {'KnuUI_ManaTankMover',66,154,'BOTTOM,ElvUIParent,BOTTOM,256,28',db.KnuUITanks == true},
  {'KnuUI_ButtonsMover',26,24,pos('KnuUI_ButtonsMover','TOPRIGHT,ElvUIParent,TOPRIGHT,-8,-212'),true},
  {'KnuUI_FlightTimerMover',240,18,'TOP,ElvUIParent,TOP,0,-120',true},
  {'KnuUI_LootMonitorMover',260,6*(22+3),'BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-148,240',db.KnuUILootMonitor ~= false},
  {'KnuUI_RaidMarkersMover',20+3*2,3+11*(20+3),'TOP,KnuUI_ButtonsMover,BOTTOM,0,-4',db.KnuUIRaidMarkers ~= 'off'},
 }
 for _, b in ipairs(own) do add(unpack(b)) end
 aliases.KnuUI_Buttons='KnuUI_ButtonsMover'
 aliases.KnuUI_ManaTank='KnuUI_ManaTankMover'
 -- El resto conserva su ancla, sin inventar el tamaño del frame.
 for name, position in pairs(db.movers or {}) do
  if not handled[name] then
   local n=add(name,20,20,position,true,'(size unknown) / tamaño desconocido')
   n.unknown=true
   local frame=name:match('^(.-)Mover$')
   if frame and not nodes[frame] and not aliases[frame] then aliases[frame]=name end
  end
 end
 return nodes,aliases
end
return M
