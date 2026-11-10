local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- Textos legibles sobre el fondo oscuro de KnuUI.
-- Sin EllesmereUI, WhatsTraining elige su tema "pergamino" (Forever/Theme.lua:75-79), con textos
-- marrón oscuro pensados para el pergamino claro (Theme.lua:3-12). Con el fondo oscuro de la skin
-- no se leen. La tabla del tema es privada (wt, Theme.lua:1), así que se cambia cada color de
-- pergamino por el equivalente del tema oscuro del propio addon (Theme.lua:38-49).
-- Las filas se crean a medida que se dibujan (Forever/Widgets.lua:16-18, Views.lua:116-183):
-- mientras la ventana está abierta se revisan los textos nuevos y a cada uno se le engancha
-- SetTextColor para corregir también los colores que se pongan después.
local function key(r, g, b) return format('%.2f,%.2f,%.2f', r or 0, g or 0, b or 0) end
local REMAP = {
	[key(0.19, 0.12, 0.06)] = { 0.90, 0.90, 0.90 }, -- body
	[key(0.08, 0.04, 0.02)] = { 1, 1, 1 },          -- strong
	[key(0.40, 0.40, 0.40)] = { 0.65, 0.65, 0.65 }, -- dim (el 0,5 del tema oscuro queda bajo con este fondo)
	[key(0.10, 0.38, 0.05)] = { 0.65, 1, 0.40 },    -- available
	[key(0.08, 0.22, 0.50)] = { 0.55, 0.84, 1 },    -- nextLevel
	[key(0.30, 0.10, 0.05)] = { 1, 0.55, 0.45 },    -- groupUnavailable
	[key(0.45, 0.09, 0.04)] = { 1, 0.55, 0.45 },    -- levelUnavailable
	[key(0.55, 0.12, 0.05)] = { 1, 0.55, 0.45 },    -- weaponUnavailable
}

local hooked = setmetatable({}, { __mode = 'k' })
local busy = false

local function Fix(fs, r, g, b, a)
	if busy then return end
	local to = REMAP[key(r, g, b)]
	if to then
		busy = true
		fs:SetTextColor(to[1], to[2], to[3], a or 1)
		busy = false
	end
end

local function Walk(node)
	for _, region in ipairs({ node:GetRegions() }) do
		if region:IsObjectType('FontString') and not hooked[region] then
			hooked[region] = true
			hooksecurefunc(region, 'SetTextColor', Fix)
			Fix(region, region:GetTextColor())
		end
	end
	for _, child in ipairs({ node:GetChildren() }) do Walk(child) end
end

local tickers = setmetatable({}, { __mode = 'k' })
local function Watch(frame)
	if not frame or tickers[frame] ~= nil then return end
	tickers[frame] = false
	local function Start()
		pcall(Walk, frame)
		if not tickers[frame] then
			tickers[frame] = C_Timer.NewTicker(0.25, function() pcall(Walk, frame) end)
		end
	end
	frame:HookScript('OnShow', Start)
	frame:HookScript('OnHide', function()
		if tickers[frame] then tickers[frame]:Cancel() end
		tickers[frame] = false
	end)
	if frame:IsShown() then Start() end
end

K:RegisterSkin('WhatsTraining', function()
	-- WhatsTraining/Forever/SpellBook.lua:593,596,636: wt.CreateFrame crea ambos marcos.
	-- Se observa la creación real; wt es privado (WhatsTraining.lua:1).
	K:WatchAddonFrame('WhatsTraining', 'WhatsTrainingOverlay', Watch)
	K:WatchAddonFrame('WhatsTraining', 'WhatsTrainingFrame', Watch)
end)
