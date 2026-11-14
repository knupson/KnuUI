local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

local NAMES = { 'EssentialCooldownViewer', 'UtilityCooldownViewer', 'BuffIconCooldownViewer', 'BuffBarCooldownViewer' }

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
	local count = math.max(viewer:GetItemCount() or 0, 1)
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

	local healer = E.db.KnuUIRole == 'healer'
	-- Tanks.lua:202-205: objetivo hasta y=268. Sus auras (perfil: buffs TOPLEFT +2 y debuffs +32, ícono 28, una
	-- fila de 8; ElvUI Defaults/Profile.lua:1642-1643) ocupan y 270-328: la columna arranca 4 más arriba, y=332.
	-- Roles.lua:73-103: grupo x=-213..213, y=340 (columnas) o 204; crece RIGHT_UP.
	-- Healer: borde derecho de la columna en x=-217; nunca invade el grupo central.
	local point, x, y = healer and 'BOTTOMRIGHT' or 'BOTTOM', healer and -217 or 0, 332
	local barX = 212 -- borde izquierdo, 4 px después del objetivo del objetivo.
	for i = 1, 3 do
		local info = systems[order[i]]
		info.anchorInfo = { point = point, relativeTo = 'UIParent', relativePoint = 'BOTTOM', offsetX = x, offsetY = y }
		-- EditModeManager.lua:340-363: soltar segundo anclaje y gestión predeterminada.
		info.anchorInfo2, info.isInDefaultPosition = nil, false
		if sizes[i].height > 0 then y = y + sizes[i].height + 4 end
		if not healer then barX = math.max(barX, sizes[i].width / 2 + 4) end
	end
	-- BuffBar crece a la derecha desde x>=212, y=208: fuera del objetivo y de la columna.
	-- En Healer x=217 deja además 4 px respecto del grupo (borde derecho x=213).
	local bar = systems[indices.BuffBar]
	bar.anchorInfo = { point = 'BOTTOMLEFT', relativeTo = 'UIParent', relativePoint = 'BOTTOM', offsetX = healer and 217 or barX, offsetY = 208 }
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
