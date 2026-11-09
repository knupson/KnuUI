local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

K:RegisterSkin('GTFO', function()
	-- GTFO/Retail/GTFO_Retail.lua:758-782: panel Settings y checks Blizzard.
	-- Classic/GTFO_Classic.lua:688-712 usa el mismo nombre de panel y templates.
	K:WatchAddonFrame('GTFO', 'GTFO_MainFrame')
end)
