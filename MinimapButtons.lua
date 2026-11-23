local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Fuentes relativas a D:/World of Warcraft/_forever_/Interface/AddOns/.
-- TomTom/libs/LibDBIcon-1.0/LibDBIcon-1.0.lua:16,178-179,253-254,409-413,428-438,465-475.
-- TomTom/libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:59-60.
-- Hide no persiste: db.hide evita que Refresh vuelva a mostrar el botón.
-- Cada objeto se procesa en su propio pcall: uno roto no interrumpe los demás.
function K:ScanMinimapButtons()
 if InCombatLockdown() then K:AfterCombat(function() K:ScanMinimapButtons() end, 'KnuUI:MinimapScan'); return end
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
 pcall(function()
  -- Shortest Path Forever no usa LibDBIcon. Sus opciones se abren con la función del compartimento de
  -- addons (ShortestPathForever.toc:19; definida en UI/Settings.lua:797, llama a ns.OpenSettings). Su
  -- botón "Journey" va colgado debajo del minimapa, sobre el panel de KnuUI (UI/Settings.lua:33-35;
  -- apagado por defecto, Core/Core.lua:82): si está prendido se oculta por esta sesión, sin tocar su opción.
  local open = _G.ShortestPathForever_OnAddonCompartmentClick
  if type(open) ~= 'function' then return end
  entries.ShortestPath = {
   label = 'Shortest Path', icon = [[Interface\AddOns\ShortestPathForever\media\Icon]],
   -- ns.OpenSettings usa el abridor seguro de ForeverCore, que necesita CreateSecureDelegate
   -- (ForeverCore/Core/OpenSettings.lua); en clientes sin esa función no abre nada (probado en el
   -- juego: nil). Ir directo a la categoría está bloqueado (SettingsPanel:OpenToCategory dio "acción de
   -- interfaz bloqueada"), y abrir el panel desde KnuUI (SettingsPanel:Open) dejó la interfaz rota
   -- (íconos transparentes, teclado perdido) hasta recargar: el panel no se abre desde acá. Sin la
   -- función segura sólo se indica dónde están las opciones (Esc > Opciones > AddOns).
   click = function()
    if type(_G.CreateSecureDelegate) == 'function' then open() return end
    E:Print(L["Shortest Path: open the AddOns tab and choose \"Shortest Path Forever\"."])
   end,
  }
  if _G.ShortestPathForeverOptionsButton then _G.ShortestPathForeverOptionsButton:Hide() end
 end)
 pcall(function()
  -- Offhand no usa LibDBIcon: su botón propio es OffhandMinimapIcon (Offhand/UI/Minimap.lua:3). Clic
  -- izquierdo del original: Offhand.Options:Open(); clic derecho: asistente y "juntar UI fuera de pantalla"
  -- (Minimap.lua:87-115). Acá: clic = opciones, Mayús = asistente, Ctrl = juntar UI.
  local offhand = _G.Offhand
  local button = _G.OffhandMinimapIcon
  if not (offhand and button) then return end
  entries.Offhand = {
   label = 'Offhand', icon = [[Interface\AddOns\Offhand\Media\OffhandLogo64x64.blp]],
   click = function()
    if IsControlKeyDown() and offhand.GatherOffScreenUI then offhand:GatherOffScreenUI() return end
    if IsShiftKeyDown() then
     if offhand.IsSetupComplete and not offhand:IsSetupComplete() and offhand.Onboarding and offhand.Onboarding.Open then
      offhand.Onboarding:Open()
     elseif offhand.Wizard and offhand.Wizard.Open then
      offhand.Wizard:Open()
     end
     return
    end
    if offhand.Options and offhand.Options.Open then offhand.Options:Open() end
   end,
  }
  -- Sólo por esta sesión: Offhand lo vuelve a mostrar en UpdateMinimapIcon (Minimap.lua:63-69); su opción
  -- guardada showMinimapIcon no se toca.
  button:Hide()
  if not K.offhandIconHooked and type(offhand.UpdateMinimapIcon) == 'function' then
   K.offhandIconHooked = true
   hooksecurefunc(offhand, 'UpdateMinimapIcon', function() button:Hide() end)
  end
 end)
 pcall(K.AbsorbOtherMinimapButtons, K, entries)
 self:RefreshLauncher()
end

-- Botones propios de cualquier otro addon: todo Button con nombre colgado del minimapa (o de MinimapBackdrop) que no sea del
-- juego, de ElvUI, de KnuUI ni de LibDBIcon (esos van arriba). Caso típico: CheapUpgradesMinimapButton, hijo de Minimap con su
-- propio OnClick (CheapUpgrades/Options.lua:1327-1360). Ícono: el campo icon/Icon del botón o su textura más grande que no sea
-- borde ni resaltado. Clic: el OnClick original con el botón del mouse que se usó en el menú. Sólo se oculta por esta sesión, y
-- si el addon lo vuelve a mostrar se oculta otra vez. Los botones protegidos (seguros) no se tocan.
local SKIP_NAME = { '^Minimap', '^MiniMap', '^GameTime', '^TimeManager', '^Elv', '^KnuUI', '^LibDBIcon', '^QueueStatus',
	'^Garrison', '^ExpansionLandingPage', '^AddonCompartment', '^HybridMinimap', 'Pin', 'Arrow', 'Ping', 'Tracking' }
local function Skippable(name)
	for _, pattern in ipairs(SKIP_NAME) do if name:find(pattern) then return true end end
end

local function ButtonIcon(button)
	for _, key in ipairs({ 'icon', 'Icon' }) do
		local t = button[key]
		local tex = type(t) == 'table' and t.GetTexture and t:GetTexture()
		if tex then return tex end
	end
	local best, area
	for _, region in ipairs({ button:GetRegions() }) do
		if region.IsObjectType and region:IsObjectType('Texture') and region.GetTexture then
			local tex = region:GetTexture()
			local text = type(tex) == 'string' and tex:lower() or ''
			if tex and not text:find('border') and not text:find('highlight') and not text:find('background') then
				local w, h = region:GetSize()
				local a = (w or 0) * (h or 0)
				if not area or a > area then best, area = tex, a end
			end
		end
	end
	return best
end

-- Pines de mapa (TomTom crea TTMinimapButton%d con textura y OnClick, TomTom/modules/minimap_pins.lua:131-154, y
-- HereBeDragons los cuelga del minimapa): no son lanzadores. Se reconocen por la tabla de pines de HereBeDragons
-- (pins.minimapPins, HereBeDragons-Pins-2.0.lua:16).
local function IsMapPin(button)
	if not LibStub then return false end
	for _, major in ipairs({ 'HereBeDragons-Pins-2.0', 'HereBeDragons-Pins-1.0' }) do
		local ok, lib = pcall(LibStub, major, true)
		if ok and type(lib) == 'table' and type(lib.minimapPins) == 'table' and lib.minimapPins[button] then return true end
	end
	return false
end

-- OnClick, o OnMouseUp en los botones que sólo usan ese (revisión de Codex 2026-11-22).
local function Handler(button)
	return button:GetScript('OnClick') or button:GetScript('OnMouseUp')
end

K.absorbedButtons = K.absorbedButtons or {}
function K:AbsorbOtherMinimapButtons(entries)
	local absorbed = self.absorbedButtons
	local parents = { _G.Minimap, _G.MinimapBackdrop }
	for _, parent in ipairs(parents) do
		if parent and parent.GetChildren then
			for _, button in ipairs({ parent:GetChildren() }) do
				local name = button.GetName and button:GetName()
				local key = name and 'Btn:'..name
				if name and not Skippable(name) and button.IsObjectType and button:IsObjectType('Button')
					and not (button.IsProtected and button:IsProtected())
					and (absorbed[button] or button:IsShown()) and not self:LauncherHasButton(entries, button)
					and not IsMapPin(button) then
					local icon = ButtonIcon(button)
					if icon and Handler(button) then
						local label = name:gsub('MinimapButton$', ''):gsub('MinimapIcon$', ''):gsub('_?Minimap$', '')
						entries[key] = {
							label = label ~= '' and label or name, icon = icon, button = button,
							click = function(_, mouse)
								local script = Handler(button)
								if script then script(button, mouse == 'RightButton' and 'RightButton' or 'LeftButton') end
							end,
						}
						button:Hide()
						if not absorbed[button] then
							absorbed[button] = true
							hooksecurefunc(button, 'Show', function(self) if K.absorbedButtons[self] then self:Hide() end end)
						end
					end
				end
			end
		end
	end
end

-- ¿Ya hay una entrada propia (de las de arriba) para este botón? Las de arriba lo ocultan, así que no queda a la vista.
function K:LauncherHasButton(entries, button)
	for key, entry in pairs(entries) do
		if entry.button == button and not key:find('^Btn:') then return true end
	end
	return false
end

function K:SetupMinimapButtons()
 if self.minimapButtonsEvents then return end
 local events = CreateFrame('Frame')
 self.minimapButtonsEvents = events
 events:RegisterEvent('PLAYER_ENTERING_WORLD')
 events:RegisterEvent('PLAYER_REGEN_DISABLED')
 events:SetScript('OnEvent', function(_, event)
  if event == 'PLAYER_REGEN_DISABLED' then K.flyout:Hide(); return end
  K:ScanMinimapButtons()
  -- Temporizadores como Dock.lua: reintentos acotados para botones tardíos.
  if C_Timer and type(C_Timer.After) == 'function' then
   C_Timer.After(2, function() K:ScanMinimapButtons() end)
   C_Timer.After(5, function() K:ScanMinimapButtons() end)
  end
 end)
 self:ScanMinimapButtons()
end
