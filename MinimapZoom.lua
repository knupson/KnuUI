local E = unpack(ElvUI)
local _, ns = ...
local L = ns.L
local K = E:GetModule('KnuUI')

-- Botón "+" arriba de la lupa de rastreo del minimapa (pedido del user 2026-11-13): duplica el tamaño del
-- minimapa y corre lo que está al lado. ElvUI cambia el tamaño con E.db.general.minimap.size y
-- M:UpdateSettings (Modules/Maps/Minimap.lua:564-614: minimapa y su contenedor juntos). Los buffos, la
-- durabilidad, la cola, etc. están anclados a la esquina de arriba a la derecha con distancias fijas
-- (Layout.lua:67-69), no al minimapa: los que están a su izquierda se corren a la izquierda y los que están
-- debajo bajan, lo mismo que creció. Lo que el jugador movió a mano mientras estaba grande no se toca al
-- volver. Nada de esto en combate.
local M = E:GetModule('Minimap')
local FACTOR = 2

local function MapDB() return E.db.general and E.db.general.minimap end

local function Parse(s)
	if type(s) ~= 'string' then return end
	local p, rel, rp, x, y = s:match('^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$')
	x, y = tonumber(x), tonumber(y)
	if p == 'TOPRIGHT' and rel == 'ElvUIParent' and rp == 'TOPRIGHT' and x and y then return x, y end
end

local function Fmt(x, y) return format('TOPRIGHT,ElvUIParent,TOPRIGHT,%d,%d', math.floor(x + 0.5), math.floor(y + 0.5)) end

local function Refresh()
	if M.UpdateSettings then pcall(M.UpdateSettings, M) end
	if K.SnapLauncher then C_Timer.After(0.1, function() K:SnapLauncher() end) end
end

-- Rectángulo de un marco en unidades de ElvUIParent (las de los movers).
local function Rect(f)
	if not (f and f.GetLeft and f:GetLeft()) then return end
	local s = f:GetEffectiveScale() / E.UIParent:GetEffectiveScale()
	return { l = f:GetLeft() * s, r = f:GetRight() * s, t = f:GetTop() * s, b = f:GetBottom() * s }
end

local function Holder() return M.MapHolder or _G.MMHolder or _G.Minimap end

-- Se mide el minimapa real antes y después de agrandarlo (revisión de Codex: puede no estar en la esquina).
-- Sólo se corren los movers que el minimapa grande tapa: los que estaban a su izquierda, lo que creció hacia
-- la izquierda; los que estaban debajo, lo que creció hacia abajo. Así se conservan las separaciones.
local function ShiftMovers(old, new)
	E.db.movers = E.db.movers or {}
	local saved = {}
	if not (old and new) then return saved end
	local dx, dy = new.l - old.l, new.b - old.b -- negativos: creció hacia la izquierda y hacia abajo
	for name, s in pairs(E.db.movers) do
		local x, y = Parse(s)
		local holder = E.CreatedMovers and E.CreatedMovers[name] and E.CreatedMovers[name].mover or _G[name]
		local r = x and name ~= 'MinimapMover' and name ~= 'KnuUI_ButtonsMover' and Rect(holder)
		if r and r.l < new.r and r.r > new.l and r.t > new.b and r.b < new.t then
			local nx, ny = x, y
			if (r.l + r.r) / 2 < old.l then nx = x + dx
			elseif (r.t + r.b) / 2 < old.b then ny = y + dy end
			if nx ~= x or ny ~= y then
				local moved = Fmt(nx, ny)
				saved[name] = { orig = s, new = moved }
				E.db.movers[name] = moved
				if E.SetMoverPoints then pcall(E.SetMoverPoints, E, name) end
			end
		end
	end
	return saved
end

local function RestoreMovers(saved)
	if not saved then return end
	for name, st in pairs(saved) do
		-- Si lo moviste a mano con el minimapa grande, queda donde lo dejaste.
		if E.db.movers[name] == st.new then
			E.db.movers[name] = st.orig
			if E.SetMoverPoints and _G[name] then pcall(E.SetMoverPoints, E, name) end
		end
	end
end

function K:ToggleBigMinimap()
	if InCombatLockdown() then E:Print(L["Leave combat before applying KnuUI."]) return end
	local db = MapDB()
	if not db then return end
	local st = E.db.KnuUIBigMinimap
	local scale = tonumber(db.scale) or 1
	if st then
		db.size = st.base
		Refresh()
		RestoreMovers(st.movers)
		E.db.KnuUIBigMinimap = nil
	else
		local base = tonumber(db.size) or math.floor(_G.Minimap:GetWidth() + 0.5)
		local old = Rect(Holder())
		db.size = base * FACTOR
		if M.UpdateSettings then pcall(M.UpdateSettings, M) end
		local movers = ShiftMovers(old, Rect(Holder()))
		E.db.KnuUIBigMinimap = { base = base, movers = movers }
		Refresh()
	end
	if K.minimapZoom then K.minimapZoom.text:SetText(E.db.KnuUIBigMinimap and '-' or '+') end
end

local function Place(button)
	local tracking = _G.MinimapCluster and (_G.MinimapCluster.Tracking or _G.MinimapCluster.TrackingFrame) or _G.MiniMapTrackingFrame or _G.MiniMapTracking
	button:ClearAllPoints()
	if tracking and tracking:IsShown() and tracking:GetBottom() and tracking:GetTop() > 0 and tracking:GetTop() < 4000 then
		button:SetPoint('BOTTOM', tracking, 'TOP', 0, 2)
	else
		button:SetPoint('BOTTOMLEFT', _G.Minimap, 'BOTTOMLEFT', 3, 30)
	end
end

function K:SetupMinimapZoom()
	if self.minimapZoom or not _G.Minimap then return end
	local b = CreateFrame('Button', 'KnuUI_MinimapZoom', _G.Minimap)
	self.minimapZoom = b
	b:SetSize(18, 18)
	b:SetFrameLevel(_G.Minimap:GetFrameLevel() + 10)
	b:SetTemplate('Default')
	if K.Hoverable then K:Hoverable(b) end
	local t = b:CreateFontString(nil, 'OVERLAY')
	t:FontTemplate('Expressway', 16, 'OUTLINE')
	t:SetPoint('CENTER', 1, 1)
	t:SetText(E.db.KnuUIBigMinimap and '-' or '+')
	local c = K.GetTheme and K:GetTheme()
	if c and c.accent then t:SetTextColor(c.accent.r, c.accent.g, c.accent.b) end
	b.text = t
	b:SetScript('OnClick', function() K:ToggleBigMinimap() end)
	b:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
		GameTooltip:SetText(E.db.KnuUIBigMinimap and L["Minimap: normal size"] or L["Minimap: double size"])
		GameTooltip:Show()
	end)
	b:SetScript('OnLeave', function() GameTooltip:Hide() end)
	-- La lupa la ubica ElvUI (M:HandleTrackingButton, Minimap.lua:152); se sigue después de cada ajuste.
	Place(b)
	if M.HandleTrackingButton then hooksecurefunc(M, 'HandleTrackingButton', function() Place(b) end) end
	if M.UpdateSettings then hooksecurefunc(M, 'UpdateSettings', function() Place(b) end) end
	C_Timer.After(1, function() Place(b) end)
end
