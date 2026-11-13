local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- Baganator: el título de la ventana ("Bolsas de ...") queda tapado por los botones de la
-- izquierda. Se recoloca entre los botones y se centra. Marcos reales (Interface/AddOns/Baganator/):
--   ViewManagement/Initialize.lua:140-141  Baganator_SingleViewBackpackViewFrame<grupo> y CategoryView
--   Skins/GW2.lua:15,27-28                 frame:GetTitleText() (ButtonFrameTemplate)
-- La posición por defecto ya es abajo a la derecha, sobre Details (Core/Config.lua:62).

local done = {}

-- Margen libre a cada lado: se miden los botones de la barra de arriba (los que están a menos de 32 de
-- su borde superior) cada vez que se abre. Con 104/78 fijos el título quedaba debajo del 4.º botón de la
-- izquierda (visto en el juego 2026-11-13: "olsas de ...").
local function Gaps(frame)
	local fl, fr, ft = frame:GetLeft(), frame:GetRight(), frame:GetTop()
	if not (fl and fr and ft) then return 104, 78 end
	local fs = frame:GetEffectiveScale()
	local mid = (fl + fr) / 2
	local left, right = 0, 0
	local function Visit(parent, depth)
		for _, c in ipairs({ parent:GetChildren() }) do
			if c:IsShown() and c.IsObjectType and c:IsObjectType('Button') and c:GetLeft() and c:GetTop() then
				local k = c:GetEffectiveScale() / fs
				local cl, cr, ct, ch = c:GetLeft() * k, c:GetRight() * k, c:GetTop() * k, c:GetHeight() * k
				if ft - ct < 32 and ch <= 40 then
					if (cl + cr) / 2 < mid then left = math.max(left, cr - fl) else right = math.max(right, fr - cl) end
				end
			end
			if depth < 2 then Visit(c, depth + 1) end
		end
	end
	Visit(frame, 0)
	return (left > 0 and left or 100) + 4, (right > 0 and right or 74) + 4
end

local function Place(frame)
	local title = frame:GetTitleText()
	if not title then return end
	local l, r = Gaps(frame)
	title:ClearAllPoints()
	title:SetPoint('TOPLEFT', frame, 'TOPLEFT', l, -6)
	title:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -r, -6)
end

local function FixTitle(frame)
	if done[frame] or type(frame.GetTitleText) ~= 'function' then return end
	local title = frame:GetTitleText()
	if not title then return end
	done[frame] = true
	local t = K:GetTheme()
	title:SetJustifyH('CENTER')
	title:SetWordWrap(false)
	if title.FontTemplate then pcall(title.FontTemplate, title, 'Expressway', 13, 'OUTLINE') end
	title:SetTextColor(t.accent.r, t.accent.g, t.accent.b)
	Place(frame)
	-- Los botones se acomodan al abrir y al cambiar de ancho: se vuelve a medir en el cuadro siguiente.
	frame:HookScript('OnShow', function(f) C_Timer.After(0, function() pcall(Place, f) end) end)
	frame:HookScript('OnSizeChanged', function(f) C_Timer.After(0, function() pcall(Place, f) end) end)
end

local function Scan()
	for name, frame in pairs(_G) do
		if type(name) == 'string' and name:find('^Baganator_.-BackpackViewFrame') and type(frame) == 'table' then
			pcall(FixTitle, frame)
		end
	end
end

function K:SetupBaganatorSkin()
	if not self:IsLoaded('Baganator') then return end
	local f = CreateFrame('Frame')
	f:RegisterEvent('PLAYER_ENTERING_WORLD')
	f:SetScript('OnEvent', function(self)
		self:UnregisterAllEvents()
		C_Timer.After(2, Scan)
	end)
end
