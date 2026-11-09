local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

-- Baganator: el título de la ventana ("Bolsas de ...") queda tapado por los botones de la
-- izquierda. Se recoloca entre los botones y se centra. Marcos reales (Interface/AddOns/Baganator/):
--   ViewManagement/Initialize.lua:140-141  Baganator_SingleViewBackpackViewFrame<grupo> y CategoryView
--   Skins/GW2.lua:15,27-28                 frame:GetTitleText() (ButtonFrameTemplate)
-- La posición por defecto ya es abajo a la derecha, sobre Details (Core/Config.lua:62).

local done = {}

local function FixTitle(frame)
	if done[frame] or type(frame.GetTitleText) ~= 'function' then return end
	local title = frame:GetTitleText()
	if not title then return end
	done[frame] = true
	local t = K:GetTheme()
	title:ClearAllPoints()
	title:SetPoint('TOPLEFT', frame, 'TOPLEFT', 104, -6)  -- después de los 4 botones de la izquierda
	title:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -78, -6) -- antes de los 3 de la derecha
	title:SetJustifyH('CENTER')
	title:SetWordWrap(false)
	if title.FontTemplate then pcall(title.FontTemplate, title, 'Expressway', 13, 'OUTLINE') end
	title:SetTextColor(t.accent.r, t.accent.g, t.accent.b)
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
