local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

K:RegisterSkin('Auctionator', function()
	-- Auctionator/Source_Classic/Initialize/Main.lua:27,38 y
	-- Source_Mainline/Initialize/Main.lua:37,48: creación tardía al abrir la subasta.
	K:WatchAddonFrame('Auctionator', 'AuctionatorAHFrame')
end)
