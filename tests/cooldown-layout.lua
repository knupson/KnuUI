-- Ejecutar desde la raíz con LuaJIT; no modifica globals del resto de la batería.
local function Copy(value)
	if type(value) ~= 'table' then return value end
	local result = {}
	for k, v in pairs(value) do result[k] = Copy(v) end
	return result
end
local function Equal(a, b)
	if type(a) ~= type(b) then return false end
	if type(a) ~= 'table' then return a == b end
	for k, v in pairs(a) do if not Equal(v, b[k]) then return false end end
	for k in pairs(b) do if a[k] == nil then return false end end
	return true
end
local function Layout(name, kind)
	local systems = { { system = 7, settings = { { setting = 3, value = 9 } }, anchorInfo = { offsetX = 77 } } }
	for i = 1, 5 do
		systems[#systems + 1] = {
			system = 42, systemIndex = i, settings = {
				{ setting = 11, value = 100 }, { setting = 12, value = 4 },
				{ setting = 13, value = 12 }, { setting = 14, value = 0 }, { setting = 15, value = 77 + i },
			},
			anchorInfo = { point = 'TOP', relativeTo = 'OtherFrame', relativePoint = 'BOTTOM', offsetX = i, offsetY = -10 },
			anchorInfo2 = { offsetX = 30 }, isInDefaultPosition = true,
		}
	end
	return { layoutName = name, layoutType = kind, interfaceStyle = 8, systems = systems }
end
local function Run(custom, reuse, healer, disabled, combat, columns, resized)
	local presets = { Layout('Moderno', 0), Layout('Clásico', 0), Layout('Mando', 0) }
	local saved = { activeLayout = custom and 4 or 2, layouts = {} }
	if custom or reuse then saved.layouts[1] = Layout(reuse and 'KnuUI' or 'Personal', 2) end
	if resized then
		for _, system in ipairs(saved.layouts[1].systems) do
			if system.system == 42 then system.settings[1].value = 80 end
		end
	end
	local original, before = Copy(saved), Copy((custom or reuse) and saved.layouts[1] or presets[2])
	local K, E, calls, result = {}, { db = { KnuUIRole = healer and 'healer' or 'mdps', KnuUITanks = columns, KnuUICooldownLayout = disabled } }, 0
	function E:GetModule() return K end
	local env = setmetatable({ ElvUI = { E } }, { __index = _G }); env._G = env
	env.Enum = { EditModeLayoutType = { Preset = 0, Account = 1, Character = 2 }, EditModeSystem = { CooldownViewer = 42 },
		EditModeCooldownViewerSetting = { IconSize = 11, IconPadding = 12, IconLimit = 13, Orientation = 14 },
		CooldownViewerOrientation = { Horizontal = 0, Vertical = 1 },
		EditModeCooldownViewerSystemIndices = { Essential = 1, Utility = 2, BuffIcon = 3, BuffBar = 4 } }
	function env.InCombatLockdown() return combat end
	env.EditModePresetLayoutManager = { GetCopyOfPresetLayouts = function() return Copy(presets) end }
	env.C_EditMode = { GetLayouts = function() return Copy(saved) end, SaveLayouts = function(value) calls = calls + 1; result = value end }
	for i, name in ipairs({ 'EssentialCooldownViewer', 'UtilityCooldownViewer', 'BuffIconCooldownViewer', 'BuffBarCooldownViewer' }) do
		-- Tamaños medidos en el juego con /knu visores (2026-11-13): 146x50, 142x30, 81x40, 330x63.
		local real = ({ { 146, 50 }, { 142, 30 }, { 81, 40 }, { 330, 63 } })[i]
		env[name] = { GetScale = function() return resized and 1.25 or 1 end, GetItemCount = function() return resized and 25 or 2 end,
			GetWidth = function() return real[1] end, GetHeight = function() return real[2] end }
		setmetatable(env[name], { __index = function(_, method) error('No se permite tocar el viewer: '..method) end })
	end
	local chunk = assert(loadfile('addons/KnuUI/CooldownLayout.lua')); setfenv(chunk, env); chunk()
	K:ApplyCooldownLayout()
	assert(Equal(saved, original))
	if disabled == false or combat then assert(calls == 0); return end
	assert(calls == 1 and result.activeLayout == 4 and #result.layouts == 4)
	for i = 1, 3 do assert(Equal(result.layouts[i], presets[i])) end
	local active = result.layouts[4]
	assert(active.layoutName == (custom and 'Personal' or 'KnuUI') and active.layoutType == 2 and active.interfaceStyle == 8)
	for i, system in ipairs(active.systems) do
		if i >= 2 and i <= 5 then
			assert(Equal(system.settings, before.systems[i].settings))
			assert(not system.anchorInfo2 and system.isInDefaultPosition == false)
			local anchor = system.anchorInfo
			assert(anchor.relativeTo == 'UIParent' and anchor.relativePoint == 'BOTTOM')
			if i <= 4 then
				assert(anchor.point == (healer and 'BOTTOMRIGHT' or 'BOTTOM') and anchor.offsetX == (healer and -217 or 0))
				assert(anchor.offsetY == (resized and { 332, 398.5, 440 } or { 332, 386, 420 })[i - 1])
			else assert(anchor.point == 'BOTTOMLEFT' and anchor.offsetX == (healer and 217 or 212) and anchor.offsetY == 208) end
			local unchanged = Copy(system)
			unchanged.anchorInfo, unchanged.anchorInfo2, unchanged.isInDefaultPosition = before.systems[i].anchorInfo, before.systems[i].anchorInfo2, before.systems[i].isInDefaultPosition
			assert(Equal(unchanged, before.systems[i]))
		else assert(Equal(system, before.systems[i])) end
	end
	-- Reaplicar sobre el diseño personalizado guardado no agrega copias ni cambia el resultado.
	saved = { activeLayout = result.activeLayout, layouts = { Copy(active) } }
	local first = Copy(result)
	K:ApplyCooldownLayout(); assert(calls == 2 and Equal(first, result))
end
Run(false, false, false)
Run(false, true, false)
Run(false, true, false, nil, false, true, true)
Run(true, false, false)
Run(false, false, true, nil, false, true)
Run(false, false, true, nil, false, false)
Run(false, false, false, false)
Run(false, false, false, nil, true)
print('OK: diseño de reutilizaciones; presets, copia, reutilización, personalizado, aislamiento, roles, opción y combate.')
