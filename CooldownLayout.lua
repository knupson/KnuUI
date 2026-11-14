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

	-- Encima del centro tapaba al personaje (visto en el juego 2026-11-13). Lugar elegido por el user, medido con
	-- tools/render en su perfil: arriba del bloque derecho, entre el objetivo del objetivo (termina en x 1168,
	-- Tanks.lua) y el monitor de botín (empieza en x 1512, LootMonitor.lua), desde y 188 (chats hasta 184). El
	-- grupo del Healer termina en x 1173 (Roles.lua:73-103: x -213..213), así que la zona arranca en 1177 para
	-- todos los roles. Centrada en el hueco se veía corrida (user 2026-11-13): borde izquierdo alineado con el
	-- bloque derecho de abajo (x 1255 = centro + 295, Tanks.lua SIDE) y 4 por encima de su borde (182 + 4 = 186).
	-- Arriba del bloque izquierdo, de borde a borde (pedido del user 2026-11-13): el bloque va de x 409 a 665
	-- (Tanks.lua: 4 + 401 + 4 = 409, ancho 256). Para cada visor se elige, con la cantidad de íconos de ahora, el
	-- tamaño (50-200 % de a 10, EditModeSettingDisplayInfo.lua:928-935) y el relleno (0-14) que dejan la fila
	-- VISIBLE lo más cerca de 256 sin pasarse. Cuentas de Blizzard: cada ícono mide base·tamaño/100
	-- (CooldownViewer.lua:2008, iconScale) y entre íconos va relleno - 4 (:2015-2017, :2061); el skin achica cada
	-- ícono 2 por lado (Skins/CooldownViewer.lua), así que lo visible es el ancho del visor menos 4. El valor
	-- guardado del tamaño es el índice del deslizador, (tamaño - 50) / 10 (con 100 % guardado 5 el cálculo
	-- directo daba alto 2, /knu visores 2026-11-13); el del relleno, el valor mismo (mínimo 0, paso 1).
	-- Si cambia la cantidad de íconos, /knu enfriamientos vuelve a ajustar.
	-- Ancho de 4 casillas del bloque izquierdo (pedido del user 2026-11-13): 4 · 41 + 3 · 2 = 170 (Tanks.lua BARS:
	-- botones de 41 con 2 de separación), desde su borde izquierdo x 409. Medido en el juego (/knu visores): el
	-- tamaño guardado es el índice del deslizador (170 % dio 85 de alto) y el relleno difiere de relleno - 4 en
	-- 0,5 a 1 px (261 de ancho en vez de 259): se acepta esa diferencia.
	-- Sobre las casillas 2 a 5 (user 2026-11-13: la 1 y la 6 libres arriba): 409 + 41 + 2 = 452.
	local LEFT, WIDTH = -508, 170 -- 452 - 960
	local keys = Enum.EditModeCooldownViewerSetting
	local function Set(info, setting, value)
		for _, s in ipairs(info.settings or {}) do
			if s.setting == setting then s.value = value; return end
		end
		info.settings = info.settings or {}
		table.insert(info.settings, { setting = setting, value = value })
	end
	local function Fit(base, n)
		local best
		for pct = 50, 200, 10 do
			for pad = 0, 14 do
				local visible = n * base * pct / 100 + (n - 1) * (pad - 4) - 4
				if visible <= WIDTH then
					-- Primero el ancho (hasta 1 px de diferencia cuenta como alineado); después la separación más
					-- cercana a 2 px, la de las casillas del bloque (visible = relleno - 4 + 4 = relleno).
					local score = math.max(0, WIDTH - visible - 1) * 100 + math.abs(pad - 2)
					if not best or score < best.score then best = { score = score, pct = pct, pad = pad, edge = base * pct / 100 } end
				end
			end
		end
		return best
	end
	local y = 186
	local fits = {}
	for i = 1, 3 do
		local info = systems[order[i]]
		local viewer = _G[NAMES[i]]
		local base = ({ 50, 30, 40 })[i]
		local n = math.max(viewer.GetItemCount and viewer:GetItemCount() or 0, 1)
		-- Buffs: su cantidad cambia con las auras activas; ajustarlo al ancho con la del momento lo llevó al 200 %
		-- (80 de alto, /knu visores 2026-11-13). Usa el tamaño y el relleno de utilidad.
		local fit = i == 3 and fits[2] and { pct = fits[2].pct, pad = fits[2].pad, edge = base * fits[2].pct / 100 } or Fit(base, n)
		fits[i] = fit
		if fit and keys and keys.IconSize and keys.IconPadding then
			Set(info, keys.IconSize, (fit.pct - 50) / 10)
			Set(info, keys.IconPadding, fit.pad)
		end
		info.anchorInfo = { point = 'BOTTOMLEFT', relativeTo = 'UIParent', relativePoint = 'BOTTOM', offsetX = LEFT - 2, offsetY = y - 2 }
		-- EditModeManager.lua:340-363: soltar segundo anclaje y gestión predeterminada.
		info.anchorInfo2, info.isInDefaultPosition = nil, false
		y = y + (fit and fit.edge or sizes[i].height) - 4 + 4 -- alto visible (lado - 4) más 4 de separación
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
