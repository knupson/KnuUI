local E = unpack(ElvUI)
local K = E:GetModule('KnuUI')

K:RegisterSkin('Pawn', function()
	-- Pawn/PawnUI.xml:399: ventana principal, con controles definidos en el mismo XML.
	K:WatchAddonFrame('Pawn', 'PawnUIFrame')
end)
