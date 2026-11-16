local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

local NAMES = { 'EssentialCooldownViewer', 'UtilityCooldownViewer', 'BuffIconCooldownViewer', 'BuffBarCooldownViewer' }

-- Cantidad de íconos contando los marcos activos del visor, sin llamar a viewer:GetItemCount().
-- GetItemCount pasa por GetCooldownIDs → CheckBuildDisplayData del gestor (CooldownViewer.lua:1992-2000, 2078-2081;
-- CooldownViewerSettingsDataProvider.lua:100-171, 237-251): llamado desde KnuUI reconstruía esos datos en código de
-- addon y, al subir de nivel, SetHiddenGroupBuffs quedaba bloqueado (ADDON_ACTION_BLOCKED, visto en el juego 2026-11-14).
-- RefreshLayout adquiere exactamente GetItemCount marcos (CooldownViewer.lua:2037-2043), así que el conteo coincide.
local function ItemCount(viewer)
	local pool, n = viewer and viewer.itemFramePool, 0
	if pool and pool.EnumerateActive then
		for _ in pool:EnumerateActive() do n = n + 1 end
	end
	return math.max(n, 1)
end

local function Size(info, viewer, index)
	-- CooldownViewer.xml:21,90,159: ítems cuadrados de 50,30,40; se conserva su configuración.
	-- CooldownViewer.lua:1993-2003,2045-2065,2299-2301: cantidad, stride y padding del GridLayout.
	-- Se calcula con los ajustes del diseño elegido: al reutilizar KnuUI pueden diferir del preset visible.
	local settings = {}
	for _, setting in ipairs(info.settings) do settings[setting.setting] = setting.value end
	local keys = Enum.EditModeCooldownViewerSetting
	local scale, padding = settings[keys.IconSize], settings[keys.IconPadding]
	local stride = settings[keys.IconLimit]
	local horizontal = settings[keys.Orientation] == Enum.CooldownViewerOrientation.Horizontal
	if not scale or not padding or not stride or stride < 1 then return end
	-- Al menos un ícono: con la cantidad del momento un visor podía dar alto 0 y la columna se aplastaba (los
	-- buffs quedaron al costado de los principales, visto en el juego 2026-11-13).
	local count = ItemCount(viewer)
	if index == 3 then stride = count end
	local along, across = math.min(count, stride), math.ceil(count / stride)
	local columns, rows = horizontal and along or across, horizontal and across or along
	-- EditModeSystemTemplates.lua:2992-2995: IconSize guardado es porcentaje.
	local edge = ({ 50, 30, 40 })[index] * scale / 100
	padding = padding - 4
	local frameScale = viewer:GetScale()
	return { width = (columns * edge + (columns - 1) * padding) * frameScale,
		height = (rows * edge + (rows - 1) * padding) * frameScale }
end

local function Copy(value)
	if type(value) ~= 'table' then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = Copy(item) end
	return result
end

function K:ApplyCooldownLayout()
	if E.db.KnuUICooldownLayout == false then return 'opción apagada' end
	if InCombatLockdown() then return 'en combate' end
	if not C_EditMode or not C_EditMode.GetLayouts or not C_EditMode.SaveLayouts or not Enum then return 'sin C_EditMode' end
	local presetManager = EditModePresetLayoutManager
	if not presetManager or not presetManager.GetCopyOfPresetLayouts then return 'sin EditModePresetLayoutManager' end
	local types, indices = Enum.EditModeLayoutType, Enum.EditModeCooldownViewerSystemIndices
	if not types then return 'sin Enum.EditModeLayoutType' end
	if not indices then return 'sin Enum.EditModeCooldownViewerSystemIndices' end
	if not Enum.EditModeSystem then return 'sin Enum.EditModeSystem' end
	if not Enum.EditModeCooldownViewerSetting then return 'sin Enum.EditModeCooldownViewerSetting' end
	if not Enum.CooldownViewerOrientation then return 'sin Enum.CooldownViewerOrientation' end

	-- EditModeManager.lua:1018-1020: GetLayouts no incluye presets; Blizzard los antepone.
	local layouts = Copy(C_EditMode.GetLayouts())
	if not layouts or not layouts.layouts then return 'GetLayouts vacío' end
	local saved = layouts.layouts
	layouts.layouts = presetManager:GetCopyOfPresetLayouts()
	for _, layout in ipairs(saved) do table.insert(layouts.layouts, layout) end
	local active = layouts.layouts[layouts.activeLayout]
	if not active then return 'sin disposición activa (' .. tostring(layouts.activeLayout) .. ')' end
	if active.layoutType == types.Preset then
		local index
		for i, layout in ipairs(layouts.layouts) do
			if layout.layoutType ~= types.Preset and layout.layoutName == 'KnuUI' then index = i; break end
		end
		if not index then
			-- EditModeManager.lua:1255,1567-1585: copia profunda, tipo/nombre e inserción por tipo.
			local copy = Copy(active)
			copy.layoutName, copy.layoutType = 'KnuUI', types.Character
			index = #layouts.layouts + 1 -- Character va después de Preset y Account.
			table.insert(layouts.layouts, index, copy)
		end
		layouts.activeLayout = index
		active = layouts.layouts[index]
	end

	local systems, sizes = {}, {}
	local order = { indices.Essential, indices.Utility, indices.BuffIcon, indices.BuffBar }
	for _, info in ipairs(active.systems or {}) do
		if info.system == Enum.EditModeSystem.CooldownViewer then systems[info.systemIndex] = info end
	end
	for i, index in ipairs(order) do
		local viewer = _G[NAMES[i]]
		if not systems[index] then return 'la disposición no tiene el visor ' .. NAMES[i] end
		if not viewer then return 'no existe ' .. NAMES[i] end
		if i <= 3 then
			-- Tamaño real que el juego ya le dio al visor (con su escala). El cálculo desde los ajustes guardados daba
			-- alto 2 en el juego (/knu visores, 2026-11-13: Utility y BuffIcon quedaron en y 338 sobre los 50 de alto de
			-- Essential); el valor guardado de IconSize no es un porcentaje directo. Sin tamaño medible (visor vacío),
			-- se reserva una fila con el lado de ícono de Blizzard (CooldownViewer.xml:21,90,159: 50, 30, 40).
			local fs = viewer.GetScale and viewer:GetScale() or 1
			local w = viewer.GetWidth and viewer:GetWidth() or 0
			local h = viewer.GetHeight and viewer:GetHeight() or 0
			local edge = ({ 50, 30, 40 })[i]
			if h < 10 then h = edge end
			if w < 10 then w = edge end
			sizes[i] = { width = w * fs, height = h * fs }
			if not sizes[i] then return 'sin ajustes de tamaño: ' .. NAMES[i] end
			-- Visor vacío (sin habilidades asignadas, visto en el juego 2026-11-13 con Utility): igual se guarda su
			-- lugar, pero no ocupa espacio en la columna.
			if sizes[i].width <= 0 or sizes[i].height <= 0 then sizes[i] = { width = 0, height = 0 } end
		end
	end

	-- Diseño A (elegido por el user 2026-11-14 entre dos bocetos, después de revisar cómo lo hacen otras interfaces
	-- y una auditoría de Codex): tamaños fijos de mayor a menor, como BetterCooldownManager, EllesmereUI y
	-- SkironCooldownManager (42/36/32, 47/41/40), sin achicar nunca; con más íconos, otra fila hacia arriba.
	-- Principales del mismo ancho que las casillas del bloque izquierdo (41, Tanks.lua BARS) con su separación de
	-- 2: cada ícono cae sobre una casilla, 6 por fila (x 409-665). Utilidad 35 y buffs 32, 7 por fila.
	-- Cuentas de Blizzard: lado = base · tamaño / 100 (CooldownViewer.lua:2008); entre íconos, relleno - 4
	-- (:2015-2017, :2061); el skin dibuja el ícono 2 adentro por lado (visible = lado - 4, separación visible =
	-- relleno). Guardado (EditModeSettingDisplayInfo.lua): tamaño como (porcentaje - 50) / 10 (:928-935, :8-13;
	-- confirmado en el juego: 170 % dio 85), íconos por fila y relleno tal cual (:906-912, :940-946, :1558-1564).
	local SPEC = {
		{ base = 50, pct = 90, pad = 2, limit = 6 },  -- principales: lado 45, visible 41
		{ base = 30, pct = 130, pad = 2, limit = 7 }, -- utilidad: lado 39, visible 35
		{ base = 40, pct = 90, pad = 2, limit = 7 },  -- buffs: lado 36, visible 32
	}
	local LEFT = -551 -- x 409 (borde izquierdo del bloque) - 960
	local keys = Enum.EditModeCooldownViewerSetting
	local function Set(info, setting, value)
		for _, s in ipairs(info.settings or {}) do
			if s.setting == setting then s.value = value; return end
		end
		info.settings = info.settings or {}
		table.insert(info.settings, { setting = setting, value = value })
	end
	local y = 186 -- 4 por encima del bloque (182)
	for i = 1, 3 do
		local info, spec = systems[order[i]], SPEC[i]
		local viewer = _G[NAMES[i]]
		local n = ItemCount(viewer)
		if i <= 2 then E.db.KnuUICooldownFit = E.db.KnuUICooldownFit or {}; E.db.KnuUICooldownFit[i] = n end -- reajuste solo
		if keys and keys.IconSize and keys.IconPadding and keys.IconLimit then
			Set(info, keys.IconSize, (spec.pct - 50) / 10)
			Set(info, keys.IconPadding, spec.pad)
			Set(info, keys.IconLimit, spec.limit)
		end
		local edge = spec.base * spec.pct / 100
		local rows = math.ceil(n / spec.limit)
		local frameH = rows * edge + (rows - 1) * (spec.pad - 4)
		info.anchorInfo = { point = 'BOTTOMLEFT', relativeTo = 'UIParent', relativePoint = 'BOTTOM', offsetX = LEFT - 2, offsetY = y - 2 }
		-- EditModeManager.lua:340-363: soltar segundo anclaje y gestión predeterminada.
		info.anchorInfo2, info.isInDefaultPosition = nil, false
		y = y + (frameH - 4) + 4 -- alto visible más 4 de separación
	end
	-- Foco y mascota (estaban en x 504-744, y 226-250, dentro de esta zona): 4 por encima de la columna, foco
	-- en el borde izquierdo del bloque y mascota en el derecho.
	E.db.movers = E.db.movers or {}
	-- En los bordes del bloque (x 409 y 665): sobre las 4 casillas del gestor no entran los dos (115 + 115 > 170).
	E.db.movers.ElvUF_FocusMover = string.format('BOTTOMLEFT,ElvUIParent,BOTTOM,%d,%d', -551, y)
	E.db.movers.ElvUF_PetMover = string.format('BOTTOMRIGHT,ElvUIParent,BOTTOM,%d,%d', -295, y)
	for _, name in ipairs({ 'ElvUF_FocusMover', 'ElvUF_PetMover' }) do
		if E.SetMoverPoints and _G[name] then pcall(E.SetMoverPoints, E, name) end
	end
	-- Barra de buffs arriba del chat izquierdo, a 4 del borde: y 210 deja libre la caja de escritura del chat,
	-- que aparece encima del chat (editBoxPosition ABOVE_CHAT, Layout.lua) al escribir.
	local bar = systems[indices.BuffBar]
	bar.anchorInfo = { point = 'BOTTOMLEFT', relativeTo = 'UIParent', relativePoint = 'BOTTOMLEFT', offsetX = 4, offsetY = 210 }
	bar.anchorInfo2, bar.isInDefaultPosition = nil, false
	-- EditModeManager.lua:1657; EditModeManagerDocumentation.lua:110,183-189: activeLayout viaja en SaveLayouts.
	local ok, err = pcall(C_EditMode.SaveLayouts, layouts)
	if not ok then return 'SaveLayouts falló: ' .. tostring(err) end
	return nil, active.layoutName or tostring(layouts.activeLayout)
end

-- /knu enfriamientos: corre sólo esto y dice el resultado.
function K:CooldownLayoutCommand()
	local why, name = self:ApplyCooldownLayout()
	if why then
		E:Print('KnuUI: gestor de enfriamientos sin ubicar: ' .. why)
	else
		-- ReloadUI es protegida: sólo desde un clic o una tecla (bloqueada desde un temporizador, visto 2026-11-13).
		E:Print('KnuUI: gestor de enfriamientos guardado en la disposición ' .. tostring(name) .. '. Escribí /reload para verlo.')
	end
end

-- /knu visores: diagnóstico. Imprime ancla, posición (relativa al ancla), tamaño y visibilidad de cada visor.
function K:CooldownViewersReport()
	for _, name in ipairs(NAMES) do
		local f = _G[name]
		if not f then
			E:Print(name .. ': no existe')
		else
			local p, rel, rp, x, y = f:GetPoint(1)
			local relName = rel and (rel.GetName and rel:GetName() or tostring(rel)) or 'nil'
			E:Print(format('%s: %s %s %s %d %d | %dx%d | %s | izq %d abajo %d', name:gsub('CooldownViewer', ''), tostring(p),
				tostring(relName), tostring(rp), math.floor(x or 0), math.floor(y or 0), math.floor(f:GetWidth() or 0),
				math.floor(f:GetHeight() or 0), f:IsShown() and 'visible' or 'oculto', math.floor(f:GetLeft() or -1),
				math.floor(f:GetBottom() or -1)))
		end
	end
	local layouts = C_EditMode and C_EditMode.GetLayouts and C_EditMode.GetLayouts()
	if layouts then E:Print('Disposición activa: ' .. tostring(layouts.activeLayout)) end
end

-- Reajuste solo (pedido del user 2026-11-14): al cambiar la cantidad de íconos de los principales o de
-- utilidad (aprender una habilidad, cambiar de talentos), la fila dejaba de ocupar las casillas 2 a 5. Blizzard
-- rearma los íconos en RefreshLayout cuando cambia la cantidad (CooldownViewer.lua:2018-2030): ahí, fuera de
-- combate y con la ubicación automática prendida, se recalcula y se guarda. No se sabe si el Modo edición lo
-- aplica sin recargar (EditModeManager.lua:193-197 lo hace con EDIT_MODE_LAYOUTS_UPDATED, no verificado que
-- SaveLayouts lo dispare), así que se avisa una vez que se ve al recargar.
local pending
local function CheckCounts()
	pending = nil
	if E.db.KnuUICooldownLayout == false or InCombatLockdown() then return end
	local fit = E.db.KnuUICooldownFit
	if type(fit) ~= 'table' then return end -- nunca se ubicó con KnuUI: no se toca lo que puso el jugador
	local changed
	for i = 1, 2 do
		local viewer = _G[NAMES[i]]
		local n = viewer and ItemCount(viewer)
		if n and fit[i] and n ~= fit[i] then changed = true end
	end
	if not changed then return end
	local why = K:ApplyCooldownLayout()
	if why then
		E:Print('KnuUI: gestor de enfriamientos sin reajustar: ' .. why)
	else
		E:Print('KnuUI: cambió la cantidad de íconos del gestor de enfriamientos; ya está reajustado y se ve al recargar (/reload).')
	end
end

local function Watch()
	for i = 1, 2 do
		local viewer = _G[NAMES[i]]
		if viewer and not viewer.KnuFitHooked and viewer.RefreshLayout then
			viewer.KnuFitHooked = true
			hooksecurefunc(viewer, 'RefreshLayout', function()
				if not pending then pending = true; C_Timer.After(2, CheckCounts) end
			end)
		end
	end
end

function K:SetupCooldownAutoFit()
	-- Después de un combate, por si cambió durante la pelea.
	local r = CreateFrame('Frame')
	r:RegisterEvent('PLAYER_REGEN_ENABLED')
	r:SetScript('OnEvent', function() if not pending then pending = true; C_Timer.After(2, CheckCounts) end end)
	if _G.EssentialCooldownViewer then Watch() return end
	local f = CreateFrame('Frame')
	f:RegisterEvent('ADDON_LOADED')
	f:SetScript('OnEvent', function(self, _, name)
		if name == 'Blizzard_CooldownViewer' then self:UnregisterAllEvents(); Watch() end
	end)
end
