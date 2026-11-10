local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- Fuentes relativas a D:/World of Warcraft/_forever_/Interface/AddOns/.
-- TomTom/libs/LibDBIcon-1.0/LibDBIcon-1.0.lua:16,178-179,253-254,409-413,428-438,465-475.
-- TomTom/libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:59-60.
-- Hide no persiste: db.hide evita que Refresh vuelva a mostrar el botón.
-- Cada objeto se procesa en su propio pcall: uno roto no interrumpe los demás.
function K:ScanMinimapButtons()
 if InCombatLockdown() then self.minimapScanPending = true; return end
 self.minimapScanPending = false
 self.launcherAddons = self.launcherAddons or {}
 local entries = self.launcherAddons
 local ok, lib, ldb = pcall(function()
  if not LibStub then return end
  return LibStub('LibDBIcon-1.0', true), LibStub('LibDataBroker-1.1', true)
 end)
 if ok and lib then
  local listed, names = pcall(function()
   if type(lib.GetButtonList) == 'function' then return lib:GetButtonList() end
   local result = {}
   for name in pairs(type(lib.objects) == 'table' and lib.objects or {}) do result[#result + 1] = name end
   return result
  end)
  if listed and type(names) == 'table' then
   for _, name in ipairs(names) do
    pcall(function()
     local button = type(lib.GetMinimapButton) == 'function' and lib:GetMinimapButton(name)
      or type(lib.objects) == 'table' and lib.objects[name]
     if not button or type(lib.Hide) ~= 'function' then return end
     local object = ldb and type(ldb.GetDataObjectByName) == 'function' and ldb:GetDataObjectByName(name)
      or button.dataObject
     -- No se oculta un acceso si no tiene una acción equivalente disponible.
     if not object or type(object.OnClick) ~= 'function' then return end
     entries['LDB:'..name] = {
      label = type(object.label) == 'string' and object.label or name, icon = object.icon,
      click = function(fakeButton)
       if type(object.OnClick) ~= 'function' then return end
       fakeButton.dataObject = object
       object.OnClick(fakeButton, 'LeftButton')
      end,
     }
     -- Sólo se oculta por esta sesión (lib:Hide); no se toca button.db, que es la
     -- configuración guardada del otro addon (LibDBIcon:254). Se reaplica en cada escaneo.
     lib:Hide(name)
    end)
   end
  end
 end
 pcall(function()
  -- GearQuestForever/Core.lua:10 exporta GearQuest.
  -- Minimap.lua:72-75,119-123,145: Toggle, SetHidden y GearQuestMinimapButton.
  local gq = _G.GearQuest
  if not (gq and gq.Minimap and type(gq.Minimap.SetHidden) == 'function'
   and gq.Log and type(gq.Log.Toggle) == 'function' and _G.GearQuestMinimapButton) then return end
  entries.GearQuest = {
   label = 'GearQuest', icon = [[Interface\AddOns\GearQuestForever\Art\GearQuest-Icon]],
   click = function()
    if gq.Log and type(gq.Log.Toggle) == 'function' then gq.Log:Toggle() end
   end,
  }
  -- Se oculta el botón sin usar SetHidden, que guardaría la opción en GearQuest (Minimap.lua:119-123).
  _G.GearQuestMinimapButton:Hide()
 end)
 pcall(function()
  -- WIM no usa LibDBIcon: su botón propio es WIM3MinimapButton (WIM/Modules/MinimapIcon.lua:165).
  -- Clic: el mismo menú que abre el botón original con clic izquierdo (MinimapIcon.lua:123-131,257-262:
  -- Menu:AnchorTo + Menu:ShowFor; WIM.Menu se crea en Modules/Menu.lua:1223-1301), anclado al
  -- lanzador de KnuUI. Con Mayús: opciones (WIM.ShowOptions, Sources/Options/Options.lua:42).
  -- (Antes abría sólo los mensajes sin leer, WindowHandler.lua:2068: sin conversaciones no mostraba nada.)
  -- WIM usa setfenv(1, WIM), así que sus funciones globales viven en la tabla WIM.
  local wim = _G.WIM
  local button = _G.WIM3MinimapButton
  if not (wim and button) then return end
  entries.WIM = {
   label = 'WIM', icon = [[Interface\AddOns\WIM\Skins\Default\minimap]],
   click = function()
    if IsShiftKeyDown() and type(wim.ShowOptions) == 'function' then wim.ShowOptions() return end
    local menu = wim.Menu
    if menu and type(menu.AnchorTo) == 'function' and type(menu.ShowFor) == 'function' then
     if menu:IsShown() then menu:Hide() return end
     local anchor = K.buttons or UIParent
     menu:AnchorTo(anchor)
     menu:ShowFor(anchor, false)
    elseif type(wim.ShowAllUnreadWindows) == 'function' then
     wim.ShowAllUnreadWindows()
    end
   end,
  }
  -- Sólo se oculta por esta sesión; la opción guardada de WIM no se toca. Se reaplica en cada escaneo.
  button:Hide()
 end)
 self:RefreshLauncher()
end

function K:SetupMinimapButtons()
 if self.minimapButtonsEvents then return end
 local events = CreateFrame('Frame')
 self.minimapButtonsEvents = events
 events:RegisterEvent('PLAYER_ENTERING_WORLD')
 events:RegisterEvent('PLAYER_REGEN_ENABLED')
 events:RegisterEvent('PLAYER_REGEN_DISABLED')
 events:SetScript('OnEvent', function(_, event)
  if event == 'PLAYER_REGEN_DISABLED' then K.flyout:Hide(); return end
  if event == 'PLAYER_REGEN_ENABLED' then
   if K.minimapScanPending then K:ScanMinimapButtons() end
   return
  end
  K:ScanMinimapButtons()
  -- Temporizadores como Dock.lua: reintentos acotados para botones tardíos.
  if C_Timer and type(C_Timer.After) == 'function' then
   C_Timer.After(2, function() K:ScanMinimapButtons() end)
   C_Timer.After(5, function() K:ScanMinimapButtons() end)
  end
 end)
 self:ScanMinimapButtons()
end
