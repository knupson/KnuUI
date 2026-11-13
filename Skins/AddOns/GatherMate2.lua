local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

local function Apply()
	local frame = _G.GatherMate2_GenericDropDownMenu
	if not frame then return end
	-- GatherMate2/Display.lua:223-225: Frame sin plantilla, sólo displayMode/initialize.
	-- El menú visible lo arma ToggleDropDownMenu (:153), no este contenedor sin texturas.
	-- No agregar un fondo a un ancla invisible ni vestir DropDownList globales de Blizzard.
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:IsObjectType('Texture') then
			K:WatchAddonFrame('GatherMate2', 'GatherMate2_GenericDropDownMenu', function(f)
				if K.KnuFrame then K:KnuFrame(f) end
			end, true)
			return
		end
	end
end

K:RegisterSkin('GatherMate2', function()
	Apply()
	hooksecurefunc('CreateFrame', function(_, name)
		if name == 'GatherMate2_GenericDropDownMenu' then
			C_Timer.After(0, function() K:RunAddonSkin('GatherMate2', Apply, Apply) end)
		end
	end)
end)
